**********************************************************************;
* Project           : IDF
*
* Program name      : IDF.sas
*
* Author            : MATSUO YAMAMOTO
*
* Date created      : 20151106
*
* Purpose           :
*
* Revision History  :
*
* Date        Author           Ref    Revision (Date in YYYYMMDD format)
* YYYYMMDD    XXXXXX XXXXXXXX  1      XXXXXXXXXXXXXXXXXXXXXXXXXXXX
*
**********************************************************************;

/*** Version ***/
%LET VER = 20150422 ;

/*** Initial setting ***/
%MACRO WORKING_DIR;

  %*** Setting macro variables;

    %LOCAL _FULLPATH _PATH;
    %LET   _FULLPATH = ;
    %LET   _PATH     = ;

    %*** Obtain full path;

    %IF %LENGTH(%SYSFUNC(GETOPTION(SYSIN))) = 0 %THEN
        %LET _FULLPATH = %SYSGET(SAS_EXECFILEPATH);
    %ELSE
        %LET _FULLPATH = %SYSFUNC(GETOPTION(SYSIN));

    %*** Process to delete from the full path to the working directory;

    %LET _PATH = %SUBSTR(   &_FULLPATH., 1, %LENGTH(&_FULLPATH.)
                          - %LENGTH(%SCAN(&_FULLPATH.,-1,'\'))
                          - %LENGTH(%SCAN(&_FULLPATH.,-2,'\'))
                          - 2 );

    %*** Return value;

    &_PATH.

%MEND WORKING_DIR;

%LET _WK_PATH = %WORKING_DIR;

LIBNAME OUTPUT "&_WK_PATH.";

/*- IDF -*/
FILENAME DRGFILE1 "&_WK_PATH.\ver&VER.\医薬品名データファイル\&VER.提供\全件.TXT";
FILENAME DRGFILE2 "&_WK_PATH.\ver&VER.\医薬品名データファイル＜可変長＞\全件＜可変長＞.TXT";
FILENAME DRGFILE3 "&_WK_PATH.\ver&VER.\英名＜可変長＞\英名＜可変長＞.TXT";

/*- IDF Read -*/
*全件;
DATA DRGFILE1;
   LENGTH DRUGCODE    $10. KANYOCAT    $1.  USECAT1     $1.  USECAT2     $2.  BASECODE    $1.
          MEDDRUG     $40. MEDDRUGK    $25. GENNAME     $40. GENNAMEK    $25. MAKERCODE   $3.
          MAKERNAME   $20. FORMCODE    $20. DRGCODECAT1 $1.  MNTSEQ      $7.  MNTFLG      $1.
          MNTYN       $4.  DRGCODECAT2 $1.;
   INFILE DRGFILE1 DLM="," DSD MISSOVER;
   INPUT DRUGCODE  KANYOCAT USECAT1     USECAT2  BASECODE
         MEDDRUG   MEDDRUGK GENNAME     GENNAMEK MAKERCODE
         MAKERNAME FORMCODE DRGCODECAT1 MNTSEQ   MNTFLG
         MNTYN     DRGCODECAT2;

   LABEL DRUGCODE    = "薬剤コード"
         KANYOCAT    = "慣用区分"
         USECAT1     = "使用区分１"
         USECAT2     = "使用区分２"
         BASECODE    = "基準名コード"
         MEDDRUG     = "薬剤名"
         MEDDRUGK    = "薬剤名カナ"
         GENNAME     = "一般名"
         GENNAMEK    = "一般名カナ"
         MAKERCODE   = "メーカーコード"
         MAKERNAME   = "メーカーの略称"
         FORMCODE    = "剤形コード"
         DRGCODECAT1 = "薬剤コード区分１"
         MNTSEQ      = "メンテナンスSEQ"
         MNTFLG      = "メンテナンスFLG"
         MNTYN       = "メンテ年月"
         DRGCODECAT2 = "薬剤コード区分２";

   IF KANYOCAT ^= "1" AND MNTFLG ^= "C";
RUN;

*全件＜可変長＞;
DATA DRGFILE2;
   LENGTH MNTSEQ $7.
          MEDDRUGFULL  $500.
          MEDDRUGFULLK $200.
          GENNAMEFULL  $500.
          GENNAMEFULLK $200.;
   INFILE DRGFILE2 DLM="," DSD MISSOVER;
   INPUT MNTSEQ MEDDRUGFULL MEDDRUGFULLK GENNAMEFULL GENNAMEFULLK;

   LABEL MNTSEQ        = "メンテナンスSEQ"
         MEDDRUGFULL   = "基本薬剤名フル"
         MEDDRUGFULLK  = "基本薬剤名フルカナ"
         GENNAMEFULL   = "一般名フル"
         GENNAMEFULLK  = "一般名フルカナ";
RUN;

*英名＜可変長＞;
DATA DRGFILE3;
   LENGTH MNTSEQ $7.
          MEDDRUGFULLE  $500.;
   INFILE DRGFILE3 DLM="," DSD MISSOVER;
   INPUT MNTSEQ MEDDRUGFULLE ;

   LABEL MNTSEQ        = "メンテナンスSEQ"
         MEDDRUGFULLE  = "基本薬剤名英語";
RUN;


PROC SORT DATA=DRGFILE1; BY MNTSEQ; RUN;
PROC SORT DATA=DRGFILE2; BY MNTSEQ; RUN;
PROC SORT DATA=DRGFILE3; BY MNTSEQ; RUN;

DATA OUTPUT.IDF_&VER.;
   MERGE DRGFILE1 (IN=A)
         DRGFILE2
         DRGFILE3 ;
   BY MNTSEQ;
   IF A;
   IF MEDDRUGFULLE="" OR LENGTH(DRUGCODE) <= 6 THEN DELETE;
   DRUGCODE3 = COMPRESS(SUBSTR(DRUGCODE,1,3));
   DRUGCODE4 = COMPRESS(SUBSTR(DRUGCODE,1,4));
RUN;

PROC SORT DATA = OUTPUT.IDF_&VER. OUT = IDF NODUPKEY; BY DRUGCODE MEDDRUGFULLE ; RUN ;
PROC SORT DATA = IDF                        NODUPKEY; BY DRUGCODE MEDDRUGFULL  ; RUN ;

/*- 3桁データ付与 -*/
DATA IDF3;
   MERGE DRGFILE1 (IN=A)
         DRGFILE2
         DRGFILE3 ;
   BY MNTSEQ;
   IF A;
   IF MEDDRUGFULLE="" OR LENGTH(DRUGCODE) = 3 THEN OUTPUT;
   RENAME MEDDRUGFULL = MEDDRUGFULL3;
   RENAME DRUGCODE = DRUGCODE3;
RUN;

PROC SORT DATA = IDF ; BY DRUGCODE3; RUN ;
PROC SORT DATA = IDF3; BY DRUGCODE3; RUN ;

DATA IDF;
  MERGE  IDF(IN=A) IDF3(KEEP=DRUGCODE3 MEDDRUGFULL3);
  BY  DRUGCODE3;
  IF A;
RUN ;

/*- 4桁データ付与 -*/
DATA IDF4;
   MERGE DRGFILE1 (IN=A)
         DRGFILE2
         DRGFILE3 ;
   BY MNTSEQ;
   IF A;
   IF MEDDRUGFULLE="" OR LENGTH(DRUGCODE) = 4 THEN OUTPUT;
   RENAME MEDDRUGFULL = MEDDRUGFULL4;
   RENAME DRUGCODE = DRUGCODE4;
RUN;

PROC SORT DATA = IDF ; BY DRUGCODE4; RUN ;
PROC SORT DATA = IDF4; BY DRUGCODE4; RUN ;

DATA IDF;
  MERGE  IDF(IN=A) IDF4(KEEP=DRUGCODE4 MEDDRUGFULL4);
  BY  DRUGCODE4;
  IF A;
RUN ;

/*- Ptoshオプション用に加工 -*/
DATA  PTOSH_IDF;
  LENGTH  OUT1 $10. OUT2 $2000.;
  SET  IDF;
  OUT1=COMPRESS(DRUGCODE);
  IF  ^MISSING(MEDDRUGFULL4) THEN DO;
    OUT2=COMPRESS(MEDDRUGFULL) ||": " || COMPRESS(MEDDRUGFULL4)  ||"(" || COMPRESS(USECAT2) ||"): "|| COMPRESS(MEDDRUGFULLE);
  END ;
  ELSE DO;
    OUT2=COMPRESS(MEDDRUGFULL) ||": " || COMPRESS(MEDDRUGFULL3)  ||"(" || COMPRESS(USECAT2) ||"): "|| COMPRESS(MEDDRUGFULLE);
  END ;
  KEEP OUT1 OUT2;
RUN ;

PROC EXPORT DATA = PTOSH_IDF OUTFILE = "&_WK_PATH.\IDF_&VER..csv" DBMS = CSV REPLACE; PUTNAMES=NO;
RUN;

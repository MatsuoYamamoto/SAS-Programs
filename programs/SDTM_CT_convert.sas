/*
 * ----------------------------------------------------------
 * Program Name   :  SDTM_CT_Convert.sas
 * Purpose        :  Conversion of SDTM Terminology File
 * Protocol #     :  
 * Author         :  Matsuo Yamamoto
 * ----------------------------------------------------------
 */

%let root = C:\Users\matsu\Desktop\CT;

libname cdisc "&root";

*+-----------------------------------------------------------------------+
 |  options                                                              |
 +-----------------------------------------------------------------------+;

options pageno=1 nocenter replace formdlim="" noxwait noxsync;
title;
footnote;

*+-----------------------------------------------------------------------+
 |  processing                                                           |
 +-----------------------------------------------------------------------+;
%let original = SDTM Terminology.txt;
%let out_filename = SDTM_Terminology_2017-12-12;

proc import out = sdtm_ct
  datafile= "&root.\&original." 
  dbms=tab replace;
  getnames=yes;
  guessingrows=max;
run;

data list01;
   set sdtm_ct;
   where Codelist_Code = "";
   keep Code Codelist_Extensible__Yes_No_ CDISC_Submission_Value CDISC_Definition;
run;

data list02;
   set list01;
   rename Code = Codelist_Code
          CDISC_Submission_Value = CodelistId
          CDISC_Definition = CTListDef
      ;
run;

data value01;
   set sdtm_ct;
   where Codelist_Code ^= "";
   drop  Codelist_Extensible__Yes_No_;
run;

proc sort data = list02; by Codelist_Code; run;
proc sort data = value01; by Codelist_Code; run;

data all01;
   merge value01
         list02
     ;
   by Codelist_Code;
   rename CDISC_Synonym_s_ = Translated
          CDISC_Definition = CTDef
      ;
   
   format _all_;
   informat _all_;
   attrib _all_ label="" ;
run;

option missing = "";

data all00;
    attrib CodelistId                   label='Codelist ID'     ;
    attrib Codelist_Code                label='Codelist Code'   ;
    attrib Codelist_Name                label='Codelist Label'  ;
    attrib Datatype                     label='Data Type'       ;
    attrib SASFormatName                label='SASFormatName'   ;
    attrib Code                         label='Code'            ;
    attrib Ordernum                     label='Oeder Number'    ;
    attrib Rank                         label='Rank'            ;
    attrib Codelist_Extensible__Yes_No_ label='ExtendedValue'   ;
    attrib CDISC_Submission_Value       label='Submission Value';
    attrib Translated                   label='Translated Text' ;
    attrib lang                         label='xml:lang'        ;
    attrib CTDef                        label='CDISC Definition';
    attrib CTListDef                    label='CDISC Codeliset Def';
    attrib NCI_Preferred_Term           label='NCI Preferred Term';

    set all01;
    Datatype = "text";
    SASFormatName="";
    OrderNum = "";
    Rank = "";
    if Translated ^= "" then lang = "en";
run;


*+-----------------------------------------------------------------------+
 |  output                                                               |
 +-----------------------------------------------------------------------+;

proc export data=all00
   outfile="&root.\&out_filename..csv"
   dbms=csv
   replace;
run;

*eof;

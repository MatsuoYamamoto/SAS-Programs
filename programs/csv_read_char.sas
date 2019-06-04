**********************************************************************;
* Project           : CSV read with Character type
*
* Program name      : csv_read_char.sas
*
* Author            : MATSUO YAMAMOTO
*
* Date created      : 20190604
*
* Purpose           : CSV read with Character type
*
* Revision History  :
*
* Date        Author           Ref    Revision (Date in YYYYMMDD format)
* YYYYMMDD    XXXXXX XXXXXXXX  1      XXXXXXXXXXXXXXXXXXXXXXXXXXXX
*
**********************************************************************;

%macro csv_read_char(filename);

  data ImportVNames;
    length var $200;
    infile "&raw.\&filename..csv" delimiter=',' dsd obs=1  lrecl=250000;
    input var @@ ;
  run;

  data _null_;
    set  ImportVNames end=eof;
    if  eof = 1 then call symput("vobs",strip(put(_n_,10.)));
  run;

  data ImportVNames;
    retain num;
    set  ImportVNames;
    if  _n_ = 1 then num=0;
    num = num + 1;
    name = compress("v" || put(num,10.)) ;
    drop num;
  run ;

  data &filename.;
    length v1-v&vobs. $200;
    infile "&raw.\&filename..csv" delimiter=',' firstobs=2 missover dsd lrecl=250000;
    input v1-v&vobs. ;
  run;

  %macro rename(oldvar,newvar);
    rename &oldvar.=&newvar.;
  %mend rename;

  proc sql;
    select cats('%rename(',name,',',var,')')
    into :renamelist separated by ' '
    from ImportVNames;
  quit;

  proc datasets ;
    modify &filename.;
    &renamelist;
  quit;

%mend;

%csv_read_char(dm);

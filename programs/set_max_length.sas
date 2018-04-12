/*
 * ----------------------------------------------------------
 * Program Name   :  
 * Purpose        :  Resetting the length of the character with the actual maximum length
 * Protocol #     :  
 * Author         :  Matsuo Yamamoto
 * ----------------------------------------------------------
 */
options formdlim = '-';

data _ds01;
  length c1-c2 $ 200;
  length n1-n2 8;
  length c3 $ 10;
  length dtc $10;

  input c1-c2 n1-n2 c3 dt dtc;

  dt = input(dtc, yymmdd10.);
  drop dtc;

  format n1 8.2;
  format n2 best.;
  format dt yymmdd10.;
cards;
A S001 1 10 Y 2001-01-01
B S002 2 20 N 2001-01-02
C S003 3 30 Y 2001-01-03
;
run;

%macro set_max_length(in=, out=);
  data _mt01;
    set &in.;
  run;

  data _mt02;
    set _mt01;

    array _aryc _character_;

    length _vname $ 50;
    length _length 8;
    do over _aryc;
      _vname = vname(_aryc);
      _len = length(_aryc);
      output;
    end;

    keep _vname _len;
  run;
  proc sort;
    by _vname;
  run;

  proc means data = _mt02 noprint;
    var _len;
    by _vname;

    output out = _mt03 (drop = _type_ _freq_) max = _maxlen;
  run;

  proc contents data = _mt01 out = _mt04 varnum noprint;
  run;

  data _mt05;
    set _mt04;

    length _vname $ 50;
    _vname = trim(left(name));

    keep _vname type varnum label format formatl formatd;
  run;
  proc sort;
    by _vname;
  run;

  data _mt;
    merge
      _mt05
      _mt03
      ;
    by _vname;

    if (type = 1) then _maxlen = 8;
  run;
  proc sort;
    by varnum;
  run;

  data &out.;
    set &in. (rename = (
      %let _dsid = %sysfunc(open(_mt));
      %let cnt = %sysfunc(attrn(&_dsid., nobs));
      %do _i = 1 %to &cnt.;
        %let _ret = %sysfunc(fetchobs(&_dsid, &_i.));
        %let name = %sysfunc(getvarc(&_dsid., %sysfunc(varnum(&_dsid., _vname))));
        &name.=_&name.
      %end;
      %let _ret = %sysfunc(close(&_dsid.));
      ));

    %let _dsid = %sysfunc(open(_mt));
    %let cnt = %sysfunc(attrn(&_dsid., nobs));

    %do _i = 1 %to &cnt.;
      %let _ret = %sysfunc(fetchobs(&_dsid, &_i.));

      %let name = %sysfunc(getvarc(&_dsid., %sysfunc(varnum(&_dsid., _vname))));
      %let type = %sysfunc(getvarn(&_dsid., %sysfunc(varnum(&_dsid., type))));
      %let label = %sysfunc(getvarc(&_dsid., %sysfunc(varnum(&_dsid., label))));

      %let format = %sysfunc(getvarc(&_dsid., %sysfunc(varnum(&_dsid., format))));
      %let formatl = %sysfunc(getvarn(&_dsid., %sysfunc(varnum(&_dsid., formatl))));
      %if (&formatl. = 0) %then %let formatl =;
      %let formatd = %sysfunc(getvarn(&_dsid., %sysfunc(varnum(&_dsid., formatd))));
      %if (&formatd. = 0) %then %let formatd =;

      %let length = %sysfunc(getvarn(&_dsid., %sysfunc(varnum(&_dsid., _maxlen))));

      %if (&type. = 1) %then %do;
        length &name. 8;
        &name. = _&name.;
      %end;
      %else %if (&type. = 2) %then %do;
        length &name. $ &length.;
        &name. = trim(left(_&name.));
      %end;

      %if ("&label." ^= "") %then %do;
        label &name. = "&label.";
      %end;

      %if ("&format." ^= "" | &formatl. ^=) %then %do;
        %if (&type. = 1) %then %do;
          format &name. &format.&formatl..&formatd.;
        %end;
        %else %if (&type. = 2) %then %do;
          format &name. $&format.&formatl..&formatd.;
        %end;
      %end;

      drop _&name.;
    %end;

    %let _ret = %sysfunc(close(&_dsid.));
  run;
%mend;

%set_max_length(in=_ds01, out=_out01);

proc contents data = _out01 varnum;
run;

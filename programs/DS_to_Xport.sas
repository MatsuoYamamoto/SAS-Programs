/*
 * ----------------------------------------------------------
 * Program Name   :  DS_to_Xport.sas
 * Purpose        :  Convert all to SAS migration file
 * Protocol #     :  
 * Author         :  Matsuo Yamamoto
 * ----------------------------------------------------------
 */

options formdlim = '-';

proc sql noprint;
  select xpath into :filepath separated by ' '
    from (select input(substr(fileref, 4), 5.) as _refno, xpath from dictionary.extfiles
        where upcase(scan(xpath, -1, '.')) = 'SAS')
    having _refno = max(_refno);
quit;
%let folderpath = %substr(&filepath., 1, %length(&filepath.) - %length(%qscan(&filepath., -1, '\')) - 1);

%macro DS_to_Xport(lib=, path=);
  %local name;
  %if (%qscan(&sysver., 1, .) = 8) %then %let name = memname;
  %else %if (%qscan(&sysver., 1, .) >= 9) %then %let name = name;

  ods exclude all;
  ods noresults;
  proc datasets memtype = data;
    contents data = &lib.._all_ nods;

    ods output members = _dsls;
  run;
  quit;
  ods results;
  ods select all;

  %local _dslsid _dsnmid dscnt dsnm _i _ret;

  %let _dslsid = %sysfunc(open(_dsls));
  %let dscnt = %sysfunc(attrn(&_dslsid., nobs));
  %let _dsnmid = %sysfunc(varnum(&_dslsid., &name.));
  %let type = %sysfunc(vartype(&_dslsid., &_dsnmid));

  * データセット;
  %do _i = 1 %to &dscnt.;
    %let _ret = %sysfunc(fetchobs(&_dslsid, &_i.));
    %let dsnm = %lowcase(%sysfunc(getvarc(&_dslsid., &_dsnmid.)));

    libname libxpt xport "&path.\&dsnm..xpt";

    proc copy in = &lib. out = libxpt; 
      select &dsnm.;
    run;

    libname libxpt clear;
  %end;

  %let _ret = %sysfunc(close(&_dslsid));
%mend;

libname libin "&folderpath.\SASDS";

%DS_to_Xport(lib=libin, path=%nrquote(&folderpath.\XPT));

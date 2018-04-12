/*
 * ----------------------------------------------------------
 * Program Name   :  Xport_to_DS.sas
 * Purpose        :  Convert all SAS transport files to SAS dataset
 * Protocol #     :  
 * Author         :  Matsuo Yamamoto
 * ----------------------------------------------------------
 */
/*
  Convert all SAS transport files to SAS dataset
*/

options formdlim = '-';

proc sql noprint;
  select xpath into :filepath separated by ' '
    from (select input(substr(fileref, 4), 5.) as _refno, xpath from dictionary.extfiles
        where upcase(scan(xpath, -1, '.')) = 'SAS')
    having _refno = max(_refno);
quit;
%let folderpath = %substr(&filepath., 1, %length(&filepath.) - %length(%qscan(&filepath., -1, '\')) - 1);

%macro Xport_to_DS(path=, lib=, ext=xpt);
  %local _rc _dirref _did _cnt _i _isdirref _isdir _filename _filepath;

  %let _dirref = dumydir;
  %let _rc = %sysfunc(filename(_dirref, "&path."));

  %let _did = %sysfunc(dopen(&_dirref.));
  %let _cnt = %sysfunc(dnum(&_did.));

  %do _i = 1 %to &_cnt.;
    %let _filename = %sysfunc(dread(&_did., &_i.));
    %let _filepath = %str(&path.\&_filename.);

    %let _isdirref = chkisdir;
    %let _rc = %sysfunc(filename(_isdirref, "&_filepath."));
    %let _isdir = %sysfunc(dopen(&_isdirref.));
    %let _rc = %sysfunc(dclose(&_isdir.));

    %if (&_isdir. = 0) %then %do;
      %if (%index(&_filename., .) > 0 & %upcase(%scan(&_filename., -1, .)) = %upcase(&ext.)) %then %do;
        libname libxpt xport "&_filepath.";

        proc copy in = libxpt out = &lib.;
        run;

        libname libxpt clear;
      %end;
    %end;
  %end;

  %let _rc = %sysfunc(dclose(&_did.));
%mend;

libname libout "&folderpath.\SASDS";

%Xport_to_DS(path=%nrquote(&folderpath.\XPT), lib=libout);

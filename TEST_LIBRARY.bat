
REM ***************************
REM Automated Testing Tool 
REM Author - Amit Saxena
REM ***************************

REM Following section is for developers only

REM To do Check variable are digits or spaces only, critical field in-loop split by and enable critical field chk, FUNIQUE keys section, improve search to show the field which has the match.
REM done CONVFMT=\"%%.20g\";

@ECHO OFF
SETLOCAL EnableDelayedExpansion
REM SET "DO_PARSE=N" etc. To override parsing, checking and searching options etc.
CALL:%~1
GOTO :END

:SUB_ROUTINES

REM Check if gawk exists at set path, otherwise set it to remote location. Finally exit program if gawk is not found.
REM It is slower if gawk is used from remote location.

:CHECK_GAWK_PATH
IF NOT EXIST "%GAWK_PATH%\gawk.exe" (
	IF NOT EXIST "C:\Software\Cygwin64\bin\gawk.exe" (
		ECHO. & ECHO Error: gawk path is not valid, set GAWK_PATH in the script & ECHO.
		PAUSE
		EXIT & REM Exit with error since gawk is not found
	)
	SET "GAWK_PATH=C:\Software\Cygwin64\bin"
)
EXIT /B

:BEFORE_PROCESS

REM Keep following line if you want to show the user prompt to confirm file processing
REM CALL :CONFIRM

REM Must call BEFORE first file is parsed, sets file counter and prints start time
CALL :TIME_START
IF EXIST FILE_NAME.TMP (ECHO FILE_NAME.TMP exists, it will be overwritten. & ECHO.)
IF /I %DO_CHECK% EQU Y (
IF EXIST ZCHECK_OUT (
	CD ZCHECK_OUT
	ECHO.
	DEL *.*
	CD ..
)
)
REM Return control 
EXIT /B

REM This subroutine displays setting of variables.
:SHOW_INFO
CLS & REM Clear screen
ECHO #:#:#:#:#:#:#:# %INFO_SRC% to %INFO_DST% Files Parser - TXT to CSV with Header #:#:#:#:#:#:#:# &ECHO.
ECHO Note: Existing csv overwritten if corresponding txt exists & ECHO.
ECHO Note: Input files will not be modified & ECHO.
ECHO Info: File output name suffix is set to %SUFFIX% &ECHO.
ECHO Info: Output file separator is set to %OSEP% & ECHO.
ECHO Info: Working folder is %WORKING_DIR% & ECHO.
ECHO Perf: Pre-stripping delimiters is set to %DO_STRIP_OSEP% (slower if enabled) & ECHO.
ECHO Perf: gawk found at %GAWK_PATH% (slower if remote location) & ECHO.

EXIT /B

REM This subroutine confirms user choice to proceed.
REM :CONFIRM
REM CHOICE /c:YN /n /t 3 /d y /m:"Enter Y to proceed N to exit, 3 sec wait : "
REM IF ERRORLEVEL 2 EXIT

REM EXIT /B

REM This suubroutine shows start time and sets the counter to zero.
:TIME_START
ECHO. & ECHO ## Process start time = %TIME% ##
EXIT /B

:FUN_PROCESS

REM If the file exists, then only attempt to process it

IF EXIST %FNAME%.TXT (

SET "VPRCTMP=PROCESSED.TMP"

REM ECHO | SET /P=Processing %FNAME% ...
ECHO. & ECHO *** Processing %FNAME% *** & ECHO.

SET VFS="%FNAME%%SUFFIX%"

SET "INF=!VFS!.CSV"

REM CALL :IS_NUMBER_SPACE "!FCRITICAL!" VAR1
REM ECHO "FCRITICAL" "!FCRITICAL!"
REM ECHO VAR1 !VAR1!
REM PAUSE

IF /I %DO_PARSE% EQU Y (
REM This subroutine strips the existing commas, sets header and parses files for which FNAME, FHDR and FWIDTH is set and updates counter on success.

IF "%FWIDTH%" NEQ "N" (

REM Input file is represented by FTEMP string
SET "FTEMP=%FNAME%.TXT"

REM To replace comma in original file with space, FILE_NAME.TMP is created in overwrite mode. Note that %OSEP% is escaped with backslash.
IF /I %DO_STRIP_OSEP% EQU Y (
	"%GAWK_PATH%\gawk" "{gsub(/\%OSEP%/,/ /)}1" !FTEMP! > FILE_NAME.TMP
	SET "FTEMP=FILE_NAME.TMP"
)

REM Replace tab in FHDR with spaces
SET "FHDR=!FHDR:	=,!"

REM Check if file is in use
2>NUL (CALL; >>"!VFS!.CSV") || (
ECHO Warning: Parse output is in use, close !VFS:"=!.CSV to re-generate it
PAUSE)

(CALL; >>"!VFS!.CSV") && (
REM Set the header of  the file
(ECHO !FHDR!) > !VFS!.CSV

REM Replace comma and tab in FWIDTH with spaces

SET "FWIDTH=!FWIDTH:,= !"
SET "FWIDTH=!FWIDTH:	= !"

REM To insert delimiters at given field widths
REM EDIT - Put field widths for your file separated by space, the required delimiter and final CSV file name, file data is appended to header CSV
"%GAWK_PATH%\gawk" "$1=$1" FIELDWIDTHS="!FWIDTH!" ^
OFS=%OSEP% !FTEMP! >> !VFS!.CSV && (ECHO __ CSV DONE) || (ECHO __ ERROR - CSV FAILED)

REM Close file in use block
)

REM Close check FWIDTH block
)

REM Following closing bracket is end of IF DO_PARSE block
)

REM File checks begin
IF /I %DO_CHECK% EQU Y (

MKDIR ZCHECK_OUT 2>NUL

REM ###############################
REM CUSTOM LOGIC - TODO - Make parameters External.
REM Since the data rows in text file always start with 2, otherwise set it to blank 
SET "FILTER=($1+0)==2"
REM Additional filter for critical field checks
SET "FILTER_CRI=($0 !~ /DEAD/)"
REM Set reporting date
SET "REP_DATE=20211201"
REM Disable printing unique values of specified column
REM SET "FUNIQUE=N"
REM #################################

SET "IS_FILE_OK=Y"

IF NOT EXIST !INF! (
	ECHO File !INF! not found, checks aborted
	EXIT /B
)

REM ECHO Checking !INF! ...

SET "VCHDIR=%WORKING_DIR%ZCHECK_OUT"

SET "CHKF=!VCHDIR!\CHECK_!VFS!.CSV"

REM Check if file is in use
2>NUL (CALL; >>"!CHKF!") || (
ECHO __ ERROR - Check output file is in use, close CHECK_!VFS:"=!.CSV to re-generate it 
PAUSE)

(CALL; >>"!CHKF!") && (

(ECHO Checking !VFS! at %DATE% %TIME%) > !CHKF!

(ECHO. & ECHO File modified date ...) >> !CHKF!
FOR %%A in (%FNAME%.TXT) DO SET MOD_TIME=%%~tA
(ECHO !MOD_TIME!) >> !CHKF!

(ECHO. & ECHO Reporting date ...) >> !CHKF!
"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==2 {print $4}" !INF! > FILE_CHECK.TMP
TYPE FILE_CHECK.TMP >> !CHKF!
SET /P V_RDATE=<FILE_CHECK.TMP
IF "!V_RDATE!" NEQ "!REP_DATE!" (
ECHO. & ECHO __ CHECK REPORTING DATE
SET "IS_FILE_OK=N"
)

(ECHO. & ECHO Number of data rows ...) >> !CHKF!
"%GAWK_PATH%\gawk" "END {print (NR - 2)}" %FNAME%.TXT > FILE_CHECK.TMP
TYPE FILE_CHECK.TMP >> !CHKF!
SET /P V_DROW=<FILE_CHECK.TMP

(ECHO. & ECHO Footer row count ...) >> !CHKF!
"%GAWK_PATH%\gawk" -F "%OSEP%" "END {print ($2+0)}" !INF! > FILE_CHECK.TMP
TYPE FILE_CHECK.TMP >> !CHKF!
SET /P V_FROW=<FILE_CHECK.TMP

IF "!V_DROW!" NEQ "!V_FROW!" (
ECHO. & ECHO __ CHECK ROW COUNT
SET "IS_FILE_OK=N"
)

(ECHO. & ECHO Number of columns ...) >> !CHKF!
"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==3 {print NF}" !INF! >> !CHKF!

(ECHO. & ECHO Number of characters in rows ...) >> !CHKF!
"%GAWK_PATH%\gawk" "NR==1 {len=length($0); print len; print (len+0) > \"FILE_CHECK1.TMP\"} NR==2 {len=length($0); print len; print (len+0) > \"FILE_CHECK2.TMP\"} (len > length($0) || len < length($0)){print \"__ CHECK ROW LENGTH - Row num:\" NR \", Expected len:\" len \", Actual len:\" length($0)}" %FNAME%.TXT >> !CHKF!

SET /P V_ROWLEN1=<FILE_CHECK1.TMP
SET /P V_ROWLEN2=<FILE_CHECK2.TMP
IF "!V_ROWLEN1!" NEQ "!V_ROWLEN2!" {
ECHO. & ECHO __ CHECK ROW LENGTH - HEADER AND DATA
SET "IS_FILE_OK=N"
)
DEL /F FILE_CHECK1.TMP FILE_CHECK2.TMP

SET VFWTOTAL=0
FOR %%X IN (!FWIDTH!) DO (
	SET /A VFWTOTAL=!VFWTOTAL!+%%X
)

(ECHO. & ECHO Total length of FWIDTH ... & ECHO !VFWTOTAL!) >> !CHKF!
IF "!V_ROWLEN2!" NEQ "!VFWTOTAL!" (
ECHO. & ECHO __ CHECK ROW LENGTH - SPECS WIDTH TOTAL NOT MATCHING DATA
SET "IS_FILE_OK=N"
)

IF "!FUNIQUE!" NEQ "N" (
(ECHO. & ECHO Find Unique ...) >> !CHKF!
FOR %%A IN (!FUNIQUE!) DO (
REM SET "VUNIKEY=!VUNIKEY!$%%AFS"
"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{print \"Unique \" $%%A FS \" count\"; next} (!FILTER! && !FILTER_CRI!){arr[$%%A]+=1} END{for(i in arr) {print i FS arr[i]; cnt++}; print cnt \" rows\";}" !INF! >> !CHKF!
)
REM End of FUNIQUE block
)

SET "VARKEY="
IF "!FPKEY!" NEQ "N" (
(ECHO. & ECHO Find duplicates ...) >> !CHKF!
FOR %%A IN (!FPKEY!) DO (
	SET "VARKEY=!VARKEY!$%%AFS"
)

REM "%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{print !VARKEY!}" !INF! >> !CHKF!
"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{print !VARKEY! \" count\"; next} !FILTER!{arr[!VARKEY!]+=1} END{for(i in arr) if(arr[i]>1){print i arr[i]; cnt++}; print cnt \"rows\"; print (cnt+0) > \"FILE_CHECK.TMP\" }" !INF! >> !CHKF!
SET /P V_DUPCNT=<FILE_CHECK.TMP
IF "!V_DUPCNT!" NEQ "0" (
ECHO. & ECHO __ CHECK FPKEY AND DUPLICATE VALUES
SET "IS_FILE_OK=N"
)

REM Find rows with blank critical fields and create check file. Applies both FILTER and FILTER_CRI to pick the rows for critical field checks
IF "!FCRITICAL!" NEQ "N" (
	(ECHO. & ECHO Check critical cols ...) >> !CHKF!
	REM ECHO "!FCRITICAL!" | "%GAWK_PATH%\gawk" -F "#" "{for(i=1;i<=NF;i++) print $i;}" > TSTFIL.TMP
	REM ECHO "%GAWK_PATH%\gawk" "BEGIN{split(\""!FCRITICAL!"\",arr,"#");for(i in arr) print arr[i];}"
	REM "BEGIN{split("!FCRITICAL!";arr;\"#\"); for(i in arr) print arr[i];}
	REM ECHO "!FCRITICAL!" | "%GAWK_PATH%\gawk" -F "#" "{for(i=1;i<=NF;i++) print $i;}"
	
	SET "VCTYPE=N"
	
	ECHO "!FCRITICAL!" | FINDSTR "#" >NUL && SET "VCTYPE=Y" || SET "VCTYPE=N"
	
	IF "!VCTYPE!" EQU "N" (
	
	FOR %%A IN (!FCRITICAL!) DO (
		SET "VAL=%%A"
		"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{col = \"Check \" $!VAL! \"[C\" !VAL! \"] blanks \" ; hdr=!VARKEY!; found=0; print $!VAL! > \"FILE_CHECK1.TMP\"; next} (!FILTER!) && (!FILTER_CRI!) && ($!VAL! ~ /^^[[:space:]0]*$/) {found+=1; \" rows\"; print (found+0) > \"FILE_CHECK.TMP\" }" !INF! >> !CHKF!
		SET /P V_CRIFLD=<FILE_CHECK1.TMP
		SET /P V_CRICNT=<FILE_CHECK.TMP
		IF "!V_CRICNT!" NEQ "0" (
			ECHO. & ECHO __ CHECK CRITICAL FIELD !V_CRIFLD! [COL !VAL!]
			SET "IS_FILE_OK=N"
			)
		)
	REM End of check VCTYPE EQU N block
	)
	
	IF "!VCTYPE!" NEQ "N" (
	
	REM SET "FCRITICAL=16 #36 #56:($7<=$5) # 17 # 2 # 60:($58 ~ /USD/)"
	REM SET "FCRITICAL=5:($4=="B" && $3==4)#6:($12<>$11 || $5==1)#7:($7<=$5) # 21: #abc# 9:($10>=-$11)"
	
	FOR /F "tokens=* USEBACKQ" %%A IN (`ECHO "!FCRITICAL!" ^| "%GAWK_PATH%\gawk" -F "#" "{for(i=1;i<=NF;i++) {if(i==1) j=substr($i,2); if(i==NF) j=substr($i,1,length($i)-2); if(i>1 && i<NF) j = $i; print j;}}"`) DO (
	
	REM ECHO. & ECHO Var A aa%%A b
	
	SET "VAL=%%A"
	SET "VFCOND=!VAL:*:=!"
	
	FOR /F "tokens=1 delims=:" %%G IN ("!VAL!") DO (
		SET "VFIELD=%%G"
	)
	
	REM ECHO vfield x!VFIELD!yy
	REM ECHO vfield 2 x!VFCOND!zz
	REM IF !VFIELD! EQU !VFCOND! (ECHO NOT SAME) ELSE (ECHO SAME)
	REM ECHO "!VAL!" | FINDSTR "[0-9]" >NUL && ECHO Found || Echo Not found
	
	IF !VFIELD! EQU !VFCOND! (
	REM ECHO Here 111 a!VFIELD!b c!VAL!d e!VFCOND!f
	"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{col = \"\nCheck \" $!VAL! \"[C\" !VAL!\"] blanks \" ; hdr=!VARKEY! ; found=0; print $!VAL! > \"FILE_CHECK1.TMP\"; next} (!FILTER!) && (!FILTER_CRI!) && ($!VAL! ~ /^^[[:space:]0]*$/) {found+=1; if(found==1){print col; print hdr}; print !VARKEY!} END{if(found>0) print found \" rows\"; print (found+0) > \"FILE_CHECK.TMP\" }" !INF! >> !CHKF!
	SET /P V_CRIFLD=<FILE_CHECK1.TMP
	SET /P V_CRICNT=<FILE_CHECK.TMP
	IF "!V_CRICNT!" NEQ "0" (
		ECHO. & ECHO __ CHECK CRITICAL FIELD !V_CRIFLD! [COL !VAL!]
		SET "IS_FILE_OK=N"
		)
)

IF !VFIELD! NEQ !VFCOND! (
	REM ECHO Here 222 a!VFIELD!b c!VAL!d e!VFCOND!f
	"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{col = \"\nCheck \" $!VFIELD! \"[C\" !VFIELD! \"] blanks \" ; hdr=!VARKEY! ; found=0; print $!VFIELD! > \"FILE_CHECK1.TMP\"; next} (!FILTER!) && (!FILTER_CRI!) && (!VFCOND!) && ($!VFIELD! ~ /^^[[:space:]0]*$/) {found+=1; if(found==1){print col; print hdr}; print !VARKEY!} END{if(found>0) print found \" rows\"; print (found+0) > \"FILE_CHECK.TMP\" }" !INF! >> !CHKF!
	SET /P V_CRIFLD=<FILE_CHECK1.TMP
	SET /P V_CRICNT=<FILE_CHECK.TMP
	IF "!V_CRICNT!" NEQ "0" (
		ECHO. & ECHO __ CHECK CRITICAL FIELD !V_CRIFLD! [COL !VFIELD!]
		SET "IS_FILE_OK=N"
		)
)

REM End of For loop
)

REM End of check VCTYPE NEQ N block
)

REM End of check FCRITICAL block
)

REM End of check FPKEY block
)

REM Sumkey used for sorting and subtotals
IF "%FSUMKEY%" NEQ "N" (

REM ECHO. & ECHO + Sort and compute subtotals ...

SET "VARKEY="
FOR %%A IN (!FSUMKEY!) DO (
	SET "VARKEY=!VARKEY!$%%AFS"
)

REM End of check FSUMKEY
)

IF "!VARKEY!" NEQ "" (

REM Check if file is in use
2>NUL (CALL; >>"!VCHDIR!\SORT_!VFS!.CSV") || (
ECHO Warning: Sort output is in use, close SORT_!VFS:"=!.CSV to re-generate it
PAUSE)

"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{hdr=$0; next} {arr[NR]=!VARKEY!FS NR RS$0} END{n=asort(arr); print hdr; for(k=1;k<=n; k++) {sub(\".*\"RS,\"\",arr[k]); print arr[k]}}" !INF! > !VCHDIR!\SORT_!VFS!.CSV

REM FSIGN and FSUMAMT used
IF "%FSUMAMT%" NEQ "N" (

(ECHO. & ECHO Subtotals ...) >> !CHKF!

IF "%FSIGN%" NEQ "N" (
	SET "FSIGN=$!FSIGN!"
)

IF "%FSIGN%" EQU "N" (SET "FSIGN=+")

"%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1{print !VARKEY! \" Subtotal\"; total=0} !FILTER!{CONVFMT=\"%%.20g\";v=(($%FSUMAMT%)+0);arr[!VARKEY!]+=(((!FSIGN! 1)+0)*(v))} END{for (i in arr) {print i arr[i]; cnt++; total+=(arr[i]+0)}; print cnt \" rows\"; print (total+0) > \"FILE_CHECK.TMP\" }" !VCHDIR!\SORT_!VFS!.CSV > FILE_NAME.TMP && (TYPE FILE_NAME.TMP >> !CHKF!)
SET /P V_TOTAL=<FILE_CHECK.TMP
IF "!V_TOTAL!" EQU "0" (
ECHO. & ECHO __ CHECK SUBTOTALS - TOTAL IS ZERO
SET "IS_FILE_OK=N"
)

REM Cleanup Files
IF EXIST !VCHDIR!\SORT_!VFS!.CSV (
	DEL /F !VCHDIR!\SORT_!VFS!.CSV
)

IF EXIST FILE_CHECK.TMP (
	DEL /FILE_CHECK.TMP
)

IF EXIST FILE_CHECK1.TMP (
	DEL /F FILE_CHECK1.TMP
)

SET VSUBTF=DEAL_SUBTOTALS.CSV
REM Check if file is in use
2>NUL (CALL; >>"!VSUBTF!") || (
ECHO Warning: Subtotal output is in use, close SUBTOTALS%SUFFIX:"=%.CSV to re-generate it
PAUSE)

REM Delete any leftover file from previous program run
IF NOT EXIST !VPRCTMP! (
IF EXIST !VSUBTF! (
	DEL /F !VSUBTF!
)
)

IF NOT EXIST !VSUBTF! (
	ECHO Subtotals %SUFFIX% on %DATE% %TIME% > !VSUBTF!
)

REM ######################################
REM CUSTOM LOGIC - If file contains GLBAL skip subtotal printing to common files.
IF x"!VFS!" EQU x"!VFS:GMPDGLBAL=!" (
REM ########################################

(ECHO. & ECHO !VFS!) >> !VSUBTF!
TYPE FILE_NAME.TMP >> !VSUBTF!

REM End of GLBAL in name check
)
REM End of FSUMAMT check block
)

REM End of check VARKEY
)

REM (ECHO. & ECHO First data row ...) >> !CHKF!
REM "%GAWK_PATH%\gawk" "FNR==2 { print $0 }" %FNAME%.TXT >> !CHKF!

(ECHO. && ECHO -- End of checks --) >> !CHKF!

REM CALL :DEQUOTE !VFS!

SET "VFS=!VFS:"=!

IF "!IS_FILE_OK!" EQU "N" (
CD ZCHECK_OUT
REN CHECK_!VFS!.CSV ERROR_!VFS!.CSV
CD ..
ECHO. & ECHO __ !VFS! HAS #ERROR#
)

IF "!IS_FILE_OK!" EQU "Y" (
CD ZCHECK_OUT
REN CHECK_!VFS!.CSV OK_!VFS!.CSV
CD ..
ECHO. & ECHO __ !VFS! IS OK
)

REM End of file in use check block
)

REM Following is end of DO_CHECK block
)

IF /I %DO_SEARCH% EQU Y (

IF "%SEARCH_STR%" NEQ "" (
CALL :TRIM x#zy%SEARCH_STR% VSEARCH

SET "VSEARCH=!VSEARCH:x#zy=!"

IF x"!VSEARCH!" NEQ x"" (

MKDIR ZSEARCH_OUT 2>NUL

SET "VSHDIR=%WORKING_DIR%ZSEARCH_OUT"

SET "SRCHF=!VSHDIR!\SEARCH%SUFFIX%_!VSEARCH!.CSV"

REM Set VARKEY again as fie checks can be off

IF "%FPKEY%" NEQ "N" (

REM Check if file is in use
2>NUL (CALL; >>"!SRCHF!") || (
ECHO Warning: Search output is in use, close SEARCH%SUFFIX:"=%_!VSEARCH:"=!.CSV to re-generate it
PAUSE)

SET "VARKEY="
FOR %%A IN (!FPKEY!) DO (
SET "VARKEY=!VARKEY!$%%AFS" )
SET "VARKEY=!VARKEY:~0,-2!"
)

IF NOT EXIST !VPRCTMP! (
IF EXIST !SRCHF! (
	DEL /F !SRCHF!
)
)

IF NOT EXIST !SRCHF! (
	(ECHO Search results for "!VSEARCH!" at %DATE% %TIME%) > !SRCHF!
)

IF NOT EXIST !INF! (
	ECHO File !INF! not found, search aborted
	EXIT /B
)

REM Find search string

IF "!VARKEY!" EQU "" (
	SET "VARKEY=$0"
)

ECHO ---
(ECHO. & ECHO Search !INF!) >> !SRCHF!
REM ECHO Searching !INF! for !VSEARCH! ...
REM "%GAWK_PATH%\gawk" -F "%OSEP%" "FNR==1 { print !VARKEY! }" !INF! > FILE_NAME.TMP
"%GAWK_PATH%\gawk" -F "%OSEP%" "BEGIN{IGNORECASE = 1} FNR==1 {print !VARKEY!; next} /!VSEARCH!/ {print !VARKEY!; cnt++} END{if(cnt>0) print cnt \" rows\"}" !INF! > FILE_NAME.TMP && (TYPE FILE_NAME.TMP >> !SRCHF! && TYPE FILE_NAME.TMP) && (ECHO --- && ECHO + Search done) || (ECHO --- && ECHO + Search done, file writing failed, please close !SRCHF! if in use)

REM End of FPKEY check block
)

REM End of SEARCH_STR check
)

REM End of Search block
)

ECHO %FNAME%.TXT >> !VPRCTMP!

REM End of If exist TXT block
)

EXIT /B

:AFTER_PROCESS
REM To compute final subtotals

IF /I %DO_CHECK% EQU Y (

SET VSUBTF=DEAL_SUBTOTALS.CSV


REM ##########################
REM Custom logic to change suffix
SET SUFFIX=_HK
REM CUSTOM LOGIC - first three fields, second field numner, sum of fourth
SET "VHDIR=CCY,COST_CTR,NOTIONAL_GL_ACC,SUM"
SET "VARKEY=$1FS$2FS$3FS"
SET "VFILTER=($2+0)==$2"
SET FSUMAMT=4
REM ##########################

"%GAWK_PATH%\gawk" -F "%OSEP%" "{arr[NR]=!VARKEY! NR RS$0} END{nsort(arr); for(k=1;k<=n;k++) {sub(\".*\"RS,\"\",arr[k]); print arr[k]}}" !VSUBTF! > ALLSORT_%SUFFIX%.CSV

"%GAWK_PATH%\gawk" -F "%OSEP%" "BEGIN{print \"!VHDIR!\"} !VFILTER!{CONVFMT=\"%%.20g\";v=(($%FSUMAMT%)+0);arr[!VARKEY!]+=(v+0)} END{for(i in arr) {print i arr[i]; cnt++}; print cnt \" rows\"}" ALLSORT_%SUFFIX%.CSV > ALLSUBTOTAL.CSV

DEL /F ALLSORT_%SUFFIX%.CSV
)

REM This subroutine shows end time and final counter for successfuk files
ECHO. & ECHO ## Process end time = %TIME% ##

REM Set file count
FOR /F "tokens=* USEBACKQ" %%F IN (`%GAWK_PATH%\gawk "END {print (NR)}" PROCESSED.TMP`)
DO (
	SET FCNT=%%F
)
ECHO. & ECHO Successfully processed %FCNT% file(s).

REM This subroutine does the clean up of temp files

IF EXIST PROCESSED.TMP (
	DEL /F PROCESSED.TMP
)

IF EXIST FILE_NAME.TMP (
	DEL /F FILE_NAME.TMP
)

IF EXIST FILE_CHECK.TMP (
	DEL /F FILE_CHECK.TMP
)

REM Press any key to continue prompt
ECHO. && PAUSE
EXIT /B

:TRIM
SET %2=%1
EXIT /B

:IS_NUMBER_SPACE
REM ECHO %1 | FINDSTR /R "^[0-9]*$" && SET %2=Y || SET %2=N
ECHO %~1 | "%GAWK_PATH%\gawk" "{if($0 ~ /^[0-9[:space:]N]+$/){print \"Y\";} else {print \"N\"}}" > TINS1.TMP
SET /P %2=<TINS1.TMP
DEL /F TINS1.TMP
EXIT /B

:END
EXIT /B

REM ******************************



	

	
	
	

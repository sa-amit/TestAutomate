:ABOUT
REM This is to showcase script based Automation Tool for Regression testing, based on gawk

:AUTHOR
REM v1 Tool   - Amit Saxena
REM v1 Config - Amit Saxena

@ECHO OFF & REM Set Debugging Off
SETLOCAL EnableDelayedExpansion
CLS & COLOR F0 & REM Clear screen and set colour

:README
REM Note - Any line starting with REM is a remarks or comment line. It is suggested to use Notepad++ for syntax highlighting.
REM Note - This script does not modify original text files to be tested. However it is suggested to keep a backup of original for critical files.
REM Note - Save this script with .cmd extension in a Windows machine, in same folder as TXT files which need to be parsed or checked. 
REM Note - Users may modify :SETTINGS and :PARSE sections to modify settings or set file config before execution.


:SETTINGS
REM ###### User to edit this section to set the script ##########

REM Edit - Set the suffix of the CSV files as per requirement
SET "SUFFIX=_TEST"
SET "SUFFIX1=_TEST"

REM Edit - Set the output file separator
SET "OSEP=,"

REM Whether or not to do the parsing
SET "DO_PARSE=N"

REM Whether or not to do the file checks
SET "DO_CHECK=Y"

REM Whether or not to do the search
SET "DO_SEARCH=Y"

REM Edit - Set the working folder if different from the one where this script is placed, presently set to current directory %~dp0
SET "WORKING_DIR=%~dp0"
cd /d "%WORKING_DIR%"

REM Edit - Set the remote or local path where gawk.exe is placed
SET "GAWK_PATH=D:\gawk"
CALL LIB.BAT :CHECK_GAWK_PATH

REM Edit - Set to Y to check and strip the input files for pre-existing csv file separator in tab limited data before parsing
REM Edit - Set to N if you are sure that there are no pre-existing csv file separator 
SET "DO_STRIP_OSEP=N"

REM Edit - Set source and destination file names, to be displayed for info
SET "INFO_SRC=SRC1"
SET "INFO_DST=SRC2"

REM ############ End of script variable settings #################

CALL :BEFORE

REM ########### User to edit this section to set file names, header and widths ############
:PARSE
REM The TXT file prefix is represented by FNAME, File header by FHDR and File col widths by FWIDTH. Line continuation for long lines is carat ^ character.
REM Edit the FNAME, FHDR, FWIDTH for files within this section and then CALL :PROCESS for each. Delete the details of unnecessary files.

REM File 1 processing starts

REM ###############

REM Settings for individual files below -

REM Set file name match for first file
SET FNAME=EQUITY_ISSUE

REM Set file header for first file
SET FHDR = MAJOR_VERSION, LASTUPDATEDTIME, ISSUE_NAME, ACTIVE, ISIN, VALOREN, CUSIP, CINS, ASSET_CLASS, SECURITY_TYPE, ISO_CFI, ISO_CFI2015, SHARES_OUTSTANDING, ^
VOTES_PER_SHARE, CONVERSION_FACTOR, CONVERSION_RATIO, SHARES_PER_DEPOSITORY_RECEIPT

REM Set primary key for first file
SET FPKEY=1 2 3

REM Set critical columns which cannot be blank
SET FCRITICAL=1 2 3 5 12

REM Set key to find totals, N if not required
SET FSUMKEY=N

REM Set amount field to be summed up, N if not required
SET FSUMAMT=N

REM Set sign field for the amount if the sign for amount is in a separate column
SET FSIGN=N

REM Print unique values of these columns
SET FUNIQUE=10 11

REM Call the parsing subroutine
CALL :PROCESS

REM Done with first file !

REM Input details of second file below
SET FNAME=BOND_ISSUE

SET FHDR = MAJOR_VERSION, LASTUPDATEDTIME, ISSUE_NAME, ACTIVE, ISIN, VALOREN, CUSIP, CINS, ASSET_CLASS, SECURITY_TYPE, ISO_CFI, ISO_CFI2015, SHARES_OUTSTANDING, ^
VOTES_PER_SHARE,CONVERSION_FACTOR, CONVERSION_RATIO, MIN_TRADE_SIZE, MATURITY_DATE

SET FPKEY=1 2 3

SET FCRITICAL=1 2 3 5 12

SET FSUMKEY=N

SET FSUMAMT=N

SET FSIGN=N

SET FUNIQUE=10 11

CALL :PROCESS

REM Input details of third file below, and so on
REM SET FNAME=OPTION_LISTING

REM ....


REM ######### End of file settings #########

CALL :AFTER
EXIT

:BEFORE
REM Keep the following line to show info about variables
CALL LIB.BAT :SHOW_INFO

REM CHOICE /c:YN /n /t 3 /d y /m:"Enter Y to proceed N to exit, 3 sec wait : "
REM IF ERRORLEVEL 2 EXIT

IF /I %DO_SEARCH% EQU Y (
	REM Request user to provide string to search
	ECHO.
	SET /P SEARCH_STR="Enter string to be searched across files [Enter to skip]: "
	ECHO.
)

CALL LIB.BAT :BEFORE_PROCESS
EXIT /B

:PROCESS
CALL LIB.BAT :FUN_PROCESS
CALL :RESET_VAR
EXIT /BAT

:RESET_VAR
SET FNAME=N
SET FWIDTH=N
SET FHDR=N
SET FPKEY=N
SET FCRITICAL=N
SET FSUMKEY=N
SET FSIGN=N
SET FSUMAMT=N
SET FUNIQUE=N
EXIT /B

:AFTER
REM ## Keep the following line - must be called once after all configs and parsing ends ## 
CALL TEST_LIBRARY.BAT :AFTER_PROCESS
EXIT

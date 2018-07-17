#!/bin/sh

# Copyright (c) 2018 ARPA Lazio <matteo.morelli@gmail.com>
# SPDX-License-Identifier: EUPL-1.2

# This script recover data from ecomanagerweb postgreSQL databases
# It needs in input start time and end time
# This is a big rewrite and merge of two different script

# --- START of User configuration parameter
# DB parameter
PSQLBIN=/path/to/psql.exe
DB_SERVER="ip or nameserver"
DB_PORT="5432"
USR="username"
DATABASE="database_name"
# Working directory
WORK=$(pwd)
# Debug option if value is not 0 temporary files are kept after the run
DEBUG=0
# --- END of User configuration parameter
# Script version 
VERSION="1.0.0"

# A function to print usage instruction
function print_help(){
	echo "Usage: ./dbDownload.sh  -t [e|i] -s [AAAA/MM/GG] -e [AAAA/MM/GG] -o <OutputFile>"
	echo "OPTION:"
	echo "-t [e|i]"
	echo "-s [AAAA/MM/GG] is Starting day"
	echo "-e [AAAA/MM/GG] is Ending day"
	echo "-o <OutputFile> Optional filename, if nothing is given an automatic "
	echo "   name is generated and file is created in current dir"

	echo "DESCRIPTION"
	echo "-t Use 0 to download chemical data in standard ecomanager format."
	echo "   Database fields NETCD,STATCD,PARAMCD,ISTANZACD,DAYDT,HOURAV,VFLAGCD"
	echo "   Use 1 to download chemical data for infoaria project format."
	echo "   Database fields NETCD,STATCD,PARAMCD,ISTANZACD,DAYDT,HOURAV,VFLAGCD,HOURST"
}


function err() {
	echo "|E| [$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}


##############################################
# Function to chek valid format of input date
# Globals:
#	None
# Arguments:
# 	A date of format YYYY/MM/DD
# Returns:
#	Exit status of 1 if date is of invalid format
##############################################
function check_valid_date(){
	local day=$1
	if [[ -z "$day" ]]; then 
		exit 1;
	fi
	if [[ ${#day} -ne 10 ]]; then
	    err 'Invalid time format: '$day
	    exit 1
	fi
	testDate=$(echo $day | grep -c '^[1-2][0-9][0-9][0-9]/[0-1][0-9]/[0-3][0-9]$')
	if date -d "${day:0:10}" >/dev/null 2>&1; then
	    if [[ $testDate -ne 1 ]]; then
	        err 'Invalid time format: '$day
	        exit 1
	    fi
	fi
}


##############################################
# Function to chek that user input is a valid
# download type ( i or e ).
# Globals:
#	None
# Arguments:
# 	String
# Returns:
#	Exit status of 1 if invalid type passed
##############################################
function check_dwl_type() {
	local type_variable=$1
	if [[ -z "$type_variable" ]]; then
		exit 1
	fi
	if [[ ${#type_variable} -ne 1 ]]; then
	    err 'Invalid download format: '$type_variable
	    exit 1
	fi
	if [[ "$type_variable" != "e" && "$type_variable" != "i" ]]; then
	    err 'Invalid download format: '$type_variable
	    exit 1
	fi
}


##############################################
# Function to set which query must be executed
# download type ( i or e ).
# Globals:
#	None
# Arguments:
# 	query type = i or e
#   start day
#   end day
# Returns:
#	on success return the query
#   on failure exit status of 1
##############################################
function set_query() {
	local query_type=$1
	local i_day=$2
	local e_day=$3
	if [[ -z "$query_type" ]]; then
		exit 1
	fi
	#TODO(matteo.morelli@gmail.com): make netcd filtering flexible with user input
	case $query_type in
		e)
		  readonly DB_QUERY="select NETCD,STATCD,PARAMCD,ISTANZACD,DAYDT,HOURAV,VFLAGCD from TDHOUR where NETCD NOT IN (6,7) and DAYDT between '"$i_day"0100' and '"$e_day"2400';"
		  ;;
		i)
		  readonly DB_QUERY="select NETCD,STATCD,PARAMCD,ISTANZACD,DAYDT,HOURAV,VFLAGCD,HOURST from TDHOUR where NETCD NOT IN (6,7) and DAYDT between '"$i_day"0100' and '"$e_day"2400'";
		  ;;
		*)
		  err 'Invalid download format: '$query_type
	      exit 1
	      ;;
	esac
	echo $DB_QUERY	
}


# ---MAIN SCRIPT---
# Get PID id for file uniqueness
IDNUM=$(date +%s)$$

if [[ $# -eq 0 ]]; then
  err 'No parameter passed, type -h for help'
  exit 1
fi
# Getting launcher parameter
# Get and check command line arguments
n_opt=0
shift $((OPTIND-1))
if [[ $# -eq 0 ]]; then
    err 'No parameter passed, type -h for help'
    exit 1
else
    while getopts "s:e:o:ht:" OPT; do     
        case $OPT in
            s)
              SDAY=$OPTARG
              check_valid_date $SDAY
              ;;
            e)
			  EDAY=$OPTARG
			  check_valid_date $EDAY
			  ;;
			o)
			  FILE_OUT=$OPTARG
			  ;;
			t)
			  DWL_TYPE=$OPTARG
			  check_dwl_type $DWL_TYPE
			  ;;
            h)
			  print_help
			  exit 0
			  ;;
			* )
	       	  print_help
	          exit 1
	          ;;
        esac
        n_opt=$(( n_opt + 1))
    done                 
fi
# ---INITIAL CHECK---
# Check that fundamental value are declared
if [[ -z "$SDAY" || -z "$EDAY" || -z "$DWL_TYPE" ]]; then
	echo "|E| Missing mandatory parameter"
	exit 1
fi
if [ $(date -d "$SDAY" +%s) -gt $(date -d "$EDAY" +%s) ]; then
	echo "|E| INVALID time period selected"
	exit 1
fi
if [[ -z "$FILE_OUT" ]]; then
	FILE_OUT=$IDNUM'-datitot.txt'
fi
#---END INITIAL CHECK---

echo "|----- Ecomanager DB Exporter V. "$VERSION" -----|"
echo '|I| Operation starting at '$(date)
echo '|I| Working dir: '$WORK
echo "|I| Initializing data for DB Export"
echo "|I| Starting Day: "$SDAY
echo "|I| Ending Day: "$EDAY
echo "|I| File di Output: "$FILE_OUT
echo "|I| Query type: "$DWL_TYPE

# FILE_OUT check
if [ -e $FILE_OUT ]; then
	echo "|W| File "$FILE_OUT" already exist, it will be OVERWRITTEN."
	if [ ! -f $FILE_OUT ]; then
		err $FILE_OUT' is NOT a file, exiting.'
		exit 1
	fi

else 
	touch $FILE_OUT >& /dev/null
	T_ERR=$?
	if [ $T_ERR != 0 ]; then
		err 'Cannot create file '$FILE_OUT', exiting.'
		exit 1
	fi
fi
# END of FILE_OUT check

# Testing online server
echo "|I| Testing Server status, WAIT"
db_server_status=$(nc -z -w 10 ${DB_SERVER} ${DB_PORT} && echo 1 || echo 0)

# Now checking nc response
if [ $db_server_status -eq 1 ]; then
	echo '|I| Server '${DB_SERVER}' DB seems ONLINE'
else
	err 'Server '${DB_SERVER}' DB seems OFFLINE, EXITING'
	exit 1
fi

# Time operation
SDAY=$(date -d "$SDAY" +%Y%m%d)
EDAY=$(date -d "$EDAY" +%Y%m%d)

echo "|I| Beginning SQL query manipulation..."
#Adjust file query.sql for db query
QUERY=$(set_query $DWL_TYPE $SDAY $EDAY)

#Create SQL file for DB query
sqlinput=$IDNUM'-'$SDAY$EDAY'.sql'
echo -e $QUERY > $sqlinput
echo "\quit" >> $sqlinput
sql_out=$IDNUM-$SDAY$EDAY$DB_SERVER'.txt'

echo "|I| Beginning Query on Server"
echo "|I| This operation can take a WHILE, BE PATIENT"

#Do DB query
#------ Preparing DB query ----
echo "|I| Executing Query on DB Server..."
$PSQLBIN -h $DB_SERVER -p $DB_PORT -d $DATABASE -U $USR -f $sqlinput -o $sql_out
if [[ "$?" -ne 0 ]]; then 
	err 'Something bad quering server: '$DB_SERVER
	exit 1
fi

echo -n "|I| Checking output file..."
FILEL=$(wc -l $sql_out | gawk '{print $1}')
echo "DONE"
if [ $FILEL -gt 10 ]; then
	#Launch AWK script for file impagination
	#gawk '{if( $5 != "" && $5 != "-------" && $ != "VFLAGCD" ) print $0;}' $IDNUM'-'$SDAY$EDAY'ROMA.txt' >> $FILE_OUT
	gawk 'BEGIN { OFS = "\t"; FS = "|" } ;
		  {if( $5 != "" ) print $1,$2,$3,$4,$5,$6,$7;}' $sql_out > $FILE_OUT
	if [[ "$?" -ne 0 ]]; then 
		err 'Something bad with '$sql_out
		exit 1
	fi
	echo "|I| output File usable - Data ADDED to "$FILE_OUT
else
	echo "|E| output File unusable - SKIPPING"
	exit 1
fi

if [ $DEBUG -eq 0 ]; then
	echo -n "|I| Erasing temporary file..."
	/usr/bin/rm $sql_out
	/usr/bin/rm $sqlinput
	echo "DONE"

else
	echo "|W| Leaving temporary files where they are"

fi

echo "|I| Operation completed successful at "$(date)

#Everything OK! Nice exit
#Bye bye.
exit 0

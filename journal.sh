#!/bin/bash

#TODO flo: year should be possible with 2022 and 22
#TODO flo: month should also be possible with 1 and 01
#TODO flo: day shoudl also be possible with 1 and 01

function usage() {
    cat << EOF >&2
Usage: $0 
        -> complete journal
       $0 --generate
        -> generate journal entry for current day
       $0 [-y|--year]=<year>
        -> journal for specific year
       $0 [-y|--year]=<year> [-m|--month]=<month>
        -> journal for specific month in year
       $0 [-y|--year]=<year> [-m|--month]=<month> [-d|--day]=<day>
        -> journal for specific day in year

EOF
    exit 1
}

function illegalArgument() {
    echo "illegalArgument"
    exit 2
}

function generateJournalEntry() {
    journalEntryYear="$(date +%Y)"
    journalEntryMonth="$(date +%m)"
    journalEntryCurrentMonthPath="./$journalEntryYear/$journalEntryMonth"

    if [ ! -d $journalEntryCurrentMonthPath ]; then
        mkdir -p $journalEntryCurrentMonthPath
    fi

    journalEntryForCurrentDay="$journalEntryCurrentMonthPath/$(date +%d).txt"

    if [ -f $journalEntryForCurrentDay ]; then
        echo "ATTENTION: journal entry for $(date +%d.%m.%Y) is already present, please resolve conflict"
        exit 3
    fi

    echo $(date "+%d.%m.%Y - %A") > $journalEntryForCurrentDay
    headerCharacterCount=$(wc -c < $journalEntryForCurrentDay)
    printf '%0.s#' $(seq 1 $(($headerCharacterCount-1))) >> $journalEntryForCurrentDay
    printf "\n\n" >> $journalEntryForCurrentDay
    printf -- "- \n" >> $journalEntryForCurrentDay
    printf "\n" >> $journalEntryForCurrentDay
    exit 0
}

function handleYearArgument() {
    yearChoice="${1#*=}"
}

function handleMonthArgument() {
    monthChoice="${1#*=}"
}

function handleDayArgument() {
    dayChoice="${1#*=}"
}

# handle illegal number of arguments
if [ "$#" -gt 3 ]; then
    usage
fi

# handle no argument passed into script, complete journal report
if [ "$#" -eq 0 ]; then
    find . -type f -name "*.txt" | sort -r | xargs cat   
    exit 0
fi

# handle argument --generate
if [ "$#" -eq 1 ] && [ "$1" == "--generate" ]; then
    generateJournalEntry
fi

# handle arguments passed into script, different journal reports
if [ "$#" -gt 0 ]; then
    while [ $# -gt 0 ]; do
        case "$1" in
            --year=*)
                handleYearArgument $1
                ;;
            -y=*)
                handleYearArgument $1
                ;;
            --month=*)
                handleMonthArgument $1
                ;;
            -m=*)
                handleMonthArgument $1
                ;;
            --day=*)
                handleDayArgument $1
                ;;
            -d=*)
                handleDayArgument $1
                ;;
            *)
                illegalArgument
        esac
        shift
    done
fi

# handle journal report for given year
if [ -n $yearChoice ] && [ -z $monthChoice ] && [ -z $dayChoice ]; then
    journalDirectory=./$yearChoice
    if [ -d $journalDirectory ]; then
        find $journalDirectory/* -type f -name "*.txt" | sort -r | xargs cat
        exit 0
    else
        printf "no journal entry for year: $yearChoice\n\n"
        exit 3
    fi
fi

# handle journal report for given year and month
if [ -n $yearChoice ] && [ -n $monthChoice ] && [ -z $dayChoice ]; then
    journalDirectory=./$yearChoice/$monthChoice
    if [ -d $journalDirectory ]; then
        find $journalDirectory/* -type f -name "*.txt" | sort -r | xargs cat
        exit 0
    else
        printf "no journal entry for year: $yearChoice - month: $monthChoice\n\n"
        exit 4
    fi
fi

# handle journal report for given year, month and day
if [ -n $yearChoice ] && [ -n $monthChoice ] && [ -n $dayChoice ]; then
    journalFile=./$yearChoice/$monthChoice/$dayChoice.txt
    if [ -f $journalFile ]; then
        cat $journalFile
        exit 0
    else 
        printf "no journal entry for year: $yearChoice - month: $monthChoice - day: $dayChoice\n\n"
        exit 5
    fi
fi

exit 0


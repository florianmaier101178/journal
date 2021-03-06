#!/bin/bash

function usage() {
    cat << EOF >&2
Usage: $0 
        -> complete journal piped to less
       $0 --books
        -> output read books to stdout
       $0 --bookRecommendations
        -> output book recommendations to stdout
       $0 --generate
        -> generate journal entry for current day
       $0 --output
        -> complete journal piped to stdout
       $0 --today
        -> edit todays journal entry
       $0 --lastentry
        -> edit last journal entry
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

function editTodaysJournalEntry() {
    journalEntryYear="$(date +%Y)"
    journalEntryMonth="$(date +%m)"
    journalEntryCurrentMonthPath="./$journalEntryYear/$journalEntryMonth"
    journalEntryForCurrentDay="$journalEntryCurrentMonthPath/$(date +%d).txt"

    if [ ! -f $journalEntryForCurrentDay ]; then
        echo "ATTENTION: journal entry for $(date +%d.%m.%Y) is not available, please generate it first"
        exit 7
    fi

    nvim $journalEntryForCurrentDay
    exit 0
}

# this opens the last entry before today in an editor
function editJournalLastEntry() {
    nvim $(tree -if . | grep txt | sort -r | head -n 2 | sed '1d')
    exit 0
}

function handleYearArgument() {
    yearChoice="${1#*=}"
    if [ ${#yearChoice} -eq 2 ]; then
        yearChoice=20$yearChoice
    fi
}

function handleMonthArgument() {
    monthChoice="${1#*=}"
    if [ ${#monthChoice} -eq 1 ]; then
        monthChoice=0$monthChoice
    fi
}

function handleDayArgument() {
    dayChoice="${1#*=}"
    if [ ${#dayChoice} -eq 1 ]; then
        dayChoice=0$dayChoice
    fi
}

# handle illegal number of arguments
if [ "$#" -gt 3 ]; then
    usage
fi

# handle no argument passed into script, complete journal report piped to less
if [ "$#" -eq 0 ]; then
    find . -type f -name "*.txt" | sort -r | \
        xargs -d $'\n' sh -c 'for arg do cat "$arg"; printf "########################################################################################################################\n\n" ; done' _ | less
    exit 0
fi

# handle read books report piped to stdout
if [ "$#" -eq 1 ] && [ "$1" == "--books" ]; then
    printf "read books:\n"
    printf "###########\n\n"

    find . -type f -name "*.txt" | sort -r | \
        xargs cat |  grep --no-group-separator -A1 "book:" | \
        grep -v "book:" | sort | uniq

    printf "\n"
    exit 0
fi

# handle book recommendations report piped to stdout
if [ "$#" -eq 1 ] && [ "$1" == "--bookRecommendations" ]; then
    printf "book recommendations:\n"
    printf "#####################\n\n"

    find . -type f -name "*.txt" | sort -r | \
        xargs cat |  grep --no-group-separator -A1 "book recommendation:" | \
        grep -v "book recommendation:" | sort | uniq

    printf "\n"
    exit 0
fi

# handle complete journal report piped to stdout
if [ "$#" -eq 1 ] && [ "$1" == "--output" ]; then
    find . -type f -name "*.txt" | sort -r | \
        xargs -d $'\n' sh -c 'for arg do cat "$arg"; printf "########################################################################################################################\n\n" ; done' _
    exit 0
fi

# handle argument --generate
if [ "$#" -eq 1 ] && [ "$1" == "--generate" ]; then
    generateJournalEntry
fi

# handle argument --today
if [ "$#" -eq 1 ] && [ "$1" == "--today" ]; then
    editTodaysJournalEntry
fi

# handle argument --lastentry
if [ "$#" -eq 1 ] && [ "$1" == "--lastentry" ]; then
    editJournalLastEntry
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
        exit 4
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
        exit 5
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
        exit 6
    fi
fi

exit 0


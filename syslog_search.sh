#!/bin/bash
#
# Syslog archive search script
# Alexander Ivashkin, August 2018
#

ScriptVersion='v. 1.8.1'

# Those constants are called "sensitive_" because they could contain sensitive data that should be removed by the anonymisation process.
#
# After anonymisation only this section would remain...
sensitive_Author="Alexander Ivashkin"
sensitive_DirectoryWithLogs="/var/data/syslog/"
sensitive_HostnamesExamples='
    router1
    NYC-switch.*4507
    London-WAN
    Texas.*ATM'
sensitive_PatternExamples='
    LINEPROTO-5-UPDOWN
    lineproto-5-updown
    %BGP
    bgp.*neighbor.*down
    Tunnel69
    OSPF.*10.10.10.10
    DAI-4-(?!DHCP) - for PCRE engine'
# There should be a sensitive section below this line... but you probably won't see it!
#


cat<<EOF
======================================================================
Welcome to the syslog search script $ScriptVersion
$sensitive_Author, August 2018
----------------------------------------------------------------------
EOF

# FUNCTIONS
#

# Make output more grammatical.
# Usage: choose_singular_or_plural NUMBER WORD_SINGULAR WORD_PLURAL
# Example: choose_singular_or_plural 99 balloon balloons
#       outputs: 99 balloons
choose_singular_or_plural()
{
    echo -n "$1 "
    [ ${1: -1} = "1" ] && echo $2 || echo $3
}

# Clean-up function to be used in the end and when catching SIGINT/SIGTERM
summarize_and_cleanup()
{
    if [ "$2" = "summarize" ]; then
        time_ElapsedSeconds=$(($(date +%s)-$time_Start))
        time_ElapsedHumanFriendly="$((time_ElapsedSeconds/60)) min $((time_ElapsedSeconds%60)) sec"
        totalLinesFound=$(($(cat $file_output | wc -l)-$file_outputHeaderSize))
        time_PerFile=$((time_ElapsedSeconds/$count_filesProcessed))

cat<<EOF
$1
Processed $( choose_singular_or_plural $count_filesProcessed file files ).
Script has helped you to find $( choose_singular_or_plural $totalLinesFound line lines ) of logs!
Time elapsed: $time_ElapsedHumanFriendly (ca. $time_PerFile seconds per file)
Exported output to $file_output.
Log file: $file_log
------------------------------
EOF

cat<<EOF>>$file_log
$1
Processed $( choose_singular_or_plural $count_filesProcessed file files ).
Found $( choose_singular_or_plural $totalLinesFound line lines ) of logs.
Time elapsed: $time_ElapsedHumanFriendly (ca. $time_PerFile seconds per file)
Exported output to $file_output.
EOF

    # No summary required (early abort)
    else
        echo $1 | tee -a $file_log
    fi

    [ -n "$old_IFS" ] && IFS=${old_IFS} || IFS=" "
    exec 2>&1
    exit
}

trap "summarize_and_cleanup 'Aborted by SIGINT.'" SIGINT
trap "summarize_and_cleanup 'Aborted by SIGTERM.'" SIGTERM

file_log="$(cd $(dirname $0) > /dev/null && pwd)/syslog_search.log"
exec 2>>$file_log

file_output="$(cd $(dirname $0) > /dev/null && pwd)/syslog_search.out"

cat<<EOF>>$file_log


======================================================================
Script started at $(date -u)
User: $(whoami)
System: $(uname -a)
BASH: $(bash --version | head -n 1)
EOF

cat<<EOF>$file_output
======================================================================
Script started at $(date -u)
EOF

# Checking for grep version.
# Order of preference: ext. grep -> basic grep -> PCRE
out_pcregrep=$(echo 696969 | pcregrep "\d{6}" 2>/dev/null)
out_egrep=$(echo 696969 | grep -E "[0-9]{6}" 2>/dev/null)
out_grep=$(echo 696969 | grep "[0-9]\{6\}" 2>/dev/null)

if [ "$out_egrep" = "696969" ]; then
    # We use newline instead of space due to different IFS in the end (to allow for spaces in filenames)
    cmd_grep=$'grep\n-Ei'
    echo 'Regular expressions flavour: extended grep (see https://www.unix.com/man-page/linux/1/grep/ for reference)'
    echo "Regexps: egrep" >> $file_log
elif [ "$out_grep" = "696969" ]; then
    cmd_grep=$'grep\n-i'
    echo 'Regular expressions flavour: grep (see https://www.unix.com/man-page/linux/1/grep/ for reference)'
    echo "Regexps: grep" >> $file_log
elif [ "$out_pcregrep" = "696969" ]; then
    cmd_grep=$'pcregrep\n-i'
    echo 'Regular expressions flavour: PCRE (see https://www.unix.com/man-page/Linux/3/pcresyntax/ for reference)'
    echo "Regexps: PCRE" >> $file_log
else
    summarize_and_cleanup 'FATAL ERROR. No grep found. ABORTING.'
fi

[ "$out_egrep" = "696969" ] && regexp_engines="egrep"; grep -V | head -n 1 >&2
if [ "$out_grep" = "696969" ]; then
    if [ -n "$regexp_engines" ]; then
        regexp_engines="$regexp_engines grep"
    else
        regexp_engines="grep"
        grep -V | head -n 1 >&2
    fi
fi
if [ "$out_pcregrep" = "696969" ]; then pcregrep -V | head -n 1 >&2; [ -n "$regexp_engines" ] && regexp_engines="$regexp_engines pcregrep" || regexp_engines="pcregrep"; fi

echo "Available regexps engines: $regexp_engines" | tee -a $file_log
echo ====================================================================== 


cd $sensitive_DirectoryWithLogs 2>/dev/null || summarize_and_cleanup 'FATAL ERROR: could not cd to $sensitive_DirectoryWithLogs. ABORTING.'

set -o pipefail
oldest_CiscoInfo=$(ls -tg --time-style=long-iso cisco_info* | tail -1 | sed -E 's/^.* [0-9]+ (2[0-9]{3}-[0-9]{2}-[0-9]{2}) .*$/\1/g' || echo NO LOGS)
oldest_CiscoCrit=$(ls -tg --time-style=long-iso cisco_crit* | tail -1 | sed -E 's/^.* [0-9]+ (2[0-9]{3}-[0-9]{2}-[0-9]{2}) .*$/\1/g' || echo NO LOGS)
oldest_Rmessages=$(ls -tg --time-style=long-iso rmessages* | tail -1 | sed -E 's/^.* [0-9]+ (2[0-9]{3}-[0-9]{2}-[0-9]{2}) .*$/\1/g' || echo NO LOGS)
oldest_Netscaler=$(ls -tg --time-style=long-iso netscaler* | tail -1 | sed -E 's/^.* [0-9]+ (2[0-9]{3}-[0-9]{2}-[0-9]{2}) .*$/\1/g' || echo NO LOGS)
set +o pipefail
count_CiscoInfo=$(ls cisco_info* | wc -l || echo 0)
count_CiscoCrit=$(ls cisco_crit* | wc -l || echo 0)
count_Rmessages=$(ls rmessages* | wc -l || echo 0)
count_NetScaler=$(ls netscaler* | wc -l || echo 0)


cat<<EOF>>$file_log
----------------------------------------------------------------------
OLDEST AVAILABLE LOGS
$(printf "%-16s %s\n" "Cisco info: " "$oldest_CiscoInfo ($count_CiscoInfo days ago)")
$(printf "%-16s %s\n" "Cisco critical: " "$oldest_CiscoCrit ($count_CiscoCrit days ago)")
$(printf "%-16s %s\n" "Rmessages: " "$oldest_Rmessages ($count_Rmessages days ago)")
$(printf "%-16s %s\n" "NetScaler: " "$oldest_Netscaler ($count_NetScaler days ago)")
----------------------------------------------------------------------
EOF

cat<<EOF

Note that this script can produce enormous amount of output. Use filtering carefully.
Moreover, it can take quite some time due to sheer amount of syslog data (especially with the NetScaler logs).
Caveat emptor. 
Be patient. You can always interrupt execution with a SIGINT (by pressing Ctrl-C) and the script would handle this correctly.

----------------------------------------------------------------------
OLDEST AVAILABLE LOGS
$(printf "%-45s %s\n" "Cisco info (severity 3-7): " "$oldest_CiscoInfo ($count_CiscoInfo days ago)")
$(printf "%-45s %s\n" "Cisco critical (severity 1-2): " "$oldest_CiscoCrit ($count_CiscoCrit days ago)")
$(printf "%-45s %s\n" "Rmessages (Arista and other weird devices): " "$oldest_Rmessages ($count_Rmessages days ago)")
$(printf "%-45s %s\n" "NetScaler (load balancers): " "$oldest_Netscaler ($count_NetScaler days ago)")
----------------------------------------------------------------------
EOF


[ "$count_CiscoInfo" -gt "0" -o "$count_CiscoCrit" -gt "0" ] && log_types="Cisco"
if [ "$count_Rmessages" -gt "0" ]; then [ -n "$log_types" ] && log_types="$log_types#rmessages" || log_types="rmessages"; fi
if [ "$count_NetScaler" -gt "0" ]; then [ -n "$log_types" ] && log_types="$log_types#NetScaler" || log_types="NetScaler"; fi
[ -z "$log_types" ] && summarize_and_cleanup "NO LOGFILES FOUND! ABORTING."

cat<<EOF

Please select the kind of logs you are interested in:

EOF

old_IFS=${IFS}
IFS="#"
exec 2>&1

log_types="$log_types#Change regexp engine (if you know what you are doing!)"
selection_done=0
while (( !selection_done )); do
PS3="Select logs:"
select log_type in $log_types;
do
    case $log_type in
        "Cisco")
            log_fileNamePattern='cisco*'
            echo "Searching in Cisco logs" | tee -a $file_log >> $file_output
            selection_done=1
            break
            ;;
        "rmessages")
            log_fileNamePattern='rmessages*'
            echo "Searching in rmessages logs" | tee -a $file_log >> $file_output
            selection_done=1
            break
            ;;
        "NetScaler")
            log_fileNamePattern='netscaler*'
            echo "Searching in NetScaler logs" | tee -a $file_log >> $file_output
            selection_done=1
            break
            ;;
        "Change regexp engine (if you know what you are doing!)")
            # $regexp_engines are also being printed as is, so we use space instead of hash
            IFS=" "
            PS3="Choose regexp engine:"
            select regexp_engine in $regexp_engines
            do
                case $regexp_engine in
                    "egrep")
                        cmd_grep=$'grep\n-Ei'
                        echo $'\nRegular expressions flavour: extended grep (see https://www.unix.com/man-page/linux/1/grep/ for reference)\n'
                        echo "Regexps changed by user to: $regexp_engine" >> $file_log
                        break
                        ;;
                    "grep")
                        cmd_grep=$'grep\n-i'
                        echo $'\nRegular expressions flavour: grep (see https://www.unix.com/man-page/linux/1/grep/ for reference)\n'
                        echo "Regexps changed by user to: $regexp_engine" >> $file_log
                        break
                        ;;
                    "pcregrep")
                        cmd_grep=$'pcregrep\n-i'
                        echo $'\nRegular expressions flavour: PCRE (see https://www.unix.com/man-page/Linux/3/pcresyntax/ for reference)\n'
                        echo "Regexps changed by user to: $regexp_engine" >> $file_log
                        break
                        ;;
                esac
            done
            PS3="Select logs:"
            IFS="#"
            break
    esac
done
done


cat<<EOF

Please select the range of logs:

EOF
PS3="Select log range:"
IFS="#"
log_ranges="Today#Last week#Last month#Hit me with your laser beams! (all of them)"
select log_range in $log_ranges;
do
    case $log_range in
        "Today")
            log_rangeDays=-1440
            break
            ;;
        "Last week")
            log_rangeDays=-11520
            break
            ;;
        "Last month")
            log_rangeDays=-46080
            break
            ;;
        "Hit me with your laser beams! (all of them)")
            log_rangeDays=0
            break
            ;;
    esac
done


cat<<EOF
Please input device hostname to search logs for.
Can be full, partial or with regexps.
Note: the hostname is case-insensitive
Examples:
$sensitive_HostnamesExamples

EOF

read -p 'Hostname: ' -r -e log_hostname

cat<<EOF

Please input search pattern. Again, it can be partial or with regexps.
Note: the pattern is case-insensitive
Examples:
$sensitive_PatternExamples

EOF

read -p 'Search pattern: ' -r -e log_pattern


echo "Hostname: $log_hostname" | tee -a $file_log >> $file_output
echo "Pattern: $log_pattern" | tee -a $file_log >> $file_output
echo "Log range: $(($log_rangeDays/-60/24)) days" | tee -a $file_log >> $file_output

exec 2>>$file_log

file_outputHeaderSize=$(cat $file_output | wc -l)
time_Start=$(date +%s)

trap "summarize_and_cleanup 'Aborted by SIGINT.' summarize" SIGINT
trap "summarize_and_cleanup 'Aborted by SIGTERM.' summarize" SIGTERM

# To catch spaces in filenames...
IFS="
"

if [ "$log_rangeDays" = "0" ]; then
    log_AllFiles=$( ls -t $log_fileNamePattern )
else
    log_AllFiles=$( find -daystart -mmin $log_rangeDays -name "$log_fileNamePattern" -print0 | xargs -0 ls -t )
fi

count_filesProcessed=0

for log_file in $log_AllFiles; do
    cat<<EOF
------------------------------
SEARCHING IN $log_file
------------------------------
EOF
    (gunzip -c $log_file 2>/dev/null || cat $log_file) | $cmd_grep "$log_hostname.*$log_pattern" | tee -a $file_output
    count_filesProcessed=$(($count_filesProcessed+1))
done

summarize_and_cleanup "DONE." summarize

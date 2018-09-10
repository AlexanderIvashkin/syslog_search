# syslog_search
A user-friendly and safe BASH script to search through a collection of files.

## Installation

Copy to your ~ and chmod +x syslog_search.sh

Edit the syslog_search.sh file with your syslog storage directory by updating this line:

    sensitive_DirectoryWithLogs="/var/data/syslog/"

## Usage

Just invoke it and it will show a menu!
An example:


```
======================================================================
Welcome to the syslog search script v. 1.8.1
Alexander Ivashkin, August 2018
----------------------------------------------------------------------
Regular expressions flavour: extended grep (see https://www.unix.com/man-page/linux/1/grep/ for reference)
Available regexps engines: egrep grep pcregrep
======================================================================

Note that this script can produce enormous amount of output. Use filtering carefully.
Moreover, it can take quite some time due to sheer amount of syslog data (especially with the NetScaler logs).
Caveat emptor. 
Be patient. You can always interrupt execution with a SIGINT (by pressing Ctrl-C) and the script would handle this correctly.

----------------------------------------------------------------------
OLDEST AVAILABLE LOGS
Cisco info (severity 3-7):                    2016-07-11 (791 days ago)
Cisco critical (severity 1-2):                2016-07-11 (791 days ago)
Rmessages (Arista and other weird devices):   2016-07-11 (791 days ago)
NetScaler (load balancers):                   2016-07-11 (791 days ago)
----------------------------------------------------------------------

Please select the kind of logs you are interested in:

1) Cisco
2) rmessages
3) NetScaler
4) Change regexp engine (if you know what you are doing!)
Select logs:1

Please select the range of logs:

1) Today
2) Last week
3) Last month
4) Hit me with your laser beams! (all of them)
Select log range:2
Please input device hostname to search logs for.
Can be full, partial or with regexps.
Note: the hostname is case-insensitive
Examples:

    router1
    NYC-switch.*4507
    London-WAN
    Texas.*ATM

Hostname: texas

Please input search pattern. Again, it can be partial or with regexps.
Note: the pattern is case-insensitive
Examples:

    LINEPROTO-5-UPDOWN
    lineproto-5-updown
    %BGP
    bgp.*neighbor.*down
    Tunnel69
    OSPF.*10.10.10.10
    DAI-4-(?!DHCP) - for PCRE engine

Search pattern: RATE
------------------------------
SEARCHING IN ./cisco_info
------------------------------
------------------------------
SEARCHING IN ./cisco_crit
------------------------------
------------------------------
SEARCHING IN ./cisco_crit.2018-09-09
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-09
------------------------------
------------------------------
SEARCHING IN ./cisco_crit.2018-09-08
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-08
------------------------------
------------------------------
SEARCHING IN ./cisco_crit.2018-09-07.gz
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-07.gz
------------------------------
------------------------------
SEARCHING IN ./cisco_crit.2018-09-06.gz
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-06.gz
------------------------------
Sep  6 08:12:25 texas-swi06-2950: Sep  6 08:12:24 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 243 packets received in 78 milliseconds on Gi5/40.
------------------------------
SEARCHING IN ./cisco_crit.2018-09-05.gz
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-05.gz
------------------------------
Sep  5 11:34:45 texas-swi06-2950: Sep  5 11:34:44 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 225 packets received in 77 milliseconds on Gi2/4.
Sep  5 11:34:45 texas-swi04-2950: Sep  5 11:34:44 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 128 packets received in 30 milliseconds on Gi4/17.
Sep  5 11:39:45 texas-swi06-2950: Sep  5 11:39:44 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 245 packets received in 565 milliseconds on Gi2/40.
Sep  5 11:39:45 texas-swi08-2950: Sep  5 11:39:44 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 179 packets received in 72 milliseconds on Gi8/13.
Sep  5 11:39:45 texas-swi04-2950: Sep  5 11:39:44 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 247 packets received in 88 milliseconds on Gi1/35.
Sep  5 11:44:40 texas-swi04-2950: Sep  5 11:44:39 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 234 packets received in 174 milliseconds on Gi1/10.
Sep  5 11:50:20 texas-swi06-2950: Sep  5 11:50:19 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 244 packets received in 569 milliseconds on Gi1/1.
------------------------------
SEARCHING IN ./cisco_crit.2018-09-04.gz
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-04.gz
------------------------------
Sep  4 21:47:15 texas-swi05-2950: Sep  4 21:47:14 GMT: %SW_DAI-4-PACKET_RATE_EXCEEDED: 470 packets received in 204 milliseconds on Gi1/15.
------------------------------
SEARCHING IN ./cisco_crit.2018-09-03.gz
------------------------------
------------------------------
SEARCHING IN ./cisco_info.2018-09-03.gz
------------------------------
DONE.
Processed 16 files.
Script has helped you to find 9 lines of logs!
Time elapsed: 0 min 51 sec (ca. 3 seconds per file)
Exported output to /home/alexander_ivashkin/syslog_search.out.
Log file: /home/alexander_ivashkin/syslog_search.log
------------------------------

```

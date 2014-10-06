#!/bin/bash

# This will take a file from an IANA established authroity (i.e. ARIN, AfriNIC,
# RIPE, etc) and covert the entire file to CIDR notation where possible. Some
# of the authorities have subnets borken down into non-CIDR possible notation
# for reasons of their own. These non-CIDR possible notations are discarded due
# to them being part of other blocks in the same file.

# Arguments
# The first argument is to be used for the file you are importing.

function cmdClear {

  clear

}

function Menu {

  echo "Please choose the authority you would like to acquire addresses from."
  echo "1. ARIN"
  echo "2. LACNIC"
  echo "3. APNIC"
  echo "4. AfriNIC"
  echo "5. RIPE"
  echo " "

  read -p "[1-5]? " AuthorityChoice

}

# List of file locations
#
# ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
# ftp://ftp.ripe.net/ripe/stats/delegated-ripencc-latest
# ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest
# ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest
# ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest

function VerifyAuthorityChoice {

  case $AuthorityChoice in

    [1-5])
    ;;

    *)
    echo "You have made a bad choice. Try again."

    Menu
  esac
}

function AcquireList {

case $AuthorityChoice in

  1)
  wget -O ARIN.orig ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
  ;;

  2)
  wget -O LACNIC.orig ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest
  ;;

  3)
  wget -O APNIC.orig ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest
  ;;

  4)
  wget -O AFRINIC.orig ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest
  ;;

  5)
  wget -O RIPE.orig ftp://ftp.ripe.net/ripe/stats/delegated-ripencc-latest
  ;;

esac

}

function SetAuthority {

case $AuthorityChoice in

  1)
  Authority="ARIN"
  ;;

  2)
  Authority="LACNIC"
  ;;

  3)
  Authority="APNIC"
  ;;

  4)
  Authority="AFRINIC"
  ;;

  5)
  Authority="RIPE"
  ;;

esac

}

function ConvertAuthorityListToCIDR {

## TODO: Update the function here to include the authority specific grep
## messages.

echo "Creation of $Authority.cidr has started."

sed '/ipv6/d' $Authority.orig \
| sed '/asn/d' \
| sed '/^2/d' \
| sed '/\*/d' \
| sed -e '/allocated/d' \
| sed -e '/available/d' \
| sed '/reserved/d' \
| sed -e 's/ripencc|..|ipv4|//g' \
| sed -e 's/ripencc||ipv4|//g' \
| sed -e 's/afrinic|..|ipv4|//g' \
| sed -e 's/afrinic||ipv4|//g' \
| sed -e 's/lacnic|..|ipv4|//g' \
| sed -e 's/lacnic||ipv4|//g' \
| sed -e 's/arin|..|ipv4|//g' \
| sed -e 's/arin||ipv4|//g' \
| sed -e 's/apnic|..|ipv4|//g' \
| sed -e 's/apnic||ipv4|//g' \
| sed -e 's/|1|.*$/\/32/g' \
| sed -e 's/|2|.*$/\/31/g' \
| sed -e 's/|4|.*$/\/30/g' \
| sed -e 's/|8|.*$/\/29/g' \
| sed -e 's/|16|.*$/\/28/g' \
| sed -e 's/|32|.*$/\/27/g' \
| sed -e 's/|64|.*$/\/26/g' \
| sed -e 's/|128|.*$/\/25/g' \
| sed -e 's/|256|.*$/\/24/g' \
| sed -e 's/|512|.*$/\/23/g' \
| sed -e 's/|1024|.*$/\/22/g' \
| sed -e 's/|2048|.*$/\/21/g' \
| sed -e 's/|4096|.*$/\/20/g' \
| sed -e 's/|8192|.*$/\/19/g' \
| sed -e 's/|16384|.*$/\/18/g' \
| sed -e 's/|32768|.*$/\/17/g' \
| sed -e 's/|65536|.*$/\/16/g' \
| sed -e 's/|131072|.*$/\/15/g' \
| sed -e 's/|262144|.*$/\/14/g' \
| sed -e 's/|524288|.*$/\/13/g' \
| sed -e 's/|1048576|.*$/\/12/g' \
| sed -e 's/|2097152|.*$/\/11/g' \
| sed -e 's/|4194304|.*$/\/10/g' \
| sed -e 's/|8388608|.*$/\/9/g' \
| sed -e 's/|16777216|.*$/\/8/g' \
| sed -e 's/|33554432|.*$/\/7/g' \
| sed -e 's/|67108864|.*$/\/6/g' \
| sed -e 's/|134217728|.*$/\/5/g' \
| sed -e 's/|268435456|.*$/\/4/g' \
| sed -e 's/|536870912|.*$/\/3/g' \
| sed -e 's/|1073741824|.*$/\/2/g' \
| sed -e 's/|2147483648|.*$/\/1/g' \
| sed -e '/^.*\|.*$/d' \
>> $Authority.cidr

echo "Creation of $Authority.cidr has finshed."

}

function ConvertCIDRtoConfig {

# This will take the CIDR file and turn it into something useable by the Cisco
# ASAs.

echo "Creation of $Authority.conf has started."


# BEGIN Network Object Loop

lineTotal=$(wc -l $Authority.cidr | awk '{print $1}')

echo $lineTotal

lineCurrent=1

while [ $lineCurrent -le $lineTotal ]; do

  sed -n "$lineCurrent p" $Authority.cidr \
| sed "s/^/object network $Authority$lineCurrent\# subnet\ /" \
| sed -e "s/\/0/\ 0\.0\.0\.0/" \
| sed -e "s/\/1/\ 128\.0\.0\.0/" \
| sed -e "s/\/2/\ 192\.0\.0\.0/" \
| sed -e "s/\/3/\ 224\.0\.0\.0/" \
| sed -e "s/\/4/\ 240\.0\.0\.0/" \
| sed -e "s/\/5/\ 248\.0\.0\.0/" \
| sed -e "s/\/6/\ 252\.0\.0\.0/" \
| sed -e "s/\/7/\ 254\.0\.0\.0/" \
| sed -e "s/\/8/\ 255\.0\.0\.0/" \
| sed -e "s/\/9/\ 255\.128\.0\.0/" \
| sed -e "s/\/10/\ 255\.192\.0\.0/" \
| sed -e "s/\/11/\ 255\.224\.0\.0/" \
| sed -e "s/\/12/\ 255\.240\.0\.0/" \
| sed -e "s/\/13/\ 255\.248\.0\.0/" \
| sed -e "s/\/14/\ 255\.252\.0\.0/" \
| sed -e "s/\/15/\ 255\.254\.0\.0/" \
| sed -e "s/\/16/\ 255\.255\.0\.0/" \
| sed -e "s/\/17/\ 255\.255\.128\.0/" \
| sed -e "s/\/18/\ 255\.255\.192\.0/" \
| sed -e "s/\/19/\ 255\.255\.224\.0/" \
| sed -e "s/\/20/\ 255\.255\.240\.0/" \
| sed -e "s/\/21/\ 255\.255\.248\.0/" \
| sed -e "s/\/22/\ 255\.255\.252\.0/" \
| sed -e "s/\/23/\ 255\.255\.254\.0/" \
| sed -e "s/\/24/\ 255\.255\.255\.0/" \
| sed -e "s/\/25/\ 255\.255\.255\.128/" \
| sed -e "s/\/26/\ 255\.255\.255\.192/" \
| sed -e "s/\/27/\ 255\.255\.255\.224/" \
| sed -e "s/\/28/\ 255\.255\.255\.240/" \
| sed -e "s/\/29/\ 255\.255\.255\.248/" \
| sed -e "s/\/30/\ 255\.255\.255\.252/" \
| sed -e "s/\/32/\ 255\.255\.255\.255/" \
| tr '#' '\n' \
>> $Authority.conf

  ((lineCurrent++))

done

# END Network Object Loop

echo object-group network $Authority >> $Authority.conf

# BEGIN Group Object Loop

lineCurrent=1

while [ $lineCurrent -le $lineTotal ]; do

  echo network-object object $Authority$lineCurrent >> $Authority.conf

  ((lineCurrent++))

done

# END Group Object Loop

echo end >> $Authority.conf

echo "Creation of $Authority.cidr has finished."

}

function Unknown01 {
#!/bin/bash

# Imports data via file and pipes out configlet to be imported into a Cisco
# ASA.

# Data to import can be found at:
# ftp://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest

# Arugments:
# $1 is the Object Name in the ASA
# $2 is the data to import

lineTotal=$(wc -l $2 | awk '{print $1}')
lineCurrent=1

while [ $lineCurrent -le $lineTotal ]; do

   sed -n "$lineCurrent p" $2 \
  | sed '/ipv6/d' | sed '/asn/d' | sed '/^2/d' | sed '/\*/d' \
  | sed -e '/allocated/d' | sed -e '/available/d' | sed '/reserved/d' \
  | sed -e 's/ripencc|..|ipv4|//' | sed -e 's/ripencc||ipv4|//' \
  > RIPE.configlet

  ((lineCurrent++))

done

}

## RUN LIST

cmdClear
Menu
VerifyAuthorityChoice
AcquireList
SetAuthority
ConvertAuthorityListToCIDR
ConvertCIDRtoConfig

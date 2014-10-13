#!/bin/bash

# regional-asa.sh,v0.3b

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

function SelectCountry {

  echo ""
  read -p "Please enter the name or part of the country's english name. " SearchCountry

  IFS=$'\n'
  Results=( $(grep -i $SearchCountry country.list) )

  for (( i = 0; i < ${#Results[@]}; i++ ))
  do
    echo $i " : " ${Results[$i]}
  done

  echo $i " : " None of the above

  echo "Please select the nubmer associated with the country you desire."
  read -p "[0-$i]? " PickCountry

  if [[ $PickCountry -eq $i ]]
  then

    SpecifyCountry

  fi

  if [[ $PickCountry -lt $i ]]
  then

    Country=$(echo ${Results[$PickCountry]})
    echo "You have selected: " $Country
    CountryShortName=$(echo $Country | awk '{ print $1 }' )
    echo $CountryShortName
  fi

}

function SpecifyCountry {

  echo ""
  echo "Would you like to specify a country?"
  read -p "[y/n]? " SpecifyCountry

  if [[ "$SpecifyCountry" == "y" || "$SpecifyCountry" == "Y" ]]
  then

    SelectCountry

  else
    exit
  fi

}

function ConvertAuthorityListToCIDR {

echo "Creation of $Authority.cidr has started."

if [[ "$SpecifyCountry" == "y" || "$SpecifyCountry" == "Y" ]]
then

sed '/ipv6/d' $Authority.orig \
| sed '/asn/d' \
| sed '/^2/d' \
| sed '/\*/d' \
| sed -e '/allocated/d' \
 -e '/available/d' \
| sed '/reserved/d' \
| sed -e "/$CountryShortName/!d" \
 -e 's/ripencc|..|ipv4|//g' \
 -e 's/ripencc||ipv4|//g' \
 -e 's/afrinic|..|ipv4|//g' \
 -e 's/afrinic||ipv4|//g' \
 -e 's/lacnic|..|ipv4|//g' \
 -e 's/lacnic||ipv4|//g' \
 -e 's/arin|..|ipv4|//g' \
 -e 's/arin||ipv4|//g' \
 -e 's/apnic|..|ipv4|//g' \
 -e 's/apnic||ipv4|//g' \
 -e 's/|1|.*$/\/32/g' \
 -e 's/|2|.*$/\/31/g' \
 -e 's/|4|.*$/\/30/g' \
 -e 's/|8|.*$/\/29/g' \
 -e 's/|16|.*$/\/28/g' \
 -e 's/|32|.*$/\/27/g' \
 -e 's/|64|.*$/\/26/g' \
 -e 's/|128|.*$/\/25/g' \
 -e 's/|256|.*$/\/24/g' \
 -e 's/|512|.*$/\/23/g' \
 -e 's/|1024|.*$/\/22/g' \
 -e 's/|2048|.*$/\/21/g' \
 -e 's/|4096|.*$/\/20/g' \
 -e 's/|8192|.*$/\/19/g' \
 -e 's/|16384|.*$/\/18/g' \
 -e 's/|32768|.*$/\/17/g' \
 -e 's/|65536|.*$/\/16/g' \
 -e 's/|131072|.*$/\/15/g' \
 -e 's/|262144|.*$/\/14/g' \
 -e 's/|524288|.*$/\/13/g' \
 -e 's/|1048576|.*$/\/12/g' \
 -e 's/|2097152|.*$/\/11/g' \
 -e 's/|4194304|.*$/\/10/g' \
 -e 's/|8388608|.*$/\/9/g' \
 -e 's/|16777216|.*$/\/8/g' \
 -e 's/|33554432|.*$/\/7/g' \
 -e 's/|67108864|.*$/\/6/g' \
 -e 's/|134217728|.*$/\/5/g' \
 -e 's/|268435456|.*$/\/4/g' \
 -e 's/|536870912|.*$/\/3/g' \
 -e 's/|1073741824|.*$/\/2/g' \
 -e 's/|2147483648|.*$/\/1/g' \
 -e '/^.*|.*$/d' \
>> $Authority.cidr

else

sed '/ipv6/d' $Authority.orig \
| sed '/asn/d' \
| sed '/^2/d' \
| sed '/\*/d' \
| sed -e '/allocated/d' \
 -e '/available/d' \
| sed '/reserved/d' \
 -e 's/ripencc|..|ipv4|//g' \
 -e 's/ripencc||ipv4|//g' \
 -e 's/afrinic|..|ipv4|//g' \
 -e 's/afrinic||ipv4|//g' \
 -e 's/lacnic|..|ipv4|//g' \
 -e 's/lacnic||ipv4|//g' \
 -e 's/arin|..|ipv4|//g' \
 -e 's/arin||ipv4|//g' \
 -e 's/apnic|..|ipv4|//g' \
 -e 's/apnic||ipv4|//g' \
 -e 's/|1|.*$/\/32/g' \
 -e 's/|2|.*$/\/31/g' \
 -e 's/|4|.*$/\/30/g' \
 -e 's/|8|.*$/\/29/g' \
 -e 's/|16|.*$/\/28/g' \
 -e 's/|32|.*$/\/27/g' \
 -e 's/|64|.*$/\/26/g' \
 -e 's/|128|.*$/\/25/g' \
 -e 's/|256|.*$/\/24/g' \
 -e 's/|512|.*$/\/23/g' \
 -e 's/|1024|.*$/\/22/g' \
 -e 's/|2048|.*$/\/21/g' \
 -e 's/|4096|.*$/\/20/g' \
 -e 's/|8192|.*$/\/19/g' \
 -e 's/|16384|.*$/\/18/g' \
 -e 's/|32768|.*$/\/17/g' \
 -e 's/|65536|.*$/\/16/g' \
 -e 's/|131072|.*$/\/15/g' \
 -e 's/|262144|.*$/\/14/g' \
 -e 's/|524288|.*$/\/13/g' \
 -e 's/|1048576|.*$/\/12/g' \
 -e 's/|2097152|.*$/\/11/g' \
 -e 's/|4194304|.*$/\/10/g' \
 -e 's/|8388608|.*$/\/9/g' \
 -e 's/|16777216|.*$/\/8/g' \
 -e 's/|33554432|.*$/\/7/g' \
 -e 's/|67108864|.*$/\/6/g' \
 -e 's/|134217728|.*$/\/5/g' \
 -e 's/|268435456|.*$/\/4/g' \
 -e 's/|536870912|.*$/\/3/g' \
 -e 's/|1073741824|.*$/\/2/g' \
 -e 's/|2147483648|.*$/\/1/g' \
 -e '/^.*|.*$/d' \
>> $Authority.cidr

fi

echo "Creation of $Authority.cidr has finshed."

}

function ConvertCIDRtoConfig {

# This will take the CIDR file and turn it into something useable by the Cisco
# ASAs.

echo "Creation of $Authority.conf has started."


# BEGIN Network Object Loop

lineTotal=$(wc -l $Authority.cidr | awk '{print $1}')

lineCurrent=1

while [ $lineCurrent -le $lineTotal ]; do

  sed -n "$lineCurrent p" $Authority.cidr \
| sed "s/^/object network $Authority$lineCurrent\# subnet\ /" \
| sed -e "s/\/0$/\ 0\.0\.0\.0/" \
 -e "s/\/1$/\ 128\.0\.0\.0/" \
 -e "s/\/2$/\ 192\.0\.0\.0/" \
 -e "s/\/3$/\ 224\.0\.0\.0/" \
 -e "s/\/4$/\ 240\.0\.0\.0/" \
 -e "s/\/5$/\ 248\.0\.0\.0/" \
 -e "s/\/6$/\ 252\.0\.0\.0/" \
 -e "s/\/7$/\ 254\.0\.0\.0/" \
 -e "s/\/8$/\ 255\.0\.0\.0/" \
 -e "s/\/9$/\ 255\.128\.0\.0/" \
 -e "s/\/10$/\ 255\.192\.0\.0/" \
 -e "s/\/11$/\ 255\.224\.0\.0/" \
 -e "s/\/12$/\ 255\.240\.0\.0/" \
 -e "s/\/13$/\ 255\.248\.0\.0/" \
 -e "s/\/14$/\ 255\.252\.0\.0/" \
 -e "s/\/15$/\ 255\.254\.0\.0/" \
 -e "s/\/16$/\ 255\.255\.0\.0/" \
 -e "s/\/17$/\ 255\.255\.128\.0/" \
 -e "s/\/18$/\ 255\.255\.192\.0/" \
 -e "s/\/19$/\ 255\.255\.224\.0/" \
 -e "s/\/20$/\ 255\.255\.240\.0/" \
 -e "s/\/21$/\ 255\.255\.248\.0/" \
 -e "s/\/22$/\ 255\.255\.252\.0/" \
 -e "s/\/23$/\ 255\.255\.254\.0/" \
 -e "s/\/24$/\ 255\.255\.255\.0/" \
 -e "s/\/25$/\ 255\.255\.255\.128/" \
 -e "s/\/26$/\ 255\.255\.255\.192/" \
 -e "s/\/27$/\ 255\.255\.255\.224/" \
 -e "s/\/28$/\ 255\.255\.255\.240/" \
 -e "s/\/29$/\ 255\.255\.255\.248/" \
 -e "s/\/30$/\ 255\.255\.255\.252/" \
 -e "s/\/32$/\ 255\.255\.255\.255/" \
| tr '#' '\n' \
>> $Authority.conf

  echo -ne $lineCurrent "/" $lineTotal '\r'

  ((lineCurrent++))

done

echo " "

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
  | sed -e '/allocated/d' -e '/available/d' | sed '/reserved/d' \
  | sed -e 's/ripencc|..|ipv4|//' -e 's/ripencc||ipv4|//' \
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
SpecifyCountry
# SelectCountry
ConvertAuthorityListToCIDR
ConvertCIDRtoConfig

#!/bin/bash
splunk_server="your event collector splunk server URL"
splunk_autorization="Splunk authorization ID"
datetime=$(date '+%d/%m/%Y %H:%M:%S');
fail=0
display_usage() {
  echo -e "\nUsage:\nsplunksend.sh [arguments] \n"
  echo "requiere arguments (argument=value):"
  echo -e "-source=        source in splunk"
  echo -e "-site=          Desired site URL to check"
  echo -e "-expiration=    SSL cert expiration date"
  echo -e "-days_left=     Days left to SSL expiration"
  echo -e "-status=        SSL cert status"
  echo -e "-sslinfo=       SSL cert info"
} 

for i in "$@" 
do
case $i in
        -site=*)
	   site="${i#*=}"
	   shift # past argument=value
	   ;;
        -source=*)
	   source_info="${i#*=}"
	   shift # past argument=value
	   ;;
         -expiration=*)
	   expiration="${i#*=}"
	   shift # past argument=value
	   ;;
	     -days_left=*)
	   days_left="${i#*=}"
	   shift # past argument=value
	   ;;
         -status=*)
	   status="${i#*=}"
	   shift # past argument=value
	   ;;
         -sslinfo=*)
	   sslinfo="${i#*=}"
	   shift # past argument=value
	   ;;
	-help|--help)
	   display_usage
           exit 1
	   shift # past argument with no value
	   ;;
esac
done

if ([ -z "$site" ]) then
echo "-site not found"
fail=1
fi

if ([ -z "$source_info" ]) then
echo "-source not found"
fail=1
fi

if ([ -z "$expiration" ]) then
echo "-expiration not found"
fail=1
fi

if ([ -z "$days_left" ]) then
echo "-days_left not found"
fail=1
fi

if ([ -z "$status" ]) then
echo "-status not found"
fail=1
fi

if ([ -z "$sslinfo" ]) then
echo "-sslinfo not found"
fail=1
fi

if [ "$fail" -eq 0 ];then
send=$(curl -s -k "$splunk_server" -H "$splunk_autorization" -d '{"sourcetype":"_json", "source":"'"$source_info"'", "event":{"site":"'"$site"'", "expiration":"'"$expiration"'" , "days_left":"'"$days_left"'", "status":"'"$status"'","date":"'"$datetime"'","sslinfo":"'"$sslinfo"'"}}')
fi
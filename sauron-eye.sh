#!/bin/bash
#
# Author        :Julio Sanz
# Contributor   :Raúl Linares
# Email         :juliojosesb@gmail.com / linares.voip@gmail.com
# Description   :Script to check SSL certificate expiration date of a list of sites. Recommended to use with a dark terminal theme to
#                see the colors correctly. The terminal also needs to support 256 colors.
# Dependencies  :openssl, mutt (if you use the mail option)
# License       :GPLv3
#
#
# VARIABLES
#

sites_list="$1"
sitename=""
html_file="certs_check.html"
current_date=$(date +%s)
end_date=""
days_left=""
certificate_last_day=""
warning_days="30"
alert_days="15"
# Terminal colors
ok_color="\e[38;5;40m"
warning_color="\e[38;5;220m"
alert_color="\e[38;5;208m"
expired_color="\e[38;5;196m"
end_of_color="\033[0m"

#
# FUNCTIONS
#

html_mode(){
	# Generate and reset file
	cat <<- EOF > $html_file
	<!DOCTYPE html>
	<html>
			<head>
			<title>SSL Certs expiration</title>
			</head>
			<body style="background-color: lightblue;">
					<h1 style="color: navy;text-align: center;font-family: 'Helvetica Neue', sans-serif;font-size: 20px;font-weight: bold;">SSL Certs expiration checker</h1>
					<table style="background-color: #C5E1E7;padding: 10px;box-shadow: 5px 10px 18px #888888;margin-left: auto ;margin-right: auto ;border: 1px solid black;">
					<tr style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;">
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Site</th>
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Expiration date</th>
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Days left</th>
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Status</th>
					</tr>
	EOF

	while read site;do
		sitename=$(echo $site | cut -d ":" -f1)
		certificate_last_day=$(echo | openssl s_client -servername "${sitename}" -connect "${site}" 2>/dev/null | \
		openssl x509 -noout -enddate 2>/dev/null | cut -d "=" -f2)
		end_date=$(date +%s -d "$certificate_last_day")
		days_left=$(((end_date - current_date) / 86400))

		if [ "$days_left" -gt "$warning_days" ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">${sitename}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">Ok</td>" >> $html_file
			echo "</tr>" >> $html_file

		elif [ "$days_left" -le "$warning_days" ] && [ "$days_left" -gt "$alert_days" ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">${sitename}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">Warning</td>" >> $html_file
			echo "</tr>" >> $html_file

		elif [ "$days_left" -le "$alert_days" ] && [ "$days_left" -gt 0 ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">${sitename}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">Alert</td>" >> $html_file
			echo "</tr>" >> $html_file

		elif [ "$days_left" -le 0 ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #EF3434;\">${sitename}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #EF3434;\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #EF3434;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #EF3434;\">Expired</td>" >> $html_file
			echo "</tr>" >> $html_file

		fi
	done < ${sites_list}

	# Close main HTML tags
	cat <<- EOF >> $html_file
			</table>
			</body>
	</html>
	EOF
    # Upload HTML repot into a azure storage blob container
	# curl -X PUT -T certs_check.html -H "Content-Type: text/html" -H "x-ms-date: $(date -u)" -H "x-ms-blob-type: BlockBlob" "https://PATH-TO-YOUR-AZURE-BLOB-STORAGE.html?sv=2018-03-28&ss=bfqt&srt=sco&sp=rwdlacup&se=2021-01-01T10:51:00Z&st=2019-01-12T02:51:00Z&spr=https&sig=xxxxxxx" /dev/null 2>&1
}

terminal_mode(){
	printf "\n| %-30s | %-30s | %-10s | %-5s %s\n" "SITE" "EXPIRATION DAY" "DAYS LEFT" "STATUS"

	while read site;do
		sitename=$(echo $site | cut -d ":" -f1)
		certificate_last_day=$(echo | openssl s_client -servername "${sitename}" -connect "${site}" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d "=" -f2)
		#certificate_last_day=$(echo | openssl s_client -showcerts -servername "${sitename}" -connect "${site}" 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d "=" -f 2 )
		end_date=$(date +%s -d "$certificate_last_day")
		days_left=$(((end_date - current_date) / 86400))

		if [ "$days_left" -gt "$warning_days" ];then
			printf "${ok_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$sitename" "$certificate_last_day" "$days_left" "Ok"
			curl -F username="SAURON" -F text="*The Site*: $sitename is under my watch, *SSL Cert* is *OK* and it will expire in *$days_left* days" -F channel=#sauron-eye -F token=slack-channel-webhook-token https://slack.com/api/chat.postMessage > /dev/null 2>&1

		elif [ "$days_left" -le "$warning_days" ] && [ "$days_left" -gt "$alert_days" ];then
			printf "${warning_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$sitename" "$certificate_last_day" "$days_left" "Warning"
			curl -F username="SAURON" -F text="*The Site*: $sitename is under my watch, *SSL Cert* is in *Warning*, it will expire in *$days_left* days" -F channel=#sauron-eye -F token=slack-channel-webhook-token https://slack.com/api/chat.postMessage > /dev/null 2>&1

		elif [ "$days_left" -le "$alert_days" ] && [ "$days_left" -gt 0 ];then
			printf "${alert_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$sitename" "$certificate_last_day" "$days_left" "Alert"
			curl -F username="SAURON" -F text="*The Site*: $sitename is under my watch, *SSL Cert* is in *Alert*, it will expire in *$days_left* days" -F channel=#sauron-eye -F token=slack-channel-webhook-token https://slack.com/api/chat.postMessage > /dev/null 2>&1

		elif [ "$days_left" -le 0 ];then
			printf "${expired_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$sitename" "$certificate_last_day" "$days_left" "Expired"
			curl -F username="SAURON" -F text="This is unacceptable, *The Site*: $sitename does not comply with my rules, You'll be sent to *Mordor* to suffer the worst punishment" -F channel=#sauron-eye -F token=slack-channel-webhook-token https://slack.com/api/chat.postMessage > /dev/null 2>&1
		fi

	done < $sites_list

	printf "\n %-10s" "STATUS LEGEND"
	printf "\n ${ok_color}%-8s${end_of_color} %-30s" "Ok" "- More than ${warning_days} days left until the certificate expires"
	printf "\n ${warning_color}%-8s${end_of_color} %-30s" "Warning" "- The certificate will expire in less than ${warning_days} days"
	printf "\n ${alert_color}%-8s${end_of_color} %-30s" "Alert" "- The certificate will expire in less than ${alert_days} days"
	printf "\n ${expired_color}%-8s${end_of_color} %-30s\n\n" "Expired" "- The certificate has already expired"
}

howtouse(){
	cat <<-'EOF'

	You must always specify -f option with the name of the file that contains the list of sites to check
	Options:
		-f [ sitelist file ]          list of sites (domains) to check
		-o [ html | terminal ]        output (can be html or terminal)
		-m [ mail ]                   mail address to send the graphs to
		-h                            help
	
	Examples:

		# Launch the script in terminal mode:
		./sauron-eye.sh -f sitelist -o terminal

		# Using HTML mode:
		./sauron-eye.sh -f sitelist -o html

		# Using HTML mode and sending results via email
		./sauron-eye.sh -f sitelist -o html -m mail@example.com

	EOF
}

# 
# MAIN
# 

if [ "$#" -eq 0 ];then
	howtouse

elif [ "$#" -ne 0 ];then
	while getopts ":f:o:m:h" opt; do
		case $opt in
			"f")
				sites_list="$OPTARG"
				;;
			"o")
				output="$OPTARG"
				if [ "$output" == "terminal" ];then
					terminal_mode
				elif [ "$output" == "html" ];then
					html_mode
				else
					echo "Wrong output selected"
					howtouse
				fi
				;;
			"m")
				if [ "$output" == "html" ];then
					mail_to="$OPTARG"
				else
					echo "Mail option is only used with HTML mode"
				fi
				;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				howtouse
				exit 1
				;;
			:)
				echo "Option -$OPTARG requires an argument." >&2
				howtouse
				exit 1
				;;
			"h" | *)
				howtouse
				exit 1
				;;
		esac
	done

	# Send mail if specified
	if [[ $mail_to ]];then
		mutt -e 'set content_type="text/html"' $mail_to -s "SSL certs expiration check" < $html_file
	fi
fi
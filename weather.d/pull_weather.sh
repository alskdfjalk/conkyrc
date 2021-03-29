#!/bin/bash
#-------------------------------------------------------------------------
# Filename: pull_weather.sh
# Author: CJ
# Date: 2020-04-14 10:01:02
# Description:
# Usage:
# Notes:
# }

#  -------------------------------------------------------------------------

weatherlog=/tmp/weather.log

weather_type_data_list=(
	air_tips
	humidity
	air_level
	air_tips
	tem
	tem1
	tem2
	win
	win_speed
	wea
	date
	day
)
weather_type_top_list=(
	update_time
	city
)

showhelp()
{
	# update_time|shidu|pm25|pm10|quality|wendu|ganmao)		low|high|sunrise|sunset|fx|fl)
	echo "Usage: $(basename $0) {argument}"
	echo "                      -u             更新天气数据"
	echo "                      -d             选择要获取哪一天的数据,默认今天"
	echo "                                     今天：0; 明天：1； 后天：2，以此类推"
	echo "                      -p             图片显示的路径（必须配合 -t type 使用）"
	echo "                      -x             图片显示的位置：x"
	echo "                      -y             图片显示的位置：y"
	echo "                      -t             选择要获取的天气数据"
	echo "                      ${weather_type_data_list[@]} ${weather_type_top_list[@]}"
	exit
}

init_args()
{
	argsnum=0
	for args in $*
	do
		allopts[argsnum]=$args
		argsnum=$[argsnum+1]
	done
	for args in $(seq 0 $#)
	do
		[ "$args" -eq "$#" ] && break
		if [ "${allopts[$args]}" == "-h" ]
		then
			showhelp
		elif [ "${allopts[$args]}" == "-d" ]
		then
			# taoday=0
			# tomorrow=1
			# after_tomorrow = 2
			which_day="${allopts[$[args+1]]}"
		elif [ "${allopts[$args]}" == "-t" ]
		then
			weathertype="${allopts[$[args+1]]}"
		elif [ "${allopts[$args]}" == "-p" ]
		then
			imgpath="${allopts[$[args+1]]}"
		elif [ "${allopts[$args]}" == "-x" ]
		then
			x="${allopts[$[args+1]]}"
		elif [ "${allopts[$args]}" == "-y" ]
		then
			y="${allopts[$[args+1]]}"
		elif [ "${allopts[$args]}" == "-u" ]
		then
			update="true"
		fi
	done
	[ -z "${weathertype}" -a -z "${update}" ] && showhelp
}


init_where_am_I(){
	zh_where_am_i="$(curl -s http://ip-api.com/json?lang=zh-CN)"
	en_where_am_i="$(curl -s http://ip-api.com/json)"
	encountry=$(echo ${en_where_am_i} | jq .country | tr "[A-Z]" "[a-z]" | tr -d \")
	countryCode=$(echo ${zh_where_am_i} | jq .countryCode | tr -d \")
	regionName=$(echo ${zh_where_am_i} | jq .regionName | tr -d \")
	regionName=$(echo ${regionName} | sed "s/\(.*\)自治区/\1/g")
	regionName=$(echo ${regionName} | sed "s/\(.*\)市/\1/g")
	city=$(echo ${zh_where_am_i} | jq .city | tr -d \" | sed "s/\(.*\)市/\1/g")
}

get_query_code(){
	prov_value=$(curl -s "http://www.weather.com.cn/data/city3jdata/${encountry}.html" | \
					grep -o "\"[0-9]*\":\"${regionName}\"" | tr -d \")
	prov_code=$(echo ${prov_value} | awk -F ":" '{print $1}')
	prov_name=$(echo ${prov_value} | awk -F ":" '{print $2}')

	city_value=$(curl -s http://www.weather.com.cn/data/city3jdata/provshi/${prov_code}.html | \
					   grep -o "\"[0-9]*\":\"${city}\"" | tr -d \")
	city_code=$(echo ${city_value} | awk -F ":" '{print $1}')
	city_name=$(echo ${city_value} | awk -F ":" '{print $2}')

	station_value=$(curl -s http://www.weather.com.cn/data/city3jdata/station/${prov_code}${city_code}.html | \
					  grep -o "\"[0-9]*\":\"${city}\"" | tr -d \")
	station_code=$(echo ${station_value} | awk -F ":" '{print $1}')
	station_name=$(echo ${station_value} | awk -F ":" '{print $2}')
}

query_weather(){
	# get_query_code
	# base_url='http://t.weather.sojson.com/api/weather/city'
	# request_url='https://tianqiapi.com/api?version=v1&appid=87783233&appsecret=XrG3R4bW&city=${1}'
	request_url='https://tianqiapi.com/api?version=v1&appid=87783233&appsecret=XrG3R4bW'
	# this_city_weather_query_url=${base_url}"/${prov_code}${station_code}${city_code}"
	echo -en $(curl -s ${request_url})
}

weather_format_variables(){
	which_day=${which_day:=0}
	[ -n "$1" ] && weathertype=${1}

	for wt in ${weather_type_top_list[@]}
	do
		[ ${wt} == ${weathertype} ] && cat ${weatherlog} | jq .${weathertype} && return 0
	done
	cat ${weatherlog} | jq .data[${which_day}].${weathertype} | tr -d \" | awk -F"转" '{print $1}'
}

query_img_for_conky(){
	nowHours=$(date -d $(date "+%H") +%s)
	dark_time=$(date -d "18" +%s)
	if [ "${nowHours}" -ge ${dark_time} ]
	then
		dn=n
	else
		dn=d
	fi
	x=${x=:50}
	y=${y=:50}
	echo \$\{image ${imgpath}/${dn}$(weather_format_variables wea).gif -p ${x},${y} \}
}

main(){
	init_args $*
	if [ "${update}" == true ]
	then
		# init_where_am_I
		query_weather ; echo
	elif [ -n "${imgpath}" ]
	then
		[ imgs != ${weathertype} ] && showhelp
		query_img_for_conky
	elif [ -n "${weathertype}" ]
	then
		echo $(weather_format_variables) | tr -d \" | tr -d "℃" 
	fi
}


main $*

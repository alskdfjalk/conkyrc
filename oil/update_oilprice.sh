#!/bin/bash
#-------------------------------------------------------------------------
# Filename: update_oilprice.sh
# Author: CJ
# Date: 2020-04-11 22:36:52
# Description:
# Usage:
# Notes:
#  -------------------------------------------------------------------------

curlopts='2> /dev/null -s'


CityName=$(bash ~cj/.xinit.d/bin/get_location.sh | jq ".regionName" | tr -d \")
local_city_price_url=$(curl ${curlopts} --connect-timeout 1 'http://youjia.chemcp.com/'  | iconv -f gb2312 -t utf8 | grep ${CityName}汽油价格)
if [ -z "${local_city_price_url}" ]
then
	CityName=北京
	local_city_price_url=$(curl ${curlopts} --connect-timeout 1 'http://youjia.chemcp.com/'  | iconv -f gb2312 -t utf8 | grep ${CityName}汽油价格)
fi
apiurl=$(echo ${local_city_price_url} | grep -o "http://youjia.chemcp.com\/[a-z]*\/" | head -1)
oilprice=$(curl ${curlopts} --connect-timeout 1 ${apiurl} | iconv -f gb2312 -t utf-8 | \
				 grep -A2 "${CityName}92#汽油价格" | \
				 grep -o "[0-9]\.[0-9]\{1,2\}元")
lastest_news_url=$(curl ${curlopts} 'http://fgw.beijing.gov.cn/so/s?qt=%E6%B2%B9%E4%BB%B7&siteCode=1100000011&tab=all&toolsStatus=1' | grep  '本市成品油价格' | awk -F'"' '{print $2}' | sort -rn | head -1)
lastest_news="$(curl ${curlopts} ${lastest_news_url} | sed -e 's/<span style="text-indent: 2em;">//g' -e 's/<\/span>//g')"
effective_date=$(echo ${lastest_news} | grep -o '零售价格自[0-9]*年[0-9]*月[0-9]*日[0-9]*时起')
rise_in_price=$(echo ${lastest_news} | grep -o '92号汽油由每升[0-9]*\.[0-9]*元调整为[0-9]*\.[0-9]*元，提高[0-9]*\.[0-9]*元；')

thisday_y=$(date "+%Y")
thisday_m=$(date "+%m" | sed 's/0\(.*\)/\1/g')
thisday_d=$(date "+%d")
thisday="${thisday_y}${thisday_m}${thisday_d}24"
riseday=$(echo ${effective_date} | grep -o '[0-9]*' | tr -d '\n')
[ "${thisday}" -le "${riseday}" ] 2> /dev/null && echo new > /home/cj/tmp/rise_in_future || rm -rf /home/cj/tmp/rise_in_future

echo ============================================
echo "今日${CityName}平均油价：92#/${oilprice}/升; "
echo "${effective_date}:"
echo "${rise_in_price}"
echo ============================================

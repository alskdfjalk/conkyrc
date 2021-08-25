#!/usr/bin/python3
# -------------------------------------------------------------------------
# Filename: query_price.py
# Author: CJ
# Date: 2021-08-06 20:39:52
# Description:
# Usage:
# Notes:
#  -------------------------------------------------------------------------

import os
import re
import sys
import datetime
from pathlib import Path
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support import expected_conditions as EC


price_change = '/home/cj/tmp/price_change'
search_url = "http://fgw.beijing.gov.cn/so/s?qt=%E6%9C%AC%E5%B8%82%E6%88%90%E5%93%81%E6%B2%B9%E4%BB%B7&siteCode=1100000011&tab=all&toolsStatus=1"
user_agent = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'


print('正在设置头部等其他数据')
opt = Options()
opt.add_argument('--headless')
opt.add_argument('--user-agent=' + user_agent)
browser = webdriver.Chrome(
    executable_path='/opt/apps/chromedriver', options=opt)


def open_url(url, filter_name, filter_value):
    print('正在使用 chrome 打开页面: ', url)
    browser.get(url)
    print('正在等待页面加载完毕')
    try:
        wait = WebDriverWait(browser, timeout=5)
        wait.until(EC.presence_of_element_located((filter_name, filter_value)))
    except BaseException:
        print(sys.exc_info())
        print('页面加载超时或者页面并非需要打开的页面')
        sys.exit(1)
    print('正在获取页面结果')
    browser.execute_script('window.scrollTo(0, document.body.scrollHeight)')


def find_newest():
    """
    """
    open_url(search_url, By.CLASS_NAME, "gotoTop")
    print('正在查找最新的价格调整新闻')
    oil_price_news = browser.find_elements_by_xpath('//a[@class="fontlan"]')
    price_news = []
    for eachnews in oil_price_news:
        price_news.append((eachnews.get_attribute('href'),
                          eachnews.get_attribute('title')))
    price_news.sort(reverse=True)
    return price_news[0]


def filter_new_price(url, changetype, savefile):
    """
    """
    print('正在打开最新一篇价格调整新闻')
    open_url(url, By.ID, "bsPanelHolder")
    print('正在截取数据')
    news_price = browser.find_element_by_class_name('xl_content')
    price_new_time_text = re.search(
        r'最高零售价格自\d*年\d*月\d*日\d*时起', news_price.text).group()
    price_new_time = datetime.datetime.strptime(
        price_new_time_text, '最高零售价格自%Y年%m月%d日%M时起')
    price_new_time += datetime.timedelta(days=1)
    price_new_time_text = price_new_time_text + changetype[-2:]
    price_92 = news_price.find_elements_by_tag_name('tr')[3].text.split()[-1]
    price_95 = news_price.find_elements_by_tag_name('tr')[4].text.split()[-1]
    if not price_new_time:
        return
    if datetime.datetime.now() <= price_new_time:
        Path(price_change).touch()
    elif os.path.isfile(price_change):
        os.remove(price_change)
    with open(savefile, 'w') as fd:
        fd.writelines('========================================\n')
        fd.writelines('本市汽油' + price_new_time_text + '\n')
        fd.writelines('92: {}元/升\n'.format(price_92))
        fd.writelines('95: {}元/升\n'.format(price_95))
        fd.writelines('========================================\n')


def close_chrome():
    print('正在关闭浏览器')
    browser.close()
    browser.quit()


if '__main__' == __name__:
    try:
        newest_price = find_newest()
        filter_new_price(
            newest_price[0], newest_price[1], '/home/cj/tmp/update_oilprice.log')
    finally:
        close_chrome()

#!/bin/bash

#入参:region, server, type
# LOGLEVEL: 日志等级，默认值为information
# TCPIP: tcp服务IP, tcp服务必须传入
# TCPPORT: tcp服务port, tcp服务必须传入
# HTTPIP: http服务IP, http服务必须传入
# HTTPPORT: http服务port, http服务必须传入
# INSTANCEID: 实例ID

function usage() {
    echo "usage:"
    echo "$0 -r region -m server -t type"
    echo "$0 --region=region --server=server --type=type"
    exit 1
}


TEMP=`getopt -o r:m:t:h -l region:,server:,type:,help -- "$@"`
[[ $? -ne 0 ]] && usage
eval set -- "$TEMP"

while true; do
	case "$1" in
		-r|--region)
			region="$2"
			shift 2
			;;
		-s|--server)
			server="$2"
			shift 2
			;;
		-h|--help)
			usage
			shift
			;;
		--)
			shift
			break
			;;
		*)
			break
			;;
	esac
done

###########  从环境变量中获取配置 #############
if [[ -z $IPADDR ]]; then
	echo "ip addr is empty"
	exit 1
fi
RUN_IP_ADDR=${IPADDR:=1}

if [[ -z $INSTANCEID ]]; then
	echo "node instancd id is empty"
	exit 1
fi
RUN_INSTANCE_ID=${INSTANCEID:=1}

if [[ -z $PORTSHIFT ]]; then
	echo "port shift is empty"
	exit 1
fi
RUN_PORT_SHIFT=${PORTSHIFT:=1}

###########  从文件中读取配置来初始化 #############
. /root/data/common.sh

## 获取用于替换的变量
GetRegionConfig $region

## 生成一个配置文件实例
file="config.json"
cp -f "templates/"$file".template" conf/$file

## 用变量替换文件实例的相应值
CreateRegionConfigFile conf/$file

## 设置时区
ln -sf   /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime

## 启动
#mv -f $file /root/conf/
./bin/main -c ./conf/$file


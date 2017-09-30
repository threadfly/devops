#!/usr/bin/env bash
# ["zk"] = "zzvzvxz"


function GetRegionConfig() {
	_migration_report_mode="day" ## "day" "week"
	_log_level="DEBUG"
	_tcp_port=9039
	_http_port=8001
	_redis_port=6379
	_redis_pool_size=5
	_lock_timeout_min=180 ## 单位分钟 eg: 60 120 86400
	_warning_email_1="rick.wu@threadfly.cn|tyr.chen@threadfly.cn"
	_warning_email_2="eden.zhong@threadfly.cn"
	_warning_email_3="yidong.wu@threadfly.cn"
	_warning_authkey=545936616 ## belong to rick.wu
case "$1" in
	"pre")
	_region_id=666888
	_zk_server_list=""	
	_unetwork_dburl=""
	_redis_ip="192.168.153.120"
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="192.168.153.120"
	;;
	"cn-sh2")
	_region_id=1000009
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.28.38.175"
	;;
	"cn-sh")
	_region_id=1000007
	_zk_server_list=""
	_unetwork_dburl="" # write
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.29.13.13"
	;;
	"cn-gd")
	_region_id=1000003
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.27.117.200"
	;;
	"cn-bj2")
	_region_id=1000001
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.27.245.155"
	;;
	"cn-hk")
	_region_id=1000004
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.26.0.193"
	;;
	"us-ca")
	_region_id=1000005
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.25.8.250"
	;;
	"us-ws")
	_region_id=1000010
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.2.188"
	;;
	"ge-fra")
	_region_id=1000011
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.6.188"
	;;
	"th-bkk")
	_region_id=1000012
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.22.188"
	;;
	"kr-seoul")
	_region_id=1000013
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.10.188"
	;;
	"sg")
	_region_id=1000014
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.14.188"
	;;
	"tw-kh")
	_region_id=1000015
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.18.188"
	;;
	"rus-mosc")
	_region_id=1000016
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.30.133"
	;;
	"jpn-tky")
	_region_id=1000017
	_zk_server_list=""
	_unetwork_dburl=""
	_redis_ip=""
	_warning_ip=""
	_warning_port=""
	_checker_host_ip="172.30.34.40"
;;
esac
echo "--------- $1 ---------------"
((COMPOSE_HTTPPORT_SHIFT=$COMPOSE_HTTPPORT_SHIFT+$_http_port))
((COMPOSE_TCPPORT_SHIFT=$COMPOSE_TCPPORT_SHIFT+$_tcp_port))
}

function CreateRegionConfigFile() {
	((httpport=$RUN_PORT_SHIFT+$_http_port))
	((tcpport=$RUN_PORT_SHIFT+$_tcp_port))
	## 先用环境变量的值来替换
	sed -i "s#%{id}#$RUN_INSTANCE_ID#" $1
	sed -i "s#%{tcp_ip}#$RUN_IP_ADDR#" $1
	sed -i "s#%{tcp_port}#$tcpport#" $1
	sed -i "s#%{http_port}#$httpport#" $1
	sed -i "s#%{log_level}#$_loglevel#" $1

	## 用配置文件的变量值来替换
	sed -i "s#%{zk_server_list}#$_zk_server_list#" $1
	
	sed -i "s#%{unetwork_dburl}#$_unetwork_dburl#" $1

	if [[ $_redis_ip == "" ]]; then
		sed -i "s#%{redis_ip}#$RUN_IP_ADDR#" $1
	else
		sed -i "s#%{redis_ip}#$_redis_ip#" $1
	fi

	sed -i "s#%{redis_port}#$_redis_port#" $1
	sed -i "s#%{redis_pool_size}#$_redis_pool_size#" $1

	sed -i "s#%{migration_report_mode}#$_migration_report_mode#" $1
	sed -i "s#%{lock_timeout_min}#$_lock_timeout_min#" $1

	sed -i "s#%{warning_ip}#$_warning_ip#" $1
	if [[ $_warning_port == "" ]]; then
		sed -i "s#%{warning_port}#0#" $1
	else
		sed -i "s#%{warning_port}#$_warning_port#" $1
	fi

	sed -i "s#%{warning_authkey}#$_warning_authkey#" $1

	sed -i "s#%{warning_email_1}#$_warning_email_1#" $1
	sed -i "s#%{warning_email_2}#$_warning_email_2#" $1
	sed -i "s#%{warning_email_3}#$_warning_email_3#" $1

	sed -i "s#%{region_id}#$_region_id#" $1

	sed -i "s#%{checker_host_ip}#$_checker_host_ip#" $1
}

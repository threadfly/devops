#!/usr/bin/env bash
# ["zk"] = "zzvzvxz"


function GetRegionConfig() {
case "$1" in
	"pre")
	_region_id=666888

	_tcp_port=7001 ## 监听端口
	_internal_api_gateway="http://127.0.0.1:4000"
	_api_host="http://127.0.0.1:5000"
	_mysql="threadfly:threadfly.cn@tcp()"
	;;
	"cn-sh2")
	_region_id=1000009

	_tcp_port=7001 ## 监听端口
	_internal_api_gateway="http://127.0.0.1:4000" # 内部 proxy 地址, 需要自己部署
	_api_host="http://internal.api.threadfly.cn" # 内部 api 地址
	_mysql="threadfly:threadfly.cn@tcp()" # mysql 配置
	;;
	"cn-gd")
	_region_id=1000003

	_tcp_port=7001 ## 监听端口
	_internal_api_gateway="http://127.0.0.1:4000" # 内部 proxy 地址, 需要自己部署
	_api_host="http://internal.api.threadfly.cn" # 内部 api 地址
	_mysql="threadfly:threadfly.cn@tcp()" # mysql 配置
	;;
	"cn-bj2")
	_region_id=1000001

	_tcp_port=7001 # 监听端口
	_internal_api_gateway="http://127.0.0.1:4000" # 内部 proxy 地址
	_api_host="http://internal.api.threadfly.cn" # 内部 api 地址
	_mysql="threadfly:threadfly.cn@tcp()"  # mysql 配置
	;;
	"cn-hk")
	_region_id=1000004

	_tcp_port=7001 # 监听端口
	_internal_api_gateway="http://127.0.0.1:4000" # 内部 proxy 地址
	_api_host="http://internal.api.threadfly.cn" # 内部 api 地址
	_mysql="threadfly:threadfly.cn@tcp()"  # mysql 配置
	;;
	"us-ca")
	_region_id=1000005

	_tcp_port=7001 # 监听端口
	_internal_api_gateway="http://127.0.0.1:4000" # 内部 proxy 地址
	_api_host="http://internal.api.threadfly.cn" # 内部 api 地址
	_mysql="threadfly:threadfly.cn@tcp()"  # mysql 配置
	;;
	"ge-fra")
	_region_id=1000011

	_tcp_port=7001 # 监听端口
	_internal_api_gateway="http://127.0.0.1:4000" # 内部 proxy 地址
	_api_host="http://internal.api.threadfly.cn" # 内部 api 地址
	_mysql="threadfly:threadfly.cn@tcp()"  # mysql 配置
	;;
esac
echo "--------- $1 ---------------"
((COMPOSE_HTTPPORT_SHIFT=$COMPOSE_HTTPPORT_SHIFT+$_tcp_port))
}

function CreateRegionConfigFile() {
	((tcpport=$RUN_PORT_SHIFT+$_tcp_port))
	## 先用环境变量的值来替换
	sed -i "s#%{tcp_ip}#0\.0\.0\.0:$tcpport#" $1
	sed -i "s#%{tcp_port}#$tcpport#" $1

	## 用配置文件的变量值来替换
	sed -i "s#%{internal_api_gateway}#$_internal_api_gateway#" $1
	sed -i "s#%{api_host}#$_api_host#" $1
	sed -i "s#%{mysql}#$_mysql#" $1
}

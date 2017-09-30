#!/bin/bash
#2017-07-22 rick.wu@threadfly.cn
#功能:
#1. 根据-c pull,拉取最新版本的镜像
#2. 根据-c deploy 下发yml文件
#3. 根据-c restart 重启container



##
##	c: 命令类型 pull|deploy|restart|stop|mkdir|rmlog
##	i: 镜像地址
##	s: 服务类型 uvpcfe|unethawkeyes
##	r: 地域信息 cn-sh2|cn-gd|cn-bj2|hk|us-ca|us-ws|th-bkk|sg|...
##	n: 容器名字
##	l: 日志等级 DEBUG|INFO|ERROR|...
##	v: 实例id   0,1,2,3,4,5...
##	a: 部署的服务地址
##	f: ip列表,用于pull,restart,mkdir,rmlog,stop
##	p: 服务的监听的端口偏移

while getopts c:i:s:r:n:l:v:a:f:p: arg
do
  case $arg in
    c)
      CMD=$OPTARG
      ;;
    i)
      IMAGE=$OPTARG
      ;;
    s)
      #auth/conn/config/file/stats/control
      SERVER=$OPTARG
      ;;
    r)
      REGION=$OPTARG
      ;;
    n)
      CONTAINERNAME=$OPTARG
      ;;
    l)
      LOGLEVEL=$OPTARG
      ;;
    v)
      INSTANCEID=$OPTARG
      ;;
## 对单个地址操作, deploy, stop
    a)
      IPADDR=$OPTARG
      ;;
## 批量操作比如mkdir, rmlog, restart
    f)
      IPLIST=$OPTARG
      ;;
    p)
	  PORT_SHIFT=$OPTARG
 	;;
  esac
done


echo "-- CMD:${CMD}"
echo "-- IMAGE:${IMAGE}"
echo "-- SERVER:${SERVER}"
echo "-- REGION:${REGION}"
echo "-- CONTAINERNAME:${CONTAINERNAME}"
echo "-- LOGLEVEL:${LOGLEVEL}"
echo "-- INSTANCEID:${INSTANCEID}"
echo "-- IPADDR:${IPADDR}"
echo "-- IPLIST:${IPLIST}"
echo "-- PORT_SHIFT:${PORT_SHIFT}"

function pullimages() {
  echo "pssh -h $IPLIST -t 0 -l root -P "docker pull $IMAGE""
  pssh -h $IPLIST -t 0 -l root -P "docker pull $IMAGE"
}

function deployyml() {
	YMLDIR="../yml"
	COMPOSE_TCPPORT_SHIFT=${PORT_SHIFT}
	COMPOSE_HTTPPORT_SHIFT=${PORT_SHIFT}
	
	## 获取端口
	. ../data/${SERVER}/common.sh
	GetRegionConfig $REGION

    local server_name="$CONTAINERNAME"
    local yml_file="${SERVER}-docker-compose.yml"
    local new_yml_file="${CONTAINERNAME}-docker-compose.yml"
    #local my_dir=$(dirname $(readlink -m $0))

    cp -f $YMLDIR/$yml_file $new_yml_file
    sed -i "s#%{server_type}#$SERVER#g" $new_yml_file
    sed -i "s#%{image}#$IMAGE#g" $new_yml_file
    sed -i "s#%{region}#$REGION#g" $new_yml_file
    sed -i "s#%{containername}#$CONTAINERNAME#g" $new_yml_file
    
	if [[ $COMPOSE_TCPPORT_SHIFT -ne ${PORT_SHIFT} ]]; then
		sed -i "s#%{tcp_port_map}#- \"$IPADDR:$COMPOSE_TCPPORT_SHIFT:$COMPOSE_TCPPORT_SHIFT\"#g" $new_yml_file
	else
		sed -i "s#%{tcp_port_map}##g" $new_yml_file
	fi

	if [[ $COMPOSE_HTTPPORT_SHIFT -ne ${PORT_SHIFT} ]]; then
		sed -i "s#%{http_port_map}#- \"$IPADDR:$COMPOSE_HTTPPORT_SHIFT:$COMPOSE_HTTPPORT_SHIFT\"#g" $new_yml_file
	else
		sed -i "s#%{http_port_map}##g" $new_yml_file
	fi

    sed -i "s#%{server_name}#$server_name#g" $new_yml_file
    sed -i "s#%{ip_addr}#$IPADDR#g" $new_yml_file
    sed -i "s#%{instance_id}#$INSTANCEID#g" $new_yml_file
    sed -i "s#%{port_shift}#$PORT_SHIFT#g" $new_yml_file

	ssh root@$IPADDR " [[ -d /data/$server_name ]] "
	IS_EXIST=$?
	if [[ $IS_EXIST -ne 0 ]]; then
		ssh root@$IPADDR "mkdir -p /data/$server_name/data"
		ssh root@$IPADDR "mkdir -p /data/$server_name/log"
	fi

	scp ../data/$SERVER/common.sh root@$IPADDR:/data/$server_name/data

	ssh root@$IPADDR " [[ -d /data/docker-compose-file/$SERVER ]]"
	IS_EXIST=$?
	if [[ $IS_EXIST -ne 0 ]]; then
		ssh root@$IPADDR "mkdir -p /data/docker-compose-file/$SERVER"
	fi

    scp  ./$new_yml_file root@$IPADDR:/data/docker-compose-file/$SERVER
}

function restartcontainer() {
  local new_yml_file="${CONTAINERNAME}-docker-compose.yml"
  echo "pssh -H $IPADDR -l root -P \"docker-compose -f /data/docker-compose-file/$SERVER/$new_yml_file up -d\""
  pssh -H $IPADDR -l root -P "docker-compose -f /data/docker-compose-file/$SERVER/$new_yml_file up -d"
}

function makedir() {
  #local yml_file="${SERVER}-docker-compose.yml"   
  pssh -h $IPLIST -t 0  -l root -P "mkdir -p /root/docker-uagent-server/"
}

function dostop() {
  pssh -H $IPADDR -l root -P "docker stop uagent-${SERVER}-server"
}

function dormlog() {
  pssh -H $IPADDR -l root -P "rm -rf /data/logs/*"
}

#main
if [[ $CMD == "pull" ]]; then
  echo "pulling"
  pullimages
elif [[ $CMD == "deploy" ]]; then
  echo "deploying"
  deployyml
elif [[ $CMD == "restart" ]]; then
  echo "restarting"
  restartcontainer
elif [[ $CMD == "mkdir" ]]; then
  echo "make dir"
  makedir
elif [[ $CMD == "stop" ]]; then
  echo "stop"
  dostop
elif [[ $CMD == "rmlog" ]]; then
  echo "rmlog"
  dormlog
else 
    echo "Usage: 
      ./distribute.sh -c pull -i 172.17.1.176:5000/conn_server:xxxx
      ./distribute.sh -c deploy -i 镜像版本 -s server name -r region -n container name -l loglevel -v node id
      ./distribute.sh -c restart -s 'server type' -a 'server ip' -n 'container name'
      ./distribute.sh -c mkdir
      ./distribute.sh -c rmlog"
fi

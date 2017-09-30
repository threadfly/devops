#! /usr/bin/env bash

function usage(){
	echo "usage:"
	echo "		$0 -t 'server type' -n 'executebal file' -a 'images create machine' [-o other exec]"
	echo "	eg:	$0 -t uvpcfe|unethawkeye -n uvpcfe-20170722123000 -a 192.168.153.97"
}

while getopts t:n:a:o:	arg
do
	case  $arg in
	t)	
		SERV_TYPE=$OPTARG
	;;
	n)
		EXEC_NAME=$OPTARG
	;;
	a)
		CREATE_ADDR=$OPTARG
	;;
	o)
		OTHER_EXEC=$OPTARG
	esac
done

if [[ $SERV_TYPE == "" || $EXEC_NAME == "" || $CREATE_ADDR == "" ]]; then
	usage
	exit 0
fi

## 制作临时目录
TMP_DIR="tmp_`date +\"%Y-%m-%d_%H-%M-%S\"`"
echo $TMP_DIR

DST_BIN_DIR=$SERV_TYPE/bin
DST_TEMPLATE_DIR=$SERV_TYPE/templates
DST_CONF_DIR=$SERV_TYPE/conf

mkdir -p ./$TMP_DIR/$DST_BIN_DIR
mkdir -p ./$TMP_DIR/$DST_TEMPLATE_DIR
mkdir -p ./$TMP_DIR/$DST_CONF_DIR

## 往临时目录塞入用于制作镜像需要的文件
cp ../exec/$SERV_TYPE/$EXEC_NAME ./$TMP_DIR/$DST_BIN_DIR/main
if [[ $OTHER_EXEC != "" ]]; then
	cp ../exec/$SERV_TYPE/$OTHER_EXEC ./$TMP_DIR/$DST_BIN_DIR/
fi
cp ../template/$SERV_TYPE/config.json.template ./$TMP_DIR/$DST_TEMPLATE_DIR/

cp ../docker/run.sh ./$TMP_DIR/$SERV_TYPE/
cp ../docker/Dockerfile ./$TMP_DIR/$SERV_TYPE/
cp ../docker/build_image.sh.template ./$TMP_DIR/$SERV_TYPE/build_image.sh

sed -i "s#%{server_type}#$SERV_TYPE#" ./$TMP_DIR/$SERV_TYPE/build_image.sh
sed -i "s#%{exec_name}#$EXEC_NAME#" ./$TMP_DIR/$SERV_TYPE/build_image.sh

cd ./$TMP_DIR/$SERV_TYPE/
tar -zcvf ${TMP_DIR}.tar.gz * --exclude *.tar.gz
cd -


## 检查用于制作镜像的机器上是否有相应的目录来存放用于制作镜像的文件
CREATE_IMAGE_DIR=""
ssh root@$CREATE_ADDR " [[ -d /data/$SERV_TYPE ]]"
IS_EXIST_1=$?
ssh root@$CREATE_ADDR " [[ -d /root/$SERV_TYPE ]]"
IS_EXIST_2=$?

if [[ $IS_EXIST_1 -ne 0 ]] && [[ $IS_EXIST_2 -ne 0 ]]; then
	ssh root@$CREATE_ADDR "mkdir -p /data/$SERV_TYPE"
	CREATE_IMAGE_DIR="/data/$SERV_TYPE"
elif [[ $IS_EXIST_1 -eq 0 ]]; then
	CREATE_IMAGE_DIR="/data/$SERV_TYPE"
else
	CREATE_IMAGE_DIR="/root/$SERV_TYPE"
fi

## 拷贝到镜像制作机器的相应目录下并执行镜像制作脚本
scp ./$TMP_DIR/$SERV_TYPE/${TMP_DIR}.tar.gz root@${CREATE_ADDR}:${CREATE_IMAGE_DIR}
ssh root@${CREATE_ADDR} "cd ${CREATE_IMAGE_DIR};
			 tar -zxvf ${TMP_DIR}.tar.gz;
			 bash -x build_image.sh;
			 rm -rf ${TMP_DIR}.tar.gz"

## 删除临时文件
rm -rf ./$TMP_DIR


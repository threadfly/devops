#! /usr/bin/env bash

HOSTIP=$1
REGION=$2
ACCOUNTID=$3
FILEUUID=$4

ssh root@$HOSTIP "cd /data/flowcleaner/unlock && bash unlock.sh $REGION $ACCOUNTID $FILEUUID && cat ./result/verified_flow.$FILEUUID"
#ssh root@$HOSTIP "cd /data/wuff/tools/checker && cat *"


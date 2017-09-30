#! /usr/bin/python

import os
import sys
import getopt

IPLIST = {
# pre 	
	'pre':
		{
		'uvpcflowgcmanager':['192.168.153.97'],
		'unethawkeye':[
			'192.168.153.97'
		],
		'udpnfe': ['192.168.153.97']
		},
# cn-bj2
	'cn-bj2': 
		{
		'unethawkeye':[
			'172.27.245.219'
		],
		'uvpcfe':['', ''],
		'udpnfe': ['172.27.246.49', '172.27.246.50', '172.23.0.140', '172.23.6.236', '172.28.246.81', '172.28.246.82']
		},
# cn-sh2
	'cn-sh2': 
		{
		'unethawkeye':[
			'172.18.38.163'
		],
		'uvpcfe':[''],
		},
# cn-sh
	'cn-sh': 
		{
		'unethawkeye':[
			'172.29.15.68'
		],
		'uvpcfe':[''],
		'udpnfe': ['172.28.38.236', '172.28.38.237', '172.18.37.238', '172.18.37.239']
		},
# cn-gd
	'cn-gd': 
		{
		'unethawkeye':[
			'172.27.4.97'
		],
		'uvpcfe':[''],
		'udpnfe': ['172.27.119.129', '172.27.119.130']
		},
# hk 
	'cn-hk': 
		{
		'unethawkeye':[
			'172.26.17.47'
		],
		'uvpcfe':[''],
		'udpnfe': ['172.26.6.160', '172.26.6.161']
		},
# us-ca 
	'us-ca': 
		{
		'unethawkeye':[
			'172.25.6.101'
		],
		'uvpcfe':[''],
		'udpnfe': ['172.25.0.239', '172.25.0.240']
		},
# us-ws
	'us-ws': 
		{
		'unethawkeye':[
			'172.30.2.237'
		],
		'uvpcfe':[''],
		},
# ge-fra 
	'ge-fra': 
		{
		'unethawkeye':[
			'172.30.6.241'
		],
		'uvpcfe':[''],
		'udpnfe': ['172.30.6.236', '172.30.6.237']
		},
# th-bkk 
	'th-bkk': 
		{
		'unethawkeye':[
			'172.30.22.234'
		],
		'uvpcfe':[''],
		},
# kr-seoul
	'kr-seoul': 
		{
		'unethawkeye':[
			'172.30.10.234'
		],
		'uvpcfe':[''],
		},
# sg
	'sg': 
		{
		'unethawkeye':[
			'172.30.14.243'
		],
		'uvpcfe':[''],
		},
# tw-kh 
	'tw-kh': 
		{
		'unethawkeye':[
			'172.30.18.244'
		],
		'uvpcfe':[''],
		},
# rus-mosc 
	'rus-mosc': 
		{
		'unethawkeye':[
			'172.30.30.179'
		],
		'uvpcfe':[''],
		},
	'jpn-tky': 
		{
		'unethawkeye':[
			'172.30.34.54'
		],
		'uvpcfe':[''],
		},
}

IPLISTFILE = "iplist.data"
loglev="DEBUG"

#
# c: command: pull|deploy|restart|mkdir|stop|rmlog
# i: docker imager
# s: server: uvpcfe|unethawkeye
# l: log level
#
def main():
	opts, args = getopt.getopt(sys.argv[1:], "c:i:s:l:")
	cmd = ""
	src = ""
	serv = ""
	global loglev
	global IPLISTFILE
	for op, value in opts:
		if op == "-c":
			cmd = value
		elif op == "-i": # docker image source
			src = value
		elif op == "-s": # server eg: uvpcfe unethawkeye
			serv = value
		elif op == "-l":
			loglev = value
	#print cmd + "\n"
	#print src + "\n"
	print "----- {0} ".format(loglev)
	IPLISTFILE = serv + "." + IPLISTFILE
	execcmd(cmd, src, serv)

def createIplist(serv):
	global IPLIST
	global IPLISTFILE
	file = open(IPLISTFILE, "w+")
	
	for region in IPLIST:
		for server in IPLIST[region]:
			if server == serv:
				for ip in IPLIST[region][server]:
					if ip != "":
						file.write(ip + "\n")
	file.close()	

def execcmd(cmd, dockerSrc, serv):
	if cmd == "pull":
		pull(dockerSrc, serv)
	elif cmd == "deploy":
		deploy(dockerSrc, serv)
	elif cmd == "restart":
		restart(serv)
	elif cmd == "mkdir":
		makedir(serv)
	elif cmd == "stop":
		dostop()
	elif cmd == "rmlog":
		removelog()
	else:
		useage()

def useage():
	print "	Useage:\n"
	print "		./distribute.py -c pull -i 172.17.1.176:5000/uagent-server:2016xxxx -s uvpcfe|unethawkeye\n"
	print "		./distribute.py -c deploy -i 172.17.1.176:5000/uagent-server:2016xxxx -s uvpcfe|unethawkeye -l INFO|DEBUG\n"
	print "		./distribute.py -c restart|mkdir|stop|rmlog -s uvpcfe|unethawkeye|...\n"
	
def pull(src, serv):
	createIplist(serv)
	print "server docker image pull " + "src:" + src + " serv:" + serv + "\n"
	global IPLISTFILE
	os.system('./distribute.sh ' + "-c pull"+" -i " + src  + " -f " + IPLISTFILE)

def deploy(src, serv):
	global loglev
	print "docker deploy " + "src:" + src + " server:" + serv +  " loglevel:" + loglev +"\n"
	#loglev = "INFO"
	serv2times = {}
	for region in IPLIST:
		for server in IPLIST[region]:
			if server == serv:
				for i in range(0, len(IPLIST[region][server])):

					if IPLIST[region][server][i] == "":
						continue

					if not serv2times.has_key(IPLIST[region][server][i]):
						serv2times[IPLIST[region][server][i]] = 0
					else:
						serv2times[IPLIST[region][server][i]]+=1
						
					container = "%(server_type)s-server-%(port_shift)d" % {'server_type': serv, 'port_shift': serv2times[IPLIST[region][server][i]]}	
					print serv2times
					instanceid = "%d" % (i)
					print "instanceid"
					print instanceid
					shellStr = "./distribute.sh -c deploy -i %(image)s -s %(server_type)s -r %(region)s -n %(container_name)s -l %(loglevel)s -v %(instanceid)s -a %(deploy_addr)s -p %(port_shift)d " % {'image': src, 'server_type': serv, 'region': region, 'container_name': container, 'loglevel': loglev, 'instanceid': instanceid, 'deploy_addr': IPLIST[region][server][i], 'port_shift': serv2times[IPLIST[region][server][i]]}
					print shellStr
					os.system(shellStr)

def restart(serv):
	print "restart all docker server!!!  " + "\n"
	serv2times = {}
	for region in IPLIST:
		for server in IPLIST[region]:
			if server == serv:
				for i in range(0, len(IPLIST[region][server])):
					if IPLIST[region][server][i] == "":
						continue

					if not serv2times.has_key(IPLIST[region][server][i]):
						serv2times[IPLIST[region][server][i]] = 0
					else:
						serv2times[IPLIST[region][server][i]]+=1
						
					container = "%(server_type)s-server-%(port_shift)d" % {'server_type': serv, 'port_shift': serv2times[IPLIST[region][server][i]]}	
					shellStr = "./distribute.sh -c restart -s %(server_type)s -a %(deploy_addr)s -n %(container_name)s" % {'server_type': serv, 'deploy_addr': IPLIST[region][server][i], 'container_name': container }
					print "--------------  " + shellStr
					os.system(shellStr)

def makedir(serv):
	print "make dir: docker-server !!!" + "\n"
	createIplist(serv)
	global IPLISTFILE
	os.system('./distribute.sh ' + "-c mkdir"+ " -f " + IPLISTFILE + " -s " + serv )
	
def removelog(serv):
	print "remove log: docker server !!!" + "\n"
	createIplist(serv)
	global IPLISTFILE
	os.system('./distribute.sh ' + "-c rmlog"+ " -f " + IPLISTFILE + " -s " + serv )
	
def dostop(serv):
	print "do stop !!!\n"
	for region in IPLIST:
		for server in IPLIST[region]:
			if server == serv:
				for i in range(0, len(IPLIST[region][server])):
					os.system('./distribute.sh ' + "-c stop"+ " -s " +  server + " -a " + IPLIST[region][server][i])


main()


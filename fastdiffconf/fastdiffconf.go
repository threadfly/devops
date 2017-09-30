package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"

	"concurrenttask"
)

const (
	TEMPLATE_DIR   = "template"
	CONFIG_TMP_DIR = "tmp"
	DATA_DIR       = "data"
	DATA_FILE_NAME = "data.json"
)

type JsonKV struct {
	RepName  string `json:"repname"`
	RepValue string `json:"repvalue"`
}

type JsonGlobalElem struct {
	ConfigName string   `json:"configname"`
	ConfigPath string   `json:"configpath"`
	Reps       []JsonKV `json:"replace"`
}

type JsonLocalElem struct {
	RemoteIp string   `json:"remoteip"`
	Reps     []JsonKV `json:"replace"`
}

type JsonData struct {
	Global JsonGlobalElem  `json:"global"`
	Local  []JsonLocalElem `json:"local"`
}

type ConfigManager struct {
	JsonData
	Env           string
	ConfigName    string
	TmpConfigPath []string
}

type ConfigTask struct {
	ConfigNameTmp string
	ConfigName    string
	ConfigDir     string
	ServerIP      string
	Err           error
}

func (this *ConfigTask) Run() {
	params := fmt.Sprintf("root@%s:%s%s", this.ServerIP, this.ConfigDir, this.ConfigName)
	fmt.Printf("\n params:%s \n", params)
	cont, err := exec.Command("scp", this.ConfigNameTmp, params).CombinedOutput()
	fmt.Printf("\n cont:%s \n", cont)
	this.Err = err
	return
}

func (this *ConfigTask) IsSucc() bool {
	return this.Err == nil
}

func Replace(k, v, file string) error {
	params := fmt.Sprintf("s#%%\\{%s\\}#%s#", k, v)
	//fmt.Printf("\n params:%s \n", params)
	_, err := exec.Command("sed", "-i", "-E", params, file).CombinedOutput()
	//fmt.Printf("\n cont:%s \n", cont)
	return err
}

func (this *ConfigManager) Init(env, configname string) {
	this.Env = env
	this.ConfigName = configname
	//1. load json data
	jsonDataFile := DATA_DIR + "/" + this.Env + "/" + DATA_FILE_NAME
	jsonContent, err := ioutil.ReadFile(jsonDataFile)
	if err != nil {
		panic(err)
	}

	err = json.Unmarshal(jsonContent, &this.JsonData)
	if err != nil {
		panic(err)
	}
}

func (this *ConfigManager) ProduccConfigTask(taskManager *concurrenttask.ConcurrentTaskManager) bool {
	templateFile := TEMPLATE_DIR + "/" + this.Env + "/" + this.ConfigName
	templateFileCont, err := ioutil.ReadFile(templateFile)
	if err != nil {
		panic(err)
	}

	isSucc := true
	for _, localElem := range this.Local {
		//0. produce tmp dir
		file, err := ioutil.TempFile(CONFIG_TMP_DIR, this.ConfigName)
		if err != nil {
			fmt.Fprintf(os.Stderr, "tempfile create fail, err:%v", err)
			isSucc = false
			break
		}
		//1. cp template file to tmp file
		_, err = file.Write(templateFileCont)
		if err != nil {
			fmt.Fprintf(os.Stderr, "tempfile write fail, err:%v", err)
			isSucc = false
			break
		}
		tmpConfigPath := file.Name()
		this.TmpConfigPath = append(this.TmpConfigPath, tmpConfigPath)
		file.Close()
		//2. sed tmp file use kv
		for _, kv := range this.Global.Reps {
			err = Replace(kv.RepName, kv.RepValue, tmpConfigPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Replace Global Config fail, err:%v, tmpConfigPath:%s", err, tmpConfigPath)
				isSucc = false
			}
		}

		for _, kv := range localElem.Reps {
			err = Replace(kv.RepName, kv.RepValue, tmpConfigPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Replace Local Config fail, err:%v tmpConfigPath:%s", err, tmpConfigPath)
				isSucc = false
			}
		}

		if !isSucc {
			break
		}

		taskManager.PushTask(&ConfigTask{
			ConfigNameTmp: tmpConfigPath,
			ConfigName:    this.JsonData.Global.ConfigName,
			ConfigDir:     this.JsonData.Global.ConfigPath,
			ServerIP:      localElem.RemoteIp,
		})
	}

	return isSucc
}

func (this *ConfigManager) ClearTmpFile() {
	//tmpFile := ""
	//for _, file := range this.TmpConfigPath {
	//tmpFile = +"/" + file
	err := os.RemoveAll(CONFIG_TMP_DIR)
	if err != nil {
		fmt.Printf("remove all tmp file err:%v", err)
	}
	err = os.Mkdir(CONFIG_TMP_DIR, os.ModeDir|os.ModePerm)
	if err != nil {
		fmt.Printf("mkdir tmp file err:%v", err)
	}
	//}
}

var (
	g_ConfigManager *ConfigManager = &ConfigManager{}
	g_ConfEnv                      = flag.String("env", "", "-env pre|stable|gray|master")
	g_ConfName                     = flag.String("cname", "", "-cname config.json")
	g_ShowConf                     = flag.Bool("s", false, "-s")
	g_FlagHelp                     = flag.Bool("h", false, "-h")
	g_Interval                     = flag.Int("i", 4, "-i 8")
)

func usage() {
	fmt.Printf(" usage: fastdiffconf [-h] [-s] [-i n] -cname test.json -env pre|stable|gray|master\n")
	fmt.Printf("        -h: help \n")
	fmt.Printf("        -s: show loaded data.json\n")
	fmt.Printf("        -i: one goroutine deal per n machine\n")
	fmt.Printf("    -cname: template config name\n")
	fmt.Printf("      -env: environment\n")
}

func main() {
	flag.Parse()
	if *g_FlagHelp {
		usage()
		return
	}

	if *g_ConfEnv == "" || *g_ConfName == "" {
		usage()
		return
	}

	g_ConfigManager.Init(*g_ConfEnv, *g_ConfName)
	if *g_ShowConf {
		fmt.Printf("global:%v\n", g_ConfigManager.JsonData.Global)
		fmt.Printf("local:%v\n\n\n", g_ConfigManager.JsonData.Local)
	}

	taskManager := concurrenttask.NewConcurrentTaskManager(*g_Interval)

	if !g_ConfigManager.ProduccConfigTask(taskManager) {
		return
	}

	//return
	taskManager.Process(true)
	fmt.Printf("%s", taskManager.RunTime)

	g_ConfigManager.ClearTmpFile()
}

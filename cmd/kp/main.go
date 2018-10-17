package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"log"

	flag "github.com/spf13/pflag"

	keyprotect "../../client"
)

func PrettyJson(data []byte) []byte {
	var prettified bytes.Buffer
	json.Indent(&prettified, data, "", "  ")
	return prettified.Bytes()
}

func usage() {
	flag.Usage()
}

func main() {
	flag.ErrHelp = errors.New("KeyProtect CLI")

	var instanceId string
	var iamToken string

	flag.StringVar(&instanceId, "instance-id", "", "Instance UUID for KP service")
	flag.StringVar(&iamToken, "iam-token", "", "IAM Auth Token from Bluemix/IBM Cloud client")
	flag.Parse()

	if instanceId == "" {
		log.Fatalln("Must specify instance-id")
	}
	if iamToken == "" {
		log.Fatalln("Must specify iam-token")
	}

	args := flag.Args()

	var subcommand string
	if len(args) == 0 {
		usage()
		return
	} else {
		subcommand = args[0]
	}

	kp := keyprotect.NewKPClient(instanceId, iamToken)

	switch subcommand {
	case "list":
		keys := kp.List()
		fmt.Printf("ID\tNAME\n")
		for _, key := range keys {
			fullKey := kp.Get(key.Id())
			fmt.Printf("%s\t%s\n", fullKey.Id(), fullKey["name"])
		}
	case "create":
		if len(args) < 2 {
			log.Fatal("name argument required for create")
		}
		name := args[1]
		key, err := kp.Generate(name)
		if err == nil {
			fmt.Printf("ID\tNAME\n")
			fmt.Printf("%s\t%s\n", key.Id(), key["name"])
		} else {
			log.Fatalf("Error creating key: %s", err)
		}
	case "delete":
		if len(args) < 2 {
			log.Fatal("ID argument required for delete")
		}
		keyId := args[1]
		err := kp.Delete(keyId)
		if err == nil {
			fmt.Printf("Deleted key: %s\n", keyId)
		} else {
			log.Fatalf("Error deleting key: %s", err)
		}
	default:
		usage()
	}

}

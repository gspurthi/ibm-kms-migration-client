package main

import (
	"bytes"
	"encoding/base64"
	"encoding/csv"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"

	flag "github.com/spf13/pflag"

	keyprotect "../../client"
)

func printBxClientVersion() {
	out, err := exec.Command("bx", "--version").Output()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Output: %s", out)
}

func PrettyJson(data []byte) []byte {
	var prettified bytes.Buffer
	json.Indent(&prettified, data, "", "  ")
	return prettified.Bytes()
}

func main() {
	flag.ErrHelp = errors.New("migration-client is used to copy keys from legacy KeyProtect instances to a new IAM enabled KeyProtect instance")

	var orgId string
	var spaceId string
	var uaaToken string

	var instanceId string
	var iamToken string

	flag.StringVar(&orgId, "org-id", "", "Org UUID for Legacy KP service")
	flag.StringVar(&spaceId, "space-id", "", "Space UUID for Legacy KP service")
	flag.StringVar(&uaaToken, "uaa-token", "", "UAA Auth Token from Bluemix/IBM Cloud client")
	flag.StringVar(&instanceId, "instance-id", "", "Instance UUID for KP service")
	flag.StringVar(&iamToken, "iam-token", "", "IAM Auth Token from Bluemix/IBM Cloud client")
	flag.Parse()

	if orgId == "" {
		log.Fatalln("Must specify org-id")
	}
	if spaceId == "" {
		log.Fatalln("Must specify space-id")
	}
	if uaaToken == "" {
		log.Fatalln("Must specify uaa-token")
	}
	if instanceId == "" {
		log.Fatalln("Must specify instance-id")
	}
	if iamToken == "" {
		log.Fatalln("Must specify iam-token")
	}

	if !strings.HasPrefix(uaaToken, "bearer") && !strings.HasPrefix(uaaToken, "Bearer") {
		uaaToken = "bearer " + uaaToken
	}
	if !strings.HasPrefix(iamToken, "bearer") && !strings.HasPrefix(iamToken, "Bearer") {
		iamToken = "bearer " + iamToken
	}

	legacy := keyprotect.NewLegacyClient(orgId, spaceId, uaaToken)
	kp := keyprotect.NewKPClient(instanceId, iamToken)

	//defer func() {
	//	if r := recover(); r != nil {
	//		fmt.Printf("error during migrate: %+v", r)
	//	}
	//}()

	stateFilePath := "migration.csv"
	stateFile, err := os.OpenFile(stateFilePath, os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		log.Fatalf("error opening state file: %s\n", err)
	}
	defer stateFile.Close()

	csvReader := csv.NewReader(stateFile)
	migrated, err := csvReader.ReadAll()
	if err != nil {
		log.Fatalf("error reading csv file: %s\n", err)
	}
	if len(migrated) == 0 {
		migrated = append(migrated, []string{"old_id", "new_id"})
	}

	oldIdMap := make(map[string]string)
	for _, migrateRecord := range migrated {
		// skip title line
		if migrateRecord[0] == "old_id" {
			continue
		}
		oldIdMap[migrateRecord[0]] = migrateRecord[1]
	}

	writeConsistent := func(records [][]string) error {
		// rewind migrated file
		if _, err := stateFile.Seek(0, 0); err != nil {
			log.Fatalf("error seeking to head of file: %s\n", err)
		}

		csvWriter := csv.NewWriter(stateFile)
		csvWriter.WriteAll(records)

		return csvWriter.Error()
	}

	keys := legacy.List()

	for _, key := range keys {

		if newId, ok := oldIdMap[key.Id()]; ok {
			fmt.Printf("Key already migrated: Old ID: %s, New ID: %s\n", key.Id(), newId)
			continue
		}

		fmt.Printf("Migrating old key [%s]\n", key.Id())
		fullKey := legacy.Get(key.Id())

		if rawPayload, ok := fullKey["payload"]; ok {
			payload := EncodePayload(string(rawPayload.([]byte)))
			fullKey["payload"] = payload
		}

		newKey, err := kp.CreateFromDef(fullKey)
		if err != nil {
			fmt.Printf("Error while creating new key: %s\n", err)
		} else {
			fmt.Printf("Key migrated. Old ID: %s, New ID: %s\n", fullKey.Id(), newKey.Id())
			migrated = append(migrated, []string{fullKey.Id(), newKey.Id()})
			if err := writeConsistent(migrated); err != nil {
				log.Printf("error saving migration state: %s\n", err)
			}
		}
	}
}

func EncodePayload(payload string) string {
	return base64.StdEncoding.EncodeToString([]byte(payload))
}

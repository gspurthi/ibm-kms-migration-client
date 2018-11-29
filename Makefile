NOW := $(shell date +"%c" | tr ' :' '__')
build: migration-client kp

test: build
	bash -c ". envs && bash test/client-wrapper.sh"

%:: cmd/%/main.go
	(cd cmd/$@ && go build -ldflags "-X main.buildTimeStamp=$(NOW)" main.go )
	mkdir -p ./bin && cp cmd/$@/main ./bin/$@

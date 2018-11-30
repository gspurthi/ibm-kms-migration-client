version := $(shell git describe --always)

deps:
	go get -v github.com/spf13/pflag

build: deps migration-client kp

test: build
	bash -c ". envs && bash scripts/client-wrapper.sh"

%:: cmd/%/main.go
	(cd cmd/$@ && go build -ldflags "-X main.buildVersion=$(version)" main.go )
	mkdir -p ./bin && cp cmd/$@/main ./bin/$@

dist:   build
	scripts/build/dist.sh

clean:
	rm -rf build/ dist/ bin/

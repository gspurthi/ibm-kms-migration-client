NOW := $(shell date -u --iso=s )
build: migration-client kp

test: build
	bash -c ". envs && bash scripts/client-wrapper.sh"

%:: cmd/%/main.go
	(cd cmd/$@ && go build -ldflags "-X main.buildTimeStamp=$(NOW)" main.go )
	mkdir -p ./bin && cp cmd/$@/main ./bin/$@

dist:   build
	scripts/build/dist.sh

clean:
	rm -rf build/ dist/ bin/

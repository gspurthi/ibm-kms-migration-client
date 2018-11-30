NOW := $(shell date -u --iso=s )
build: migration-client kp

test: build
	bash -c ". envs && bash scripts/client-wrapper.sh"

%:: cmd/%/main.go
	(cd cmd/$@ && go build -ldflags "-X main.buildTimeStamp=$(NOW)" . ) 
	mkdir -p ./bin && cp cmd/$@/$@ ./bin/$@

dist:
	scripts/build/dist.sh

clean:
	rm -rf bin/
	rm -rf build/ dist/


build: migration-client kp

test: build
	bash -c ". envs && bash test/client-wrapper.sh"

%:: cmd/%/main.go
	(cd cmd/$@ && go build . )
	mkdir -p ./bin && cp cmd/$@/$@ ./bin/$@

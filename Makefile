
build: migration-client kp

test: build
	bash -c ". envs && bash test/client-wrapper.sh"

%:: cmd/%/main.go
	(cd cmd/$@ && go build main.go )
	mkdir -p ./bin && cp cmd/$@/main ./bin/$@

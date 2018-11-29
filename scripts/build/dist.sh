#!/bin/bash

extra_files=(README.md test/client-wrapper.sh sample/envs)

archs=(amd64)
oss=(windows linux darwin)

cmd="migration-client"

for os in ${oss[@]}; do
    for arch in ${archs[@]}; do
        (cd cmd/$cmd/ && GOOS=${os} GOARCH=${arch} go build .)
        binname="${cmd}"
        if [ "$os" == "windows" ]; then
            binname="${binname}.exe"
        fi
        mkdir -p ./build/${os}.${arch} && cp cmd/$cmd/$binname ./build/${os}.${arch}/$binname

        for extra in ${extra_files[@]}; do
            cp $extra ./build/${os}.${arch}/
        done

        mkdir -p dist
        zipname="dist/$cmd-${os}-${arch}.zip"
        echo "Building $zipname"
        zip -r -j $zipname build/${os}.${arch}
    done
done


#!/bin/bash -e

extra_files=(README.md scripts/client-wrapper.sh sample/envs)

archs=(amd64)
oss=(windows linux darwin)

cmd="migration-client"

for os in ${oss[@]}; do
    for arch in ${archs[@]}; do
        (cd cmd/$cmd/ && GOOS=${os} GOARCH=${arch} go build main.go)
        src_name="main"
        dest_name="${cmd}"
        if [ "$os" == "windows" ]; then
            src_name="${src_name}.exe"
            dest_name="${dest_name}.exe"
        fi
        mkdir -p ./build/${os}.${arch} && cp cmd/$cmd/$src_name ./build/${os}.${arch}/$dest_name

        for extra in ${extra_files[@]}; do
            cp $extra ./build/${os}.${arch}/
        done

        mkdir -p dist
        zipname="dist/$cmd-${os}-${arch}.zip"
        echo "Building $zipname"
        zip -r -j $zipname build/${os}.${arch}
    done
done


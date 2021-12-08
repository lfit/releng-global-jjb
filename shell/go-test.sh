#!/bin/bash

set -eux

echo "--> go-test.sh"
go version

#cd test/usecases/oruclosedlooprecovery/goversion/
cd "$GO_ROOT"

go test ./...

echo "--> go-test.sh ends"

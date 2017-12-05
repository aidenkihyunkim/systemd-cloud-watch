ROOT := $(shell pwd)

all: build

SOURCEDIR=./
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')
BINARY_NAME=systemd-cloud-watch
LOCAL_BINARY=bin/local/$(BINARY_NAME)

LINUX_AMD64_BINARY=bin/linux-amd64/$(BINARY_NAME)
DARWIN_AMD64_BINARY=bin/darwin-amd64/$(BINARY_NAME)
WINDOWS_AMD64_BINARY=bin/windows-amd64/$(BINARY_NAME).exe

.PHONY: docker
docker: Dockerfile
	docker run --rm \
	-e TARGET_GOOS=$(TARGET_GOOS) \
	-e TARGET_GOARCH=$(TARGET_GOARCH) \
	-v $(shell pwd)/:/go/src/github.com/castlery/systemd-cloud-watch/ \
	$(shell docker build -f Dockerfile-build -q .)

.PHONY: build
build: $(LOCAL_BINARY)

$(LOCAL_BINARY): $(SOURCES)
	. ./scripts/shared_env && ./scripts/build_binary.sh ./bin/local
	@echo "Built systemd-cloud-watch"

.PHONY: test
test:
	. ./scripts/shared_env && go test -v -timeout 30s -short -cover $(shell go list ./ecr-login/... | grep -v /vendor/)

.PHONY: all-variants
all-variants: linux-amd64 darwin-amd64 windows-amd64

.PHONY: linux-amd64
linux-amd64: $(LINUX_AMD64_BINARY)
$(LINUX_AMD64_BINARY): $(SOURCES)
	./scripts/build_variant.sh linux amd64

.PHONY: darwin-amd64
darwin-amd64: $(DARWIN_AMD64_BINARY)
$(DARWIN_AMD64_BINARY): $(SOURCES)
	./scripts/build_variant.sh darwin amd64

.PHONY: gogenerate
gogenerate:
	./scripts/gogenerate

.PHONY: get-deps
get-deps:
	go get github.com/tools/godep
	go get golang.org/x/tools/cmd/cover
	go get github.com/golang/mock/mockgen
	go get golang.org/x/tools/cmd/goimports

.PHONY: clean
clean:
	rm -rf ./bin/local/ ||:

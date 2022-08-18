###############################
# Common defaults/definitions #
###############################

comma := ,

# Checks two given strings for equality.
eq = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),\
                                $(findstring $(2),$(1))),1)

# Recursively lists all files in the given directory with the given pattern.
rwildcard = $(strip $(wildcard $(1)$(2))\
                    $(foreach d,$(wildcard $(1)*),$(call rwildcard,$(d)/,$(2))))




######################
# Project parameters #
######################

NAME := $(strip $(shell grep -m1 'name: ' pubspec.yaml | cut -d ' ' -f2))
OWNER := $(or $(GITHUB_REPOSITORY_OWNER),team113)
REGISTRIES := $(strip $(subst $(comma), ,\
	$(shell grep -m1 'registry: \["' .github/workflows/ci.yml \
	        | cut -d':' -f2 | tr -d '"][')))

VERSION ?= $(strip $(shell grep -m1 'version: ' pubspec.yaml | cut -d ' ' -f2))
FLUTTER_VER ?= $(strip \
	$(shell grep -m1 'FLUTTER_VER: ' .github/workflows/ci.yml | cut -d':' -f2 \
                                                              | tr -d'"'))




###########
# Aliases #
###########

build: flutter.build


clean: clean.flutter clean.test.e2e


deps: flutter.pub


docs: docs.dart


down: docker.down


e2e: test.e2e


fmt: flutter.fmt


gen: flutter.gen


lint: flutter.analyze


release: git.release


run: flutter.run


test: test.unit


up: docker.up




####################
# Flutter commands #
####################

# Lint Flutter Dart sources with dartanalyzer.
#
# Usage:
#	make flutter.analyze [dockerized=(no|yes)]

flutter.analyze:
ifeq ($(wildcard lib/api/backend/*.graphql.dart),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
ifeq ($(dockerized),yes)
	docker run --rm --network=host -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make flutter.analyze dockerized=no
else
	flutter analyze
endif


# Build Flutter project from sources.
#
# Usage:
#	make flutter.build [( [platform=apk] [split-per-abi=(no|yes)]
#	                    | platform=(appbundle|web|linux|macos|windows|ios) )]
#	                   [dart-env=<VAR1>=<VAL1>[,<VAR2>=<VAL2>...]]
#	                   [dockerized=(no|yes)]

flutter.build:
ifeq ($(wildcard lib/api/backend/*.graphql.dart),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
ifeq ($(dockerized),yes)
ifeq ($(platform),macos)
	$(error Dockerized macOS build is not supported)
else ifeq ($(platform),windows)
	$(error Dockerized Windows build is not supported)
else ifeq ($(platform),ios)
	$(error Dockerized iOS build is not supported)
else
	docker run --rm --network=host -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make flutter.build platform=$(platform) dart-env='$(dart-env)' \
			                   dockerized=no
endif
else
# TODO: `--split-debug-info` should be used on any non-Web platform.
#       1) macOS/iOS `--split-debug-info` can be tracked here:
#          https://github.com/getsentry/sentry-dart/issues/444
#       2) Linux/Windows `--split-debug-info` can be tracked here:
#          https://github.com/getsentry/sentry-dart/issues/433
	flutter build $(or $(platform),apk) --release \
		$(if $(call eq,$(platform),web),--web-renderer html --source-maps,) \
		$(if $(call eq,$(or $(platform),apk),apk),\
		    --split-debug-info=symbols \
		    $(if $(call eq,$(split-per-abi),yes),--split-per-abi,), \
		) \
		$(foreach v,$(subst $(comma), ,$(dart-env)),--dart-define=$(v)) \
		$(if $(call eq,$(platform),ios),--no-codesign,)
endif


# Clean all Flutter dependencies and generated files.
#
# Usage:
#	make flutter.clean [dockerized=(no|yes)]

flutter.clean:
ifeq ($(dockerized),yes)
	docker run --rm --network=host -v "$(PWD)":/app -w /app \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make flutter.clean dockerized=no
else
	flutter clean
	rm -rf .cache/pub/ doc/ \
	       lib/api/backend/*.dart \
	       lib/api/backend/*.g.dart \
	       lib/api/backend/*.graphql.dart \
	       lib/domain/model/*.g.dart
endif


# Format Flutter Dart sources with dartfmt.
#
# Usage:
#	make flutter.fmt [check=(no|yes)] [dockerized=(no|yes)]

flutter.fmt:
ifeq ($(dockerized),yes)
	docker run --rm --network=host -v "$(PWD)":/app -w /app \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make flutter.fmt check=$(check) dockerized=no
else
	flutter format $(if $(call eq,$(check),yes),-n --set-exit-if-changed,) .
endif


# Run `build_runner` Flutter tool to generate project Dart sources.
#
# Usage:
#	make flutter.gen [overwrite=(yes|no)] [dockerized=(no|yes)]

flutter.gen:
ifeq ($(dockerized),yes)
	docker run --rm --network=host -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make flutter.gen overwrite=$(overwrite) dockerized=no
else
	flutter pub run build_runner build \
		$(if $(call eq,$(overwrite),no),,--delete-conflicting-outputs)
endif


# Resolve Flutter project dependencies.
#
# Usage:
#	make flutter.pub [cmd=(get|<pub-cmd>)] [dockerized=(no|yes)]

flutter.pub:
ifeq ($(dockerized),yes)
	docker run --rm --network=host -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make flutter.pub cmd='$(cmd)' dockerized=no
else
	flutter pub $(or $(cmd),get)
endif


# Run built project on an attached device or in an emulator.
#
# Usage:
#	make flutter.run [debug=(yes|no)]
#	                 [device=(<device-id>|linux|macos|windows|chrome)]
#	                 [dart-env=<VAR1>=<VAL1>[,<VAR2>=<VAL2>...]]

flutter.run:
ifeq ($(wildcard lib/api/backend/*.graphql.dart),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
	flutter run $(if $(call eq,$(debug),no),--release,) \
		$(if $(call eq,$(device),),,-d $(device)) \
		$(foreach v,$(subst $(comma), ,$(dart-env)),--dart-define=$(v))




####################
# Testing commands #
####################

# Run Flutter E2E tests.
#
# Usage:
#	make test.e2e [device=(chrome|linux|macos|windows|web-server|<device-id>)]
#	              [dockerized=(no|yes)]
#	              [port=(4444|<port>)]
#	              [gen=(yes|no)] [clean=(no|yes)]
#	              [( [start-app=no]
#	               | start-app=yes [no-cache=(no|yes)] [pull=(no|yes)] )]

test.e2e:
ifeq ($(clean),yes)
	@make clean.e2e
endif
ifneq ($(gen),no)
ifeq ($(wildcard test/e2e/*.g.dart),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
endif
ifeq ($(start-app),yes)
	@make docker.up no-cache=$(no-cache) pull=$(pull) background=yes log=no
endif
ifeq ($(dockerized),yes)
	docker run --rm -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make test.e2e device=$(device) \
			              dockerized=no gen=no clean=no start-app=no
else
	flutter drive --headless -d $(or $(device),chrome) \
	    --driver-port=$(or $(port),4444) \
		--web-renderer html --web-port 50000 \
		--driver=test_driver/integration_test_driver.dart \
		--target=test/e2e/suite.dart
endif
ifeq ($(start-app),yes)
	@make docker.down
endif


# Run Flutter unit tests.
#
# Usage:
#	make test.unit [dockerized=(no|yes)]

test.unit:
ifeq ($(wildcard lib/api/backend/*.graphql.dart),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
ifeq ($(dockerized),yes)
	docker run --rm -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make test.unit dockerized=no
else
	flutter test
endif




##########################
# Documentation commands #
##########################

# Generate project documentation of Dart sources.
#
# Usage:
#	make docs.dart [( [dockerized=no] [open=(no|yes)]
#	                | dockerized=yes )]
#	               [clean=(no|yes)]

docs.dart:
ifeq ($(wildcard lib/api/backend/*.graphql.dart),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
ifeq ($(clean),yes)
	rm -rf doc/api
endif
ifeq ($(dockerized),yes)
	docker run --rm -v "$(PWD)":/app -w /app \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make docs.dart open=no dockerized=no clean=no
else
	flutter pub run dartdoc
ifeq ($(open),yes)
	flutter pub global run dhttpd --path doc/api
endif
endif




#####################
# Cleaning commands #
#####################

clean.e2e: clean.test.e2e


clean.flutter: flutter.clean


# Clean E2E tests generated cache.
#
# Usage:
#	make clean.e2e

clean.test.e2e:
	rm -rf .dart_tool/build/generated/messenger/integration_test \
	       test/e2e/gherkin/reports/




######################
# Copyright commands #
######################

# Populate project sources with copyright notice.
#
# Usage:
#	make copyright [check=(no|yes)]

copyright:
	docker run --rm -v "$(PWD)":/src -w /src \
		ghcr.io/google/addlicense \
			-f NOTICE $(if $(call eq,$(check),yes),-check,-v) \
			$(foreach pat,\
				$(shell grep -v '#' .gitignore | sed 's/^\///' | grep '\S'),\
					-ignore '$(pat)') \
			$(call rwildcard,,*.dart) \
			$(call rwildcard,,*.feature) $(call rwildcard,,.feature) \
			$(call rwildcard,,*.ftl) \
			$(call rwildcard,,*.graphql) \
			$(call rwildcard,,*.kt) \
			$(call rwildcard,helm/,*.conf) \
			$(call rwildcard,helm/,*.tpl) $(call rwildcard,helm/,*.txt) \
			$(call rwildcard,helm/,templates/*.yaml) \
			$(call rwildcard,helm/,values.yaml) \
			web/index.html \
			Dockerfile




###################
# Docker commands #
###################

docker-env = $(strip $(if $(call eq,$(minikube),yes),\
	$(subst export,,$(shell minikube docker-env | cut -d '\#' -f1)),))
docker-registries = $(strip $(if $(call eq,$(registries),),\
                            $(REGISTRIES),$(subst $(comma), ,$(registries))))
docker-tags = $(strip $(if $(call eq,$(tags),),\
                      $(VERSION),$(subst $(comma), ,$(tags))))


# Stop Docker Compose development environment and remove all related containers.
#
# Usage:
#	make docker.down

docker.down:
	-docker-compose down --rmi=local -v


# Build project Docker image.
#
# Usage:
#	make docker.image [tag=(dev|<tag>)]
#	                  [no-cache=(no|yes)]
#	                  [minikube=(no|yes)]

github_url := $(strip $(or $(GITHUB_SERVER_URL),https://github.com))
github_repo := $(strip $(or $(GITHUB_REPOSITORY),$(OWNER)/$(NAME)))

docker.image:
ifeq ($(wildcard build/web),)
	@make flutter.build platform=web dart-env='$(dart-env)' \
	                    dockerized=$(dockerized)
endif
	$(docker-env) \
	docker build --network=host --force-rm \
		$(if $(call eq,$(no-cache),yes),--no-cache --pull,) \
		--label org.opencontainers.image.source=$(github_url)/$(github_repo) \
		--label org.opencontainers.image.revision=$(strip \
			$(shell git show --pretty=format:%H --no-patch)) \
		--label org.opencontainers.image.version=$(strip $(VERSION)) \
		-t $(OWNER)/$(NAME):$(or $(tag),dev) .
# TODO: Enable after first release.
#		--label org.opencontainers.image.version=$(subst v,,$(strip \
			$(shell git describe --tags --dirty --match='v*')))


# Push project Docker images to container registries.
#
# Usage:
#	make docker.push [tags=($(VERSION)|<docker-tag-1>[,<docker-tag-2>...])]
#	                 [registries=($(REGISTRIES)|<prefix-1>[,<prefix-2>...])]
#	                 [minikube=(no|yes)]

docker.push:
	$(foreach tag,$(subst $(comma), ,$(docker-tags)),\
		$(foreach registry,$(subst $(comma), ,$(docker-registries)),\
			$(call docker.push.do,$(registry),$(tag))))
define docker.push.do
	$(eval repo := $(strip $(1)))
	$(eval tag := $(strip $(2)))
	$(docker-env) \
	docker push $(repo)/$(OWNER)/$(NAME):$(tag)
endef


# Tag project Docker image with given tags.
#
# Usage:
#	make docker.tags [of=(dev|<docker-tag>)]
#	                 [tags=($(VERSION)|<docker-tag-1>[,<docker-tag-2>...])]
#	                 [registries=($(REGISTRIES)|<prefix-1>[,<prefix-2>...])]
#	                 [minikube=(no|yes)]

docker.tags:
	$(foreach tag,$(subst $(comma), ,$(docker-tags)),\
		$(foreach registry,$(subst $(comma), ,$(docker-registries)),\
			$(call docker.tags.do,$(or $(of),dev),$(registry),$(tag))))
define docker.tags.do
	$(eval from := $(strip $(1)))
	$(eval repo := $(strip $(2)))
	$(eval to := $(strip $(3)))
	$(docker-env) \
	docker tag $(OWNER)/$(NAME):$(from) $(repo)/$(OWNER)/$(NAME):$(to)
endef


# Save project Docker images to a tarball file.
#
# Usage:
#	make docker.tar [to-file=(.cache/docker/image.tar|<file-path>)]
#	                [tags=($(VERSION)|<docker-tag-1>[,<docker-tag-2>...])]

docker-tar-file = $(or $(to-file),.cache/docker/image.tar)

docker.tar:
	@mkdir -p $(dir $(docker-tar-file))
	docker save -o $(docker-tar-file) \
		$(foreach tag,$(subst $(comma), ,$(or $(tags),$(VERSION))),\
			$(OWNER)/$(NAME):$(tag))


# Load project Docker images from a tarball file.
#
# Usage:
#	make docker.untar [from-file=(.cache/docker/image.tar|<file-path>)]

docker.untar:
	docker load -i $(or $(from-file),.cache/docker/image.tar)


# Run Docker Compose development environment.
#
# Usage:
#	make docker.up [pull=(no|yes)] [no-cache=(no|yes)]
#	               [( [rebuild=no]
#	                | rebuild=yes [dart-env=<VAR1>=<VAL1>[,<VAR2>=<VAL2>...]]
#	                              [dockerized=(no|yes)] )]
#	               [( [background=no]
#	                | background=yes [log=(no|yes)] )]

docker.up: docker.down
ifeq ($(pull),yes)
	docker-compose pull --parallel --ignore-pull-failures
endif
ifeq ($(no-cache),yes)
	rm -rf .cache/cockroachdb/ .cache/coturn/ .cache/minio/
endif
ifeq ($(wildcard .cache/minio),)
	@mkdir -p .cache/minio/data/
endif
ifeq ($(rebuild),yes)
	@make flutter.build platform=web dart-env='$(dart-env)' \
	                    dockerized=$(dockerized)
endif
	docker-compose up \
		$(if $(call eq,$(background),yes),-d,--abort-on-container-exit)
ifeq ($(background),yes)
ifeq ($(log),yes)
	docker-compose logs -f
endif
endif




#################
# Helm commands #
#################

helm-chart := $(or $(chart),messenger)
helm-chart-dir := helm/$(helm-chart)


# Lint project Helm chart.
#
# Usage:
#	make helm.lint [chart=messenger]

helm.lint:
	helm lint $(helm-chart-dir)/


# Build Helm package from project Helm chart.
#
# Usage:
#	make helm.package [chart=messenger]
#	                  [out-dir=(.cache/helm|<dir-path>)] [clean=(no|yes]]

helm-package-dir = $(or $(out-dir),.cache/helm)

helm.package:
ifeq ($(clean),yes)
	@rm -rf $(helm-package-dir)
endif
	@mkdir -p $(helm-package-dir)/
	helm package --destination=$(helm-package-dir)/ $(helm-chart-dir)/


# Create and push Git tag to release project Helm chart.
#
# Usage:
#	make helm.release [chart=messenger]

helm-git-tag = helm/$(helm-chart)/$(strip \
	$(shell grep -m1 'version: ' $(helm-chart-dir)/Chart.yaml | cut -d' ' -f2))

helm.release:
ifeq ($(shell git rev-parse $(helm-git-tag) >/dev/null 2>&1 && echo "ok"),ok)
	$(error "Git tag $(helm-git-tag) already exists")
endif
	git tag $(helm-git-tag)
	git push origin refs/tags/$(helm-git-tag)




################
# Git commands #
################

# Release project version (apply version tag and push).
#
# Usage:
#	make git.release [ver=($(VERSION)|<proj-ver>)]

git-release-tag = $(strip $(or $(ver),$(VERSION)))

git.release:
ifeq ($(shell git rev-parse $(git-release-tag) >/dev/null 2>&1 && echo "ok"),ok)
	$(error "Git tag $(git-release-tag) already exists")
endif
	git tag $(git-release-tag) main
	git push origin refs/tags/$(git-release-tag)




##################
# .PHONY section #
##################

.PHONY: build clean deps docs down e2e fmt gen lint release run test up \
        clean.e2e clean.flutter clean.test.e2e \
        copyright \
        docker.down docker.image docker.push docker.tags docker.tar \
        docker.untar docker.up \
        docs.dart \
        flutter.analyze flutter.clean flutter.build flutter.fmt flutter.gen \
        flutter.pub flutter.run \
        git.release \
        helm.lint helm.package helm.release \
        test.e2e test.unit

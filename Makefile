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

IMAGE_REPO := $(strip $(shell grep 'IMAGE_REPO=' .env | cut -d '=' -f2))
IMAGE_NAME := $(strip $(shell grep 'IMAGE_NAME=' .env | cut -d '=' -f2))

VERSION ?= $(strip $(shell grep -m1 'version: ' pubspec.yaml | cut -d ' ' -f2))
FLUTTER_VER ?= $(strip \
	$(shell grep -m1 'FLUTTER_VER: ' .github/workflows/ci.yml | cut -d':' -f2 \
                                                              | tr -d'"'))




###########
# Aliases #
###########

build: flutter.build


clean: clean.flutter


deps: flutter.pub


docs: docs.dart


fmt: flutter.fmt


gen: flutter.gen


lint: flutter.analyze


release: git.release


run: flutter.run


test: test.unit




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
		$(if $(call eq,$(dart-env),),,--dart-define=$(dart-env)) \
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
		$(if $(call eq,$(dart-env),),,--dart-define=$(dart-env))




####################
# Testing commands #
####################

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

clean.flutter: flutter.clean




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
			$(call rwildcard,,*.graphql) \
			$(call rwildcard,,*.kt) \
			web/index.html \
			Dockerfile




###################
# Docker commands #
###################

docker-env = $(strip $(if $(call eq,$(minikube),yes),\
	$(subst export,,$(shell minikube docker-env | cut -d '\#' -f1)),))

# Authenticate to GitHub Container Registry.
#
# Note that Personal Access Token (PAT) might be required to be passed as a
# password.
#
# Usage:
#	make docker.auth [user=<github-username>] [pass-stdin=(no|yes)]
#	                 [minikube=(no|yes)]

docker.auth:
	$(docker-env) $(if $(call eq,$(token),),,CR_PAT=$(token)) \
	docker login ghcr.io \
		$(if $(call eq,$(user),),,-u $(user)) \
		$(if $(call eq,$(pass-stdin),yes),--password-stdin,)


# Build project Docker image.
#
# Usage:
#	make docker.build [tag=(dev|<tag>)]
#	                  [no-cache=(no|yes)]
#	                  [minikube=(no|yes)]

docker.build:
ifeq ($(wildcard artifacts),)
	mkdir artifacts
endif
ifeq ($(wildcard build/web),)
	@make flutter.build platform=web dart-env='$(dart-env)' \
	                    dockerized=$(dockerized)
endif
	$(docker-env) \
	docker build --network=host --force-rm \
		$(if $(call eq,$(no-cache),yes),--no-cache --pull,) \
		-t $(IMAGE_REPO)/$(IMAGE_NAME):$(or $(tag),dev) .


# Pull project Docker images from Container Registry.
#
# Usage:
#	make docker.pull [repos=($(IMAGE_REPO)|<prefix-1>[,<prefix-2>...])]
#	                 [tags=(@all|<t1>[,<t2>...])]
#	                 [minikube=(no|yes)]

docker-pull-repos = $(or $(repos),$(IMAGE_REPO))
docker-pull-tags = $(or $(tags),@all)

docker.pull:
ifeq ($(docker-pull-tags),@all)
	$(foreach repo,$(subst $(comma), ,$(docker-pull-repos)),\
		$(call docker.pull.do,$(repo)/$(IMAGE_NAME) --all-tags))
else
	$(foreach tag,$(subst $(comma), ,$(docker-pull-tags)),\
		$(foreach repo,$(subst $(comma), ,$(docker-pull-repos)),\
			$(call docker.pull.do,$(repo)/$(IMAGE_NAME):$(tag))))
endif
define docker.pull.do
	$(eval image-full := $(strip $(1)))
	$(docker-env) \
	docker pull $(image-full)
endef


# Push project Docker images to Container Registry.
#
# Usage:
#	make docker.push [repos=($(IMAGE_REPO)|<prefix-1>[,<prefix-2>...])]
#	                 [tags=(dev|<t1>[,<t2>...])]
#	                 [minikube=(no|yes)]

docker-push-repos = $(or $(repos),$(IMAGE_REPO))
docker-push-tags = $(or $(tags),dev)

docker.push:
	$(foreach tag,$(subst $(comma), ,$(docker-push-tags)),\
		$(foreach repo,$(subst $(comma), ,$(docker-push-repos)),\
			$(call docker.push.do,$(repo)/$(IMAGE_NAME):$(tag))))
define docker.push.do
	$(eval image-full := $(strip $(1)))
	$(docker-env) \
	docker push $(image-full)
endef


# Tag project Docker image with given tags.
#
# Usage:
#	make docker.tag [of=(dev|<tag>)]
#	                [repos=($(IMAGE_REPO)|<prefix-1>[,<prefix-2>...])]
#	                [tags=(dev|<t1>[,<t2>...])]
#	                [minikube=(no|yes)]

docker-tag-of := $(or $(of),dev)
docker-tag-with := $(or $(tags),dev)
docker-tag-repos = $(or $(repos),$(IMAGE_REPO))

docker.tag:
	$(foreach tag,$(subst $(comma), ,$(docker-tag-with)),\
		$(foreach repo,$(subst $(comma), ,$(docker-tag-repos)),\
			$(call docker.tag.do,$(repo),$(tag))))
define docker.tag.do
	$(eval repo := $(strip $(1)))
	$(eval tag := $(strip $(2)))
	$(docker-env) \
	docker tag $(IMAGE_REPO)/$(IMAGE_NAME):$(if $(call eq,$(of),),dev,$(of)) \
	           $(repo)/$(IMAGE_NAME):$(tag)
endef


# Save project Docker images to a tarball file.
#
# Usage:
#	make docker.tar [to-file=(.cache/image.tar|<file-path>)]
#	                [tags=(dev|<t1>[,<t2>...])]
#	                [minikube=(no|yes)]

docker-tar-file = $(or $(to-file),.cache/image.tar)
docker-tar-tags = $(or $(tags),dev)

docker.tar:
	@mkdir -p $(dir $(docker-tar-file))
	$(docker-env) \
	docker save -o $(docker-tar-file) \
		$(foreach tag,$(subst $(comma), ,$(docker-tar-tags)),\
			$(IMAGE_REPO)/$(IMAGE_NAME):$(tag))


# Load project Docker images from a tarball file.
#
# Usage:
#	make docker.untar [from-file=(.cache/image.tar|<file-path>)]
#		[minikube=(no|yes)]

docker.untar:
	$(docker-env) \
	docker load -i $(or $(from-file),.cache/image.tar)




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

.PHONY: build clean deps docs fmt gen lint release run test \
        clean.flutter \
        copyright \
        docker.auth docker.build docker.pull docker.push docker.tag docker.tar \
        docker.untar \
        docs.dart \
        flutter.analyze flutter.clean flutter.build flutter.fmt flutter.gen \
        flutter.pub flutter.run \
        git.release \
        test.unit

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

VERSION ?= $(strip $(shell grep -m1 'version: ' pubspec.yaml | cut -d ' ' -f2))
FLUTTER_VER ?= $(strip \
	$(shell grep -m1 'FLUTTER_VER: ' .github/workflows/ci.yml | cut -d':' -f2 \
                                                              | tr -d'"'))




###########
# Aliases #
###########

build: flutter.build


clean: clean.e2e clean.flutter


deps: flutter.pub


docs: docs.dart


e2e: test.e2e


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

# Run Flutter E2E tests.
#
# Usage:
#	make test.e2e [( [start-app=no]
#	               | start-app=yes [TAG=(dev|<docker-tag>)]
#	                               [no-cache=(no|yes)]
#	                               [pull=(no|yes)] )]
#	              [device=(chrome|web-server|macos|linux|windows|<device-id>)]
#	              [dockerized=(no|yes)]
#	              [gen=(no|yes)]

test.e2e:
ifeq ($(if $(call eq,$(gen),yes),,$(wildcard test/e2e/*.g.dart)),)
	@make flutter.gen overwrite=yes dockerized=$(dockerized)
endif
ifeq ($(start-app),yes)
	@make docker.up tag=$(tag) no-cache=$(no-cache) pull=$(pull) \
	                background=yes log=no
	while ! timeout 1 bash -c "echo > /dev/tcp/localhost/4444"; do sleep 1; done
	docker logs -f socmob-webdriver-chrome &
endif
ifeq ($(dockerized),yes)
	docker run --rm -v "$(PWD)":/app -w /app \
	           --network=container:socmob-mobile \
	           -v "$(HOME)/.pub-cache":/usr/local/flutter/.pub-cache \
		ghcr.io/instrumentisto/flutter:$(FLUTTER_VER) \
			make test.e2e dockerized=no start-app=no gen=no device=$(device)
else
	flutter drive --headless -d $(or $(device),chrome) \
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

# Clean E2E tests generated cache.
#
# Usage:
#	make clean.e2e

clean.e2e:
	rm -rf .dart_tool/build/generated/messenger/integration_test \
	       test/e2e/gherkin/reports/

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





# Stop Docker Compose development environment and remove all related containers.
#
# Usage:
#	make docker.down

docker.down:
	docker compose down --rmi=local -v


# Run Docker Compose development environment.
#
# Usage:
#	make docker.up [pull=(no|yes)] [no-cache=(no|yes)]
#	               [tag=(dev|<tag>)]
#	               [rebuild=(no|yes)]
#	               [( [rebuild=no]
#	                | rebuild=yes [dart-env=<VAR1>=<VAL1>[,<VAR2>=<VAL2>...]]
#	                              [dockerized=(no|yes)] )]
#	               [( [background=no]
#	                | background=yes [log=(no|yes)] )]

docker.up: docker.down
ifeq ($(pull),yes)
	COMPOSE_FRONTEND_TAG=$(or $(tag),dev) \
	docker-compose pull --parallel --ignore-pull-failures
endif
ifeq ($(no-cache),yes)
	rm -rf .cache/cockroachdb/ .cache/coturn/ .cache/minio/
endif
ifeq ($(rebuild),yes)
	@make flutter.build platform=web dart-env='$(dart-env)' \
	                    dockerized=$(dockerized)
endif
ifeq ($(wildcard build/web),)
	@make flutter.build platform=web dart-env='$(dart-env)' \
	                    dockerized=$(dockerized)
endif
ifeq ($(wildcard .cache/minio),)
	@mkdir -p .cache/minio/data/
	@chown -R 1001:1001 .cache/minio/
endif
	COMPOSE_FRONTEND_TAG=$(or $(tag),dev) \
	docker-compose up \
		$(if $(call eq,$(background),yes),-d,--abort-on-container-exit)
ifeq ($(background),yes)
ifeq ($(log),yes)
	docker-compose logs -f
endif
endif




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
        clean.e2e clean.flutter \
        copyright \
        docs.dart \
        flutter.analyze flutter.clean flutter.build flutter.fmt flutter.gen \
            flutter.pub flutter.run \
        git.release \
        test.unit

PWD := $(shell pwd)
JENKINS_HOME := $(PWD)/jenkins_home

.PHONY: all
all: init setup restart

.PHONY: init
init: install-prerequisites | $(JENKINS_HOME)/init.groovy.d/admin_user.groovy

.PHONY: install-prerequisites
install-prerequisites:
	pipenv install

$(JENKINS_HOME):
	mkdir -p $(JENKINS_HOME)

$(JENKINS_HOME)/init.groovy.d: | $(JENKINS_HOME)
	mkdir -p $(JENKINS_HOME)/init.groovy.d

$(JENKINS_HOME)/init.groovy.d/admin_user.groovy: | $(JENKINS_HOME)/init.groovy.d
	cp $(PWD)/jenkins_admin_user.groovy $(JENKINS_HOME)/init.groovy.d/admin_user.groovy

.PHONY: up
up:
	. .envrc && pipenv run docker-compose up -d

.PHONY: down
down:
	. .envrc && pipenv run docker-compose down

.PHONY: ps
ps:
	. .envrc && pipenv run docker-compose ps

.PHONY: exec-master
exec-master:
	pipenv run docker-compose exec jenkins /bin/bash

.PHONY: start
start:
	. .envrc && pipenv run docker-compose start

.PHONY: stop
stop:
	. .envrc && pipenv run docker-compose stop

.PHONY: restart
restart:
	. .envrc && pipenv run docker-compose restart jenkins

.PHONY: clean
clean: down

.PHONY: destroy
destroy: clean
	rm -rf jenkins_home/

.PHONY: setup
setup: up install-jenkins-plugins

.PHONY: install-jenkins-plugins
install-jenkins-plugins:
	{ \
		. .envrc ; \
		pluginlist=$$(cat jenkins_plugins.txt | tr '\n' ' ') ; \
		echo "$${pluginlist}" ; \
		pipenv run docker-compose exec jenkins /usr/local/bin/install-plugins.sh $${pluginlist} ; \
	}

# https://stackoverflow.com/a/26339924
# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
.PHONY: list
list:
	@grep '^\.PHONY' ./Makefile | awk '{print $$2}'

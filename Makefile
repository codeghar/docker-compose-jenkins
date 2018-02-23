PWD := $(shell pwd)
JENKINS_HOME := $(PWD)/jenkins_home
JENKINS_URL := http://localhost:8080

.PHONY: create
create: init setup restart-jenkins-master test

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
	. .envrc && pipenv run docker-compose restart
	@{ \
		echo 'Check Jenkins master is available' ; \
		while [[ $$(curl -s -w "%{http_code}" -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)' $(JENKINS_URL)/ -o /dev/null) != "200" ]]; do \
			sleep 5 ; \
		done ; \
		echo 'Jenkins master is now available' ; \
	}

# https://stackoverflow.com/a/30082067
.PHONY: restart-jenkins-master
restart-jenkins-master:
	@{ \
		. .envrc ; \
		echo 'Restarting Jenkins master' ; \
		while [[ $$(curl -s -w "%{http_code}" -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)' $(JENKINS_URL)/ -o /dev/null) != "200" ]]; do \
			sleep 5 ; \
		done ; \
		curl --request POST -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)' $(JENKINS_URL)/quietDown ; \
		curl --request POST -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)' $(JENKINS_URL)/restart ; \
		while [[ $$(curl -s -w "%{http_code}" -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)' $(JENKINS_URL)/ -o /dev/null) != "200" ]]; do \
			sleep 5 ; \
		done ; \
		echo 'Jenkins master is now available' ; \
	}

.PHONY: clean
clean: down

.PHONY: destroy
destroy: clean
	rm -rf jenkins_home/

.PHONY: setup
setup: up install-jenkins-plugins

.PHONY: install-jenkins-plugins
install-jenkins-plugins:
	@{ \
		. .envrc ; \
		pluginlist=$$(cat jenkins_plugins.txt | tr '\n' ' ') ; \
		echo "$${pluginlist}" ; \
		pipenv run docker-compose exec jenkins /usr/local/bin/install-plugins.sh $${pluginlist} ; \
	}

# https://stackoverflow.com/a/12730830
.PHONY: test
test:
	@echo 'Check all required plugins are installed'
	@{ \
		. .envrc ; \
		curl -s --request GET -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)' $(JENKINS_URL)/pluginManager/api/json?depth=1 | jq '[ ."plugins"[] | .shortName ]' > /tmp/jenkins_plugins_actual ; \
		sleep 2 ; \
		while read LINE  ; \
		do  \
			grep "\"$${LINE}\"," /tmp/jenkins_plugins_actual ; \
		done <$(PWD)/jenkins_plugins.txt ; \
		rm -f /tmp/jenkins_plugins_actual ; \
	}
	@echo 'All required plugins are installed'

# https://stackoverflow.com/a/26339924
# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
.PHONY: list
list:
	@grep '^\.PHONY' ./Makefile | awk '{print $$2}'

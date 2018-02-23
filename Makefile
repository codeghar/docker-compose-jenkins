PWD := $(shell pwd)
BIN := $(PWD)/bin
JENKINS_HOME := $(PWD)/jenkins_home
JENKINS_AUTH := -u '$(JENKINS_LEADER_ADMIN_USER)':'$(JENKINS_LEADER_ADMIN_PASSWORD)'

.PHONY: create
create: init jenkins-master-setup restart-jenkins-master jenkins-master-test jenkins-cli-setup

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
	. .envrc && $(BIN)/check-jenkins-available.sh

# https://stackoverflow.com/a/30082067
.PHONY: restart-jenkins-master
restart-jenkins-master:
	@{ \
		. .envrc ; \
		$(BIN)/check-jenkins-available.sh ; \
		echo 'Restarting Jenkins master' ; \
		curl --request POST $(JENKINS_AUTH) $(JENKINS_URL)/quietDown ; \
		curl --request POST $(JENKINS_AUTH) $(JENKINS_URL)/restart ; \
		$(BIN)/check-jenkins-available.sh ; \
	}

.PHONY: clean
clean: down

.PHONY: destroy
destroy: clean
	rm -rf cli/
	rm -rf jenkins_home/

.PHONY: jenkins-master-up
jenkins-master-up:
	. .envrc && pipenv run docker-compose up -d jenkins
	. .envrc && $(BIN)/check-jenkins-available.sh

.PHONY: jenkins-master-setup
jenkins-master-setup: jenkins-master-up install-jenkins-plugins

.PHONY: install-jenkins-plugins
install-jenkins-plugins:
	@{ \
		. .envrc ; \
		pluginlist=$$(cat jenkins_plugins.txt | tr '\n' ' ') ; \
		echo "$${pluginlist}" ; \
		pipenv run docker-compose exec jenkins /usr/local/bin/install-plugins.sh $${pluginlist} ; \
	}

.PHONY: jenkins-cli-setup
jenkins-cli-setup: | $(PWD)/cli/jenkins-cli.jar
	. .envrc && pipenv run docker-compose up -d cli

$(PWD)/cli:
	mkdir -p $(PWD)/cli

$(PWD)/cli/jenkins-cli.jar: | $(PWD)/cli
	curl -s -o $(PWD)/cli/jenkins-cli.jar $(JENKINS_AUTH) $(JENKINS_URL)/jnlpJars/jenkins-cli.jar

.PHONY: exec-cli
exec-cli:
	pipenv run docker-compose exec cli /bin/bash

# https://stackoverflow.com/a/12730830
.PHONY: jenkins-master-test
jenkins-master-test:
	echo $(JENKINS_AUTH)
	. .envrc && $(BIN)/check-jenkins-available.sh
	@echo 'Check all required plugins are installed'
	@{ \
		. .envrc ; \
		curl -s --request GET $(JENKINS_AUTH) $(JENKINS_URL)/pluginManager/api/json?depth=1 | jq '[ ."plugins"[] | .shortName ]' > /tmp/jenkins_plugins_actual ; \
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

#!groovy

// Source: https://technologyconversations.com/2017/06/16/automating-jenkins-docker-setup/

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def env = System.getenv()
String user= env['JENKINS_LEADER_ADMIN_USER']
String passwd= env['JENKINS_LEADER_ADMIN_PASSWORD']

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(user, passwd)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()

Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

#!/bin/sh

echo 'Check Jenkins master is available'

while [ "$(curl -s -w '%{http_code}' -u "${JENKINS_LEADER_ADMIN_USER}":"${JENKINS_LEADER_ADMIN_PASSWORD}" "${JENKINS_URL}"/ -o /dev/null)" != "200" ]; do
    sleep 5
done

echo 'Jenkins master is now available'

# Jenkins with Docker Compose

Create a sandbox/playground with Docker Compose to learn Jenkins 2, test your
config or ideas, etc.

# Requirements

* Docker
* Python 3.6+
* [pipenv](https://docs.pipenv.org/)
* GNU make

# Initial Setup

        $ make all

1. Installs required Python packages using ``pipenv``.
2. Creates *./jenkins_home/* directory, to be mounted in the Jenkins master container.
3. Copies *jenkins_admin_user.groovy* to *jenkins_home/init.groovy.d/*. This file creates a default admin user without needing to do the same in the web interface. See customization section for more information.
4. Creates the Jenkins master container.
5. Installs plugins listed in *jenkins_plugins.txt*. See customization section to see how to install your desired plugins.
6. Restarts the Jenkins master container. This gives the Jenkins master to load all settings since changes were made.
7. Runs ``git update-index --assume-unchanged ./docker-compose.yml`` to ignore any changes made to the file as described in the Customize section. Manually revert this with ``git update-index --no-assume-unchanged ./docker-compose.yml``.

# Environment Lifecycle

``docker-compose`` is used to manage the lifecycle of containers. Helper
targets in ``make`` are *up*, *down*, *start*, *stop*, and *ps* based on their
counterparts *up -d*, *down*, *start*, *stop*, and *ps* respectively in
``docker-compose``.

        $ make up
        $ make ps
        $ make stop
        $ make start
        $ make down

Run ``bash`` in Jenkins master container.

        $ make exec-master

Get a list of all ``make`` targets.

        $ make list

The *Makefile* is pretty simple; feel free to read it for more information.

## Caution

Cleaning up the environment is synonymous with *down*.

        $ make clean

## Alert

Destroying the environment removes all containers and rolls back changes made
to the git repo in the *init* target.

        $ make destroy

1. Destroys all containers.
2. Deletes *jenkins_home* directory.

# Customize

These files are prime candidates to customize for your needs.

## .envrc

Contains authentication credentials for Jenkins master and ssh login
credentials for Jenkins minion (build node).

Strongly suggest to change sensitive values using more secure options.

## jenkins_admin_user.groovy

It's a Groovy script that creates an admin user in Jenkins master. The values
for user name and password are read in the container from environment variables
*JENKINS_LEADER_ADMIN_USER* and *JENKINS_LEADER_ADMIN_PASSWORD* respectively.

Source:
[Automating Jenkins Docker Setup](https://technologyconversations.com/2017/06/16/automating-jenkins-docker-setup/).

## jenkins_plugins.txt

Modify this list to include the plugins you want to install.
[Jenkins Plugins Index](https://plugins.jenkins.io) has more information.

Based on [issue 348](https://github.com/jenkinsci/docker/issues/348), a
workaround is used in the Makefile.

## docker-compose.yml

Mounts *jenkins_home* directory (created by ``make all`` or more specifically
by ``make init``) into the Jenkins master container.

*JAVA_OPTS* environment variable is used to
[disable the setup wizard](https://groups.google.com/d/msg/jenkinsci-users/Pb4QZVc2-f0/PJnKcbieBgAJ)
since all that work is done through automation.

## Makefile

May not require too much attention but you never know.

# Notes

Instead of creating a Docker image based on the upstream Jenkins image, I chose
to do all the work at runtime in the container. This provides more flexibility
to customize your experience. If you're happy with what you see and get here,
you can create your own Docker image if so desired.

The official and community documentation of Jenkins uses the words *master* and
*slave*. I dislike the word *slave*. Instead, I use *minion*.

# TODO

Configure Jenkins minions to be Docker container(s) as well.

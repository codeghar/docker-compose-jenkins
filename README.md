# Jenkins with Docker Compose

Create a sandbox/playground with Docker Compose to learn Jenkins 2, test your
config or ideas, etc.

# Requirements

* Docker
* Python 3.6+
* [pipenv](https://docs.pipenv.org/)

# Optional

* direnv

# Initial Setup

        $ pipenv install

Installs required Python packages using ``pipenv``.

The drawback is that you either activate the Python virtualenv once with
``pipenv shell`` (*preferred*) or prepend ``pipenv run`` to every command. If
you go the ``pipenv shell`` route, you only have to activate it *once* and then
run ``invoke`` or ``docker-compose`` as needed. When you're done, you can
``deactivate`` the virtualenv.

        $ invoke

[Invoke](http://docs.pyinvoke.org/en/latest/) is used to run the *create* and
*destroy* tasks described below. It's a task execution mechanism similar to
``make``. It runs the tasks in *tasks.py*.

        $ direnv allow

If you have installed ``direnv``
([highly recommended](https://github.com/direnv/direnv)), it uses *.envrc* file
to export the required environment variables as long as you are in this
directory.

# Create

        $ pipenv shell  # activate Python virtualenv
        $ . .envrc  # export required environment variables; not needed if you have direnv
        $ invoke create

1. Creates *./jenkins_home/* directory, to be mounted in the Jenkins master container.
2. Copies *jenkins_admin_user.groovy* to *jenkins_home/init.groovy.d/* directory. This file creates a default admin user without needing to do the same in the web interface. See customization section for more information.
3. Creates the Jenkins master container.
4. Downloads *jenkins-cli.jar* from Jenkins server to *./cli* directory.
5. Creates a container (called *cli*) to run *jenkins-cli.jar* and mounts *./cli* directory in it.
6. Installs plugins listed in *jenkins_plugins.txt*. See customization section to see how to install your desired plugins.
7. Verifies all plugins were installed successfully.

# Destroy

        $ pipenv shell  # activate Python virtualenv
        $ . .envrc  # export required environment variables; not needed if you have direnv
        $ invoke destroy

1. Destroys all containers.
2. Deletes *cli* and *jenkins_home* directories.

# Container Lifecycle

        $ pipenv shell  # activate Python virtualenv
        $ . .envrc  # export required environment variables; not needed if you have direnv
        $ docker-compose

``docker-compose`` is used to manage the lifecycle of containers.

Run ``bash`` in Jenkins master container.

        $ pipenv shell  # activate Python virtualenv
        $ docker-compose exec jenkins bash

Run ``bash`` in Jenkins cli container.

        $ pipenv shell  # activate Python virtualenv
        $ docker-compose exec cli bash

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

### jenkins

Uses the official distribution of Jenkins in a Docker image.

Mounts *jenkins_home* directory (created by ``make create`` or more
specifically by ``make init``) into the Jenkins master container.

*JAVA_OPTS* environment variable is used to
[disable the setup wizard](https://groups.google.com/d/msg/jenkinsci-users/Pb4QZVc2-f0/PJnKcbieBgAJ)
since all that work is done through automation.

### cli

Uses the official distribution of OpenJDK JRE in a Docker image.

Mounts *cli* directory (created by ``make create``) into the cli container.

The *JENKINS_URL* environment variable -- when set -- is picked up by the cli
and the user does not need to provide the ``-s`` flag anymore ([Source](https://jenkins.io/doc/book/managing/cli/#using-the-client)).
In this instance, since both containers are on the same Docker network, using
the name of the Jenkins container works.

# Notes

Instead of creating a Docker image based on the upstream Jenkins image, I chose
to do all the work at runtime in the container. This provides more flexibility
to customize your experience. If you're happy with what you see and get here,
you can create your own Docker image if so desired.

The official and community documentation of Jenkins uses the words *master* and
*slave*. I dislike the word *slave*. Instead, I use *minion*.

# TODO

Configure Jenkins minions to be Docker container(s) as well.

## Introduction

[hyrax3_app](https://github.com/CottageLabs/hyrax3_app) is an application based on [Hyrax 3.3](https://github.com/samvera/hyrax/releases/tag/v3.3.0) stack by [Cottage Labs](https://cottagelabs.com/) and [AntLeaf](https://antleaf.com/). It is built with Docker containers, which simplify development and deployment onto live services.

## Code Status

[![CircleCI Status for CottageLabs/hyrax3_app](https://circleci.com/gh/CottageLabs/hyrax3_app/tree/master.svg?style=svg)](https://circleci.com/gh/CottageLabs/hyrax3_app)

[![Coverage Status](https://coveralls.io/repos/github/CottageLabs/hyrax3_app/badge.svg?branch=master)](https://coveralls.io/github/CottageLabs/hyrax3_app?branch=master)
## Getting Started

Clone the repository with `git clone https://github.com/CottageLabs/hyrax3_app.git`.

Ensure you have docker and docker-compose.

Open a console and try running `docker -h` and `docker-compose -h` to verify they are both accessible.

Create the environment file `.env`. You can start by copying the template file [.env.template.development](https://github.com/CottageLabs/hyrax3_app/blob/master/.env.template.development) to `.env` and customizing the values to your setup. (For production environment, use .env.template as your template)

## quick start
If you would like to do a test run of the system, start the docker containers
```bash
$ cd hyrax3_app
$ docker-compose up -d
```
You should see the containers being built and the services start.

## Docker compose explained

There are 4 `docker-compose` files provided in the repository, which build the containers running the services as shown above
* [docker-compose.yml](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml) is the main docker-compose file. It builds all the core servcies required to run the application
* [fcrepo](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L13-L22) is the container running the [Fedora 4 commons repository](https://wiki.duraspace.org/display/FEDORA47/Fedora+4.7+Documentation), an rdf document store. By default, this runs the fedora service on port 8080 internally in docker (http://fcrepo:8080/fcrepo/rest).<br/><br/>
* [Solr container](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L24-L45) runs [SOLR](lucene.apache.org/solr/), an enterprise search server. By default, this runs the SOLR service on port 8983 internally in docker (http://solr:8983).<br/><br/>
* [db containers](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L47-L76) running a postgres database, used by the Hyrax application and Fedora. By default, this runs the database service on port 5432 internally in docker.<br/><br/>
* [redis container](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L121-L132) running [redis](https://redis.io/), used by Hyrax to manage background tasks. By default, this runs the redis service on port 6379 internally in docker.<br/><br/>
* [app container](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L78-L96) sets up the [Hyrax] application, which is then used by 2 services - web and workers.<br/><br/>
  * [Web container](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L98-L110) runs the application. By default, this runs on port 3000 internally in docker (http://web:3000). <br/><br/>This container runs [docker-entrypoint.sh](https://github.com/CottageLabs/hyrax3_app/blob/master/hyrax/docker-entrypoint.sh). It needs the database, solr and fedora containers to be up and running. It waits for 15s to ensure Solr and fedora are running and exits if they are not. It [runs a rake task](https://github.com/CottageLabs/hyrax3_app/blob/master/hyrax/docker-entrypoint.sh#L39-L40), ([https://github.com/CottageLabs/hyrax3_app/blob/master/hyrax/lib/tasks/setup_hyrax.rake)) to setup the application. <br/><br/>The default workflows are loaded, the default admin set and collection types are created as a part of the setup.<br/><br/>
  * [Wokers container](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.yml#L112-L119) runs the background tasks for materials data repository, using [sidekiq](https://github.com/mperham/sidekiq) and redis. By default, this runs the worker service. <br/><br/> Hyrax processes long-running or particularly slow work in background jobs to speed up the web request/response cycle. When a user submits a file through a work (using the web or an import task), there a humber of background jobs that are run, initilated by the hyrax actor stack, as explained [here](https://samvera.github.io/what-happens-deposit-2.0.html)<br/><br/>You can monitor the background workers using the materials data repository service at http://web:3000/sidekiq when logged in as an admin user. <br/><br/>
* [docker-compose.override.yml](https://github.com/CottageLabs/hyrax3_app/blob/master/docker-compose.override.yml) This file exposes the ports for fcrepo, solr and the hyrax web container, so they an be accessed outside the container. If running this service in development or test, we could use this file. <br/>


The data for the application is stored in docker named volumes as specified by the compose files. These are:

```bash
$ docker volume list -f name=hyrax3
DRIVER    VOLUME NAME
local     hyrax3_app_app
local     hyrax3_app_cache
local     hyrax3_app_db
local     hyrax3_app_db-fcrepo
local     hyrax3_app_derivatives
local     hyrax3_app_fcrepo
local     hyrax3_app_file_uploads
local     hyrax3_app_redis
local     hyrax3_app_solr
```

These will persist when the system is brought down and rebuilt. Deleting them will require importers etc. to run again.


## Running in development or test

When running in development and test environment, prepare your .env file using .env.template.development as the template. You need to use `docker-compose -f docker-compose.yml -f docker-compose.override.yml`. This will use the docker-compose.yml file and the docker-compose.override.yml file and not use the docker-compose-production.yml.
  * fcrepo container will run the fedora service, which will be available in port 8080 at  http://localhost:8080/fcrepo/rest
  * Solr container will run the Solr service, which will be available in port 8983 at  http://localhost:8983
  * The web container runs the materials data repository service, which will be available in port 3000 at http://localhost:3000

You could setup an alias for docker-compose on your local machine, to ease typing

```bash
alias hd='docker-compose -f docker-compose.yml -f docker-compose.override.yml'
```

### Yarn and static assets

Static asset build is only run in `production` environment to speed up container creation in develop. To see features such as the IIIF viewer, `yarn install` must be run on the web container once it's up.

```
hd run web yarn install
```

## Running in production

When running in production, prepare your .env file using .env.template as the template (not .env.template.development). You need to use `docker-compose -f docker-compose.yml -f docker-compose-production.yml`, replacing docker-compose.override.yml with docker-compose-production.yml. To assist this, an alias similar to that below can be useful:

```bash
alias hd='docker-compose -f docker-compose.yml'
```

* The service will run without the ports of intermediary services such as Solr being exposed to the host.
* Materials data repository is accessible at port 443, http requests to port 80 will be redirected to https.

## Builidng, starting and managing the service with docker

### Build the docker container

To start with, you would need to build the system, before running the services. To do this you need to issue the `build` command
```bash
$ hd build
```

### Start and run the services in the containers

To run the containers after build, issue the `up` command (-d means run as daemon, in the background):

```bash
$ hd up -d
```
The containers should all start and the services should be available in their end points as described above
* web server at http://localhost:3000 in development and https://domain-name in production

### docker container status and logs

You can see the state of the containers with `docker-compose ps`, and view logs e.g. for the web container using `docker-compose logs web`

The services that you would need to monitor the logs for are docker mainly web and workers.


### Some example docker commands and usage:

[Docker cheat sheet](https://github.com/wsargent/docker-cheat-sheet)

```bash
# Bring the whole application up to run in the background, building the containers
hd up -d --build

# Stop the container
hd stop

# Halt the system
hd down

# Re-create the nginx container without affecting the rest of the system (and run in the background with -d)
hd up -d --build --no-deps --force-recreate nginx

# View the logs for the web application container
hd logs web

# Create a log dump file
hd logs web | tee web_logs_`date --iso-8601`
# (writes to e.g. web_logs_2022-02-14)

# View all running containers
hd ps
# (example output:)
$ hd ps
NAME                    COMMAND                  SERVICE             STATUS              PORTS
hyrax3_app-app-1        "irb"                    app                 exited (0)          
hyrax3_app-appdb-1      "docker-entrypoint.s…"   appdb               running (healthy)   5432/tcp
hyrax3_app-db-1         "docker-entrypoint.s…"   db                  running             5432/tcp
hyrax3_app-fcrepo-1     "catalina.sh run"        fcrepo              running             0.0.0.0:8080->8080/tcp, :::8080->8080/tcp
hyrax3_app-fcrepodb-1   "docker-entrypoint.s…"   fcrepodb            running (healthy)   5432/tcp
hyrax3_app-redis-1      "docker-entrypoint.s…"   redis               running (healthy)   6379/tcp
hyrax3_app-solr-1       "docker-entrypoint.s…"   solr                running (healthy)   0.0.0.0:8983->8983/tcp, :::8983->8983/tcp
hyrax3_app-web-1        "bash -c /bin/docker…"   web                 running             0.0.0.0:3000->3000/tcp, :::3000->3000/tcp
hyrax3_app-workers-1    "bundle exec sidekiq"    workers             exited (1)          

# Using its container name, you can run a shell in a container to view or make changes directly
docker exec -it hyrax3_app-web-1 /bin/bash
```

## Backups

There is [docker documentation](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes) advising how to back up volumes and their data.

### System initialisation and configuration

* As mentioned above, there is a `.env` file containing application secrets. This **must not** be checked into version control!

* The system is configured on start-up using the `docker-entrypoint.sh` script, which configures users in the `seed/setup.json` file.


  

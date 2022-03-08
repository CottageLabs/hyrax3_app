#!/bin/bash

echo "current env $RAILS_ENV"
echo "Creating log folder"
mkdir -p $APP_WORKDIR/log

if [ "$RAILS_ENV" = "production" ]; then
    # Verify all the production gems are installed
    bundle check
else
    # install any missing development gems (as we can tweak the development container without rebuilding it)
    bundle check || bundle install --without production
fi

# wait for Solr and Fedora to come up
sleep 15s

## Run any pending migrations, if the database exists
## If not setup the database
bundle exec rake db:exists && bundle exec rake db:migrate || bundle exec rake db:setup

# setup test db for unit test
if [ "$RAILS_ENV" != "production" ]; then
  echo "setup test db for unit testing"
  bundle exec rake db:setup RAILS_ENV=test
  bundle exec rake db:migrate RAILS_ENV=test
fi

# check that Solr is running
SOLR=$(curl --silent --connect-timeout 45 "http://${SOLR_HOST:-solr}:${SOLR_PORT:-8983}/solr/" | grep "Apache SOLR")
if [ -n "$SOLR" ] ; then
    echo "Solr is running..."
else
    echo "ERROR: Solr is not running"
    exit 1
fi

# check that Fedora is running
FEDORA=$(curl --silent --connect-timeout 45 "http://${FEDORA_HOST:-fcrepo}:${FEDORA_PORT:-8080}/fcrepo/" | grep "Fedora Commons Repository")
if [ -n "$FEDORA" ] ; then
    echo "Fedora is running..."
else
    echo "ERROR: Fedora is not running"
    exit 1
fi

echo "Setting up hyrax... (this can take a few minutes)"
bundle exec rake hyrax3_app:setup_hyrax["seed/setup.json"]
npm install --unsafe-perm  # install uv, --unsafe-perm for root permission

# echo "--------- Starting Hyrax in $RAILS_ENV mode ---------"
rm -f /tmp/hyrax.pid
bundle exec rails server -p 3000 -b '0.0.0.0' --pid /tmp/hyrax.pid

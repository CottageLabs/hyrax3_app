#!/bin/bash

echo "Creating log folder"
mkdir -p $APP_WORKDIR/log

if [ "$RAILS_ENV" = "production" ]; then
    # Verify all the production gems are installed
    bundle check
else
    # install any missing development gems (as we can tweak the development container without rebuilding it)
    bundle check || bundle install --without production
fi

## Run any pending migrations, if the database exists
## If not setup the database
bundle exec rake db:exists && bundle exec rake db:migrate || bundle exec rake db:setup

# Check solr and fedora are running
n=0
solr_running=false
fedora_running=false
while [[ $n -lt 15 ]]
do
    # check Solr is running
    if [ "solr_running" = false ] ; then
      SOLR=$(curl --silent --connect-timeout 45 "http://${SOLR_HOST:-solr}:${SOLR_PORT:-8983}/solr/" | grep "Apache SOLR")
      if [ -n "$SOLR" ] ; then
          echo "Solr is running"
          solr_running=true
      fi
    fi

    # check Fedora is running
    if [ "fedora_running" = false ] ; then
      FEDORA=$(curl --silent --connect-timeout 45 "http://${FEDORA_HOST:-fcrepo}:${FEDORA_PORT:-8080}/fcrepo/" | grep "Fedora Commons Repository")
      if [ -n "$FEDORA" ] ; then
          echo "Fedora is running"
          fedora_running=true
      fi
    fi

    if [ "solr_running" = true ] &&  [ "fedora_running" = true ] ; then
      break
    else
      sleep 1
    fi
    n=$(( n+1 ))
done

# Exit if Solr is not running
if [ "solr_running" = false ] ; then
    echo "ERROR: Solr is not running"
    exit 1
fi

# Exit if Fedora is not running
if [ "fedora_running" = false ] ; then
    echo "ERROR: Fedora is not running"
    exit 1
fi

echo "Setting up hyrax... (this can take a few minutes)"
bundle exec rake hyrax3_app:setup_hyrax["seed/setup.json"]

# echo "--------- Starting Hyrax in $RAILS_ENV mode ---------"
rm -f /tmp/hyrax.pid
bundle exec rails server -p 3000 -b '0.0.0.0' --pid /tmp/hyrax.pid

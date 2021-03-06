APPS = asset-manager content-store govuk-content-schemas government-frontend \
	publishing-api router router-api rummager \
	specialist-publisher static travel-advice-publisher collections-publisher \
	collections frontend publisher calendars \
	manuals-publisher manuals-frontend whitehall content-tagger \
	contacts-admin finder-frontend

RUBY_VERSION = `cat .ruby-version`
DOCKER_RUN = docker run --rm -v `pwd`:/app ruby:$(RUBY_VERSION)
DOCKER_COMPOSE_CMD = docker-compose -f docker-compose.yml
TEST_PROCESSES := 1

ifndef JENKINS_URL
  DOCKER_COMPOSE_CMD += -f docker-compose.development.yml
endif

ifndef TEST_ARGS
  TEST_ARGS = spec -o '--tag ~flaky --tag ~new'
endif

TEST_CMD = $(DOCKER_COMPOSE_CMD) run publishing-e2e-tests bundle exec parallel_rspec -n $(TEST_PROCESSES) $(TEST_ARGS)

all:
	$(MAKE) clone
	$(MAKE) stop
	$(MAKE) clean_docker
	$(MAKE) pull build
	$(MAKE) start
	$(MAKE) test
	$(MAKE) stop

$(APPS):
	bin/clone-app $@

clone: $(APPS)

kill:
	$(DOCKER_COMPOSE_CMD) kill
	$(DOCKER_COMPOSE_CMD) rm -f

build: kill
	$(DOCKER_COMPOSE_CMD) build diet-error-handler publishing-e2e-tests $(APPS_TO_BUILD)

setup:
	bundle exec rake docker:wait_for_dbs
	$(MAKE) setup_dbs
	bundle exec rake docker:wait_for_rabbitmq
	$(MAKE) setup_queues
	$(MAKE) clean_tmp
	bundle exec rake docker:wait_for_publishing_api
	$(MAKE) publish_routes
	$(DOCKER_COMPOSE_CMD) run --rm publishing-e2e-tests bundle exec rake govuk:wait_for_router
	bundle exec rake docker:wait_for_apps

setup_dbs: router_setup content_store_setup asset_manager_setup \
  publishing_api_setup travel_advice_setup whitehall_setup \
  content_tagger_setup manuals_publisher_setup specialist_publisher_setup \
  publisher_setup collections_publisher_setup rummager_setup contacts_admin_setup

router_setup:
	$(DOCKER_COMPOSE_CMD) exec -T router-api bundle exec rake db:purge
	$(DOCKER_COMPOSE_CMD) exec -T draft-router-api bundle exec rake db:purge

content_store_setup:
	$(DOCKER_COMPOSE_CMD) exec -T content-store bundle exec rake db:purge
	$(DOCKER_COMPOSE_CMD) exec -T draft-content-store bundle exec rake db:purge

asset_manager_setup:
	$(DOCKER_COMPOSE_CMD) exec -T asset-manager bundle exec rake db:purge

publishing_api_setup:
	$(DOCKER_COMPOSE_CMD) exec -T publishing-api bundle exec rake db:setup

travel_advice_setup:
	$(DOCKER_COMPOSE_CMD) exec -T travel-advice-publisher bundle exec rake db:seed

whitehall_setup:
	$(DOCKER_COMPOSE_CMD) exec -T whitehall-admin bundle exec rake db:create db:purge db:setup

content_tagger_setup:
	$(DOCKER_COMPOSE_CMD) exec -T content-tagger bundle exec rake db:setup

manuals_publisher_setup:
	$(DOCKER_COMPOSE_CMD) exec -T manuals-publisher bundle exec rake db:seed

specialist_publisher_setup:
	$(DOCKER_COMPOSE_CMD) exec -T specialist-publisher env RUN_SEEDS_IN_PRODUCTION=true bundle exec rake db:seed

publisher_setup:
	$(DOCKER_COMPOSE_CMD) exec -T publisher bundle exec rake db:setup

collections_publisher_setup:
	$(DOCKER_COMPOSE_CMD) exec -T collections-publisher bundle exec rake db:setup

rummager_setup:
	$(DOCKER_COMPOSE_CMD) exec -T rummager env RUMMAGER_INDEX=all bundle exec rake rummager:create_all_indices

wait_for_whitehall_admin:
	bundle exec rake docker:wait_for_whitehall_admin

contacts_admin_setup: wait_for_whitehall_admin
	$(DOCKER_COMPOSE_CMD) exec -T contacts-admin bundle exec rake db:setup

setup_queues:
	$(DOCKER_COMPOSE_CMD) exec -T publishing-api bundle exec rake setup_exchange
	$(DOCKER_COMPOSE_CMD) run --rm publishing-api-worker rails runner 'Sidekiq::Queue.new.clear'
	$(DOCKER_COMPOSE_CMD) exec -T rummager-worker bundle exec rake message_queue:create_queues

publish_routes: publish_rummager publish_specialist publish_frontend publish_contacts_admin publish_whitehall

publish_rummager:
	$(DOCKER_COMPOSE_CMD) exec -T rummager bundle exec rake publishing_api:publish_special_routes

publish_specialist:
	$(DOCKER_COMPOSE_CMD) exec -T specialist-publisher bundle exec rake publishing_api:publish_finders

publish_frontend:
	$(DOCKER_COMPOSE_CMD) exec -T frontend bundle exec rake publishing_api:publish_special_routes

publish_contacts_admin:
	$(DOCKER_COMPOSE_CMD) exec -T contacts-admin bundle exec rake finders:publish

publish_whitehall:
	$(DOCKER_COMPOSE_CMD) exec -T whitehall-admin bundle exec rake publishing_api:publish_special_routes

clean_apps:
	$(DOCKER_RUN) bash -c 'rm -rf /app/apps/*'

clean_docker:
	bundle exec rake docker:remove_built_app_images

clean_tmp:
	$(DOCKER_RUN) bash -c 'find /app/tmp -not -name .keep -type f -delete'
	$(DOCKER_RUN) bash -c 'find /app/tmp -depth -empty -type d -delete'

clean: clean_tmp clean_apps clean_docker

up:
	$(DOCKER_COMPOSE_CMD) up -d

pull:
	$(DOCKER_COMPOSE_CMD) pull --parallel --ignore-pull-failures

start:
	$(MAKE) up
	$(MAKE) setup

test:
	$(TEST_CMD)

test-specialist-publisher:
	$(TEST_CMD) -o '--tag specialist_publisher --tag ~flaky --tag ~new'

test-travel-advice-publisher:
	$(TEST_CMD) -o '--tag travel_advice_publisher --tag ~flaky --tag ~new'

test-collections-publisher:
	$(TEST_CMD) -o '--tag collections_publisher --tag ~flaky --tag ~new'

test-publisher:
	$(TEST_CMD) -o '--tag publisher --tag ~flaky --tag ~new'

test-manuals-publisher:
	$(TEST_CMD) -o '--tag manuals_publisher --tag ~flaky --tag ~new'

test-collections:
	$(TEST_CMD) -o '--tag collections --tag ~flaky --tag ~new'

test-finder-frontend:
	$(TEST_CMD) -o '--tag finder_frontend --tag ~flaky --tag ~new'

test-frontend:
	$(TEST_CMD) -o '--tag frontend --tag ~flaky --tag ~new'

test-government-frontend:
	$(TEST_CMD) -o '--tag government_frontend --tag ~flaky --tag ~new'

test-content-tagger:
	$(TEST_CMD) -o '--tag content_tagger --tag ~flaky --tag ~new'

test-contacts-admin:
	$(TEST_CMD) -o '--tag contacts_admin --tag ~flaky --tag ~new'

test-whitehall:
	$(TEST_CMD) -o '--tag whitehall --tag ~flaky --tag ~new'

stop: kill

.PHONY: all $(APPS) clone kill build setup start up test stop \
	test-specialist-publisher test-travel-advice-publisher \
	test-collections-publisher test-publisher test-manuals-publisher \
	test-frontend test-content-tagger test-contacts-admin test-finder-frontend \
	router_setup content_store_setup asset_manager_setup \
	publishing_api_setup travel_advice_setup whitehall_setup \
	content_tagger_setup manuals_publisher_setup \
	specialist_publisher_setup publisher_setup collections_publisher_setup \
	rummager_setup publish_rummager publish_specialist publish_frontend \
	publish_contacts_admin publish_whitehall setup_dbs setup_queues \
	wait_for_whitehall_admin contacts_admin_setup pull \
	clean_apps clean_docker clean_tmp clean

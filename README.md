# GOV.UK Publishing End-to-end Tests

A suite of end-to-end publishing tests that allow us to test functionality
across applications and services. The idea is that we test the sequence of
actions and movement of data throughout the system in a 'real world' context,
rather than stubbing services and making assumptions about responses. The tests
are browser tests (written in [RSpec](http://rspec.info/), using
[Capybara](https://github.com/teamcapybara/capybara)) that mimic the behaviour
of content editors.

Currently we have tests for [Specialist Publisher][specialist-publisher] and
[Travel Advice Publisher][travel-advice-publisher] (which require the
supporting applications and infrastructure, including Publishing API,
Content Store, Content Schemas, Router, Frontend, Static, MongoDB, Postgres,
Redis, RabbitMQ).

## Contents

- [How to run the tests](#how-to-run-tests)
- [Todo](#todo)
- [Gotchas](#gotchas)

## How to run the tests

### With Docker

Once you have [installed Docker][install-docker] you can build and run the test
suite with:

```
$ make
```

Running this command executes the following targets in order, which you can
choose to run separately to speed up development: `clone`, `build`, `start`,
`test` and `stop`.

For example, to run only the tests for the specialist publisher, you need only
do:

```bash
$ make -j4 clone
$ make build start test-specialist-publisher stop
```

See [docs/docker.md](docs/docker.md) for more information
configuring/troubleshooting docker.

### Without Docker

It is possible the run this suite without Docker however you will have to
set-up and configure each application in the stack and have them available
on `*.dev.gov.uk`. The tests can then be run with:

```
bundle exec rspec
```

### Contributing

More information on adding tests can be found in the [contributing guidelines](CONTRIBUTING.md) 

## Todo

- Can we run the tests in parallel?
- Run the applications in rails production - requires mocking sign-on, and
  various env var changes
- Disable the virus scanner in asset-manager - perhaps with env var
- Reduce setup steps - can Specialist Publisher work without finders for instance?

## Gotchas

### WEBrick server seems to stop responding

We had a nasty bug with Router API where the web server seemed to stop
responding to any requests. This issue was experienced once the application
was upgraded to Rails 5.1 and Mongoid 6.1. The symptom was that any requests
to the server seemed to hang and never respond. The way this was resolved was
to switch from using WEBrick on Router API and instead
[use unicorn server][use-unicorn-pr].

[install-docker]: https://www.docker.com/community-edition
[specialist-publisher]: https://github.com/alphagov/specialist-publisher
[travel-advice-publisher]: https://github.com/alphagov/travel-advice-publisher
[docker-healthcheck]: https://docs.docker.com/engine/reference/builder/#healthcheck
[use-unicorn-pr]: https://github.com/alphagov/router-api/pull/113

# BAS - Business Automation Suite

Many organizations and individuals rely on automation across various contexts in their daily operations. With BAS, we aim to provide an open-source platform that empowers users to create customized automation systems tailored to their unique requirements. BAS consists of a series of abstract components designed to facilitate the creation of diverse bots, regardless of context.

The underlying idea is to develop generic components that can serve a wide range of needs, this approach ensures that all members of the community can leverage the platform's evolving suite of components and bots to their advantage.

![Gem Version](https://img.shields.io/gem/v/bas?style=for-the-badge)
![Gem Total Downloads](https://img.shields.io/gem/dt/bas?style=for-the-badge)
![Build Badge](https://img.shields.io/github/actions/workflow/status/kommitters/bas/ci.yml?style=for-the-badge)
[![Coverage Status](https://img.shields.io/coveralls/github/kommitters/bas?style=for-the-badge)](https://coveralls.io/github/kommitters/bas?branch=main)
![GitHub License](https://img.shields.io/github/license/kommitters/bas?style=for-the-badge)
[![OpenSSF Scorecard](https://img.shields.io/ossf-scorecard/github.com/kommitters/bas?label=openssf%20scorecard&style=for-the-badge)](https://api.securityscorecards.dev/projects/github.com/kommitters/bas)
[![OpenSSF Best Practices](https://img.shields.io/cii/summary/8713?label=openssf%20best%20practices&style=for-the-badge)](https://bestpractices.coreinfrastructure.org/projects/8713)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add bas

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install bas

## Requirements

* Ruby 2.6.0 or higher

## Terms

### BOT
A bot is a tool responsible for executing a specific automation task. The bot's pipeline consists of reading from a shared storage (if required), processing a particular task, and then writing the result to a shared storage.

### Shared Storage
Shared storage is a central location where data can be read and written by multiple bots to facilitate coordination in an automation task. It serves as a common data exchange point, allowing each bot to access information generated by others as needed to complete its specific task. Examples of shared storage include a PostgreSQL database, an S3 bucket, or other types of storage systems that support concurrent access and data persistence.

### Use case
A use case refers to an automation problem larger than what a single bot can manage. It typically involves a set of bots, each solving a specific part of the overall problem independently. To enable these bots to interact, shared storage is used. This shared storage could be a PostgreSQL database, an S3 bucket, or another shared storage type, allowing bots to read and write data that other bots can access to complete their tasks.

## Building my own BOT

The gem provides essential interfaces, types, and methods to help you easily create your own bot. For instance, two base classes are provided: one for handling shared storage read-write operations and another for defining the bot’s specific task logic.

### 1. SharedStorage - Read and Write data.

The `SharedStorage` class abstracts the process of reading from and writing to shared storage. This class specification is available in `bas/shared_storage/base.rb`, from which custom implementations can be built.

Currently, the gem supports: `PostgreSQL`.

### 2. Bot - Solve a specific automation task
The bot executes the logic required to complete a specific task. For this, an instance of shared storage (for reading and for writing) must be provided to the bot.

The base interface for a bot is available in the `bas/bot/base.rb class`.

## Examples

### Preparing the configurations

The current implementation of the PostgreSQL shared storage expect a table with the following structure: 

```sql
CREATE TABLE api_data(
    id SERIAL NOT NULL,
    "data" jsonb,
    tag varchar(255),
    archived boolean,
    stage varchar(255),
    status varchar(255),
    error_message jsonb,
    version varchar(255),
    inserted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(id)
);
```

### Define the bot

In this example, we demonstrate how to configure a bot to fetch data from an API and save it in a postgres database.

For this, a bot could be defined as follow:
```ruby
require "httparty"

module Bas
  module Bot
    class FetchFromAPi
      URL = 'some-url.com'

      def process
        request = HTTParty.get(URL, { headers: })

        if request.code == 200
          { success: request.body }
        else
          { error: request.error_message }
        end
      end

      private

      def headers
        {
          "Authorization" => "Bearer #{process_options[:token]}",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
```

The `Bot::Base` interface expects the process method to return a hash with a single key, which can be `success` (when the response is valid) or `error` (when an error occurs). This consistency allows SharedStorage to handle the same data types regardless of the specific bot used.

Finally, to execute the bot we could define it like follows:

```ruby
connection = {
  host: "localhost",
  port: 5432,
  dbname: "bas",
  user: "postgres",
  password: "postgres"
}

read_options = {
  connection:,
  db_table: "api_data",
  tag: "AnotherBot"
}

write_options = {
  connection:,
  db_table: "api_data",
  tag: "FetchFromAPi"
}

options = {
  token: "api_token"
}

shared_storage = SharedStorage.new(read_options:, write_options:)

bot = Bas::Bot::FetchFromAPi.new(options, shared_storage)
bot.execute
```

The `tag` parameter in the read and write options specifies which record to look at (when reading) and what tag to assign to the record (when writing). This way, each bot can work independently with its own records in the shared storage.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Changelog

Features and bug fixes are listed in the [CHANGELOG][changelog] file.

## Code of conduct

We welcome everyone to contribute. Make sure you have read the [CODE_OF_CONDUCT][coc] before.

## Contributing

For information on how to contribute, please refer to our [CONTRIBUTING][contributing] guide.

## License

The gem is licensed under an MIT license. See [LICENSE][license] for details.

<br/>

<hr/>

[<img src="https://github.com/kommitters/chaincerts-smart-contracts/assets/1649973/d60d775f-166b-4968-89b6-8be847993f8c" width="80px" alt="kommit"/>](https://kommit.co)

<sub>

[Website][kommit-website] •
[Github][kommit-github] •
[X][kommit-x] •
[LinkedIn][kommit-linkedin]

</sub>

[license]: https://github.com/kommitters/bas/blob/main/LICENSE
[coc]: https://github.com/kommitters/bas/blob/main/CODE_OF_CONDUCT.md
[changelog]: https://github.com/kommitters/bas/blob/main/CHANGELOG.md
[contributing]: https://github.com/kommitters/bas/blob/main/CONTRIBUTING.md
[kommit-website]: https://kommit.co
[kommit-github]: https://github.com/kommitters
[kommit-x]: https://twitter.com/kommitco
[kommit-linkedin]: https://www.linkedin.com/company/kommit-co

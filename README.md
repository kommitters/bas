# BAS - Business Automation System

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

## BOT
A bot is a tool in charge of executing a specific automation task. The pipeline of a bot consists of reading from a data source, processing a specific task, and then writing a result in storage.

## Use case
A use case is an automation problem greater than the one managed by a single bot. A use case comprises a set of bots that are agnostic between them and each one solves a specific task (parts of the automation problem). To connect the bots, a shared storage should be used. This shared storage could be a PostgresDB database, an S3 bucket, or any kind of storage where the bots will read and write data so another bot can use it to execute their tasks.

For example, a system to notify birthdays in a company (automation problem) can be solved with three bots: one to fetch the data from an external data source, one to format the birthday message, and the last one to notify somewhere.

## Building my own BOT

The gem provides with basic interfaces, types, and methods to shape your own bot in an easy way. Since the process of reading and writing in a shared storage is separated from the main task, two base classes were defined to deal with this executions, leaving the logic of the specific task in the bot file.

### 1. Read - Obtaining the data from the Shared Storage

Specifically, a reader is an object in charged of bringing data from a shared storage. The gem already provides the base interface
for building your own reader for your specific shared storage, or rely on already built classes if they match your purpose.

The base interface for a reader can be found under the `bas/read/base.rb` class.

### 2. Write - Apply changes in a shared storage
The **Write** is in charge of creating or updating information in a shared storage. This is the last step for every BOT. These changes can be a transaction in a database, adding files in a cloud storage, or simply creating logs.

The base interface for a writer can be found under the `bas/write/base.rb` class.

### 3. Bot - Solve a specific automation task
The bot execute the logic to solve an specific task. For this, it can use the data from the read step, and then returns a processed response to be wrote by the write component. Every bot reads from a shared storage and writes in a shared storage.

The base interface for a bot can be found under the `bas/bot/base.rb` class.

## Examples

In this example, we demonstrate how to instantiate a birthday notification bot and execute it in a basic Ruby project. We'll also cover its deployment in a serverless configuration, specifically using a simple Lambda deployment.

### Preparing the configurations

We'll need some configurations for this specific use case:
* A **Notion database ID**, from a database with the following structure:

| Complete Name (text) |    BD_this_year (formula)   |         BD (date)        |
| -------------------- | --------------------------- | ------------------------ |
|       John Doe       |       January 24, 2024      |      January 24, 2000    |
|       Jane Doe       |       June 20, 2024         |      June 20, 2000       |

With the following formula for the **BD_this_year** column: `dateAdd(prop("BD"), year(now()) - year(prop("BD")), "years")`

* A Notion secret, which can be obtained, by creating an integration here: `https://developers.notion.com/`, browsing on the **View my integrations** option, and selecting the **New Integration** or **Create new integration** buttons.

### Instantiating the FetchBirthdayFromNotion Bot

The specific bot can be found in the `bas/bot/fetch_birthdays_from_notion.rb` file.

**Normal ruby code**
```
options = {
  process_options: {
    database_id: "notion database id",
    secret: "notion secret"
  },
  write_options: {
    connection: {
      host: "host",
      port: 5432,
      dbname: "bas",
      user: "postgres",
      password: "postgres"
    },
    db_table: "use_cases",
    bot_name: "FetchBirthdaysFromNotion"
  }
}

bot = Bot::FetchBirthdaysFromNotion.new(options)
bot.execute

```

## Real case usage
For implementation details, please refer to the examples folder in the repository. You can find an example of how to configure a Lambda function with a bot there.

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

### Serverless
We'll explain how to configure and deploy a bot with serverless.

#### Configuring environment variables
Create the environment variables configuration file (`env.yml`)

And put the following env variables
```
dev:
  BIRTHDAY_NOTION_DATABASE_ID: "BIRTHDAY_NOTION_DATABASE_ID"
  BIRTHDAY_NOTION_SECRET: "BIRTHDAY_NOTION_SECRET"
prod:
  BIRTHDAY_NOTION_DATABASE_ID: "BIRTHDAY_NOTION_DATABASE_ID"
  BIRTHDAY_NOTION_SECRET: "BIRTHDAY_NOTION_SECRET"

```

The variables should be defined either in the custom settings section within the `serverless.yml` file to ensure accessibility by all lambdas, or in the environment configuration option for each lambda respectively. For example:

```bash
# Accessible by all the lambdas
custom:
  settings:
      api:
        NOTION_DATABASE_ID: ${file(./env.yml):${env:STAGE}.NOTION_DATABASE_ID}
        NOTION_SECRET: ${file(./env.yml):${env:STAGE}.NOTION_SECRET}}

# Accessible by the lambda
functions:
  lambdaName:
    environment:
      NOTION_DATABASE_ID: ${file(./env.yml):${env:STAGE}.NOTION_DATABASE_ID}
      NOTION_SECRET: ${file(./env.yml):${env:STAGE}.NOTION_SECRET}}
```

#### Schedule
the schedule is configured using an environment variable containing the cron configuration. For example:
```bash
# env.yml file
SCHEDULER: cron(0 13 ? * MON-FRI *)

# serverless.yml
functions:
  lambdaName:
    events:
      - schedule:
        rate: ${file(./env.yml):${env:STAGE}.SCHEDULER}
```

To learn how to modify the cron configuration follow this guide: [Schedule expressions using rate or cron](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html)

#### Building your lambda
On your serverless configuration, create your lambda function, on your serverless `/src` folder.

```ruby
# frozen_string_literal: true

require 'bas/bot/fetch_birthdays_from_notion'

# Initialize the environment variables
NOTION_DATABASE_ID = ENV.fetch('NOTION_DATABASE_ID')
NOTION_SECRET = ENV.fetch('NOTION_SECRET')

module Notifier
  # Service description
  class UseCaseName
    def self.notify(*)
      options = { process_options: , write_options: }

      begin
        use_case = Bot::FetchBirthdaysFromNotion.new(options)

        use_case.execute
      rescue StandardError => e
        { body: { message: e.message } }
      end
    end

    def self.process_options
      {
        database_id: NOTION_DATABASE_ID,
        secret: NOTION_SECRET
      }
    end

    def self.write_options
      {
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
    end
  end
end
```

#### Configure the lambda
In the `serverless.yml` file, add a new instance in the `functions` block with this structure:

```bash
functions:
  fetchBirthdayFromNotion:
    handler: src/lambdas/birthday_fetch.Bot::Birthday.fetch
    environment:
      BIRTHDAY_NOTION_DATABASE_ID: ${file(./env.yml):${env:STAGE}.BIRTHDAY_NOTION_DATABASE_ID}
      BIRTHDAY_NOTION_SECRET: ${file(./env.yml):${env:STAGE}.BIRTHDAY_NOTION_SECRET}
    events:
      - schedule:
          name: birthday-fetch
          description: "Fetch every 24 hours at 8:30 a.m (UTC-5) from monday to friday"
          rate: cron(${file(./env.yml):${env:STAGE}.BIRTHDAY_FETCH_SCHEDULER})
          enabled: true
```

#### Deploying

Configure the AWS keys:

```bash
serverless config credentials --provider aws --key YOUR_KEY --secret YOUR_SECRET
```

Deploy the project:
```bash
STAGE=prod sls deploy --verbose
```

# frozen_string_literal: true

# fetcher
require_relative "../fetcher/notion/use_case/birthday_today"
require_relative "../fetcher/notion/use_case/birthday_next_week"
require_relative "../fetcher/notion/use_case/pto_today"
require_relative "../fetcher/notion/use_case/pto_next_week"
require_relative "../fetcher/notion/use_case/work_items_limit"
require_relative "../fetcher/postgres/use_case/pto_today"
require_relative "../fetcher/imap/use_case/support_emails"

# mapper
require_relative "../mapper/notion/birthday_today"
require_relative "../mapper/notion/pto_today"
require_relative "../mapper/notion/work_items_limit"
require_relative "../mapper/postgres/pto_today"
require_relative "../mapper/imap/support_emails"

# formatter
require_relative "../formatter/birthday"
require_relative "../formatter/pto"
require_relative "../formatter/work_items_limit"
require_relative "../formatter/support_emails"

# dispatcher
require_relative "../dispatcher/discord/implementation"
require_relative "../dispatcher/slack/implementation"

require_relative "use_case"
require_relative "./types/config"

##
# This module provides factory methods for use cases within the system. Each method
# represents a use case implementation introduced in the system.
#
module UseCases
  # Provides an instance of the Birthdays notifications from Notion to Discord use case implementation.
  #
  # <b>Example</b>
  #
  #   options = {
  #     fetch_options: {
  #       database_id: NOTION_DATABASE_ID,
  #       secret: NOTION_API_INTEGRATION_SECRET,
  #     },
  #     dispatch_options: {
  #       webhook: "https://discord.com/api/webhooks/1199213527672565760/KmpoIzBet9xYG16oFh8W1RWHbpIqT7UtTBRrhfLcvWZdNiVZCTM-gpil2Qoy4eYEgpdf",
  #       name: "Birthday Bot"
  #     }
  #   }
  #
  #   use_case = UseCases.notify_birthday_from_notion_to_discord(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * Notion database ID, from a database with the following structure:
  #
  #         _________________________________________________________________________________
  #         | Complete Name (text) |    BD_this_year (formula)   |         BD (date)        |
  #         | -------------------- | --------------------------- | ------------------------ |
  #         |       John Doe       |       January 24, 2024      |      January 24, 2000    |
  #         |       Jane Doe       |       June 20, 2024         |      June 20, 2000       |
  #         ---------------------------------------------------------------------------------
  #         With the following formula for the BD_this_year column:
  #            dateAdd(prop("BD"), year(now()) - year(prop("BD")), "years")
  #
  #   * A Notion secret, which can be obtained, by creating an integration here: `https://developers.notion.com/`,
  #     browsing on the <View my integations> option, and selecting the <New Integration> or <Create new>
  #     integration** buttons.
  #   * A webhook key, which can be generated directly on discrod on the desired channel, following this instructions:
  #     https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
  #
  def self.notify_birthday_from_notion_to_discord(options)
    fetcher = Fetcher::Notion::BirthdayToday.new(options[:fetch_options])
    mapper = Mapper::Notion::BirthdayToday.new
    formatter = Formatter::Birthday.new(options[:format_options])
    dispatcher = Dispatcher::Discord::Implementation.new(options[:dispatch_options])
    use_case_config = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_config)
  end

  # Provides an instance of the next week Birthdays notifications from Notion to Discord use case implementation.
  #
  # <b>Example</b>
  #
  #   options = {
  #     fetch_options: {
  #       database_id: NOTION_DATABASE_ID,
  #       secret: NOTION_API_INTEGRATION_SECRET,
  #     },
  #     dispatch_options: {
  #       webhook: "https://discord.com/api/webhooks/1199213527672565760/KmpoIzBet9xYG16oFh8W1RWHbpIqT7UtTBRrhfLcvWZdNiVZCTM-gpil2Qoy4eYEgpdf",
  #       name: "Birthday Bot"
  #     },
  #     format_options: {
  #       template: "individual_name, Wishing you a very happy birthday! Enjoy your special day! :birthday: :gift:",
  #       timezone: "-05:00"
  #     }
  #   }
  #
  #   use_case = UseCases.notify_next_week_birthday_from_notion_to_discord(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * Notion database ID, from a database with the following structure:
  #
  #         _________________________________________________________________________________
  #         | Complete Name (text) |    BD_this_year (formula)   |         BD (date)        |
  #         | -------------------- | --------------------------- | ------------------------ |
  #         |       John Doe       |       January 24, 2024      |      January 24, 2000    |
  #         |       Jane Doe       |       June 20, 2024         |      June 20, 2000       |
  #         ---------------------------------------------------------------------------------
  #         With the following formula for the BD_this_year column:
  #            dateAdd(prop("BD"), year(now()) - year(prop("BD")), "years")
  #
  #   * A Notion secret, which can be obtained, by creating an integration here: `https://developers.notion.com/`,
  #     browsing on the <View my integations> option, and selecting the <New Integration> or <Create new>
  #     integration** buttons.
  #   * A webhook key, which can be generated directly on discrod on the desired channel, following this instructions:
  #     https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
  #
  def self.notify_next_week_birthday_from_notion_to_discord(options)
    fetcher = Fetcher::Notion::BirthdayNextWeek.new(options[:fetch_options])
    mapper = Mapper::Notion::BirthdayToday.new
    formatter = Formatter::Birthday.new(options[:format_options])
    dispatcher = Dispatcher::Discord::Implementation.new(options[:dispatch_options])
    use_case_cofig = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_cofig)
  end

  # Provides an instance of the PTO notifications from Notion to Discord use case implementation.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     fetch_options: {
  #       database_id: NOTION_DATABASE_ID,
  #       secret: NOTION_API_INTEGRATION_SECRET,
  #     },
  #     dispatch_options: {
  #       webhook: "https://discord.com/api/webhooks/1199213527672565760/KmpoIzBet9xYG16oFh8W1RWHbpIqT7UtTBRrhfLcvWZdNiVZCTM-gpil2Qoy4eYEgpdf",
  #       name: "Pto Bot"
  #     }
  #   }
  #
  #   use_case = UseCases.notify_pto_from_notion_to_discord(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * Notion database ID, from a database with the following structure:
  #
  #         ________________________________________________________________________________________________________
  #         |    Person (person)   |        Desde? (date)                    |       Hasta? (date)                  |
  #         | -------------------- | --------------------------------------- | ------------------------------------ |
  #         |       John Doe       |       January 24, 2024                  |      January 27, 2024                |
  #         |       Jane Doe       |       November 11, 2024 2:00 PM         |      November 11, 2024 6:00 PM       |
  #         ---------------------------------------------------------------------------------------------------------
  #
  #   * A Notion secret, which can be obtained, by creating an integration here: `https://developers.notion.com/`,
  #     browsing on the <View my integations> option, and selecting the <New Integration> or <Create new>
  #     integration** buttons.
  #   * A webhook key, which can be generated directly on discrod on the desired channel, following this instructions:
  #     https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
  #
  def self.notify_pto_from_notion_to_discord(options)
    fetcher = Fetcher::Notion::PtoToday.new(options[:fetch_options])
    mapper = Mapper::Notion::PtoToday.new
    formatter = Formatter::Pto.new(options[:format_options])
    dispatcher = Dispatcher::Discord::Implementation.new(options[:dispatch_options])
    use_case_config = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_config)
  end

  # Provides an instance of the next week PTO notifications from Notion to Discord use case implementation.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     fetch_options: {
  #       database_id: NOTION_DATABASE_ID,
  #       secret: NOTION_API_INTEGRATION_SECRET,
  #     },
  #     dispatch_options: {
  #       webhook: "https://discord.com/api/webhooks/1199213527672565760/KmpoIzBet9xYG16oFh8W1RWHbpIqT7UtTBRrhfLcvWZdNiVZCTM-gpil2Qoy4eYEgpdf",
  #       name: "Pto Bot"
  #     },
  #     format_options: {
  #       template: ":beach: individual_name its going to be on PTO next week,",
  #       timezone: "-05:00"
  #     }
  #   }
  #
  #   use_case = UseCases.notify_next_week_pto_from_notion_to_discord(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * Notion database ID, from a database with the following structure:
  #
  #         ________________________________________________________________________________________________________
  #         |    Person (person)   |        Desde? (date)                    |       Hasta? (date)                  |
  #         | -------------------- | --------------------------------------- | ------------------------------------ |
  #         |       John Doe       |       January 24, 2024                  |      January 27, 2024                |
  #         |       Jane Doe       |       November 11, 2024 2:00 PM         |      November 11, 2024 6:00 PM       |
  #         ---------------------------------------------------------------------------------------------------------
  #
  #   * A Notion secret, which can be obtained, by creating an integration here: `https://developers.notion.com/`,
  #     browsing on the <View my integations> option, and selecting the <New Integration> or <Create new>
  #     integration** buttons.
  #   * A webhook key, which can be generated directly on discrod on the desired channel, following this instructions:
  #     https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
  #
  def self.notify_next_week_pto_from_notion_to_discord(options)
    fetcher = Fetcher::Notion::PtoNextWeek.new(options[:fetch_options])
    mapper = Mapper::Notion::PtoToday.new
    formatter = Formatter::Pto.new(options[:format_options])
    dispatcher = Dispatcher::Discord::Implementation.new(options[:dispatch_options])
    use_case_config = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_config)
  end

  # Provides an instance of the PTO notifications from Postgres to Slack use case implementation.
  #
  # <br>
  # <b>Example</b>
  #
  # options = {
  #   fetch_options: {
  #     connection: {
  #       host: "localhost",
  #       port: 5432,
  #       dbname: "db_pto",
  #       user: "postgres",
  #       password: "postgres"
  #     }
  #   },
  #   dispatch_options:{
  #     webhook: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX",
  #     name: "Pto Bot"
  #   },
  #   format_options: {
  #     template: "Custom template",
  #     timezone: "-05:00"
  #   }
  # }
  #
  #   use_case = UseCases.notify_pto_from_postgres_to_slack(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * A connection to a Postgres database and a table with the following structure:
  #
  #          Column      |          Type          | Collation | Nullable |           Default
  #     -----------------+------------------------+-----------+----------+------------------------------
  #      id              | integer                |           | not null | generated always as identity
  #      create_time     | date                   |           |          |
  #      individual_name | character varying(255) |           |          |
  #      start_date      | date                   |           |          |
  #      end_date        | date                   |           |          |
  #
  #   * A webhook key, which can be generated directly on slack on the desired channel, following this instructions:
  #     https://api.slack.com/messaging/webhooks#create_a_webhook
  #
  def self.notify_pto_from_postgres_to_slack(options)
    fetcher = Fetcher::Postgres::PtoToday.new(options[:fetch_options])
    mapper = Mapper::Postgres::PtoToday.new
    formatter = Formatter::Pto.new(options[:format_options])
    dispatcher = Dispatcher::Slack::Implementation.new(options[:dispatch_options])
    use_case_config = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_config)
  end

  # Provides an instance of the Work Items wip limit notifications from Notion to Discord use case implementation.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     fetch_options: {
  #       database_id: NOTION_DATABASE_ID,
  #       secret: NOTION_API_INTEGRATION_SECRET
  #     },
  #     dispatch_options: {
  #       webhook: "https://discord.com/api/webhooks/1199213527672565760/KmpoIzBet9xYG16oFh8W1RWHbpIqT7UtTBRrhfLcvWZdNiVZCTM-gpil2Qoy4eYEgpdf",
  #       name: "wipLimit"
  #     }
  #   }
  #
  #   use_case = UseCases.notify_wip_limit_from_notion_to_discord(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * Notion database ID, from a database with the following structure:
  #
  #         _________________________________________________________________________________
  #         |           OK         |            Status           |     Responsible Domain   |
  #         | -------------------- | --------------------------- | ------------------------ |
  #         |           ✅         |       In Progress           |      "kommit.admin"      |
  #         |           🚩         |       Fail                  |      "kommit.ops"        |
  #         ---------------------------------------------------------------------------------
  #
  #   * A Notion secret, which can be obtained, by creating an integration here: `https://developers.notion.com/`,
  #     browsing on the <View my integations> option, and selecting the <New Integration> or <Create new>
  #     integration** buttons.
  #   * A webhook key, which can be generated directly on discrod on the desired channel, following this instructions:
  #     https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
  #
  def self.notify_wip_limit_from_notion_to_discord(options)
    fetcher = Fetcher::Notion::WorkItemsLimit.new(options[:fetch_options])
    mapper = Mapper::Notion::WorkItemsLimit.new
    formatter = Formatter::WorkItemsLimit.new(options[:format_options])
    dispatcher = Dispatcher::Discord::Implementation.new(options[:dispatch_options])
    use_case_config = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_config)
  end

  # Provides an instance of the support emails from an google IMAP server to Discord use case implementation.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     fetch_options: {
  #       user: 'info@email.co',
  #       refresh_token: REFRESH_TOKEN,
  #       client_id: CLIENT_ID,
  #       client_secret: CLIENT_SECRET,
  #       inbox: 'INBOX',
  #       search_email: 'support@email.co'
  #     },
  #     dispatch_options: {
  #       webhook: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX",
  #       name: "emailSupport"
  #     }
  #   }
  #
  #   use_case = UseCases.notify_support_email_from_imap_to_discord(options)
  #   use_case.perform
  #
  #   #################################################################################
  #
  #   Requirements:
  #   * A google gmail account with IMAP support activated.
  #   * A set of authorization parameters like a client_id, client_secret, and a resfresh_token. To
  #     generate them, follow this instructions: https://developers.google.com/identity/protocols/oauth2
  #   * A webhook key, which can be generated directly on discrod on the desired channel, following this instructions:
  #     https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
  #
  def self.notify_support_email_from_imap_to_discord(options)
    fetcher = Fetcher::Imap::SupportEmails.new(options[:fetch_options])
    mapper = Mapper::Imap::SupportEmails.new
    formatter = Formatter::SupportEmails.new(options[:format_options])
    dispatcher = Dispatcher::Discord::Implementation.new(options[:dispatch_options])
    use_case_config = UseCases::Types::Config.new(fetcher, mapper, formatter, dispatcher)

    UseCases::UseCase.new(use_case_config)
  end
end

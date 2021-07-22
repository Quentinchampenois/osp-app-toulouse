# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/proposals/test/factories"
require "decidim/debates/test/factories"
require "decidim/meetings/test/factories"
require "decidim/accountability/test/factories"
require "decidim/system/test/factories"
require "decidim/participatory_processes/test/factories"

FactoryBot.modify do
  factory :debate, class: "Decidim::Debates::Debate" do
    title { generate_localized_debate_title }
    description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_debate_title } }
    information_updates { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_debate_title } }
    instructions { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_debate_title } }
    start_time { 1.day.from_now }
    end_time { start_time.advance(hours: 2) }
    component { build(:component, manifest_name: "debates") }
    author { component.try(:organization) }

    trait :open_ama do
      start_time { 1.day.ago }
      end_time { 1.day.from_now }
    end

    trait :with_author do
      author do
        build(:user, organization: component.organization) if component
      end
    end

    trait :with_user_group_author do
      author do
        create(:user, organization: component.organization) if component
      end
      user_group do
        create(:user_group, :verified, organization: component.organization, users: [author]) if component
      end
    end
  end

  factory :participatory_process, class: "Decidim::ParticipatoryProcess" do
    title { generate_localized_title }
    slug { generate(:participatory_process_slug) }
    subtitle { generate_localized_title }
    short_description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
    description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
    organization
    hero_image { Decidim::Dev.test_file("city.jpeg", "image/jpeg") } # Keep after organization
    banner_image { Decidim::Dev.test_file("city2.jpeg", "image/jpeg") } # Keep after organization
    published_at { Time.current }
    meta_scope { Decidim::Faker::Localized.word }
    developer_group { generate_localized_title }
    local_area { generate_localized_title }
    target { generate_localized_title }
    participatory_scope { generate_localized_title }
    participatory_structure { generate_localized_title }
    announcement { generate_localized_title }
    show_metrics { true }
    show_statistics { true }
    private_space { false }
    start_date { Date.current }
    end_date { 2.months.from_now }
    area { nil }
    display_linked_assemblies { false }
    emitter { :unspecified }

    trait :from_city do
      emitter { :city }
    end

    trait :from_metropolis do
      emitter { :metropolis }
    end

    trait :from_both_city_and_metropolis do
      emitter { :both }
    end

    trait :with_linked_assemblies do
      display_linked_assemblies { true }
    end

    trait :promoted do
      promoted { true }
    end

    trait :unpublished do
      published_at { nil }
    end

    trait :published do
      published_at { Time.current }
    end

    trait :private do
      private_space { true }
    end

    trait :with_steps do
      transient { current_step_ends { 1.month.from_now } }

      after(:create) do |participatory_process, evaluator|
        create(:participatory_process_step,
               active: true,
               end_date: evaluator.current_step_ends,
               participatory_process: participatory_process)
        participatory_process.reload
        participatory_process.steps.reload
      end
    end

    trait :active do
      start_date { 2.weeks.ago }
      end_date { 1.week.from_now }
    end

    trait :past do
      start_date { 2.weeks.ago }
      end_date { 1.week.ago }
    end

    trait :upcoming do
      start_date { 1.week.from_now }
      end_date { 2.weeks.from_now }
    end

    trait :with_scope do
      scopes_enabled { true }
      scope { create :scope, organization: organization }
    end
  end

  factory :user, class: "Decidim::User" do
    email { generate(:email) }
    password { "password1234" }
    password_confirmation { password }
    name { generate(:name) }
    nickname { generate(:nickname) }
    organization
    locale { organization.default_locale }
    tos_agreement { "1" }
    avatar { Decidim::Dev.test_file("avatar.jpg", "image/jpeg") }
    personal_url { Faker::Internet.url }
    about { "<script>alert(\"ABOUT\");</script>" + Faker::Lorem.paragraph(2) }
    confirmation_sent_at { Time.current }
    accepted_tos_version { organization.tos_version }
    email_on_notification { true }
    registration_metadata do
      {
        city_residential_area: build(:scope).id.to_s,
        city_work_area: build(:scope).id.to_s,
        gender: "other",
        birth_date: { month: Faker::Date.birthday.month, year: Faker::Date.birthday.year },
        statutory_representative_email: generate(:email)
      }
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :deleted do
      email { "" }
      deleted_at { Time.current }
    end

    trait :admin_terms_accepted do
      admin_terms_accepted_at { Time.current }
    end

    trait :admin do
      admin { true }
      admin_terms_accepted
    end

    trait :user_manager do
      roles { ["user_manager"] }
      admin_terms_accepted
    end

    trait :managed do
      email { "" }
      password { "" }
      password_confirmation { "" }
      encrypted_password { "" }
      managed { true }
    end

    trait :officialized do
      officialized_at { Time.current }
      officialized_as { generate_localized_title }
    end
  end
end

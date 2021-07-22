# frozen_string_literal: true

module Decidim
  # A form object used to handle user registrations
  class RegistrationForm < Form
    mimic :user

    include JsonbAttributes

    GENDER_TYPES = %w(male female other).freeze
    LIVING_AREA = %w(city metropolis other).freeze

    MONTHNAMES = (1..12).map { |m| Date::MONTHNAMES[m] }.freeze

    attribute :name, String
    attribute :nickname, String
    attribute :email, String
    attribute :password, String
    attribute :password_confirmation, String
    attribute :living_area, String
    attribute :city_residential_area, String
    attribute :city_work_area, String
    attribute :metropolis_residential_area, String
    attribute :metropolis_work_area, String
    attribute :gender, String
    attribute :tos_agreement, Boolean
    attribute :additional_tos, Boolean
    attribute :current_locale, String
    jsonb_attribute :birth_date, [
      [:month, String],
      [:year, String]
    ]
    attribute :underage, Boolean
    attribute :statutory_representative_email, String

    validates :name, presence: true
    validates :nickname, presence: true, format: /\A[\w\-]+\z/, length: { maximum: Decidim::User.nickname_max_length }
    validates :email, presence: true, 'valid_email_2/email': { disposable: true }
    validates :password, confirmation: true
    validates :password, password: { name: :name, email: :email, username: :nickname }
    validates :password, :password_confirmation, presence: true
    validates :tos_agreement, allow_nil: false, acceptance: true
    validates :month, :year, presence: true
    validates :additional_tos, allow_nil: false, acceptance: true

    validate :email_unique_in_organization
    validate :nickname_unique_in_organization
    validate :no_pending_invitations_exist

    validates :gender,
              inclusion: { in: GENDER_TYPES },
              if: ->(form) { form.gender.present? }

    validates :living_area,
              inclusion: { in: LIVING_AREA },
              presence: true

    validates :city_residential_area,
              inclusion: { in: :city_scopes_ids },
              presence: true,
              if: :city_living_area?

    validates :city_work_area,
              inclusion: { in: :city_scopes_ids },
              if: ->(form) { form.city_work_area.present? && city_living_area? }

    validates :metropolis_residential_area,
              inclusion: { in: :metropolis_scopes_ids },
              presence: true,
              if: :metropolis_living_area?

    validates :metropolis_work_area,
              inclusion: { in: :metropolis_scopes_ids },
              if: ->(form) { form.metropolis_work_area.present? && metropolis_living_area? }

    validates :month,
              inclusion: { in: MONTHNAMES },
              if: ->(form) { form.month.present? }

    validates :year,
              inclusion: { in: :year_for_select },
              if: ->(form) { form.year.present? }

    validates :statutory_representative_email,
              presence: true,
              'valid_email_2/email': { disposable: true },
              if: ->(form) { form.underage.present? }

    def map_model(model)
      self.month = model.birth_date["month"]
      self.year = model.birth_date["year"]
    end

    def city_residential_area_for_select
      city_scopes
    end

    def city_work_area_for_select
      city_scopes
    end

    def metropolis_residential_area_for_select
      metropolis_scopes
    end

    def metropolis_work_area_for_select
      metropolis_scopes
    end

    def gender_types_for_select
      GENDER_TYPES.map do |type|
        [
          I18n.t(type.downcase, scope: "decidim.devise.registrations.new.gender"),
          type
        ]
      end
    end

    def month_names_for_select
      MONTHNAMES.map do |month_name|
        [
          I18n.t(month_name.downcase, scope: "decidim.devise.registrations.new.month_name"),
          month_name
        ]
      end
    end

    def year_for_select
      (Time.current.year - 120..Time.current.year).map(&:to_s).reverse
    end

    private

    def city_living_area?
      living_area == "city"
    end

    def metropolis_living_area?
      living_area == "metropolis"
    end

    def city_scopes
      @city_scopes ||= current_organization.scopes.where(parent: top_level_city_scopes)
    end

    def metropolis_scopes
      @metropolis_scopes ||= current_organization.scopes.where(parent: top_level_metropolis_scopes)
    end

    def city_scopes_ids
      city_scopes.collect { |scope| scope.id.to_s }
    end

    def metropolis_scopes_ids
      metropolis_scopes.collect { |scope| scope.id.to_s }
    end

    def email_unique_in_organization
      errors.add :email, :taken if User.no_active_invitation.find_by(email: email, organization: current_organization).present?
    end

    def nickname_unique_in_organization
      errors.add :nickname, :taken if User.no_active_invitation.find_by(nickname: nickname, organization: current_organization).present?
    end

    def no_pending_invitations_exist
      errors.add :base, I18n.t("devise.failure.invited") if User.has_pending_invitations?(current_organization.id, email)
    end

    def top_level_metropolis_scopes
      @top_level_metropolis_scopes ||= top_level_scopes.where("name @> ?", { en: "Toulouse metropolis" }.to_json)
                                                       .or(top_level_scopes.where("name @> ?", { fr: "Métropole de Toulouse" }.to_json))
    end

    def top_level_city_scopes
      @top_level_city_scopes ||= top_level_scopes.where("name @> ?", { en: "Toulouse city" }.to_json)
                                                 .or(top_level_scopes.where("name @> ?", { fr: "Ville de Toulouse" }.to_json))
    end

    def top_level_scopes
      @top_level_scopes ||= current_organization.scopes.top_level
    end
  end
end

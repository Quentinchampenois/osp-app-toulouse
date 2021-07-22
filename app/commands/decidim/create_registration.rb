# frozen_string_literal: true

module Decidim
  # A command with all the business logic to create a user through the sign up form.
  class CreateRegistration < Rectify::Command
    # Public: Initializes the command.
    #
    # form - A form object with the params.
    def initialize(form)
      @form = form
    end

    # Executes the command. Broadcasts these events:
    #
    # - :ok when everything is valid.
    # - :invalid if the form wasn't valid and we couldn't proceed.
    #
    # Returns nothing.
    def call
      if form.invalid?
        user = User.has_pending_invitations?(form.current_organization.id, form.email)
        user.invite!(user.invited_by) if user
        return broadcast(:invalid)
      end

      create_user

      send_email_to_statutory_representative

      broadcast(:ok, @user)
    rescue ActiveRecord::RecordInvalid
      broadcast(:invalid)
    end

    private

    attr_reader :form

    def create_user
      @user = User.create!(
        email: form.email,
        name: form.name,
        nickname: form.nickname,
        password: form.password,
        password_confirmation: form.password_confirmation,
        organization: form.current_organization,
        tos_agreement: form.tos_agreement,
        email_on_notification: true,
        accepted_tos_version: form.current_organization.tos_version,
        locale: form.current_locale,
        registration_metadata: registration_metadata
      )
    end

    def registration_metadata
      {
        additional_tos: form.additional_tos,
        living_area: form.living_area,
        city_residential_area: city_living_area? ? form.city_residential_area : nil,
        city_work_area: city_living_area? ? form.city_work_area : nil,
        metropolis_residential_area: metropolis_living_area? ? form.metropolis_residential_area : nil,
        metropolis_work_area: metropolis_living_area? ? form.metropolis_work_area : nil,
        gender: form.gender,
        birth_date: form.birth_date,
        statutory_representative_email: form.statutory_representative_email
      }
    end

    def statutory_representative_email
      form.statutory_representative_email if form.underage.present?
    end

    def send_email_to_statutory_representative
      return if registration_metadata[:statutory_representative_email].blank?

      Decidim::StatutoryRepresentativeMailer.inform(@user).deliver_later
    end

    def city_living_area?
      form.living_area == "city"
    end

    def metropolis_living_area?
      form.living_area == "metropolis"
    end
  end
end

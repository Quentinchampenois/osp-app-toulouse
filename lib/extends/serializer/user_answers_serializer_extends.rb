# frozen_string_literal: true

module UserAnswersSerializerExtends
  # Public: Initializes the serializer with a collection of Answers.
  def initialize(answers, private_scope = false)
    @answers = answers
    @private_scope = private_scope
  end

  # Public: Exports a hash with the serialized data for the user answers.
  def serialize
    @answers.each_with_index.inject({}) do |serialized, (answer, idx)|
      admin_extra_fields do
        user = answer_user answer

        serialized.update(
          answer_translated_attribute_name(:user_name) => user.try(:name) || "",
          answer_translated_attribute_name(:user_nickname) => user.try(:nickname) || "",
          answer_translated_attribute_name(:user_email) => user.try(:email) || "",
          answer_translated_attribute_name(:user_birth_date) => key_from_registration_metadata(user, :birth_date).to_s,
          answer_translated_attribute_name(:user_gender) => key_from_registration_metadata(user, :gender),
          answer_translated_attribute_name(:user_living_area) => key_from_registration_metadata(user, :living_area),
          answer_translated_attribute_name(:user_city_residential_area) => city_residential_area(user),
          answer_translated_attribute_name(:user_city_work_area) => city_work_area(user),
          answer_translated_attribute_name(:user_metropolis_residential_area) => metropolis_residential_area(user),
          answer_translated_attribute_name(:user_metropolis_work_area) => metropolis_work_area(user),
          answer_translated_attribute_name(:user_statutory_representative_email) => key_from_registration_metadata(user, :statutory_representative_email)
        )
      end

      serialized.update(
        answer_translated_attribute_name(:id) => answer.id,
        answer_translated_attribute_name(:created_at) => answer.created_at.to_s(:db),
        answer_translated_attribute_name(:ip_hash) => answer.ip_hash,
        answer_translated_attribute_name(:user_status) => answer_translated_attribute_name(answer.decidim_user_id.present? ? "registered" : "unregistered"),
        "#{idx + 1}. #{translated_attribute(answer.question.body)}" => normalize_body(answer)
      )
    end
  end

  private

  def city_residential_area(user)
    return "" unless key_from_registration_metadata(user, :living_area) == "city"

    key_from_registration_metadata(user, :city_residential_area)
  end

  def city_work_area(user)
    return "" unless key_from_registration_metadata(user, :living_area) == "city"

    key_from_registration_metadata(user, :city_work_area)
  end

  def metropolis_residential_area(user)
    return "" unless key_from_registration_metadata(user, :living_area) == "metropolis"

    key_from_registration_metadata(user, :metropolis_residential_area)
  end

  def metropolis_work_area(user)
    return "" unless key_from_registration_metadata(user, :living_area) == "metropolis"

    key_from_registration_metadata(user, :metropolis_work_area)
  end

  def answer_user(answer)
    return nil if answer.decidim_user_id.blank?

    Decidim::User.find answer.decidim_user_id
  end

  def admin_extra_fields
    return "" unless @private_scope && block_given?

    yield
  end
end

Decidim::Forms::UserAnswersSerializer.class_eval do
  prepend(UserAnswersSerializerExtends)
end

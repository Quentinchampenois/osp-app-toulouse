# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Meetings
    describe RegistrationSerializer do
      describe "#serialize" do
        let!(:subject) { described_class.new(registration) }
        let!(:registration) { create(:registration) }
        let(:user) { registration.user }
        let(:city_work_area) { create(:scope, organization: user.organization) }
        let(:city_residential_area) { create(:scope, organization: user.organization) }
        let!(:user_group) { create(:user_group, :verified, organization: user.organization, users: [user]) }
        let(:registration_metadata) do
          {
            birth_date: "1981",
            gender: "Female",
            city_work_area: city_work_area.id,
            city_residential_area: city_residential_area.id,
            statutory_representative_email: "statutory_representative_email@example.org"
          }
        end

        context "when there is no questionnaire" do
          it "includes the id" do
            expect(subject.serialize).to include("ID" => registration.id)
          end

          it "includes the registration code" do
            expect(subject.serialize).to include("Code" => registration.code)
          end

          it "includes the user" do
            user.update!(registration_metadata: registration_metadata)
            registration.update!(user_group: user_group)

            expect(subject.serialize).to include("User")
            expect(subject.serialize["User"]).to include("Name" => user.name)
            expect(subject.serialize["User"]).to include("Nickname" => user.nickname)
            expect(subject.serialize["User"]).to include("Email" => user.email)
            expect(subject.serialize["User"]).to include("Birth date" => registration_metadata[:birth_date])
            expect(subject.serialize["User"]).to include("Gender" => registration_metadata[:gender])
            expect(subject.serialize["User"]).to include("Work area" => translated(city_work_area.name))
            expect(subject.serialize["User"]).to include("Residential area" => translated(city_residential_area.name))
            expect(subject.serialize["User"]).to include("Statutory representative email" => registration_metadata[:statutory_representative_email])
            expect(subject.serialize["User"]).to include("User group" => user_group&.name)
          end
        end

        context "when questionnaire enabled" do
          let(:meeting) { create :meeting, :with_registrations_enabled }
          let!(:user) { create(:user, organization: meeting.organization) }
          let!(:registration) { create(:registration, meeting: meeting, user: user) }

          let!(:questions) { create_list :questionnaire_question, 3, questionnaire: meeting.questionnaire }
          let!(:answers) do
            questions.map do |question|
              create :answer, questionnaire: meeting.questionnaire, question: question, user: user
            end
          end

          let!(:multichoice_question) { create :questionnaire_question, questionnaire: meeting.questionnaire, question_type: "multiple_option" }
          let!(:multichoice_answer_options) { create_list :answer_option, 2, question: multichoice_question }
          let!(:multichoice_answer) do
            create :answer, questionnaire: meeting.questionnaire, question: multichoice_question, user: user, body: nil
          end
          let!(:multichoice_answer_choices) do
            multichoice_answer_options.map do |answer_option|
              create :answer_choice, answer: multichoice_answer, answer_option: answer_option, body: answer_option.body[I18n.locale.to_s]
            end
          end

          let!(:singlechoice_question) { create :questionnaire_question, questionnaire: meeting.questionnaire, question_type: "single_option" }
          let!(:singlechoice_answer_options) { create_list :answer_option, 2, question: multichoice_question }
          let!(:singlechoice_answer) do
            create :answer, questionnaire: meeting.questionnaire, question: singlechoice_question, user: user, body: nil
          end
          let!(:singlechoice_answer_choice) do
            answer_option = singlechoice_answer_options.first
            create :answer_choice, answer: singlechoice_answer, answer_option: answer_option, body: answer_option.body[I18n.locale.to_s]
          end

          let!(:subject) { described_class.new(registration) }
          let(:serialized) { subject.serialize }

          it "includes the answer for each question" do
            expect(serialized["Registration form answers"]).to include(
              "1. #{translated(questions.first.body, locale: I18n.locale)}" => answers.first.body
            )
            expect(serialized["Registration form answers"]).to include(
              "3. #{translated(questions.last.body, locale: I18n.locale)}" => answers.last.body
            )
            expect(serialized["Registration form answers"]).to include(
              "4. #{translated(multichoice_question.body, locale: I18n.locale)}" => multichoice_answer_choices.map(&:body)
            )

            expect(serialized["Registration form answers"]).to include(
              "5. #{translated(singlechoice_question.body, locale: I18n.locale)}" => [singlechoice_answer_choice.body]
            )
          end
        end
      end
    end
  end
end

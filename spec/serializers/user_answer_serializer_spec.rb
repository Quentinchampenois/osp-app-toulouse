# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    describe UserAnswersSerializer do
      subject do
        described_class.new(questionnaire.answers)
      end

      let!(:questionable) { create(:dummy_resource) }
      let!(:questionnaire) { create(:questionnaire, questionnaire_for: questionable) }
      let!(:user) { create(:user, organization: questionable.organization) }
      let!(:questions) { create_list :questionnaire_question, 3, questionnaire: questionnaire }
      let!(:answers) do
        questions.map do |question|
          create :answer, questionnaire: questionnaire, question: question, user: user
        end
      end

      let!(:multichoice_question) { create :questionnaire_question, questionnaire: questionnaire, question_type: "multiple_option" }
      let!(:multichoice_answer_options) { create_list :answer_option, 2, question: multichoice_question }
      let!(:multichoice_answer) do
        create :answer, questionnaire: questionnaire, question: multichoice_question, user: user, body: nil
      end
      let!(:multichoice_answer_choices) do
        multichoice_answer_options.map do |answer_option|
          create :answer_choice, answer: multichoice_answer, answer_option: answer_option, body: answer_option.body[I18n.locale.to_s]
        end
      end

      let!(:singlechoice_question) { create :questionnaire_question, questionnaire: questionnaire, question_type: "single_option" }
      let!(:singlechoice_answer_options) { create_list :answer_option, 2, question: multichoice_question }
      let!(:singlechoice_answer) do
        create :answer, questionnaire: questionnaire, question: singlechoice_question, user: user, body: nil
      end
      let!(:singlechoice_answer_choice) do
        answer_option = singlechoice_answer_options.first
        create :answer_choice, answer: singlechoice_answer, answer_option: answer_option, body: answer_option.body[I18n.locale.to_s], custom_body: "Free text"
      end
      let!(:city_parent_scope) do
        create(:scope,
               name: {
                 fr: "Ville de Toulouse",
                 en: "Toulouse city"
               },
               organization: questionable.organization)
      end
      let!(:metropolis_parent_scope) do
        create(:scope,
               name: {
                 fr: "Métropole de Toulouse",
                 en: "Toulouse metropolis"
               },
               organization: questionable.organization)
      end

      let!(:city_residential_area) { create(:scope, parent: city_parent_scope) }
      let!(:city_work_area) { create(:scope, parent: city_parent_scope) }
      let!(:metropolis_residential_area) { create(:scope, parent: metropolis_parent_scope) }
      let!(:metropolis_work_area) { create(:scope, parent: metropolis_parent_scope) }

      let(:living_area) { "city" }

      let(:registration_metadata) do
        {
          birth_date: "1981",
          gender: "Female",
          living_area: living_area,
          city_work_area: city_work_area.id,
          city_residential_area: city_residential_area.id,
          metropolis_residential_area: metropolis_residential_area.id,
          metropolis_work_area: metropolis_work_area.id,
          statutory_representative_email: "statutory_representative_email@example.org"
        }
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "includes the answer for each question" do
          questions.each_with_index do |question, idx|
            expect(serialized).to include(
              "#{idx + 1}. #{translated(question.body, locale: I18n.locale)}" => answers[idx].body
            )
          end

          expect(serialized).to include(
            "4. #{translated(multichoice_question.body, locale: I18n.locale)}" => multichoice_answer_choices.map(&:body)
          )

          expect(serialized).to include(
            "5. #{translated(singlechoice_question.body, locale: I18n.locale)}" => ["Free text"]
          )
        end

        context "and includes the attributes" do
          let!(:an_answer) { create(:answer, questionnaire: questionnaire, question: questions.sample, user: user) }

          it "the id of the answer" do
            key = I18n.t(:id, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq an_answer.id
          end

          it "the creation of the answer" do
            key = I18n.t(:created_at, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq an_answer.created_at.to_s(:db)
          end
        end

        it "doesn't includes user data" do
          expect(serialized["Username"]).to eq(nil)
          expect(serialized["Nickname"]).to eq(nil)
          expect(serialized["Email"]).to eq(nil)
          expect(serialized["Birth date"]).to eq(nil)
          expect(serialized["Gender"]).to eq(nil)
          expect(serialized["City work area"]).to eq(nil)
          expect(serialized["City residential area"]).to eq(nil)
          expect(serialized["Metropolis work area"]).to eq(nil)
          expect(serialized["Metropolis residential area"]).to eq(nil)
          expect(serialized["Statutory representative email"]).to eq(nil)
        end

        context "when export is made by administrator" do
          subject do
            described_class.new(questionnaire.answers, true)
          end

          let(:serialized) { subject.serialize }

          context "when living_area is city" do
            it "serializes user data" do
              user.update!(registration_metadata: registration_metadata)

              expect(serialized["Username"]).to eq(user.name)
              expect(serialized["Nickname"]).to eq(user.nickname)
              expect(serialized["Email"]).to eq(user.email)
              expect(serialized["Gender"]).to eq(registration_metadata[:gender])
              expect(serialized["Living area"]).to eq(registration_metadata[:living_area])
              expect(serialized["City work area"]).to eq(translated(city_work_area.name))
              expect(serialized["City residential area"]).to eq(translated(city_residential_area.name))
              expect(serialized["Metropolis work area"]).to eq("")
              expect(serialized["Metropolis residential area"]).to eq("")
              expect(serialized["Statutory representative email"]).to eq(registration_metadata[:statutory_representative_email])
              expect(serialized["Birth date"]).to eq(registration_metadata[:birth_date])
            end
          end

          context "when living_area is metropolis" do
            let(:living_area) { "metropolis" }

            it "serializes user data" do
              user.update!(registration_metadata: registration_metadata)

              expect(serialized["Username"]).to eq(user.name)
              expect(serialized["Nickname"]).to eq(user.nickname)
              expect(serialized["Email"]).to eq(user.email)
              expect(serialized["Gender"]).to eq(registration_metadata[:gender])
              expect(serialized["Living area"]).to eq(registration_metadata[:living_area])
              expect(serialized["City work area"]).to eq("")
              expect(serialized["City residential area"]).to eq("")
              expect(serialized["Metropolis work area"]).to eq(translated(metropolis_work_area.name))
              expect(serialized["Metropolis residential area"]).to eq(translated(metropolis_residential_area.name))
              expect(serialized["Statutory representative email"]).to eq(registration_metadata[:statutory_representative_email])
              expect(serialized["Birth date"]).to eq(registration_metadata[:birth_date])
            end
          end

          context "when living_area is other" do
            let(:living_area) { "other" }

            it "serializes user data" do
              user.update!(registration_metadata: registration_metadata)

              expect(serialized["Username"]).to eq(user.name)
              expect(serialized["Nickname"]).to eq(user.nickname)
              expect(serialized["Email"]).to eq(user.email)
              expect(serialized["Gender"]).to eq(registration_metadata[:gender])
              expect(serialized["Living area"]).to eq(registration_metadata[:living_area])
              expect(serialized["City work area"]).to eq("")
              expect(serialized["City residential area"]).to eq("")
              expect(serialized["Metropolis work area"]).to eq("")
              expect(serialized["Metropolis residential area"]).to eq("")
              expect(serialized["Work area"]).not_to eq(translated(metropolis_work_area.name))
              expect(serialized["Residential area"]).not_to eq(translated(metropolis_residential_area.name))
              expect(serialized["Statutory representative email"]).to eq(registration_metadata[:statutory_representative_email])
              expect(serialized["Birth date"]).to eq(registration_metadata[:birth_date])
            end
          end

          context "when user has no registration metadata" do
            before do
              user.update!(registration_metadata: nil)
            end

            it "doesn't includes user registration metadata" do
              expect(serialized["Birth date"]).to be_empty
              expect(serialized["Gender"]).to be_empty
              expect(serialized["City work area"]).to be_empty
              expect(serialized["Metropolis work area"]).to be_empty
              expect(serialized["City residential area"]).to be_empty
              expect(serialized["Metropolis residential area"]).to be_empty
              expect(serialized["Statutory representative email"]).to be_empty
            end
          end

          it "includes user columns" do
            expect(serialized["Username"]).not_to eq(nil)
            expect(serialized["Nickname"]).not_to eq(nil)
            expect(serialized["Email"]).not_to eq(nil)
            expect(serialized["Birth date"]).not_to eq(nil)
            expect(serialized["Gender"]).not_to eq(nil)
            expect(serialized["City work area"]).not_to eq(nil)
            expect(serialized["City residential area"]).not_to eq(nil)
            expect(serialized["Metropolis work area"]).not_to eq(nil)
            expect(serialized["Metropolis residential area"]).not_to eq(nil)
            expect(serialized["Statutory representative email"]).not_to eq(nil)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalSerializer do
      subject do
        described_class.new(proposal)
      end

      let(:creator) { proposal.authors.first }
      let!(:proposal) { create(:proposal, :accepted) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: proposal.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { proposal.component }

      let!(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
      let(:meetings) { create_list(:meeting, 2, component: meetings_component) }

      let!(:proposals_component) { create(:component, manifest_name: "proposals", participatory_space: participatory_process) }
      let(:other_proposals) { create_list(:proposal, 2, component: proposals_component) }

      let(:expected_answer) do
        answer = proposal.answer
        Decidim.available_locales.each_with_object({}) do |locale, result|
          result[locale.to_s] = if answer.is_a?(Hash)
                                  answer[locale.to_s] || ""
                                else
                                  ""
                                end
        end
      end

      before do
        proposal.add_coauthor(creator)
        proposal.update!(category: category)
        proposal.update!(scope: scope)
        proposal.link_resources(meetings, "proposals_from_meeting")
        proposal.link_resources(other_proposals, "copied_from_component")
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include("ID" => proposal.id)
        end

        it "serializes the category" do
          expect(serialized["Category"]).to include("ID" => category.id)
          expect(serialized["Category"]).to include("Name" => category.name)
        end

        it "serializes the scope" do
          expect(serialized["Scope"]).to include("ID" => scope.id)
          expect(serialized["Scope"]).to include("Name" => scope.name)
        end

        it "serializes the title" do
          expect(serialized).to include("Title" => translated(proposal.title))
        end

        it "serializes the body" do
          expect(serialized).to include("Content" => translated(proposal.body))
        end

        it "serializes the amount of supports" do
          expect(serialized).to include("Supports" => proposal.proposal_votes_count)
        end

        it "serializes the amount of comments" do
          expect(serialized).to include("Comments" => proposal.comments.count)
        end

        it "serializes the date of creation" do
          expect(serialized).to include("Publication date" => proposal.published_at)
        end

        it "serializes the url" do
          expect(serialized["Url"]).to include("http", proposal.id.to_s)
        end

        it "serializes the component" do
          expect(serialized["Component"]).to include("ID" => proposal.component.id)
        end

        it "serializes the meetings" do
          expect(serialized["Meeting url"].length).to eq(2)
          expect(serialized["Meeting url"].first).to match(%r{http.*/meetings})
        end

        it "serializes the participatory space" do
          expect(serialized["Participatory space"]).to include("ID" => participatory_process.id)
          expect(serialized["Participatory space"]["URL"]).to include("http", participatory_process.slug)
        end

        it "serializes the state" do
          expect(serialized).to include("State" => proposal.state)
        end

        it "serializes the reference" do
          expect(serialized).to include("Reference" => proposal.reference)
        end

        it "serializes the answer" do
          expect(serialized).to include("Answer" => expected_answer)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include("Attachments" => proposal.attachments.count)
        end

        it "serializes the amount of endorsements" do
          expect(serialized).to include("Endorsements" => proposal.endorsements.count)
        end

        it "serializes related proposals" do
          expect(serialized["Related proposals"].length).to eq(2)
          expect(serialized["Related proposals"].first).to match(%r{http.*/proposals})
        end

        it "doesn't serializes authors data" do
          expect(serialized).not_to include("Authors")
        end

        context "when export is made by administrator on backoffice" do
          subject do
            described_class.new(proposal, true)
          end

          let(:registration_metadata) { { birth_date: [], gender: [], city_work_area: [], city_residential_area: [], statutory_representative_email: [] } }

          it "serializes authors" do
            expect(serialized).to include("Authors")
          end

          context "when creator is a unique user" do
            let(:city_work_area) { create(:scope, organization: participatory_process.organization) }
            let(:city_residential_area) { create(:scope, organization: participatory_process.organization) }
            let(:registration_metadata) do
              {
                birth_date: "1981",
                gender: "Female",
                city_work_area: city_work_area.id,
                city_residential_area: city_residential_area.id,
                statutory_representative_email: "statutory_representative_email@example.org"
              }
            end

            before do
              creator.update!(registration_metadata: registration_metadata)
            end

            it "serializes author data" do
              expect(serialized["Authors"]).to include("Names" => creator.name)
              expect(serialized["Authors"]).to include("Nicknames" => creator.nickname)
              expect(serialized["Authors"]).to include("Emails" => creator.email)
              expect(serialized["Authors"]).to include("Gender" => registration_metadata[:gender])
              expect(serialized["Authors"]).to include("Work area" => translated(city_work_area.name))
              expect(serialized["Authors"]).to include("Residential area" => translated(city_residential_area.name))
              expect(serialized["Authors"]).to include("Statutory representative email" => registration_metadata[:statutory_representative_email])
              expect(serialized["Authors"]).to include("Birth date" => registration_metadata[:birth_date])
            end

            context "when unique user doesn't have registration metadata" do
              before do
                proposal.authors.first.update!(registration_metadata: nil)
              end

              it "leaves empty each fields" do
                expect(serialized["Authors"]["Birth date"]).to be_empty
                expect(serialized["Authors"]["Gender"]).to be_empty
                expect(serialized["Authors"]["Work area"]).to be_empty
                expect(serialized["Authors"]["Residential area"]).to be_empty
                expect(serialized["Authors"]["Statutory representative email"]).to be_empty
              end
            end
          end

          context "when there is several creators" do
            let(:another_creator) { create(:user, :confirmed, organization: proposal.organization) }
            let(:city_work_area_2) { create(:scope, organization: participatory_process.organization) }
            let(:city_residential_area_2) { create(:scope, organization: participatory_process.organization) }
            let(:registration_metadata_2) do
              {
                birth_date: { "year": "2016", "month": "May" },
                gender: "Male",
                city_work_area: city_work_area_2.id,
                city_residential_area: city_residential_area_2.id,
                statutory_representative_email: "statutory_representative_email_2@example.org"
              }
            end

            before do
              another_creator.update!(registration_metadata: registration_metadata_2)
              proposal.add_coauthor(another_creator)
            end

            it "serializes authors data" do
              registration_metadatas = proposal.authors.collect(&:registration_metadata)
              expect(serialized["Authors"]["Names"]).to eq("#{creator.name},#{another_creator.name}")
              expect(serialized["Authors"]["Nicknames"]).to eq("#{creator.nickname},#{another_creator.nickname}")
              expect(serialized["Authors"]["Emails"]).to eq("#{creator.email},#{another_creator.email}")
              expect(serialized["Authors"]["Gender"]).to eq("other,#{registration_metadata_2[:gender]}")
              expect(serialized["Authors"]["Work area"]).to eq("-,#{translated(city_work_area_2.name)}")
              expect(serialized["Authors"]["Residential area"]).to eq("-,#{translated(city_residential_area_2.name)}")
              expect(serialized["Authors"]["Statutory representative email"]).to eq(registration_metadatas.map { |rg_metadata| rg_metadata["statutory_representative_email"] }.join(","))
              expect(serialized["Authors"]["Birth date"]).not_to be_empty
            end

            it "serializes the two authors names" do
              expect(serialized["Authors"]["Names"]).to include(proposal.authors.collect(&:name).join(","))
            end
          end

          context "when creator is a user group" do
            let(:author) { create(:user, :confirmed, organization: proposal.organization) }
            let(:user_group) { create(:user_group, :verified, users: [author], organization: proposal.organization) }

            before do
              proposal.coauthorships.clear
              proposal.add_coauthor(author, user_group: user_group)
            end

            it "serializes authors data" do
              registration_metadatas = proposal.authors.collect(&:registration_metadata)

              expect(serialized["Authors"]["Names"]).to eq("#{creator.name},#{author.name}")
              expect(serialized["Authors"]["Nicknames"]).to eq("#{creator.nickname},#{author.nickname}")
              expect(serialized["Authors"]["Emails"]).to eq("#{creator.email},#{author.email}")
              expect(serialized["Authors"]["Gender"]).to eq("other,other")
              expect(serialized["Authors"]["Work area"]).to eq("-,-")
              expect(serialized["Authors"]["Residential area"]).to eq("-,-")
              expect(serialized["Authors"]["Statutory representative email"]).to eq(registration_metadatas.map { |rg_metadata| rg_metadata["statutory_representative_email"] }.join(","))
              expect(serialized["Authors"]["Birth date"]).not_to be_empty
            end
          end

          context "when creator is the organization" do
            before do
              proposal.coauthorships.clear
              proposal.add_coauthor(proposal.organization)
            end

            it "serializes authors metadata" do
              expect(serialized).to include("Authors")
              expect(serialized["Authors"]).to include("Names")
              expect(serialized["Authors"]).to include("Nicknames")
              expect(serialized["Authors"]).to include("Emails")
              expect(serialized["Authors"]).to include("Birth date")
              expect(serialized["Authors"]).to include("Gender")
              expect(serialized["Authors"]).to include("Work area")
              expect(serialized["Authors"]).to include("Residential area")
              expect(serialized["Authors"]).to include("Statutory representative email")
            end

            it "leaves empty each values" do
              expect(serialized["Authors"]["Names"]).to be_empty
              expect(serialized["Authors"]["Nicknames"]).to be_empty
              expect(serialized["Authors"]["Emails"]).to be_empty
              expect(serialized["Authors"]["Birth date"]).to be_empty
              expect(serialized["Authors"]["Gender"]).to be_empty
              expect(serialized["Authors"]["Work area"]).to be_empty
              expect(serialized["Authors"]["Residential area"]).to be_empty
              expect(serialized["Authors"]["Statutory representative email"]).to be_empty
            end
          end
        end

        context "with proposal having an answer" do
          let!(:proposal) { create(:proposal, :with_answer) }

          it "serializes the answer" do
            expect(serialized).to include(t("decidim.proposals.admin.exports.column_name.proposals.answer") => expected_answer)
          end
        end
      end
    end
  end
end

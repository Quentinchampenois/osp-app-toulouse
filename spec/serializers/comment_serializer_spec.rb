# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Comments
    describe CommentSerializer do
      let(:author) { comment.author }
      let(:comment) { create(:comment) }
      let(:subject) { described_class.new(comment) }
      let(:city_work_area) { create(:scope, organization: comment.organization) }
      let(:city_residential_area) { create(:scope, organization: comment.organization) }
      let(:registration_metadata) do
        {
          birth_date: "1995",
          gender: "Female",
          city_work_area: city_work_area.id,
          city_residential_area: city_residential_area.id,
          statutory_representative_email: "statutory_representative_email@example.org"
        }
      end

      describe "#serialize" do
        before do
          allow(Time.zone.now).to receive(:year).and_return("2021")
        end

        it "includes the id" do
          expect(subject.serialize).to include("ID" => comment.id)
        end

        it "includes the creation date" do
          expect(subject.serialize).to include("Creation date" => comment.created_at)
        end

        it "includes the body" do
          expect(subject.serialize).to include("Content" => comment.body)
        end

        it "includes the author" do
          expect(subject.serialize["Author"]).to(
            include("ID" => author.id, "Name" => author.name)
          )
        end

        it "includes the alignment" do
          expect(subject.serialize).to include("Alignment" => comment.alignment)
        end

        it "includes the depth" do
          expect(subject.serialize).to include("Depth" => comment.depth)
        end

        it "includes the root commentable's url" do
          expect(subject.serialize["Root commentable URL"]).to match(/http/)
        end

        it "includes authors metadata" do
          author.update!(registration_metadata: registration_metadata)

          expect(subject.serialize["Author"]).to include("Birth date" => "1995")
          expect(subject.serialize["Author"]).to include("Age scope" => "From 25 to 39 years old")
          expect(subject.serialize["Author"]).to include("Gender" => "Female")
          expect(subject.serialize["Author"]).to include("Work area" => translated(city_work_area.name))
          expect(subject.serialize["Author"]).to include("Residential area" => translated(city_residential_area.name))
          expect(subject.serialize["Author"]).to include("Statutory representative email" => "statutory_representative_email@example.org")
        end
      end
    end
  end
end

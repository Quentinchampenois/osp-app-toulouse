# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Exporters::Serializer do
    let(:subject) { described_class.new(resource) }
    let(:resource) { OpenStruct.new(id: 1, name: "John") }
    let(:admin_extra_fields) { OpenStruct.new(age: 30, city: "London") }

    it { expect(subject).respond_to? :resource }

    describe "#serialize" do
      context "when export is public" do
        it "serializer doesn't merge the admin_extra_fields" do
          expect(subject.serialize).to include(:id)
          expect(subject.serialize).to include(:name)
          expect(subject.serialize).not_to include(:age)
          expect(subject.serialize).not_to include(:city)
        end

        it "turns the object into a hash" do
          expect(subject.serialize).to eq(id: resource.id, name: resource.name)
        end
      end

      context "when export is made by administrator" do
        let(:subject) { described_class.new(resource, true) }

        before do
          allow(subject).to receive(:admin_extra_fields).and_return(admin_extra_fields.to_h)
        end

        it "serializer merges the admin_extra_fields" do
          expect(subject.serialize).to include(:id)
          expect(subject.serialize).to include(:name)
          expect(subject.serialize).to include(:age)
          expect(subject.serialize).to include(:city)
        end

        it "turns the object into a hash" do
          expect(subject.serialize).to eq(
            id: resource.id,
            name: resource.name,
            age: admin_extra_fields.age,
            city: admin_extra_fields.city
          )
        end
      end
    end

    describe "#options_merge" do
      context "when export is public" do
        it "returns a empty Hash" do
          expect(subject.send(:options_merge, admin_extra_fields.to_h)).to eq({})
        end
      end

      context "when export is made by administrator" do
        let(:subject) { described_class.new(resource, true) }

        it "returns the options parameter" do
          expect(subject.send(:options_merge, admin_extra_fields.to_h)).to eq(age: admin_extra_fields.age, city: admin_extra_fields.city)
        end

        context "when options parameters is empty" do
          it "returns a empty hash" do
            expect(subject.send(:options_merge)).to eq({})
          end
        end

        context "when options parameters is not a Hash" do
          it "returns a empty hash" do
            expect(subject.send(:options_merge, admin_extra_fields)).to eq({})
          end
        end
      end
    end

    describe "#age_scope" do
      before do
        allow(Time.zone.now).to receive(:year).and_return("2021")
      end

      context "when age is nil" do
        let(:age) { nil }

        it "returns empty string" do
          expect(subject.send(:age_scope, age)).to be_empty
        end
      end

      context "when age is 15 years old" do
        let(:age) { "2006" }

        it "serializes user data" do
          expect(subject.send(:age_scope, age)).to eq("Less than 18 years old")
        end
      end

      context "when age is 20 years old" do
        let(:age) { "2001" }

        it "serializes user data" do
          expect(subject.send(:age_scope, age)).to eq("From 18 to 24 years old")
        end
      end

      context "when age is 30 years old" do
        let(:age) { "1991" }

        it "serializes user data" do
          expect(subject.send(:age_scope, age)).to eq("From 25 to 39 years old")
        end
      end

      context "when age is 40 years old" do
        let(:age) { "1981" }

        it "serializes user data" do
          expect(subject.send(:age_scope, age)).to eq("From 40 to 65 years old")
        end
      end

      context "when age is 68 years old" do
        let(:age) { "1953" }

        it "serializes user data" do
          expect(subject.send(:age_scope, age)).to eq("More than 65 years old")
        end
      end
    end
  end
end

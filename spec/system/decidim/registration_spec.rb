# frozen_string_literal: true

require "spec_helper"

def fill_registration_form(params = {})
  if params[:step] == 1
    within "ol.horizontal__steps" do
      expect(page).to have_css("li:first-child", class: "step--active")
      expect(page).not_to have_css("li:last-child", class: "step--active")
    end

    fill_in :registration_user_email, with: "nikola.tesla@example.org"
    fill_in :registration_user_password, with: "sekritpass123"
    fill_in :registration_user_password_confirmation, with: "sekritpass123"
    check("registration_user_tos_agreement")
    check("registration_user_additional_tos")
  else
    within "ol.horizontal__steps" do
      expect(page).not_to have_css("li:first-child", class: "step--active")
      expect(page).to have_css("li:last-child", class: "step--active")
    end

    fill_in :registration_user_name, with: "Nikola Tesla"
    fill_in :registration_user_nickname, with: "the-greatest-genius-in-history"

    expect(page).not_to have_select("user[metropolis_residential_area]")
    expect(page).not_to have_select("user[metropolis_work_area]")
    expect(page).not_to have_select("user[city_residential_area]")
    expect(page).not_to have_select("user[city_work_area]")
    if params[:living_area] == :metropolis
      select("Metropolis", from: :registration_user_living_area)
      select translated(metropolis_residential_scope.name), from: :registration_user_metropolis_residential_area
      select translated(metropolis_work_scope.name), from: :registration_user_metropolis_work_area

      expect(page).to have_select("user[metropolis_residential_area]")
      expect(page).to have_select("user[metropolis_work_area]")
      expect(page).not_to have_select("user[city_residential_area]")
      expect(page).not_to have_select("user[city_work_area]")
    elsif params[:living_area] == :other
      select("Other", from: :registration_user_living_area)

      expect(page).not_to have_select("user[city_residential_area]")
      expect(page).not_to have_select("user[city_work_area]")
      expect(page).not_to have_select("user[metropolis_residential_area]")
      expect(page).not_to have_select("user[metropolis_work_area]")
    else
      select("City", from: :registration_user_living_area)
      select translated(city_residential_scope.name), from: :registration_user_city_residential_area
      select translated(city_work_scope.name), from: :registration_user_city_work_area

      expect(page).not_to have_select("user[metropolis_residential_area]")
      expect(page).not_to have_select("user[metropolis_work_area]")
      expect(page).to have_select("user[city_residential_area]")
      expect(page).to have_select("user[city_work_area]")
    end

    select "Other", from: :registration_user_gender
    select "September", from: :registration_user_month
    select "1992", from: :registration_user_year
    check :registration_underage_registration
    fill_in :registration_user_statutory_representative_email, with: "milutin.tesla@example.org"
  end
end

def submit_form
  within("form.new_user") do
    find("*[type=submit]").click
  end
end

describe "Registration", type: :system do
  let(:organization) { create(:organization) }
  let!(:city_parent_scope) do
    create(:scope,
           name: {
             fr: "Ville de Toulouse",
             en: "Toulouse city"
           },
           organization: organization)
  end
  let!(:metropolis_parent_scope) do
    create(:scope,
           name: {
             fr: "Métropole de Toulouse",
             en: "Toulouse metropolis"
           },
           organization: organization)
  end

  let!(:city_residential_scope) { create(:scope, parent: city_parent_scope) }
  let!(:city_work_scope) { create(:scope, parent: city_parent_scope) }
  let!(:metropolis_residential_scope) { create(:scope, parent: metropolis_parent_scope) }
  let!(:metropolis_work_scope) { create(:scope, parent: metropolis_parent_scope) }
  let!(:terms_and_conditions_page) { Decidim::StaticPage.find_by(slug: "terms-and-conditions", organization: organization) }
  let!(:another_user) { create(:user, organization: organization) }

  before do
    switch_to_host(organization.host)
    visit decidim.new_user_registration_path
  end

  context "when signing up" do
    describe "on first sight" do
      it "shows fields empty" do
        expect(page).to have_content("Sign up to participate")
        expect(page).to have_field("registration_user_email", with: "")
        expect(page).to have_field("registration_user_password", with: "")
        expect(page).to have_field("registration_user_password_confirmation", with: "")
      end
    end

    describe "after clicking in next step" do
      it "forces user to fill first step attributes" do
        expect(page).to have_button("Continue", disabled: true)

        expect(page).to have_field("registration_user_email", with: "")
        expect(page).to have_field("registration_user_password", with: "")
        expect(page).to have_field("registration_user_password_confirmation", with: "")
        expect(page).not_to have_field("registration_user_name", with: "")
        expect(page).not_to have_field("registration_user_nickname", with: "")
      end

      context "when a mandatory field is missing" do
        it "forces user to fill first step attributes" do
          fill_registration_form(step: 1)
          fill_in :registration_user_email, with: ""

          expect(page).to have_button("Continue", disabled: true)
          expect(find_field(:registration_user_email)[:class]).to eq("is-invalid-input")
        end
      end

      context "when multiples mandatory fields are missing" do
        it "forces user to fill first step attributes" do
          fill_registration_form(step: 1)
          fill_in :registration_user_email, with: ""
          fill_in :registration_user_password, with: ""

          expect(page).to have_button("Continue", disabled: true)
          expect(find_field(:registration_user_email)[:class]).to eq("is-invalid-input")
          expect(find_field(:registration_user_password)[:class]).to eq("is-invalid-input")
        end
      end

      context "when a password confirmation doesn't match" do
        it "forces user to fill first step attributes" do
          fill_registration_form(step: 1)
          fill_in :registration_user_password_confirmation, with: "no-match"

          expect(page).to have_button("Continue", disabled: true)
        end
      end

      it "shows fields empty" do
        fill_registration_form(step: 1)
        click_button "Continue"

        expect(page).not_to have_field("registration_user_email")
        expect(page).not_to have_field("registration_user_password")
        expect(page).not_to have_field("registration_user_password_confirmation")
        expect(page).to have_field("registration_user_name", with: "")
        expect(page).to have_field("registration_user_nickname", with: "")
        expect(page).to have_select("user[living_area]", selected: "Please select")
        expect(page).to have_select("user[gender]", selected: "Please select")
        expect(page).to have_select("user[month]", selected: "Please select")
        expect(page).to have_select("user[year]", selected: "Please select")
        expect(page).to have_unchecked_field("Underage")
      end
    end
  end

  context "when registering with additional fields" do
    before do
      fill_registration_form(step: 1)
      click_button "Continue"
    end

    context "when living area is city" do
      it "allows user to register" do
        fill_registration_form(step: 2)
        submit_form

        expect(page).to have_content("Welcome! You have signed up successfully.")
      end
    end

    context "when living area is metropolis" do
      it "allows user to register" do
        fill_registration_form(step: 2, living_area: :metropolis)
        submit_form

        expect(page).to have_content("Welcome! You have signed up successfully.")
      end
    end

    context "when living area is other" do
      it "allows user to register" do
        fill_registration_form(step: 2, living_area: :other)
        submit_form

        expect(page).to have_content("Welcome! You have signed up successfully.")
      end
    end
  end
end

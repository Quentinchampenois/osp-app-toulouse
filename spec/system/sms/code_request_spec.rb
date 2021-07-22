# frozen_string_literal: true

require "spec_helper"

describe "SMS code request", type: :system do
  let!(:organization) do
    create(:organization, available_authorizations: ["sms"])
  end

  let!(:user) { create(:user, :confirmed, organization: organization) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_sms.root_path
  end

  it "redirects to verification after login" do
    expect(page).to have_content("Verify your identity with the SMS verification method")
    expect(page).to have_content("Enter your phone number and the verification code sent by SMS. This method allows us to ensure that you have voted only once.")
    expect(page).to have_content("Must contain only numbers")
    expect(page).to have_content("Must start with 0")
    expect(page).to have_content("Must contain 10 digits")
    expect(page).to have_content("Must not be used by another account on this platform")
  end

  context "when requesting a code by sms" do
    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(SMSGatewayService).to receive(:deliver_code).and_return(true)
      # rubocop:enable RSpec/AnyInstance

      fill_in "Mobile phone number", with: "600102030"
      click_button "Send me an SMS"
    end

    it "allows the user to request a code by sms to get verified" do
      expect(page).to have_content("Thanks! We've sent an SMS to your phone")
    end
  end
end

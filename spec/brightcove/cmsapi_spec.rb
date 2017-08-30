require "spec_helper"

RSpec.describe Brightcove::Cmsapi do
  it "has a version number" do
    expect(Brightcove::Cmsapi::VERSION).not_to be nil
  end

  before do
    stub_request(:post, Brightcove::Cmsapi::OAUTH_ENDPOINT)
      .to_return(
        body: '{
          "access_token": "test_token",
          "token_type": "Bearer",
          "expires_in": 300
        }',
        headers: { 'Content-Type': 'application/json' }
      )

    stub_request(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos")
      .to_return(
        body: '{
          "temp": "temp"
        }',
        headers: { 'Content-Type': 'application/json' }
      )
  end

  let(:client) do
    Brightcove::Cmsapi.new(
      account_id: "my_account_id",
      client_id: "my_client_id",
      client_secret: "my_client_secret")
  end

  describe ".new" do
    it "calls the brightcove API for a token when initialized" do
      client

      expect(WebMock).to have_requested(:post, Brightcove::Cmsapi::OAUTH_ENDPOINT)
        .with(basic_auth: ['my_client_id', 'my_client_secret'])
    end
  end

  describe ".get" do
    it "uses the oauth token in request header" do
      client.get("videos")

      expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos")
        .with(headers: { 'Authorization': 'Bearer test_token' })
    end

    it "reuses the token for requests made within the token expiry time" do
      client.get("videos")
      client.get("videos")
      client.get("videos")

      expect(WebMock).to have_requested(:post, Brightcove::Cmsapi::OAUTH_ENDPOINT)
        .with(basic_auth: ['my_client_id', 'my_client_secret']).once
    end
  end
end

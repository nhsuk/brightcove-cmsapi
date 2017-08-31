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

    stub_request(:get, %r{#{Brightcove::Cmsapi::API_ROOT}/my_account_id/.*})
      .to_return(
        body: '[{
          "temp": "temp"
        }]',
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

    it "renews the token before making more requests when expired" do
      client.get("videos")
      Timecop.travel(Time.now + 301)
      client.get("videos")

      expect(WebMock).to have_requested(:post, Brightcove::Cmsapi::OAUTH_ENDPOINT)
        .with(basic_auth: ['my_client_id', 'my_client_secret']).twice
    end

    it "appends argment string to API get request" do
      client.get("playlists?limit=100")

      expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/playlists?limit=100")
    end
  end

  describe ".get_all" do
    context "without a path prefix" do
      it "checks the count of available resources" do
        stub_counts(5)
        client.get_all("video")

        expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/counts/videos")
      end

      context "with a count below 100 that doesn't require multiple requests for paginated results" do
        before do
          stub_counts(20)
        end

        it "makes a single call for resources when count is less than the API's 100 pagination limit" do
          client.get_all("video")

          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=0")
          expect(WebMock).to have_not_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=100")
        end
      end

      context "with a count above 100 that requires multiple requests for paginated results" do
        it "makes two calls for resources when count is between 100 and 200" do
          stub_counts(120)
          client.get_all("video")

          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=0")
          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=100")
        end

        it "makes four calls for resources when count is between 300 and 399" do
          stub_counts(368)
          client.get_all("video")

          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=0")
          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=100")
          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=200")
          expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=300")
          expect(WebMock).to have_not_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/videos?limit=100&offset=400")
        end
      end
    end

    context "with a path prefix" do
      before do
        stub_request(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/folders/my_folder_id")
          .to_return(
            body: '{
              "video_count": 15
            }',
            headers: { 'Content-Type': 'application/json' }
          )
      end

      it "prefixes the resource path" do
        client.get_all("folders/my_folder_id", "video")

        expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/folders/my_folder_id")
        expect(WebMock).to have_requested(:get, "#{Brightcove::Cmsapi::API_ROOT}/my_account_id/folders/my_folder_id/videos?limit=100&offset=0")
      end
    end
  end
end

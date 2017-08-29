require "http"
require "pry"

module Brightcove
  class Cmsapi
    VERSION = "0.1.0"
    OAUTH_ENDPOINT = "https://oauth.brightcove.com/v4/access_token"
    API_ROOT = "https://cms.api.brightcove.com/v1/accounts"

    def initialize(account_id:, client_id:, client_secret:)
      @base_url = "#{API_ROOT}/#{account_id}"
      @client_id = client_id
      @client_secret = client_secret
      set_token
    end

    def self.default_api
      @default_api ||= new(
        account_id: ENV['BRIGHTCOVE_ACCOUNT_ID'],
        client_id: ENV['BRIGHTCOVE_CLIENT_ID'],
        client_secret: ENV['BRIGHTCOVE_CLIENT_SECRET'])
    end

    def get(path)
      set_token if @token_expires < Time.now
      response = HTTP.auth("Bearer #{@token}").get("#{@base_url}/#{path}")

      if response.code == 401 # Unauthorized, token expired
        set_token
        HTTP.auth("Bearer #{@token}").get("#{@base_url}/#{path}")
      else
        response
      end
    end

    def get_all(path, resource)
      count = get(path).parse.fetch("#{resource}_count")
      offset = 0
      resources = []
      while offset < count do
        resources.concat(get("#{path}/#{resource}s?limit=100&offset=#{offset}").parse)
        offset = offset + 100
      end
      resources
    end

    private

    def set_token
      response = HTTP.basic_auth(user: @client_id, pass: @client_secret)
                     .post(OAUTH_ENDPOINT,
                           form: { grant_type: "client_credentials" }).parse
      @token = response.fetch("access_token")
      @token_expires = Time.now + response.fetch("expires_in")
    end
  end
end

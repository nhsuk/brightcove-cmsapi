require "http"
require_relative "errors"

module Brightcove
  class Cmsapi
    OAUTH_ENDPOINT = "https://oauth.brightcove.com/v4/access_token"
    API_ROOT = "https://cms.api.brightcove.com/v1/accounts"

    def initialize(account_id:, client_id:, client_secret:)
      @base_url = "#{API_ROOT}/#{account_id}"
      @client_id = client_id
      @client_secret = client_secret
      set_token
    end

    def self.default_api
      account_id = ENV['BRIGHTCOVE_ACCOUNT_ID']
      client_id = ENV['BRIGHTCOVE_CLIENT_ID']
      client_secret = ENV['BRIGHTCOVE_CLIENT_SECRET']

      if [account_id, client_id, client_secret].any? { |c| c.to_s.empty? }
        raise AuthenticationError, 'Missing Brightcove API credentials'
      end

      @default_api ||= new(
        account_id: account_id,
        client_id: client_id,
        client_secret: client_secret)
    end

    def get(path)
      set_token if @token_expires < Time.now
      response = HTTP.auth("Bearer #{@token}").get("#{@base_url}/#{path}")

      case response.code
      when 200 # OK
        response
      when 401 # Unauthorized, token expired
        set_token
        response = HTTP.auth("Bearer #{@token}").get("#{@base_url}/#{path}")

        # if a fresh token still returns 401 the request must be unauthorized
        raise_account_error if response.code == 401

        response
      else
        raise CmsapiError, response.to_s
      end
    end

    def get_all(path="", resource)
      if path.empty?
        count = get("counts/#{resource}s").parse.fetch("count")
        resource_path = "#{resource}s"
      else
        count = get(path).parse.fetch("#{resource}_count")
        resource_path = "#{path}/#{resource}s"
      end
      offset = 0
      resources = []
      while offset < count do
        resources.concat(get("#{resource_path}?limit=100&offset=#{offset}").parse)
        offset = offset + 100
      end
      resources
    end

    private

    def set_token
      response = HTTP.basic_auth(user: @client_id, pass: @client_secret)
                     .post(OAUTH_ENDPOINT,
                           form: { grant_type: "client_credentials" })
      token_response = response.parse

      if response.status == 200
        @token = token_response.fetch("access_token")
        @token_expires = Time.now + token_response.fetch("expires_in")
      else
        raise AuthenticationError, token_response.fetch("error_description")
      end
    end

    def raise_account_error
      raise AuthenticationError, 'Token valid but not for the given account_id'
    end
  end
end

require 'omniauth'
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Challengepost < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = "user"

      option :name, "challengepost"

      option :client_options, {
        :site => (ENV['CHALLENGEPOST_FOUNTAINHEAD_URL'] || 'http://fountainhead.challengepost.com'),
        :authorize_url => '/oauth/authorize',
        :token_url => '/oauth/access_token'
      }

      option :authorize_options, [:scope]

      uid { raw_info['id'] }

      info do
        prune!({
          'nickname' => raw_info['screen_name'],
          'email' => raw_info['email'],
          'location' => raw_info['location'],
          'first_name' => raw_info['first_name'],
          'last_name' => raw_info['last_name']
        })
      end

      extra do
        prune!({
          'raw_info' => raw_info
        })
      end

      def authorize_params
        super.tap do |params|
          %w[scope].each { |v| params[v.to_sym] = request.params[v] if request.params[v] }
          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      def raw_info
        access_token.options[:mode] = :query
        @raw_info ||= access_token.get("/oauth/user.json").parsed
      end

      protected

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end
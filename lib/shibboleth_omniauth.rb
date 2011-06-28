require 'omniauth/core'
module OmniAuth
  module Strategies
    class Shibboleth
      include OmniAuth::Strategy

      attr_accessor :base_url

      #receive and save any needed parameters for the strategy
      def initialize(app, base_url, options = {})
        self.base_url = base_url
        super(app, :shibboleth, options)
      end

      #redirect to shibboleth login
      def request_phase
        r = Rack::Response.new
        r.redirect shibboleth_login_url
        r.finish
      end

      #check to see if we have a successful authentication
      def callback_phase
        puts "Hi callback"
      end

      #normalize use
      def auth_hash

      end

      protected

      def shibboleth_login_url
        url = self.base_url
        target = make_https(@request.env['HTTP_REFERER'] || 'https://connectionstest.ideals.illinois.edu')
        url = "#{url}?target=#{CGI.escape(target)}"
        return url
      end

      def make_https(url)
        if url.match(/^http:/)
          url.gsub!(/^http:/, 'https:')
        end
        url
      end

    end
  end
end
require 'spec_helper'
require 'omniauth-challengepost'

describe OmniAuth::Strategies::Challengepost do
  before do
    @request = double('Request')
    @request.stub(:params) { {} }
    @request.stub(:cookies) { {} }
    @request.stub(:env) { {} }

    @app_id = '123'
    @app_secret = '53cr3tz'
  end

  subject do
    args = [@app_id, @app_secret, @options].compact
    OmniAuth::Strategies::Challengepost.new(nil, *args).tap do |strategy|
      strategy.stub(:request) { @request }
    end
  end

  it { should be_a(OmniAuth::Strategies::OAuth2) }

  describe '#client' do
    it 'has correct Facebook site' do
      subject.client.site.should eq('http://challengepost.com')
    end

    it 'has correct authorize url' do
      subject.client.options[:authorize_url].should eq('/oauth/authorize')
    end

    it 'has correct token url' do
      subject.client.options[:token_url].should eq('/oauth/token')
    end
  end

  describe '#callback_url' do

    it "returns the default callback url" do
      url_base = 'http://auth.request.com'
      @request.stub(:url) { "#{url_base}/some/page" }
      subject.stub(:script_name) { '' } # as not to depend on Rack env
      subject.callback_url.should eq("#{url_base}/auth/challengepost/callback")
    end

    it "returns path from callback_path option" do
      url_base = 'http://auth.request.com'
      @options = { :callback_path => "/auth/CP/done"}
      @request.stub(:url) { "#{url_base}/some/page" }
      subject.stub(:script_name) { '' } # as not to depend on Rack env
      subject.callback_url.should eq("#{url_base}/auth/CP/done")
    end

  end

  describe '#authorize_options' do
    it 'includes default scope for email and offline access' do
      subject.authorize_params.should be_a(Hash)
      subject.authorize_params[:scope].should eq('user')
    end

    it 'includes scope parameter from request when present' do
      @request.stub(:params) { { 'scope' => 'admin' } }
      subject.authorize_params.should be_a(Hash)
      subject.authorize_params[:scope].should eq('admin')
    end

    it 'includes scope parameter from request when present' do
      @request.stub(:params) { { 'scope' => 'user, admin' } }
      subject.authorize_params.should be_a(Hash)
      subject.authorize_params[:scope].should eq('user, admin')
    end

  end

  describe '#uid' do
    before :each do
      subject.stub(:raw_info) { { 'id' => '123' } }
    end

    it 'returns the id from raw_info' do
      subject.uid.should eq('123')
    end
  end

  describe '#info' do
    context 'when optional data is not present in raw info' do
      before :each do
        subject.stub(:raw_info) { {} }
      end

      it 'has no email key' do
        subject.info.should_not have_key('email')
      end

      it 'has no nickname key' do
        subject.info.should_not have_key('nickname')
      end

      it 'has no first name key' do
        subject.info.should_not have_key('first_name')
      end

      it 'has no last name key' do
        subject.info.should_not have_key('last_name')
      end

      it 'has no location key' do
        subject.info.should_not have_key('location')
      end

    end

    context 'when optional data is present in raw info' do
      before :each do
        @raw_info ||= { 'screen_name' => 'fredsmith' }
        subject.stub(:raw_info) { @raw_info }
      end

      it 'returns the name' do
        subject.info['nickname'].should eq('fredsmith')
      end

      it 'returns the email' do
        @raw_info['email'] = 'fred@smith.com'
        subject.info['email'].should eq('fred@smith.com')
      end

      it 'returns the username as nickname' do
        @raw_info['screen_name'] = 'fredsmith'
        subject.info['nickname'].should eq('fredsmith')
      end

      it 'returns the first name' do
        @raw_info['first_name'] = 'Fred'
        subject.info['first_name'].should eq('Fred')
      end

      it 'returns the last name' do
        @raw_info['last_name'] = 'Smith'
        subject.info['last_name'].should eq('Smith')
      end

      it 'returns the location name as location' do
        @raw_info['location'] = 'Palo Alto, California'
        subject.info['location'].should eq('Palo Alto, California')
      end

    end

  end

  describe '#raw_info' do
    before :each do
      @access_token = double('OAuth2::AccessToken', :options => {})
      subject.stub(:access_token) { @access_token }
    end

    it 'performs a GET to /oauth/user.json' do
      @access_token.stub(:get) { @access_token.as_null_object }
      @access_token.should_receive(:get).with('/user/credentials')
      subject.raw_info
    end

    it 'returns a Hash' do
      @access_token.stub(:get).with('/user/credentials') do
        raw_response = double('Faraday::Response')
        raw_response.stub(:body) { '{ "user" : { "ohai": "thar" } }' }
        raw_response.stub(:status) { 200 }
        raw_response.stub(:headers) { { 'Content-Type' => 'application/json' } }
        OAuth2::Response.new(raw_response)
      end
      subject.raw_info.should be_a(Hash)
      subject.raw_info['ohai'].should eq('thar')
    end
  end

end

#   describe '#credentials' do
#     before :each do
#       @access_token = double('OAuth2::AccessToken')
#       @access_token.stub(:token)
#       @access_token.stub(:expires?)
#       @access_token.stub(:expires_at)
#       @access_token.stub(:refresh_token)
#       subject.stub(:access_token) { @access_token }
#     end

#     it 'returns a Hash' do
#       subject.credentials.should be_a(Hash)
#     end

#     it 'returns the token' do
#       @access_token.stub(:token) { '123' }
#       subject.credentials['token'].should eq('123')
#     end

#     it 'returns the expiry status' do
#       @access_token.stub(:expires?) { true }
#       subject.credentials['expires'].should eq(true)

#       @access_token.stub(:expires?) { false }
#       subject.credentials['expires'].should eq(false)
#     end

#     it 'returns the refresh token and expiry time when expiring' do
#       ten_mins_from_now = (Time.now + 600).to_i
#       @access_token.stub(:expires?) { true }
#       @access_token.stub(:refresh_token) { '321' }
#       @access_token.stub(:expires_at) { ten_mins_from_now }
#       subject.credentials['refresh_token'].should eq('321')
#       subject.credentials['expires_at'].should eq(ten_mins_from_now)
#     end

#     it 'does not return the refresh token when it is nil and expiring' do
#       @access_token.stub(:expires?) { true }
#       @access_token.stub(:refresh_token) { nil }
#       subject.credentials['refresh_token'].should be_nil
#       subject.credentials.should_not have_key('refresh_token')
#     end

#     it 'does not return the refresh token when not expiring' do
#       @access_token.stub(:expires?) { false }
#       @access_token.stub(:refresh_token) { 'XXX' }
#       subject.credentials['refresh_token'].should be_nil
#       subject.credentials.should_not have_key('refresh_token')
#     end
#   end

#   describe '#extra' do
#     before :each do
#       @raw_info = { 'name' => 'Fred Smith' }
#       subject.stub(:raw_info) { @raw_info }
#     end

#     it 'returns a Hash' do
#       subject.extra.should be_a(Hash)
#     end

#     it 'contains raw info' do
#       subject.extra.should eq({ 'raw_info' => @raw_info })
#     end
#   end

#   describe '#signed_request' do
#     context 'cookie/param not present' do
#       it 'is nil' do
#         subject.send(:signed_request).should be_nil
#       end
#     end

#     context 'cookie present' do
#       before :each do
#         @payload = {
#           'algorithm' => 'HMAC-SHA256',
#           'code' => 'm4c0d3z',
#           'issued_at' => Time.now.to_i,
#           'user_id' => '123456'
#         }

#         @request.stub(:cookies) do
#           { "fbsr_#{@client_id}" => signed_request(@payload, @client_secret) }
#         end
#       end

#       it 'parses the access code out from the cookie' do
#         subject.send(:signed_request).should eq(@payload)
#       end
#     end

#     context 'param present' do
#       before :each do
#         @payload = {
#           'algorithm' => 'HMAC-SHA256',
#           'oauth_token' => 'XXX',
#           'issued_at' => Time.now.to_i,
#           'user_id' => '123456'
#         }

#         @request.stub(:params) do
#           { 'signed_request' => signed_request(@payload, @client_secret) }
#         end
#       end

#       it 'parses the access code out from the param' do
#         subject.send(:signed_request).should eq(@payload)
#       end
#     end

#     context 'cookie + param present' do
#       before :each do
#         @payload_from_cookie = {
#           'algorithm' => 'HMAC-SHA256',
#           'from' => 'cookie'
#         }

#         @request.stub(:cookies) do
#           { "fbsr_#{@client_id}" => signed_request(@payload_from_cookie, @client_secret) }
#         end

#         @payload_from_param = {
#           'algorithm' => 'HMAC-SHA256',
#           'from' => 'param'
#         }

#         @request.stub(:params) do
#           { 'signed_request' => signed_request(@payload_from_param, @client_secret) }
#         end
#       end

#       it 'picks param over cookie' do
#         subject.send(:signed_request).should eq(@payload_from_param)
#       end
#     end
#   end

#   describe '#request_phase' do
#     describe 'params contain a signed request with an access token' do
#       before do
#         payload = {
#           'algorithm' => 'HMAC-SHA256',
#           'oauth_token' => 'm4c0d3z'
#         }
#         @raw_signed_request = signed_request(payload, @client_secret)
#         @request.stub(:params) do
#           { "signed_request" => @raw_signed_request }
#         end

#         subject.stub(:callback_url) { '/' }
#       end

#       it 'redirects to callback passing along signed request' do
#         subject.should_receive(:redirect).with("/?signed_request=#{Rack::Utils.escape(@raw_signed_request)}").once
#         subject.request_phase
#       end
#     end
#   end

#   describe '#build_access_token' do
#     describe 'params contain a signed request with an access token' do
#       before do
#         @payload = {
#           'algorithm' => 'HMAC-SHA256',
#           'oauth_token' => 'm4c0d3z'
#         }
#         @raw_signed_request = signed_request(@payload, @client_secret)
#         @request.stub(:params) do
#           { "signed_request" => @raw_signed_request }
#         end

#         subject.stub(:callback_url) { '/' }
#       end

#       it 'returns a new access token from the signed request' do
#         result = subject.build_access_token
#         result.should be_an_instance_of(::OAuth2::AccessToken)
#         result.token.should eq(@payload['oauth_token'])
#       end
#     end
#   end

# private

#   def signed_request(payload, secret)
#     encoded_payload = base64_encode_url(MultiJson.encode(payload))
#     encoded_signature = base64_encode_url(signature(encoded_payload, secret))
#     [encoded_signature, encoded_payload].join('.')
#   end

#   def base64_encode_url(value)
#     Base64.encode64(value).tr('+/', '-_').gsub(/\n/, '')
#   end

#   def signature(payload, secret, algorithm = OpenSSL::Digest::SHA256.new)
#     OpenSSL::HMAC.digest(algorithm, secret, payload)
#   end
# end

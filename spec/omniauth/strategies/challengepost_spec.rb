require 'spec_helper'
require 'omniauth-challengepost'
require 'uri'

describe OmniAuth::Strategies::Challengepost do
  before do
    @request = double('Request')
    allow(@request).to receive(:params) { {} }
    allow(@request).to receive(:cookies) { {} }
    allow(@request).to receive(:env) { {} }
    allow(@request).to receive(:scheme) { 'http' }

    @app_id = '123'
    @app_secret = '53cr3tz'
  end

  subject do
    args = [@app_id, @app_secret, @options].compact
    OmniAuth::Strategies::Challengepost.new(nil, *args).tap do |strategy|
      allow(strategy).to receive(:request) { @request }
    end
  end

  it { should be_a(OmniAuth::Strategies::OAuth2) }

  describe '#client' do
    it 'has correct Facebook site' do
      expect(subject.client.site).to eq('https://api.devpost.com')
    end

    it 'has correct authorize url' do
      expect(subject.client.options[:authorize_url]).to eq('https://oauth.devpost.com/oauth/authorize')
    end

    it 'has correct token url' do
      expect(subject.client.options[:token_url]).to eq('https://oauth.devpost.com/oauth/token')
    end
  end

  describe '#callback_url' do

    it "returns the default callback url" do
      url_base = 'http://auth.request.com'
      allow(@request).to receive(:url) { "#{url_base}/some/page" }
      allow(subject).to receive(:script_name) { '' } # as not to depend on Rack env
      expect(subject.callback_url).to eq("#{url_base}/auth/challengepost/callback")
    end

    it "returns path from callback_path option" do
      url_base = 'http://auth.request.com'
      @options = { :callback_path => "/auth/CP/done"}
      allow(@request).to receive(:url) { "#{url_base}/some/page" }
      allow(subject).to receive(:script_name) { '' } # as not to depend on Rack env
      expect(subject.callback_url).to eq("#{url_base}/auth/CP/done")
    end

  end

  describe '#uid' do
    before :each do
      allow(subject).to receive(:raw_info) { { 'id' => '123' } }
    end

    it 'returns the id from raw_info' do
      expect(subject.uid).to eq('123')
    end
  end

  describe '#info' do
    context 'when optional data is not present in raw info' do
      before :each do

        allow(subject).to receive(:raw_info) { {} }
      end

      it 'has no email key' do
        expect(subject.info).to_not have_key('email')
      end

      it 'has no nickname key' do
        expect(subject.info).to_not have_key('nickname')
      end

      it 'has no first name key' do
        expect(subject.info).to_not have_key('first_name')
      end

      it 'has no last name key' do
        expect(subject.info).to_not have_key('last_name')
      end

      it 'has no location key' do
        expect(subject.info).to_not have_key('location')
      end

    end

    context 'when optional data is present in raw info' do
      before :each do
        @raw_info ||= { 'screen_name' => 'fredsmith' }
        allow(subject).to receive(:raw_info) { @raw_info }
      end

      it 'returns the name' do
        expect(subject.info['nickname']).to eq('fredsmith')
      end

      it 'returns the email' do
        @raw_info['email'] = 'fred@smith.com'
        expect(subject.info['email']).to eq('fred@smith.com')
      end

      it 'returns the username as nickname' do
        @raw_info['screen_name'] = 'fredsmith'
        expect(subject.info['nickname']).to eq('fredsmith')
      end

      it 'returns the first name' do
        @raw_info['first_name'] = 'Fred'
        expect(subject.info['first_name']).to eq('Fred')
      end

      it 'returns the last name' do
        @raw_info['last_name'] = 'Smith'
        expect(subject.info['last_name']).to eq('Smith')
      end

      it 'returns the location name as location' do
        @raw_info['location'] = 'Palo Alto, California'
        expect(subject.info['location']).to eq('Palo Alto, California')
      end

    end

  end

  describe '#raw_info' do
    before :each do
      @access_token = double('OAuth2::AccessToken', :options => {})
      allow(subject).to receive(:access_token) { @access_token }
    end

    it 'performs a GET to /user/credentials' do
      allow(@access_token).to receive(:get) { @access_token.as_null_object }
      expect(@access_token).to receive(:get).with('/user/credentials')
      subject.raw_info
    end

    it 'returns a Hash' do
      allow(@access_token).to receive(:get).with('/user/credentials') do
        raw_response = double('Faraday::Response')
        allow(raw_response).to receive(:body) { '{ "user" : { "ohai": "thar" } }' }
        allow(raw_response).to receive(:status) { 200 }
        allow(raw_response).to receive(:headers) { { 'Content-Type' => 'application/json' } }
        OAuth2::Response.new(raw_response)
      end
      expect(subject.raw_info).to be_a(Hash)
      expect(subject.raw_info['ohai']).to eq('thar')
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

require 'spec_helper'

describe Travis::Build::Addons::ArtifactsV2, :sexp do
  let(:script) { stub('script') }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:config) { { paths: ['/foo.tgz'] } }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { artifacts_v2: config } }) }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }

  before :all do
    ENV['ARTIFACTS_JWT_PRIVATE_KEY'] = OpenSSL::PKey::RSA.generate(2048).to_s
    ENV['ARTIFACTS_SERVER_ADDR'] = 'https://example.com'
  end

  after :all do
    ENV.delete 'ARTIFACTS_JWT_PRIVATE_KEY'
    ENV.delete 'ARTIFACTS_SERVER_ADDR'
  end

  before :each do
    addon.after_after_script
  end

  it { should match_sexp [:cmd, %r[curl -s -X POST -H "Authorization: Bearer .+" -F file=@/foo.tgz https://example.com/jobs/1]] }
end

require 'travis/build/addons/base'

require 'jwt'
require 'openssl'

module Travis
  module Build
    class Addons
      class ArtifactsV2 < Base
        SUPER_USER_SAFE = true

        attr_reader :artifacts_server_addr, :rsa_private

        def initialize(*)
          super

          @artifacts_server_addr = ENV['ARTIFACTS_SERVER_ADDR']
          begin
            @rsa_private = OpenSSL::PKey::RSA.new ENV['ARTIFACTS_JWT_PRIVATE_KEY']
          rescue
            @rsa_private = nil
            sh.echo 'addon artifacts_v2 is not configured yet.', ansi: :yellow
          end
        end

        def after_after_script
          if !rsa_private.nil? && config.has_key?(:paths)
            sh.newline
            sh.echo 'Uploading artifacts', ansi: :yellow

            sh.fold 'artifacts_v2.upload' do
              upload
            end
            sh.newline
          end
        end

        private

          def upload
            jwt_token = token

            config[:paths].each do |path|
              sh.echo "Uploading #{path}"
              puts data.inspect
              sh.cmd "curl -s -X POST -H \"Authorization: Bearer #{jwt_token}\" -F file=@#{path} #{artifacts_server_addr}/jobs/#{data.job[:id]}".untaint
            end
          end

          def token
            pull_request = self.data.pull_request ? self.data.pull_request : ''
            now = Time.now.to_i()
            payload = {
              'iss' => "Travis CI, GmbH",
              'slug' => self.data.slug,
              'pull-request' => pull_request,
              'exp' => now + 7200,
              'iat' => now
            }
            begin
              return JWT.encode payload, rsa_private, 'RS256'
            rescue Exception
              sh.echo 'There was an error while encoding a JWT token for addon artifacts_v2.', ansi: :yellow
            end
          end
      end
    end
  end
end

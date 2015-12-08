module Maia
  class Messenger < ActiveJob::Base

    def perform(tokens, payload)
      logger.info "Pushing to #{tokens.size} token(s)..."
      logger.info "Payload: #{payload}"

      notification = GCM::Notification.new(payload)
      responses = gcm.deliver(notification, tokens)

      responses.each do |response|
        if error = response.error
          raise Maia::Error, error
        else
          handle_failed_tokens response.results.failed
          update_devices_to_use_canonical_ids response.results.with_canonical_ids
        end
      end
    end

    private
      def gcm
        @_service ||= GCM::Service.new connection: connection
      end

      def connection
        nil # use the default
      end

      def handle_failed_tokens(results)
        results.each do |result|
          device = Maia::Device.find_by(token: result.token)
          logger.info "#{result.token} failed: #{result.error}"
          if device && invalid_token_error?(result.error)
            logger.info "Invalid token #{device.token} - destroying device #{device.id}."
            device.destroy
          end
        end
      end

      def update_devices_to_use_canonical_ids(results)
        results.each do |result|
          device = Maia::Device.find_by token: result.token
          next if device.nil?
          if user_already_has_token_registered?(device.pushable, result.canonical_id)
            device.destroy
          else
            device.update token: result.canonical_id
          end
        end
      end

      def invalid_token_error?(error)
        error =~ /InvalidRegistration|NotRegistered/
      end

      def user_already_has_token_registered?(user, token)
        user.devices.exists? token: token
      end
  end
end

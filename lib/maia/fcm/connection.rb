module Maia
  module FCM
    class Connection
      URL = 'https://fcm.googleapis.com/fcm/send'.freeze

      def initialize(key)
        @key = key
      end

      def write(payload = {})
        request = Net::HTTP::Post.new uri, headers
        request.body = payload.to_json
        http.request request
      end

      def uri
        URI(URL)
      end

      def headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "key=#{@key}"
        }
      end

      def http
        @_http ||= Net::HTTP.new(uri.host, uri.port).tap do |h|
          h.use_ssl = true
        end
      end
    end
  end
end

# frozen_string_literal: true

require "bunny"
require "json"

module Orders
  module Publishers
    class PublishFailed < StandardError; end

    class Rabbitmq
      def initialize(
        rabbitmq_url: ENV.fetch("RABBITMQ_URL"),
        exchange_name: ENV.fetch("ORDERS_EXCHANGE", "orders"),
        routing_key: ENV.fetch("ORDER_CREATED_ROUTING_KEY", "order.created")
      )
        @rabbitmq_url = rabbitmq_url
        @exchange_name = exchange_name
        @routing_key = routing_key
      end

      def publish(payload)
        connection = Bunny.new(@rabbitmq_url)
        connection.start

        channel = connection.create_channel
        exchange = channel.direct(@exchange_name, durable: true)

        exchange.publish(payload.to_json, routing_key: @routing_key, persistent: true)
      rescue Bunny::Exception, JSON::GeneratorError => e
        raise PublishFailed, "Failed to publish event: #{e.class}"
      ensure
        connection&.close
      end
    end
  end
end

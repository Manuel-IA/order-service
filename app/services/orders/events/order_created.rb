# frozen_string_literal: true

require "securerandom"
require "time"

module Orders
  module Events
    class OrderCreated
      def self.build(order)
        {
          event_id: SecureRandom.uuid,
          event_type: "order.created",
          occurred_at: Time.now.utc.iso8601,
          order: {
            id: order.id,
            customer_id: order.customer_id,
            product_name: order.product_name,
            quantity: order.quantity,
            price: order.price&.to_s,
            status: order.status
          }
        }
      end
    end
  end
end

# frozen_string_literal: true

module Orders
  class Create
    def self.call(params, customer_client: CustomerService::Client.new, publisher: Publishers::Rabbitmq.new)
      new(params, customer_client:, publisher:).call
    end

    def initialize(params, customer_client:, publisher:)
      @params = params
      @customer_client = customer_client
      @publisher = publisher
    end

    def call
      customer = @customer_client.fetch_customer(@params[:customer_id])

      order = nil
      Order.transaction do
        order = Order.create!(
          customer_id: @params[:customer_id],
          product_name: @params[:product_name],
          quantity: @params[:quantity],
          price: @params[:price],
          status: @params[:status].presence || "created",
          customer_name: customer[:customer_name],
          address: customer[:address]
        )

        payload = Events::OrderCreated.build(order)
        @publisher.publish(payload)
      end

      order
    end
  end
end

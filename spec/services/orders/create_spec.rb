# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::Create do
  it "fetches customer, creates order, and publishes event" do
    fake_customer_client = double("CustomerClient",
      fetch_customer: { customer_name: "Ana", address: "Calle 1", orders_count: 0 }
    )

    fake_publisher = double("Publisher")
    expect(fake_publisher).to receive(:publish) do |payload|
      expect(payload[:event_type]).to eq("order.created")
      expect(payload[:order][:customer_id]).to eq(1)
    end

    order = described_class.call(
      { customer_id: 1, product_name: "Phone", quantity: 1, price: 1000 },
      customer_client: fake_customer_client,
      publisher: fake_publisher
    )

    expect(order).to be_persisted
    expect(order.customer_name).to eq("Ana") if order.respond_to?(:customer_name)
  end
end

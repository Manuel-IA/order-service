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

  it "does not create order nor publish when customer service is unavailable" do
    customer_client = double("CustomerClient")
    publisher = double("Publisher")

    allow(customer_client).to receive(:fetch_customer).and_raise(CustomerService::Unavailable)

    expect(publisher).not_to receive(:publish)

    expect {
      described_class.call(
        { customer_id: 1, product_name: "Phone", quantity: 1, price: 1000, status: "paid" },
        customer_client: customer_client,
        publisher: publisher
      )
    }.to raise_error(CustomerService::Unavailable)

    expect(Order.count).to eq(0)
  end

  it "publishes order.created event with expected payload shape" do
    fake_customer_client = double("CustomerClient",
      fetch_customer: { customer_name: "Ana", address: "Calle 1", orders_count: 0 }
    )

    published = nil
    fake_publisher = double("Publisher")
    allow(fake_publisher).to receive(:publish) { |payload| published = payload }

    order = described_class.call(
      { customer_id: 1, product_name: "Keyboard", quantity: 2, price: 500, status: "paid" },
      customer_client: fake_customer_client,
      publisher: fake_publisher
    )

    expect(order).to be_persisted
    expect(published).to be_a(Hash)
    expect(published[:event_type]).to eq("order.created")
    expect(published[:event_id]).to be_present
    expect(published[:order]).to include(
      id: order.id,
      customer_id: 1,
      product_name: "Keyboard",
      quantity: 2,
      status: "paid"
    )
    expect(published[:occurred_at]).to be_present
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders API", type: :request do
  describe "GET /api/v1/orders" do
    it "returns orders filtered by customer_id" do
      create(:order, customer_id: 1)
      create(:order, customer_id: 2)

      get "/api/v1/orders", params: { customer_id: 1 }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(1)
      expect(body.first["customer_id"]).to eq(1)
    end
  end

  describe "POST /api/v1/orders" do
    it "creates an order" do
      allow(Orders::Create).to receive(:call).and_wrap_original do |m, params|
        Order.create!(
          customer_id: params[:customer_id],
          product_name: params[:product_name],
          quantity: params[:quantity],
          price: params[:price],
          status: params[:status] || "created"
        )
      end

      post "/api/v1/orders", params: {
        order: {
          customer_id: 1,
          product_name: "Mouse",
          quantity: 1,
          price: 50000,
          status: "created"
        }
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["customer_id"]).to eq(1)
      expect(body["product_name"]).to eq("Mouse")
    end
  end
end

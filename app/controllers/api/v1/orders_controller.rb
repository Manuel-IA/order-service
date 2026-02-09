# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      def index
        customer_id = params[:customer_id]
        return render json: { error: "customer_id is required" }, status: :bad_request if customer_id.blank?

        orders = Order.where(customer_id: customer_id).order(created_at: :desc)
        render json: orders.map { |order| serialize(order) }
      end

      def create
        attrs = order_params.to_h

        # Check if a valid status is provided before attempting to create the order
        if attrs["status"].present? && !Order.statuses.key?(attrs["status"])
          return render json: {
            error: "invalid_status",
            allowed_statuses: Order.statuses.keys
          }, status: :unprocessable_entity
        end

        order = Orders::Create.call(attrs)
        render json: serialize(order), status: :created
      end

      private

      def order_params
        params.require(:order).permit(:customer_id, :product_name, :quantity, :price, :status)
      end

      def serialize(order)
        {
          id: order.id,
          customer_id: order.customer_id,
          product_name: order.product_name,
          quantity: order.quantity,
          price: order.price&.to_s,
          status: order.status,
          customer_name: order.try(:customer_name),
          address: order.try(:address),
          created_at: order.created_at
        }
      end
    end
  end
end

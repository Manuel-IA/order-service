# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module CustomerService
  class Client
    DEFAULT_TIMEOUT = 2

    def initialize(base_url: ENV.fetch("CUSTOMER_SERVICE_URL", nil))
      raise Unavailable, "CUSTOMER_SERVICE_URL is not configured" if base_url.blank?

      @conn = Faraday.new(url: base_url) do |f|
        f.request :retry,
          max: 1, # One retry (2 attempts total): reduces latency impact but handles transient failures
          interval: 0.1,
          backoff_factor: 2,
          interval_randomness: 0.2,
          methods: %i[get],
          retry_statuses: [429, 502, 503, 504],
          exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]

        f.options.timeout = DEFAULT_TIMEOUT
        f.options.open_timeout = DEFAULT_TIMEOUT
        f.adapter Faraday.default_adapter
      end
    end

    # Return a hash with :customer_name, :address and :orders_count
    def fetch_customer(customer_id)
      res = @conn.get("/api/v1/customers/#{customer_id}")

      case res.status
      when 200
        parse_customer!(res.body)
      when 404
        raise NotFound, "Customer #{customer_id} not found"
      else
        raise Unavailable, "Customer service error (status=#{res.status})"
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise Unavailable, "Customer service unavailable: #{e.class}"
    end

    private

    def parse_customer!(body)
      json = JSON.parse(body) rescue nil
      raise BadResponse, "Invalid JSON from customer service" if json.nil?

      # Support {customer:{...}} or {...}
      data = json["customer"] || json

      {
        customer_name: data["customer_name"] || data["name"],
        address: data["address"],
        orders_count: data["orders_count"]
      }
    end
  end
end

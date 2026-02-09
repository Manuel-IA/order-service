FactoryBot.define do
  factory :order do
    customer_id { 1 }
    product_name { "Mouse" }
    quantity { 1 }
    price { "500.20" }
    status { "paid" }
    customer_name { "Ana" }
    address { "Calle 1" }
  end
end

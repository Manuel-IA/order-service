FactoryBot.define do
  factory :order do
    customer_id { 1 }
    product_name { "MyString" }
    quantity { 1 }
    price { "9.99" }
    status { "MyString" }
    customer_name { "MyString" }
    address { "MyString" }
  end
end

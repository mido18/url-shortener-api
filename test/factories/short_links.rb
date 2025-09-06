FactoryBot.define do
  factory :short_link do
    original_url { "MyText" }
    slug { "MyString" }
    visits { 1 }
  end
end

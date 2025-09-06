require "test_helper"

class DecodeControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get decode_create_url
    assert_response :success
  end
end

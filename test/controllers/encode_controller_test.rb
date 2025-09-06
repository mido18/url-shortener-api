require "test_helper"

class EncodeControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get encode_create_url
    assert_response :success
  end
end

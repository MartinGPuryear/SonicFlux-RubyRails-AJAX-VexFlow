require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  test "should get lobby" do
    get :lobby
    assert_response :success
  end

  test "should get play" do
    get :play
    assert_response :success
  end

  test "should get leaders" do
    get :leaders
    assert_response :success
  end

  test "should get progress" do
    get :progress
    assert_response :success
  end

  test "should get about" do
    get :about
    assert_response :success
  end

  test "should get intro" do
    get :intro
    assert_response :success
  end

end

require "test_helper"

class SubstackSourcesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "sources-ctrl@cf.test")
    Creator.create!(user: @user, name: "Test", topic: "AI", goal: "grow", audience: "devs")
    sign_in @user
  end

  # --- index ---------------------------------------------------------------

  test "index lists only the current user's sources" do
    @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed", name: "Lenny")
    other = create_user!(email: "other-src@cf.test")
    Creator.create!(user: other, name: "X", topic: "X", goal: "X", audience: "X")
    other.substack_sources.create!(feed_url: "another.substack.com/feed")

    get substack_sources_path
    assert_response :success
    assert_select "td", text: /Lenny/
    assert_select "td", text: /another/, count: 0
  end

  # --- new -----------------------------------------------------------------

  test "new renders the add-source form" do
    get new_substack_source_path
    assert_response :success
  end

  # --- create --------------------------------------------------------------

  test "create saves a source scoped to current user and enqueues a fetch job" do
    assert_enqueued_with(job: FetchSubstackSourceJob) do
      assert_difference "SubstackSource.count" do
        post substack_sources_path, params: {
          substack_source: { feed_url: "lennysnewsletter.substack.com" }
        }
      end
    end
    assert_equal @user, SubstackSource.last.user
    assert_redirected_to substack_posts_path
  end

  test "create re-renders new on invalid input" do
    post substack_sources_path, params: { substack_source: { feed_url: "" } }
    assert_response :unprocessable_entity
  end

  # --- destroy -------------------------------------------------------------

  test "destroy removes the source owned by current user" do
    source = @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed")
    assert_difference "SubstackSource.count", -1 do
      delete substack_source_path(source)
    end
    assert_redirected_to substack_sources_path
  end

  test "destroy cannot remove another user's source" do
    other = create_user!(email: "other-del@cf.test")
    Creator.create!(user: other, name: "X", topic: "X", goal: "X", audience: "X")
    other_source = other.substack_sources.create!(feed_url: "another.substack.com/feed")

    assert_no_difference "SubstackSource.count" do
      delete substack_source_path(other_source)
    end
    assert_response :not_found
  end

  # --- auth ----------------------------------------------------------------

  test "redirects to sign-in when not authenticated" do
    sign_out @user
    get substack_sources_path
    assert_redirected_to new_user_session_path
  end
end

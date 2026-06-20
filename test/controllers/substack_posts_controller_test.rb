require "test_helper"

class SubstackPostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user   = create_user!(email: "posts-ctrl@cf.test")
    Creator.create!(user: @user, name: "Test", topic: "AI", goal: "grow", audience: "devs")
    @source = @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed", name: "Lenny")
    sign_in @user
  end

  # --- index ---------------------------------------------------------------

  test "index renders the feed" do
    @source.substack_posts.create!(guid: "abc", title: "Hot take", published_at: 1.day.ago)
    get substack_posts_path
    assert_response :success
    assert_select "td", text: /Hot take/
  end

  test "index shows empty-state when no sources exist" do
    @source.destroy
    get substack_posts_path
    assert_response :success
    assert_select "p", text: /no sources yet/i
  end

  test "index links each post to a seeded generate_idea chat" do
    post = @source.substack_posts.create!(guid: "seed", title: "Hot take", published_at: 1.day.ago)
    get substack_posts_path
    assert_select "a[href=?]",
                  new_chat_path(purpose: "generate_idea", substack_post_id: post.id),
                  text: /use as inspiration/i
  end

  test "index subscribes to the user's live feed stream and renders the feed container" do
    get substack_posts_path
    # turbo_stream_from renders this custom element; its presence means the
    # page will receive FetchSubstackSourceJob's broadcasts live.
    assert_select "turbo-cable-stream-source", count: 1
    assert_select "div#substack_feed", count: 1
  end

  test "index shows only current user's posts" do
    other = create_user!(email: "other-posts@cf.test")
    Creator.create!(user: other, name: "X", topic: "X", goal: "X", audience: "X")
    other_src = other.substack_sources.create!(feed_url: "another.substack.com/feed")
    other_src.substack_posts.create!(guid: "xyz", title: "Other user's post", published_at: Time.current)

    @source.substack_posts.create!(guid: "mine", title: "My post", published_at: Time.current)

    get substack_posts_path
    assert_select "td a", text: /My post/
    assert_select "td", text: /Other user's post/, count: 0
  end

  # --- refresh -------------------------------------------------------------

  test "refresh enqueues a fetch job for each stale source and redirects" do
    # source has never been fetched → stale? is true
    assert_enqueued_with(job: FetchSubstackSourceJob, args: [ @source.id ]) do
      post refresh_substack_posts_path
    end
    assert_redirected_to substack_posts_path
    assert_match(/refreshing 1 source/i, flash[:notice])
  end

  test "refresh skips a freshly-fetched source and says the feed is up to date" do
    @source.update_columns(fetched_at: 5.minutes.ago)
    assert_no_enqueued_jobs(only: FetchSubstackSourceJob) do
      post refresh_substack_posts_path
    end
    assert_redirected_to substack_posts_path
    assert_match(/already up to date/i, flash[:notice])
  end

  test "refresh button uses turbo_submits_with for its loading state" do
    # Disabling the button in a click handler would cancel the submission
    # before it starts (a disabled button can't submit a form), so the
    # loading state must come from Turbo's data-turbo-submits-with instead.
    get substack_posts_path
    assert_select "form[action=?]", refresh_substack_posts_path do
      assert_select "input[type=submit][data-turbo-submits-with='refreshing...']"
    end
  end

  # --- auth ----------------------------------------------------------------

  test "redirects to sign-in when not authenticated" do
    sign_out @user
    get substack_posts_path
    assert_redirected_to new_user_session_path
  end
end

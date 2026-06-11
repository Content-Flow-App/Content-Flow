require "test_helper"
require "turbo/broadcastable/test_helper"

class FetchSubstackSourceJobTest < ActiveJob::TestCase
  # capture_turbo_stream_broadcasts records the <turbo-stream> elements the job
  # pushes over Action Cable, so we can assert on what a user sitting on the
  # feed page would actually see arrive.
  include Turbo::Broadcastable::TestHelper

  setup do
    @user   = User.create!(email: "fetch-job@cf.test", password: "password123")
    @source = @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed", name: "Lenny")
    @stream = "substack_feed_#{@user.id}"
  end

  # This repo's Minitest (6.0.6) ships no stub helper, so we swap the service's
  # class method out and restore it afterwards. The job must not hit the
  # network in tests.
  def with_service_stub(replacement)
    original = SubstackFetchService.method(:call)
    SubstackFetchService.singleton_class.define_method(:call, &replacement)
    yield
  ensure
    SubstackFetchService.singleton_class.define_method(:call, original)
  end

  test "broadcasts the re-rendered feed to the source's user after a fetch" do
    fetched = proc do |source|
      source.substack_posts.create!(guid: "g1", title: "Fresh hot take", published_at: 1.hour.ago)
      source.update_columns(fetched_at: Time.current, fetch_error: nil)
      true
    end

    elements = nil
    with_service_stub(fetched) do
      elements = capture_turbo_stream_broadcasts(@stream) do
        FetchSubstackSourceJob.perform_now(@source.id)
      end
    end

    assert_equal 1, elements.size
    stream = elements.first
    assert_equal "replace",       stream["action"]
    assert_equal "substack_feed", stream["target"]
    assert_includes stream.to_html, "Fresh hot take"
  end

  test "broadcasts after a failed fetch so the feed shows the error" do
    failed = proc do |source|
      source.update_columns(fetch_error: "This doesn't look like a valid RSS feed.")
      false
    end

    elements = nil
    with_service_stub(failed) do
      elements = capture_turbo_stream_broadcasts(@stream) do
        FetchSubstackSourceJob.perform_now(@source.id)
      end
    end

    assert_equal 1, elements.size
    assert_includes elements.first.to_html, "valid RSS feed"
  end

  test "does nothing when the source no longer exists" do
    gone_id = @source.id
    @source.destroy

    with_service_stub(proc { |_| flunk "service must not be called" }) do
      elements = capture_turbo_stream_broadcasts(@stream) do
        FetchSubstackSourceJob.perform_now(gone_id)
      end
      assert_empty elements
    end
  end
end

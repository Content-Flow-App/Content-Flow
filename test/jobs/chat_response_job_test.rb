require "test_helper"
require "turbo/broadcastable/test_helper"

class ChatResponseJobTest < ActiveJob::TestCase
  # Turbo's test helper gives us capture_turbo_stream_broadcasts, which records
  # the <turbo-stream> elements the job pushes over Action Cable so we can
  # assert on what the user would actually see in the chat.
  include Turbo::Broadcastable::TestHelper

  setup do
    @chat = Chat.create!
    @stream = "chat_#{@chat.id}"
  end

  # This repo's Minitest (6.0.6) ships no Object#stub or Minitest::Mock, so we
  # roll our own swap-and-restore. This variant replaces an *instance* method on
  # a class for the duration of the block — needed because the job re-fetches
  # the chat with Chat.find, so we can't stub a single object.
  def with_instance_stub(klass, meth, replacement)
    original = klass.instance_method(meth)
    klass.define_method(meth, &replacement)
    yield
  ensure
    klass.define_method(meth, original)
  end

  test "request_timeout is capped at 30s so a hung request fails fast" do
    # The core of the timeout fix: without this cap RubyLLM defaults to 300s
    # and, with 3 retries, a hung request could block the job for ~20 minutes.
    assert_equal 30, RubyLLM.config.request_timeout
  end

  test "a Faraday::TimeoutError is rescued and broadcasts a timeout message" do
    elements = nil
    with_instance_stub(Chat, :complete, proc { raise Faraday::TimeoutError }) do
      elements = capture_turbo_stream_broadcasts(@stream) do
        # If the rescue were missing, perform_now would re-raise here and fail
        # the test — Faraday::TimeoutError is NOT a RubyLLM::Error subclass.
        assert_nothing_raised { ChatResponseJob.perform_now(@chat.id) }
      end
    end

    html = elements.map(&:to_html).join
    assert_includes html, "request timed out"
    assert_includes html, "did not respond in time"
  end

  test "a RubyLLM::RateLimitError is rescued and broadcasts a rate-limit message" do
    elements = nil
    with_instance_stub(Chat, :complete, proc { raise RubyLLM::RateLimitError.new(nil) }) do
      elements = capture_turbo_stream_broadcasts(@stream) do
        assert_nothing_raised { ChatResponseJob.perform_now(@chat.id) }
      end
    end

    html = elements.map(&:to_html).join
    assert_includes html, "rate limit reached"
  end

  test "the generation-action loading state is always cleared on failure" do
    elements = nil
    with_instance_stub(Chat, :complete, proc { raise Faraday::TimeoutError }) do
      elements = capture_turbo_stream_broadcasts(@stream) do
        ChatResponseJob.perform_now(@chat.id)
      end
    end

    # The ensure block re-broadcasts generation-action regardless of outcome, so
    # the user is never left with a permanent spinner.
    targets = elements.map { |el| el["target"] }
    assert_includes targets, "generation-action"
  end
end

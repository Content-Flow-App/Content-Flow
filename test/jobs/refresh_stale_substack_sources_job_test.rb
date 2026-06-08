require "test_helper"

class RefreshStaleSubstackSourcesJobTest < ActiveJob::TestCase
  def setup
    @user = User.create!(email: "refresh-job@cf.test", password: "password123")
  end

  test "enqueues a fetch job for a never-fetched source" do
    source = @user.substack_sources.create!(feed_url: "https://stale.substack.com/feed")

    assert_enqueued_with(job: FetchSubstackSourceJob, args: [ source.id ]) do
      RefreshStaleSubstackSourcesJob.perform_now
    end
  end

  test "enqueues a fetch job for a source past the cooldown" do
    source = @user.substack_sources.create!(feed_url: "https://overdue.substack.com/feed")
    source.update_columns(fetched_at: 2.hours.ago)

    assert_enqueued_with(job: FetchSubstackSourceJob, args: [ source.id ]) do
      RefreshStaleSubstackSourcesJob.perform_now
    end
  end

  test "skips a source that was refreshed within the cooldown" do
    source = @user.substack_sources.create!(feed_url: "https://fresh.substack.com/feed")
    source.update_columns(fetched_at: 5.minutes.ago)

    assert_no_enqueued_jobs(only: FetchSubstackSourceJob) do
      RefreshStaleSubstackSourcesJob.perform_now
    end
  end
end

require "test_helper"

# Guards the production deployment setup added for issue #164.
#
# These tests don't boot the production environment; they verify the two
# config files whose breakage is silent in development and only shows up
# after a deploy:
#
#   * Procfile — without the `worker` process type, jobs get enqueued in
#     production but nothing ever runs them (the original #164 bug).
#   * config/storage.yml — the `amazon` service is built from env vars via
#     ERB, where an indentation slip produces invalid YAML or a key that
#     quietly disappears.
class ProductionSetupTest < ActiveSupport::TestCase
  test "Procfile defines web, worker, and release process types" do
    procfile = parse_procfile

    assert_equal "bin/rails server", procfile["web"]
    assert_equal "bin/jobs", procfile["worker"]
    assert_equal "bin/rails db:prepare", procfile["release"]
  end

  test "bin/jobs is executable" do
    assert File.executable?(Rails.root.join("bin/jobs")),
      "bin/jobs must be executable for the Procfile worker process to boot"
  end

  test "amazon storage service reads its settings from env vars" do
    amazon = parse_storage_yml(
      "S3_ACCESS_KEY_ID"     => "key",
      "S3_SECRET_ACCESS_KEY" => "secret",
      "S3_REGION"            => "us-east-1",
      "S3_BUCKET"            => "avatars"
    ).fetch("amazon")

    assert_equal "S3",        amazon["service"]
    assert_equal "key",       amazon["access_key_id"]
    assert_equal "secret",    amazon["secret_access_key"]
    assert_equal "us-east-1", amazon["region"]
    assert_equal "avatars",   amazon["bucket"]
  end

  test "amazon storage service defaults the region when unset" do
    amazon = parse_storage_yml("S3_BUCKET" => "avatars").fetch("amazon")

    assert_equal "eu-west-1", amazon["region"]
  end

  test "amazon storage service omits the endpoint key unless S3_ENDPOINT is set" do
    amazon = parse_storage_yml("S3_BUCKET" => "avatars").fetch("amazon")

    assert_not_includes amazon.keys, "endpoint",
      "a blank endpoint would break the AWS client; the key must be absent"
  end

  test "amazon storage service includes the endpoint when S3_ENDPOINT is set" do
    amazon = parse_storage_yml(
      "S3_BUCKET"   => "avatars",
      "S3_ENDPOINT" => "https://acc.r2.cloudflarestorage.com"
    ).fetch("amazon")

    assert_equal "https://acc.r2.cloudflarestorage.com", amazon["endpoint"]
  end

  private

  S3_ENV_KEYS = %w[
    S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_REGION S3_BUCKET S3_ENDPOINT
  ].freeze

  # Renders config/storage.yml with only the given S3_* env vars set,
  # restoring the original environment afterwards (swap-and-restore — see
  # the project note on Minitest 6 lacking `stub`).
  def parse_storage_yml(env)
    original = S3_ENV_KEYS.index_with { |key| ENV[key] }
    S3_ENV_KEYS.each { |key| ENV[key] = env[key] }

    YAML.load(
      ERB.new(Rails.root.join("config/storage.yml").read).result,
      aliases: true
    )
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  def parse_procfile
    Rails.root.join("Procfile").read.scan(/^(\w+):\s*(.+?)\s*$/).to_h
  end
end

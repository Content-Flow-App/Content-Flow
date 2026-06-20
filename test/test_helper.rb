ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    TEST_PASSWORD = "Str0ng!Password1"

    def create_user!(email:, password: TEST_PASSWORD, confirmed: true)
      user = User.new(email: email, password: password, password_confirmation: password)
      user.skip_confirmation! if confirmed
      user.save!
      user
    end
  end
end

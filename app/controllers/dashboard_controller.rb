class DashboardController < ApplicationController
  # No `skip_before_action :authenticate_user!` here, so the inherited
  # `before_action :authenticate_user!` from ApplicationController applies:
  # unauthenticated visitors are bounced to the Devise sign-in page. This is
  # the logged-in counterpart to the public `pages#home` landing.

  def show
    # `includes(:scripts)` eager-loads each idea's scripts in one extra SQL
    # query rather than N queries (one per idea) — the N+1 equivalent would be:
    #
    #   current_user.ideas.each { |i| i.scripts }  # hits DB once per idea
    #
    # With includes Rails runs exactly two queries total:
    #   SELECT * FROM ideas WHERE user_id = ?
    #   SELECT * FROM scripts WHERE idea_id IN (...)
    @ideas = current_user.ideas.includes(:scripts).order(created_at: :desc)

    # Implicit template lookup (Rails "magic"):
    # No explicit `render` call → Rails finds the template by convention:
    #   controller "dashboard" + action "show" → app/views/dashboard/show.html.erb
  end
end

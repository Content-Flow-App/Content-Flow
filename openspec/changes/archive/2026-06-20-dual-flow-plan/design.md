## Changes required

### 1. Migrations

One migration per post type:

```ruby
# db/migrate/TIMESTAMP_add_idea_to_linkedin_posts.rb
add_reference :linkedin_posts, :idea, null: true, foreign_key: true
change_column_null :linkedin_posts, :script_id, true
# repeat for twitter_posts, instagram_posts
```

### 2. Models

Each post model gains a dual-parent pattern:

```ruby
# Before
belongs_to :script
has_one :user, through: :script

# After
belongs_to :script, optional: true
belongs_to :idea,   optional: true

validates :script_id, uniqueness: true, allow_nil: true
validate :requires_exactly_one_parent

def parent_idea = script&.idea || idea
def user        = parent_idea&.user

private

def requires_exactly_one_parent
  if script_id.present? == idea_id.present?
    errors.add(:base, "must belong to either a script or an idea, not both")
  end
end
```

The `Idea` model gets direct post associations:

```ruby
# app/models/idea.rb
has_many :linkedin_posts,  dependent: :destroy
has_many :twitter_posts,   dependent: :destroy
has_many :instagram_posts, dependent: :destroy
```

### 3. Routes

Add singular post resources nested directly under ideas alongside the existing
scripted nesting:

```ruby
resources :ideas do
  resource :linkedin_post,  only: [:show, :new, :create, :edit, :update, :destroy]
  resource :twitter_post,   only: [:show, :new, :create, :edit, :update, :destroy]
  resource :instagram_post, only: [:show, :new, :create, :edit, :update, :destroy]

  resources :scripts, shallow: true do
    # existing post routes stay exactly as they are
    resource :linkedin_post,  only: [:show, :new, :create, :edit, :update, :destroy]
    resource :twitter_post,   only: [:show, :new, :create, :edit, :update, :destroy]
    resource :instagram_post, only: [:show, :new, :create, :edit, :update, :destroy]
  end
end
```

New route helpers generated:

| Helper | Path | Use |
|---|---|---|
| `idea_linkedin_post_path(@idea)` | `/ideas/:idea_id/linkedin_post` | direct flow show/new |
| `script_linkedin_post_path(@script)` | `/scripts/:script_id/linkedin_post` | scripted flow (unchanged) |

### 4. Controllers

Each post controller gains a parent-resolution branch. The existing `@script`
path is untouched; the new `@idea` path is an `elsif`:

```ruby
# app/controllers/linkedin_posts_controller.rb
before_action :set_parent

def new
  # redirect to chat — pass chattable from whichever parent is present
  chattable = @script || @idea
  redirect_to new_chat_path(
    purpose:         :generate_linkedin_post,
    chattable_type:  chattable.class.name,
    chattable_id:    chattable.id
  )
end

def create
  @linkedin_post = @parent.build_linkedin_post(linkedin_post_params)
  # ... standard save/redirect
end

private

def set_parent
  if params[:script_id]
    @script = current_user_scripts.find(params[:script_id])
    @parent = @script
  elsif params[:idea_id]
    @idea = current_user.ideas.find(params[:idea_id])
    @parent = @idea
  end
end
```

`build_linkedin_post` is a `has_one` helper on Script. For the direct Idea path,
use `@idea.linkedin_posts.build` (has_many) with a uniqueness guard, or add
`has_one :linkedin_post` to Idea as well if the business rule is one-per-idea.

#### `UserScopedResource` concern

Add a helper for cross-path ownership:

```ruby
def current_user_linkedin_posts
  LinkedinPost
    .left_joins(script: :idea)
    .left_joins(:idea)
    .where("ideas.user_id = :uid OR linkedin_posts_ideas.user_id = :uid", uid: current_user.id)
end
```

### 5. LlmContext

Currently walks: `LinkedinPost → Script → Idea → User → Creator`.

Add a nil-safe skip when `script` is absent:

```ruby
# app/services/llm_context.rb
when LinkedinPost
  idea   = chattable.script&.idea || chattable.idea
  script = chattable.script
  layers = [creator_layer(idea.user), idea_layer(idea)]
  layers << script_layer(script) if script
  layers.join("\n\n")
```

This means a directly-generated post gets idea + creator context (but no script
context, since there is none).

### 6. `GenerationPlan`

Update the purpose table for the direct path:

| purpose | schema | chattable | owner resolution | persist | redirect |
|---|---|---|---|---|---|
| `generate_linkedin_post` (scripted) | `LinkedinPostSchema` | `Script` | `current_user_scripts.find` | `script.build_linkedin_post.save` | `script_linkedin_post_path` |
| `generate_linkedin_post` (direct) | `LinkedinPostSchema` | `Idea` | `current_user.ideas.find` | `idea.linkedin_posts.create` | `idea_linkedin_post_path` |

The `GenerationsController` already branches on `chattable_type`; add `Idea` as
a valid chattable for post generation.

### 7. Idea `show` view

Add a "posts" section alongside the existing "scripts" section:

```erb
<%# Direct posts — idea → post flow %>
<% if @idea.linkedin_posts.any? || @idea.twitter_posts.any? || @idea.instagram_posts.any? %>
  <section>
    <h2 class="cf-h2 font-normal">posts</h2>
    <%# list direct posts with link to each %>
  </section>
<% end %>

<%# Scripted posts — idea → script → post flow %>
<section>
  <h2 class="cf-h2 font-normal">scripts</h2>
  <%# existing scripts table %>
</section>

<%# CTAs for both paths %>
<%= link_to "write a script", new_idea_script_path(@idea) %>
<%= link_to "create a post directly", new_idea_linkedin_post_path(@idea) %>
```

### 8. Onboarding state

`User#next_onboarding_step` currently requires a script before `:post`:

```ruby
# Before
return :script if ideas.any? && ideas.flat_map(&:scripts).empty?
return :post   if scripts.any? && scripts.flat_map { ... }.empty?

# After
has_direct_post = linkedin_posts.joins(:idea).where(ideas: { user_id: id })
                                .or(linkedin_posts.joins(script: :idea).where(...))
return :post if ideas.any? && !has_direct_post.any? && scripts.flat_map { ... }.empty?
```

Simpler: consider onboarding `:post` step satisfied if the user has **any** post,
regardless of whether it came through a script or directly.


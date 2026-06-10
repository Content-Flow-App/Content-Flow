# GenerationPlan is the single source of truth for how each chat `purpose`
# turns a conversation into a saved record. It is the data side of
# GenerationsController#create: the controller stays one generic flow (resolve
# owner -> extract -> build -> save -> redirect) and the per-purpose differences
# all live here, mirroring the table in docs/USER_JOURNEYS.md:
#
#   purpose                | schema             | owner        | persist             | redirect
#   -----------------------|--------------------|--------------|---------------------|--------------------------
#   generate_idea          | IdeaSchema         | current_user | user.ideas.build    | idea_path
#   generate_script        | ScriptSchema       | parent Idea  | idea.scripts.build  | script_path
#   generate_linkedin_post | LinkedinPostSchema | parent Script| update or build     | script_linkedin_post_path
#
# The three behavioural slots (`owner_resolver`, `persist`, `redirect_target`)
# are procs *run in the controller's context via instance_exec*. That lets them
# call the controller's private, user-scoped relations (`current_user.ideas`,
# `current_user_scripts`) and path helpers directly — so authorization and
# routing stay in the controller's hands while the wiring lives in one table.
class GenerationPlan
  # Raised when a chat has no (or an unknown) generate purpose — e.g. a plain
  # free-form chat. The controller rescues this and sends the user back with a
  # flash rather than 500-ing.
  class UnknownPurpose < StandardError; end

  # `permitted_keys` is derived from the schema (its declared properties are the
  # allow-list), so a plan is fully defined by its purpose's four slots.
  Plan = Struct.new(:schema, :owner_resolver, :persist, :redirect_target, keyword_init: true) do
    def permitted_keys
      schema.properties.keys
    end
  end

  REGISTRY = {
    "generate_idea" => Plan.new(
      schema: IdeaSchema,
      # The chattable is the User itself; authorize by confining the lookup to
      # the current user — a foreign id raises RecordNotFound (-> 404).
      owner_resolver: ->(id) { User.where(id: current_user.id).find(id) },
      persist: ->(owner, attrs) { owner.ideas.build(attrs) },
      redirect_target: ->(record) { idea_path(record) }
    ),
    "generate_script" => Plan.new(
      schema: ScriptSchema,
      owner_resolver: ->(id) { current_user.ideas.find(id) },
      persist: ->(owner, attrs) { owner.scripts.build(attrs) },
      redirect_target: ->(record) { script_path(record) }
    ),
    "generate_linkedin_post" => Plan.new(
      schema: LinkedinPostSchema,
      # chattable_type is Script for the scripted path, Idea for the direct path.
      owner_resolver: ->(id) {
        @chat.chattable_type == "Idea" ? current_user.ideas.find(id) : current_user_scripts.find(id)
      },
      persist: ->(owner, attrs) { GenerationPlan.assign_linkedin_post(owner, attrs) },
      redirect_target: ->(record) {
        record.script ? script_linkedin_post_path(record.script) : idea_linkedin_post_path(record.idea)
      }
    ),
    "generate_twitter_post" => Plan.new(
      schema: TwitterPostSchema,
      owner_resolver: ->(id) {
        @chat.chattable_type == "Idea" ? current_user.ideas.find(id) : current_user_scripts.find(id)
      },
      persist: ->(owner, attrs) { GenerationPlan.assign_twitter_post(owner, attrs) },
      redirect_target: ->(record) {
        record.script ? script_twitter_post_path(record.script) : idea_twitter_post_path(record.idea)
      }
    ),
    "generate_instagram_post" => Plan.new(
      schema: InstagramPostSchema,
      owner_resolver: ->(id) {
        @chat.chattable_type == "Idea" ? current_user.ideas.find(id) : current_user_scripts.find(id)
      },
      persist: ->(owner, attrs) { GenerationPlan.assign_instagram_post(owner, attrs) },
      redirect_target: ->(record) {
        record.script ? script_instagram_post_path(record.script) : idea_instagram_post_path(record.idea)
      }
    )
  }.freeze

  def self.for(chat)
    REGISTRY.fetch(chat.purpose.to_s) do
      raise UnknownPurpose, "no generation plan for purpose #{chat.purpose.inspect}"
    end
  end

  # Singular association: a script has at most one linkedin_post. Update the
  # existing one if present, otherwise build a new one — either way the attrs are
  # assigned and the controller saves. Kept as a method (not an inline lambda) so
  # the multi-step build stays readable.
  def self.assign_linkedin_post(script, attrs)
    (script.linkedin_post || script.build_linkedin_post).tap do |post|
      post.assign_attributes(attrs)
    end
  end

  def self.assign_twitter_post(script, attrs)
    (script.twitter_post || script.build_twitter_post).tap do |post|
      post.assign_attributes(attrs)
    end
  end

  def self.assign_instagram_post(script, attrs)
    (script.instagram_post || script.build_instagram_post).tap do |post|
      post.assign_attributes(attrs)
    end
  end
end

module ChatsHelper
  # What a generate-purpose chat produces, in user-facing words. One map serves
  # every label built around it: "save as idea", "saving your idea...",
  # "view your idea". Returns nil for a free-form chat (no purpose), which the
  # partials use to hide the save UI entirely.
  GENERATION_NOUNS = {
    "generate_idea"           => "idea",
    "generate_script"         => "script",
    "generate_linkedin_post"  => "linkedin post",
    "generate_twitter_post"   => "twitter post",
    "generate_instagram_post" => "instagram post"
  }.freeze

  def generation_noun(chat)
    GENERATION_NOUNS[chat.purpose]
  end
end

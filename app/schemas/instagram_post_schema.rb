class InstagramPostSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the Instagram post (internal label)."
  string :hook, description: "The opening line of the caption. Must be complete and compelling under 125 characters — that is all Instagram shows before the 'more' tap."
  string :body, min_length: 50, max_length: 2200, description: "The full caption body following the hook. Short lines with blank lines between thoughts. Include 3-5 relevant hashtags and one clear call-to-action at the end."
end

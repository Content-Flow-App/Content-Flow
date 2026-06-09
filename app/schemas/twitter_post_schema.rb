class TwitterPostSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the Twitter post (internal label)."
  string :hook, description: "The opening tweet — concise, attention-grabbing, under 280 characters."
  string :body, description: "The full thread body following the hook, formatted as a Twitter thread."
end
#now?

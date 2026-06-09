class InstagramPostSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the Instagram post (internal label)."
  string :hook, description: "The opening line of the caption — the hook visible before 'more'."
  string :body, min_length: 50, max_length: 2200, description: "The full caption body following the hook, including hashtags. Your character limit is 125 before the 'more' appears, don't reach that unless the user ask for it "
end

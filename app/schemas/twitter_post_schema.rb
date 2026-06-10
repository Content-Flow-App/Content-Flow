class TwitterPostSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the Twitter post (internal label)."
  string :hook, description: "The opening tweet — must stand alone as a complete, compelling thought under 280 characters. Most readers only see this and decide whether to read the thread."
  string :body, description: "The thread body following the hook. Write as a sequence of tweet-sized beats (~240-280 characters each), separated by blank lines — one idea per beat. Use 0-2 hashtags woven into the text, not stacked at the end."
end

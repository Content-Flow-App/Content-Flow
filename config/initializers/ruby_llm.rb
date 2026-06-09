RubyLLM.configure do |config|
  # Project - Content Flow
  # For text generation → gpt-4o-mini. It's the natural default: low latency, low cost, and strong general quality. Step up to gpt-4o only for tasks where you notice the mini model struggling
  # (complex reasoning, long nuanced content). This is also exactly the model you had working before the gpt-5-nano change.
  # For embeddings → text-embedding-3-small. Best balance of quality, speed, and cost, and it pairs naturally with the OpenAI-style client you've already configured. Choose text-embedding-3-large
  # only if you measure a meaningful retrieval-quality gain and can accept 2× the vector size (which also affects your DB column / storage). Reach for the Cohere models only if multilingual
  # content is a real requirement.
  
  # Setup - Dummy
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)
  config.gemini_api_key    = ENV.fetch("GEMINI_API_KEY", nil)
  config.deepseek_api_key  = ENV.fetch("DEEPSEEK_API_KEY", nil)
  # Setup - Working
  config.openai_api_key = ENV.fetch("GITHUB_TOKEN", Rails.application.credentials.dig(:openai_api_key))
  config.openai_api_base = "https://models.inference.ai.azure.com"
  config.default_model = "gpt-4o-mini"
  # Cap each API attempt at 30 s. With the default 3 retries the worst-case
  # hang before an error fires is 4 × 30 s = 2 minutes instead of 20.
  config.request_timeout = 30
  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end

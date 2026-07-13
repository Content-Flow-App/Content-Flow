RubyLLM.configure do |config|
  # Project - Content Flow
  # For text generation → gpt-4o-mini. It's the natural default: low latency, low cost, and strong general quality. Step up to gpt-4o only for tasks where you notice the mini model struggling
  # (complex reasoning, long nuanced content). This is also exactly the model you had working before the gpt-5-nano change.
  # For embeddings → text-embedding-3-small. Best balance of quality, speed, and cost, and it pairs naturally with the OpenAI-style client you've already configured. Choose text-embedding-3-large
  # only if you measure a meaningful retrieval-quality gain and can accept 2× the vector size (which also affects your DB column / storage). Reach for the Cohere models only if multilingual
  # content is a real requirement.
  
  # Setup - Dummy
  config.gemini_api_key    = ENV.fetch("GEMINI_API_KEY", nil)
  config.deepseek_api_key  = ENV.fetch("DEEPSEEK_API_KEY", nil)

  # Setup - Working
  #
  # Anthropic Console API key — live as of 2026-07-13. `claude-sonnet-5` is
  # the exact model id Anthropic's own `v1/models` reports (confirmed directly
  # against the live API, not assumed from the bundled registry, which at the
  # time only knew as far as `claude-sonnet-4-6`). It's now the app default;
  # `Model.refresh!` pulled its real pricing/context-window/capabilities data
  # into the `models` table.
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)
  config.default_model = "claude-sonnet-5"

  # GitHub Models' original Azure-hosted endpoint (models.inference.ai.azure.com)
  # was retired on 2025-10-17 — any token, however valid, gets "Bad credentials"
  # there now. Its replacement, models.github.ai/inference, needs a token with
  # `models: read` permission (a fine-grained PAT, set under the token's
  # "Account permissions" → "Models"). Set GITHUB_TOKEN on Heroku to one of
  # those. No longer the default model, but stays fully configured and
  # selectable.
  config.openai_api_key = ENV.fetch("GITHUB_TOKEN", Rails.application.credentials.dig(:openai_api_key))
  config.openai_api_base = "https://models.github.ai/inference"
  # Cap each API attempt at 30 s. With the default 3 retries the worst-case
  # hang before an error fires is 4 × 30 s = 2 minutes instead of 20.
  config.request_timeout = 30
  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true

  # When the `models` table is empty (e.g. the test DB, which this app never
  # seeds), RubyLLM falls back to this file instead of resolving from the
  # database. Left unset, that fallback is the ruby_llm gem's own bundled
  # models.json — a moving target tied to whatever gem version happens to be
  # installed, not something this repo controls. Pointing it at a committed
  # project file means new models (like claude-sonnet-5, added here before
  # any published gem version knew about it) are available in every
  # environment, not just ones with a seeded `models` table. Regenerate with
  # `RubyLLM.models.save_to_json` after `Model.refresh!` picks up new models.
  config.model_registry_file = Rails.root.join("config", "ruby_llm_models.json").to_s
end

# The new GitHub Models endpoint requires the OpenAI-compatible `model` field
# in the request body to carry a publisher prefix ("openai/gpt-4o-mini"), but
# our Model registry (and every existing chat/message row) stores the bare id
# ("gpt-4o-mini") — deliberately, since a prefixed id would collide with
# OpenRouter's own "openai/<model>" naming in RubyLLM's registry and resolve
# to the wrong (unconfigured) provider. So the prefix is added right before
# the request is sent, only when we're actually talking to GitHub Models.
module RubyLLM
  module Providers
    class OpenAI
      module GithubModelsModelPrefix
        GITHUB_MODELS_HOST = "models.github.ai"

        def render_payload(...)
          payload = super
          if config.openai_api_base.to_s.include?(GITHUB_MODELS_HOST) && !payload[:model].to_s.include?("/")
            payload[:model] = "openai/#{payload[:model]}"
          end
          payload
        end
      end
    end
  end
end

RubyLLM::Providers::OpenAI.prepend(RubyLLM::Providers::OpenAI::GithubModelsModelPrefix)

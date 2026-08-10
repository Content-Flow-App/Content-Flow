RubyLLM.configure do |config|
  # Project - Content Flow
  #
  # GitHub Models (models.github.ai/inference) was dropped entirely — see
  # issue #45. It was our only route to OpenAI/Mistral/DeepSeek chat models,
  # and GitHub confirmed via live API error it's mid "scheduled retirement
  # brownout": `RubyLLM::Error: GitHub Models is temporarily unavailable as
  # part of a scheduled retirement brownout.` That's not a transient outage —
  # it's GitHub sunsetting the free inference endpoint — so any chat routed
  # through it (including chats created before Anthropic became the default)
  # was liable to break in production with no recovery. Anthropic direct is
  # now the only chat provider.
  #
  # For embeddings (unused today) → text-embedding-3-small would be the natural
  # choice if this app ever adds retrieval: best balance of quality, speed, and
  # cost. text-embedding-3-large only pays off if you measure a real
  # retrieval-quality gain and can accept 2× the vector size.

  # Setup - Dummy
  config.gemini_api_key    = ENV.fetch("GEMINI_API_KEY", nil)

  # Setup - Working
  #
  # Anthropic Console API key — live as of 2026-07-13. `claude-sonnet-5` is
  # the exact model id Anthropic's own `v1/models` reports (confirmed directly
  # against the live API, not assumed from the bundled registry, which at the
  # time only knew as far as `claude-sonnet-4-6`). It's now the app default;
  # `Model.refresh!` pulled its real pricing/context-window/capabilities data
  # into the `models` table. `claude-opus-5` and `claude-haiku-4-5-20251001`
  # (confirmed the same way, live against `v1/models`) round out the
  # selectable allowlist — see ApplicationController::CHAT_MODELS.
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)

  # DeepSeek Platform API key — account funded and key live as of issue #60.
  # Verified directly against DeepSeek's own `v1/models` plus a real chat
  # completion (issue #54): `deepseek-chat` is gone from the account; the
  # live catalog reports `deepseek-v4-flash` and `deepseek-v4-pro` instead,
  # completion-tested against `deepseek-v4-flash`. Which one lands in
  # ApplicationController::CHAT_MODELS is still open — see design.md Open
  # Questions in openspec/changes/add-open-source-models.
  config.deepseek_api_key = ENV.fetch("DEEPSEEK_API_KEY", nil)

  # OpenRouter API key — account funded and key live as of issue #60.
  # Verified directly against OpenRouter's own `/api/v1/models` plus real,
  # billed chat completions (issue #54): `moonshotai/kimi-k3` ($0.00054) and
  # `z-ai/glm-5.2` ($0.00007632), both reachable on the funded tier. One key
  # covers any publisher OpenRouter fronts — see ApplicationController's
  # `real_publisher` label correction for how those publishers are surfaced.
  config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)

  config.default_model = "claude-sonnet-5"

  # Cap each API attempt at 90 s. With the default 3 retries the worst-case
  # hang before an error fires is 4 × 90 s = 6 minutes instead of 20.
  #
  # Originally set to 30 s (issue #45) to bound retries at 2 minutes. That was
  # too tight for claude-opus-5: its extended-reasoning responses can take
  # longer than 30 s to produce a first byte, so every attempt — and every
  # retry — tripped the cap. Confirmed in production on chat 171 (issue #49):
  # the job "completed" in 121.27 s, ~4 × 30 s, with no assistant message
  # persisted — a real Faraday::TimeoutError on every attempt, not a hang.
  config.request_timeout = 90
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

class Model < ApplicationRecord
  acts_as_model

  # [provider-agnostic model_id, real publisher slug] for rows RubyLLM
  # registers under a multi-vendor aggregator provider. Kept keyed by the
  # OpenRouter model id itself (not by ApplicationController::CHAT_MODELS)
  # since this is a data-tagging concern, not an allowlist concern.
  REAL_PUBLISHERS = {
    "moonshotai/kimi-k3" => "moonshotai",
    "z-ai/glm-5.2" => "zhipu"
  }.freeze

  # RubyLLM::ActiveRecord::ModelMethods#refresh! (save_to_database) fetches
  # OpenRouter's live catalog and overwrites the `metadata` column wholesale
  # every time it runs — OpenRouter's own API has no publisher field, so our
  # real_publisher tag never survives a refresh unless it's reapplied after.
  def self.refresh!
    super
    tag_real_publishers!
  end

  def self.tag_real_publishers!
    REAL_PUBLISHERS.each do |model_id, real_publisher|
      model = find_by(provider: "openrouter", model_id: model_id)
      next unless model

      model.update!(metadata: model.metadata.merge("real_publisher" => real_publisher))
    end
  end
end

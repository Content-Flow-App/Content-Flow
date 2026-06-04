# LlmContext builds the layered system prompt that makes the chat assistant
# "creator-aware". It walks a chattable's ancestry chain and assembles a
# system instruction from the creator profile downward:
#
#   LinkedinPost -> Script -> Idea -> User -> Creator
#
# Each rung adds a layer of context:
#   - Idea          -> creator profile (name/topic/goal/audience)
#   - Script        -> creator profile + parent idea
#   - LinkedinPost  -> creator profile + parent idea + parent script
#                      (including the script's saved system_prompt)
#   - User          -> creator profile only (top-level chats)
#
# `Creator` itself owns no chats (see USER_JOURNEYS decision 4): brand context
# is always reached through `user.creator`. The returned string is handed to
# `chat.with_instructions(...)` at chat creation, which persists it as one
# `role: :system` message.
#
# Extensibility: every platform output (LinkedIn today; Instagram and YouTube
# planned) is a sibling leaf hanging off the same Script -> Idea -> User ->
# Creator spine. Those upstream layers are shared, so a new platform costs one
# `when` branch in #layers_for plus its own leaf method (e.g. an
# `instagram_post_layer`) — nothing else changes.
#
# Usage:
#   LlmContext.for(idea)  # => "You are ContentFlow's assistant...\n\n..."
#   LlmContext.for(nil)   # => nil (standalone chat, no context)
class LlmContext
  def self.for(chattable)
    new(chattable).build
  end

  def initialize(chattable)
    @chattable = chattable
  end

  # Returns the assembled system prompt, or nil when there is nothing to say
  # (unknown/absent chattable). A blank result tells the caller to skip
  # with_instructions entirely so the standalone /chats flow stays untouched.
  def build
    sections = layers_for(@chattable).compact
    return nil if sections.empty?

    ([ preamble ] + sections).join("\n\n")
  end

  private

  # Layers from the creator profile down to (and including) the node itself.
  # Each content node prepends its parent's layers, so the spine is assembled
  # once via recursion and reused by every platform leaf that hangs off a
  # Script. Adding Instagram/YouTube = one sibling branch + one leaf method.
  def layers_for(node)
    case node
    when User         then [ creator_layer(node.creator) ]
    when Idea         then layers_for(node.user) + [ idea_layer(node) ]
    when Script       then layers_for(node.idea) + [ script_layer(node) ]
    when LinkedinPost then layers_for(node.script) + [ linkedin_post_layer(node) ]
    # Future platform leaves (siblings of LinkedinPost):
    #   when InstagramPost then layers_for(node.script) + [ instagram_post_layer(node) ]
    #   when YoutubeVideo  then layers_for(node.script) + [ youtube_video_layer(node) ]
    else []
    end
  end

  def preamble
    "You are ContentFlow's content assistant. You help a creator turn ideas " \
    "into scripts and platform posts. Use the context below to give feedback " \
    "and suggestions that fit this creator's brand, topic, goal, and audience."
  end

  # --- Shared upstream layers (reused by every platform) ----------------

  def creator_layer(creator)
    return nil if creator.nil?

    <<~TEXT.strip
      CREATOR PROFILE
      Name: #{creator.name}
      Topic: #{creator.topic}
      Goal: #{creator.goal}
      Audience: #{creator.audience}
    TEXT
  end

  def idea_layer(idea)
    <<~TEXT.strip
      PARENT IDEA
      Title: #{idea.title}
      Topic: #{idea.topic}
      Description: #{idea.description}
    TEXT
  end

  def script_layer(script)
    text = <<~TEXT.strip
      PARENT SCRIPT
      Title: #{script.title}
      Style: #{script.style}
      Length: #{script.length}
      Description: #{script.description}
    TEXT

    if script.system_prompt.present?
      text + "\n\nSCRIPT INSTRUCTIONS\n#{script.system_prompt}"
    else
      text
    end
  end

  # --- Platform-specific leaf layers ------------------------------------

  def linkedin_post_layer(post)
    <<~TEXT.strip
      THIS LINKEDIN POST
      Title: #{post.title}
      Hook: #{post.hook}
      Body: #{post.body}
    TEXT
  end
end

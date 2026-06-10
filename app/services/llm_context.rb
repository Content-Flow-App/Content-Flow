# LlmContext builds the layered system prompt that makes the chat assistant
# "creator-aware". It walks a chattable's ancestry chain and assembles a
# system instruction from the creator profile downward:
#
#   LinkedinPost -> Script -> Idea -> User -> Creator
#
# Each rung's text is owned by the model itself, via a `#system_prompt` method
# (e.g. `Idea#system_prompt`, `Script#system_prompt`). LlmContext is just the
# assembler: it knows the spine (which parent each node hangs off) and stacks
# each node's #system_prompt from the creator profile down:
#   - Idea          -> creator profile (name/topic/goal/audience)
#   - Script        -> creator profile + parent idea
#   - LinkedinPost  -> creator profile + parent idea + parent script
#                      (including the script's creator-authored custom_instructions)
#   - User          -> creator profile only (top-level chats)
#
# `Creator` itself owns no chats (see USER_JOURNEYS decision 4): brand context
# is always reached through `user.creator` (User#system_prompt delegates to it).
# The returned string is handed to `chat.with_instructions(...)` at chat
# creation, which persists it as one `role: :system` message.
#
# Extensibility: every platform output (LinkedIn today; Instagram and YouTube
# planned) is a sibling leaf hanging off the same Script -> Idea -> User ->
# Creator spine. Those upstream layers are shared, so a new platform costs one
# `when` branch in #layers_for plus its own leaf method (e.g. an
# `instagram_post_layer`) — nothing else changes.
#
# Platform guidelines: during *generation* the chattable is still the parent
# Script (the post doesn't exist yet), so the leaf layers above never run —
# there is nothing yet to describe "this Instagram post" with. To still tell
# the model how an Instagram caption differs from a Twitter thread (length,
# hook visibility, hashtags, tone, ...) we key a final layer off the chat's
# `purpose` instead of the chattable's class. It is appended whenever the
# purpose names a platform, regardless of whether the chattable is the parent
# Script (generating) or the post itself (refining later).
#
# Usage:
#   LlmContext.for(idea)                                    # => "You are ContentFlow's assistant...\n\n..."
#   LlmContext.for(script, purpose: "generate_instagram_post") # => "...\n\nPLATFORM GUIDELINES — INSTAGRAM\n..."
#   LlmContext.for(nil)                                     # => nil (standalone chat, no context)
class LlmContext
  def self.for(chattable, purpose: nil)
    new(chattable, purpose).build
  end

  def initialize(chattable, purpose = nil)
    @chattable = chattable
    @purpose = purpose
  end

  # Returns the assembled system prompt, or nil when there is nothing to say
  # (unknown/absent chattable, no platform guidelines). A blank result tells
  # the caller to skip with_instructions entirely so the standalone /chats
  # flow stays untouched.
  def build
    system_prompts = layers_for(@chattable).compact
    system_prompts << platform_guidelines_layer if platform_guidelines_layer
    return nil if system_prompts.empty?

    ([ preamble ] + system_prompts).join("\n\n")
  end

  private

  # Layers from the creator profile down to (and including) the node itself.
  # Each content node prepends its parent's layers, so the spine is assembled
  # once via recursion; the per-node text lives on the model's #system_prompt.
  # Adding a new platform leaf = one branch here + a #system_prompt on the model.
  def layers_for(node)
    case node
    when User                                      then [ node.system_prompt ]
    when Idea                                      then layers_for(node.user)        + [ node.system_prompt ]
    when Script                                    then layers_for(node.idea)        + [ node.system_prompt ]
    when LinkedinPost, TwitterPost, InstagramPost
      # Direct-path posts have no script; walk via parent_idea instead.
      # Scripted path: creator → idea → script → post.
      # Direct path:   creator → idea → post (script layer skipped — nothing to say).
      if node.script
        layers_for(node.script) + [ node.system_prompt ]
      else
        layers_for(node.idea) + [ node.system_prompt ]
      end
    else []
    end
  end

  def preamble
    "You are ContentFlow's content assistant. You help a creator turn ideas " \
    "into scripts and platform posts. Use the context below to give feedback " \
    "and suggestions that fit this creator's brand, topic, goal, and audience."
  end

  # --- Platform guidelines (keyed off the chat's purpose) ---------------
  #
  # Generic advice ("write a good hook") doesn't tell the model that an
  # Instagram caption and a Twitter thread succeed under completely different
  # constraints. These layers spell out the platform-specific shape — length,
  # what's actually visible before a tap, hashtag/emoji conventions, tone — so
  # generated `title`/`hook`/`body` fields land in the right register for
  # where they'll actually be published.
  def platform_guidelines_layer
    case @purpose
    when "generate_instagram_post" then instagram_guidelines_layer
    when "generate_twitter_post"   then twitter_guidelines_layer
    when "generate_linkedin_post"  then linkedin_guidelines_layer
    end
  end

  def linkedin_guidelines_layer
    <<~TEXT.strip
      **PLATFORM GUIDELINES — LINKEDIN**
      - Only the first 2-3 lines (~200 characters) show in the feed before a
        "...see more" cut, so the hook has to earn the expand on its own —
        lead with the insight or tension, not a warm-up.
      - Write the body as short, scannable paragraphs with blank lines between
        them; dense blocks get scrolled past. One idea per paragraph.
      - Tone is professional but personal and first-person — credible and
        value-driven, sharing a lesson or point of view. Avoid hype, buzzwords,
        and engagement-bait phrasing.
      - Title is an internal label for this app only — it is never shown on
        LinkedIn, so it doesn't need to read like part of the post.
      - Close with a question or invitation to discuss, and 3-5 relevant
        hashtags on their own line at the end.
    TEXT
  end

  def instagram_guidelines_layer
    <<~TEXT.strip
      **SCRIPT GUIDELINES — INSTAGRAM REEL**
      - The script is spoken on camera — no emojis, no written-post language.
      - Max 130 words (~45 seconds). Cut everything that isn't essential.
      - Never open with "Hey", "Hello", or a self-introduction.
        Start with a strong hook that earns attention in the first 3 seconds.
      - Structure: hook → one main point → one call-to-action.

      **CAPTION GUIDELINES — INSTAGRAM**
      - Feeds truncate the caption after roughly 125 characters behind a
        "...more" tap, so the hook has to land as a scroll-stopper entirely on
        its own, with no setup from the rest of the caption.
      - Title is an internal label for this app only — it is never shown on
        Instagram, so it doesn't need to read like part of the caption.
      - Write the body in short lines with blank lines between thoughts; a
        wall of text reads as skippable on a phone, broken-up lines don't.
      - Tone is casual, visual-first, and personal — like talking to a
        follower, not announcing to an audience. Emojis are welcome where
        they add warmth, not stacked as decoration.
      - Close with 3-5 hashtags that are actually relevant to this post
        (not a generic stack of 30) and one clear call-to-action: save,
        share, comment, or follow.
    TEXT
  end

  def twitter_guidelines_layer
    <<~TEXT.strip
      **PLATFORM GUIDELINES — TWITTER**
      - The hook is the opening tweet and must work as a complete, standalone
        thought under 280 characters — most readers see only it in their feed
        and decide whether to expand the thread from it alone.
      - The body continues as a thread: write it as a sequence of tweet-sized
        beats (roughly 280 characters each), one idea per beat, in the order
        they should be read — not as a single continuous paragraph.
      - Tone is direct, punchy, and conversational — shorter sentences and a
        more opinionated edge than a LinkedIn post; say the thing plainly
        rather than building up to it.
      - Use hashtags sparingly, if at all (0-2, woven into a sentence) —
        stacking them at the end reads as spam on this platform.
    TEXT
  end
end

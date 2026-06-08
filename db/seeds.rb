# db/seeds.rb
#
# Seeds the content-flow chain: User → Creator → Idea → Script → LinkedinPost
#
# Run with: bin/rails db:seed
#
# This is idempotent in the sense that it wipes the relevant tables first, so
# you can run it repeatedly and always land in the same known-good state.

# ------------------------------------------------------------------------------
# 1. Destroy existing records
# ------------------------------------------------------------------------------
# Order matters. None of these tables use `on_delete: :cascade` (see
# db/schema.rb), so a parent row can't be deleted while child rows still point
# at it. We therefore delete from the bottom of the chain upward:
#
#   chats → linkedin_posts → scripts → ideas → creators → users
#
# Chat.destroy_all goes first and clears *all* chats — including standalone
# chats (chattable: nil) from the /chats flow, which no owner's
# `dependent: :destroy` would reach. It cascades to messages via acts_as_chat.
puts "Destroying existing records..."

Chat.destroy_all
LinkedinPost.destroy_all
Script.destroy_all
Idea.destroy_all
Creator.destroy_all
User.destroy_all

puts "  Done. Tables are clean.\n\n"

# ------------------------------------------------------------------------------
# 2. Sample data
# ------------------------------------------------------------------------------
# One entry per creator. Each creator owns a user account and 3 ideas; every
# idea carries exactly one script, and every script carries exactly one
# LinkedIn post. Looping over this structure keeps the creation logic in one
# place instead of repeating `create!` calls 50+ times.
SEED_DATA = [
  {
    email: "demo@contentflow.com",
    creator: {
      name: "Theodora",
      topic: "AI & Productivity",
      audience: "Startup founders and knowledge workers",
      goal: "Build thought leadership and grow my audience"
    },
    ideas: [
      {
        title: "How AI is changing the way we create content",
        topic: "AI & Content Creation",
        description: "An exploration of how AI tools are transforming content workflows for creators and marketers.",
        script: {
          title: "AI Content Creation Revolution",
          style: "educational",
          length: "short",
          description: "A short educational script covering the top AI tools transforming content creation.",
          system_prompt: "You are a knowledgeable tech content creator. Write engaging, concise scripts."
        },
        post: {
          title: "AI tools that actually work",
          hook: "I spent 30 days testing every AI content tool on the market. Here's what actually works:",
          body: <<~BODY
            Most AI tools promise to 10x your content output.

            Only 3 actually delivered.

            1. ChatGPT for first drafts — fast, but needs heavy editing
            2. Midjourney for visuals — the quality is genuinely impressive
            3. Descript for video editing — cuts production time in half

            The secret? AI works best as a thinking partner, not a replacement.

            What AI tools are you using for content creation?
          BODY
        }
      },
      {
        title: "The 2-hour workday myth",
        topic: "Productivity",
        description: "Why chasing a shorter workday misses the point, and what to optimise for instead.",
        script: {
          title: "Rethinking the Productive Day",
          style: "conversational",
          length: "medium",
          description: "A conversational script challenging popular productivity advice.",
          system_prompt: "You are a productivity coach. Write practical, myth-busting scripts."
        },
        post: {
          title: "The 2-hour workday myth",
          hook: "Everyone's selling you a 2-hour workday. Here's why that's the wrong goal:",
          body: <<~BODY
            Productivity isn't about working less.

            It's about making the hours you work actually count.

            Three things that moved the needle for me:

            1. One deep-work block before email
            2. A hard stop — deadlines create focus
            3. Saying no to "quick calls"

            Optimise for output, not for a smaller number on the clock.

            What's your one non-negotiable work habit?
          BODY
        }
      },
      {
        title: "Building a second brain with AI",
        topic: "Knowledge Management",
        description: "How to combine note-taking systems with AI to never lose a good idea again.",
        script: {
          title: "Your AI-Powered Second Brain",
          style: "educational",
          length: "long",
          description: "A detailed walkthrough of pairing note-taking with AI retrieval.",
          system_prompt: "You are a knowledge-management expert. Write thorough, structured scripts."
        },
        post: {
          title: "Build a second brain",
          hook: "I haven't lost a good idea in 2 years. Here's the system:",
          body: <<~BODY
            Your brain is for having ideas, not storing them.

            My setup:

            1. Capture everything in one inbox
            2. Tag by project, not by folder
            3. Let AI surface connections I'd never spot

            The result? Ideas compound instead of evaporating.

            Where do your best ideas go to die?
          BODY
        }
      }
    ]
  },
  {
    email: "maya@contentflow.com",
    creator: {
      name: "Maya Chen",
      topic: "Personal Finance",
      audience: "Millennials paying off debt and starting to invest",
      goal: "Make money management feel approachable and stress-free"
    },
    ideas: [
      {
        title: "The debt snowball that actually stuck",
        topic: "Debt Payoff",
        description: "A real story of paying off debt and the habits that made it sustainable.",
        script: {
          title: "How I Paid Off My Debt",
          style: "storytelling",
          length: "medium",
          description: "A personal-finance story script about a successful debt payoff journey.",
          system_prompt: "You are a relatable finance creator. Write warm, honest scripts."
        },
        post: {
          title: "The debt snowball",
          hook: "I paid off $42k in 19 months on an average salary. No side hustle. Here's how:",
          body: <<~BODY
            Everyone said I needed to earn more.

            What I actually needed was a system.

            1. Listed every debt smallest to largest
            2. Threw every spare dollar at the smallest
            3. Rolled each payment into the next

            The wins came fast — and that's what kept me going.

            Momentum beats math when you're starting out.
          BODY
        }
      },
      {
        title: "Index funds explained in 60 seconds",
        topic: "Investing",
        description: "A beginner-friendly breakdown of why index funds are a sensible default.",
        script: {
          title: "Index Funds 101",
          style: "educational",
          length: "short",
          description: "A short, jargon-free explainer on index fund investing.",
          system_prompt: "You are a finance educator. Write clear, beginner-friendly scripts."
        },
        post: {
          title: "Index funds explained",
          hook: "If I could teach my younger self one money lesson, it'd be this:",
          body: <<~BODY
            You don't need to pick winning stocks.

            You just need to own the whole market.

            That's what an index fund does:

            1. Buys a tiny slice of hundreds of companies
            2. Charges almost nothing in fees
            3. Quietly compounds for decades

            Boring? Yes. Effective? Also yes.
          BODY
        }
      },
      {
        title: "The 50/30/20 budget, simplified",
        topic: "Budgeting",
        description: "How to split your income without tracking every single coffee.",
        script: {
          title: "Budgeting Without the Spreadsheet",
          style: "conversational",
          length: "short",
          description: "A relaxed take on the 50/30/20 budgeting rule.",
          system_prompt: "You are a friendly finance coach. Write low-pressure, practical scripts."
        },
        post: {
          title: "The 50/30/20 budget",
          hook: "I tracked every expense for a year. Then I quit and did this instead:",
          body: <<~BODY
            Detailed budgets fail because they're exhausting.

            So I switched to one rule:

            50% needs
            30% wants
            20% future you

            That's it. No 40-row spreadsheet.

            The best budget is the one you'll actually keep.
          BODY
        }
      }
    ]
  },
  {
    email: "marcus@contentflow.com",
    creator: {
      name: "Marcus Webb",
      topic: "Fitness & Wellness",
      audience: "Busy professionals who struggle to find time to train",
      goal: "Help people stay consistent without living in the gym"
    },
    ideas: [
      {
        title: "The 20-minute workout that works",
        topic: "Training",
        description: "Why short, frequent sessions beat the occasional marathon gym day.",
        script: {
          title: "Short Workouts, Real Results",
          style: "educational",
          length: "short",
          description: "A script making the case for efficient, time-boxed training.",
          system_prompt: "You are a fitness coach. Write motivating, no-nonsense scripts."
        },
        post: {
          title: "The 20-minute workout",
          hook: "You don't need 90 minutes in the gym. You need 20 minutes, 4x a week.",
          body: <<~BODY
            The "go hard or go home" crowd has it backwards.

            Consistency beats intensity every time.

            My weekly template:

            1. Two strength sessions
            2. Two short conditioning days
            3. Walk daily, no excuses

            Twenty focused minutes you'll repeat > two hours you'll dread.
          BODY
        }
      },
      {
        title: "Sleep is the cheat code",
        topic: "Recovery",
        description: "How prioritising sleep outperforms most supplements and routines.",
        script: {
          title: "Why Sleep Beats Supplements",
          style: "conversational",
          length: "medium",
          description: "A script on the underrated role of sleep in fitness results.",
          system_prompt: "You are a wellness coach. Write evidence-based, calming scripts."
        },
        post: {
          title: "Sleep is the cheat code",
          hook: "I wasted years on supplements. The real cheat code was free:",
          body: <<~BODY
            No pre-workout fixes a bad night's sleep.

            When I started protecting my sleep:

            1. Recovery got faster
            2. Cravings dropped
            3. Workouts felt easier

            Train hard, eat well — but sleep is the foundation.

            How many hours did you get last night?
          BODY
        }
      },
      {
        title: "Protein without the chicken-and-rice boredom",
        topic: "Nutrition",
        description: "Simple ways to hit protein targets without eating the same meal daily.",
        script: {
          title: "Eat Enough Protein, Stay Sane",
          style: "educational",
          length: "short",
          description: "A practical script on varied, high-protein eating.",
          system_prompt: "You are a nutrition coach. Write simple, actionable scripts."
        },
        post: {
          title: "Protein without boredom",
          hook: "Hitting your protein goal doesn't mean eating chicken and rice 5x a day.",
          body: <<~BODY
            Most people undereat protein because it gets boring.

            Easy swaps that fixed it for me:

            1. Greek yogurt instead of cereal
            2. Eggs on everything
            3. A protein shake as a default snack

            Variety is what makes a diet stick.

            What's your go-to high-protein meal?
          BODY
        }
      }
    ]
  },
  {
    email: "priya@contentflow.com",
    creator: {
      name: "Priya Nair",
      topic: "Software Engineering Careers",
      audience: "Junior developers trying to level up",
      goal: "Demystify the path from junior to senior engineer"
    },
    ideas: [
      {
        title: "What separates junior and senior engineers",
        topic: "Career Growth",
        description: "It's rarely about raw coding skill — here's what actually matters.",
        script: {
          title: "Junior to Senior, Decoded",
          style: "educational",
          length: "medium",
          description: "A script explaining the real differences between experience levels.",
          system_prompt: "You are a senior engineer and mentor. Write candid, helpful scripts."
        },
        post: {
          title: "Junior vs senior engineers",
          hook: "Senior engineers aren't just better coders. The real gap is somewhere else:",
          body: <<~BODY
            I used to think seniority was about syntax.

            It's not. It's about judgement.

            What changed for me:

            1. Asking "should we?" before "how do we?"
            2. Writing code my teammates can delete
            3. Reducing scope instead of adding it

            Code is the easy part. Decisions are the job.
          BODY
        }
      },
      {
        title: "How to read a giant codebase",
        topic: "Engineering Skills",
        description: "A practical approach to getting productive in unfamiliar code fast.",
        script: {
          title: "Navigating Legacy Code",
          style: "educational",
          length: "long",
          description: "A detailed script on strategies for understanding large codebases.",
          system_prompt: "You are an experienced engineer. Write structured, practical scripts."
        },
        post: {
          title: "Reading a giant codebase",
          hook: "Dropped into a 500k-line codebase? Don't read it top to bottom. Do this:",
          body: <<~BODY
            New codebases feel overwhelming because you try to understand everything.

            You don't need to.

            1. Follow one real request end to end
            2. Set breakpoints, watch the data flow
            3. Ignore everything not on that path

            Understand one slice deeply before going wide.
          BODY
        }
      },
      {
        title: "The career-defining power of writing",
        topic: "Soft Skills",
        description: "Why clear writing quietly accelerates engineering careers.",
        script: {
          title: "Why Engineers Should Write",
          style: "conversational",
          length: "short",
          description: "A script on the underrated value of writing for engineers.",
          system_prompt: "You are a tech lead. Write reflective, encouraging scripts."
        },
        post: {
          title: "Engineers who write win",
          hook: "The best career move I made as an engineer had nothing to do with code:",
          body: <<~BODY
            I learned to write clearly.

            Suddenly:

            1. My proposals got approved
            2. My PRs got reviewed faster
            3. People trusted my judgement

            Writing is thinking made visible.

            Invest in it earlier than you think you need to.
          BODY
        }
      }
    ]
  },
  {
    email: "elena@contentflow.com",
    creator: {
      name: "Elena Rossi",
      topic: "Sustainable Living",
      audience: "Eco-conscious consumers wanting practical change",
      goal: "Make sustainability feel doable, not preachy"
    },
    ideas: [
      {
        title: "Sustainability without the guilt",
        topic: "Mindset",
        description: "Why an all-or-nothing approach to going green backfires.",
        script: {
          title: "Progress Over Perfection",
          style: "conversational",
          length: "medium",
          description: "A script reframing sustainability as small, sustainable habits.",
          system_prompt: "You are a sustainability advocate. Write warm, non-judgemental scripts."
        },
        post: {
          title: "Sustainability without guilt",
          hook: "You don't need a zero-waste pantry to make a difference. Start here:",
          body: <<~BODY
            Perfect sustainability is a trap.

            It makes people give up before they start.

            What actually works:

            1. Change one habit at a time
            2. Use what you already own
            3. Celebrate small wins

            A million people doing it imperfectly beats a handful doing it perfectly.
          BODY
        }
      },
      {
        title: "The real cost of fast fashion",
        topic: "Conscious Consumption",
        description: "Breaking down what cheap clothing actually costs us.",
        script: {
          title: "Behind the Price Tag",
          style: "educational",
          length: "medium",
          description: "A script unpacking the hidden costs of fast fashion.",
          system_prompt: "You are an ethical-living educator. Write informative, balanced scripts."
        },
        post: {
          title: "The cost of fast fashion",
          hook: "That $5 t-shirt isn't cheap. Someone else is paying for it.",
          body: <<~BODY
            Fast fashion feels like a bargain.

            The real price shows up elsewhere:

            1. Garment workers underpaid
            2. Landfills overflowing
            3. Clothes that fall apart in a season

            Buy less. Buy better. Wear it longer.

            When did you last repair instead of replace?
          BODY
        }
      },
      {
        title: "Composting in a tiny apartment",
        topic: "Zero Waste",
        description: "Yes, you can compost without a backyard — here's how.",
        script: {
          title: "Small-Space Composting",
          style: "educational",
          length: "short",
          description: "A how-to script on composting in limited living spaces.",
          system_prompt: "You are a zero-waste coach. Write practical, encouraging scripts."
        },
        post: {
          title: "Composting in an apartment",
          hook: "No backyard? You can still compost. I've done it in a studio flat for 3 years.",
          body: <<~BODY
            "I'd compost if I had the space."

            You have more options than you think:

            1. A sealed countertop bin
            2. A local drop-off or community garden
            3. Bokashi for the truly tiny kitchen

            A third of household waste is organic. This is the easiest win there is.
          BODY
        }
      }
    ]
  }
]

# ------------------------------------------------------------------------------
# 3. Create the records
# ------------------------------------------------------------------------------
puts "Seeding #{SEED_DATA.size} creators and their content...\n\n"

SEED_DATA.each do |data|
  # --- User -------------------------------------------------------------------
  user = User.create!(
    email: data[:email],
    password: "password123",
    password_confirmation: "password123"
  )
  puts "Created user: #{user.email}"

  # --- Creator (one per user; User has_one :creator) --------------------------
  creator = Creator.create!(data[:creator].merge(user: user))
  puts "  Created creator: #{creator.name} (#{creator.topic})"

  # --- Ideas → Scripts → LinkedIn posts ---------------------------------------
  # Idea belongs_to :user (there's no creator_id column), so each idea is tied
  # to the user we just created.
  data[:ideas].each do |idea_data|
    idea = Idea.create!(
      user: user,
      title: idea_data[:title],
      topic: idea_data[:topic],
      description: idea_data[:description]
    )
    puts "    Created idea: #{idea.title}"

    # One script per idea.
    script = Script.create!(idea_data[:script].merge(idea: idea))
    puts "      Created script: #{script.title}"

    # One LinkedIn post per script.
    post = LinkedinPost.create!(idea_data[:post].merge(script: script))
    puts "      Created LinkedIn post: #{post.title}"
  end

  puts ""
end

# ------------------------------------------------------------------------------
# 4. Sample chats (exercise the polymorphic `chattable` association — F1)
# ------------------------------------------------------------------------------
# A chat can belong to any chattable owner (User/Idea/Script/LinkedinPost) via
# chattable_type/chattable_id, or stand alone (chattable: nil). We seed one of
# each so the new association — and the existing standalone /chats flow — both
# have demo data to poke at in the console or UI.
puts "Seeding sample chats..."

# Owned chat: idea.chats.create! sets chattable_type "Idea" + chattable_id.
demo_idea = Idea.find_by!(title: "How AI is changing the way we create content")
idea_chat = demo_idea.chats.create!
idea_chat.messages.create!(role: "user",      content: "Help me brainstorm hooks for this idea.")
idea_chat.messages.create!(role: "assistant", content: "Sure — bold, curious, or contrarian?")
puts "  Created idea chat (chattable: Idea ##{demo_idea.id}) with #{idea_chat.messages.count} messages"

# Standalone chat: no owner, mirrors the existing /chats flow.
standalone = Chat.create!
standalone.messages.create!(role: "user", content: "What should I post about today?")
puts "  Created standalone chat (no owner) with #{standalone.messages.count} message"

puts ""

# ------------------------------------------------------------------------------
# 5. Sample Substack feed (idea-feed source + cached posts)
# ------------------------------------------------------------------------------
# The fetch pipeline reads live RSS over the network, so seeding real sources
# would make `db:seed` slow and flaky (and dependent on a feed staying online).
# Instead we insert one source plus a few cached posts *directly*, bypassing
# SubstackFetchService — enough to exercise the feed UI and the "use as
# inspiration" → generate_idea chat flow completely offline.
#
# fetched_at is stamped to "now" so the source isn't stale: a Refresh won't try
# to re-fetch it over the network and overwrite this demo data.
#
# No explicit cleanup is needed — User.destroy_all above cascades through
# `has_many :substack_sources, dependent: :destroy` (and on to posts).
puts "Seeding sample Substack feed..."

demo_user = User.find_by!(email: "demo@contentflow.com")
substack_source = demo_user.substack_sources.create!(
  feed_url:   "https://www.lennysnewsletter.com/feed",
  name:       "Lenny's Newsletter",
  handle:     "lennysnewsletter",
  fetched_at: Time.current
)

SUBSTACK_POSTS = [
  {
    title:   "How the best product teams cut scope",
    author:  "Lenny Rachitsky",
    summary: "Shipping the right slice beats shipping everything. A look at how high-performing teams ruthlessly trim scope without losing the plot.",
    published_at: 2.days.ago
  },
  {
    title:   "The hidden cost of context switching",
    author:  "Lenny Rachitsky",
    summary: "Every tab, ping, and 'quick question' has a price. Why protecting deep-work blocks is the highest-leverage habit for makers.",
    published_at: 6.days.ago
  },
  {
    title:   "What great onboarding actually looks like",
    author:  "Lenny Rachitsky",
    summary: "First impressions compound. A teardown of onboarding flows that turn signups into habitual users.",
    published_at: 13.days.ago
  },
  {
    title:   "Pricing is a product decision, not a finance one",
    author:  "Lenny Rachitsky",
    summary: "Why your pricing page deserves the same care as your core feature work, and a simple framework for getting it right.",
    published_at: 25.days.ago
  }
]

SUBSTACK_POSTS.each_with_index do |post_data, i|
  substack_source.substack_posts.create!(
    guid:         "seed-substack-#{i}",
    url:          "https://www.lennysnewsletter.com/p/seed-#{i}",
    title:        post_data[:title],
    author:       post_data[:author],
    summary:      post_data[:summary],
    published_at: post_data[:published_at]
  )
end
puts "  Created source '#{substack_source.name}' with #{substack_source.substack_posts.count} cached posts"

puts ""

# ------------------------------------------------------------------------------
# 6. Summary
# ------------------------------------------------------------------------------
puts "Seeding complete!"
puts "  Users:           #{User.count}"
puts "  Creators:        #{Creator.count}"
puts "  Ideas:           #{Idea.count}"
puts "  Scripts:         #{Script.count}"
puts "  LinkedIn posts:  #{LinkedinPost.count}"
puts "  Chats:           #{Chat.count} (#{Chat.where.not(chattable_id: nil).count} owned, #{Chat.where(chattable_id: nil).count} standalone)"
puts "  Messages:        #{Message.count}"
puts "  Substack sources: #{SubstackSource.count}"
puts "  Substack posts:   #{SubstackPost.count}"

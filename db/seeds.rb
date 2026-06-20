# db/seeds.rb
#
# Seeds the content-flow chain: User → Creator → Idea → Script → posts
# (LinkedIn / Twitter / Instagram, attached both directly to ideas and to scripts)
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
TwitterPost.destroy_all
InstagramPost.destroy_all
LinkedinPost.destroy_all
Script.destroy_all
Idea.destroy_all
Creator.destroy_all
User.destroy_all

puts "  Done. Tables are clean.\n\n"

# ------------------------------------------------------------------------------
# 2. Sample data
# ------------------------------------------------------------------------------
# One entry per creator. Each creator owns a user account and 3 ideas. Every
# idea carries exactly one script, and BOTH the idea and its script carry one
# direct post per platform (LinkedIn, Twitter, Instagram): the idea's posts
# live under the flat `linkedin_post:` / `twitter_post:` / `instagram_post:`
# keys, the script's under the nested `script_posts:` hash. Looping over this
# structure keeps the creation logic in one place instead of repeating
# `create!` calls 100+ times.
SEED_DATA = [
  {
    email: "theo@contentflow.com",
    creator: {
      name: "Theodora",
      topic: "AI, Productivity and Technology",
      audience: "Startup founders, knowledge workers, young professionals, between 18-35 years of age",
      goal: "Build thought leadership and grow my audience, teach non technical people how to use AI and Software"
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
          custom_instructions: "You are a knowledgeable tech content creator. Write engaging, concise scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "AI tools thread",
          hook: "I tested every AI content tool so you don't have to. Here's the honest verdict 🧵",
          body: <<~BODY
            1/ ChatGPT: best for first drafts. Plan on rewriting half of it — but half a draft beats a blank page.

            2/ Midjourney: genuinely impressive. The gap between AI visuals and stock photos is closing fast.

            3/ Descript: cuts video editing time in half. If you're on camera at all, try this.

            Bottom line: use AI as a thinking partner, not a ghostwriter.

            What's in your stack?
          BODY
        },
        instagram_post: {
          title: "AI content tools that actually work",
          hook: "30 days. Every AI content tool on the market. Here's what made the cut ↓",
          body: <<~BODY
            I've been deep in the AI tool rabbit hole so you don't have to be.

            The ones worth your time:

            ✦ ChatGPT — first drafts in minutes (edit heavily)
            ✦ Midjourney — visuals that stop the scroll
            ✦ Descript — video editing without the pain

            The mindset shift that changed everything: AI as a creative collaborator, not a replacement.

            Save this for the next time someone asks what tools you use 🔖

            Which of these have you tried?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "The 3-layer AI content stack",
            hook: "Stop asking if AI will replace creators. Ask what your stack looks like:",
            body: <<~BODY
              Every efficient content workflow I've seen has the same three layers:

              1. Ideation — AI for angles, you for taste
              2. Drafting — AI for speed, you for voice
              3. Distribution — AI for formats, you for timing

              The tools change monthly. The layers don't.

              Which layer is weakest in your workflow?
            BODY
          },
          twitter_post: {
            title: "3-layer AI stack",
            hook: "Every AI content workflow that actually works has the same 3 layers 🧵",
            body: <<~BODY
              1/ Ideation: AI generates angles. You pick the one with taste.

              2/ Drafting: AI gets you to 70% fast. Your voice carries the last 30%.

              3/ Distribution: AI reformats one idea for every platform. You decide where it lands.

              Tools change monthly. Layers don't.
            BODY
          },
          instagram_post: {
            title: "The AI content stack, explained",
            hook: "Your content workflow has 3 layers. AI can power all of them ↓",
            body: <<~BODY
              The tools keep changing. The system doesn't.

              ✦ Ideation — AI for angles, you for taste
              ✦ Drafting — AI for speed, you for voice
              ✦ Distribution — AI for formats, you for timing

              Build the system once. Swap the tools as they improve.

              Save this before your next content sprint 🔖

              Which layer needs the most work in your setup?
            BODY
          }
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
          custom_instructions: "You are a productivity coach. Write practical, myth-busting scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "2-hour workday myth",
          hook: "Hot take: the 2-hour workday is a distraction. Here's what actually matters 🧵",
          body: <<~BODY
            1/ Working fewer hours isn't the goal. Doing fewer *wrong* things is.

            2/ My non-negotiables:
            → Deep work block before email opens
            → A hard stop time (constraints create focus)
            → No "quick calls" that aren't quick

            3/ The metric to optimise: did meaningful work get done today?

            Hours are vanity. Output is sanity.
          BODY
        },
        instagram_post: {
          title: "The productivity myth nobody talks about",
          hook: "The 2-hour workday gurus aren't lying. They're just optimising for the wrong thing.",
          body: <<~BODY
            Productivity culture sold you a fantasy.

            Fewer hours ≠ better life if the hours you have are filled with noise.

            What actually works:

            ✦ One protected deep-work block — before Slack, before email
            ✦ A real end time — deadlines you make for yourself
            ✦ Fewer meetings, full stop

            You don't need a shorter workday. You need a fuller one.

            Drop your one non-negotiable work habit below 👇
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Measure output, not hours",
            hook: "I deleted my time tracker and got more done. Here's what I measure instead:",
            body: <<~BODY
              Hours worked is a vanity metric.

              What I track now:

              1. Did one meaningful thing ship today?
              2. Did I protect my deep-work block?
              3. Did I end on time?

              Three yeses beats ten logged hours.

              What do you actually measure?
            BODY
          },
          twitter_post: {
            title: "Output over hours",
            hook: "I deleted my time tracker. Productivity went up. Here's the replacement 🧵",
            body: <<~BODY
              1/ Tracking hours tells you how long you sat there. Not whether anything happened.

              2/ The three questions I ask at 5pm instead:
              → Did one meaningful thing ship?
              → Did the deep-work block survive?
              → Did I stop on time?

              3/ Three yeses beats ten logged hours.

              What's your end-of-day check?
            BODY
          },
          instagram_post: {
            title: "Stop tracking hours",
            hook: "I deleted my time tracker and finally got productive. Here's what I do instead ↓",
            body: <<~BODY
              Hours are how long you sat there. Not what happened.

              My 5pm scorecard:

              ✦ One meaningful thing shipped
              ✦ Deep-work block protected
              ✦ Hard stop respected

              Three yeses = a good day. No spreadsheet required.

              What's on your end-of-day checklist? 👇
            BODY
          }
        }
      },
      {
        title: "Building a second brain with AI",
        topic: "Knowledge Management",
        description: "How to combine note-taking systems with AI to never lose a good idea again.",
        script: {
          title: "Second Brain Systems",
          style: "educational",
          length: "medium",
          description: "A practical walkthrough of building an AI-assisted note system that compounds.",
          custom_instructions: "You are a knowledge-management nerd. Write systematic, actionable scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Second brain with AI",
          hook: "I haven't lost a good idea in 2 years. The system is embarrassingly simple 🧵",
          body: <<~BODY
            1/ Your brain is terrible at storing ideas. It's great at generating them. Stop asking it to do both.

            2/ The setup:
            → One capture inbox (doesn't matter which app)
            → Tags over folders — ideas live in many contexts
            → AI to resurface what you forgot you knew

            3/ The real win: ideas start connecting across topics you never linked manually.

            What do you use to capture ideas?
          BODY
        },
        instagram_post: {
          title: "Build a second brain with AI",
          hook: "2 years. Zero lost ideas. Here's the system that made it happen ↓",
          body: <<~BODY
            Your brain is a generator, not a hard drive.

            Stop treating it like one.

            My second brain setup:

            ✦ One inbox — capture everything, judge nothing
            ✦ Tags over folders — ideas belong to multiple projects
            ✦ AI as a connection engine — it finds links you'd never spot

            The result isn't just fewer lost ideas. It's ideas that compound.

            Save this and build yours this week 🔖

            What's your note-taking app of choice?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "The capture habit",
            hook: "Your second brain fails at the first step, not the last. Fix capture first:",
            body: <<~BODY
              Everyone obsesses over the perfect note app.

              Almost nobody fixes capture.

              1. One inbox, zero friction
              2. Capture in under 10 seconds or you won't
              3. Process weekly, not in the moment

              A mediocre system you feed daily beats a perfect one you abandon.

              How do you capture ideas on the go?
            BODY
          },
          twitter_post: {
            title: "Capture before organising",
            hook: "Your second brain isn't failing at organisation. It's failing at capture 🧵",
            body: <<~BODY
              1/ The perfect folder structure doesn't matter if ideas never make it in.

              2/ Capture rules that stick:
              → One inbox for everything
              → Under 10 seconds or it won't happen
              → Sort weekly, never in the moment

              3/ Feed a mediocre system daily and it beats the perfect system you abandoned.

              Where do your ideas go right now?
            BODY
          },
          instagram_post: {
            title: "Fix capture first",
            hook: "Your note system isn't broken. Your capture habit is ↓",
            body: <<~BODY
              Stop redesigning your folders. Start catching your ideas.

              ✦ One inbox — everything goes in, no sorting
              ✦ Ten-second rule — if capture takes longer, you'll skip it
              ✦ Weekly review — organise in batches, not in the moment

              The system that gets fed daily wins. Every time.

              Save this and set up your inbox today 🔖
            BODY
          }
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
          custom_instructions: "You are a relatable finance creator. Write warm, honest scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Debt snowball story",
          hook: "$42k gone in 19 months. Average salary. No side hustle. Here's the exact method 🧵",
          body: <<~BODY
            1/ Everyone said I needed to earn more. I didn't. I needed a system I'd actually stick to.

            2/ The debt snowball:
            → List debts smallest to largest (ignore interest rate)
            → Attack the smallest with every spare dollar
            → Roll that payment into the next debt when it's gone

            3/ The psychology is the point. Small wins early = motivation to keep going.

            Momentum beats math.
          BODY
        },
        instagram_post: {
          title: "How I paid off $42k",
          hook: "$42,000 of debt. 19 months. Average salary. No side hustle. Here's what worked ↓",
          body: <<~BODY
            I used to think I needed to earn more to get out of debt.

            Turns out I needed a system — not a raise.

            The debt snowball method:

            ✦ List every debt smallest to largest
            ✦ Throw everything extra at the smallest
            ✦ Roll each cleared payment into the next

            The math isn't optimal. The psychology is.

            Early wins kept me going when it felt impossible.

            Have you ever tried the snowball method? 👇
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Momentum beats math",
            hook: "The avalanche method is mathematically better. I still tell people to snowball. Here's why:",
            body: <<~BODY
              Personal finance is more personal than finance.

              The snowball works because:

              1. The first win lands in weeks, not years
              2. Every cleared debt frees up cash and confidence
              3. You stop avoiding your own numbers

              A plan you finish beats a plan that's optimal.

              Which debt would you knock out first?
            BODY
          },
          twitter_post: {
            title: "Snowball vs avalanche",
            hook: "The avalanche method saves more interest. I still recommend the snowball 🧵",
            body: <<~BODY
              1/ On paper, paying highest-interest first wins. On paper.

              2/ In real life:
              → The snowball's first win lands in weeks
              → Each cleared debt frees cash AND confidence
              → You stop dreading your own spreadsheet

              3/ The best payoff plan is the one you finish.

              Personal finance is more personal than finance.
            BODY
          },
          instagram_post: {
            title: "Why the snowball works",
            hook: "The 'wrong' debt method got me debt-free. Here's why I'd choose it again ↓",
            body: <<~BODY
              Mathematically, the avalanche wins. Behaviourally, the snowball does.

              ✦ First win in weeks — not years
              ✦ Every cleared debt = more cash, more confidence
              ✦ You actually open your banking app again

              A plan you stick to beats a plan that's optimal.

              Tag someone starting their payoff journey 💪
            BODY
          }
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
          custom_instructions: "You are a finance educator. Write clear, beginner-friendly scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Index funds in 60 seconds",
          hook: "The investing advice I wish I'd gotten at 22: you don't need to pick stocks 🧵",
          body: <<~BODY
            1/ An index fund doesn't try to beat the market. It *is* the market.

            2/ What that means practically:
            → Owns tiny slices of hundreds of companies
            → Fees near zero (0.03–0.10% is normal)
            → Compounds quietly for decades

            3/ Most professional fund managers underperform index funds over 10+ years.

            Boring beats clever. Every time.
          BODY
        },
        instagram_post: {
          title: "Index funds, explained simply",
          hook: "The one investing concept I'd teach every 20-something. It takes 60 seconds to understand ↓",
          body: <<~BODY
            You don't need to find the next Apple.

            You just need to own a little bit of everything.

            That's literally what an index fund does:

            ✦ Buys tiny slices of hundreds of companies
            ✦ Near-zero fees (think 0.03%)
            ✦ Compounds silently for decades

            Boring? Completely. Effective? Undeniably.

            The best investment strategy is the one you can set and forget.

            Are you investing in index funds? 👇
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Fees eat fortunes",
            hook: "A 1% fee sounds tiny. Over 30 years it can eat a quarter of your portfolio:",
            body: <<~BODY
              The most boring number in investing is the most important one.

              1. 1% vs 0.05% in fees = a six-figure gap over a career
              2. High fees rarely buy better returns
              3. Index funds make low fees the default

              Check your expense ratio before your returns.

              Do you know what you're paying?
            BODY
          },
          twitter_post: {
            title: "The 1% fee trap",
            hook: "A 1% fee doesn't sound like much. Over 30 years it can cost you a six-figure sum 🧵",
            body: <<~BODY
              1/ Fees compound exactly like returns do. Against you.

              2/ The quiet math:
              → 1% vs 0.05% on the same portfolio
              → Same market, same decades
              → The difference is often 20%+ of your final balance

              3/ Most expensive funds don't outperform. You're paying more for less.

              Check your expense ratio today.
            BODY
          },
          instagram_post: {
            title: "The fee that eats your future",
            hook: "One tiny number decides more of your wealth than stock picks ever will ↓",
            body: <<~BODY
              It's not the market. It's the fee.

              ✦ 1% fee vs 0.05% — same portfolio, wildly different outcome
              ✦ Over 30 years the gap is often six figures
              ✦ Expensive funds rarely beat cheap index funds

              Boring, low-cost, automatic. That's the whole strategy.

              Go check your expense ratio — it takes 2 minutes 📌
            BODY
          }
        }
      },
      {
        title: "The 50/30/20 budget, simplified",
        topic: "Budgeting",
        description: "How to split your income without tracking every single coffee.",
        script: {
          title: "Budgeting Without Spreadsheets",
          style: "conversational",
          length: "short",
          description: "A friendly explainer on automating the 50/30/20 split so the budget runs itself.",
          custom_instructions: "You are a relatable finance creator. Write warm, practical scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "50/30/20 budget rule",
          hook: "I spent a year tracking every coffee and grocery item. Then I found a better way 🧵",
          body: <<~BODY
            1/ Detailed budgets fail because they're exhausting to maintain. You miss one week and the whole system collapses.

            2/ The 50/30/20 rule instead:
            → 50% → needs (rent, food, bills)
            → 30% → wants (fun, treats, life)
            → 20% → future you (savings, investments, debt)

            3/ It's not perfect. It's sustainable. And sustainable wins.

            What budgeting method do you actually stick to?
          BODY
        },
        instagram_post: {
          title: "Budget without the spreadsheet",
          hook: "I quit tracking every expense and my finances got better. Here's what I switched to ↓",
          body: <<~BODY
            Detailed budgets make you feel organised for about a week.

            Then life happens and the spreadsheet dies.

            The 50/30/20 rule is different:

            ✦ 50% → needs (rent, utilities, groceries)
            ✦ 30% → wants (whatever makes life enjoyable)
            ✦ 20% → future you (savings, investing, debt)

            No categories. No guilt. No 47-row spreadsheet.

            The best budget is the one you'll actually keep. 📌

            Which budgeting method works for you?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Automate the split",
            hook: "The best budget runs without you. Set it up once:",
            body: <<~BODY
              Willpower is a terrible budgeting tool.

              Automation isn't:

              1. Payday transfer #1 → bills account
              2. Payday transfer #2 → savings and investments
              3. What's left is guilt-free spending

              Decide once. Let the system decide every month after.

              Is your budget automated yet?
            BODY
          },
          twitter_post: {
            title: "Set-and-forget budget",
            hook: "Your budget shouldn't need willpower. It needs two standing orders 🧵",
            body: <<~BODY
              1/ Every budget that relies on daily discipline eventually loses to a bad week.

              2/ The payday setup:
              → Transfer 1: bills account
              → Transfer 2: savings + investing
              → Whatever's left: spend it, guilt-free

              3/ You make the decision once. The system makes it every month after.

              Automated > disciplined.
            BODY
          },
          instagram_post: {
            title: "The budget that runs itself",
            hook: "I haven't 'done my budget' in months. It does itself. Here's the setup ↓",
            body: <<~BODY
              Two standing orders replaced my entire budgeting routine.

              ✦ Payday transfer #1 → bills
              ✦ Payday transfer #2 → savings + investing
              ✦ The rest → spend without guilt

              No tracking. No categories. No Sunday-night spreadsheet shame.

              Set it up once this payday 📌

              Is your budget automated?
            BODY
          }
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
          custom_instructions: "You are a fitness coach. Write motivating, no-nonsense scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "20-minute workout case",
          hook: "The \"go hard or go home\" mentality is keeping you out of the gym 🧵",
          body: <<~BODY
            1/ You're not skipping workouts because you're lazy. You're skipping because 90-minute sessions aren't sustainable.

            2/ My weekly template:
            → 2 strength sessions (20 min)
            → 2 conditioning days (20 min)
            → Daily walk (non-negotiable)

            3/ The math: 20 focused minutes × 4 = 80 minutes/week. That's it.

            A workout you'll actually do beats a perfect one you keep postponing.
          BODY
        },
        instagram_post: {
          title: "The 20-minute workout",
          hook: "Stop waiting for the 90-minute window that never comes. You only need 20 minutes.",
          body: <<~BODY
            Real talk: most people don't skip the gym because they're lazy.

            They skip because the bar is too high.

            My sustainable weekly template:

            ✦ Monday — 20 min strength
            ✦ Wednesday — 20 min conditioning
            ✦ Friday — 20 min strength
            ✦ Saturday — 20 min conditioning
            ✦ Every day — walk

            That's 80 minutes of intentional training per week.

            Consistency > intensity. Every single time. 💪

            What's your go-to short workout?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "The minimum effective dose",
            hook: "More training isn't better training. Better training is better training:",
            body: <<~BODY
              The gym doesn't reward time served.

              What 20 focused minutes needs:

              1. One main lift, done well
              2. One conditioning finisher
              3. Zero phone scrolling between sets

              Intensity with intention beats volume with distraction.

              How long is your average session?
            BODY
          },
          twitter_post: {
            title: "Minimum effective dose",
            hook: "Your 90-minute workout is mostly rest and scrolling. Here's the honest version 🧵",
            body: <<~BODY
              1/ Track your next long session. Actual working time is usually under 25 minutes.

              2/ The 20-minute version:
              → One main lift, focused
              → One short conditioning finisher
              → Phone stays in the locker

              3/ Same stimulus, quarter of the time, zero excuses left.

              Try it for two weeks.
            BODY
          },
          instagram_post: {
            title: "Your workout is shorter than you think",
            hook: "Time your next gym session. The actual work is ~20 minutes. So just do 20 minutes ↓",
            body: <<~BODY
              The 90-minute workout is mostly rest, chat, and scrolling.

              The 20-minute version:

              ✦ One main lift — full focus
              ✦ One conditioning finisher — short and sharp
              ✦ No phone until you're done

              Same results. Quarter of the time. Zero excuses.

              Try it for two weeks and tell me how it goes 💪
            BODY
          }
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
          custom_instructions: "You are a wellness coach. Write evidence-based, calming scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Sleep beats supplements",
          hook: "I spent years optimising everything except the thing that matters most 🧵",
          body: <<~BODY
            1/ Pre-workout, creatine, protein timing — I tried all of it. Nothing moved the needle like fixing my sleep.

            2/ What changed when I started protecting 7–8 hours:
            → Muscle recovery visibly faster
            → Food cravings down significantly
            → Every session felt better

            3/ Sleep is free. It's available tonight. And it outperforms most of your supplement stack.

            How many hours did you get last night?
          BODY
        },
        instagram_post: {
          title: "Sleep is your best supplement",
          hook: "I used to spend $200/month on supplements. The best performance upgrade was free.",
          body: <<~BODY
            Hot take: your sleep schedule matters more than your stack.

            When I went from 5–6 hours to a protected 8:

            ✦ Recovery got noticeably faster
            ✦ Cravings dropped (no more 10pm raids)
            ✦ PRs started moving again

            Sleep is the foundation that everything else sits on.

            Train hard. Eat well. But protect your sleep like it's your job.

            How many hours are you averaging right now? 👇
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "The wind-down routine",
            hook: "You can't force sleep. You can make it inevitable:",
            body: <<~BODY
              Good sleep starts 90 minutes before bed.

              The routine that fixed mine:

              1. Screens dim, notifications off
              2. Same bedtime, even weekends
              3. Cool, dark room — boring on purpose

              Recovery is built in the evening, not the morning.

              What time do you actually wind down?
            BODY
          },
          twitter_post: {
            title: "Make sleep inevitable",
            hook: "You can't force yourself to sleep. You can make it inevitable 🧵",
            body: <<~BODY
              1/ Sleep isn't a switch. It's a runway. Mine is 90 minutes long.

              2/ The boring routine that works:
              → Screens dim, notifications off
              → Same bedtime every night (yes, weekends)
              → Cool, dark, boring room

              3/ Recovery is built in the evening. The morning just reports the result.

              What's your wind-down look like?
            BODY
          },
          instagram_post: {
            title: "Build a sleep runway",
            hook: "Sleep isn't a switch you flip. It's a runway you build. 90 minutes long ↓",
            body: <<~BODY
              You can't force sleep. You can prepare for it.

              ✦ 90 minutes out — screens dim, notifications off
              ✦ Same bedtime — even on weekends
              ✦ Cool, dark room — boring is the goal

              Your recovery is decided before your head hits the pillow.

              What time does your wind-down start? 👇
            BODY
          }
        }
      },
      {
        title: "Protein without the chicken-and-rice boredom",
        topic: "Nutrition",
        description: "Simple ways to hit protein targets without eating the same meal daily.",
        script: {
          title: "Protein Made Easy",
          style: "conversational",
          length: "short",
          description: "A quick script on hitting daily protein targets with simple, repeatable swaps.",
          custom_instructions: "You are a fitness coach. Write motivating, no-nonsense scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "High protein without boredom",
          hook: "You're not failing to hit your protein goal because of willpower. It's because it's boring 🧵",
          body: <<~BODY
            1/ Chicken breast + rice is a fine meal. The 5th time. Not the 35th.

            2/ Easy protein swaps that don't feel like a chore:
            → Greek yogurt instead of cereal (18–20g, done)
            → Eggs on everything (lunch, dinner, snacks)
            → Protein shake as a default snack, not a post-workout ritual

            3/ Variety is the real protocol. If you can't sustain it, it doesn't work.

            What's your go-to high-protein meal?
          BODY
        },
        instagram_post: {
          title: "Hit your protein without the boredom",
          hook: "Chicken and rice every day is not a personality. Here's how to hit your protein without losing your mind.",
          body: <<~BODY
            Most people undereat protein because the \"healthy\" options feel like punishment.

            Easy swaps that actually stick:

            ✦ Greek yogurt at breakfast — ~20g before you've even started
            ✦ Eggs on everything — lunch, dinner, whatever
            ✦ Protein shake as a snack — not just post-workout

            You don't need a perfect meal plan. You need options you'll keep reaching for.

            Variety is what makes a diet sustainable. 🥚

            What's your favourite high-protein meal?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Protein by default",
            hook: "Stop chasing protein at dinner. Win it by default at breakfast:",
            body: <<~BODY
              Most people start the day 0 for 1 on protein.

              Front-load instead:

              1. 30g at breakfast before anything else
              2. Anchor every meal around the protein first
              3. Keep one zero-effort option in the fridge

              Hit it early and the rest of the day takes care of itself.

              What's your breakfast protein?
            BODY
          },
          twitter_post: {
            title: "Front-load your protein",
            hook: "You're not behind on protein at dinner. You were behind at breakfast 🧵",
            body: <<~BODY
              1/ Cereal, toast, coffee — most breakfasts are a protein zero. The day never recovers.

              2/ The fix:
              → 30g before anything else
              → Build each meal around protein first
              → One zero-effort backup always in the fridge

              3/ Win breakfast and the daily target stops being a chase.

              What's your go-to morning protein?
            BODY
          },
          instagram_post: {
            title: "Win protein at breakfast",
            hook: "If you're scrambling for protein at 9pm, the problem happened at 9am ↓",
            body: <<~BODY
              Most breakfasts are a protein zero. Then dinner becomes a panic.

              ✦ 30g at breakfast — before anything else
              ✦ Protein first at every meal — build the plate around it
              ✦ One zero-effort option in the fridge at all times

              Front-load it and the target hits itself.

              What's your 30g breakfast? 🥚
            BODY
          }
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
          custom_instructions: "You are a senior engineer and mentor. Write candid, helpful scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Junior vs senior gap",
          hook: "The gap between junior and senior isn't technical skill. It's something harder to teach 🧵",
          body: <<~BODY
            1/ Junior me thought seniority meant knowing more syntax. I was wrong.

            2/ The real gaps:
            → "Should we build this?" before "How do we build this?"
            → Writing code your team can change or delete without fear
            → Shrinking scope instead of expanding it

            3/ Technical skill gets you in the room. Judgement gets you promoted.

            What was your biggest mindset shift going from junior to senior?
          BODY
        },
        instagram_post: {
          title: "What makes a senior engineer",
          hook: "Senior engineers aren't faster coders. The real difference is something else entirely ↓",
          body: <<~BODY
            When I was a junior engineer, I thought seniority was about speed and syntax.

            It's not.

            The real shift happens when you start asking different questions:

            ✦ "Should we build this?" before "How do we?"
            ✦ "Will my team be able to change this in a year?"
            ✦ "What can we cut?" instead of what can we add?

            Code is the easy part. Decisions are the actual job.

            Save this for your next career conversation 💾

            What was your biggest mindset shift as an engineer?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Judgement is trainable",
            hook: "Nobody is born with senior-engineer judgement. Here's how you build it:",
            body: <<~BODY
              Judgement looks like magic. It's actually reps.

              How to get them faster:

              1. Write down your predictions before decisions land
              2. Review what you got wrong, not just what broke
              3. Shadow the engineers whose calls keep ageing well

              Experience is just feedback loops you actually closed.

              How do you train judgement on your team?
            BODY
          },
          twitter_post: {
            title: "Training judgement",
            hook: "Senior judgement isn't a gift. It's reps. Here's how to get them faster 🧵",
            body: <<~BODY
              1/ Write your prediction down before every big decision. Review it when reality lands.

              2/ Post-mortem your own calls, not just the outages.

              3/ Find the engineer whose decisions keep ageing well. Ask them why, every time.

              Experience = feedback loops you actually closed.
            BODY
          },
          instagram_post: {
            title: "How to build engineering judgement",
            hook: "Judgement looks like talent. It's actually a training plan ↓",
            body: <<~BODY
              Senior engineers aren't psychic. They've just closed more feedback loops.

              ✦ Predict in writing — before the decision lands
              ✦ Review your misses — not just the incidents
              ✦ Study the engineers whose calls age well

              You can't shortcut the reps. You can stop wasting them.

              Save this for your next growth conversation 💾
            BODY
          }
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
          custom_instructions: "You are an experienced engineer. Write structured, practical scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Reading a giant codebase",
          hook: "First week in a 500k-line codebase? Please don't start at line 1 🧵",
          body: <<~BODY
            1/ The instinct is to read everything. That's why new engineers feel lost for months.

            2/ What actually works:
            → Pick one real feature or request
            → Follow it end to end through the code
            → Set breakpoints, watch the data move
            → Ignore every file not on that path

            3/ Understand one slice deeply. Then another. The map builds itself.

            What's your strategy for a new codebase?
          BODY
        },
        instagram_post: {
          title: "How to read a massive codebase",
          hook: "500,000 lines of code. First day on the job. Here's how to not drown ↓",
          body: <<~BODY
            New engineers try to read the whole thing.

            That's why it takes so long to feel productive.

            The approach that actually works:

            ✦ Pick one feature — something real, something users touch
            ✦ Follow it end to end through the stack
            ✦ Set breakpoints, watch data transform
            ✦ Ignore every file not on that path

            You don't need to understand everything. You need to understand one thing deeply.

            Then another. Then another.

            The mental map builds itself. 🗺️

            What helped you most when joining a new codebase?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Trace, don't read",
            hook: "Reading code is overrated. Tracing it is everything:",
            body: <<~BODY
              A codebase is not a book. Stop reading it like one.

              The tracing toolkit:

              1. A debugger and one real request
              2. Logs that show the actual call order
              3. Notes on the path — yours, not the wiki's

              The map you draw yourself is the one you remember.

              Debugger or print statements — which camp are you in?
            BODY
          },
          twitter_post: {
            title: "Trace the codebase",
            hook: "Stop 'reading the codebase'. Trace it instead 🧵",
            body: <<~BODY
              1/ Code isn't prose. The execution order is nothing like the file order.

              2/ The toolkit:
              → One real request + a debugger
              → Logs to confirm the actual call sequence
              → Hand-drawn notes of the path

              3/ The map you draw yourself sticks. The wiki's doesn't.

              Debugger or print statements?
            BODY
          },
          instagram_post: {
            title: "Trace the code, don't read it",
            hook: "The codebase isn't a book. Reading it top to bottom teaches you almost nothing ↓",
            body: <<~BODY
              Execution order ≠ file order. That's why reading fails.

              ✦ Pick one real request
              ✦ Step through it with a debugger
              ✦ Sketch the path in your own notes

              The map you draw yourself is the map you remember.

              Team debugger or team print statement? 👇
            BODY
          }
        }
      },
      {
        title: "The career-defining power of writing",
        topic: "Soft Skills",
        description: "Why clear writing quietly accelerates engineering careers.",
        script: {
          title: "Write Your Way Up",
          style: "conversational",
          length: "medium",
          description: "A script on using clear writing — docs, RFCs, PR descriptions — to accelerate an engineering career.",
          custom_instructions: "You are a senior engineer and mentor. Write candid, helpful scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Engineers should write",
          hook: "The highest-leverage career skill for engineers isn't a programming language 🧵",
          body: <<~BODY
            1/ I spent years thinking career growth was about technical depth. It matters, but it's not the differentiator.

            2/ When I started writing clearly:
            → RFCs got read and approved
            → PRs got reviewed in hours, not days
            → Leadership started trusting my judgement on things outside my scope

            3/ Writing is thinking made visible. If you can't write it, you haven't thought it through.

            Start a technical blog. Write design docs nobody asked for. Just write.
          BODY
        },
        instagram_post: {
          title: "Why engineers who write get promoted",
          hook: "The career move that changed everything for me had zero lines of code in it.",
          body: <<~BODY
            I learned to write clearly.

            Not prose. Not essays. Just: clear, concise technical communication.

            What changed immediately:

            ✦ Proposals got approved without back-and-forth
            ✦ PRs got reviewed faster (reviewers knew what they were looking at)
            ✦ Stakeholders trusted my judgement beyond my immediate team

            Writing is thinking made visible. If your writing is muddy, so is your thinking.

            Start earlier than you think you need to. The compounding is real. 📝

            Do you write about engineering outside of work?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "The PR description advantage",
            hook: "Want faster reviews? Stop writing better code. Start writing better PR descriptions:",
            body: <<~BODY
              Reviewers don't read your code first. They read your description.

              What mine always include:

              1. The problem, in one sentence
              2. The approach, and what I ruled out
              3. Where to look first

              Five minutes of writing saves days of back-and-forth.

              What makes a PR easy for you to review?
            BODY
          },
          twitter_post: {
            title: "Better PR descriptions",
            hook: "Your PRs aren't reviewed slowly because of the code. It's the description 🧵",
            body: <<~BODY
              1/ A reviewer's first question is never "is this code good?" It's "what am I looking at?"

              2/ Answer it up front:
              → The problem, one sentence
              → The approach, plus what you ruled out
              → Where to start reading

              3/ Five minutes of writing saves days of ping-pong.

              What's your PR template?
            BODY
          },
          instagram_post: {
            title: "Write PRs people want to review",
            hook: "The fastest way to better code reviews has nothing to do with the code ↓",
            body: <<~BODY
              Reviewers read your description before your diff.

              ✦ One sentence: what problem is this solving?
              ✦ One paragraph: the approach and what you ruled out
              ✦ One pointer: where to look first

              Five minutes of writing. Days of back-and-forth saved.

              Save this for your next pull request 📝
            BODY
          }
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
          custom_instructions: "You are a sustainability advocate. Write warm, non-judgemental scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Sustainability without perfectionism",
          hook: "Perfectionism is the enemy of actually helping the planet 🧵",
          body: <<~BODY
            1/ The all-or-nothing approach to sustainability has convinced millions of people that they can't start until they're ready to go all in. They never start.

            2/ What works instead:
            → One habit changed, for real
            → Using what you already own (no new "eco" purchases)
            → Celebrating progress without scorekeeping

            3/ A million people doing it imperfectly > a handful doing it perfectly.

            What's the one sustainable habit you've actually kept?
          BODY
        },
        instagram_post: {
          title: "Sustainability without the guilt trip",
          hook: "You don't need a zero-waste pantry, a capsule wardrobe, and a composting system to start. You just need to start.",
          body: <<~BODY
            Sustainability perfectionism is a trap.

            It makes people feel like they can't do anything unless they can do everything.

            The approach that actually works:

            ✦ Change one thing at a time — and actually change it
            ✦ Use what you already own before buying "eco" alternatives
            ✦ Celebrate the small wins without comparing

            A million people making imperfect choices beats a handful living perfectly.

            Progress over perfection. Always. 🌱

            What's one sustainable swap you've actually stuck with?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "One swap at a time",
            hook: "The greenest thing you can do this month is embarrassingly small. Do it anyway:",
            body: <<~BODY
              Grand eco-resolutions die by February.

              Single swaps survive:

              1. Pick one habit — just one
              2. Run it for 30 days before adding another
              3. Let the easy win pull the next one along

              Small and permanent beats big and abandoned.

              What's the one swap you'd start with?
            BODY
          },
          twitter_post: {
            title: "One swap at a time",
            hook: "Your big sustainability overhaul will fail. The one tiny swap won't 🧵",
            body: <<~BODY
              1/ Grand eco-resolutions collapse the first busy week. Single habits don't.

              2/ The protocol:
              → One swap, just one
              → 30 days before adding the next
              → Let each easy win pull the next one along

              3/ Small and permanent beats big and abandoned.

              What swap would you start with?
            BODY
          },
          instagram_post: {
            title: "Start with one swap",
            hook: "Forget the lifestyle overhaul. Pick one swap and keep it for 30 days ↓",
            body: <<~BODY
              Big green resolutions die by February. Tiny swaps don't.

              ✦ One habit at a time — seriously, one
              ✦ 30 days before you add the next
              ✦ Easy wins pull harder ones along

              Small and permanent beats big and abandoned. 🌱

              What's your one swap this month?
            BODY
          }
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
          custom_instructions: "You are an ethical-living educator. Write informative, balanced scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Real cost of fast fashion",
          hook: "The $5 t-shirt isn't cheap. The cost just shows up somewhere else 🧵",
          body: <<~BODY
            1/ Fast fashion externalized its costs so well that consumers stopped seeing them.

            2/ Where the price actually goes:
            → Garment workers paid below a living wage
            → Landfills filling faster than they empty
            → Clothes designed to last one season

            3/ You don't have to buy expensive. You have to buy less.

            Buy less. Buy better. Wear it longer.

            When did you last repair something instead of replacing it?
          BODY
        },
        instagram_post: {
          title: "The real cost of a $5 t-shirt",
          hook: "That $5 t-shirt isn't cheap. You just can't see who paid the difference.",
          body: <<~BODY
            Fast fashion makes you feel like you're getting a deal.

            You're not. The cost gets transferred.

            Where the real price goes:

            ✦ Garment workers — underpaid in unsafe conditions
            ✦ The environment — landfills, water pollution, CO2
            ✦ Your wardrobe — clothes designed to fall apart in a season

            The fix isn't buying expensive. It's buying less.

            Buy less. Buy better. Wear it until it dies. Then repair it.

            When did you last repair instead of replace? 🧵
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "The 30-wears test",
            hook: "Before you buy it, ask one question: will I wear this 30 times?",
            body: <<~BODY
              Most impulse buys fail the question instantly.

              The 30-wears test works because:

              1. It filters trends from wardrobe staples
              2. It reframes price as cost-per-wear
              3. It takes five seconds at the till

              The most sustainable garment is the one you keep wearing.

              Would your last purchase pass?
            BODY
          },
          twitter_post: {
            title: "The 30-wears test",
            hook: "One question kills most impulse clothing buys: will I wear it 30 times? 🧵",
            body: <<~BODY
              1/ Most fast-fashion purchases get worn fewer than 10 times. Some never.

              2/ Why the test works:
              → Filters trends from staples
              → Turns price into cost-per-wear
              → Takes 5 seconds at the checkout

              3/ The most sustainable garment is the one you actually keep wearing.

              Would your last buy pass?
            BODY
          },
          instagram_post: {
            title: "Will you wear it 30 times?",
            hook: "One question before the checkout. It kills most impulse buys on the spot ↓",
            body: <<~BODY
              "Will I wear this 30 times?"

              ✦ Filters trends from true staples
              ✦ Reframes price as cost-per-wear
              ✦ Takes five seconds to ask

              The most sustainable piece in any wardrobe is the one that gets worn for years.

              Be honest: would your last purchase pass? 👇
            BODY
          }
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
          description: "A compact how-to on starting compost in an apartment, from bin choice to drop-off.",
          custom_instructions: "You are a sustainability advocate. Write warm, non-judgemental scripts."
        },
        linkedin_post: {
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
        },
        twitter_post: {
          title: "Apartment composting",
          hook: "\"I'd compost if I had a garden.\" You don't need one. 3 years in a studio flat 🧵",
          body: <<~BODY
            1/ The space excuse is real. But there are options that fit any kitchen.

            2/ What works without a garden:
            → Sealed countertop bin — no smell, no fuss
            → Local drop-off point or community garden (most cities have them)
            → Bokashi fermentation — works in the tiniest spaces, no odour

            3/ ~30% of household waste is organic. Composting is the highest-impact kitchen habit there is.

            No garden required.
          BODY
        },
        instagram_post: {
          title: "Composting without a garden",
          hook: "\"I'd compost if I had a backyard.\" I've been composting in a studio flat for 3 years. You have options.",
          body: <<~BODY
            The "I need a garden" excuse is the most common one I hear.

            It's also the easiest to solve.

            Apartment composting options that actually work:

            ✦ Sealed countertop bin — zero smell, surprisingly compact
            ✦ Local drop-off or community garden — most cities have them (check your council)
            ✦ Bokashi system — fermentation, not decomposition, works in the tiniest kitchen

            About a third of what goes in your bin is organic waste.

            Composting is one of the highest-impact habits you can build at home. 🌿

            Have you tried composting? What stopped you?
          BODY
        },
        script_posts: {
          linkedin_post: {
            title: "Your first week of composting",
            hook: "Want to start composting this week? Here's the whole setup:",
            body: <<~BODY
              Apartment composting takes one evening to set up.

              1. Any sealed container with a lid — fancy bins optional
              2. Find your nearest drop-off (your council's site lists them)
              3. Freeze scraps between drop-offs — zero smell, zero fuss

              That's the entire system. Start tonight.

              What's been stopping you?
            BODY
          },
          twitter_post: {
            title: "Compost setup in one evening",
            hook: "Apartment composting takes one evening to set up. Here's the whole thing 🧵",
            body: <<~BODY
              1/ You need: a sealed container, a freezer drawer, and your nearest drop-off point. That's it.

              2/ The flow:
              → Scraps go in the container
              → Container lives in the freezer (zero smell)
              → Weekly trip to the drop-off

              3/ No garden, no worms, no odour. Tonight is a fine night to start.
            BODY
          },
          instagram_post: {
            title: "Start composting tonight",
            hook: "No garden, no worms, no smell. Apartment composting in 3 steps ↓",
            body: <<~BODY
              The whole setup takes one evening:

              ✦ Any sealed container — the fancy bin is optional
              ✦ Freeze your scraps — zero smell between drop-offs
              ✦ Find your nearest drop-off point — your council lists them

              A third of your bin is organic waste. This is the easiest habit swap there is. 🌿

              What's stopped you from starting?
            BODY
          }
        }
      }
    ]
  }
]

# ------------------------------------------------------------------------------
# 3. Create the records
# ------------------------------------------------------------------------------
# Pairs each SEED_DATA post key with its model class so post creation below
# can loop instead of repeating three near-identical blocks per parent.
POST_TYPES = {
  linkedin_post:  LinkedinPost,
  twitter_post:   TwitterPost,
  instagram_post: InstagramPost
}.freeze

puts "Seeding #{SEED_DATA.size} creators and their content...\n\n"

SEED_DATA.each do |data|
  # --- User -------------------------------------------------------------------
  user = User.new(
    email: data[:email],
    password: "Str0ng!Password1",
    password_confirmation: "Str0ng!Password1"
  )
  user.skip_confirmation!
  user.save!
  puts "Created user: #{user.email}"

  # --- Creator (one per user; User has_one :creator) --------------------------
  creator = Creator.create!(data[:creator].merge(user: user))
  puts "  Created creator: #{creator.name} (#{creator.topic})"

  # --- Ideas → script → posts -------------------------------------------------
  # Idea belongs_to :user (there's no creator_id column), so each idea is tied
  # to the user we just created.
  #
  # Every idea gets one script, and BOTH nodes get one direct post per platform:
  #   Idea posts:   `idea: idea`     → idea_id set, script_id nil
  #   Script posts: `script: script` → script_id set, idea_id nil
  # Each post model validates exactly-one-parent plus uniqueness of idea_id and
  # script_id, so "3 direct posts" per node means one LinkedIn + one Twitter +
  # one Instagram — a fourth post of any platform would fail validation.
  data[:ideas].each do |idea_data|
    idea = Idea.create!(
      user: user,
      title: idea_data[:title],
      topic: idea_data[:topic],
      description: idea_data[:description]
    )
    puts "    Created idea: #{idea.title}"

    script = Script.create!(idea_data[:script].merge(idea: idea))
    puts "      Created script: #{script.title}"

    POST_TYPES.each do |key, klass|
      post = klass.create!(idea_data[key].merge(idea: idea))
      puts "      Created #{klass.name} (direct on idea): #{post.title}"
    end

    POST_TYPES.each do |key, klass|
      post = klass.create!(idea_data[:script_posts][key].merge(script: script))
      puts "      Created #{klass.name} (via script): #{post.title}"
    end
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
# 5. Sample Substack feed (idea-feed sources + cached posts)
# ------------------------------------------------------------------------------
# The fetch pipeline reads live RSS over the network, so seeding real sources
# would make `db:seed` slow and flaky (and dependent on a feed staying online).
# Instead we insert a few well-known publications plus cached posts *directly*,
# bypassing SubstackFetchService — enough to exercise the feed UI and the
# "use as inspiration" → generate_idea chat flow completely offline.
#
# fetched_at is stamped to "now" so the sources aren't stale: a Refresh won't
# try to re-fetch them over the network and overwrite this demo data.
#
# No explicit cleanup is needed — User.destroy_all above cascades through
# `has_many :substack_sources, dependent: :destroy` (and on to posts).
puts "Seeding sample Substack feed..."

demo_user = User.find_by!(email: "theo@contentflow.com")

SUBSTACK_FEED_DATA = [
  {
    source: {
      feed_url: "https://www.lennysnewsletter.com/feed",
      name:     "Lenny's Newsletter",
      handle:   "lennysnewsletter"
    },
    posts: [
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
  },
  {
    source: {
      feed_url: "https://stratechery.com/feed",
      name:     "Stratechery",
      handle:   "stratechery"
    },
    posts: [
      {
        title:   "Why bundling always wins eventually",
        author:  "Ben Thompson",
        summary: "Unbundled products win the early skirmishes, but history keeps rewarding whoever reassembles the bundle. A framework for spotting which side you're on.",
        published_at: 3.days.ago
      },
      {
        title:   "The aggregator's dilemma",
        author:  "Ben Thompson",
        summary: "Platforms grow by serving users better than suppliers can themselves — until the day suppliers start asking what they're owed.",
        published_at: 9.days.ago
      },
      {
        title:   "Regulation as a moat",
        author:  "Ben Thompson",
        summary: "Compliance costs that look like a burden from the outside can be the strongest competitive advantage from the inside.",
        published_at: 18.days.ago
      }
    ]
  },
  {
    source: {
      feed_url: "https://newsletter.pragmaticengineer.com/feed",
      name:     "The Pragmatic Engineer",
      handle:   "pragmaticengineer"
    },
    posts: [
      {
        title:   "What separates senior engineers from the rest",
        author:  "Gergely Orosz",
        summary: "It's rarely about writing more code faster. A look at the judgment calls, communication habits, and ownership that actually move the needle.",
        published_at: 1.day.ago
      },
      {
        title:   "Inside a real on-call rotation",
        author:  "Gergely Orosz",
        summary: "What actually happens when the pager goes off at 3am — and how the best teams turn incidents into better systems instead of better excuses.",
        published_at: 8.days.ago
      },
      {
        title:   "The return of the in-person interview",
        author:  "Gergely Orosz",
        summary: "After years of fully remote hiring loops, more companies are bringing candidates back on-site. What's driving the shift, and what it means for you.",
        published_at: 16.days.ago
      }
    ]
  }
].freeze

SUBSTACK_FEED_DATA.each do |feed_data|
  source   = demo_user.substack_sources.create!(feed_data[:source].merge(fetched_at: Time.current))
  base_url = source.feed_url.delete_suffix("/feed")

  feed_data[:posts].each_with_index do |post_data, i|
    source.substack_posts.create!(
      guid:         "seed-#{source.handle}-#{i}",
      url:          "#{base_url}/p/seed-#{i}",
      title:        post_data[:title],
      author:       post_data[:author],
      summary:      post_data[:summary],
      published_at: post_data[:published_at]
    )
  end

  puts "  Created source '#{source.name}' with #{source.substack_posts.count} cached posts"
end

puts ""

# ------------------------------------------------------------------------------
# 6. Summary
# ------------------------------------------------------------------------------
puts "Seeding complete!"
puts "  Users:            #{User.count}"
puts "  Creators:         #{Creator.count}"
puts "  Ideas:            #{Idea.count}"
puts "  Scripts:          #{Script.count}"
puts "  LinkedIn posts:   #{LinkedinPost.count}"
puts "  Twitter posts:    #{TwitterPost.count}"
puts "  Instagram posts:  #{InstagramPost.count}"
puts "  Chats:            #{Chat.count} (#{Chat.where.not(chattable_id: nil).count} owned, #{Chat.where(chattable_id: nil).count} standalone)"
puts "  Messages:         #{Message.count}"
puts "  Substack sources: #{SubstackSource.count}"
puts "  Substack posts:   #{SubstackPost.count}"

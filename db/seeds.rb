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
    linkedin_post = LinkedinPost.create!(idea_data[:linkedin_post].merge(script: script))
    puts "      Created LinkedIn post: #{linkedin_post.title}"

    # One Twitter post per script.
    twitter_post = TwitterPost.create!(idea_data[:twitter_post].merge(script: script))
    puts "      Created Twitter post: #{twitter_post.title}"

    # One Instagram post per script.
    instagram_post = InstagramPost.create!(idea_data[:instagram_post].merge(script: script))
    puts "      Created Instagram post: #{instagram_post.title}"
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

demo_user = User.find_by!(email: "demo@contentflow.com")

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

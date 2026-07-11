-- ═══════════════════════════════════════════════════════════
-- 💬  STEP B — DIALOGUE DATA MODULE  (The Brain)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  ReplicatedStorage ▸ DialogueData  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   EVERY word the NPC says + every option lives here.
--   This is a branching dialogue TREE with RANDOM answer pools,
--   so the NPC has VARIETY (says something different each time).
--   Edit text here → no code needed. Super customizable! 🎨
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("DialogueData"); if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "DialogueData"
m.Parent = RS
m.Source = [====[
-- ═══════════════════════════════════════════════════════════
-- 💬  DIALOGUE DATA  —  ModuleScript  |  ReplicatedStorage
-- The whole conversation lives here. Edit freely — no code needed!
-- ═══════════════════════════════════════════════════════════

local DialogueData = {}

--[[
═══════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: NPC IDENTITY + DETECTION
═══════════════════════════════════════════════════════════
  NPCName        : shown above his head + in the UI
  NPCSearchNames : the model name(s) to look for (your NPC = "ShopDealler")
  TalkDistance   : how close (in studs) before he starts talking
────────────────────────────────────────────────────────────
]]
DialogueData.NPCName        = "Shopkeeper"
DialogueData.NPCSearchNames = { "ShopDealler", "Shopkeeper", "ShopNPC", "Merchant" }
DialogueData.TalkDistance   = 12

--[[ ───────────────────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: OVERHEAD CHAT BUBBLE (text above NPC)
   The bubble POPS IN with a bounce whenever he answers.
   Set Enabled = false to turn the floating text off.
─────────────────────────────────────────────────────── ]]
DialogueData.Overhead = {
	Enabled      = true,                          -- show floating text above NPC?
	OffsetY      = 2.4,                           -- how high above the head (studs)
	MaxDistance  = 70,                            -- hide if camera is farther than this
	BubbleColor  = Color3.fromRGB(22, 22, 28),    -- bubble background
	TextColor    = Color3.fromRGB(245, 245, 250), -- spoken text color
	NameColor    = Color3.fromRGB(255, 215, 0),   -- NPC name + outline color
	TextSize     = 19,                            -- size of spoken text
	PopTime      = 0.35,                          -- bounce-in duration (seconds)
	AutoClearTime = 6,                            -- bubble fades out after this long
}

--[[ ───────────────────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: FAREWELL POOL (said when you leave)
   Random each time → variety!  {table of strings}
─────────────────────────────────────────────────────── ]]
DialogueData.Farewells = {
	"Farewell, traveler! Come back anytime.",
	"Safe travels, friend!",
	"May fortune favor your rolls!",
	"Until we meet again!",
}

--[[ ───────────────────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: AUTO-SHOP NODE
   The shop menu is BUILT AUTOMATICALLY from ShopData.Items.
   You don't list potions here — just control the flavor text.
   NodeKey must match the Goto used in a node's Options below.
─────────────────────────────────────────────────────── ]]
DialogueData.AutoShop = {
	Enabled  = true,
	NodeKey  = "Shop",        -- must match a Goto="Shop" option
	BrowseLine = {
		"Here's what I've got for sale. Choose wisely!",
		"Take your pick — these are my finest brews.",
		"Everything's made fresh today. What'll it be?",
	},
}

--[[ ════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: THE DIALOGUE TREE (branching!)
═══════════════════════════════════════════════════════════

HOW IT WORKS:
  • Each NODE has a random pool of Lines (variety!) + a list of Options.
  • An option either:
        Goto   = "NodeName"   → jump to that node
        Action = "OpenShop"   → open the shop window
        Action = "Close"      → end the conversation
  • The first option's node (Root) is shown when you walk up.

HOW TO ADD A NEW BRANCH:
  1. Add a new node below, e.g.  MyTopic = { Lines={...}, Options={...} }
  2. Add an option somewhere that says  { Text="...", Goto="MyTopic" }
  3. Done! The NPC now has a new thing to talk about. ✨
═══════════════════════════════════════════════════════════ ]]
DialogueData.Nodes = {

	-- 🏠 ROOT (the greeting menu)
	Root = {
		Lines = {
			"Ah, a traveler! Welcome to my little corner of the world. How can I help?",
			"Well met, friend! What brings you to my shop today?",
			"Ooh, a customer! Take a look around — I've got wonders to share.",
			"You again? Ha! Good to see your face. What'll it be?",
		},
		Options = {
			{ Text = "What do you sell?",     Goto = "Shop"   },
			{ Text = "Tell me your story",    Goto = "Story"  },
			{ Text = "Any rolling tips?",     Goto = "Tips"   },
			{ Text = "How's the weather?",    Goto = "Weather" },
			{ Text = "Nevermind",             Action = "Close" },
		},
	},

	-- 📖 STORY
	Story = {
		Lines = {
			"Long ago, I was a gambler — chasing the rarest auras across the land...",
			"I've held auras that bend reality itself. Genesis, Eclipse... all of them.",
			"Every potion I brew carries a story. Care to hear one?",
		},
		Options = {
			{ Text = "Tell me about Genesis", Goto = "Genesis" },
			{ Text = "◀ Back",                Goto = "Root"    },
			{ Text = "Goodbye",               Action = "Close" },
		},
	},
	Genesis = {
		Lines = {
			"Genesis... the aura of beginnings. It's said to appear only to the truly fortunate.",
			"When Genesis rolls, legend says the very sky holds its breath.",
		},
		Options = {
			{ Text = "◀ Back to story", Goto = "Story" },
			{ Text = "◀ Back to menu",  Goto = "Root"  },
		},
	},

	-- 💡 TIPS
	Tips = {
		Lines = {
			"Tip: Rare auras come with patience — and maybe a little luck potion, eh?",
			"Tip: Bad weather can MUTATE your auras into something even rarer!",
			"Tip: Equip your rarest aura to show off your luck to everyone.",
			"Tip: Coins stack up faster with a coin boost. Just sayin'.",
		},
		Options = {
			{ Text = "Buy a luck potion", Action = "OpenShop" },
			{ Text = "◀ Back",            Goto = "Root"        },
			{ Text = "Goodbye",           Action = "Close"     },
		},
	},

	-- 🌦️ WEATHER  (DYNAMIC — comments on the ACTUAL current weather!)
	Weather = {
		WeatherAware = true,   -- picks a line based on live weather
		WeatherLines = {
			Clear          = { "Clear skies and calm winds — a fine day to roll!", "Not a cloud in sight. Perfect hunting weather." },
			Sandstorm      = { "Ugh, the sandstorm's raging. Watch for Sandy mutations!", "The sand stings... but it brings rare sandy auras." },
			["Blood Moon"] = { "The Blood Moon... stay vigilant. Cursed things walk tonight.", "I'd stay inside if I were you. The curse is strong." },
			["Cosmic Rift"]= { "A Cosmic Rift! Cosmic mutations await the bold!", "The stars are tearing open — cosmic auras are near!" },
		},
		Fallback = { "Strange skies today... I can't quite read them.", "The weather's acting odd. Be careful out there." },
		Options = {
			{ Text = "◀ Back",  Goto = "Root"    },
			{ Text = "Goodbye", Action = "Close" },
		},
	},

	-- ➕ ADD YOUR OWN NODES HERE! (see HOW TO ADD A NEW BRANCH above)
}

return DialogueData
]====]

print("✅ STEP B done! DialogueData module created in ReplicatedStorage.")
print("   💬 Nodes: Root, Story, Genesis, Tips, Weather(+Shop auto) — fully editable!")

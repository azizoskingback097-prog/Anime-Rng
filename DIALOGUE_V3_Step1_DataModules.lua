-- ═══════════════════════════════════════════════════════════
-- 📦  DIALOGUE V3 — STEP 1: DATA MODULES  (ShopData + DialogueData)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates BOTH modules in ONE paste so you can't forget one!
--   • ReplicatedStorage ▸ ShopData     (potions — auto-detected by NPC)
--   • ReplicatedStorage ▸ DialogueData (every word + option the NPC says)
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")

-- ─────────────────────────────────────────────────────────
-- 🛒  ShopData  (edit potions here → NPC offers them automatically)
-- ─────────────────────────────────────────────────────────
local oldShop = RS:FindFirstChild("ShopData"); if oldShop then oldShop:Destroy() end
task.wait(0.1)
local shopMod = Instance.new("ModuleScript")
shopMod.Name = "ShopData"
shopMod.Parent = RS
shopMod.Source = [====[
local ShopData = {}

--[[
📌 CUSTOMIZABLE SECTION: SHOP ITEMS (potions, boosts)
   Add a block here → it shows up in the NPC's shop automatically!
   Fields: DisplayName, Description, Icon, Color, Price, Duration,
           Type ("LuckMultiplier" or "CoinMultiplier"), Value, BuyLine
]]--
ShopData.Items = {
	LuckPotion = {
		DisplayName = "x2 Luck Potion",
		Description = "Doubles your luck while rolling for 5 minutes.",
		Icon = "🍀",
		Color = Color3.fromRGB(120, 200, 120),
		Price = 100000,
		Duration = 300,
		Type = "LuckMultiplier",
		Value = 2.0,
		BuyLine = { "Bottoms up! May the rare auras favor you! 🍀", "Luck be a lady tonight!" },
	},
	CoinBoost = {
		DisplayName = "x2 Coins Boost",
		Description = "Doubles every coin you earn for 5 minutes.",
		Icon = "💰",
		Color = Color3.fromRGB(255, 200, 80),
		Price = 200000,
		Duration = 300,
		Type = "CoinMultiplier",
		Value = 2.0,
		BuyLine = { "Spend it wisely, friend! 💰", "Don't spend it all at once!" },
	},
	-- ➕ ADD MORE POTIONS BELOW — they show up automatically!
}

return ShopData
]====]
print("✅ ShopData module created.")

-- ─────────────────────────────────────────────────────────
-- 💬  DialogueData  (every word + option the NPC says)
-- ─────────────────────────────────────────────────────────
local oldDial = RS:FindFirstChild("DialogueData"); if oldDial then oldDial:Destroy() end
task.wait(0.1)
local dialMod = Instance.new("ModuleScript")
dialMod.Name = "DialogueData"
dialMod.Parent = RS
dialMod.Source = [====[
local DialogueData = {}

-- 📌 NPC IDENTITY + DETECTION
DialogueData.NPCName        = "Shopkeeper"
DialogueData.NPCSearchNames = { "ShopDealler", "Shopkeeper", "ShopNPC", "Merchant" }
DialogueData.TalkDistance   = 12

-- 📌 PROXIMITY PROMPT (the "Press E" prompt above the NPC)
DialogueData.Prompt = {
	Enabled            = true,
	ActionText         = "Talk",          -- the verb shown
	KeyboardKeyCode    = "E",             -- the key (E)
	HoldDuration       = 0,               -- 0 = instant tap
	MaxActivationDistance = 12,           -- how close before the prompt shows
}

-- 📌 OVERHEAD CHAT BUBBLE (text above NPC + bouncy pop)
DialogueData.Overhead = {
	Enabled      = true,
	OffsetY      = 2.4,
	MaxDistance  = 70,
	BubbleColor  = Color3.fromRGB(22, 22, 28),
	TextColor    = Color3.fromRGB(245, 245, 250),
	NameColor    = Color3.fromRGB(255, 215, 0),
	TextSize     = 19,
	PopTime      = 0.35,
	AutoClearTime = 6,
}

-- 📌 FAREWELL POOL (random each time → variety)
DialogueData.Farewells = {
	"Farewell, traveler! Come back anytime.",
	"Safe travels, friend!",
	"May fortune favor your rolls!",
	"Until we meet again!",
}

-- 📌 AUTO-SHOP NODE (built automatically from ShopData — don't list potions here)
DialogueData.AutoShop = {
	Enabled  = true,
	NodeKey  = "Shop",
	BrowseLine = {
		"Here's what I've got for sale. Choose wisely!",
		"Take your pick — these are my finest brews.",
		"Everything's made fresh today. What'll it be?",
	},
}

-- 📌 THE DIALOGUE TREE (branching! each node has random Lines + Options)
--   Option fields: Goto="NodeName" | Action="OpenShop"/"Close" | Color=Color3
DialogueData.Nodes = {
	Root = {
		Lines = {
			"Ah, a traveler! Welcome to my little corner of the world. How can I help?",
			"Well met, friend! What brings you to my shop today?",
			"Ooh, a customer! Take a look around — I've got wonders to share.",
			"You again? Ha! Good to see your face. What'll it be?",
		},
		Options = {
			{ Text = "What do you sell?",  Goto = "Shop"    },
			{ Text = "Tell me your story", Goto = "Story"   },
			{ Text = "Any rolling tips?",  Goto = "Tips"    },
			{ Text = "How's the weather?", Goto = "Weather" },
			{ Text = "Nevermind",          Action = "Close" },
		},
	},
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
	Weather = {
		WeatherAware = true,
		WeatherLines = {
			Clear           = { "Clear skies and calm winds — a fine day to roll!", "Not a cloud in sight. Perfect hunting weather." },
			Sandstorm       = { "Ugh, the sandstorm's raging. Watch for Sandy mutations!", "The sand stings... but it brings rare sandy auras." },
			["Blood Moon"]  = { "The Blood Moon... stay vigilant. Cursed things walk tonight.", "I'd stay inside if I were you. The curse is strong." },
			["Cosmic Rift"] = { "A Cosmic Rift! Cosmic mutations await the bold!", "The stars are tearing open — cosmic auras are near!" },
		},
		Fallback = { "Strange skies today... I can't quite read them.", "The weather's acting odd. Be careful out there." },
		Options = {
			{ Text = "◀ Back",  Goto = "Root"    },
			{ Text = "Goodbye", Action = "Close" },
		},
	},
}

return DialogueData
]====]
print("✅ DialogueData module created.")

print("✅✅ STEP 1 COMPLETE! Both data modules are in ReplicatedStorage.")
print("   Now run Step 2 (NPCShopServer) and Step 3 (DialogueUI).")

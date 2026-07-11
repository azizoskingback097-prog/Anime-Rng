-- ═══════════════════════════════════════════════════════════
-- 🤖  DIALOGUE V3 — STEP 2: NPC SHOP SERVER  (ProximityPrompt + Relay)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  ServerScriptService ▸ NPCShopServer  (Script)
-- ═══════════════════════════════════════════════════════════
-- WHAT THIS DOES:
--   1. Auto-scans for the ShopDealler NPC (works even if map loads late).
--   2. Creates a SERVER-SIDE ProximityPrompt (press E to talk) — the
--      reliable way (prompts in LocalScripts are buggy).
--   3. When you press E → fires DialogueEvent to your client → opens UI.
--   4. Relays "open shop" requests from the dialogue to the ShopUI.
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local old = SSS:FindFirstChild("NPCShopServer"); if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("Script")
s.Name = "NPCShopServer"
s.Parent = SSS
s.Source = [====[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")

-- 🔌 Ensure remotes exist (DialogueEvent may already be there)
local function ensureRemote(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remotes
		print("🔌 Created missing remote: " .. name)
	end
	return r
end
local DialogueEvent = ensureRemote("DialogueEvent")
local ShopOpenEvent = ensureRemote("ShopOpenEvent")

-- 📖 Read NPC config from DialogueData (guarded — won't crash if missing)
local NPC_NAME = "Shopkeeper"
local SEARCH_NAMES = { "ShopDealler", "Shopkeeper", "ShopNPC", "Merchant" }
local PROMPT_CFG = { ActionText = "Talk", Key = "E", Hold = 0, Distance = 12 }
pcall(function()
	local DialogueData = require(ReplicatedStorage:WaitForChild("DialogueData", 10))
	if DialogueData then
		NPC_NAME = DialogueData.NPCName or NPC_NAME
		SEARCH_NAMES = DialogueData.NPCSearchNames or SEARCH_NAMES
		local p = DialogueData.Prompt
		if p then PROMPT_CFG = { ActionText = p.ActionText or "Talk", Key = p.KeyboardKeyCode or "E", Hold = p.HoldDuration or 0, Distance = p.MaxActivationDistance or 12 } end
	end
end)

print("🤖 NPCShopServer started — searching for NPC...")

-- 🎯 Attach a ProximityPrompt to the NPC
local function setupPrompt(npc)
	-- find a good part to attach the prompt to
	local attach = npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChild("Torso")
		or npc:FindFirstChild("UpperTorso")
		or npc:FindFirstChild("Head")
	if not attach then
		for _, c in ipairs(npc:GetDescendants()) do
			if c:IsA("BasePart") then attach = c break end
		end
	end
	if not attach then
		warn("❌ NPC found but has no part to attach the prompt to!")
		return false
	end

	-- remove old prompts on that part
	for _, c in ipairs(attach:GetChildren()) do
		if c:IsA("ProximityPrompt") then c:Destroy() end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = PROMPT_CFG.ActionText
	prompt.ObjectText = NPC_NAME
	prompt.KeyboardKeyCode = Enum.KeyCode[PROMPT_CFG.Key] or Enum.KeyCode.E
	prompt.HoldDuration = PROMPT_CFG.Hold
	prompt.MaxActivationDistance = PROMPT_CFG.Distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = attach

	-- press E → tell that player's client to open/toggle the dialogue
	prompt.Triggered:Connect(function(player)
		DialogueEvent:FireClient(player)
	end)

	print("✅ ProximityPrompt (E) attached to NPC: " .. npc:GetFullName())
	return true
end

-- 🔎 AUTO-SCAN for the NPC (keeps trying until the map loads it)
task.spawn(function()
	local done = false
	local ticks = 0
	while not done do
		for _, name in ipairs(SEARCH_NAMES) do
			local map = Workspace:FindFirstChild("Map")
			local npc = (map and map:FindFirstChild(name, true)) or Workspace:FindFirstChild(name, true)
			if npc then
				done = setupPrompt(npc)
				if done then break end
			end
		end
		if done then break end
		ticks = ticks + 1
		if ticks % 5 == 1 then print("🔍 Still searching for NPC... (names: " .. table.concat(SEARCH_NAMES, ", ") .. ")") end
		task.wait(1)
	end
end)

-- 🔁 RELAY: dialogue client asks to open shop → tell ShopUI to open
DialogueEvent.OnServerEvent:Connect(function(player, action)
	if action == "OpenShop" then
		ShopOpenEvent:FireClient(player)
	end
end)

print("✅ NPCShopServer ready! (ProximityPrompt + Shop relay active)")
]====]

print("✅ STEP 2 done! NPCShopServer (ProximityPrompt) created in ServerScriptService.")

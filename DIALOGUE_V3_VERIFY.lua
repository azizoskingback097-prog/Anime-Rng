-- ═══════════════════════════════════════════════════════════
-- 🔍  DIALOGUE V3 — VERIFY SETUP  (run ANYTIME to check health)
-- Paste in:  View ▸ Command Bar   →   Enter
-- ═══════════════════════════════════════════════════════════
-- Read-only diagnostic. Tells you exactly what's present/missing.
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local WS  = game:GetService("Workspace")

local pass, fail = 0, 0
local function check(label, cond, fix)
	if cond then pass = pass + 1; print("✅ " .. label)
	else fail = fail + 1; print("❌ " .. label .. "  → FIX: " .. (fix or "see guide")) end
end

print("═══════════════════════════════════════════")
print("🔍  DIALOGUE V3 — SETUP CHECK")
print("═══════════════════════════════════════════")

-- Modules
check("ShopData module exists",     RS:FindFirstChild("ShopData") ~= nil,     "run Step 1")
check("DialogueData module exists", RS:FindFirstChild("DialogueData") ~= nil, "run Step 1")

-- Scripts
check("NPCShopServer script exists",  SSS:FindFirstChild("NPCShopServer") ~= nil,  "run Step 2")
check("DialogueUI script exists",     SPS:FindFirstChild("DialogueUI") ~= nil,    "run Step 3")

-- Remotes
local remotes = RS:FindFirstChild("Remotes")
check("Remotes folder exists", remotes ~= nil, "your GameServer should create it")
if remotes then
	check("DialogueEvent remote exists",        remotes:FindFirstChild("DialogueEvent") ~= nil,        "run Step 2")
	check("ShopOpenEvent remote exists",        remotes:FindFirstChild("ShopOpenEvent") ~= nil,        "your GameServer should create it")
	check("PurchaseItemFunction remote exists", remotes:FindFirstChild("PurchaseItemFunction") ~= nil, "your GameServer should create it")
end

-- NPC
local npc = nil
for _, name in ipairs({ "ShopDealler", "Shopkeeper", "Merchant" }) do
	local map = WS:FindFirstChild("Map")
	npc = (map and map:FindFirstChild(name, true)) or WS:FindFirstChild(name, true)
	if npc then break end
end
check("NPC model found in Workspace", npc ~= nil, "make sure NPC is named 'ShopDealler' (or add to NPCSearchNames)")
if npc then
	print("   ↳ NPC path: " .. npc:GetFullName())
	-- prompt?
	local hasPrompt = false
	for _, d in ipairs(npc:GetDescendants()) do
		if d:IsA("ProximityPrompt") then hasPrompt = true; break end
	end
	check("ProximityPrompt attached to NPC", hasPrompt, "Step 2 should add it on Play — re-run Step 2 if not")
end

print("═══════════════════════════════════════════")
print(string.format("RESULT: %d passed, %d failed", pass, fail))
if fail == 0 then print("🎉 ALL GOOD! Press Play and press E near the NPC.") end
print("═══════════════════════════════════════════")

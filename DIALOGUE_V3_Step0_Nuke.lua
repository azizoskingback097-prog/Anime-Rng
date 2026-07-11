-- ═══════════════════════════════════════════════════════════
-- 💣  DIALOGUE V3 — STEP 0: NUKE OLD STUFF  (run FIRST)
-- Paste in:  View ▸ Command Bar   →   Enter
-- ═══════════════════════════════════════════════════════════
-- Wipes every old dialogue piece so V3 starts clean. Safe to re-run.
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS  = game:GetService("ReplicatedStorage")
local WS  = game:GetService("Workspace")

print("💣 Nuking old dialogue (V3 clean slate)...")

-- 1) Nuke the broken animation ID that freezes characters
local brokenID = "1852625856"
for _, o in ipairs(game:GetDescendants()) do
	if o:IsA("Animation") and string.find(o.AnimationId, brokenID) then
		print("🗑️ Nuked broken animation: " .. o:GetFullName())
		o:Destroy()
	end
end

-- 2) Remove old server / client scripts
local oldS = SSS:FindFirstChild("NPCShopServer");  if oldS then oldS:Destroy(); print("🗑️ Removed old NPCShopServer") end
local oldC = SPS:FindFirstChild("DialogueUI");     if oldC then oldC:Destroy(); print("🗑️ Removed old DialogueUI") end
-- (keep the data modules — V3 will overwrite them anyway)

-- 3) Clean any leftover prompt / bubble on the NPC
local function cleanNPC()
	local map = WS:FindFirstChild("Map")
	for _, name in ipairs({ "ShopDealler", "Shopkeeper", "Merchant" }) do
		local npc = (map and map:FindFirstChild(name, true)) or WS:FindFirstChild(name, true)
		if npc then
			for _, part in ipairs(npc:GetDescendants()) do
				if part:IsA("BasePart") then
					for _, c in ipairs(part:GetChildren()) do
						if c:IsA("ProximityPrompt") or c.Name == "NPCDialogueBubble" or c.Name == "TalkPrompt" then
							c:Destroy()
						end
					end
				end
			end
		end
	end
end
cleanNPC()

print("✅ STEP 0 complete! Now run Step 1, 2, 3 in order.")

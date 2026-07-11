-- ═══════════════════════════════════════════════════════════
-- 💣  STEP 0 — NUKE OLD DIALOGUE  (run this FIRST)
-- Paste in:  View ▸ Command Bar   →   Enter
-- ═══════════════════════════════════════════════════════════
-- 📝 Wipes every old dialogue piece so the new V2 system is clean.
--    Safe to run more than once.
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS  = game:GetService("ReplicatedStorage")
local WS  = game:GetService("Workspace")

print("💣 Nuking old dialogue...")

-- 1) Nuke the broken animation ID that freezes characters
local brokenID = "1852625856"
for _, o in ipairs(game:GetDescendants()) do
	if o:IsA("Animation") and string.find(o.AnimationId, brokenID) then
		print("🗑️ Nuked broken animation: " .. o:GetFullName())
		o:Destroy()
	end
end

-- 2) Remove old server / client / module scripts
for _, n in ipairs({ "NPCShopServer" }) do
	local x = SSS:FindFirstChild(n); if x then x:Destroy(); print("🗑️ Removed " .. n) end
end
for _, n in ipairs({ "DialogueUI" }) do
	local x = SPS:FindFirstChild(n); if x then x:Destroy(); print("🗑️ Removed " .. n) end
end
for _, n in ipairs({ "DialogueData", "ShopData" }) do
	local x = RS:FindFirstChild(n); if x then x:Destroy(); print("🗑️ Removed " .. n) end
end

-- 3) Clean any leftover bubble / prompt on the NPC
local map = WS:FindFirstChild("Map")
local npc = (map and map:FindFirstChild("ShopDealler", true)) or WS:FindFirstChild("ShopDealler", true)
if npc then
	local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
	if head then
		for _, n in ipairs({ "NPCDialogueBubble", "DialogueGui" }) do
			local x = head:FindFirstChild(n); if x then x:Destroy(); print("🗑️ Removed NPC " .. n) end
		end
		local p = head:FindFirstChildOfClass("ProximityPrompt")
		if p then p:Destroy(); print("🗑️ Removed ProximityPrompt") end
	end
end

print("✅ STEP 0 complete! Old dialogue nuked. Now run Steps A → D.")

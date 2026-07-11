-- ═══════════════════════════════════════════════════════════
-- 💣 STEP 1: COMPLETE NUKE OF OLD DIALOGUE & BROKEN ANIMS
-- ═══════════════════════════════════════════════════════════
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Workspace = game:GetService("Workspace")
local brokenID = "1852625856"

print("💣 Nuking old data...")

-- 1. Delete Broken Animations
for _, obj in ipairs(game:GetDescendants()) do
	if obj:IsA("Animation") and string.find(obj.AnimationId, brokenID) then
		print("🗑️ Nuked broken animation: " .. obj:GetFullName())
		obj:Destroy()
	end
end

-- 2. Delete Server & Client Dialogue Scripts
local oldS = SSS:FindFirstChild("NPCShopServer"); if oldS then oldS:Destroy() end
local oldC = SPS:FindFirstChild("DialogueUI"); if oldC then oldC:Destroy() end

-- 3. Clean NPC
local map = Workspace:FindFirstChild("Map")
local npc = map and map:FindFirstChild("ShopDealler", true) or Workspace:FindFirstChild("ShopDealler", true)
if npc then
	local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
	if head then
		local oldBB = head:FindFirstChild("DialogueGui"); if oldBB then oldBB:Destroy() end
		local oldPrompt = head:FindFirstChildOfClass("ProximityPrompt"); if oldPrompt then oldPrompt:Destroy() end
	end
end

print("✅ Step 1 Complete! Everything is nuked. Proceed to Step 2.")

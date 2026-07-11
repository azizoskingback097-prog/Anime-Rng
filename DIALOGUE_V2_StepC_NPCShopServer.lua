-- ═══════════════════════════════════════════════════════════
-- 🤖  STEP C — NPC SHOP SERVER  (Auto-Scan + Shop Relay)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  ServerScriptService ▸ NPCShopServer  (Script)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES (tiny + bulletproof):
--   1. Auto-scans for the ShopDealler NPC and prints when found.
--   2. RELAYS the "open shop" signal so the dialogue can open the shop
--      (this fixes the old bug where the client tried to FireClient).
--   No ProximityPrompt — the client uses a Heartbeat distance check.
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
local ShopOpenEvent     = Remotes:WaitForChild("ShopOpenEvent")

print("🤖 NPCShopServer started — auto-scanning for NPC...")

-- 🔎 AUTO-SCAN: find the NPC even if the map loads late
task.spawn(function()
	local found = false
	while not found do
		local map = Workspace:FindFirstChild("Map")
		local npc = (map and map:FindFirstChild("ShopDealler", true)) or Workspace:FindFirstChild("ShopDealler", true)
		if npc then
			found = true
			print("✅ NPCShopServer found NPC: " .. npc:GetFullName())
		end
		task.wait(1)
	end
end)

-- 🔁 RELAY: client says "open my shop" → we tell that client's ShopUI to open
ShopOpenEvent.OnServerEvent:Connect(function(player)
	ShopOpenEvent:FireClient(player)
end)

print("✅ NPCShopServer ready! (Shop-open relay active)")
]====]

print("✅ STEP C done! NPCShopServer created in ServerScriptService.")

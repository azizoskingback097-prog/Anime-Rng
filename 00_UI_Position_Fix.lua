-- ═══════════════════════════════════════════════════════════
-- 📍 UI POSITION FIX (Roll = Center, Inventory = Center-Right)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- Fix Roll Button
local roll = SPS:FindFirstChild("RollUI")
if roll then
	local src = roll.Source
	-- Replace the old position logic with centered position
	src = src:gsub(
		'button.Position = UDim2.fromScale%(0.81,0.87%)',
		'button.AnchorPoint = Vector2.new(0.5, 0.5)\nbutton.Position = UDim2.fromScale(0.5, 0.85)'
	)
	roll.Source = src
	print("✅ Roll Button moved to Center!")
else
	print("⚠️ RollUI not found!")
end

-- Fix Inventory Button
local inv = SPS:FindFirstChild("InventoryUI")
if inv then
	local src = inv.Source
	-- Replace the old position logic with center-right position
	src = src:gsub(
		'openBtn.Position = UDim2.fromScale%(0.81,0.76%)',
		'openBtn.AnchorPoint = Vector2.new(0.5, 0.5)\nopenBtn.Position = UDim2.fromScale(0.85, 0.85)'
	)
	inv.Source = src
	print("✅ Inventory Button moved to Center-Right!")
else
	print("⚠️ InventoryUI not found!")
end

print("🎮 Press Play to see the new UI layout!")

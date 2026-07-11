-- ═══════════════════════════════════════════════════════════
-- 🔗 CONNECT PREMIUM VFX — maps the 3 new VFX to auras for testing
-- ═══════════════════════════════════════════════════════════
-- Run AFTER the Premium VFX Pack command bar!
-- This updates the AuraMap so you can test the new VFX right away.
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local VFXData = RS:FindFirstChild("VFXData")

if not VFXData then
	warn("❌ VFXData not found!")
	return
end

local source = VFXData.Source

-- Update the AuraMap to connect new premium VFX to auras
-- This replaces specific lines in the AuraMap

-- 1. Inferno Storm → Nine-Tails (fire aura gets the epic fire tornado!)
source = source:gsub(
	'%["Nine%-Tails"%]%s*=%s*"[^"]*"',
	'["Nine-Tails"] = "Inferno Storm"'
)

-- 2. Celestial Aura → Genesis (the rarest gets the most divine effect!)
source = source:gsub(
	'%["Genesis"%]%s*=%s*"[^"]*"',
	'["Genesis"] = "Celestial Aura"'
)

-- 3. Void Rift → Cursed Energy (dark cursed energy gets the void effect!)
source = source:gsub(
	'%["Cursed Energy"%]%s*=%s*"[^"]*"',
	'["Cursed Energy"] = "Void Rift"'
)

VFXData.Source = source

print("══════════════════════════════════════")
print("🔗 PREMIUM VFX CONNECTED!")
print("══════════════════════════════════════")
print("🔥 Nine-Tails      → Inferno Storm")
print("✨ Genesis         → Celestial Aura")
print("🌌 Cursed Energy   → Void Rift")
print("══════════════════════════════════════")
print("🎮 TEST NOW:")
print("   1. Press Play")
print("   2. Admin → Give Aura: Nine-Tails")
print("   3. Inventory → Equip Nine-Tails")
print("   4. See the Inferno Storm VFX! 🔥")
print("══════════════════════════════════════")
print("📖 Read VFX_GUIDE.md to learn how to make your own!")
print("══════════════════════════════════════")

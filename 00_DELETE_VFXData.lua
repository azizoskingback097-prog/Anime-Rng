-- ═══════════════════════════════════════════════
-- 🗑️ DELETE VFXData — it keeps getting corrupted!
-- ═══════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- This REMOVES VFXData so it can't cause errors.
-- The new VFXClient doesn't need it anymore!
-- ═══════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("VFXData")
if old then
	print("🗑️ Deleting broken VFXData...")
	old:Destroy()
	print("✅ VFXData deleted!")
else
	print("ℹ️ VFXData not found (already deleted)")
end

-- Make sure CustomVFX folder exists
local cvx = RS:FindFirstChild("CustomVFX")
if not cvx then
	cvx = Instance.new("Folder")
	cvx.Name = "CustomVFX"
	cvx.Parent = RS
	print("📁 Created CustomVFX folder")
end

print("✅ Done! Now paste the VFXClient fix.")

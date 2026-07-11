-- ═══════════════════════════════════════════════════════════
-- 🛠️  ADMIN PANEL  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- A testing panel for ADMINS only. If you're not on the admin list
-- in RollServer, the button never appears. If you are, you get:
--   • Give yourself ANY aura (pick from the list)
--   • Set your LUCK multiplier (higher = rarer pulls)
--   • Give a guaranteed RARE aura (for testing visuals)
--   • Clear your whole inventory
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Button pos/size → OPEN_BUTTON_POS / OPEN_BUTTON_SIZE
--   • Colors          → ⚙️ UI THEME block
--   • (Admin list is in RollServer → ADMIN_IDS)
--
-- 🔗 RELATED SCRIPTS:
--   • RollServer  → answers AdminFunction (checks ADMIN_IDS)
--   • AuraDatabase → fills the "give aura" list
--   • InventoryUI → open it after giving an aura to see results
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Add a "Mass Roll x100" button that calls RollFunction 100 times
--   in a loop to test rarity rates fast.
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local AuraData      = require(ReplicatedStorage:WaitForChild("AuraDatabase"))

-- ⚙️ ─────────────────── CUSTOMIZE: UI THEME ───────────────────
local BG_COLOR      = Color3.fromRGB(40, 25, 30)
local TEXT_COLOR    = Color3.fromRGB(255, 255, 255)
local BUTTON_COLOR  = Color3.fromRGB(200, 60, 80)
local FIELD_COLOR   = Color3.fromRGB(60, 60, 75)
-- ⚙️ ─────────────────── CUSTOMIZE: LAYOUT ─────────────────────
local OPEN_BUTTON_POS  = UDim2.fromScale(0.81, 0.68)
local OPEN_BUTTON_SIZE = UDim2.fromScale(0.16, 0.06)
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

-- ────────────── check if this player is an admin ──────────────
-- The server returns true/false. If not admin, we do nothing.
local amAdmin = AdminFunction:InvokeServer("IsAdmin")
if not amAdmin then
	return  -- stop here — no admin UI is created for non-admins
end

-- ────────────── build the UI ──────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanelGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = OPEN_BUTTON_SIZE
openBtn.Position = OPEN_BUTTON_POS
openBtn.Text = "🛠️  Admin"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextScaled = true
openBtn.BackgroundColor3 = BUTTON_COLOR
openBtn.TextColor3 = TEXT_COLOR
local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15, 0); obCorner.Parent = openBtn
openBtn.Parent = gui

-- window
local window = Instance.new("Frame")
window.Size = UDim2.fromScale(0.35, 0.7)
window.Position = UDim2.fromScale(0.32, 0.15)
window.BackgroundColor3 = BG_COLOR
window.Visible = false
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04, 0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = BUTTON_COLOR; wStroke.Parent = window
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.07)
title.Position = UDim2.fromScale(0, 0.02)
title.Text = "🛠️  Admin Panel"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.BackgroundTransparency = 1
title.TextColor3 = TEXT_COLOR
title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.12, 0.06)
closeBtn.Position = UDim2.fromScale(0.85, 0.015)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
closeBtn.TextColor3 = TEXT_COLOR
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2, 0); cbCorner.Parent = closeBtn
closeBtn.Parent = window

-- ────── "GIVE AURA" list ──────
local giveLabel = Instance.new("TextLabel")
giveLabel.Size = UDim2.fromScale(0.9, 0.05)
giveLabel.Position = UDim2.fromScale(0.05, 0.10)
giveLabel.Text = "Give yourself an aura:"
giveLabel.Font = Enum.Font.GothamBold
giveLabel.TextScaled = true
giveLabel.TextXAlignment = Enum.TextXAlignment.Left
giveLabel.BackgroundTransparency = 1
giveLabel.TextColor3 = TEXT_COLOR
giveLabel.Parent = window

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(0.9, 0.45)
scroll.Position = UDim2.fromScale(0.05, 0.16)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = window

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0.01, 0)
list.Parent = scroll

-- fill the give list with every aura (sorted rarest first)
local sorted = {}
for _, a in ipairs(AuraData.Auras) do table.insert(sorted, a) end
table.sort(sorted, function(a, b) return a.Rarity > b.Rarity end)

for _, aura in ipairs(sorted) do
	local item = Instance.new("TextButton")
	item.Size = UDim2.fromScale(1, 0.08)
	item.Text = aura.Name .. "  (1 in " .. aura.Rarity .. ")"
	item.Font = Enum.Font.GothamMedium
	item.TextScaled = true
	item.BackgroundColor3 = FIELD_COLOR
	item.TextColor3 = aura.Color
	local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15, 0); iCorner.Parent = item
	item.Parent = scroll

	item.MouseButton1Click:Connect(function()
		local ok = AdminFunction:InvokeServer("GiveAura", aura.Name)
		if ok then
			item.Text = "✓ Given: " .. aura.Name
			task.wait(0.8)
			item.Text = aura.Name .. "  (1 in " .. aura.Rarity .. ")"
		end
	end)
end

-- ────── LUCK setter ──────
local luckLabel = Instance.new("TextLabel")
luckLabel.Size = UDim2.fromScale(0.9, 0.05)
luckLabel.Position = UDim2.fromScale(0.05, 0.63)
luckLabel.Text = "Luck multiplier (higher = rarer):"
luckLabel.Font = Enum.Font.GothamBold
luckLabel.TextScaled = true
luckLabel.TextXAlignment = Enum.TextXAlignment.Left
luckLabel.BackgroundTransparency = 1
luckLabel.TextColor3 = TEXT_COLOR
luckLabel.Parent = window

local luckBox = Instance.new("TextBox")
luckBox.Size = UDim2.fromScale(0.55, 0.06)
luckBox.Position = UDim2.fromScale(0.05, 0.69)
luckBox.Text = "1"
luckBox.Font = Enum.Font.GothamMedium
luckBox.TextScaled = true
luckBox.BackgroundColor3 = FIELD_COLOR
luckBox.TextColor3 = TEXT_COLOR
luckBox.ClearTextOnFocus = false
luckBox.Numeric = true
local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0.15, 0); lbCorner.Parent = luckBox
luckBox.Parent = window

local luckBtn = Instance.new("TextButton")
luckBtn.Size = UDim2.fromScale(0.3, 0.06)
luckBtn.Position = UDim2.fromScale(0.64, 0.69)
luckBtn.Text = "Set Luck"
luckBtn.Font = Enum.Font.GothamBold
luckBtn.TextScaled = true
luckBtn.BackgroundColor3 = BUTTON_COLOR
luckBtn.TextColor3 = TEXT_COLOR
local lkbCorner = Instance.new("UICorner"); lkbCorner.CornerRadius = UDim.new(0.15, 0); lkbCorner.Parent = luckBtn
luckBtn.Parent = window

luckBtn.MouseButton1Click:Connect(function()
	local val = tonumber(luckBox.Text) or 1
	local result = AdminFunction:InvokeServer("SetLuck", val)
	if result then
		luckBtn.Text = "✓ Luck = " .. tostring(result)
		task.wait(0.8)
		luckBtn.Text = "Set Luck"
	end
end)

-- ────── quick buttons ──────
local rareBtn = Instance.new("TextButton")
rareBtn.Size = UDim2.fromScale(0.43, 0.07)
rareBtn.Position = UDim2.fromScale(0.05, 0.78)
rareBtn.Text = "🎲 Give Rare"
rareBtn.Font = Enum.Font.GothamBold
rareBtn.TextScaled = true
rareBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 200)
rareBtn.TextColor3 = TEXT_COLOR
local rbCorner = Instance.new("UICorner"); rbCorner.CornerRadius = UDim.new(0.15, 0); rbCorner.Parent = rareBtn
rareBtn.Parent = window

rareBtn.MouseButton1Click:Connect(function()
	local got = AdminFunction:InvokeServer("GiveRare")
	if got then
		rareBtn.Text = "✓ " .. got
		task.wait(1)
		rareBtn.Text = "🎲 Give Rare"
	end
end)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.fromScale(0.43, 0.07)
clearBtn.Position = UDim2.fromScale(0.52, 0.78)
clearBtn.Text = "🗑️ Clear All"
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextScaled = true
clearBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
clearBtn.TextColor3 = TEXT_COLOR
local clbCorner = Instance.new("UICorner"); clbCorner.CornerRadius = UDim.new(0.15, 0); clbCorner.Parent = clearBtn
clearBtn.Parent = window

clearBtn.MouseButton1Click:Connect(function()
	AdminFunction:InvokeServer("ClearInventory")
	clearBtn.Text = "✓ Cleared"
	task.wait(0.8)
	clearBtn.Text = "🗑️ Clear All"
end)

-- ────── open/close ──────
local isOpen = false
openBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	window.Visible = isOpen
end)
closeBtn.MouseButton1Click:Connect(function()
	isOpen = false
	window.Visible = false
end)

print("🛠️ Admin panel loaded — you're an admin!")

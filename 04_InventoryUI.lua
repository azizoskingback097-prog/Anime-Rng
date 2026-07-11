-- ═══════════════════════════════════════════════════════════
-- 🎒  INVENTORY UI  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- A small backpack button on screen. Click it → a window opens
-- showing every aura you've rolled (with how many of each), and
-- which one you currently have EQUIPPED. Click an aura to wear it.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Open button pos/size → OPEN_BUTTON_POS / OPEN_BUTTON_SIZE
--   • Window look          → ⚙️ UI THEME block (colors)
--   • How many per row     → ITEMS_PER_ROW
--
-- 🔗 RELATED SCRIPTS:
--   • GameServer → answers GetInventoryFunction + EquipFunction
--   • AuraData   → reads colors for the item buttons
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Add a "DELETE" button on each item to trash duplicates.
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes              = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction        = Remotes:WaitForChild("EquipFunction")
local AuraData             = require(ReplicatedStorage:WaitForChild("AuraData"))

-- ⚙️ ─────────────────── CUSTOMIZE: UI THEME ───────────────────
local BG_COLOR        = Color3.fromRGB(25, 25, 40)
local ITEM_COLOR      = Color3.fromRGB(45, 45, 65)
local TEXT_COLOR      = Color3.fromRGB(255, 255, 255)
local EQUIPPED_COLOR  = Color3.fromRGB(80, 200, 120)
local BUTTON_COLOR    = Color3.fromRGB(80, 120, 255)
-- ⚙️ ─────────────────── CUSTOMIZE: LAYOUT ─────────────────────
local OPEN_BUTTON_POS  = UDim2.fromScale(0.81, 0.76)
local OPEN_BUTTON_SIZE = UDim2.fromScale(0.16, 0.06)
local ITEMS_PER_ROW    = 4
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

-- ────────────── main GUI ──────────────
local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- open button
local openBtn = Instance.new("TextButton")
openBtn.Size = OPEN_BUTTON_SIZE
openBtn.Position = OPEN_BUTTON_POS
openBtn.Text = "🎒  Inventory"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextScaled = true
openBtn.BackgroundColor3 = BUTTON_COLOR
openBtn.TextColor3 = TEXT_COLOR
local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15, 0); obCorner.Parent = openBtn
openBtn.Parent = gui

-- window (hidden until opened)
local window = Instance.new("Frame")
window.Size = UDim2.fromScale(0.55, 0.62)
window.Position = UDim2.fromScale(0.225, 0.19)
window.BackgroundColor3 = BG_COLOR
window.Visible = false
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04, 0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(80,120,255); wStroke.Parent = window
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.1)
title.Position = UDim2.fromScale(0, 0.02)
title.Text = "🎒  Your Auras"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.BackgroundTransparency = 1
title.TextColor3 = TEXT_COLOR
title.Parent = window

-- close button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.07, 0.09)
closeBtn.Position = UDim2.fromScale(0.9, 0.015)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = TEXT_COLOR
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2, 0); cbCorner.Parent = closeBtn
closeBtn.Parent = window

-- scrolling list of items
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(0.94, 0.82)
scroll.Position = UDim2.fromScale(0.03, 0.13)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = window

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(1 / ITEMS_PER_ROW - 0.02, 0.18)
grid.CellPadding = UDim2.fromScale(0.02, 0.02)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

-- ────────────── logic ──────────────
local isOpen = false

local function refresh()
	-- wipe old items
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local data = GetInventoryFunction:InvokeServer()
	if not data or not data.Counts then return end

	local equipped = data.Equipped

	-- sort by rarity (rarest first)
	local names = {}
	for name in pairs(data.Counts) do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		local ra = AuraData.GetByName(a); local rb = AuraData.GetByName(b)
		return (ra and ra.Rarity or 0) > (rb and rb.Rarity or 0)
	end)

	for _, name in ipairs(names) do
		local aura = AuraData.GetByName(name)
		local count = data.Counts[name]

		local item = Instance.new("TextButton")
		item.Text = name .. "\n(×" .. count .. ")"
		item.Font = Enum.Font.GothamBold
		item.TextScaled = true
		item.BackgroundColor3 = ITEM_COLOR
		item.TextColor3 = (aura and aura.Color) or TEXT_COLOR

		-- highlight equipped one
		if name == equipped then
			item.BackgroundColor3 = EQUIPPED_COLOR
			item.Text = "✓ " .. name .. "\n(×" .. count .. ")"
			local eStroke = Instance.new("UIStroke"); eStroke.Thickness = 3; eStroke.Color = Color3.fromRGB(255,255,255); eStroke.Parent = item
		end
		local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15, 0); iCorner.Parent = item
		item.Parent = scroll

		-- click to equip
		item.MouseButton1Click:Connect(function()
			EquipFunction:InvokeServer(name)
			refresh()
		end)
	end
end

openBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	window.Visible = isOpen
	if isOpen then refresh() end
end)

closeBtn.MouseButton1Click:Connect(function()
	isOpen = false
	window.Visible = false
end)

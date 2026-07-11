-- ═══════════════════════════════════════════════════════════
-- 🎵 INVENTORYUI + SFX — adds sounds to inventory!
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Adds these sounds:
--   • Open inventory → open sound
--   • Close inventory → close sound
--   • Click item → click sound
--   • Equip aura → equip sound
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("InventoryUI")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "InventoryUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction = Remotes:WaitForChild("EquipFunction")

local SFX
pcall(function() SFX = require(ReplicatedStorage:WaitForChild("SFXConfig")) end)

local AuraData
pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)

local BG_COLOR = Color3.fromRGB(25,25,40)
local ITEM_COLOR = Color3.fromRGB(45,45,65)
local MUTATION_ITEM_COLOR = Color3.fromRGB(60,40,70)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local EQUIPPED_COLOR = Color3.fromRGB(80,200,120)
local BUTTON_COLOR = Color3.fromRGB(80,120,255)
local ITEMS_PER_ROW = 4

-- Self-clean
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "InventoryGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 20
gui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromScale(0.16,0.06); openBtn.Position = UDim2.fromScale(0.81,0.76)
openBtn.Text = "🎒  Inventory"; openBtn.Font = Enum.Font.GothamBold; openBtn.TextScaled = true
openBtn.BackgroundColor3 = BUTTON_COLOR; openBtn.TextColor3 = TEXT_COLOR
local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn
openBtn.Parent = gui

local window = Instance.new("Frame")
window.Size = UDim2.fromScale(0.55,0.62); window.Position = UDim2.fromScale(0.225,0.19)
window.BackgroundColor3 = BG_COLOR; window.Visible = false
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(80,120,255); wStroke.Parent = window
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1,0.1); title.Position = UDim2.fromScale(0,0.02)
title.Text = "🎒  Your Auras"; title.Font = Enum.Font.GothamBlack; title.TextScaled = true
title.BackgroundTransparency = 1; title.TextColor3 = TEXT_COLOR; title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.07,0.09); closeBtn.Position = UDim2.fromScale(0.9,0.015)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60); closeBtn.TextColor3 = TEXT_COLOR
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn
closeBtn.Parent = window

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(0.94,0.82); scroll.Position = UDim2.fromScale(0.03,0.13)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromScale(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = window

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(0.23,0.18); grid.CellPadding = UDim2.fromScale(0.02,0.02)
grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = scroll

-- Parse mutated names
local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then
		return { Mutation = string.sub(stored,1,sep-1), Base = string.sub(stored,sep+1), Display = string.sub(stored,1,sep-1) .. " " .. string.sub(stored,sep+1) }
	end
	return { Mutation = nil, Base = stored, Display = stored }
end

local function getMutationColor(mutName)
	local WeatherData = ReplicatedStorage:FindFirstChild("WeatherData")
	if WeatherData then
		local ok, wd = pcall(function() return require(WeatherData) end)
		if ok and wd then
			local w = wd.GetByMutation(mutName)
			if w and w.Mutation and w.Mutation.Color then return w.Mutation.Color end
		end
	end
	return nil
end

local isOpen = false

local function refresh()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local data = GetInventoryFunction:InvokeServer()
	if not data or not data.Counts then return end

	local equipped = data.Equipped
	local names = {}
	for name in pairs(data.Counts) do table.insert(names, name) end

	-- Sort by rarity
	table.sort(names, function(a, b)
		local pa = parseAuraName(a); local pb = parseAuraName(b)
		local ra = AuraData and AuraData.GetByName(pa.Base)
		local rb = AuraData and AuraData.GetByName(pb.Base)
		local raV = (ra and ra.Rarity or 0); local rbV = (rb and rb.Rarity or 0)
		if raV == rbV then
			if pa.Mutation and not pb.Mutation then return true end
			if not pa.Mutation and pb.Mutation then return false end
		end
		return raV > rbV
	end)

	for _, name in ipairs(names) do
		local parsed = parseAuraName(name)
		local aura = AuraData and AuraData.GetByName(parsed.Base)
		local count = data.Counts[name]

		local item = Instance.new("TextButton")
		item.Text = parsed.Display .. "\n(x" .. count .. ")"
		item.Font = Enum.Font.GothamBold; item.TextScaled = true

		if parsed.Mutation then
			item.BackgroundColor3 = MUTATION_ITEM_COLOR
			item.TextColor3 = getMutationColor(parsed.Mutation) or (aura and aura.Color) or TEXT_COLOR
		else
			item.BackgroundColor3 = ITEM_COLOR
			item.TextColor3 = (aura and aura.Color) or TEXT_COLOR
		end

		if name == equipped then
			item.BackgroundColor3 = EQUIPPED_COLOR
			item.Text = "✓ " .. parsed.Display .. "\n(x" .. count .. ")"
			local eStroke = Instance.new("UIStroke"); eStroke.Thickness = 3; eStroke.Color = Color3.fromRGB(255,255,255); eStroke.Parent = item
		end

		local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15,0); iCorner.Parent = item
		item.Parent = scroll

		-- 🔊 CLICK SOUND + EQUIP SOUND
		item.MouseButton1Click:Connect(function()
			if SFX then SFX.Play(gui, "click") end
			EquipFunction:InvokeServer(name)
			if SFX then SFX.Play(gui, "equip") end
			refresh()
		end)
	end
end

-- 🔊 OPEN/CLOSE SOUNDS
openBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	window.Visible = isOpen
	if isOpen then
		if SFX then SFX.Play(gui, "open") end
		refresh()
	else
		if SFX then SFX.Play(gui, "close") end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	isOpen = false
	window.Visible = false
	if SFX then SFX.Play(gui, "close") end
end)

print("InventoryUI loaded! (with SFX)")
]==]

print("✅ InventoryUI + SFX APPLIED!")
print("🔊 Sounds added:")
print("   - Open inventory → open sound")
print("   - Close inventory → close sound")
print("   - Click item → click sound")
print("   - Equip aura → equip sound")
print("🎮 Test it — press Play, open inventory, click items!")

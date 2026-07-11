-- ═══════════════════════════════════════════════════════════
-- 🔧 QUICK FIX: Admin crash + old script cleanup
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar (EDIT mode) → Enter
-- Fixes 2 things:
--   1. Removes luckBox.Numeric = true (crashes AdminUI)
--   2. Deletes the old 02_RNGManager_Server script (running alongside GameServer)
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- ═══════════════════════════════════════════════════════════
-- FIX 1: Delete ALL old stray scripts (expanded list with numbered prefixes)
-- ═══════════════════════════════════════════════════════════
local oldNames = {
	"02_RNGManager_Server", "RNGManager", "RollServer",
	"01_AuraData", "01_AuraDatabase", "AuraDatabase",
	"03_RollClient", "03_RollUI",
	"04_InventoryUI", "05_AdminPanel", "05_AdminUI", "06_StatsUI",
	"AdminPanel",
}

local destroyed = 0
local function deepDelete(parent, label)
	for _, child in ipairs(parent:GetChildren()) do
		deepDelete(child, label)
		for _, name in ipairs(oldNames) do
			if child.Name == name then
				print("💥 [" .. label .. "] Deleted: " .. child.Name)
				child:Destroy()
				destroyed = destroyed + 1
			end
		end
	end
end

deepDelete(game:GetService("ServerScriptService"), "ServerScriptService")
deepDelete(game:GetService("ReplicatedStorage"), "ReplicatedStorage")
deepDelete(game:GetService("StarterPlayer"), "StarterPlayer")
deepDelete(game:GetService("StarterGui"), "StarterGui")

print("🧹 Cleaned up " .. destroyed .. " old items.")

-- ═══════════════════════════════════════════════════════════
-- FIX 2: Rewrite AdminUI WITHOUT the crash line
-- ═══════════════════════════════════════════════════════════
local function create(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst then inst:Destroy() end
	inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

create("LocalScript", "AdminUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local AdminStatusEvent = Remotes:WaitForChild("AdminStatusEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local function buildAdminUI()
	-- 🧹 SELF-CLEAN
	for _, child in ipairs(playerGui:GetChildren()) do
		if child.Name == "AdminPanelGui" then child:Destroy() end
	end

	local BG_COLOR = Color3.fromRGB(40,25,30)
	local TEXT_COLOR = Color3.fromRGB(255,255,255)
	local BUTTON_COLOR = Color3.fromRGB(200,60,80)
	local FIELD_COLOR = Color3.fromRGB(60,60,75)

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminPanelGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.Parent = playerGui

	local openBtn = Instance.new("TextButton")
	openBtn.Size = UDim2.fromScale(0.16,0.06)
	openBtn.Position = UDim2.fromScale(0.81,0.68)
	openBtn.Text = "🛠️  Admin"
	openBtn.Font = Enum.Font.GothamBold
	openBtn.TextScaled = true
	openBtn.BackgroundColor3 = BUTTON_COLOR
	openBtn.TextColor3 = TEXT_COLOR
	local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn
	openBtn.Parent = gui

	local window = Instance.new("Frame")
	window.Size = UDim2.fromScale(0.35,0.78)
	window.Position = UDim2.fromScale(0.32,0.11)
	window.BackgroundColor3 = BG_COLOR
	window.Visible = false
	local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
	local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = BUTTON_COLOR; wStroke.Parent = window
	window.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1,0.06)
	title.Position = UDim2.fromScale(0,0.02)
	title.Text = "🛠️  Admin Panel"
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.BackgroundTransparency = 1
	title.TextColor3 = TEXT_COLOR
	title.Parent = window

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromScale(0.12,0.05)
	closeBtn.Position = UDim2.fromScale(0.85,0.015)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextScaled = true
	closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,40)
	closeBtn.TextColor3 = TEXT_COLOR
	local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn
	closeBtn.Parent = window

	-- ────── GIVE AURA LIST ──────
	local giveLabel = Instance.new("TextLabel")
	giveLabel.Size = UDim2.fromScale(0.9,0.04)
	giveLabel.Position = UDim2.fromScale(0.05,0.09)
	giveLabel.Text = "Give yourself an aura:"
	giveLabel.Font = Enum.Font.GothamBold
	giveLabel.TextScaled = true
	giveLabel.TextXAlignment = Enum.TextXAlignment.Left
	giveLabel.BackgroundTransparency = 1
	giveLabel.TextColor3 = TEXT_COLOR
	giveLabel.Parent = window

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(0.9,0.48)
	scroll.Position = UDim2.fromScale(0.05,0.14)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromScale(0,0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = window

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0.01,0)
	list.Parent = scroll

	local sorted = {}
	for _, a in ipairs(AuraData.Auras) do table.insert(sorted, a) end
	table.sort(sorted, function(a,b) return a.Rarity > b.Rarity end)
	for _, aura in ipairs(sorted) do
		local item = Instance.new("TextButton")
		item.Size = UDim2.fromScale(1,0.08)
		item.Text = aura.Name .. "  (1 in " .. aura.Rarity .. ")"
		item.Font = Enum.Font.GothamMedium
		item.TextScaled = true
		item.BackgroundColor3 = FIELD_COLOR
		item.TextColor3 = aura.Color
		local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15,0); iCorner.Parent = item
		item.Parent = scroll
		item.MouseButton1Click:Connect(function()
			local ok = AdminFunction:InvokeServer("GiveAura", aura.Name)
			if ok then item.Text = "✓ Given: " .. aura.Name; task.wait(0.8); item.Text = aura.Name .. "  (1 in " .. aura.Rarity .. ")" end
		end)
	end

	-- ────── LUCK SETTER ──────
	local luckLabel = Instance.new("TextLabel")
	luckLabel.Size = UDim2.fromScale(0.9,0.04)
	luckLabel.Position = UDim2.fromScale(0.05,0.64)
	luckLabel.Text = "Luck multiplier:"
	luckLabel.Font = Enum.Font.GothamBold
	luckLabel.TextScaled = true
	luckLabel.TextXAlignment = Enum.TextXAlignment.Left
	luckLabel.BackgroundTransparency = 1
	luckLabel.TextColor3 = TEXT_COLOR
	luckLabel.Parent = window

	local luckBox = Instance.new("TextBox")
	luckBox.Size = UDim2.fromScale(0.55,0.05)
	luckBox.Position = UDim2.fromScale(0.05,0.69)
	luckBox.Text = "1"
	luckBox.Font = Enum.Font.GothamMedium
	luckBox.TextScaled = true
	luckBox.BackgroundColor3 = FIELD_COLOR
	luckBox.TextColor3 = TEXT_COLOR
	luckBox.ClearTextOnFocus = false
	-- ⚠️ REMOVED: luckBox.Numeric = true (this caused the crash!)
	local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0.15,0); lbCorner.Parent = luckBox
	luckBox.Parent = window

	local luckBtn = Instance.new("TextButton")
	luckBtn.Size = UDim2.fromScale(0.3,0.05)
	luckBtn.Position = UDim2.fromScale(0.64,0.69)
	luckBtn.Text = "Set Luck"
	luckBtn.Font = Enum.Font.GothamBold
	luckBtn.TextScaled = true
	luckBtn.BackgroundColor3 = BUTTON_COLOR
	luckBtn.TextColor3 = TEXT_COLOR
	local lkbCorner = Instance.new("UICorner"); lkbCorner.CornerRadius = UDim.new(0.15,0); lkbCorner.Parent = luckBtn
	luckBtn.Parent = window
	luckBtn.MouseButton1Click:Connect(function()
		local val = tonumber(luckBox.Text) or 1
		local result = AdminFunction:InvokeServer("SetLuck", val)
		if result then luckBtn.Text = "✓ Luck = " .. tostring(result); task.wait(0.8); luckBtn.Text = "Set Luck" end
	end)

	-- ────── QUICK BUTTONS ──────
	local rareBtn = Instance.new("TextButton")
	rareBtn.Size = UDim2.fromScale(0.43,0.06)
	rareBtn.Position = UDim2.fromScale(0.05,0.77)
	rareBtn.Text = "🎲 Give Rare"
	rareBtn.Font = Enum.Font.GothamBold
	rareBtn.TextScaled = true
	rareBtn.BackgroundColor3 = Color3.fromRGB(150,80,200)
	rareBtn.TextColor3 = TEXT_COLOR
	local rbCorner = Instance.new("UICorner"); rbCorner.CornerRadius = UDim.new(0.15,0); rbCorner.Parent = rareBtn
	rareBtn.Parent = window
	rareBtn.MouseButton1Click:Connect(function()
		local got = AdminFunction:InvokeServer("GiveRare")
		if got then rareBtn.Text = "✓ " .. got; task.wait(1); rareBtn.Text = "🎲 Give Rare" end
	end)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.fromScale(0.43,0.06)
	clearBtn.Position = UDim2.fromScale(0.52,0.77)
	clearBtn.Text = "🗑️ Clear All"
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextScaled = true
	clearBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
	clearBtn.TextColor3 = TEXT_COLOR
	local clbCorner = Instance.new("UICorner"); clbCorner.CornerRadius = UDim.new(0.15,0); clbCorner.Parent = clearBtn
	clearBtn.Parent = window
	clearBtn.MouseButton1Click:Connect(function()
		AdminFunction:InvokeServer("ClearInventory")
		clearBtn.Text = "✓ Cleared"; task.wait(0.8); clearBtn.Text = "🗑️ Clear All"
	end)

	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.fromScale(0.9,0.06)
	resetBtn.Position = UDim2.fromScale(0.05,0.85)
	resetBtn.Text = "♻️ Reset ALL Data"
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextScaled = true
	resetBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
	resetBtn.TextColor3 = TEXT_COLOR
	local rsbCorner = Instance.new("UICorner"); rsbCorner.CornerRadius = UDim.new(0.15,0); rsbCorner.Parent = resetBtn
	resetBtn.Parent = window
	resetBtn.MouseButton1Click:Connect(function()
		AdminFunction:InvokeServer("ResetData")
		resetBtn.Text = "✓ Data Reset"; task.wait(0.8); resetBtn.Text = "♻️ Reset ALL Data"
	end)

	local isOpen = false
	openBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		window.Visible = isOpen
	end)
	closeBtn.MouseButton1Click:Connect(function()
		isOpen = false
		window.Visible = false
	end)
	print("🛠️ AdminUI built successfully!")
end

AdminStatusEvent.OnClientEvent:Connect(function(isAdmin)
	if isAdmin then buildAdminUI() end
end)
print("⏳ AdminUI ready, waiting for server confirmation...")
]==]

print("══════════════════════════════════════")
print("✅ FIX COMPLETE!")
print("🔧 Fixed: removed luckBox.Numeric (crash)")
print("🧹 Deleted old 02_RNGManager_Server script")
print("══════════════════════════════════════")
print("➡️ Press Play — the 🛠️ Admin button should appear ~2 seconds after you spawn!")

-- ═══════════════════════════════════════════════════════════
-- 🛠️  MASTER COMMAND BAR v6 — CLEAN SLATE (NUKE + REBUILD)
-- ═══════════════════════════════════════════════════════════
-- HOW TO USE:  View > Command Bar  →  paste ALL of this  →  Enter
--
-- STEP 1: NUKES every old script + remote (any name we ever used)
-- STEP 2: Recreates everything fresh, clean, no duplicates
--
-- Each LocalScript ALSO self-cleans old GUIs on startup, so even
-- if old instances are stuck in PlayerGui, they get destroyed.
--
-- ⚠️ Enable DataStore: Game Settings → Security → ✅ Enable Studio Access to API Services
-- ⚠️ Admin: "Twix79i" is set in ADMIN_USERNAMES (inside GameServer)
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- ───────────────────────────────────────────────────────────
-- 💣 STEP 1: NUKE — destroy EVERYTHING rng-related
-- ───────────────────────────────────────────────────────────

-- every script name we've EVER used (all versions)
local oldNames = {
	"AuraData", "AuraDatabase",
	"RNGManager", "RollServer", "GameServer",
	"RollClient", "RollUI",
	"InventoryUI", "StatsUI",
	"AdminPanel", "AdminUI",
}

-- destroy from all three locations
for _, name in ipairs(oldNames) do
	local function nukeFrom(parent)
		local inst = parent:FindFirstChild(name)
		if inst then inst:Destroy() end
	end
	nukeFrom(RS)
	nukeFrom(SSS)
	nukeFrom(SPS)
end

-- nuke the entire Remotes folder so no stale remotes remain
local oldRemotes = RS:FindFirstChild("Remotes")
if oldRemotes then oldRemotes:Destroy() end

print("💣 Nuke complete — all old scripts removed.")

-- small pause to let Studio process the deletions
task.wait(0.2)

-- ───────────────────────────────────────────────────────────
-- 🆕 STEP 2: REBUILD — create everything fresh
-- ───────────────────────────────────────────────────────────

local function create(className, name, parent)
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

-- 2A) REMOTES
local remotes = create("Folder", "Remotes", RS)
create("RemoteFunction", "RollFunction", remotes)
create("RemoteEvent",    "AnnounceEvent", remotes)
create("RemoteFunction", "GetInventoryFunction", remotes)
create("RemoteFunction", "EquipFunction", remotes)
create("RemoteFunction", "AdminFunction", remotes)
create("RemoteFunction", "GetStatsFunction", remotes)
create("RemoteEvent",    "StatsUpdatedEvent", remotes)

-- 2B) AURA DATA
create("ModuleScript", "AuraData", RS).Source = [==[
local AuraData = {}
AuraData.Auras = {
	{ Name = "Flicker",  Rarity = 1,      Color = Color3.fromRGB(180,180,180), Tier = "Common"    },
	{ Name = "Spark",    Rarity = 4,      Color = Color3.fromRGB(120,200,255), Tier = "Common"    },
	{ Name = "Glow",     Rarity = 16,     Color = Color3.fromRGB(120,255,150), Tier = "Uncommon"  },
	{ Name = "Ember",    Rarity = 32,     Color = Color3.fromRGB(255,140,60),  Tier = "Uncommon"  },
	{ Name = "Surge",    Rarity = 128,    Color = Color3.fromRGB(80,120,255),  Tier = "Rare"      },
	{ Name = "Bloom",    Rarity = 256,    Color = Color3.fromRGB(255,90,200),  Tier = "Rare"      },
	{ Name = "Tempest",  Rarity = 1000,   Color = Color3.fromRGB(0,255,200),   Tier = "Epic"      },
	{ Name = "Eclipse",  Rarity = 7777,   Color = Color3.fromRGB(20,20,40),    Tier = "Legendary" },
	{ Name = "Genesis",  Rarity = 70000,  Color = Color3.fromRGB(255,255,200), Tier = "Mythic"    },
	{ Name = "Spirit Bomb",    Rarity = 500,   Color = Color3.fromRGB(80,160,255),  Tier = "Rare"      },
	{ Name = "Nine-Tails",     Rarity = 5000,  Color = Color3.fromRGB(255,120,40),  Tier = "Legendary" },
	{ Name = "Conqueror Haki", Rarity = 8000,  Color = Color3.fromRGB(200,0,0),     Tier = "Legendary" },
	{ Name = "Cursed Energy",  Rarity = 12000, Color = Color3.fromRGB(60,0,90),     Tier = "Mythic"    },
	{ Name = "Hollow Mask",    Rarity = 20000, Color = Color3.fromRGB(245,245,245), Tier = "Mythic"    },
}
local function rollOnce()
	local totalWeight = 0
	for _, aura in ipairs(AuraData.Auras) do totalWeight = totalWeight + 1 / aura.Rarity end
	local r = math.random() * totalWeight
	local cumulative = 0
	for _, aura in ipairs(AuraData.Auras) do
		cumulative = cumulative + 1 / aura.Rarity
		if r <= cumulative then return aura end
	end
	return AuraData.Auras[1]
end
function AuraData.GetWeightedRandom(luck)
	luck = math.max(1, math.floor(luck or 1))
	local best = rollOnce()
	for _ = 2, luck do
		local attempt = rollOnce()
		if attempt.Rarity > best.Rarity then best = attempt end
	end
	return best
end
function AuraData.GetByName(name)
	for _, aura in ipairs(AuraData.Auras) do
		if aura.Name == name then return aura end
	end
	return nil
end
return AuraData
]==]

-- 2C) GAME SERVER
create("Script", "GameServer", SSS).Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local ADMIN_IDS        = { 12345678, 87654321 }
local ADMIN_USERNAMES  = { "Twix79i" }
local ROLL_COOLDOWN    = 0.5
local LUCK             = 1
local ANNOUNCE_RARITY  = 1000
local AUTO_EQUIP_FIRST = true
local AUTOSAVE_INTERVAL = 60
local DATASTORE_KEY    = "AnimeRNG_v1"

local Remotes              = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction         = Remotes:WaitForChild("RollFunction")
local AnnounceEvent        = Remotes:WaitForChild("AnnounceEvent")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction        = Remotes:WaitForChild("EquipFunction")
local AdminFunction        = Remotes:WaitForChild("AdminFunction")
local GetStatsFunction     = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent    = Remotes:WaitForChild("StatsUpdatedEvent")

local playerStore
local ok = pcall(function()
	playerStore = DataStoreService:GetDataStore(DATASTORE_KEY)
end)
if not ok then warn("⚠️ DataStore not available! Enable 'Studio Access to API Services' in Game Settings → Security") end

local PlayerData = {}
local lastRoll   = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end
	for _, name in ipairs(ADMIN_USERNAMES) do
		if player.Name == name then return true end
	end
	return false
end

local function newData()
	return { Inventory = {}, Equipped = nil, Rolls = 0, Luck = LUCK, RarestAura = "None", RarestRarity = 0 }
end

local function ensureFields(data)
	data.Inventory    = data.Inventory    or {}
	data.Equipped     = data.Equipped     or nil
	data.Rolls        = data.Rolls        or 0
	data.Luck         = data.Luck         or LUCK
	data.RarestAura   = data.RarestAura   or "None"
	data.RarestRarity = data.RarestRarity or 0
	return data
end

local function getData(player)
	if not PlayerData[player] then PlayerData[player] = newData() end
	return PlayerData[player]
end

local function buildStats(data)
	local unique = {}
	for _, name in ipairs(data.Inventory) do unique[name] = true end
	local found = 0
	for _ in pairs(unique) do found = found + 1 end
	return {
		Rolls = data.Rolls, RarestAura = data.RarestAura, RarestRarity = data.RarestRarity,
		Luck = data.Luck, Found = found, Total = #AuraData.Auras,
	}
end

local function loadData(player)
	if playerStore then
		local key = "Player_" .. player.UserId
		local success, result = pcall(function() return playerStore:GetAsync(key) end)
		if success and result then
			PlayerData[player] = ensureFields(result)
		elseif not success then
			warn("Load failed for " .. player.Name .. ": " .. tostring(result))
			PlayerData[player] = newData()
		else
			PlayerData[player] = newData()
		end
	else
		PlayerData[player] = newData()
	end
	task.wait(0.5)
	if PlayerData[player] then
		StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player]))
	end
end

local function saveData(player)
	local data = PlayerData[player]
	if not data or not playerStore then return end
	local key = "Player_" .. player.UserId
	local success, err = pcall(function() playerStore:SetAsync(key, data) end)
	if not success then warn("Save failed for " .. player.Name .. ": " .. tostring(err)) end
end

RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then return nil end
	lastRoll[player] = now
	local data = getData(player)
	data.Rolls = data.Rolls + 1
	local aura = AuraData.GetWeightedRandom(data.Luck)
	table.insert(data.Inventory, aura.Name)
	if aura.Rarity > data.RarestRarity then
		data.RarestRarity = aura.Rarity
		data.RarestAura = aura.Name
	end
	if AUTO_EQUIP_FIRST and data.Equipped == nil then data.Equipped = aura.Name end
	if aura.Rarity >= ANNOUNCE_RARITY then
		AnnounceEvent:FireAllClients({ Player = player.Name, Name = aura.Name, Rarity = aura.Rarity, Tier = aura.Tier })
	end
	StatsUpdatedEvent:FireClient(player, buildStats(data))
	return { Name = aura.Name, Rarity = aura.Rarity, Tier = aura.Tier, TotalRolls = data.Rolls, Color = aura.Color }
end

GetInventoryFunction.OnServerInvoke = function(player)
	local data = getData(player)
	local counts = {}
	for _, name in ipairs(data.Inventory) do counts[name] = (counts[name] or 0) + 1 end
	return { Counts = counts, Equipped = data.Equipped }
end

EquipFunction.OnServerInvoke = function(player, auraName)
	local data = getData(player)
	for _, name in ipairs(data.Inventory) do
		if name == auraName then data.Equipped = auraName; return true end
	end
	return false
end

AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)
	if action == "IsAdmin" then return true
	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name); StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "SetLuck" then
		data.Luck = math.max(1, math.floor(tonumber(value) or 1)); StatsUpdatedEvent:FireClient(player, buildStats(data)); return data.Luck
	elseif action == "GiveRare" then
		local aura = AuraData.GetWeightedRandom(5000)
		table.insert(data.Inventory, aura.Name); StatsUpdatedEvent:FireClient(player, buildStats(data)); return aura.Name
	elseif action == "ClearInventory" then
		data.Inventory = {}; data.Equipped = nil; StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ResetData" then
		PlayerData[player] = newData(); StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player])); return true
	end
	return nil
end

GetStatsFunction.OnServerInvoke = function(player) return buildStats(getData(player)) end

Players.PlayerAdded:Connect(function(player) loadData(player) end)
Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	PlayerData[player] = nil; lastRoll[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player in pairs(PlayerData) do saveData(player) end
	end
end)

game:BindToClose(function()
	for player in pairs(PlayerData) do saveData(player) end
	task.wait(2)
end)

print("✅ GameServer running! (Rolling + Inventory + Equip + Admin + Stats + DataStore)")
]==]

-- 2D) ROLL UI  (no counter — StatsUI handles that; fixes text overlap)
create("LocalScript", "RollUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local auraNames = {}
for _, a in ipairs(AuraData.Auras) do table.insert(auraNames, a.Name) end

-- 💡 SELF-CLEAN: destroy any old version of this GUI that's stuck
local oldGui = playerGui:FindFirstChild("RollGui")
if oldGui then oldGui:Destroy() end

local FLICKER_SPEEDS = {0.03,0.035,0.04,0.045,0.05,0.06,0.07,0.085,0.10,0.12}
local NEAR_MISS_RARITY = 1000
local NEAR_MISS_HOLD = 0.6
local FLASH_TIME = 0.25
local GLOW_STROKE = 0.2
local SHAKE_THRESHOLD = 1000
local SHAKE_INTENSITY = 0.012
local SHAKE_DURATION = 0.4
local RESULT_HOME = UDim2.fromScale(0.2,0.36)
local NEAR_MISS_SIZE = UDim2.fromScale(0.7,0.32)

local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)

local rareAuras = {}
for _, a in ipairs(AuraData.Auras) do
	if a.Rarity >= NEAR_MISS_RARITY then table.insert(rareAuras, a) end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(0.16,0.09)
button.Position = UDim2.fromScale(0.81,0.87)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR
button.TextColor3 = TEXT_COLOR
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12,0); bCorner.Parent = button
button.Parent = gui

local result = Instance.new("TextLabel")
result.Size = UDim2.fromScale(0.6,0.22)
result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.GothamBlack
result.TextScaled = true
result.BackgroundTransparency = 1
result.TextColor3 = TEXT_COLOR
result.TextStrokeTransparency = 1
result.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7,0.1)
banner.Position = UDim2.fromScale(0.15,0.12)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR
banner.TextColor3 = BANNER_COLOR
banner.BackgroundTransparency = 1
banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2,0); bnCorner.Parent = banner
banner.Parent = gui

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1,1)
flash.Position = UDim2.fromScale(0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,255,255)
flash.BackgroundTransparency = 1
flash.ZIndex = 50
flash.Active = false
flash.Parent = gui

local function setGlow(on)
	result.TextStrokeColor3 = result.TextColor3
	result.TextStrokeTransparency = on and GLOW_STROKE or 1
end

local function shakeLabel(label, homePos, rarity)
	local intensity = SHAKE_INTENSITY
	local duration = SHAKE_DURATION
	if rarity >= 5000 then intensity = SHAKE_INTENSITY*1.5; duration = SHAKE_DURATION*1.4 end
	if rarity >= 70000 then intensity = SHAKE_INTENSITY*2.2; duration = SHAKE_DURATION*1.8 end
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		local ox = (math.random()-0.5)*2*intensity
		local oy = (math.random()-0.5)*2*intensity
		label.Position = UDim2.fromScale(homePos.X.Scale+ox, homePos.Y.Scale+oy)
		task.wait(0.02)
	end
	label.Position = homePos
end

local isRolling = false
button.MouseButton1Click:Connect(function()
	if isRolling then return end
	isRolling = true
	button.Text = "..."

	result.Text = ""
	result.TextColor3 = TEXT_COLOR
	result.Position = RESULT_HOME
	result.Size = UDim2.fromScale(0.6,0.22)
	setGlow(false)

	local gotResult = false
	local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)

	for _, speed in ipairs(FLICKER_SPEEDS) do
		result.Text = auraNames[math.random(1,#auraNames)]
		task.wait(speed)
	end

	if #rareAuras > 0 then
		local fake = rareAuras[math.random(1,#rareAuras)]
		result.TextColor3 = fake.Color
		setGlow(true)
		result.Text = fake.Name .. "\n1 in " .. fake.Rarity .. "  •  " .. fake.Tier
		result.Size = NEAR_MISS_SIZE
		result.Position = UDim2.fromScale(0.15,0.34)
		local zoomIn = TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.30)})
		zoomIn:Play()
		task.wait(NEAR_MISS_HOLD)
	end

	flash.BackgroundTransparency = 1
	local flashIn = TweenService:Create(flash, TweenInfo.new(FLASH_TIME*0.4), {BackgroundTransparency = 0})
	flashIn:Play()
	flashIn.Completed:Wait()

	setGlow(false)
	result.Size = UDim2.fromScale(0.6,0.22)

	while not gotResult do task.wait(0.02) end
	button.Text = "ROLL"

	if not res then
		result.Text = "⏳ Too fast! Wait a moment."
		result.TextColor3 = TEXT_COLOR
		TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
		isRolling = false
		return
	end

	result.Text = res.Name .. "\n1 in " .. res.Rarity .. "  •  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	result.Position = UDim2.fromScale(0.2,-0.3)
	TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
	local reveal = TweenService:Create(result, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = RESULT_HOME})
	reveal:Play()
	reveal.Completed:Wait()

	if res.Rarity >= SHAKE_THRESHOLD then
		setGlow(true)
		shakeLabel(result, RESULT_HOME, res.Rarity)
	end
	isRolling = false
end)

AnnounceEvent.OnClientEvent:Connect(function(info)
	banner.Text = "🎉  " .. info.Player .. " pulled " .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.Visible = true
	banner.BackgroundTransparency = 0.3
	banner.Position = UDim2.fromScale(0.15,-0.15)
	local tween = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)})
	tween:Play()
	task.delay(5, function() banner.Visible = false end)
end)
]==]

-- 2E) INVENTORY UI
create("LocalScript", "InventoryUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction = Remotes:WaitForChild("EquipFunction")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

-- 💡 SELF-CLEAN
local oldGui = playerGui:FindFirstChild("InventoryGui")
if oldGui then oldGui:Destroy() end

local BG_COLOR = Color3.fromRGB(25,25,40)
local ITEM_COLOR = Color3.fromRGB(45,45,65)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local EQUIPPED_COLOR = Color3.fromRGB(80,200,120)
local BUTTON_COLOR = Color3.fromRGB(80,120,255)

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromScale(0.16,0.06)
openBtn.Position = UDim2.fromScale(0.81,0.76)
openBtn.Text = "🎒  Inventory"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextScaled = true
openBtn.BackgroundColor3 = BUTTON_COLOR
openBtn.TextColor3 = TEXT_COLOR
local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn
openBtn.Parent = gui

local window = Instance.new("Frame")
window.Size = UDim2.fromScale(0.55,0.62)
window.Position = UDim2.fromScale(0.225,0.19)
window.BackgroundColor3 = BG_COLOR
window.Visible = false
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(80,120,255); wStroke.Parent = window
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1,0.1)
title.Position = UDim2.fromScale(0,0.02)
title.Text = "🎒  Your Auras"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.BackgroundTransparency = 1
title.TextColor3 = TEXT_COLOR
title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.07,0.09)
closeBtn.Position = UDim2.fromScale(0.9,0.015)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
closeBtn.TextColor3 = TEXT_COLOR
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn
closeBtn.Parent = window

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(0.94,0.82)
scroll.Position = UDim2.fromScale(0.03,0.13)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromScale(0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = window

local ITEMS_PER_ROW = 4
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(1/ITEMS_PER_ROW-0.02,0.18)
grid.CellPadding = UDim2.fromScale(0.02,0.02)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

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
	table.sort(names, function(a,b)
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
		if name == equipped then
			item.BackgroundColor3 = EQUIPPED_COLOR
			item.Text = "✓ " .. name .. "\n(×" .. count .. ")"
			local eStroke = Instance.new("UIStroke"); eStroke.Thickness = 3; eStroke.Color = Color3.fromRGB(255,255,255); eStroke.Parent = item
		end
		local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15,0); iCorner.Parent = item
		item.Parent = scroll
		item.MouseButton1Click:Connect(function() EquipFunction:InvokeServer(name); refresh() end)
	end
end

openBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	window.Visible = isOpen
	if isOpen then refresh() end
end)
closeBtn.MouseButton1Click:Connect(function() isOpen = false; window.Visible = false end)
]==]

-- 2F) STATS UI
create("LocalScript", "StatsUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- 💡 SELF-CLEAN
local oldGui = playerGui:FindFirstChild("StatsGui")
if oldGui then oldGui:Destroy() end

local BG_COLOR = Color3.fromRGB(25,25,40)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local TITLE_COLOR = Color3.fromRGB(255,215,0)
local STROKE_COLOR = Color3.fromRGB(80,120,255)

local gui = Instance.new("ScreenGui")
gui.Name = "StatsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.20,0.20)
panel.Position = UDim2.fromScale(0.78,0.02)
panel.BackgroundColor3 = BG_COLOR
panel.BackgroundTransparency = 0.15
local pCorner = Instance.new("UICorner"); pCorner.CornerRadius = UDim.new(0.08,0); pCorner.Parent = panel
local pStroke = Instance.new("UIStroke"); pStroke.Thickness = 2; pStroke.Color = STROKE_COLOR; pStroke.Parent = panel
panel.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0.04,0)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = panel

local function makeLabel()
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.92,0.18)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = TEXT_COLOR
	lbl.Parent = panel
	return lbl
end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(0.92,0.2)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextScaled = true
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = TITLE_COLOR
titleLabel.Text = "📊  STATS"
titleLabel.Parent = panel

local rollsLabel = makeLabel()
local rarestLabel = makeLabel()
local foundLabel = makeLabel()
local luckLabel = makeLabel()

local function formatRarity(n)
	if n == 0 then return "—" end
	return "1 in " .. n
end

local function update(stats)
	if not stats then return end
	rollsLabel.Text = "Rolls:  " .. tostring(stats.Rolls or 0)
	rarestLabel.Text = "Rarest: " .. tostring(stats.RarestAura or "None") .. "  (" .. formatRarity(stats.RarestRarity) .. ")"
	foundLabel.Text = "Found:  " .. tostring(stats.Found or 0) .. "/" .. tostring(stats.Total or 0)
	luckLabel.Text = "Luck:  ×" .. tostring(stats.Luck or 1)
end

-- wait a beat for the server to load, then request stats
task.delay(1, function()
	update(GetStatsFunction:InvokeServer())
end)
StatsUpdatedEvent.OnClientEvent:Connect(update)
]==]

-- 2G) ADMIN UI  (with timing fix + DisplayOrder fix)
create("LocalScript", "AdminUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

-- 💡 SELF-CLEAN
local oldGui = playerGui:FindFirstChild("AdminPanelGui")
if oldGui then oldGui:Destroy() end

-- ⏳ FIX: wait for the server to FULLY load before checking admin
-- This prevents the admin check from hanging/failing on startup
task.wait(2)

local amAdmin = false
local success, result = pcall(function()
	return AdminFunction:InvokeServer("IsAdmin")
end)
if success then amAdmin = result end
if not amAdmin then return end

local BG_COLOR = Color3.fromRGB(40,25,30)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BUTTON_COLOR = Color3.fromRGB(200,60,80)
local FIELD_COLOR = Color3.fromRGB(60,60,75)

local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanelGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100   -- 🔝 ALWAYS on top of everything
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

local luckLabel = Instance.new("TextLabel")
luckLabel.Size = UDim2.fromScale(0.9,0.04)
luckLabel.Position = UDim2.fromScale(0.05,0.64)
luckLabel.Text = "Luck multiplier (higher = rarer):"
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
luckBox.Numeric = true
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
print("🛠️ AdminUI loaded — you're an admin!")
]==]

print("✅ CLEAN SLATE COMPLETE! v6")
print("💣 Nuked all old scripts, rebuilt everything fresh.")
print("📝 Scripts: AuraData, GameServer, RollUI, InventoryUI, StatsUI, AdminUI")
print("🔧 Fixes: text overlap (no duplicate GUIs), admin (timing + DisplayOrder)")
print("💾 DataStore: enable 'Studio Access to API Services' in Game Settings → Security")

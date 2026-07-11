-- ═══════════════════════════════════════════════════════════
-- 🌍 DYNAMIC AREA UI & CROSSFADING MUSIC SYSTEM
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Looks for the "MapZones" folder in Workspace to keep things clean!
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("ZoneClient")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "ZoneClient"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🎵 ZONE DATA TABLE
local ZONE_DATA = {
	["SpawnZone"] = {
		DisplayName = "Spawn Area",
		TextColor = Color3.fromRGB(255, 255, 255),
		MusicId = "rbxassetid://1837879082", -- Replace with your Spawn music
		MusicVolume = 0.5
	},
	["ForestZone"] = {
		DisplayName = "Mystic Forest",
		TextColor = Color3.fromRGB(100, 255, 100),
		MusicId = "rbxassetid://1846468024", -- Replace with your Forest music
		MusicVolume = 0.4
	},
	["SakuraZone"] = {
		DisplayName = "Sakura Garden",
		TextColor = Color3.fromRGB(255, 150, 180),
		MusicId = "rbxassetid://1838115150", -- Replace with your Sakura music
		MusicVolume = 0.4
	}
}

local currentZone = nil
local activeZones = {} 

-- UI SETUP
local gui = Instance.new("ScreenGui")
gui.Name = "ZoneUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 12
gui.Parent = playerGui

local areaFrame = Instance.new("Frame")
areaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
areaFrame.Size = UDim2.fromOffset(600, 100)
areaFrame.Position = UDim2.fromScale(0.5, 0.2)
areaFrame.BackgroundTransparency = 1
areaFrame.Parent = gui

local areaText = Instance.new("TextLabel")
areaText.Size = UDim2.fromScale(1, 1)
areaText.BackgroundTransparency = 1
areaText.Text = ""
areaText.Font = Enum.Font.GothamBlack
areaText.TextScaled = true
areaText.TextColor3 = Color3.fromRGB(255, 255, 255)
areaText.TextTransparency = 1
areaText.ZIndex = 10
areaText.Parent = areaFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3; stroke.Color = Color3.fromRGB(0, 0, 0); stroke.Transparency = 1; stroke.Parent = areaText

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,200,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
})
grad.Parent = areaText

-- MUSIC SETUP
local music1 = Instance.new("Sound")
music1.Volume = 0; music1.Looped = true; music1.Parent = SoundService
local music2 = Instance.new("Sound")
music2.Volume = 0; music2.Looped = true; music2.Parent = SoundService

local activeTrack = music1
local inactiveTrack = music2

local function playZoneMusic(zoneName)
	local data = ZONE_DATA[zoneName]
	if not data or not data.MusicId then return end
	if activeTrack.SoundId == data.MusicId then return end

	local newTrack = inactiveTrack
	newTrack.SoundId = data.MusicId
	newTrack.Volume = 0
	newTrack:Play()

	TweenService:Create(newTrack, TweenInfo.new(2), {Volume = data.MusicVolume}):Play()
	TweenService:Create(activeTrack, TweenInfo.new(2), {Volume = 0}):Play()

	inactiveTrack = activeTrack
	activeTrack = newTrack

	task.delay(2.1, function()
		if inactiveTrack.Volume == 0 then inactiveTrack:Stop() end
	end)
end

-- AREA UI ANIMATION
local function showAreaUI(zoneName)
	local data = ZONE_DATA[zoneName]
	if not data then return end

	areaText.Text = data.DisplayName
	areaText.TextColor3 = data.TextColor
	stroke.Transparency = 1
	areaText.TextTransparency = 1

	local t1 = TweenService:Create(areaText, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency = 0})
	local t2 = TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 0.2})
	t1:Play(); t2:Play()
	
	task.delay(3, function()
		local t3 = TweenService:Create(areaText, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1})
		local t4 = TweenService:Create(stroke, TweenInfo.new(1), {Transparency = 1})
		t3:Play(); t4:Play()
	end)
end

-- DETECT ZONE CHANGES
local function updateCurrentZone()
	local foundZone = nil
	for zoneName, _ in pairs(activeZones) do
		foundZone = zoneName
		break
	end
	if foundZone and foundZone ~= currentZone then
		currentZone = foundZone
		showAreaUI(currentZone)
		playZoneMusic(currentZone)
	end
end

-- BIND TOUCH EVENTS TO ZONE PARTS
local function setupZones()
	local zoneFolder = Workspace:WaitForChild("MapZones", 5)
	if not zoneFolder then warn("❌ 'MapZones' folder not found in Workspace!") return end

	for _, part in ipairs(zoneFolder:GetChildren()) do
		if part:IsA("BasePart") then
			-- Hide the parts during gameplay so players don't see them!
			part.Transparency = 1 
			
			part.Touched:Connect(function(hit)
				if hit:IsDescendantOf(player.Character) then
					if not activeZones[part.Name] then
						activeZones[part.Name] = true
						updateCurrentZone()
					end
				end
			end)
			
			part.TouchEnded:Connect(function(hit)
				if hit:IsDescendantOf(player.Character) then
					task.wait(0.2)
					local partsInZone = Workspace:GetPartsInPart(part)
					local stillInside = false
					for _, p in ipairs(partsInZone) do
						if p:IsDescendantOf(player.Character) then
							stillInside = true
							break
						end
					end
					if not stillInside then
						activeZones[part.Name] = nil
					end
				end
			end)
		end
	end
end

setupZones()
print("ZoneClient loaded! (Looking for MapZones folder)")
]==]

print("✅ ZONE UI & MUSIC SYSTEM APPLIED!")
print("👉 Paste the Auto-Setup script first to generate the parts, then move them!")

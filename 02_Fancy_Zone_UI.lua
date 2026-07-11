-- ═══════════════════════════════════════════════════════════
-- 💎 FANCY AREA UI & MUSIC SYSTEM (Highly Modular!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
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
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════
-- ⚙️ CONFIGURATION (Change these to customize your UI!)
-- ═══════════════════════════════════════════════════════════
local FONT_TYPE = Enum.Font.Bodoni             -- Font style
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)  -- Default text color
local TEXT_SIZE = 80                           -- How big the text is

local DESIGN_IMAGE_ID = "rbxassetid://7681663596" -- Fancy flourish/underline image
local DESIGN_COLOR = Color3.fromRGB(200, 200, 255) -- Tint of the fancy image

local FADE_SPEED = 1.0                         -- How fast it fades in/out (Seconds)
local UI_HOLD_TIME = 4.0                       -- How long the text stays on screen
-- ═══════════════════════════════════════════════════════════

-- 🎵 ZONE DATA TABLE (Customize names and music IDs here!)
local ZONE_DATA = {
	["SpawnZone"] = { DisplayName = "The Sanctuary", TextColor = Color3.fromRGB(255, 255, 255), MusicId = "rbxassetid://1837879082", MusicVolume = 0.5 },
	["ForestZone"] = { DisplayName = "Whispering Woods", TextColor = Color3.fromRGB(150, 255, 150), MusicId = "rbxassetid://1846468024", MusicVolume = 0.4 },
	["SakuraZone"] = { DisplayName = "Sakura Gardens", TextColor = Color3.fromRGB(255, 180, 200), MusicId = "rbxassetid://1838115150", MusicVolume = 0.4 }
}

local currentZone = nil
local zoneParts = {}

-- UI SETUP
local gui = Instance.new("ScreenGui")
gui.Name = "ZoneUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 12
gui.Parent = playerGui

-- Main Container
local areaFrame = Instance.new("Frame")
areaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
areaFrame.Size = UDim2.fromOffset(800, 200)
areaFrame.Position = UDim2.fromScale(0.5, 0.18) -- Top center of screen
areaFrame.BackgroundTransparency = 1
areaFrame.Parent = gui

-- 1. Fancy Design Image (Underline/Flourish)
local designImage = Instance.new("ImageLabel")
designImage.Name = "FancyDesign"
designImage.AnchorPoint = Vector2.new(0.5, 0.5)
designImage.BackgroundTransparency = 1
designImage.Image = DESIGN_IMAGE_ID
designImage.ImageColor3 = DESIGN_COLOR
designImage.Size = UDim2.fromOffset(600, 100) -- Size of the design
designImage.Position = UDim2.new(0.5, 0, 0.5, 25) -- Sits below the text
designImage.ImageTransparency = 1
designImage.ZIndex = 9
designImage.Parent = areaFrame

-- 2. Area Text Label
local areaText = Instance.new("TextLabel")
areaText.Name = "AreaText"
areaText.AnchorPoint = Vector2.new(0.5, 0.5)
areaText.Size = UDim2.fromOffset(700, 100)
areaText.Position = UDim2.new(0.5, 0, 0.5, -20) -- Sits above the design
areaText.BackgroundTransparency = 1
areaText.Text = ""
areaText.Font = FONT_TYPE
areaText.TextSize = TEXT_SIZE
areaText.TextColor3 = TEXT_COLOR
areaText.TextTransparency = 1
areaText.ZIndex = 10
areaText.Parent = areaFrame

-- Drop shadow for text
local stroke = Instance.new("UIStroke")
stroke.Thickness = 2; stroke.Color = Color3.fromRGB(10, 10, 20); stroke.Transparency = 1; stroke.Parent = areaText

-- MUSIC SETUP
local music1 = Instance.new("Sound")
music1.Volume = 0; music1.Looped = true; music1.Parent = SoundService
local music2 = Instance.new("Sound")
music2.Volume = 0; music2.Looped = true; music2.Parent = SoundService
local activeTrack = music1
local inactiveTrack = music2

local function playZoneMusic(zoneName)
	local data = ZONE_DATA[zoneName]
	if not data or not data.MusicId or activeTrack.SoundId == data.MusicId then return end
	local newTrack = inactiveTrack
	newTrack.SoundId = data.MusicId; newTrack.Volume = 0; newTrack:Play()
	TweenService:Create(newTrack, TweenInfo.new(FADE_SPEED), {Volume = data.MusicVolume}):Play()
	TweenService:Create(activeTrack, TweenInfo.new(FADE_SPEED), {Volume = 0}):Play()
	inactiveTrack = activeTrack; activeTrack = newTrack
	task.delay(FADE_SPEED + 0.1, function() if inactiveTrack.Volume == 0 then inactiveTrack:Stop() end end)
end

-- AREA UI ANIMATION (Smooth Fade In / Fade Out)
local isAnimating = false
local function showAreaUI(zoneName)
	local data = ZONE_DATA[zoneName]
	if not data then return end
	
	-- Setup Text
	areaText.Text = string.upper(data.DisplayName) -- Makes it look fancy!
	areaText.TextColor3 = data.TextColor or TEXT_COLOR
	
	-- Fade In Both Elements
	TweenService:Create(areaText, TweenInfo.new(FADE_SPEED), {TextTransparency = 0}):Play()
	TweenService:Create(stroke, TweenInfo.new(FADE_SPEED), {Transparency = 0.2}):Play()
	TweenService:Create(designImage, TweenInfo.new(FADE_SPEED), {ImageTransparency = 0}):Play()
	
	-- Wait, then Fade Out
	task.delay(UI_HOLD_TIME, function()
		TweenService:Create(areaText, TweenInfo.new(FADE_SPEED), {TextTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(FADE_SPEED), {Transparency = 1}):Play()
		TweenService:Create(designImage, TweenInfo.new(FADE_SPEED), {ImageTransparency = 1}):Play()
	end)
end

-- COLLECT ZONE PARTS
local function setupZones()
	local zoneFolder = Workspace:WaitForChild("MapZones", 10)
	if not zoneFolder then return end
	
	task.wait(2) -- Wait for map to stream in
	
	for _, obj in ipairs(zoneFolder:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1 
			table.insert(zoneParts, obj)
		end
	end
end

task.spawn(setupZones)

-- DETECT ZONE CHANGES
RunService.Heartbeat:Connect(function()
	local char = player.Character; if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	
	for _, zone in ipairs(zoneParts) do
		local localPos = zone.CFrame:PointToObjectSpace(hrp.Position)
		if math.abs(localPos.X) < zone.Size.X/2 and math.abs(localPos.Y) < zone.Size.Y/2 and math.abs(localPos.Z) < zone.Size.Z/2 then
			if currentZone ~= zone.Name then
				currentZone = zone.Name
				showAreaUI(currentZone)
				playZoneMusic(currentZone)
			end
			return 
		end
	end
	currentZone = nil
end)
]==]

print("✅ FANCY AREA UI APPLIED! Fully modular and ready to customize.")

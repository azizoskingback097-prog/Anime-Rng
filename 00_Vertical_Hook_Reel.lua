-- ═══════════════════════════════════════════════════════════
-- 🎰 SOL'S RNG STYLE VERTICAL REEL (With Stop-and-Go Hook!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- HOW IT WORKS:
--   • Reel moves smoothly from Top to Bottom.
--   • You can see roughly 5 auras at once.
--   • Every 3-5 rolls, it FAKE STOPS on a rare aura to hook you, 
--     then speeds back up and lands on your actual result!
--   • Small UI impact when stopping.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Lighting = game:GetService("Lighting")
local old = SPS:FindFirstChild("RollUI")
if old then old:Destroy() end

-- Ensure Blur exists
local blur = Lighting:FindFirstChild("RollBlur")
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "RollBlur"
	blur.Size = 0
	blur.Parent = Lighting
end

task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "RollUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

local SFX
pcall(function() SFX = require(ReplicatedStorage:WaitForChild("SFXConfig")) end)
local AuraData
pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)

local blur = Lighting:WaitForChild("RollBlur")

local auraNames, commonAuras, rareAuras = {}, {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a)
		if a.Rarity < 100 then table.insert(commonAuras, a) end
		if a.Rarity >= 5000 then table.insert(rareAuras, a) end
	end
end
if #auraNames == 0 then auraNames = { {Name="...", Color=Color3.fromRGB(255,255,255), Tier="Common", Rarity=1} } end
if #commonAuras == 0 then commonAuras = auraNames end
if #rareAuras == 0 then rareAuras = auraNames end

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- Build UI
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

local shaker = Instance.new("Frame")
shaker.Size = UDim2.fromScale(1, 1); shaker.Position = UDim2.fromScale(0, 0)
shaker.BackgroundTransparency = 1; shaker.Parent = gui

-- Vertical Reel Window
local reelClip = Instance.new("Frame")
reelClip.AnchorPoint = Vector2.new(0.5, 0.5)
reelClip.Size = UDim2.fromOffset(400, 700) -- Tall window to see multiple auras
reelClip.Position = UDim2.fromScale(0.5, 0.4)
reelClip.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
reelClip.BackgroundTransparency = 0.2
reelClip.ClipsDescendants = true
reelClip.ZIndex = 5
local rcCorner = Instance.new("UICorner"); rcCorner.CornerRadius = UDim.new(0.05, 0); rcCorner.Parent = reelClip
reelClip.Parent = shaker

-- Center Line
local centerLine = Instance.new("Frame")
centerLine.AnchorPoint = Vector2.new(0.5, 0.5)
centerLine.Size = UDim2.fromOffset(420, 6)
centerLine.Position = UDim2.fromScale(0.5, 0.5)
centerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerLine.BorderSizePixel = 0
centerLine.ZIndex = 10
centerLine.Parent = reelClip

-- The Moving Reel
local reel = Instance.new("Frame")
reel.Size = UDim2.fromOffset(380, 0) -- Height grows as cards are added
reel.Position = UDim2.fromScale(0, 0)
reel.BackgroundTransparency = 1
reel.Parent = reelClip

-- Result Text
local resultText = Instance.new("TextLabel")
resultText.AnchorPoint = Vector2.new(0.5, 0.5)
resultText.Size = UDim2.fromOffset(500, 100)
resultText.Position = UDim2.fromScale(0.5, 0.82)
resultText.Text = ""
resultText.Font = Enum.Font.GothamBlack
resultText.TextScaled = true
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.TextTransparency = 1
resultText.ZIndex = 20
resultText.Parent = shaker

-- Buttons
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.5, 0.92)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5)
autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.85)
autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoBtn.ZIndex = 20
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.15, 0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1)
banner.Position = UDim2.fromScale(0.15, 0.1)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(30,30,45)
banner.TextColor3 = Color3.fromRGB(255,215,0)
banner.BackgroundTransparency = 1
banner.Visible = false
banner.ZIndex = 30
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

-- ═══════════════════════════════════════════════════════════
-- CARD & REEL LOGIC
-- ═══════════════════════════════════════════════════════════
local CARD_HEIGHT = 130
local CARD_GAP = 20
local STEP = CARD_HEIGHT + CARD_GAP

local function createCard(auraData, index)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(380, CARD_HEIGHT)
	card.Position = UDim2.fromOffset(0, index * STEP)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BorderSizePixel = 0
	card.ZIndex = 5
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	stroke.Parent = card
	
	local glow = Instance.new("UIStroke")
	glow.Thickness = 8
	glow.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	glow.Transparency = 0.5
	glow.Parent = card
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.9)
	label.Position = UDim2.fromScale(0.05, 0.05)
	label.BackgroundTransparency = 1
	label.Text = auraData.Name .. "\n\n" .. (auraData.Tier or "Common")
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.ZIndex = 6
	label.Parent = card
	
	return card
end

local function clearReel()
	for _, child in ipairs(reel:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	reel.Size = UDim2.fromOffset(380, 0)
end

-- ═══════════════════════════════════════════════════════════
-- CUTSCENE MANAGER 
-- ═══════════════════════════════════════════════════════════
local CutsceneManager = {}

function CutsceneManager.Play(res)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 15
	overlay.Parent = gui
	
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
	resultText.Text = res.DisplayName or res.Name
	resultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	resultText.TextTransparency = 0
	
	task.wait(3)
	
	TweenService:Create(overlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(resultText, TweenInfo.new(1), {TextTransparency = 1}):Play()
	task.wait(1)
	overlay:Destroy()
end

-- ═══════════════════════════════════════════════════════════
-- MAIN VERTICAL REEL ANIMATION (With Stop-and-Go Hook!)
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false
local teaseCounter = math.random(3, 5)
local rollCount = 0

local function playReel(res)
	button.Active = false
	button.Text = "..."
	clearReel()
	
	rollCount += 1
	local isTeaseRoll = (rollCount % teaseCounter == 0)
	if isTeaseRoll then
		teaseCounter = math.random(3, 5) -- Reset counter
	end
	
	-- Generate 60 cards
	local totalCards = 60
	local teaseIndex = 40 -- The card it will fake-stop on
	
	for i = 0, totalCards - 1 do
		local cardData
		
		if i == totalCards - 1 then
			cardData = res -- Actual Winner (Last card)
		elseif isTeaseRoll and i == teaseIndex then
			cardData = rareAuras[math.random(1, #rareAuras)] -- The Fake Rare!
		else
			cardData = commonAuras[math.random(1, #commonAuras)]
		end
		
		local card = createCard(cardData, i)
		card.Parent = reel
	end
	
	reel.Size = UDim2.fromOffset(380, totalCards * STEP)
	task.wait(0.1)
	
	-- Math for Vertical Y Positioning
	local winnerIndex = totalCards - 1
	local winnerCenterY = winnerIndex * STEP + (CARD_HEIGHT / 2)
	local reelClipCenterY = reelClip.AbsoluteSize.Y / 2
	local finalEndY = reelClipCenterY - winnerCenterY
	
	-- Start Position (Top of the reel visible, moving down)
	-- Actually, to move top-to-bottom, we want Y to go from 0 to negative.
	reel.Position = UDim2.fromOffset(0, 0)
	
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 15}):Play()
	if SFX then SFX.Play(gui, "roll") end
	
	-- Tick loop
	task.spawn(function()
		local tickTime = os.clock()
		while reel.Position.Y.Offset > finalEndY + 50 do
			if os.clock() - tickTime > 0.08 then
				if SFX then SFX.Play(gui, "tick", 0.2) end
				tickTime = os.clock()
			end
			task.wait()
		end
	end)
	
	if isTeaseRoll then
		-- 1. FAKE STOP MATH (For the tease card)
		local teaseCenterY = teaseIndex * STEP + (CARD_HEIGHT / 2)
		local teaseEndY = reelClipCenterY - teaseCenterY
		
		-- Fast spin to the tease card
		local spin1 = TweenService:Create(reel, TweenInfo.new(2.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(0, teaseEndY)
		})
		spin1:Play()
		spin1.Completed:Wait()
		
		-- Hold for tension (Player thinks they won!)
		task.wait(0.8) 
		if SFX then SFX.Play(gui, "tick") end
		
		-- 2. RESUME SPIN (Fast forward to actual winner)
		local spin2 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(0, finalEndY)
		})
		spin2:Play()
		spin2.Completed:Wait()
	else
		-- NORMAL LONG SPIN (No tease)
		local spin = TweenService:Create(reel, TweenInfo.new(4.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(0, finalEndY)
		})
		spin:Play()
		spin.Completed:Wait()
	end
	
	-- Remove Blur
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	
	-- Impact Effects
	if SFX then 
		if res.Rarity >= 5000 then SFX.Play(gui, "legendary")
		elseif res.Rarity >= 1000 then SFX.Play(gui, "rare")
		else SFX.Play(gui, "reveal") end
	end
	
	-- Small UI Shake
	local shakeIntensity = res.Rarity >= 1000 and 6 or 2
	local t0 = os.clock()
	while os.clock() - t0 < 0.3 do
		local ox = (math.random() - 0.5) * shakeIntensity * 2
		local oy = (math.random() - 0.5) * shakeIntensity * 2
		shaker.Position = UDim2.fromOffset(ox, oy)
		task.wait()
	end
	shaker.Position = UDim2.fromScale(0, 0)
	
	button.Text = "ROLL"
	button.Active = true
	
	-- Check if Cutscene is needed
	if res.Rarity >= 50000 then 
		CutsceneManager.Play(res)
	end
	
	task.wait(2)
end

-- ═══════════════════════════════════════════════════════════
-- ROLL ORCHESTRATOR
-- ═══════════════════════════════════════════════════════════
local function doRoll()
	if isRolling then return end
	isRolling = true
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	
	while not gotResult do task.wait(0.02) end
	if not res then isRolling = false; return end

	playReel(res)
	isRolling = false
end

button.MouseButton1Click:Connect(doRoll)

autoBtn.MouseButton1Click:Connect(function()
	autoRollEnabled = not autoRollEnabled
	if autoRollEnabled then
		autoBtn.Text = "AUTO: ON"
		autoBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	else
		autoBtn.Text = "AUTO: OFF"
		autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
	if SFX then SFX.Play(gui, "click") end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if autoRollEnabled and not isRolling then doRoll() end
	end
end)

AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.TextColor3 = info.Color or Color3.fromRGB(255, 215, 0)
	banner.Visible = true
	banner.BackgroundTransparency = 0.3
	banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.1)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)

print("RollUI loaded! (Sol's RNG Vertical Reel with Stop-and-Go Hook)")
]==]

print("✅ SOL'S RNG VERTICAL REEL APPLIED!")
print("⬇️ Reel now moves Top-to-Bottom (shows multiple auras).")
print("🪝 Added the 'Stop-and-Go' Fakeout Hook!")

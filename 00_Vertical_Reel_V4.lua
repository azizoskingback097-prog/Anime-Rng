-- ═══════════════════════════════════════════════════════════
-- 🎰 VERTICAL REEL V4 (The "Hard Stop" Mind Game!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- THE NEW TEASE MECHANIC:
--   • The reel will FULLY STOP on the aura for 1 second to trick you.
--   • If Rare is before: It stops on Rare, then skips to Actual.
--   • If Rare is after: It stops on Actual, creeps to Rare, then pulls back.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Lighting = game:GetService("Lighting")
local old = SPS:FindFirstChild("RollUI")
if old then old:Destroy() end

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
local RunService = game:GetService("RunService")

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

-- REEL CONTAINER
local reelContainer = Instance.new("Frame")
reelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
reelContainer.Size = UDim2.fromOffset(400, 700)
reelContainer.Position = UDim2.fromScale(0.5, 0.42)
reelContainer.BackgroundTransparency = 1
reelContainer.Visible = false
reelContainer.ZIndex = 5
reelContainer.Parent = shaker

-- Reel Window
local reelClip = Instance.new("Frame")
reelClip.Size = UDim2.fromScale(1, 1)
reelClip.Position = UDim2.fromScale(0, 0)
reelClip.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
reelClip.BackgroundTransparency = 0.3
reelClip.ClipsDescendants = true
reelClip.ZIndex = 5
local rcCorner = Instance.new("UICorner"); rcCorner.CornerRadius = UDim.new(0.05, 0); rcCorner.Parent = reelClip
reelClip.Parent = reelContainer

-- Center Line
local centerLine = Instance.new("Frame")
centerLine.AnchorPoint = Vector2.new(0.5, 0.5)
centerLine.Size = UDim2.fromOffset(420, 6)
centerLine.Position = UDim2.fromScale(0.5, 0.5)
centerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerLine.BorderSizePixel = 0
centerLine.ZIndex = 10
centerLine.Parent = reelClip

-- Center Glow
local centerGlow = Instance.new("Frame")
centerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
centerGlow.Size = UDim2.fromOffset(420, 100)
centerGlow.Position = UDim2.fromScale(0.5, 0.5)
centerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerGlow.BackgroundTransparency = 0.9
centerGlow.BorderSizePixel = 0
centerGlow.ZIndex = 9
local cgCorner = Instance.new("UICorner"); cgCorner.CornerRadius = UDim.new(1, 0); cgCorner.Parent = centerGlow
centerGlow.Parent = reelClip

-- Moving Reel
local reel = Instance.new("Frame")
reel.Size = UDim2.fromOffset(380, 0)
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

-- CARD LOGIC
local CARD_HEIGHT = 130
local CARD_WIDTH = 360
local CARD_GAP = 20
local STEP = CARD_HEIGHT + CARD_GAP

local function createCard(auraData, index)
	local card = Instance.new("Frame")
	card.Name = "Card" .. index
	card.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromOffset(190, index * STEP + (CARD_HEIGHT / 2))
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BorderSizePixel = 0
	card.ZIndex = 5
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Thickness = 4
	stroke.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	stroke.Parent = card
	
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
	
	card:SetAttribute("BaseWidth", CARD_WIDTH)
	card:SetAttribute("BaseHeight", CARD_HEIGHT)
	return card
end

local function clearReel()
	for _, child in ipairs(reel:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	reel.Size = UDim2.fromOffset(380, 0)
end

-- CARD POP EFFECT
local popConnection = nil

local function startCardPopTracker()
	if popConnection then popConnection:Disconnect() end
	local lastPoppedIndex = -1
	
	popConnection = RunService.RenderStepped:Connect(function()
		if not reelContainer.Visible then return end
		local reelY = reel.Position.Y.Offset
		local centerLineY = reelClip.AbsoluteSize.Y / 2
		local centerInReel = centerLineY - reelY
		local closestIndex = math.floor(centerInReel / STEP + 0.5)
		
		if closestIndex ~= lastPoppedIndex and closestIndex >= 0 then
			if lastPoppedIndex >= 0 then
				local oldCard = reel:FindFirstChild("Card" .. lastPoppedIndex)
				if oldCard then
					local bw = oldCard:GetAttribute("BaseWidth")
					local bh = oldCard:GetAttribute("BaseHeight")
					TweenService:Create(oldCard, TweenInfo.new(0.15), {Size = UDim2.fromOffset(bw, bh)}):Play()
				end
			end
			local newCard = reel:FindFirstChild("Card" .. closestIndex)
			if newCard then
				local bw = newCard:GetAttribute("BaseWidth")
				local bh = newCard:GetAttribute("BaseHeight")
				TweenService:Create(newCard, TweenInfo.new(0.1), {Size = UDim2.fromOffset(bw + 20, bh + 20)}):Play()
				if SFX and closestIndex > lastPoppedIndex + 0 then
					SFX.Play(gui, "tick", 0.15)
				end
			end
			lastPoppedIndex = closestIndex
		end
	end)
end

-- CUTSCENE MANAGER
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

-- MAIN REEL ANIMATION
local isRolling = false
local autoRollEnabled = false
local teaseCounter = math.random(3, 5)
local rollCount = 0

local function playReel(res)
	button.Active = false
	button.Text = "..."
	clearReel()
	
	reelContainer.Visible = true
	
	rollCount += 1
	local isTeaseRoll = (rollCount % teaseCounter == 0)
	if isTeaseRoll then
		teaseCounter = math.random(3, 5)
	end
	
	local totalCards = 60
	local winnerIndex = 54
	local teaseIndex = winnerIndex - 2 -- Default to before
	local isTeaseBefore = true
	
	if isTeaseRoll then
		isTeaseBefore = math.random() > 0.5
		if isTeaseBefore then
			teaseIndex = winnerIndex - 2
		else
			teaseIndex = winnerIndex + 2 -- After
		end
	end
	
	for i = 0, totalCards - 1 do
		local cardData
		if i == winnerIndex then
			cardData = res
		elseif isTeaseRoll and i == teaseIndex then
			cardData = rareAuras[math.random(1, #rareAuras)]
		else
			cardData = commonAuras[math.random(1, #commonAuras)]
		end
		local card = createCard(cardData, i)
		card.Parent = reel
	end
	
	reel.Size = UDim2.fromOffset(380, totalCards * STEP)
	task.wait(0.1)
	
	-- Math for Y Position
	local reelClipCenterY = reelClip.AbsoluteSize.Y / 2
	local getTargetY = function(index)
		local cardCenterY = index * STEP + (CARD_HEIGHT / 2)
		return reelClipCenterY - cardCenterY
	end
	
	local finalEndY = getTargetY(winnerIndex)
	reel.Position = UDim2.fromOffset(0, 0)
	
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 15}):Play()
	TweenService:Create(reelClip, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
	if SFX then SFX.Play(gui, "roll") end
	
	startCardPopTracker()
	
	if isTeaseRoll then
		if isTeaseBefore then
			-- SCENARIO 1: RARE IS BEFORE ACTUAL
			-- 1. Fast spin exactly to Rare
			local t1 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(0, getTargetY(teaseIndex))
			})
			t1:Play()
			t1.Completed:Wait()
			
			-- 2. Hard stop on Rare for 1 second (Mind game!)
			task.wait(1.0)
			
			-- 3. Skip to Actual (Fast forward)
			local t2 = TweenService:Create(reel, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(0, finalEndY)
			})
			t2:Play()
			t2.Completed:Wait()
		else
			-- SCENARIO 2: RARE IS AFTER ACTUAL
			-- 1. Fast spin exactly to Actual
			local t1 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(0, finalEndY)
			})
			t1:Play()
			t1.Completed:Wait()
			
			-- 2. Hard stop on Actual for 1 second
			task.wait(1.0)
			
			-- 3. Slowly creep forward towards Rare (Stop at edge!)
			local t2 = TweenService:Create(reel, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(0, getTargetY(winnerIndex + 0.6)) -- Creep past center
			})
			t2:Play()
			t2.Completed:Wait()
			
			-- 4. Hold at the edge for 0.5 seconds (Tension!)
			task.wait(0.5)
			
			-- 5. Smoothly pull back to exact center
			local t3 = TweenService:Create(reel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(0, finalEndY)
			})
			t3:Play()
			t3.Completed:Wait()
		end
	else
		-- NORMAL LONG SPIN (No tease)
		local spin = TweenService:Create(reel, TweenInfo.new(4.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(0, finalEndY)
		})
		spin:Play()
		spin.Completed:Wait()
	end
	
	if popConnection then popConnection:Disconnect(); popConnection = nil end
	
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	
	-- Impact Sound
	if SFX then 
		if res.Rarity >= 5000 then SFX.Play(gui, "legendary")
		elseif res.Rarity >= 1000 then SFX.Play(gui, "rare")
		else SFX.Play(gui, "reveal") end
	end
	
	-- UI Shake
	local shakeIntensity = res.Rarity >= 1000 and 6 or 2
	local t0 = os.clock()
	while os.clock() - t0 < 0.3 do
		local ox = (math.random() - 0.5) * shakeIntensity * 2
		local oy = (math.random() - 0.5) * shakeIntensity * 2
		shaker.Position = UDim2.fromOffset(ox, oy)
		task.wait()
	end
	shaker.Position = UDim2.fromScale(0, 0)
	
	-- Highlight winner
	local winnerCard = reel:FindFirstChild("Card" .. winnerIndex)
	if winnerCard then
		local stroke = winnerCard:FindFirstChild("Stroke")
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.3), {Thickness = 8, Transparency = 0}):Play()
		end
	end
	
	button.Text = "ROLL"
	button.Active = true
	
	if res.Rarity >= 50000 then 
		CutsceneManager.Play(res)
	end
	
	task.wait(2)
	
	-- Fade out UI completely
	TweenService:Create(reelClip, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	for _, card in ipairs(reel:GetChildren()) do
		if card:IsA("GuiObject") then
			TweenService:Create(card, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			for _, child in ipairs(card:GetDescendants()) do
				if child:IsA("TextLabel") then
					TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
				elseif child:IsA("UIStroke") then
					TweenService:Create(child, TweenInfo.new(0.5), {Transparency = 1}):Play()
				end
			end
		end
	end
	TweenService:Create(centerLine, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(centerGlow, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	
	task.wait(0.6)
	reelContainer.Visible = false
end

-- ROLL ORCHESTRATOR
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

print("RollUI loaded! (Vertical Reel V4 - Hard Stop Mind Game)")
]==]

print("✅ VERTICAL REEL V4 APPLIED!")
print("🧠 The reel now fully STOPS for 1 second to trick the player before creeping!")

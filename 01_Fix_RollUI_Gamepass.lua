-- ═══════════════════════════════════════════════════════════
-- 🔧 ROLL UI: FIX AUTO-SKIP PURCHASE
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- (Fixes the gamepass so it activates instantly upon purchase!)
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
local MarketplaceService = game:GetService("MarketplaceService")

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
local AUTO_SKIP_GAMEPASS_ID = 12345678 
local LEGENDARY_THRESHOLD = 5000

local auraNames, commonAuras, rareAuras = {}, {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a)
		if a.Rarity < 100 then table.insert(commonAuras, a) end
		if a.Rarity >= 1000 and a.Rarity < LEGENDARY_THRESHOLD then table.insert(rareAuras, a) end
	end
end
if #auraNames == 0 then auraNames = { {Name="...", Color=Color3.fromRGB(255,255,255), Tier="Common", Rarity=1} } end
if #commonAuras == 0 then commonAuras = auraNames end
if #rareAuras == 0 then rareAuras = auraNames end

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

local shaker = Instance.new("Frame")
shaker.Size = UDim2.fromScale(1, 1); shaker.Position = UDim2.fromScale(0, 0)
shaker.BackgroundTransparency = 1; shaker.Parent = gui

local reelContainer = Instance.new("Frame")
reelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
reelContainer.Size = UDim2.fromOffset(400, 700)
reelContainer.Position = UDim2.fromScale(0.5, 0.45)
reelContainer.BackgroundTransparency = 1
reelContainer.Visible = false
reelContainer.ZIndex = 5
reelContainer.Parent = shaker

local reelClip = Instance.new("Frame")
reelClip.Size = UDim2.fromScale(1, 1)
reelClip.Position = UDim2.fromScale(0, 0)
reelClip.BackgroundTransparency = 1
reelClip.ClipsDescendants = true
reelClip.ZIndex = 5
reelClip.Parent = reelContainer

local centerBeam = Instance.new("Frame")
centerBeam.AnchorPoint = Vector2.new(0.5, 0.5)
centerBeam.Size = UDim2.fromOffset(440, 30)
centerBeam.Position = UDim2.fromScale(0.5, 0.5)
centerBeam.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerBeam.BackgroundTransparency = 0.8
centerBeam.BorderSizePixel = 0
centerBeam.ZIndex = 9
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(1, 0); cbCorner.Parent = centerBeam
local cbGrad = Instance.new("UIGradient")
cbGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
cbGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.2),
	NumberSequenceKeypoint.new(1, 1)
})
cbGrad.Parent = centerBeam
centerBeam.Parent = reelClip

local reel = Instance.new("Frame")
reel.Size = UDim2.fromOffset(380, 0)
reel.Position = UDim2.fromScale(0, 0)
reel.BackgroundTransparency = 1
reel.Parent = reelClip

local topResultText = Instance.new("TextLabel")
topResultText.AnchorPoint = Vector2.new(0.5, 0.5)
topResultText.Size = UDim2.fromOffset(600, 80)
topResultText.Position = UDim2.fromScale(0.5, 0.15)
topResultText.Text = ""
topResultText.Font = Enum.Font.GothamBlack
topResultText.TextScaled = true
topResultText.BackgroundTransparency = 1
topResultText.TextColor3 = Color3.fromRGB(255, 255, 255)
topResultText.TextTransparency = 1
topResultText.ZIndex = 20
topResultText.Parent = shaker

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.fromOffset(180, 50)
button.Position = UDim2.fromScale(0.5, 0.92)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack; button.TextSize = 24
button.BackgroundColor3 = Color3.fromRGB(80, 120, 255); button.TextColor3 = Color3.fromRGB(255,255,255)
button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.2, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5)
autoBtn.Size = UDim2.fromOffset(100, 40)
autoBtn.Position = UDim2.fromScale(0.35, 0.92)
autoBtn.Text = "AUTO"
autoBtn.Font = Enum.Font.GothamBold; autoBtn.TextSize = 18
autoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); autoBtn.TextColor3 = Color3.fromRGB(150,150,150)
autoBtn.ZIndex = 20
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.2, 0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local skipBtn = Instance.new("TextButton")
skipBtn.AnchorPoint = Vector2.new(0.5, 0.5)
skipBtn.Size = UDim2.fromOffset(100, 40)
skipBtn.Position = UDim2.fromScale(0.65, 0.92)
skipBtn.Text = "SKIP"
skipBtn.Font = Enum.Font.GothamBold; skipBtn.TextSize = 18
skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); skipBtn.TextColor3 = Color3.fromRGB(150,150,150)
skipBtn.ZIndex = 20
local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0.2, 0); sbCorner.Parent = skipBtn
skipBtn.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1); banner.Position = UDim2.fromScale(0.15, 0.1)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(30,30,45); banner.TextColor3 = Color3.fromRGB(255,215,0)
banner.BackgroundTransparency = 1; banner.Visible = false; banner.ZIndex = 30
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

local CARD_HEIGHT = 120
local CARD_WIDTH = 360
local CARD_GAP = 30
local STEP = CARD_HEIGHT + CARD_GAP

local function createCard(auraData, index)
	local card = Instance.new("Frame")
	card.Name = "Card" .. index
	card.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromOffset(190, index * STEP + (CARD_HEIGHT / 2))
	card.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	card.BackgroundTransparency = 0.4 
	card.BorderSizePixel = 0
	card.ZIndex = 5
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Thickness = 3
	stroke.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	stroke.Transparency = 0.2
	stroke.Parent = card
	
	local grad = Instance.new("UIGradient")
	grad.Name = "BorderGradient"
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, auraData.Color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	grad.Rotation = 90
	grad.Parent = stroke
	
	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.fromScale(0.9, 0.6)
	nameText.Position = UDim2.fromScale(0.05, 0.1)
	nameText.BackgroundTransparency = 1
	nameText.Text = auraData.Name
	nameText.Font = Enum.Font.GothamBlack
	nameText.TextScaled = true
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.ZIndex = 6
	nameText.Parent = card
	
	local rarityText = Instance.new("TextLabel")
	rarityText.Size = UDim2.fromScale(0.9, 0.25)
	rarityText.Position = UDim2.fromScale(0.05, 0.7)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = "1 in " .. auraData.Rarity
	rarityText.Font = Enum.Font.GothamMedium
	rarityText.TextScaled = true
	rarityText.TextColor3 = auraData.Color or Color3.fromRGB(200, 200, 200)
	rarityText.ZIndex = 6
	rarityText.Parent = card
	
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

local CutsceneManager = {}
function CutsceneManager.Play(res)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1; overlay.ZIndex = 15; overlay.Parent = gui
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
	topResultText.Text = res.DisplayName or res.Name
	topResultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	topResultText.TextTransparency = 0
	task.wait(3)
	TweenService:Create(overlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(topResultText, TweenInfo.new(1), {TextTransparency = 1}):Play()
	task.wait(1); overlay:Destroy()
end

local isRolling = false
local autoRollEnabled = false
local teaseCounter = math.random(3, 5)
local rollCount = 0

local function playReel(res, isSkipped)
	button.Active = false; button.Text = "..."
	clearReel()
	reelContainer.Visible = true
	rollCount += 1
	
	local isTeaseRoll = (rollCount % teaseCounter == 0) and not isSkipped
	if isTeaseRoll then teaseCounter = math.random(3, 5) end
	
	local totalCards = 60
	local winnerIndex = 54
	local teaseIndex = winnerIndex - 2 
	local isTeaseBefore = true
	
	if isTeaseRoll then
		isTeaseBefore = math.random() > 0.5
		teaseIndex = isTeaseBefore and (winnerIndex - 2) or (winnerIndex + 2)
	end
	
	for i = 0, totalCards - 1 do
		local cardData
		if i == winnerIndex then cardData = res
		elseif isTeaseRoll and i == teaseIndex then cardData = rareAuras[math.random(1, #rareAuras)]
		else cardData = commonAuras[math.random(1, #commonAuras)] end
		createCard(cardData, i).Parent = reel
	end
	
	reel.Size = UDim2.fromOffset(380, totalCards * STEP)
	task.wait(0.1)
	
	local reelClipCenterY = reelClip.AbsoluteSize.Y / 2
	local getTargetY = function(index) return reelClipCenterY - (index * STEP + (CARD_HEIGHT / 2)) end
	local finalEndY = getTargetY(winnerIndex)
	reel.Position = UDim2.fromOffset(0, 0)
	
	if isSkipped then
		reel.Position = UDim2.fromOffset(0, finalEndY)
		blur.Size = 15
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
		local shakeIntensity = 10
		local t0 = os.clock()
		while os.clock() - t0 < 0.3 do
			shaker.Position = UDim2.fromOffset((math.random() - 0.5) * shakeIntensity * 2, (math.random() - 0.5) * shakeIntensity * 2)
			task.wait()
		end
		shaker.Position = UDim2.fromScale(0, 0)
		
		topResultText.Text = (res.DisplayName or res.Name) .. " (1 in " .. res.Rarity .. ")"
		topResultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
		topResultText.TextTransparency = 0
		if SFX then SFX.Play(gui, "reveal") end
		
		task.wait(1.0)
		TweenService:Create(topResultText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		for _, card in ipairs(reel:GetChildren()) do
			if card:IsA("GuiObject") then card.Visible = false end
		end
		reelContainer.Visible = false
		button.Text = "ROLL"; button.Active = true
		return
	end
	
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 10}):Play()
	if SFX then SFX.Play(gui, "roll") end
	
	if isTeaseRoll then
		if isTeaseBefore then
			local t1 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, getTargetY(teaseIndex - 0.2))})
			t1:Play(); t1.Completed:Wait()
			task.wait(0.6) 
			local t2 = TweenService:Create(reel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
			t2:Play(); t2.Completed:Wait()
		else
			local t1 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
			t1:Play(); t1.Completed:Wait()
			task.wait(0.6) 
			local t2 = TweenService:Create(reel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, getTargetY(winnerIndex + 0.8))})
			t2:Play(); t2.Completed:Wait()
			task.wait(0.3)
			local t3 = TweenService:Create(reel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
			t3:Play(); t3.Completed:Wait()
		end
	else
		local spin = TweenService:Create(reel, TweenInfo.new(4.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
		spin:Play(); spin.Completed:Wait()
	end
	
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	if SFX then 
		if res.Rarity >= 5000 then SFX.Play(gui, "legendary")
		elseif res.Rarity >= 1000 then SFX.Play(gui, "rare")
		else SFX.Play(gui, "reveal") end
	end
	
	local shakeIntensity = res.Rarity >= 1000 and 6 or 2
	local t0 = os.clock()
	while os.clock() - t0 < 0.3 do
		shaker.Position = UDim2.fromOffset((math.random() - 0.5) * shakeIntensity * 2, (math.random() - 0.5) * shakeIntensity * 2)
		task.wait()
	end
	shaker.Position = UDim2.fromScale(0, 0)
	
	button.Text = "ROLL"; button.Active = true
	if res.Rarity >= 50000 then CutsceneManager.Play(res) end
	task.wait(2)
	
	TweenService:Create(reelClip, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	for _, card in ipairs(reel:GetChildren()) do
		if card:IsA("GuiObject") then
			TweenService:Create(card, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			for _, child in ipairs(card:GetDescendants()) do
				if child:IsA("TextLabel") then TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
				elseif child:IsA("UIStroke") then TweenService:Create(child, TweenInfo.new(0.5), {Transparency = 1}):Play() end
			end
		end
	end
	TweenService:Create(centerBeam, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	task.wait(0.6); reelContainer.Visible = false
end

-- 💥 INSTANT GAMEPASS UNLOCK LOGIC
local hasSkipGamepass = false
local autoSkipEnabled = false

local function updateSkipUI()
	if autoSkipEnabled then
		skipBtn.Text = "SKIP: ON"
		skipBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0); skipBtn.TextColor3 = Color3.fromRGB(255,255,255)
	else
		skipBtn.Text = "SKIP"
		skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); skipBtn.TextColor3 = Color3.fromRGB(150,150,150)
	end
end

local function checkGamepass()
	pcall(function()
		hasSkipGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_SKIP_GAMEPASS_ID)
	end)
	if hasSkipGamepass then
		autoSkipEnabled = true
	end
	updateSkipUI()
end
task.spawn(checkGamepass)

-- LISTEN FOR PURCHASE IN REAL-TIME!
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, purchased)
	if plr == player and id == AUTO_SKIP_GAMEPASS_ID and purchased then
		hasSkipGamepass = true
		autoSkipEnabled = true
		updateSkipUI()
	end
end)

local function doRoll()
	if isRolling then return end
	isRolling = true
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	while not gotResult do task.wait(0.02) end
	if not res then isRolling = false; return end

	local shouldSkip = autoSkipEnabled and (res.Rarity < LEGENDARY_THRESHOLD)
	playReel(res, shouldSkip)
	isRolling = false
end

button.MouseButton1Click:Connect(doRoll)

autoBtn.MouseButton1Click:Connect(function()
	autoRollEnabled = not autoRollEnabled
	if autoRollEnabled then autoBtn.Text = "AUTO: ON"; autoBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0); autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
	else autoBtn.Text = "AUTO"; autoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); autoBtn.TextColor3 = Color3.fromRGB(150,150,150) end
	if SFX then SFX.Play(gui, "click") end
end)

skipBtn.MouseButton1Click:Connect(function()
	if hasSkipGamepass then
		autoSkipEnabled = not autoSkipEnabled
		updateSkipUI()
		if SFX then SFX.Play(gui, "click") end
	else
		MarketplaceService:PromptGamePassPurchase(player, AUTO_SKIP_GAMEPASS_ID)
	end
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
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.1)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)

print("RollUI loaded! (Auto-Skip Purchase Fixed)")
]==]

print("✅ ROLL UI APPLIED! (Auto-Skip Purchase Fix)")

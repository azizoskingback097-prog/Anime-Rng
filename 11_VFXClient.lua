-- ═══════════════════════════════════════════════════════════
-- ✨ VFX CLIENT — LocalScript | PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- When you equip an aura, this script creates cool VFX on your
-- character (particles, fire, smoke, lights). When you unequip,
-- it removes everything cleanly. VFX follows you and reattaches
-- after respawn.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Edit VFXData (in ReplicatedStorage) to change/add effects
--   • This script just READS VFXData and creates instances
--
-- 🔗 RELATED SCRIPTS:
--   • VFXData → defines all VFX configs
--   • GameServer → fires EquippedChangedEvent when you equip/unequip
--   • AuraData → reads aura tiers for VFX lookup
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local AuraData  = require(ReplicatedStorage:WaitForChild("AuraData"))
local VFXData   = require(ReplicatedStorage:WaitForChild("VFXData"))

-- the remote that tells us when equip changes
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")

--[[
────────────────────────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: VFX Display Settings
HOW TO USE: Tweak how VFX appears on the character.
  • FADE_IN_TIME = how fast VFX fades in when equipped (seconds)
  • FADE_OUT_TIME = how fast VFX fades out when unequipped (seconds)
  • VFX_TAG = the tag used to track VFX instances for cleanup
────────────────────────────────────────────────────────────
]]
local FADE_IN_TIME  = 0.5
local FADE_OUT_TIME = 0.8
local VFX_TAG       = "AuraVFX"

-- ═══════════════════════════════════════════════════════════
-- 🧹 CLEANUP: remove all old VFX from a character
-- ═══════════════════════════════════════════════════════════
local function clearVFX(character)
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:GetAttribute(VFX_TAG) then
			-- stop emitting so existing particles fade naturally
			if obj:IsA("ParticleEmitter") then
				obj.Enabled = false
			elseif obj:IsA("Fire") or obj:IsA("Smoke") then
				obj.Enabled = false
			end
			obj:Destroy()
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- 🏗️ EFFECT CREATORS — one function per effect type
-- Each creates the instance, tags it for cleanup, returns it
-- ═══════════════════════════════════════════════════════════

local function createParticle(part, cfg)
	local emitter = Instance.new("ParticleEmitter")
	if cfg.Color        then emitter.Color = cfg.Color end
	if cfg.Size         then emitter.Size = cfg.Size end
	if cfg.Transparency then emitter.Transparency = cfg.Transparency end
	if cfg.Lifetime     then emitter.Lifetime = cfg.Lifetime end
	if cfg.Rate         then emitter.Rate = cfg.Rate end
	if cfg.Speed        then emitter.Speed = cfg.Speed end
	if cfg.SpreadAngle  then emitter.SpreadAngle = cfg.SpreadAngle end
	if cfg.Acceleration then emitter.Acceleration = cfg.Acceleration end
	if cfg.Rotation     then emitter.Rotation = cfg.Rotation end
	if cfg.RotSpeed     then emitter.Rotation = cfg.RotSpeed end
	if cfg.LightEmission then emitter.LightEmission = cfg.LightEmission end
	if cfg.Texture and cfg.Texture ~= "" then emitter.Texture = cfg.Texture end
	emitter.Enabled = false  -- start disabled (we fade in)
	emitter:SetAttribute(VFX_TAG, true)
	emitter.Parent = part
	return emitter
end

local function createFire(part, cfg)
	local fire = Instance.new("Fire")
	fire.Color = cfg.Color or Color3.fromRGB(255, 100, 30)
	fire.SecondaryColor = cfg.SecondaryColor or Color3.fromRGB(255, 200, 50)
	fire.Size = cfg.Size or 2
	fire.Heat = cfg.Heat or 15
	fire.Enabled = false
	fire:SetAttribute(VFX_TAG, true)
	fire.Parent = part
	return fire
end

local function createSmoke(part, cfg)
	local smoke = Instance.new("Smoke")
	smoke.Color = cfg.Color or Color3.fromRGB(150, 150, 150)
	smoke.Size = cfg.Size or 1.2
	smoke.Opacity = cfg.Opacity or 0.4
	smoke.RiseVelocity = cfg.RiseAcceleration or 1.5
	smoke.Enabled = false
	smoke:SetAttribute(VFX_TAG, true)
	smoke.Parent = part
	return smoke
end

local function createLight(part, cfg)
	local light = Instance.new("PointLight")
	light.Color = cfg.Color or Color3.fromRGB(255, 255, 255)
	light.Brightness = 0  -- start at 0 (fade in)
	light.Range = cfg.Range or 10
	light:SetAttribute(VFX_TAG, true)
	light:SetAttribute("TargetBrightness", cfg.Brightness or 1)
	light.Parent = part
	return light
end

-- ═══════════════════════════════════════════════════════════
-- 🎬 APPLY VFX: create all effects for a VFX config
-- ═══════════════════════════════════════════════════════════
local function applyVFX(character, vfxConfig)
	if not character or not vfxConfig then return end

	local createdEffects = {}

	for _, effect in ipairs(vfxConfig.Effects) do
		-- find the body part
		local part = character:FindFirstChild(effect.Part)
		if not part then
			-- fallback: use HumanoidRootPart if the specified part doesn't exist (R6 compat)
			part = character:FindFirstChild("HumanoidRootPart")
		end
		if not part then continue end

		local instance
		if effect.Type == "Particle" then
			instance = createParticle(part, effect)
		elseif effect.Type == "Fire" then
			instance = createFire(part, effect)
		elseif effect.Type == "Smoke" then
			instance = createSmoke(part, effect)
		elseif effect.Type == "Light" then
			instance = createLight(part, effect)
		end

		if instance then
			table.insert(createdEffects, instance)
		end
	end

	-- fade in all effects
	task.spawn(function()
		task.wait(0.1)  -- small delay so they all spawn first
		for _, inst in ipairs(createdEffects) do
			if inst:IsA("ParticleEmitter") or inst:IsA("Fire") or inst:IsA("Smoke") then
				inst.Enabled = true
			elseif inst:IsA("PointLight") then
				local target = inst:GetAttribute("TargetBrightness") or 1
				TweenService:Create(inst, TweenInfo.new(FADE_IN_TIME), { Brightness = target }):Play()
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- 🔍 PARSE AURA: handle mutated auras ("Sandy|Tempest" → "Tempest")
-- ═══════════════════════════════════════════════════════════
local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then
		return string.sub(stored, sep + 1)  -- return base aura name
	end
	return stored
end

-- ═══════════════════════════════════════════════════════════
-- 🎮 MAIN: track current equipped aura + apply VFX
-- ═══════════════════════════════════════════════════════════
local currentEquipped = nil

local function updateVFX()
	local character = player.Character
	if not character then return end

	-- clean up old VFX
	clearVFX(character)

	-- if nothing equipped, we're done (VFX removed)
	if not currentEquipped or currentEquipped == "" then return end

	-- parse mutated name → base aura
	local baseName = parseAuraName(currentEquipped)

	-- look up aura in AuraData to get its tier
	local aura = AuraData.GetByName(baseName)
	local tier = aura and aura.Tier or nil

	-- look up the VFX config
	local vfxConfig = VFXData.GetVFXForAura(baseName, tier)
	if vfxConfig then
		applyVFX(character, vfxConfig)
	end
end

-- listen for equip changes from the server
EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	currentEquipped = auraName
	updateVFX()
end)

-- reattach VFX after respawn
player.CharacterAdded:Connect(function()
	task.wait(1)  -- wait for character to fully load
	updateVFX()
end)

print("✨ VFXClient loaded! (7 VFX types ready)")

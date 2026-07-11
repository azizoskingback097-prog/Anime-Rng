-- ═══════════════════════════════════════════════════════════
-- 🔢  SYS2 #1 — NUMBER FORMATTER  (the ONE place numbers get pretty)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  ReplicatedStorage ▸ NumberFormatter  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 Use this EVERYWHERE a number becomes text:
--       coins, prices, multipliers, rarity values, counts, etc.
--   Both server & client can `require` it.
--
--   local F = require(ReplicatedStorage:WaitForChild("NumberFormatter"))
--   F.FormatNumber(1500)        --> "1.5K"
--   F.FormatNumber(1250000)     --> "1.25M"
--   F.FormatOddsNumber(70000)   --> "70K"   (for "1 in 70K" flex text)
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("NumberFormatter"); if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "NumberFormatter"
m.Parent = RS
m.Source = [====[
local NumberFormatter = {}

--[[
═══════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: GLOBAL NUMBER FORMATTING
═══════════════════════════════════════════════════════════
  DECIMALS      : max decimals shown (0, 1, or 2). Trailing zeros
                  are always trimmed, so 1.0 -> "1", 1.50 -> "1.5".
  SUFFIXES      : scale labels. Add more to support bigger numbers.
                  K=thousand, M=million, B=billion, T=trillion,
                  Qa=quadrillion, Qi=quintillion...
────────────────────────────────────────────────────────────
]]
NumberFormatter.DECIMALS = 2
NumberFormatter.SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp" }

-- internal: format a 0..1000 value with up to N decimals, trim trailing zeros/dot
local function trim(n, decimals)
	decimals = decimals or NumberFormatter.DECIMALS
	local fmt = "%." .. tostring(decimals) .. "f"
	local s = string.format(fmt, n)
	s = s:gsub("(%..-)0+$", "%1")   -- trim trailing zeros after a dot
	s = s:gsub("%.$", "")           -- trim dangling dot
	return s
end

--[[
  FormatNumber(n) → string
    0,1,999      -> "0","1","999"
    1000         -> "1K"
    1500         -> "1.5K"
    1000000      -> "1M"
    1250000      -> "1.25M"
    1000000000   -> "1B"
]]
function NumberFormatter.FormatNumber(n)
	n = tonumber(n) or 0
	if n < 0 then return "-" .. NumberFormatter.FormatNumber(-n) end
	n = math.floor(n)                 -- whole coins only
	local suffixes = NumberFormatter.SUFFIXES
	local i = 1
	while n >= 1000 and i < #suffixes do
		n = n / 1000
		i = i + 1
	end
	return trim(n) .. suffixes[i]
end

--[[
  FormatOddsNumber(x) → string    (for "1 in X" flex text above the player)
  GOAL: keep the NUMBER part short (~4 chars max).
    x <= 9999   -> plain integer ("1000","7777","9999")
    x >= 10000  -> abbreviated, compact ("10K","250K","999K","1M","1.5M","12M","70K")
]]
function NumberFormatter.FormatOddsNumber(x)
	x = tonumber(x) or 0
	if x < 0 then return "-" .. NumberFormatter.FormatOddsNumber(-x) end
	x = math.floor(x)
	if x < 10000 then
		return tostring(x)            -- "1000" .. "9999"
	end
	-- abbreviate, keeping the number part compact (<=4 chars)
	local suffixes = { "K", "M", "B", "T", "Qa" }
	local div = 0
	while x >= 1000 and div < #suffixes do
		x = x / 1000
		div = div + 1
	end
	-- x is now in [1, 1000). Pick decimals to stay compact:
	--   < 10  -> up to 1 decimal  ("9.9")   e.g. 1.5M, 9.9B
	--   >= 10 -> 0 decimals       ("99","999") e.g. 70K, 250K, 999K
	local s
	if x < 10 then s = trim(x, 1) else s = tostring(math.floor(x)) end
	return s .. suffixes[div]
end

return NumberFormatter
]====]

print("✅ NumberFormatter created in ReplicatedStorage.")
print('   FormatNumber(1500)="'..require(m).FormatNumber(1500)..'"  FormatOddsNumber(70000)="'..require(m).FormatOddsNumber(70000)..'"')

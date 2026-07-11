# 📖 COMPLETE GUIDE v10 — Skybox, Day/Night, Announcements & Teaching Comments

---

## 📚 PART 1: HOW TO READ THE TEACHING COMMENTS

Every script now has **dashed comment blocks** around customizable sections:

```lua
--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Aura List
HOW TO USE: Add, remove, or edit aura entries here.
EXAMPLE:
  { Name = "YourAura", Rarity = 5000, Color = Color3.fromRGB(255,0,0), Tier = "Legendary" },
────────────────────────────────────────
]]
```

**Rule:** Anything inside a `📌 CUSTOMIZABLE SECTION` block is safe to edit.
Anything outside those blocks is engine logic — don't touch unless you know what you're doing.

---

## 🌌 PART 2: SKYBOX SYSTEM

### How it works
- Each weather can optionally have a `Skybox` field with 6 asset IDs
- When weather activates, WeatherClient creates/updates a `Sky` object in Lighting
- When weather returns to Clear, the skybox resets to default

### How to add a skybox (from Toolbox or Creator Marketplace)
1. **View → Toolbox** → search "skybox"
2. Insert one → find the **Sky** object inside it
3. Copy the 6 asset IDs (SkyboxBk, SkyboxDn, SkyboxFt, SkyboxLf, SkyboxRt, SkyboxUp)
4. Add them to your weather in WeatherData:
```lua
Skybox = {
    "rbxassetid://111111",  -- Bk (Back)
    "rbxassetid://222222",  -- Dn (Down)
    "rbxassetid://333333",  -- Ft (Front)
    "rbxassetid://444444",  -- Lf (Left)
    "rbxassetid://555555",  -- Rt (Right)
    "rbxassetid://666666",  -- Up (Up)
},
```

### Day/Night Skybox (optional)
In `WeatherData.TimeCycle`, you can set day and night skyboxes:
```lua
TimeCycle = {
    Enabled = true,
    DayDurationMinutes = 10,  -- 10 real minutes = full 24h cycle
    DaySkybox = nil,   -- {6 IDs} for daytime sky
    NightSkybox = nil,  -- {6 IDs} for nighttime sky
}
```

---

## 🌦️ PART 3: DAY/NIGHT CYCLE

### How it works
- Runs **continuously** in WeatherClient (client-side, smooth)
- Advances `ClockTime` from 0→24 over `DayDurationMinutes` real minutes
- **Pauses automatically** when a non-Clear weather is active (weather takes over lighting)
- **Resumes** when weather returns to Clear

### How to customize
In `WeatherData` → `TimeCycle` section:
```lua
TimeCycle = {
    Enabled = true,            -- set false to disable
    DayDurationMinutes = 10,   -- how long a full day takes (lower = faster cycle)
    StartTime = 6,             -- start hour (6 = morning, 18 = evening)
}
```

### How it integrates with Weather
```
Clear weather   → Day/Night cycle controls ClockTime (smooth sunrise/sunset)
Sandstorm       → Weather overrides ClockTime to 12 (midday sandy)
Blood Moon      → Weather overrides ClockTime to 0 (midnight, dark red)
Back to Clear   → Day/Night resumes from where it left off
```

---

## 📢 PART 4: DUAL ANNOUNCEMENT SYSTEM

### How it works
When a player pulls something rare (≥ ANNOUNCE_RARITY), TWO things happen:

**Part A — UI Banner** (top of screen)
- Animated banner slides in
- Text colored with the **rarity color** of the aura

**Part B — Chat Message** (Roblox chat)
```
⭐ Twix79i has obtained Sandy Tempest! (Legendary)
```
- Message colored with the **rarity color** (Legendary = gold, Rare = blue, etc.)

### How to customize
In `GameServer`:
```lua
local ANNOUNCE_RARITY = 1000  -- lower = more announcements (100 = almost every rare)
```
In `RollUI` (chat format):
```lua
local msg = "⭐ " .. info.Player .. " has obtained " .. info.Name .. "! (" .. info.Tier .. ")"
```

### Rarity colors (from AuraData)
| Tier | Example Colors |
|------|---------------|
| Common | Gray |
| Rare | Blue / Pink |
| Epic | Cyan |
| Legendary | Gold / Red |
| Mythic | Yellow / Purple |

Each aura defines its own Color — the announcement uses THAT specific color.

---

## 📝 QUICK REFERENCE: ALL CUSTOMIZABLE SECTIONS

| Script | Customizable Sections |
|--------|----------------------|
| `AuraData` | 📌 Aura List (add/remove auras) |
| `WeatherData` | 📌 Weathers List, 📌 Time Cycle, 📌 Mutation settings |
| `GameServer` | 📌 Admin List, 📌 Roll Settings, 📌 Announcement Threshold |
| `WeatherServer` | 📌 Chat Tips, 📌 Timing |
| `WeatherClient` | 📌 VFX Settings, 📌 Day/Night display |
| `RollUI` | 📌 Animation Settings, 📌 UI Theme, 📌 Announcement Format |
| `InventoryUI` | 📌 Layout, 📌 Colors |
| `StatsUI` | 📌 Panel Position, 📌 Colors |
| `AdminUI` | 📌 Button Position |

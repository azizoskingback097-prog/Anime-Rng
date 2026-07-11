# 🌦️ WEATHER — How to Customize Everything

Your weather system lives in **`ReplicatedStorage ▸ WeatherData`** (a ModuleScript).
Three scripts read it:
- **WeatherServer** — picks a random weather every few minutes + chat tips
- **WeatherClient** — applies the lighting, skybox, and particles you see
- **GameServer** — applies the **mutations** (Sandy / Cosmic / Cursed) to your rolls

You edit **only `WeatherData`** — no other scripts. Here's how. 🎨

---

## 🕐 1. Day / Night Cycle
At the top of `WeatherData`:
```lua
WeatherData.TimeCycle = {
    Enabled = true,              -- turn the whole cycle on/off
    DayDurationMinutes = 10,     -- real minutes for a full 24h cycle (lower = faster)
    StartTime = 6,               -- 0=midnight, 6=dawn, 12=noon, 18=dusk
    DaySkybox = nil,             -- optional {6 image IDs} for daytime sky
    NightSkybox = nil,           -- optional {6 image IDs} for nighttime sky
}
```
> Want a faster cycle? Set `DayDurationMinutes = 5`. Want it frozen at noon? `Enabled = false`.

---

## ☁️ 2. The Weather List
Each weather is one `{ }` block in `WeatherData.Weathers`. Here's what every field does:

```lua
{
    Name      = "Sandstorm",                 -- the ID (used by mutations, admin, dialogue)
    Weight    = 25,                          -- how OFTEN it's picked (higher = more common). Clear=50, rare ones=10
    Duration  = { 60, 120 },                 -- how long it lasts: random between 60–120 seconds

    Mutation = {                             -- OPTIONAL: chance to mutate rolled auras
        Chance = 0.10,                       -- 0.10 = 10% chance per roll
        Name   = "Sandy",                    -- mutation name (Sandy / Cosmic / Cursed / your own)
        Color  = Color3.fromRGB(220,190,140),-- tint applied to the aura
    },

    Lighting = {                             -- how the world LOOKS during this weather
        ClockTime = 12,                      -- 0–24 (time of day)
        FogColor  = Color3.fromRGB(200,170,120),
        FogEnd    = 150,                     -- lower = thicker fog
        Ambient   = Color3.fromRGB(180,150,100),
        OutdoorAmbient = Color3.fromRGB(200,170,120),
        Brightness = 1.5,
        ColorShift_Top    = Color3.fromRGB(40,30,10),
        ColorShift_Bottom = Color3.fromRGB(40,30,10),
    },

    Skybox = {                               -- 6 sky image IDs, OR nil for default sky
        "rbxassetid://111",  -- Bk (back)
        "rbxassetid://222",  -- Dn (down/floor)
        "rbxassetid://333",  -- Ft (front)
        "rbxassetid://444",  -- Lf (left)
        "rbxassetid://555",  -- Rt (right)
        "rbxassetid://666",  -- Up (up/sky)
    },

    Particles = {                            -- OPTIONAL: particle effects (sand, embers, snow...)
        {
            Color = Color3.fromRGB(210,180,140),
            Rate = 300,                      -- particles per second
            Speed = NumberRange.new(15,30),
            Lifetime = NumberRange.new(4,7),
            Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4),NumberSequenceKeypoint.new(1,1)}),
            Texture = "",                    -- "" = default square; or rbxassetid://image
        },
    },

    BannerText  = "🌪️  SANDSTORM!  10% chance for SANDY mutations!",  -- big announcement text
    BannerColor = Color3.fromRGB(220,190,140),                       -- banner accent color
},
```

---

## ➕ 3. Add a NEW Weather (step by step)
1. Copy a whole `{ }` block (e.g. Sandstorm's).
2. Paste it inside `WeatherData.Weathers` and change the values:
```lua
{
    Name = "Frost", Weight = 10, Duration = { 60, 90 },
    Mutation = { Chance = 0.12, Name = "Frosted", Color = Color3.fromRGB(150,220,255) },
    Lighting = { ClockTime = 9, FogColor = Color3.fromRGB(200,230,255), FogEnd = 120,
                 Ambient = Color3.fromRGB(150,180,210), OutdoorAmbient = Color3.fromRGB(180,210,235),
                 Brightness = 1.4 },
    Skybox = nil,
    Particles = { { Color = Color3.fromRGB(230,240,255), Rate = 120, Speed = NumberRange.new(2,6),
                    Lifetime = NumberRange.new(6,10),
                    Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,1)}),
                    Texture = "" } },
    BannerText = "❄️  FROST!  12% chance for FROSTED mutations!",
    BannerColor = Color3.fromRGB(150,220,255),
},
```
3. Save (Ctrl+S). That's it — it's now in the random rotation automatically. ✨

> 🎯 To make a weather **rarer**: lower its `Weight`. To make it last **longer**: raise `Duration`.
> To force a weather RIGHT NOW: open your **Admin panel → Force Weather** (uses the `Name`).

---

## 🧬 4. Mutations (the special part)
A `Mutation` makes your rolled aura get a prefix + tint. Your defaults:
| Weather | Mutation | Coin multiplier |
|---------|----------|-----------------|
| Sandstorm | **Sandy** | 1.25× coins |
| Blood Moon | **Cursed** | 1.75× coins |
| Cosmic Rift | **Cosmic** | 1.5× coins |

These multipliers live in **`GameServer`** (`MUTATION_MULTIPLIERS`). If you invent a new mutation name (like "Frosted") and want it to give bonus coins, add it there too:
```lua
local MUTATION_MULTIPLIERS = { Sandy = 1.25, Cosmic = 1.5, Cursed = 1.75, Frosted = 1.3 }
```

---

## 🌌 5. Skybox Troubleshooting
> **"My sky is solid BLACK!"** → You used an **Asset ID** instead of an **Image ID**.
> Fix: in Studio, insert a `Sky` object → read the `SkyboxBk/Dn/Ft/Lf/Rt/Up` property values → **those** are the correct image IDs to put in the `Skybox = { }` list.

---

## ⚙️ 6. How often weather changes
Controlled in **`ServerScriptService ▸ WeatherServer`** (the cycle timing + chat tips). The `Weight` of each weather in `WeatherData` controls the *odds*; WeatherServer controls *when* it rolls.

---

### Quick reference — what to change for common requests
| I want to... | Edit this |
|---|---|
| Make weather change faster/slower | `WeatherServer` timing + each weather's `Duration` |
| Make a weather rarer | its `Weight` (lower = rarer) |
| Change the sky / fog / lighting | that weather's `Lighting` + `Skybox` |
| Add particles (snow, rain, embers) | that weather's `Particles` |
| Add a brand-new weather | copy a block in `WeatherData.Weathers` |
| Change mutation odds | that weather's `Mutation.Chance` |
| Give a mutation bonus coins | `GameServer` → `MUTATION_MULTIPLIERS` |

Have fun brewing up some wild weather! ⛈️🌈

# 📖 GUIDE: How to Add Skyboxes & New Weathers

---

## 🌌 PART 1: HOW TO LOAD A SKYBOX FROM THE TOOLBOX

A Roblox skybox is made of **6 images** (the 6 sides of a box surrounding the world):
- **Bk** (Back), **Ft** (Front), **Lf** (Left), **Rt** (Right), **Up** (Top), **Dn** (Down)

### Step-by-step:

1. **Open the Toolbox** (View → Toolbox)
2. **Search "skybox"** (or "skybox sand", "skybox night", etc.)
3. **Find one you like** → right-click → **Insert** (it goes into Workspace)
4. The inserted object is usually a **Model** or **Sky** object
5. **Find the Sky object** inside it — it has 6 properties:
   ```
   SkyboxBk = "rbxassetid://1234567890"
   SkyboxDn = "rbxassetid://1234567891"
   SkyboxFt = "rbxassetid://1234567892"
   SkyboxLf = "rbxassetid://1234567893"
   SkyboxRt = "rbxassetid://1234567894"
   SkyboxUp = "rbxassetid://1234567895"
   ```
6. **Copy those 6 asset IDs** (the numbers after `rbxassetid://`)
7. **Paste them into your weather's Skybox field** in `WeatherData`:
   ```lua
   Skybox = {
       "rbxassetid://1234567890",  -- Bk
       "rbxassetid://1234567891",  -- Dn
       "rbxassetid://1234567892",  -- Ft
       "rbxassetid://1234567893",  -- Lf
       "rbxassetid://1234567894",  -- Rt
       "rbxassetid://1234567895",  -- Up
   },
   ```

### ⚠️ Important Notes:
- **Order matters!** Bk, Dn, Ft, Lf, Rt, Up (alphabetical)
- If you set `Skybox = nil`, the skybox **doesn't change** (keeps whatever was there)
- The WeatherClient creates/updates a `Sky` object in Lighting automatically
- You can find skyboxes on the Roblox Creator Marketplace too

### 💡 Tip: Test a skybox first
Insert it into Workspace → drag the Sky object into Lighting → press Play.
If it looks good, grab the IDs and put them in WeatherData!

---

## 🌪️ PART 2: HOW TO ADD A NEW WEATHER

Adding a weather is just **copy-pasting a block** in `WeatherData` and filling in the fields.
Here's what each field does:

### The Template (copy this!):
```lua
{
    Name     = "YOUR WEATHER NAME",        -- shown in banner + used by admin
    Weight   = 20,                          -- higher = appears more often (vs other weathers)
    Duration = { 60, 120 },                 -- [min_seconds, max_seconds] it lasts

    -- 🧬 MUTATION (what happens to auras rolled during this weather)
    Mutation = {
        Chance = 0.15,                      -- 0.15 = 15% chance to mutate
        Name   = "YOUR MUTATION NAME",      -- prefix added to aura (e.g. "Frostbite Tempest")
        Color  = Color3.fromRGB(100, 200, 255),  -- color of mutated auras
    },

    -- 💡 LIGHTING (how the world looks during this weather)
    Lighting = {
        ClockTime        = 14,              -- 0-24 (0=midnight, 12=noon, 14=afternoon)
        FogColor         = Color3.fromRGB(199, 217, 240),  -- fog tint
        FogEnd           = 100000,          -- how far you can see (low = thick fog)
        Ambient          = Color3.fromRGB(128, 128, 128),  -- indoor lighting tint
        OutdoorAmbient   = Color3.fromRGB(128, 128, 128),  -- outdoor lighting tint
        Brightness       = 2,               -- sun brightness (0=dark, 3=bright)
        ColorShift_Top    = Color3.fromRGB(0, 0, 0),       -- color shift on top of parts
        ColorShift_Bottom = Color3.fromRGB(0, 0, 0),       -- color shift on bottom of parts
    },

    -- 🌌 SKYBOX (optional — see Part 1 above)
    Skybox = nil,  -- or { "rbxassetid://...", ... } (6 IDs: Bk, Dn, Ft, Lf, Rt, Up)

    -- 🎇 PARTICLES (VFX that float around the player)
    Particles = {
        {
            Color        = Color3.fromRGB(255, 255, 255),  -- particle color
            Size         = NumberSequence.new(2),           -- particle size (can animate)
            Transparency = NumberSequence.new(0),           -- 0=opaque, 1=invisible
            Lifetime    = NumberRange.new(5, 10),           -- seconds before disappearing
            Rate         = 100,                             -- particles per second
            Speed        = NumberRange.new(5, 10),          -- how fast they shoot out
            SpreadAngle  = Vector2.new(45, 45),             -- how wide they spread
            Acceleration = Vector3.new(0, -10, 0),          -- gravity/wind (Y=-10 = falling)
            Texture      = "",                               -- "rbxassetid://..." for custom shape
        },
        -- you can add MORE particle emitters here! (each { } is a separate emitter)
    },

    -- 📢 BANNER (the message shown when weather starts)
    BannerText  = "❄️  YOUR WEATHER!  Auras have a 15% chance to be YOUR_MUTATION!",
    BannerColor = Color3.fromRGB(100, 200, 255),
},
```

---

## 💡 PART 3: EXAMPLE WEATHERS (ready to copy-paste!)

### ❄️ Example 1: BLIZZARD
```lua
{
    Name = "Blizzard", Weight = 20, Duration = { 60, 120 },
    Mutation = { Chance = 0.12, Name = "Frostbite", Color = Color3.fromRGB(150, 220, 255) },
    Lighting = {
        ClockTime = 11, FogColor = Color3.fromRGB(220, 235, 255), FogEnd = 200,
        Ambient = Color3.fromRGB(180, 200, 230), OutdoorAmbient = Color3.fromRGB(200, 220, 255),
        Brightness = 2.5, ColorShift_Top = Color3.fromRGB(20, 40, 60), ColorShift_Bottom = Color3.fromRGB(20, 40, 60),
    },
    Skybox = nil,
    Particles = {
        { Color = Color3.fromRGB(240, 250, 255),
          Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0.5) }),
          Transparency = NumberSequence.new(0.3), Lifetime = NumberRange.new(3, 6), Rate = 400,
          Speed = NumberRange.new(20, 40), SpreadAngle = Vector2.new(30, 30),
          Acceleration = Vector3.new(10, -15, 0), Texture = "" },
    },
    BannerText = "❄️  BLIZZARD!  Auras have a 12% chance to be FROSTBITE!",
    BannerColor = Color3.fromRGB(150, 220, 255),
},
```

### ⚡ Example 2: THUNDERSTORM
```lua
{
    Name = "Thunderstorm", Weight = 15, Duration = { 45, 90 },
    Mutation = { Chance = 0.15, Name = "Charged", Color = Color3.fromRGB(255, 255, 100) },
    Lighting = {
        ClockTime = 19, FogColor = Color3.fromRGB(40, 40, 60), FogEnd = 250,
        Ambient = Color3.fromRGB(50, 50, 70), OutdoorAmbient = Color3.fromRGB(60, 60, 80),
        Brightness = 0.5, ColorShift_Top = Color3.fromRGB(0, 0, 30), ColorShift_Bottom = Color3.fromRGB(0, 0, 30),
    },
    Skybox = nil,
    Particles = {
        { Color = Color3.fromRGB(150, 170, 200),
          Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) }),
          Transparency = NumberSequence.new(0.5), Lifetime = NumberRange.new(2, 4), Rate = 500,
          Speed = NumberRange.new(50, 80), SpreadAngle = Vector2.new(10, 10),
          Acceleration = Vector3.new(0, -50, 0), Texture = "" },
    },
    BannerText = "⚡  THUNDERSTORM!  Auras have a 15% chance to be CHARGED!",
    BannerColor = Color3.fromRGB(255, 255, 100),
},
```

### ☠️ Example 3: TOXIC SPORE
```lua
{
    Name = "Toxic Spore", Weight = 10, Duration = { 60, 90 },
    Mutation = { Chance = 0.20, Name = "Toxic", Color = Color3.fromRGB(100, 255, 50) },
    Lighting = {
        ClockTime = 16, FogColor = Color3.fromRGB(60, 100, 40), FogEnd = 180,
        Ambient = Color3.fromRGB(40, 80, 30), OutdoorAmbient = Color3.fromRGB(50, 100, 40),
        Brightness = 1, ColorShift_Top = Color3.fromRGB(0, 40, 0), ColorShift_Bottom = Color3.fromRGB(0, 40, 0),
    },
    Skybox = nil,
    Particles = {
        { Color = Color3.fromRGB(120, 255, 80),
          Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 1) }),
          Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
          Lifetime = NumberRange.new(6, 12), Rate = 150, Speed = NumberRange.new(1, 3),
          SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 2, 0), Texture = "" },
    },
    BannerText = "☠️  TOXIC SPORES!  Auras have a 20% chance to be TOXIC!",
    BannerColor = Color3.fromRGB(100, 255, 50),
},
```

---

## 🔧 PART 4: WHERE DO I PASTE THESE?

Open **`WeatherData`** (ModuleScript in ReplicatedStorage) → find the `WeatherData.Weathers = { ... }` list → paste your new weather block inside the `{ }` brackets (add a comma after the previous one). That's it!

### Example structure after adding Blizzard:
```lua
WeatherData.Weathers = {
    { Name = "Clear", ... },        -- don't forget the comma!
    { Name = "Sandstorm", ... },    -- don't forget the comma!
    { Name = "Blood Moon", ... },   -- don't forget the comma!
    { Name = "Blizzard", ... },     -- your new weather! (no comma needed on the last one)
}
```

The admin panel automatically picks up new weathers (it reads from WeatherData),
so they'll appear in the weather control buttons immediately!

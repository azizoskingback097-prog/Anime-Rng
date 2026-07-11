# 🎨 HOW TO USE YOUR OWN VFX — Super Detailed Guide

> This teaches you how to take ANY VFX from the Toolbox (or your own)
> and make it appear on your character when you equip an aura.

---

## 📁 STEP 1: FIND THE CUSTOMVFX FOLDER

After running the command bar, you have a new folder:

```
ReplicatedStorage/
  └── CustomVFX/    ← YOUR VFX GOES HERE!
```

This is where you store all your custom VFX effects.

---

## 📦 STEP 2: GET YOUR VFX INTO THE GAME

### Option A: From the Toolbox
1. Open **Toolbox** (View → Toolbox)
2. Search for what you want: "fire particle", "smoke effect", "aura", etc.
3. Find one you like → **right-click → Insert**
4. It appears in your Workspace

### Option B: Make Your Own
1. Create a Part in Workspace
2. Add a **ParticleEmitter** to it (click the + next to the Part)
3. Customize its properties (Color, Size, Rate, etc.)

---

## 🔍 STEP 3: FIND THE PARTICLE EMITTER

When you insert a VFX from the Toolbox, it usually comes as a Model or a Part.
You need to find the **ParticleEmitter** inside it.

**Example structure:**
```
Workspace
  └── CoolFireEffect (Model)        ← what you inserted
       └── Part
            └── ParticleEmitter      ← THIS is what you want!
```

**To find it:**
1. In Explorer, click the ▶ arrows to expand everything
2. Look for an object called **"ParticleEmitter"** (or "Fire" or "Smoke")
3. Click it — you should see its properties in the Properties panel

---

## 📂 STEP 4: MOVE IT TO THE CUSTOMVFX FOLDER

1. **Click and drag** the ParticleEmitter
2. **Drop it into** `ReplicatedStorage > CustomVFX`
3. **Right-click → Rename** it to something simple

**Examples of good names:**
- `"MyFire"` (for a fire effect)
- `"PurpleSmoke"` (for purple smoke)
- `"CoolSparkles"` (for sparkle effect)
- `"RedAura"` (for a red aura)

⚠️ **Names are case-sensitive!** If you name it `"MyFire"`, you must write `"MyFire"` in the code (not `"myfire"`)

---

## ✏️ STEP 5: ADD IT TO VFXDATA

Open **VFXData** (in ReplicatedStorage) and add a new VFX definition:

```lua
-- Find the VFX section (VFXData.VFX = { ... })
-- Add this INSIDE it:

VFXData.VFX["My Awesome Effect"] = {
    Name = "My Awesome Effect",
    Effects = {
        {
            Type = "Template",              -- ← tells it to use YOUR VFX
            TemplateName = "MyFire",        -- ← the name in CustomVEX folder
            Part = "HumanoidRootPart",      -- ← which body part
        },
    },
}
```

### What each line does:
| Line | What it means |
|------|--------------|
| `Type = "Template"` | "Use my own VFX from the folder" |
| `TemplateName = "MyFire"` | "Look for an object named MyFire in CustomVFX" |
| `Part = "HumanoidRootPart"` | "Attach it to the center of the body" |

---

## 🔗 STEP 6: CONNECT IT TO AN AURA

Find the `VFXData.AuraMap` section (at the top of VFXData):

```lua
VFXData.AuraMap = {
    -- ... existing entries ...
    ["Nine-Tails"] = "My Awesome Effect",    -- ← ADD THIS!
}
```

This means: "When a player equips Nine-Tails, show 'My Awesome Effect'"

---

## ✅ STEP 7: TEST IT!

1. Press **Play**
2. Open **Admin panel** → Give yourself Nine-Tails
3. Open **Inventory** → **Click Nine-Tails to equip**
4. Look at your character → your custom VFX should appear!

---

## 🎯 ADVANCED: MULTIPLE EFFECTS PER AURA

You can combine your own VFX with scripted ones!

```lua
VFXData.VFX["Mega Fire Aura"] = {
    Name = "Mega Fire Aura",
    Effects = {
        -- Your own fire particles
        { Type = "Template", TemplateName = "MyFire", Part = "HumanoidRootPart" },

        -- PLUS a scripted orange glow
        { Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(255,100,0), Brightness = 2, Range = 12 },

        -- PLUS scripted ember particles
        { Type = "Particle", Part = "HumanoidRootPart",
          Color = ColorSequence.new(Color3.fromRGB(255,200,50)),
          Size = NumberSequence.new(1), Rate = 30,
          Speed = NumberRange.new(5,10), Acceleration = Vector3.new(0,8,0),
          Lifetime = NumberRange.new(1,2) },
    },
}
```

---

## 🐛 DEBUGGING (Why isn't my VFX showing?)

The VFXClient now prints **debug messages** to the Output window!

1. **View → Output** (open the Output panel)
2. **Equip an aura**
3. **Read the messages** — they tell you exactly what's happening:

```
📡 Received equip event: Nine-Tails
🔄 updateVFX called, equipped = Nine-Tails
🔍 Looking up aura: Nine-Tails
📊 Tier: Legendary
🎬 Applying VFX: Fire Burst (3 effects)
✅ Created Fire on HumanoidRootPart
✅ Created Particle on HumanoidRootPart
✅ Created Light on HumanoidRootPart
🎬 VFX applied: 3 effects created
```

If something is wrong, the debug messages will show you WHERE:

```
⚠️ VFX Template 'MyFire' not found in CustomVFX folder!
```
→ You named it differently, or it's not in the folder

```
❌ No VFX found for aura 'Nine-Tails' (tier: Legendary)
```
→ VFXData.AuraMap doesn't have this aura, or VFX name is misspelled

```
❌ No character found!
```
→ The character hasn't spawned yet

---

## ❌ COMMON MISTAKES

### 1. "Template not found" warning
**Cause:** The name in `TemplateName` doesn't match the name in the CustomVFX folder
**Fix:** Check spelling AND capitalization. `"MyFire"` ≠ `"myfire"` ≠ `"My Fire"`

### 2. VFX appears but looks wrong
**Cause:** The original ParticleEmitter had different settings
**Fix:** Edit the ParticleEmitter IN the CustomVEX folder (change its properties there)

### 3. VFX doesn't follow the player
**Cause:** You dragged a Part instead of just the ParticleEmitter
**Fix:** Make sure you only put the ParticleEmitter in CustomVFX, not the whole Part

### 4. Nothing shows in Output when equipping
**Cause:** The equip event isn't reaching the client
**Fix:** Make sure GameServer was updated (re-run the command bar), and EquippedChangedEvent exists in Remotes

---

## 💡 PRO TIP: TEST YOUR VFX FIRST

Before connecting VFX to an aura, test it works:

1. Put your ParticleEmitter in CustomVEX
2. Drag a COPY of it into Workspace (on a Part)
3. Press Play → see if it looks good
4. If yes, delete the Workspace copy and connect it to an aura!

---

## 📝 QUICK REFERENCE

```
YOUR VFX WORKFLOW:
  1. Get VFX from Toolbox → Insert
  2. Find the ParticleEmitter inside it
  3. Drag ParticleEmitter to ReplicatedStorage/CustomVFX
  4. Rename it (e.g. "MyFire")
  5. Add to VFXData: { Type="Template", TemplateName="MyFire", Part="HumanoidRootPart" }
  6. Connect to aura: VFXData.AuraMap["Nine-Tails"] = "My Awesome Effect"
  7. Test: Admin → Give Nine-Tails → Equip
```

# 💬 DIALOGUE V2 — Super Customizable NPC System

A fully **data-driven** NPC dialogue system (just like your VFX auto-detect setup).
The NPC now has:

- 🎲 **Answer variety** — random pools, so he says something different each time
- 💬 **Floating chat bubble above his head** with a **bouncy pop animation**
- 🌿 **"Grow a Garden 2"** style dialogue box (dark, rounded, typewriter, hover effects)
- 🌳 **Branching options** (Story, Genesis lore, Tips, live Weather comments, Shop)
- 🛒 **Auto-detect potions** from `ShopData` — add a potion, the NPC offers it automatically
- ⚙️ **Edit words/options in ONE file** (`DialogueData`) — no code needed

---

## 🚀 INSTALL (run each in **View ▸ Command Bar**, in order)

| Step | File | What it does |
|------|------|--------------|
| **0** | `DIALOGUE_V2_Step0_Nuke.lua` | Wipes old dialogue (run first, safe to repeat) |
| **A** | `DIALOGUE_V2_StepA_ShopData.lua` | Creates `ReplicatedStorage/ShopData` (potions) |
| **B** | `DIALOGUE_V2_StepB_DialogueData.lua` | Creates `ReplicatedStorage/DialogueData` (words/options) |
| **C** | `DIALOGUE_V2_StepC_NPCShopServer.lua` | Creates `ServerScriptService/NPCShopServer` (relay) |
| **D** | `DIALOGUE_V2_StepD_DialogueUI.lua` | Creates `StarterPlayerScripts/DialogueUI` (the UI + bubble) |

Then press **Play** and walk up to the **ShopDealler** NPC. You should see:
```
✅ Found NPC: Workspace.Map.ShopDealler
✅ Overhead bubble attached to NPC!
```
and the dialogue box pops open, with his words floating above his head. 🎉

> ⚠️ **Important:** always paste from the Command Bar — never copy code out of chat into Studio (markdown corrupts special characters).

---

## 🎨 HOW TO CUSTOMIZE (no coding!)

### ✏️ Change what the NPC says / add a conversation branch
Open **`ReplicatedStorage ▸ DialogueData`** (a ModuleScript). Everything he says lives there.

**Add a new thing to talk about** (e.g. "Rumors"):
1. Add a new node at the bottom of `DialogueData.Nodes`:
```lua
Rumors = {
    Lines = {
        "I hear a strange aura has been seen near the forest at night...",
        "They say the Blood Moon brings things... cursed things.",
    },
    Options = {
        { Text = "Spooky! Tell me more", Goto = "Rumors" },  -- loops
        { Text = "◀ Back", Goto = "Root" },
        { Text = "Goodbye", Action = "Close" },
    },
},
```
2. Add an option in **Root** (or any node) that jumps to it:
```lua
{ Text = "Any rumors?", Goto = "Rumors" },
```
3. Save (Ctrl+S) → done! The button appears automatically. ✨

**Option types:**
| Field | Meaning |
|-------|---------|
| `Goto = "NodeName"` | Jump to another node |
| `Action = "OpenShop"` | Open the shop window |
| `Action = "Close"` | End the conversation |
| `Color = Color3.fromRGB(...)` | (optional) button accent color |

> 🎲 Every node's `Lines` is a **list** — the game picks one at random for variety. Add as many lines as you like!

---

### 🧪 Add a NEW potion (auto-offered by the NPC)
Open **`ReplicatedStorage ▸ ShopData`** and add a block inside `ShopData.Items`:
```lua
SpeedPotion = {
    DisplayName = "x2 Luck Mega Potion",
    Description = "A legendary brew — double luck for 10 minutes!",
    Icon = "⭐",
    Color = Color3.fromRGB(160, 120, 255),
    Price = 500000,
    Duration = 600,
    Type = "LuckMultiplier",   -- or "CoinMultiplier"
    Value = 2.0,
    BuyLine = { "Behold... the legendary brew! ⭐", "Few are worthy." },
},
```
Save → the NPC now offers it in the Shop branch automatically. 🪄

> **Heads up — one important detail:** the *dialogue* shows the potion instantly, but for the **purchase to actually work**, the **server** (`GameServer`) must also know that item ID. The two existing potions (`LuckPotion`, `CoinBoost`) already work. For brand-new ones, run **Step E** below — it makes `ShopData` the *single* place you ever edit.

---

## 🫧 The overhead bubble + pop animation
Controlled in `DialogueData ▸ Overhead`:
```lua
Enabled      = true,            -- floating text on/off
OffsetY      = 2.4,             -- height above the head
MaxDistance  = 70,              -- hides when camera is far
BubbleColor  = Color3.fromRGB(22,22,28),
TextColor    = Color3.fromRGB(245,245,250),
NameColor    = Color3.fromRGB(255,215,0),
TextSize     = 19,
PopTime      = 0.35,            -- bounce-in speed
AutoClearTime = 6,              -- fades out after N seconds
```
Every time the NPC answers, the bubble **scales from 0 → 1 with a Back/Out bounce** and auto-fades. Pure eye-candy, fully tweakable. 🎈

---

## 🔌 OPTIONAL Step E — make potions work from ONE place
Run `DIALOGUE_V2_StepE_GameServer_Sync.lua` in the Command Bar. It **reads** your GameServer and tells you exactly the one line to change so the server pulls items straight from `ShopData`. After that, adding a potion in `ShopData` is all you ever need — no second edit, no broken purchases. (It's read-only and safe — it just diagnoses + prints instructions.)

---

## 🛠️ TROUBLESHOOTING

| Symptom | Fix |
|---------|-----|
| Dialogue doesn't open | Make sure the NPC model is named exactly `ShopDealler` (or add its name to `DialogueData.NPCSearchNames`). Check Output for `✅ Found NPC`. |
| Bubble doesn't appear | `DialogueData.Overhead.Enabled` must be `true`. The bubble shows when you're close enough to talk. |
| Shop button does nothing | Run **Step C** (the relay). The old code had a bug where the client tried to `FireClient` (impossible) — the relay fixes it. |
| Buying a new potion says "not found" | The server doesn't know that item yet → run **Step E**. |
| Character freezes on respawn | The broken animation `1852625856` is back. Re-run **Step 0** to nuke it. |

---

## 🧩 How it fits your existing game
- **No remotes changed** — uses your existing `ShopOpenEvent` + `PurchaseItemFunction`.
- **No ProximityPrompt** — pure Heartbeat distance auto-scan (your preferred method).
- **Doesn't touch** GameServer, WeatherServer, VFX, or any other system.
- Everything is data in `ReplicatedStorage`, just like `AuraData` / `VFXData`.

Have fun building conversations! You're doing great. 💪

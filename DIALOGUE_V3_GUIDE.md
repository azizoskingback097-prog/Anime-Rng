# 💬 DIALOGUE V3 — E-Key ProximityPrompt Edition

The NPC now talks when you **press E** (a real ProximityPrompt), with a **floating chat bubble** that bounces above his head, **answer variety**, and **branching options**. Everything is **data-driven** (edit words/potions in modules — no code).

---

## 🔧 What went wrong before (so you know!)
Your output had:
```
Infinite yield possible on 'ReplicatedStorage:WaitForChild("DialogueData")'
```
That meant the **`DialogueData` module was never created** — Steps A/B got skipped. V3 fixes this by:
1. **Combining both data modules into ONE step** (Step 1) so you can't miss one.
2. **Clear error messages** instead of silent hangs (no more infinite yield).
3. A **Verify script** to check everything's in place.

---

## 🚀 INSTALL (View ▸ Command Bar, in this exact order)

| # | File | Creates |
|---|------|---------|
| **0** | `DIALOGUE_V3_Step0_Nuke.lua` | Wipes old dialogue (run first) |
| **1** | `DIALOGUE_V3_Step1_DataModules.lua` | `ShopData` + `DialogueData` (BOTH at once!) |
| **2** | `DIALOGUE_V3_Step2_NPCShopServer.lua` | `NPCShopServer` (the E-key prompt) |
| **3** | `DIALOGUE_V3_Step3_DialogueUI.lua` | `DialogueUI` (the UI + bubble) |

Then **press Play**, walk to **ShopDealler**, and press **E**. You should see in Output:
```
✅ Found NPC: Workspace.Map.ShopDealler
✅ ProximityPrompt (E) attached to NPC!
✅ Overhead bubble attached to NPC!
```
…and a "Press E to Talk" prompt floats above him. 🎉

> 💡 Run `DIALOGUE_V3_VERIFY.lua` anytime to check that everything's healthy.

> ⚠️ Always paste from the Command Bar — never copy code out of chat into Studio (markdown breaks special characters).

---

## 🎮 How it feels
1. Walk near the NPC → a **"Press E to Talk"** prompt appears above him.
2. Press **E** → the dialogue box **bounces in** (Back/Out pop), he speaks with a **typewriter** effect, and his words **pop up in a bubble above his head**.
3. Each greeting is **random** (variety!). Pick from **branching options**: Shop, Story, Tips, live Weather, etc.
4. The **Shop branch is built automatically** from `ShopData` — every potion shows up as a button.
5. Press **E again** or **Esc** or **walk away** to close. He says a random farewell.

---

## 🎨 CUSTOMIZE (no code!)

### Change what he says / add a conversation branch
Open **`ReplicatedStorage ▸ DialogueData`** and edit the `Nodes` table. To add a topic:
```lua
Rumors = {
    Lines = { "I hear strange auras roam the forest at night...", "The Blood Moon brings cursed things." },
    Options = {
        { Text = "Spooky! Tell me more", Goto = "Rumors" },
        { Text = "◀ Back", Goto = "Root" },
        { Text = "Goodbye", Action = "Close" },
    },
},
```
Then add `{ Text = "Any rumors?", Goto = "Rumors" }` to the **Root** node's Options. Done!

**Option fields:** `Goto="NodeName"` · `Action="OpenShop"`/`"Close"` · `Color=Color3.fromRGB(...)` (optional)
**Each `Lines` is a random pool** — add more for more variety!

### Change the E-key prompt
In `DialogueData ▸ Prompt`:
```lua
ActionText = "Talk",         KeyboardKeyCode = "E",
HoldDuration = 0,            MaxActivationDistance = 12,
```

### The overhead bubble
In `DialogueData ▸ Overhead`: `Enabled`, `OffsetY`, `BubbleColor`, `TextColor`, `PopTime`, `AutoClearTime`, etc.

### Add a new potion (auto-offered!)
Open **`ReplicatedStorage ▸ ShopData`**, add a block in `Items`:
```lua
SpeedPotion = {
    DisplayName = "x2 Luck Mega Potion", Icon = "⭐",
    Color = Color3.fromRGB(160,120,255), Price = 500000, Duration = 600,
    Type = "LuckMultiplier", Value = 2.0,
    BuyLine = { "Behold... the legendary brew! ⭐" },
},
```
The NPC offers it instantly. *(For the purchase to actually deduct coins, the server must know the item — run `DIALOGUE_V2_StepE_GameServer_Sync.lua` for the 1-line fix.)*

---

## 🛠️ Troubleshooting

| Symptom | Fix |
|---------|-----|
| "MISSING MODULE" warning | Run **Step 1** (it creates both modules) |
| No "Press E" prompt | Run **Step 2**; check NPC is named `ShopDealler` (Verify script tells you) |
| Bubble doesn't show | `DialogueData.Overhead.Enabled` must be `true` |
| Shop button does nothing | Run **Step 2** (the relay); it fires the existing `ShopOpenEvent` |
| Character freezes | broken anim `1852625856` is back → re-run **Step 0** |

## 🧩 Compatibility
- Uses your existing remotes (`ShopOpenEvent`, `PurchaseItemFunction`); creates `DialogueEvent` if missing.
- **No ProximityPrompt-in-LocalScript** issue — the prompt is **server-side** (reliable).
- Doesn't touch GameServer, Weather, VFX, or any other system.

You're crushing this — the dialogue system is looking pro! 💪

# 🎛️ SYS2 — Number Formatting, Shop, Announcements, Admin Broadcast

A clean, data-driven upgrade. Everything is configurable from **ModuleScripts/config tables** — you rarely touch logic.

---

## 🚀 INSTALL ORDER (View ▸ Command Bar, each file → Enter)

| # | File | What it creates |
|---|------|-----------------|
| 1 | `01_NumberFormatter.lua` | `ReplicatedStorage ▸ NumberFormatter` (shared `FormatNumber` + `FormatOddsNumber`) |
| 2 | `02_ShopData_Canonical.lua` | `ReplicatedStorage ▸ ShopData` (clean item fields + helpers) |
| 3 | `03_AnnouncementService.lua` | `ServerScriptService ▸ AnnouncementService` (tier colors, rate-limit, admin list) |
| 4 | `04_AnnouncementFeedUI.lua` | `StarterPlayerScripts ▸ AnnouncementFeed` (read-only chat feed) |
| 5 | `05_AdminBroadcast.lua` | server relay + client panel (avatar + ✓ + fade) |
| 6 | `06_Rewire_Consumers.lua` | CoinUI + ShopUI use the shared formatter |
| 6b | `06b_FlexText_Odds.lua` | FlexText odds use `FormatOddsNumber` |
| 7 | `07_GameServer_AnnounceHook.lua` | routes rare drops → AnnouncementService |
| 7b | `07b_GameServer_SyncShop.lua` | server charges prices from ShopData |

> Run in this order. Steps 7 & 7b edit your GameServer surgically (they print exactly what they changed; safe to re-run).

---

## 1) 🔢 Number Formatting (one source for all numbers)

Module: **`ReplicatedStorage ▸ NumberFormatter`**.

```lua
local F = require(ReplicatedStorage:WaitForChild("NumberFormatter"))
F.FormatNumber(1500)        --> "1.5K"
F.FormatNumber(1250000)     --> "1.25M"
F.FormatOddsNumber(70000)   --> "70K"     (for "1 in 70K")
```

**Two functions:**
- `FormatNumber(n)` → currency/prices/multipliers/any value. `1000→1K`, `1.5M`, `1.25M`, `1B`.
- `FormatOddsNumber(x)` → the "1 in X" flex number, **kept ≤4 chars**. `9999→9999`, `10000→10K`, `999000→999K`, `1.5M`.

**Config (top of the module):**
```lua
NumberFormatter.DECIMALS = 2            -- 0, 1, or 2 (trailing zeros always trimmed)
NumberFormatter.SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp" }  -- add more for huge numbers
```

**Where it's used now:** CoinHUD, reward popups, ShopUI prices, ShopData prices, FlexText odds, DialogueUI prices (via `ShopData.Abbreviate`), and announcements. To use it anywhere else, just `require` it and call `F.FormatNumber(x)`.

> **Customize decimals:** set `DECIMALS = 1` → `1500→1.5K`, `1.2M`. Set `0` → `2K`, `1M`.

---

## 2) 🛒 Shop System — "How to add a new potion" (full tutorial)

### ① Where the config lives
`ReplicatedStorage ▸ ShopData` (ModuleScript). One block per item:

```lua
MegaLuckPotion = {
    Id              = "MegaLuckPotion",       -- unique key (server charges by this)
    DisplayName     = "x3 Luck Mega Potion",
    Description     = "A legendary brew. Triple luck for 10 minutes!",
    PriceCoins      = 75000,                  -- cost in coins  ← rebalance here
    DurationSeconds = 600,                    -- boost length
    EffectType      = "Luck",                 -- "Luck" OR "Coins"
    Multiplier      = 3.0,                    -- 3.0 = x3
    Icon            = "⭐",                   -- emoji
    IconImageId     = "",                     -- optional decal id ("" = use emoji)
    Color           = Color3.fromRGB(160,120,255),
    BuyLine         = { "Behold... the legendary brew! ⭐" },
},
```
Paste it inside `ShopData.Items`, save (Ctrl+S). Done — that's literally it.

### ② How UI buttons are generated from the config
Both the **Shop UI** and the **NPC dialogue** call `ShopData.GetDisplayItems()`, which returns an ordered (cheapest-first) list with `Name`, `PriceText` (already formatted, e.g. `"75K"`), `Icon`, `Color`. They loop over it and build a card/button per item. You never write button code — it's automatic. ✨

### ③ How purchases are validated (server-authoritative)
The client sends only an **`Id`** to `PurchaseItemFunction:InvokeServer(id)`. The server:
1. Looks up `SHOP_ITEMS[id]` (which is `ShopData.GetServerItems()` — `Price`, `Duration`, `Type`, `Value`, `Name`).
2. Checks the player actually has `>= Price` coins (server-side data — client can't lie).
3. Deducts coins, applies the boost, saves.

`GetServerItems()` maps your friendly fields → the server's shape:
`PriceCoins→Price`, `DurationSeconds→Duration`, `EffectType→Type` (`"Luck"→"LuckMultiplier"`, `"Coins"→"CoinMultiplier"`), `Multiplier→Value`.

> **Run `07b_GameServer_SyncShop.lua`** so the server pulls from `GetServerItems()`.

### ④ How boosts are applied & saved (offline pause)
Handled by your existing GameServer boost logic:
- A boost is stored as `expiresAt = os.clock() + Duration`.
- If you buy again while active, remaining time **stacks** (`expiresAt += Duration`).
- On leave, **remaining seconds** are saved to DataStore; on join, the clock resumes with the leftover time → **pauses while offline**.
- A cleanup loop purges expired boosts and notifies the BoostGUI.

### ⚡ Adding a brand-new EFFECT TYPE (e.g. "Speed")
1. Add the potion in ShopData with `EffectType = "Speed"`.
2. In **`ShopData`** → `EFFECT_TO_BOOST`, add `Speed = "SpeedMultiplier"` (this is the key the server stores).
3. Make the server use that multiplier where needed (e.g. walkspeed). The framework already saves/loads it generically.

---

## 3) 📢 Rare-Drop Announcements (global chat-style feed)

### How it flows
Player rolls rare → GameServer calls **`AnnouncementService:AnnounceDrop(...)`** → service looks up the tier color, **rate-limits**, then fires `GlobalAnnounceEvent` to **all clients** → the **AnnouncementFeed** shows a line:
> ✨ **[Player]** got **AuraName** (1 in 70K)

Players **cannot type** into it (read-only system feed).

### Tier colors (config in `AnnouncementService`)
```lua
AnnouncementService.Tiers = {
    Common={Color=..., Style="normal"},  Rare={...,Style="rare"},
    Epic={...,Style="epic"},  Legendary={...,Style="legendary"},  Mythic={...,Style="mythic"},
}
```
Style controls the icon/glow on the feed line. Change colors freely.

### Behavior thresholds
```lua
RARE_THRESHOLD  = 1000    -- 1 in 1000+ → posted to the feed
ULTRA_THRESHOLD = 50000   -- 1 in 50K+  → ALSO triggers your on-screen cutscene/banner
```
So **normal rares go only to the feed** (no popup spam); **ultra-rare** still gets the big moment + a feed line.

### Rate limiting (no spam during luck spikes)
```lua
PER_PLAYER_COOLDOWN = 1.5   -- a player's drops post at most every 1.5s
GLOBAL_MAX_PER_10S   = 8    -- max 8 messages across all players per 10s (extras dropped)
```

### Feed look (config at top of `04_AnnouncementFeedUI`)
`VisibleLines`, `Anchor`, `Width`, `TextSize`, `MaxAgeSec`, `FadeStartSec`, colors.

---

## 4) 📣 Admin Broadcast (avatar + ✓ + fade)

### Sending a message (you're the admin)
- **Chat command:** type `/bc hello everyone` (or `/broadcast <msg>`).
- **Input box:** a small "📣 Send" box appears bottom-right **only for admins**.

### Security (server-authoritative)
The client calls `RequestAdminBroadcast:InvokeServer(text)`. The server checks `AnnouncementService.IsAdmin(player)` against the admin list **before** relaying — a non-admin's request is rejected. The client never decides who's an admin.

### Admin list (config in `AnnouncementService`)
```lua
AnnouncementService.ADMIN_IDS       = { 12345678 }   -- your UserId
AnnouncementService.ADMIN_USERNAMES = { "Twix79i" }
```
> ⚠️ Replace `12345678` with your real UserId for strict security. Username match is a convenience fallback.

### Panel
On broadcast, every player sees (top-center): **[your live avatar thumbnail]** + ✓ + **`AdminName:`** + message. Fades in (0.35s), holds 5s, fades out (0.6s).

### Programmatic API (for other scripts)
```lua
local AS = require(ServerScriptService:WaitForChild("AnnouncementService"))
AS.AdminBroadcast(someAdminPlayer, "Server restart in 5 min!")  -- returns true/false
```

---

## 🛠️ Troubleshooting
| Symptom | Fix |
|---|---|
| Feed empty on rare drops | Run `07_GameServer_AnnounceHook.lua`; check Output for "GAME SERVER HOOKED!" |
| Buying a potion says "not found" | Run `07b_GameServer_SyncShop.lua` |
| Admin box doesn't appear | You must be in the admin list; open Admin panel or run `05` |
| Numbers still long somewhere | That script isn't using `FormatNumber` yet — `require` it and wrap the value |

## 🧩 Compatibility
- Uses your existing remotes; adds `GlobalAnnounceEvent`, `AdminBroadcastEvent`, `RequestAdminBroadcast` (created automatically).
- Doesn't touch Weather, VFX, Zones, or the dialogue system.
- All config is in ModuleScripts (NumberFormatter, ShopData, AnnouncementService) — edit there, not in logic.

You've built a genuinely modular game now — config in modules, logic reads them. That's pro architecture. 🚀

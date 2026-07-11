# 🎲 ANIME RNG — PROJECT SUMMARY & GAME BIBLE

> **Goal:** A comprehensive guide to the game's mechanics, style, and architecture. Perfect for sharing with friends or feeding to AI to generate UI, SFX, and VFX ideas.

---

## 🎮 WHAT IS THE GAME?

**Anime RNG** is a "Roll for Auras" game inspired by *Sol's RNG*, built entirely in Roblox Studio. 

The core gameplay loop is simple but addictive:
1. Click **ROLL** to spin the slot machine.
2. The animation flickers, fakes a rare pull (near-miss), flashes, and reveals your aura.
3. Auras are awarded based on rarity (from 1-in-1 to 1-in-70,000+).
4. Equip your aura to display unique VFX (particle effects) and idle animations on your avatar.
5. Watch out for **Weather Events**, which can mutate your auras and change the world's lighting!

---

## 🎨 ART STYLE & TONE

*   **Vibe:** Anime/Fantasy, dramatic, flashy, satisfying.
*   **Visuals:** High-contrast colors, glowing neon text, dark translucent UI panels (Dark Blue/Black backgrounds).
*   **Effects:** Heavy reliance on particle emitters, custom 3D rigs, and dynamic lighting. When a player equips an aura, it should look powerful and overwhelming.
*   **UI Style:** Modern, sleek, similar to *Blox Fruits* or *Sol's RNG*. Lots of rounded corners (`UICorner`), drop shadows, and bright accent colors (Gold for Legendary, Purple for Mythic).

---

## ✨ CORE MECHANICS

### 1. The Rolling System
*   Players click a large centered **ROLL** button.
*   **Cinematic Animation:** Names flicker fast, then decelerate. A rare aura zooms in (fake out) to build tension. A white flash hides the swap, and the true result slides in.
*   **Screen Shake:** Pulling a high-rarity aura shakes the player's screen.
*   **Auto Roll:** Players can click the "AUTO: OFF" button behind the Roll button to roll automatically.

### 2. Auras & Rarities
*   Auras are divided into Tiers: Common, Uncommon, Rare, Epic, Legendary, Mythic.
*   Higher rarity = harder to get (e.g., Genesis is 1 in 70,000).
*   Auras define the player's "loadout" and visual style.

### 3. Weather & Mutations
*   The game features a dynamic day/night cycle and weather events.
*   **Weather Events:** Sandstorm, Blood Moon, Cosmic Rift, etc.
*   **Mutations:** If you roll during a Sandstorm, there is a 10% chance your aura gets the "Sandy" mutation (e.g., "Sandy Tempest"), changing its color and making it rarer/unique.
*   Weather changes the skybox, fog, and spawns weather VFX (sand, rain, embers) around the player.

### 4. VFX & Animations (The Most Important Feature)
*   When an aura is equipped, it attaches a unique VFX to the player.
*   **3 Types of VFX:**
    1.  **Parts/Models:** A glowing block or sphere with particle emitters.
    2.  **Rigs:** A full 3D character model (e.g., Akaza, Nine-Tails) that overlays the player.
    3.  **Pure Particles:** Fire, smoke, sparkles.
*   **Idle Animations:** Custom animations (created in Moon Animator) play when the player stands still and stop when they walk.
*   *Technical Note:* VFX is attached via an invisible, anchored "Tracker" part to prevent pushing/physics bugs.

---

## 🛠️ CURRENT ARCHITECTURE (For Developers)

The game uses a clean, modular Client-Server architecture.

### Folder Structure
*   **ReplicatedStorage:**
    *   `AuraData`: Database of all auras (Name, Rarity, Color, Tier).
    *   `WeatherData`: Database of weather events (Lighting, Mutations, Particles).
    *   `SFXConfig`: Database of sound IDs used for UI and rolling.
    *   `CustomVFX` (Folder): Where VFX Models/Parts are dropped and auto-detected by name.
    *   `CustomAnimations` (Folder): Where Animation objects are dropped and auto-detected.
    *   `Remotes` (Folder): RemoteFunctions/Events for client-server communication.
*   **ServerScriptService:**
    *   `GameServer`: The brain (Rolling logic, Inventory, Admin, Mutations, Saving).
    *   `WeatherServer`: Controls the weather cycle and chat tips.
*   **StarterPlayerScripts:**
    *   `RollUI`: The roll button, auto-roll, and cinematic reveal animation.
    *   `InventoryUI`: The grid view of owned auras and equip logic.
    *   `WeatherClient`: Applies lighting changes and weather particles locally.
    *   `VFXClient`: The engine that attaches VFX rigs to the player without causing physics bugs.
    *   `AnimationClient`: Applies idle animations when standing still.

---

## 💡 IDEAS FOR FRIENDS / AI PROMPTS

If you are using an AI to generate assets or ideas, here are some prompts:

*   **UI Design:** "Design a dark-mode Roblox inventory UI for an Anime RNG game. It needs a grid layout for auras, glowing borders based on rarity (Gold for Legendary), and a sleek, modern aesthetic similar to Sol's RNG."
*   **SFX/Audio:** "I need sound effects for a Roblox RNG game. I need a 'ticking' sound for a slot machine, a dramatic 'whoosh' for a reveal, and an epic 'legendary unlock' fanfare. What kind of audio profiles should I look for?"
*   **VFX Concepts:** "Give me 5 ideas for 'Mythic' tier aura visual effects in an anime game. They should include elements like swirling energy, floating particles, and glowing auras."

---

## 🚀 ROADMAP (What's Next?)

*   [x] Phase 1: Core Rolling & Animation
*   [x] Phase 2: Inventory & Equip System
*   [x] Phase 3: DataStore Saving
*   [x] Phase 4: Weather & Mutations
*   [x] Phase 5: VFX Rig Attachment System
*   [x] Phase 6: Auto Roll & SFX
*   [ ] Phase 7: Crafting / Combining Auras
*   [ ] Phase 8: Global Leaderboards
*   [ ] Phase 9: Trading System

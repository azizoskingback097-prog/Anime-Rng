# 🎵 HOW TO CUSTOMIZE YOUR SFX (SOUNDS)

All your sound settings live inside a script called **`SFXConfig`** (located in `ReplicatedStorage`).

---

## 📍 Step 1: Find a Sound You Like
1. Go to the **Toolbox** in Roblox Studio.
2. Click the dropdown at the top of the Toolbox and change it from **Models** to **Audio**.
3. Search for a sound (e.g., "epic swoosh", "click", "magic reveal").
4. Right-click the sound you like and click **Copy ID** (or look at its Asset ID in the properties).

*(Note: The ID will look like a bunch of numbers, e.g., `9123456789`)*

---

## ✏️ Step 2: Put It In Your Game
1. In the **Explorer**, click the arrow next to `ReplicatedStorage`.
2. Double-click **`SFXConfig`** to open it.
3. Look for the sound you want to change. For example, if you want to change the Roll sound:

```lua
-- BEFORE:
["roll"] = { id = "rbxassetid://6042053626", volume = 0.5 },

-- AFTER (with your new ID):
["roll"] = { id = "rbxassetid://9123456789", volume = 0.5 },
```

---

## 🔊 What Each Sound Means
Here are the sounds currently in your game. You can change ANY of them!

| Name | When it plays |
|------|--------------|
| `roll` | When you click the big ROLL button |
| `tick` | The fast clicking sound during the flicker animation |
| `reveal` | The sound when a common/uncommon aura appears |
| `rare` | The sound when you pull an Epic aura |
| `legendary` | The sound when you pull a Legendary aura |
| `mythic` | The sound when you pull a Mythic aura |
| `click` | When you click an item in your inventory |
| `open` | When you open the inventory window |
| `close` | When you close the inventory window |
| `equip` | When you equip an aura |

---

## ⚠️ Troubleshooting Sounds

**"Asset type does not match requested type"**
*Cause:* You put an Image ID or Model ID instead of an **Audio ID**.
*Fix:* Go back to the Toolbox, make sure you are searching in the **Audio** category, and copy the correct ID!

**"User is not authorized to access Asset"**
*Cause:* The sound was uploaded by someone else and they didn't share it publicly, OR it's a copyrighted song.
*Fix:* Find a different sound in the Toolbox that is free to use, or upload your own .mp3/.ogg file to Roblox!

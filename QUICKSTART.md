# Quick Start Guide

## Loading the Script

1. **Start your Roblox executor** and join the fishing game
2. **Load the script** by pointing to `main.lua` or copy-pasting the contents
3. **Wait for WindUI to load** - this may take a few seconds on first run
4. **The UI will appear** with a purple/violet theme

## First Time Setup

### 1. Configure Webhooks (Optional)
- Go to **Webhook** tab
- Enter your Discord webhook URL
- Toggle **Enable Fish Notifications**
- Test with the **Test Webhook** button

### 2. Set Up Config (Recommended)
- Go to **Configuration** tab
- Enter a config name (e.g., "MySettings")
- Adjust your preferred settings across all tabs
- Click **Save Config** to save your setup

### 3. Choose Fishing Mode

**For beginners (Legit Mode):**
- Go to **Fishing** tab
- Enable **Auto Fish (Legit)**
- Adjust click speed if needed
- Choose a fishing area and teleport there

**For intermediate (Normal Instant):**
- In **Fishing** tab
- Enable **Normal Instant Fish**
- Set your preferred delay
- Teleport to area, optionally enable freeze

**For advanced (Blatant):**
- In **Fishing** tab → **Blatant Mode**
- Adjust Complete Delay and Cancel Delay
- Enable **Instant Fishing (Blatant)**
- ⚠️ Use at your own risk

## Common Workflows

### Farming at Specific Location
1. Go to **Fishing** tab
2. Choose area from dropdown
3. Click **Teleport to Chosen Area**
4. Enable your preferred fishing mode
5. For better results, enable **Teleport & Freeze at Area**

### Auto Sell While Fishing
1. Go to **Automatic** tab → **Autosell Fish**
2. Choose method: **Delay** (every X seconds) or **Count** (when inventory has X fish)
3. Set the value
4. Toggle **Enable Auto Sell**
5. Works alongside any fishing mode

### Auto Favorite Rare Fish
1. Go to **Automatic** tab → **Auto Favorite / Unfavorite**
2. Select filters:
   - **by Rarity**: Select "Mythic", "Secret", etc.
   - **by Item Name**: Select specific fish names
   - **by Mutation**: Select "Shiny", "Gemstone", etc.
3. Toggle **Enable Auto Favorite**
4. Fish will be automatically favorited when caught

### Merchant Auto Buy
1. Go to **Shop** tab → **Traveling Merchant**
2. Toggle **Live Stock & Buy Actions** to see current stock
3. Click **BUY** buttons on items you want
4. For automatic repurchasing, toggle **Auto Buy Current Stock**

### Event Auto-Join (Lochness)
1. Go to **Events** tab
2. Toggle **Auto Join Ancient Lochness Event**
3. The script will auto-teleport when event starts and return when it ends

## Tips & Best Practices

### Performance Optimization
- Use **Teleport & Freeze** to prevent server lag from pushing you
- Enable **FPS Ultra Boost** in Tools tab for better performance
- Disable unnecessary visuals (No Skin Effect, No Cutscene) to reduce lag

### Safety
- Start with **Legit Mode** to learn the script
- Blatant mode has higher detection risk
- Use **Hide All Usernames** for streaming
- Keep **Auto Favorite** on to protect rare fish from accidental selling

### Configuration Management
- Save multiple configs for different scenarios (e.g., "LegitFarming", "BlatantGrinding")
- Configs are saved in `ftgshub_configs/` folder
- Share configs with friends by sending the .json file

### Troubleshooting

**UI not appearing?**
- Check if WindUI loaded successfully (check console)
- Try rejoining the game
- Ensure your executor supports required functions

**Fishing not working?**
- Verify remotes are cached (check console for errors)
- Make sure you have a fishing rod equipped
- Try different fishing modes
- Check if you're in a valid fishing area

**Webhook not sending?**
- Verify webhook URL is correct and from a Discord channel
- Check if your executor has `request()` function
- Test with the Test Webhook button

**Config not saving?**
- Ensure `ftgshub_configs/` folder exists (script creates it automatically)
- Check for write permissions
- Try a different config name (no special characters)

## Keyboard Shortcuts

- **F** - Toggle UI visibility (can be changed in Configuration tab)

## File Locations

- **Configs**: `ftgshub_configs/*.json`
- **Memory/Logs**: `memory/YYYY-MM-DD.md` (daily logs)
- **Long-term Memory**: `MEMORY.md` (curated memories)

## Need Help?

- Check the **About** tab for version info
- Join the Noxius Community Discord (link in About tab)
- Review console output for error messages
- Ensure all dependencies (WindUI) are loading correctly

---

*Happy Fishing! 🎣*
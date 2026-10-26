# NectarX — Step 1: Image Collection

This starter version collects labelled screenshots for the future NectarX image library. The macro itself is not implemented yet.

## Run it by double-clicking (Windows)

1. Download the repository using **Code → Download ZIP**, then extract the ZIP.
2. Install Python 3 for Windows from https://www.python.org/downloads/windows/ if it is not installed. During setup, enable **Add Python to PATH**.
3. Open the extracted folder.
4. Double-click **`RUN_IMAGE_COLLECTOR.bat`**. It checks for Pillow and installs it if needed, then opens the collector.
5. Keep the black terminal window open until you finish.

You only need an internet connection the first time if Pillow needs to be installed. If the collector reports an error, the terminal stays open so you can read it.

## Collect images

1. Open Bee Swarm Simulator.
2. In the collector, choose a category and enter a descriptive image name.
3. Click **Capture full screen**, **Select a screenshot file**, or **Crop the screen**.
4. Click **Save image to library**.
5. Images are saved locally in `NectarX images/<category>/`. The `image_manifest.json` file is updated automatically.

## Exact images to collect

Capture real screenshots from your own game. Capture each distinct state clearly, ideally at the same game resolution and UI scale. Start with one good image of each item/state below; add variations when useful.

### 1. `fields_landmarks`
- `field_clover` — Clover Field
- `field_sunflower` — Sunflower Field
- `field_mushroom` — Mushroom Field
- `field_blue_flower` — Blue Flower Field
- `field_strawberry` — Strawberry Field
- `field_spider` — Spider Field
- `field_bamboo` — Bamboo Field
- `field_pineapple` — Pineapple Patch
- `field_stump` — Stump Field (if accessible)
- `field_cactus` — Cactus Field
- `field_pumpkin` — Pumpkin Patch
- `field_pine_tree` — Pine Tree Forest
- `field_rose` — Rose Field
- `field_mountain_top` — Mountain Top Field
- `field_pepper` — Pepper Patch (if accessible)
- `field_coconut` — Coconut Field (if accessible)
- `landmark_hive_area`, `landmark_cannon`, `landmark_gates` — hive area, cannon, and important gates

### 2. `tokens_flowers`
- Tokens: `token_pollen`, `token_honey`, `token_blue_boost`, `token_red_boost`, `token_critical`, `token_focus`, `token_haste`, `token_token_link`, `token_bomb`, `token_blue_bomb`, `token_red_bomb`, `token_magnet`, `token_mark`, `token_inspire`
- Flower states: `flower_empty`, `flower_partly_collected`, `flower_full`
- For tokens, take a close-up and (if possible) a normal gameplay view showing context. Only collect tokens you actually encounter.

### 3. `backpack_pollen`
- `pollen_bar_empty`, `pollen_bar_half`, `pollen_bar_full`
- `backpack_low`, `backpack_nearly_full`, `backpack_full`
- `honey_counter_visible`

### 4. `hive_conversion`
- `hive_claimed`, `hive_empty_slots`, `hive_conversion_active`, `hive_conversion_complete`
- `hive_balloon` and `hive_dialogue` if present

### 5. `movement_travel`
- `movement_player_idle`, `movement_player_running`, `movement_jump`
- `movement_cannon_view`, `movement_sprinkler`, `movement_field_edge`

### 6. `npcs_quests`
- NPCs: `npc_black_bear`, `npc_brown_bear`, `npc_polar_bear`, `npc_mother_bear`, `npc_panda_bear`, `npc_scientist_bear`
- Also `npc_gummy_bear`, `npc_dapper_bear`, `npc_bucko_guard`, `npc_riley_guard` if accessible
- `quest_active`, `quest_progress`, `dialogue_open`, `dialogue_closed`
- Keep quest text readable when possible.

### 7. `bees_abilities`
- Bee examples: `bee_basic`, `bee_bomber`, `bee_hasty`, `bee_looker`, `bee_rad`, `bee_bumble`, `bee_music`, `bee_ninja`, `bee_shy`, `bee_vector`, `bee_precise`, `bee_fuzzy` (only if owned/available)
- `ability_token_on_ground`, `bee_swarm_in_field`
- Capture bee icons/names and ability tokens separately when possible.

### 8. `planters`
- `planter_empty`, `planter_placed`, `planter_growing`, `planter_ready`, `planter_harvested`
- `planter_dialogue` if present

### 9. `menus_ui`
- `ui_quest_list`, `ui_inventory`, `ui_bee_menu`, `ui_shop`, `ui_settings`
- `ui_prompt_interact`, `ui_loading_or_respawn`, `ui_error_or_disconnect` if encountered

### 10. `other`
- Any useful game state not covered above; use a descriptive name.

## Image quality rules

- The collector saves images as PNG.
- Keep the target object and UI readable; avoid motion blur and overlays covering the target.
- Crop tightly for individual tokens, bee icons, and small UI elements. Keep wider screenshots for field navigation and full-screen states.
- Avoid exact duplicates unless the state is meaningfully different.
- Start with fields, backpack/pollen, hive conversion, NPC dialogue, and common tokens. Gather the rest over time.

## Where files go

- `NectarX images/<category>/<image_name>.png`
- `NectarX images/image_manifest.json`

The collector saves locally. It does **not** automatically upload images to GitHub, recognize game states, or train an AI. Upload the folder to GitHub when ready.

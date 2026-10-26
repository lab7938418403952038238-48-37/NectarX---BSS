# NectarX — Step 1: Image Collection

This fresh start focuses only on collecting labelled screenshots for the future NectarX image library. The macro itself is not implemented yet.

## Requirements

- Windows
- Python 3
- Bee Swarm Simulator open when capturing game screens

Install the image dependency:

```powershell
py -m pip install pillow
```

Run the collector:

```powershell
py image_collector.py
```

## Workflow

1. Open Bee Swarm Simulator and navigate to the screen/state you want to record.
2. In the collector, choose a category.
3. Capture the full screen, select an existing screenshot, or crop a region.
4. Give the image a clear name, then click **Save image to library**.
5. Images are stored under `NectarX images/<category>/`; `image_manifest.json` records their names, paths, dimensions, labels, and capture times.

## Suggested categories

- `fields_landmarks`
- `tokens_flowers`
- `backpack_pollen`
- `hive_conversion`
- `movement_travel`
- `npcs_quests`
- `bees_abilities`
- `planters`
- `menus_ui`
- `other`

Capture real screenshots and use accurate labels. The collector does not automatically recognize the game state or train an AI. Images and the manifest are saved locally; commit and push them to GitHub when you're ready.

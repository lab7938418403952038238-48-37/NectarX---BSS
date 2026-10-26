# NectarX AutoHotkey Image Collector

## Requirements
- Windows 10 or 11
- AutoHotkey **v2** (not v1): https://www.autohotkey.com/

## Run
1. Download this repository (Code → Download ZIP) and extract it.
2. Install AutoHotkey v2.
3. Double-click `image_collector.ahk`.
4. Choose a category, enter a descriptive image name, and capture or select an image.
5. Click **Save image to library**.

No Python or Pillow is required. The collector uses Windows PowerShell and .NET's built-in image APIs for screen capture and PNG conversion.

## Cropping
Use **Win+Shift+S** to snip a region, then copy the snip to the clipboard and click **Save image from clipboard** in the collector. If clipboard capture does not work on your Windows setup, save the snip as a file and use **Choose screenshot file**.

## Output
Images are saved locally to `NectarX images/<category>/<image_name>.png`. The manifest is `NectarX images/image_manifest.json`.

This tool saves files on your computer. It does not upload images to GitHub automatically, recognize game states, or train an AI. Commit or upload the generated image folder separately when you are ready.

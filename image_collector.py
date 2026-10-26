"""
NectarX Image Collector
Run on Windows with: py -m pip install pillow
Then: py image_collector.py

Captures screenshots or lets you select/crop a region, labels each image,
and stores it in NectarX images/<category>/ with an image_manifest.json.
"""
from pathlib import Path
from datetime import datetime
import json
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, simpledialog

try:
    from PIL import Image, ImageGrab, ImageTk
except ImportError:
    raise SystemExit("Pillow is required. Install it with: py -m pip install pillow")

ROOT = Path(__file__).resolve().parent
IMAGE_ROOT = ROOT / "NectarX images"
MANIFEST = IMAGE_ROOT / "image_manifest.json"
CATEGORIES = [
    "fields_landmarks", "tokens_flowers", "backpack_pollen",
    "hive_conversion", "movement_travel", "npcs_quests",
    "bees_abilities", "planters", "menus_ui", "other"
]

def load_manifest():
    try:
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else []
    except (OSError, json.JSONDecodeError):
        return []

def save_manifest(items):
    IMAGE_ROOT.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(items, indent=2, ensure_ascii=False), encoding="utf-8")

class Collector(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("NectarX — Image Collector")
        self.geometry("620x440")
        self.minsize(540, 390)
        self.items = load_manifest()
        self.latest = None
        self._build()

    def _build(self):
        outer = ttk.Frame(self, padding=16)
        outer.pack(fill="both", expand=True)
        ttk.Label(outer, text="NectarX Image Collector", font=("Segoe UI", 17, "bold")).pack(anchor="w")
        ttk.Label(outer, text="Capture real game UI and label it for NectarX's image library.").pack(anchor="w", pady=(3, 14))

        form = ttk.Frame(outer)
        form.pack(fill="x")
        ttk.Label(form, text="Category").grid(row=0, column=0, sticky="w", pady=5)
        self.category = tk.StringVar(value=CATEGORIES[0])
        ttk.Combobox(form, textvariable=self.category, values=CATEGORIES, state="readonly", width=28).grid(row=0, column=1, sticky="ew", padx=8, pady=5)
        ttk.Label(form, text="Image name").grid(row=1, column=0, sticky="w", pady=5)
        self.name = tk.StringVar()
        ttk.Entry(form, textvariable=self.name).grid(row=1, column=1, sticky="ew", padx=8, pady=5)
        form.columnconfigure(1, weight=1)

        ttk.Separator(outer).pack(fill="x", pady=12)
        ttk.Button(outer, text="1. Capture full screen", command=self.capture_screen).pack(fill="x", pady=4)
        ttk.Button(outer, text="2. Select a screenshot file", command=self.open_file).pack(fill="x", pady=4)
        ttk.Button(outer, text="3. Crop the screen (select region)", command=self.crop_screen).pack(fill="x", pady=4)
        ttk.Button(outer, text="Save image to library", command=self.save_image).pack(fill="x", pady=8)
        self.status = tk.StringVar(value=f"Loaded {len(self.items)} manifest entries. Images save locally in: {IMAGE_ROOT}")
        ttk.Label(outer, textvariable=self.status, wraplength=570).pack(anchor="w", pady=(8, 0))
        ttk.Label(outer, text="Tip: open Bee Swarm Simulator first. Capture one clearly identifiable item/state at a time.", wraplength=570).pack(anchor="w", pady=(6, 0))

    def set_image(self, image, default_name):
        self.latest = image.convert("RGB")
        if not self.name.get().strip():
            self.name.set(default_name)
        self.status.set(f"Image ready: {self.latest.width} × {self.latest.height}. Add a name and save.")

    def capture_screen(self):
        self.withdraw()
        self.after(350, self._capture_after_hide)

    def _capture_after_hide(self):
        try:
            self.set_image(ImageGrab.grab(), "screen_capture")
        except Exception as exc:
            messagebox.showerror("Capture failed", str(exc))
        finally:
            self.deiconify()

    def open_file(self):
        filename = filedialog.askopenfilename(title="Choose a screenshot", filetypes=[("Images", "*.png *.jpg *.jpeg *.bmp *.webp"), ("All files", "*.*")])
        if not filename:
            return
        try:
            self.set_image(Image.open(filename), Path(filename).stem)
        except Exception as exc:
            messagebox.showerror("Could not open image", str(exc))

    def crop_screen(self):
        self.withdraw()
        self.after(350, self._start_crop)

    def _start_crop(self):
        try:
            screenshot = ImageGrab.grab().convert("RGB")
            self.deiconify()
            self._crop_window(screenshot)
        except Exception as exc:
            self.deiconify()
            messagebox.showerror("Crop failed", str(exc))

    def _crop_window(self, screenshot):
        win = tk.Toplevel(self)
        win.title("Drag to select the image region — Escape cancels")
        win.attributes("-topmost", True)
        screen_w, screen_h = win.winfo_screenwidth(), win.winfo_screenheight()
        scale = min(screen_w / screenshot.width, (screen_h - 60) / screenshot.height, 1.0)
        preview = screenshot.resize((int(screenshot.width * scale), int(screenshot.height * scale)))
        photo = ImageTk.PhotoImage(preview)
        canvas = tk.Canvas(win, width=preview.width, height=preview.height, cursor="cross")
        canvas.pack()
        canvas.create_image(0, 0, image=photo, anchor="nw")
        canvas.image = photo
        state = {"start": None, "rect": None}
        def down(event):
            state["start"] = (event.x, event.y)
            if state["rect"]:
                canvas.delete(state["rect"])
            state["rect"] = canvas.create_rectangle(event.x, event.y, event.x, event.y, outline="red", width=2)
        def drag(event):
            if state["start"] and state["rect"]:
                canvas.coords(state["rect"], *state["start"], event.x, event.y)
        def up(event):
            if not state["start"]:
                return
            x1, y1 = state["start"]
            left, right = sorted((max(0, x1), min(preview.width, event.x)))
            top, bottom = sorted((max(0, y1), min(preview.height, event.y)))
            if right - left < 5 or bottom - top < 5:
                return
            crop = screenshot.crop((int(left / scale), int(top / scale), int(right / scale), int(bottom / scale)))
            self.set_image(crop, "screen_region")
            win.destroy()
        canvas.bind("<ButtonPress-1>", down)
        canvas.bind("<B1-Motion>", drag)
        canvas.bind("<ButtonRelease-1>", up)
        win.bind("<Escape>", lambda _e: win.destroy())

    def save_image(self):
        if self.latest is None:
            messagebox.showinfo("No image", "Capture a screen, crop a region, or select an image first.")
            return
        name = self.name.get().strip()
        if not name:
            messagebox.showinfo("Name needed", "Enter a clear name for this image.")
            return
        safe = "".join(c if c.isalnum() or c in "-_" else "_" for c in name).strip("_")
        if not safe:
            messagebox.showinfo("Invalid name", "Use a name containing letters or numbers.")
            return
        category = self.category.get()
        folder = IMAGE_ROOT / category
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"{safe}.png"
        if path.exists() and not messagebox.askyesno("Overwrite?", f"{path.relative_to(ROOT)} already exists. Replace it?"):
            return
        try:
            self.latest.save(path, format="PNG")
            entry = {
                "name": safe,
                "category": category,
                "path": path.relative_to(ROOT).as_posix(),
                "width": self.latest.width,
                "height": self.latest.height,
                "captured_at": datetime.now().astimezone().isoformat(timespec="seconds"),
                "label": name.replace("_", " ")
            }
            self.items = [x for x in self.items if x.get("path") != entry["path"]]
            self.items.append(entry)
            save_manifest(self.items)
            self.latest = None
            self.name.set("")
            self.status.set(f"Saved {entry['path']} • {len(self.items)} manifest entries.")
            messagebox.showinfo("Saved", f"Image saved to:\n{path}\n\nThe manifest was updated.")
        except Exception as exc:
            messagebox.showerror("Save failed", str(exc))

if __name__ == "__main__":
    Collector().mainloop()

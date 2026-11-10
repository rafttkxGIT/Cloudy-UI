# ☁️ CloudyUI

A clean, cloud-white interface library for Roblox, written in Luau. One file, no dependencies.

- Windows, tabs and collapsible sections
- Buttons, toggles, sliders, dropdowns, inputs, keybinds, color pickers
- Notifications and dialogs
- Search, themes, config saving, mobile support

---

## Files

| File | What it is |
|---|---|
| `Cloudy UI.luau` | The library. This is the file you load. |
| `Example.luau` | A full example script that uses every element. |

---

## Installation

### Option 1 — Load from GitHub

```lua
local Cloudy = loadstring(game:HttpGet("https://raw.githubusercontent.com/rafttkxGIT/Cloudy-UI/refs/heads/main/Cloudy%20UI.luau"))()
```

### Option 2 — Roblox Studio

1. Create a **ModuleScript** in **ReplicatedStorage** and name it `CloudyUI`.
2. Paste the content of `Cloudy UI.luau` into it.
3. Load it from a **LocalScript** (for example in StarterPlayer → StarterPlayerScripts):

```lua
local Cloudy = require(game:GetService("ReplicatedStorage"):WaitForChild("CloudyUI"))
```

---

## Quick start

```lua
local Window = Cloudy:CreateWindow({
	Name = "My Hub",
	Subtitle = "v1.0",
})

local Main = Window:CreateTab("Main")

Main:CreateToggle({
	Name = "Auto farm",
	Flag = "AutoFarm",
	Callback = function(enabled)
		print("Auto farm:", enabled)
	end,
})

Main:CreateButton({
	Name = "Say hello",
	Callback = function()
		Cloudy:Notify({ Title = "Hello!", Content = "CloudyUI is working." })
	end,
})

Window:CreateSettingsTab()
```

Press **RightShift** to hide or show the window.

---

## Window

```lua
local Window = Cloudy:CreateWindow({
	Name = "My Hub",
	Subtitle = "v1.0",
	Theme = "Cloud",
	Size = Vector2.new(600, 420),
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigurationSaving = { Enabled = true, FolderName = "MyHub", FileName = "config" },
})
```

| Option | What it does | Default |
|---|---|---|
| `Name` | Title in the top bar and on the loading splash | `"CloudyUI"` |
| `Subtitle` | Small gray text next to the title | none |
| `Theme` | `"Cloud"`, `"Light"`, `"Gray"`, `"Storm"`, `"Dark"`, or a custom table | `"Cloud"` |
| `Size` | Window size in pixels | `600 x 420` |
| `ToggleKey` | Key that hides/shows the window | `RightShift` |
| `ConfigurationSaving` | Saves values between sessions | off |
| `Intro` | Loading splash when the window opens | `true` |
| `IntroText` | Small text on the splash | `"Loading…"` |
| `ShowProfile` | Player avatar and name at the bottom of the sidebar | `true` |
| `Resizable` | Drag the bottom-right corner to resize | `true` |
| `Logo` | Cloud logo in the top bar | `true` |
| `Icon` | Your own logo (Roblox image asset ID) instead of the cloud | none |

### Window methods

| Method | What it does |
|---|---|
| `Window:CreateTab(name, icon)` | Adds a tab (`icon` is an optional image asset ID) |
| `Window:CreateSettingsTab(name)` | Adds a ready-made settings tab (theme, toggle key, unload) |
| `Window:SelectTab(tab)` | Switches to a tab |
| `Window:SetVisible(true/false)` | Shows or hides the window |
| `Window:Toggle()` | Flips visible/hidden |
| `Window:SetMinimized(true/false)` | Collapses to the top bar |
| `Window:SetToggleKey("K")` | Changes the hide/show key |
| `Window:SetTitle(title, subtitle)` | Changes the top bar text |
| `Window:Dialog({...})` | Opens a popup |
| `Window:Destroy()` | Removes this window |

---

## Tabs and sections

```lua
local Main = Window:CreateTab("Main")
local Farming = Main:CreateSection("Farming")
```

Elements can be created on a tab or inside a section. Click a section title to collapse it.

| Method | What it does |
|---|---|
| `Tab:Select()` | Switches to the tab |
| `Section:SetCollapsed(true/false)` | Collapses or expands the section |
| `Section:SetName("New name")` | Renames the section |

---

## Elements

Every `Create...` function also works as `Add...` (for example `Tab:AddButton`).

### Button

```lua
Tab:CreateButton({
	Name = "Click me",
	Description = "Optional small text", -- makes the button a taller row
	Variant = "Outline",                 -- "Outline" | "Primary" | "Secondary" | "Ghost" | "Destructive"
	Callback = function()
		print("clicked")
	end,
})
```

### Toggle

```lua
Tab:CreateToggle({
	Name = "Auto farm",
	Description = "Optional description",
	Default = false,
	Flag = "AutoFarm",
	Callback = function(enabled)
		print(enabled) -- true or false
	end,
})
```

### Slider

```lua
Tab:CreateSlider({
	Name = "Walk speed",
	Range = { 16, 100 },
	Increment = 1,       -- use 0.1 for decimals
	Suffix = "studs/s",  -- optional
	Default = 16,
	Flag = "WalkSpeed",
	Callback = function(value)
		print(value)
	end,
})
```

Click the number on the right to type an exact value.

### Dropdown

```lua
local Mode = Tab:CreateDropdown({
	Name = "Mode",
	Options = { "Easy", "Normal", "Hard" },
	Default = "Normal",
	Multi = false, -- true = pick several; Default and the callback value become lists
	Flag = "Mode",
	Callback = function(option)
		print(option)
	end,
})

Mode:Refresh({ "Easy", "Normal", "Hard", "Insane" }, true) -- true = keep the current selection
```

### Input

```lua
Tab:CreateInput({
	Name = "Player name",
	Placeholder = "Username",
	Default = "",
	Numeric = false,       -- true = numbers only, the callback gets a number
	ClearOnSubmit = false, -- true = empty the box after typing
	Flag = "PlayerName",
	Callback = function(text)
		print(text)
	end,
})
```

The callback runs when you press Enter or click away.

### Keybind

```lua
Tab:CreateKeybind({
	Name = "Dash",
	Default = "Q",
	Hold = false, -- true = Callback(true) on press and Callback(false) on release
	Flag = "DashKey",
	Callback = function()
		print("key pressed")
	end,
	ChangedCallback = function(key) -- optional: runs when the key is rebound
		print("new key:", key)
	end,
})
```

Click the element to pick a new key. **Backspace** removes the key, **Esc** cancels.

### Color picker

```lua
Tab:CreateColorPicker({
	Name = "Highlight color",
	Default = Color3.fromRGB(90, 140, 255),
	Flag = "HighlightColor",
	Callback = function(color)
		print(color) -- Color3
	end,
})
```

### Label, paragraph, divider

```lua
Tab:CreateLabel("A simple line of text")
Tab:CreateParagraph({ Title = "Title", Content = "Longer text that wraps onto several lines." })
Tab:CreateDivider()
```

---

## Controlling elements from code

```lua
local MyToggle = Tab:CreateToggle({ Name = "Test", Flag = "Test" })

MyToggle:Set(true)         -- change the value (runs the Callback)
MyToggle:Set(true, true)   -- change the value silently (no Callback)
MyToggle:SetName("Renamed")
MyToggle:SetVisible(false)
MyToggle:Destroy()
print(MyToggle.Value)
```

| Element | `Set` takes |
|---|---|
| Toggle | `true` / `false` |
| Slider | number |
| Dropdown | option, or a list of options when `Multi = true` |
| Input | text or number |
| Keybind | key name like `"E"`, or `"None"` |
| Color picker | `Color3` |
| Label | text |
| Paragraph | `{ Title = "...", Content = "..." }` |

Buttons have `:Fire()` to run their callback from code.

---

## Flags

Give an element a `Flag` and its value is always readable from `Cloudy.Flags`:

```lua
Tab:CreateToggle({ Name = "Auto farm", Flag = "AutoFarm" })

task.spawn(function()
	while task.wait(1) do
		if Cloudy.Flags.AutoFarm then
			print("farming…")
		end
	end
end)
```

`Cloudy.Options.AutoFarm` is the element itself, so `Cloudy.Options.AutoFarm:Set(false)` also works. Flag names must be unique.

---

## Notifications

```lua
Cloudy:Notify({
	Title = "Saved",
	Content = "Your settings were applied.",
	Duration = 4,     -- seconds
	Type = "Success", -- "Info" (default) | "Success" | "Warning" | "Error"
})
```

Click a notification to dismiss it early.

## Dialogs

```lua
Window:Dialog({
	Title = "Are you sure?",
	Content = "This cannot be undone.",
	Buttons = {
		{ Name = "Cancel" },
		{
			Name = "Confirm",
			Primary = true,
			Callback = function()
				print("confirmed")
			end,
		},
	},
})
```

---

## Themes

```lua
Cloudy:SetTheme("Cloud") -- soft white and sky blue (default)
Cloudy:SetTheme("Light") -- pure white and gray
Cloudy:SetTheme("Gray")
Cloudy:SetTheme("Storm") -- dark blue-gray
Cloudy:SetTheme("Dark")
```

Themes switch instantly, even while the window is open.

### Custom theme

Pass a table with the colors you want to change:

```lua
Cloudy:SetTheme({
	Background = Color3.fromRGB(251, 253, 255),   -- window
	Surface = Color3.fromRGB(241, 246, 252),      -- hover and soft fills
	SurfaceHover = Color3.fromRGB(231, 239, 249), -- stronger hover
	Border = Color3.fromRGB(221, 231, 243),       -- outlines and lines
	Text = Color3.fromRGB(38, 50, 68),            -- main text
	SubText = Color3.fromRGB(124, 139, 160),      -- gray text
	Accent = Color3.fromRGB(108, 172, 240),       -- toggle on, slider fill, primary button
	AccentText = Color3.fromRGB(255, 255, 255),   -- text on accent
	Track = Color3.fromRGB(211, 223, 238),        -- toggle off, slider bar
	Knob = Color3.fromRGB(255, 255, 255),         -- toggle and slider knob
	Danger = Color3.fromRGB(229, 72, 77),         -- destructive buttons
	Shadow = 0.8,                                 -- shadow transparency (0–1)
})
```

To add a named theme to the settings tab picker, register it before creating the settings tab:

```lua
Cloudy.Themes.Ocean = { --[[ all the keys above ]] }
```

---

## Saving settings

```lua
local Window = Cloudy:CreateWindow({
	Name = "My Hub",
	ConfigurationSaving = { Enabled = true, FolderName = "MyHub", FileName = "config" },
})

-- create all your elements (each with a Flag) …

Cloudy:LoadConfiguration() -- call this last
```

- Only elements with a `Flag` are saved.
- Values save automatically shortly after they change; `Cloudy:SaveConfiguration()` saves immediately.
- Saving needs the `writefile` / `readfile` functions. Where they do not exist (normal Roblox Studio), saving is skipped without an error.

---

## The cloud logo

The cloud is stored inside the library as pixels and painted when the window opens, so it needs no uploaded image.

Painting uses Roblox's `EditableImage`. In your own published game, turn on **Game Settings → Security → Allow Mesh / Image APIs**. If painting is not allowed, the library draws a simple cloud shape instead.

To use your own logo, upload an image to Roblox and pass its asset ID:

```lua
Cloudy:CreateWindow({ Name = "My Hub", Icon = 1234567890 })
```

---

## Removing the interface

```lua
Cloudy:Destroy()
```

Removes every window and notification and disconnects everything the library created.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing appears | The script must be a **LocalScript**, not a Script |
| Window is hidden | Press **RightShift** |
| A callback does nothing | Check the Output window for `[CloudyUI] callback error` |
| Settings do not save | Saving needs `writefile` / `readfile` |
| The cloud looks like simple shapes | Enable **Allow Mesh / Image APIs** in Game Settings → Security |

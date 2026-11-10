--!nocheck
-- Cloudy UI example

local Cloudy = loadstring(game:HttpGet("https://raw.githubusercontent.com/rafttkxGIT/Cloudy-UI/refs/heads/main/Cloudy%20UI.luau"))()

local Window = Cloudy:CreateWindow({
	Name = "Cloudy Hub",
	Subtitle = "v1.0",
	Theme = "Cloud", -- "Cloud" | "Light" | "Gray" | "Storm" | "Dark" | custom table
	Size = Vector2.new(600, 420),
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigurationSaving = { Enabled = true, FolderName = "CloudyHub", FileName = "main" },
})

----------------------------------------------------------------------
local Main = Window:CreateTab("Main")

Main:CreateParagraph({
	Title = "Welcome",
	Content = "This is CloudyUI — a clean white and gray interface library. Every element is shown below.",
})

local Basics = Main:CreateSection("Basics")

Basics:CreateButton({
	Name = "Send notification",
	Description = "Shows a toast in the corner",
	Callback = function()
		Cloudy:Notify({ Title = "Hello!", Content = "This is a CloudyUI notification.", Duration = 4 })
		Cloudy:Notify({ Title = "Saved", Content = "Success style.", Type = "Success", Duration = 5 })
		Cloudy:Notify({ Title = "Careful", Content = "Warning style.", Type = "Warning", Duration = 6 })
		Cloudy:Notify({ Title = "Failed", Content = "Error style. Click a toast to dismiss it.", Type = "Error", Duration = 7 })
	end,
})

Basics:CreateToggle({
	Name = "Auto farm",
	Description = "Example toggle",
	Default = false,
	Flag = "AutoFarm",
	Callback = function(enabled)
		print("Auto farm:", enabled)
	end,
})

Basics:CreateSlider({
	Name = "Walk speed",
	Range = { 16, 100 },
	Increment = 1,
	Suffix = "studs/s",
	Default = 16,
	Flag = "WalkSpeed",
	Callback = function(value)
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

local Choices = Main:CreateSection("Choices")

local Mode = Choices:CreateDropdown({
	Name = "Mode",
	Options = { "Easy", "Normal", "Hard" },
	Default = "Normal",
	Flag = "Mode",
	Callback = function(option)
		print("Mode:", option)
	end,
})

Choices:CreateDropdown({
	Name = "Targets",
	Options = { "Coins", "Gems", "Chests", "Bosses" },
	Default = { "Coins" },
	Multi = true,
	Flag = "Targets",
	Callback = function(selected)
		print("Targets:", table.concat(selected, ", "))
	end,
})

Choices:CreateButton({
	Name = "Refresh mode options",
	Callback = function()
		Mode:Refresh({ "Easy", "Normal", "Hard", "Insane" }, true)
	end,
})

----------------------------------------------------------------------
local Inputs = Window:CreateTab("Inputs")

Inputs:CreateInput({
	Name = "Player name",
	Placeholder = "Username",
	Flag = "PlayerName",
	Callback = function(text)
		print("Name:", text)
	end,
})

Inputs:CreateInput({
	Name = "Amount",
	Placeholder = "0",
	Numeric = true,
	Flag = "Amount",
	Callback = function(number)
		print("Amount:", number)
	end,
})

Inputs:CreateKeybind({
	Name = "Dash",
	Default = "Q",
	Flag = "DashKey",
	Callback = function()
		print("Dash pressed")
	end,
})

Inputs:CreateKeybind({
	Name = "Sprint (hold)",
	Default = "LeftControl",
	Hold = true,
	Flag = "SprintKey",
	Callback = function(holding)
		print("Sprinting:", holding)
	end,
})

Inputs:CreateDivider()

Inputs:CreateColorPicker({
	Name = "Highlight color",
	Default = Color3.fromRGB(90, 140, 255),
	Flag = "HighlightColor",
	Callback = function(color)
		print("Color:", color)
	end,
})

Inputs:CreateLabel("Values are also readable any time through Cloudy.Flags.WalkSpeed, Cloudy.Flags.Mode, …")

Inputs:CreateButton({
	Name = "Open dialog",
	Callback = function()
		Window:Dialog({
			Title = "Reset everything?",
			Content = "This is a modal dialog with custom buttons.",
			Buttons = {
				{ Name = "Cancel" },
				{
					Name = "Confirm",
					Primary = true,
					Callback = function()
						Cloudy:Notify({ Title = "Confirmed", Content = "You pressed confirm." })
					end,
				},
			},
		})
	end,
})

----------------------------------------------------------------------
Window:CreateSettingsTab() -- theme picker, toggle keybind, unload button

Cloudy:LoadConfiguration() -- restores saved flags (when file APIs are available)
Cloudy:Notify({ Title = "Cloudy Hub loaded", Content = "Press RightShift to toggle the interface." })


--!nocheck
--[[
	CloudyUI  ·  a clean white & gray interface library for Roblox (Luau)

	Windows · Tabs · Sections · Buttons · Toggles · Sliders · Dropdowns (single/multi)
	Inputs · Keybinds · Color pickers · Labels · Paragraphs · Dividers
	Notifications · Dialogs · Search · Themes · Config saving · Mobile support

	local Cloudy = loadstring(game:HttpGet(URL))()   -- or require(ModuleScript)
	local Window = Cloudy:CreateWindow({ Name = "My Hub" })
	local Tab = Window:CreateTab("Main")
	Tab:CreateButton({ Name = "Hello", Callback = function() print("hi") end })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Cloudy = {
	Version = "2.3.0",
	Flags = {}, -- [flag] = current value
	Options = {}, -- [flag] = element object
	Themes = {},
	_connections = {},
	_refreshers = {},
	_guis = {},
	_windows = {},
}

----------------------------------------------------------------------
-- Themes
----------------------------------------------------------------------

local rgb = Color3.fromRGB

-- Default: soft white with a hint of sky, like clouds
Cloudy.Themes.Cloud = {
	Background = rgb(251, 253, 255),
	Surface = rgb(241, 246, 252),
	SurfaceHover = rgb(231, 239, 249),
	Border = rgb(221, 231, 243),
	Text = rgb(38, 50, 68),
	SubText = rgb(124, 139, 160),
	Accent = rgb(108, 172, 240),
	AccentText = rgb(255, 255, 255),
	Track = rgb(211, 223, 238),
	Knob = rgb(255, 255, 255),
	Danger = rgb(229, 72, 77),
	Logo = rgb(214, 219, 228),
	Shadow = 0.8,
}

Cloudy.Themes.Light = {
	Background = rgb(255, 255, 255),
	Surface = rgb(246, 246, 248),
	SurfaceHover = rgb(238, 238, 242),
	Border = rgb(229, 229, 234),
	Text = rgb(26, 26, 30),
	SubText = rgb(125, 125, 135),
	Accent = rgb(34, 34, 40),
	AccentText = rgb(255, 255, 255),
	Track = rgb(222, 222, 228),
	Knob = rgb(255, 255, 255),
	Danger = rgb(229, 72, 77),
	Logo = rgb(214, 219, 228),
	Shadow = 0.78,
}

Cloudy.Themes.Gray = {
	Background = rgb(236, 236, 239),
	Surface = rgb(226, 226, 230),
	SurfaceHover = rgb(216, 216, 221),
	Border = rgb(208, 208, 214),
	Text = rgb(34, 34, 38),
	SubText = rgb(110, 110, 120),
	Accent = rgb(70, 70, 78),
	AccentText = rgb(255, 255, 255),
	Track = rgb(198, 198, 205),
	Knob = rgb(255, 255, 255),
	Danger = rgb(229, 72, 77),
	Logo = rgb(214, 219, 228),
	Shadow = 0.75,
}

-- Night sky: deep blue-gray with a soft blue accent
Cloudy.Themes.Storm = {
	Background = rgb(24, 29, 38),
	Surface = rgb(32, 38, 49),
	SurfaceHover = rgb(40, 47, 60),
	Border = rgb(46, 54, 68),
	Text = rgb(230, 236, 245),
	SubText = rgb(136, 148, 168),
	Accent = rgb(120, 180, 245),
	AccentText = rgb(18, 24, 34),
	Track = rgb(54, 63, 79),
	Knob = rgb(255, 255, 255),
	Danger = rgb(229, 72, 77),
	Logo = rgb(255, 255, 255),
	Shadow = 0.5,
}

Cloudy.Themes.Dark = {
	Background = rgb(17, 17, 19),
	Surface = rgb(26, 26, 29),
	SurfaceHover = rgb(34, 34, 38),
	Border = rgb(39, 39, 44),
	Text = rgb(236, 236, 240),
	SubText = rgb(138, 138, 148),
	Accent = rgb(232, 232, 238),
	AccentText = rgb(17, 17, 19),
	Track = rgb(50, 50, 56),
	Knob = rgb(255, 255, 255),
	Danger = rgb(229, 72, 77),
	Logo = rgb(255, 255, 255),
	Shadow = 0.45,
}

Cloudy.Theme = table.clone(Cloudy.Themes.Cloud)
Cloudy.ThemeName = "Cloud"

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local FONT = "rbxasset://fonts/families/GothamSSm.json"
local Regular = Font.new(FONT, Enum.FontWeight.Regular)
local Medium = Font.new(FONT, Enum.FontWeight.Medium)
local Bold = Font.new(FONT, Enum.FontWeight.SemiBold)

local bindings = {}

local function bind(inst, prop, key)
	local map = bindings[inst]
	if not map then
		map = {}
		bindings[inst] = map
		inst.Destroying:Connect(function()
			bindings[inst] = nil
		end)
	end
	map[prop] = key
	inst[prop] = Cloudy.Theme[key]
end

local function create(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k == "Theme" then
				for prop, key in pairs(v) do
					bind(inst, prop, key)
				end
			elseif k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function tween(inst, time, props, style, dir)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(key)
	return create("UIStroke", {
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Theme = { Color = key or "Border" },
	})
end

local function padding(all, x)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, x or all),
		PaddingRight = UDim.new(0, x or all),
	})
end

local function list(gap, horizontal)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	})
end

local function text(str, size, font, colorKey, props)
	local base = {
		BackgroundTransparency = 1,
		Text = str or "",
		TextSize = size or 13,
		FontFace = font or Medium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = colorKey or "Text" },
	}
	if props then
		for k, v in pairs(props) do
			base[k] = v
		end
	end
	return create("TextLabel", base)
end

local function track(conn)
	table.insert(Cloudy._connections, conn)
	return conn
end

local function safeCall(callback, ...)
	if typeof(callback) ~= "function" then
		return
	end
	task.spawn(function(...)
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("[CloudyUI] callback error: " .. tostring(err))
		end
	end, ...)
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Calls onMove(Vector3 position) while the pointer is held on `gui`.
local function dragInput(gui, onMove, onEnd)
	local dragging = false
	gui.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		dragging = true
		onMove(input.Position)
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				conn:Disconnect()
				if onEnd then
					onEnd()
				end
			end
		end)
	end)
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and isMove(input) then
			onMove(input.Position)
		end
	end))
end

local function hover(button, target, normalKey, hoverKey)
	button.MouseEnter:Connect(function()
		tween(target, 0.15, { BackgroundColor3 = Cloudy.Theme[hoverKey] })
	end)
	button.MouseLeave:Connect(function()
		tween(target, 0.15, { BackgroundColor3 = Cloudy.Theme[normalKey] })
	end)
end

-- Soft expanding circle from the press point (card must clip descendants).
local function ripple(card, position)
	local origin, size = card.AbsolutePosition, card.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	local circle = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(
			math.clamp((position.X - origin.X) / size.X, 0, 1),
			math.clamp((position.Y - origin.Y) / size.Y, 0, 1)
		),
		Size = UDim2.fromScale(0, 0),
		BackgroundColor3 = Cloudy.Theme.Accent,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = card,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }),
	})
	tween(circle, 0.6, { Size = UDim2.fromScale(2.4, 2.4), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	task.delay(0.65, function()
		circle:Destroy()
	end)
end

-- Web-style focus ring: the outline turns accent while a text box is focused.
local function focusRing(box)
	local outline = box:FindFirstChildOfClass("UIStroke")
	if not outline then
		return
	end
	box.Focused:Connect(function()
		tween(outline, 0.2, { Color = Cloudy.Theme.Accent })
	end)
	box.FocusLost:Connect(function()
		tween(outline, 0.2, { Color = Cloudy.Theme.Border })
	end)
end

local function attachRipple(card)
	card.InputBegan:Connect(function(input)
		if isPress(input) then
			ripple(card, input.Position)
		end
	end)
end

-- The cloud logo, stored as pixels (gray + alpha per pixel, hex) and painted at runtime
-- with an EditableImage, so no uploaded asset is needed.
local CLOUD_W, CLOUD_H = 50, 33
local CLOUD_DATA = table.concat({
	"0000000000000000000000000000000000000000000000000000000000000000000000000000000053255a58676f73857199",
	"73a970a86d916869553900000000000000000000000000000000000000000000000000000000000000000000000000000000",
	"00000000000000000000000000000000000000000000000000000000000000000000000086a5a1f59fffa2ff9cffa0ffa8ff",
	"aaffabffacffb0ffb1ffa6fe99bc504300000000000000000000000000000000000000000000000000000000000000000000",
	"0000000000000000000000000000000000000000000000000000000000000000524198efa3ff99ff9bff9bffa5ffaaffa6ff",
	"adffb2ffb0ffaeffafffafffaeffa3f761760000000000000000000000000000000000000000000000000000000000000000",
	"0000000000000000000000000000000000000000000000000000000000006fa5a1ff9affa1ff97ff98ffa8ffa1ffa2ffa5ff",
	"abffb0ffb4ffb7ffbaffb9ffb6ffb4ffb6ff697e000000000000000000000000000000000000000000000000000000000000",
	"000000000000000000000000000000000000000000000000000000006b9e9aff96ffa0ff90ff98ffa7ff9effa3ffafffb2ff",
	"b4ffb5ffb5ffb6ffb7ffb8ffb6ffb5ffb4ffabf1546100000000000000000000000000000000000000000000000000000000",
	"00000000000000000000000000000000000000000000000000005b7699ff93ff9dff95ff9cff9aff9affa5ffa7ffaaffacff",
	"b4ffbbffbdffbaffb8ffb8ffb8ffc0ffb3ffb0ff9bc636130000000000000000000000000000000000000000000000000000",
	"000000000000000000000000000000000000000000000000242a8fff91ff98ff93ff93ff95ff9dffa4ffa8ffaeffaeffb9ff",
	"bbffbcffbbffbaffbaffbbffbbffb6ffb4ffb1ffb4ff6e8b0000000000000000000000000000000000000000000000000000",
	"0000000000000000000000000000000000000000000000006dcc9dff9aff92ff9dff98ff95ff9affa5ffaeffb1ffb1ffb8ff",
	"beffc1ffc0ffbfffbfffbeffbaffb7ffb5ffb3ffb4ffa0f02d49000000000000000000000000000000000000000000000000",
	"0000000000000000000000000000000000000000171633508cff9eff98ff92ff90ff96ff9dffa1ffa5ffaaffb2ffb8ffbaff",
	"bfffc1ffbfffbdffbdffbbffb7ffb6ffb0ffb0ffb4ffafff47a1001600000000000000000000000000000000000000000000",
	"0000000000000000000000000000363d568273ff80ff97ffb8ffafffacffa9ff9fff9eff9fffa3ffaaffb2ffb6ffb9ffbcff",
	"c0ffc1ffbfffbcffbaffb7ffb3ffb4ffacffacffafffb9ff65ff0b5a00000000000000000000000000000000000000000000",
	"00000000000000000000554b7ad6a1ffb6ffc0ffbaffbaffc2ffc4ffcbffceffc1ffb7ffacffaaffb1ffb8ffbbffbaffbeff",
	"c1ffc1ffbeffbbffb9ffb5ffb0ffaeffaeffb0ffb2ffb6ff74ff1ab2168818410b1800000000000000000000000000000000",
	"00000000000000008196aaffb5ffb8ffb4ffb2ffb9ffc2ffc4ffc7ffc3ffcdffd2ffceffc7ffbeffb8ffb7ffbbffc0ffc0ff",
	"c0ffc0ffbdffbaffb7ffb3ffb0ffb0ffb2ffabffafffb5ffa6ff8fff96ffa1ff92ff71db3774000400000000000000000000",
	"0000000000008db0b6ffb0ffbcffb0ffb0ffb0ffbbffb8ffb8ffc4ffc6ffd2ffd1ffd5ffd6ffcfffc4ffbdffbdffc0ffc0ff",
	"bfffbcffbaffb7ffb4ffb0ffaeffa7ffafffaeffb6ffbaffbcffc5ffc8ffcfffceffd1ffc4ff6ddb14330000000000000000",
	"00000000979bb8ffadffbdffafffabffaeffb2ffb8ffb9ffc7ffd3ffd0ffc8ffd0ffd1ffd2ffd1ffccffc6ffc0ffbdffbfff",
	"bcffb8ffb5ffb3ffb0ffadffabffacffadffabffb0ffb7ffbbffcaffcfffd5ffe0ffd5ffcaffd9ff9bff2878000000000000",
	"0000815fb6ffb4ffaeffa4ffa8ffa9ffb0ffb3ffb3ffbeffc6ffbdffcbffd0ffcfffd0ffd0ffceffcaffc6ffc3ffc2ffbdff",
	"baffb5ffb2ffafffacffa9ffa8ffa8ffa7ffadffb4ffc7ffc6ffc8ffceffd6ffd5ffdaffdaffd1ffcbff93ff2aae00010000",
	"0000abffaaffa3ffa1ffa0ffacffa5ffb1ffb4ffb7ffb9ffbdffc2ffc7ffc8ffc7ffcaffccffceffccffc9ffc4ffc1ffbcff",
	"b8ffb3ffafffacffaaffa9ffa7ffa8ffacffb3ffbcffc5ffcaffceffd0ffd5ffdaffd5ffd5ffd3ffd2ffb4ff65ff13a30000",
	"8858acffa4ffa2ff9fffa0ffa7ffadffb1ffb4ffb6ffb9ffbdffc2ffc5ffc6ffc3ffc4ffc6ffc6ffc5ffc3ffc0ffbeffbaff",
	"b6ffb2ffafffadffabffaaffa9ffaaffadffb3ffbdffc7ffceffd2ffd3ffd4ffdaffd6ffd4ffcbffc8ffbcff8eff2bff120e",
	"a9a19eff9cffa1ff9effa2ffa1ffabffb0ffb2ffb4ffb6ffbaffbfffc0ffbfffbfffbfffbfffbfffbeffbdffbcffbbffb7ff",
	"b5ffb1ffafffaeffadffadffadffaeffb2ffb8ffc1ffcaffd1ffd5ffd5ffd8ffdbffd4ffd0ffc3ffbaffbbffadff50ff12da",
	"a4c299ff9fffa1ffa2ffa8ffa6ffacffaeffafffb0ffb1ffb5ffb8ffb8ffb5ffb9ffb8ffb8ffb8ffb8ffb8ffb8ffb8ffb4ff",
	"b3ffb1ffb0ffafffafffb0ffb0ffb2ffb9ffc1ffc8ffcfffd3ffd6ffd6ffd8ffd5ffc8ffc3ffbbffafffafffacff6aff12ff",
	"9be0a0ff9eff99ffa0ffa3ffa8ffacffaeffaeffadffadffb0ffb2ffb0ffadffafffafffafffafffb0ffb1ffb2ffb2ffb1ff",
	"b0ffb0ffafffafffb0ffb2ffb3ffb6ffbfffcaffcfffd2ffd4ffd6ffd6ffd0ffcbffbbffb5ffb2ffa9ffa4ffa1ff71ff10ff",
	"99e5a0ff97ff96ffa2ff9dffa4ffa8ffacffacffaaffa9ffa9ffaaffa9ffa6ffa5ffa6ffa6ffa8ffa9ffabffadffaeffadff",
	"aeffaeffafffb0ffb2ffb4ffb6ffbaffc5ffcfffd2ffd3ffd4ffd3ffd2ffccffc6ffb9ffaeffa8ffa2ff9dff9cff72ff14ff",
	"99ce9dff9cff9cffa7ffa1ffa4ffa5ffa4ffa5ffa4ffa1ffa0ffa0ffa0ff9eff9eff9eff9eff9fffa2ffa5ffa8ffaaffacff",
	"adffafffb1ffb3ffb5ffb9ffbbffc2ffcaffd0ffd1ffd1ffd1ffceffcaffc6ffbdffb3ffa7ff9eff99ff96ff97ff6aff14ff",
	"98a497ffa0ff98ff9cff9cffa0ff9cff9cff9dff9cff99ff97ff98ff98ff97ff97ff96ff96ff97ff9aff9fffa3ffa5ffacff",
	"aeffb1ffb4ffb6ffb9ffbdffc0ffcaffceffd1ffd0ffcfffcfffcaffc3ffbaffadffa6ff9eff96ff92ff8fff90ff5aff0aff",
	"8f599fff93ff96ff9dff91ff92ff94ff91ff92ff90ff8cff8aff8bff8cff8bff8cff8bff8dff92ff96ff99ff9dffa0ffa5ff",
	"adffb1ffb1ffb6ffbdffc2ffc7ffccffcaffceffd2ffcfffcaffc0ffb4ffacffa2ff9aff99ff8cff91ff8aff7fff3eff18d6",
	"00009fdc98ff94ff90ff8bff93ff8cff88ff89ff88ff85ff83ff84ff84ff83ff83ff84ff87ff8bff8fff92ff97ff9bff9fff",
	"a9ffafffb2ffb9ffc0ffc4ffc7ffcfffccffceffceffc8ffc0ffb6ffabff9fff9dff8dff89ff89ff81ff80ff74ff2dff1a0a",
	"0000000096ff8bff90ff88ff7fff7cff7dff7eff7eff7cff7bff7bff7cff7bff7cff7eff82ff86ff89ff8dff93ff99ffa0ff",
	"abffb1ffb6ffbeffc4ffc7ffcaffccffc9ffc8ffc5ffbcffb2ffa9ff9fff9cff8aff85ff8eff8bff7cff7dff50ff19f50000",
	"000000008f7d7dff7fff85ff83ff80ff7aff7aff7aff78ff77ff78ff7aff7bff77ff7aff7fff83ff85ff89ff92ff99ffa1ff",
	"aaffafffb3ffbbffc1ffc4ffc6ffc9ffc5ffc3ffbeffb3ffaaffa2ff9aff91ff90ff8dff80ff78ff7dff6cff27ff091b0000",
	"00000000000086617fff74ff7cff7dff74ff73ff72ff70ff70ff71ff74ff76ff75ff78ff7dff81ff83ff87ff91ff99ffa4ff",
	"adffb3ffb8ffc1ffc6ffc6ffc6ffc2ffbeffbbffb4ffa8ffa0ff99ff93ff86ff88ff7fff7bff84ff76ff36ff127100000000",
	"0000000000000000000082ff7cff76ff73ff72ff70ff70ff6fff70ff73ff76ff78ff7aff7fff82ff85ff8aff93ff9cff9eff",
	"a8ffb0ffb6ffc0ffc4ffc1ffbfffbfffbaffb6ffafffa3ff9bff96ff90ff92ff8aff88ff84ff6dff45ff0d28000000000000",
	"0000000000000000000000007e8479ff76ff75ff74ff75ff75ff74ff76ff78ff76ff78ff7bff7fff82ff87ff90ff98ffa1ff",
	"a9ffaeffb2ffbaffbeffbaffb7ffb5ffafffabffa6ff9dff97ff93ff8dff8dff8bff84ff54ff195200000000000000000000",
	"0000000000000000000000000000000000006b4f6ab66de76cff6aff6bff6dff6eff6fff71ff74ff78ff7dff86ff8dff91ff",
	"96ff95ff96ff9cff9fff9cff9bff99ff94ff91ff8dff88ff84ff82ff7dff6ad8485800000000000000000000000000000000",
	"00000000000000000000000000000000000000000000000000000000000000000000000000001525144118551b791ea321bb",
	"1fd51ef81eff1fff21ff21ff21ff1eff1dff1cff1bff1bdb1b5f000000000000000000000000000000000000000000000000",
	"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
	"0000000000000000000600090003000000000000000000000000000000000000000000000000000000000000000000000000",
})

local cloudImage = nil -- EditableImage, or false when the device/game does not allow it

local function getCloudImage()
	if cloudImage ~= nil then
		return cloudImage
	end
	cloudImage = false
	pcall(function()
		local image = game:GetService("AssetService"):CreateEditableImage({
			Size = Vector2.new(CLOUD_W, CLOUD_H),
		})
		if not image then
			return
		end
		local count = CLOUD_W * CLOUD_H
		local pixels = buffer.create(count * 4)
		for i = 0, count - 1 do
			local gray = tonumber(string.sub(CLOUD_DATA, i * 4 + 1, i * 4 + 2), 16)
			local alpha = tonumber(string.sub(CLOUD_DATA, i * 4 + 3, i * 4 + 4), 16)
			buffer.writeu8(pixels, i * 4, gray)
			buffer.writeu8(pixels, i * 4 + 1, gray)
			buffer.writeu8(pixels, i * 4 + 2, gray)
			buffer.writeu8(pixels, i * 4 + 3, alpha)
		end
		image:WritePixelsBuffer(Vector2.zero, Vector2.new(CLOUD_W, CLOUD_H), pixels)
		cloudImage = image
	end)
	return cloudImage
end

-- Cloud logo. Order of preference: your `icon` asset id, the embedded cloud image,
-- then a cloud drawn from rounded frames if images cannot be painted here.
-- Returns the container and a fade(time, transparency) function.
local function makeCloud(parent, height, props, icon)
	local base = {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, math.floor(height * 1.5 + 0.5), 0, height),
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local container = create("Frame", base)

	if icon then
		local image = create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ScaleType = Enum.ScaleType.Fit,
			Image = typeof(icon) == "number" and ("rbxassetid://" .. icon) or tostring(icon),
			Parent = container,
		})
		container.Parent = parent
		return container, function(time, transparency)
			tween(image, time, { ImageTransparency = transparency })
		end
	end

	local embedded = getCloudImage()
	if embedded then
		local image = create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ScaleType = Enum.ScaleType.Fit,
			Parent = container,
		})
		local ok = pcall(function()
			image.ImageContent = Content.fromObject(embedded)
		end)
		if ok then
			container.Parent = parent
			return container, function(time, transparency)
				tween(image, time, { ImageTransparency = transparency })
			end
		end
		image:Destroy()
	end

	local pieces = {}
	local function piece(cx, cy, w, h, shade, z)
		table.insert(pieces, create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cx, cy),
			Size = UDim2.fromScale(w, h),
			BorderSizePixel = 0,
			ZIndex = z,
			Theme = { BackgroundColor3 = "Logo" },
			Parent = container,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			-- white on top fading to soft gray underneath, like a lit cloud
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.new(1, 1, 1), shade),
			}),
		}))
	end
	piece(0.25, 0.60, 0.34, 0.50, rgb(226, 230, 236), 1) -- left puff
	piece(0.50, 0.42, 0.50, 0.75, rgb(232, 235, 240), 1) -- big middle puff
	piece(0.76, 0.62, 0.36, 0.52, rgb(222, 226, 233), 1) -- right puff
	piece(0.50, 0.76, 1.00, 0.48, rgb(188, 194, 204), 2) -- flat base

	container.Parent = parent
	return container, function(time, transparency)
		for _, frame in ipairs(pieces) do
			tween(frame, time, { BackgroundTransparency = transparency })
		end
	end
end

local function mountGui(gui)
	local mounted = false
	if typeof(gethui) == "function" then
		mounted = pcall(function()
			gui.Parent = gethui()
		end)
	end
	if not mounted then
		mounted = pcall(function()
			gui.Parent = game:GetService("CoreGui")
		end)
	end
	if not mounted or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	table.insert(Cloudy._guis, gui)
end

----------------------------------------------------------------------
-- Theme API
----------------------------------------------------------------------

function Cloudy:SetTheme(theme)
	if typeof(theme) == "string" then
		local preset = self.Themes[theme]
		if not preset then
			warn("[CloudyUI] unknown theme: " .. theme)
			return
		end
		self.ThemeName = theme
		theme = preset
	else
		self.ThemeName = "Custom"
	end
	for key, value in pairs(theme) do
		self.Theme[key] = value
	end
	for inst, map in pairs(bindings) do
		for prop, key in pairs(map) do
			pcall(function()
				inst[prop] = self.Theme[key]
			end)
		end
	end
	for _, refresh in ipairs(self._refreshers) do
		pcall(refresh)
	end
end

function Cloudy:GetThemes()
	local names = {}
	for name in pairs(self.Themes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

----------------------------------------------------------------------
-- Configuration saving
----------------------------------------------------------------------

local fs = {
	write = writefile,
	read = readfile,
	isfile = isfile,
	isfolder = isfolder,
	makefolder = makefolder,
}

Cloudy._config = { Enabled = false, FolderName = "CloudyUI", FileName = "config" }
Cloudy._loading = false

local function configPath()
	local cfg = Cloudy._config
	return cfg.FolderName, cfg.FolderName .. "/" .. cfg.FileName .. ".json"
end

local function encodeValue(value)
	if typeof(value) == "Color3" then
		return { __type = "Color3", hex = value:ToHex() }
	end
	return value
end

local function decodeValue(value)
	if typeof(value) == "table" and value.__type == "Color3" then
		return Color3.fromHex(value.hex)
	end
	return value
end

function Cloudy:SaveConfiguration()
	if not (self._config.Enabled and fs.write) then
		return false
	end
	local data = {}
	for flag, option in pairs(self.Options) do
		data[flag] = encodeValue(option.Value)
	end
	local folder, path = configPath()
	return pcall(function()
		if fs.makefolder and fs.isfolder and not fs.isfolder(folder) then
			fs.makefolder(folder)
		end
		fs.write(path, HttpService:JSONEncode(data))
	end)
end

function Cloudy:LoadConfiguration()
	if not (self._config.Enabled and fs.read and fs.isfile) then
		return false
	end
	local _, path = configPath()
	local ok, data = pcall(function()
		if not fs.isfile(path) then
			return nil
		end
		return HttpService:JSONDecode(fs.read(path))
	end)
	if not ok or typeof(data) ~= "table" then
		return false
	end
	self._loading = true
	for flag, value in pairs(data) do
		local option = self.Options[flag]
		if option and option.Set then
			pcall(option.Set, option, decodeValue(value))
		end
	end
	self._loading = false
	return true
end

local saveQueued = false
local function queueSave()
	if Cloudy._loading or saveQueued or not Cloudy._config.Enabled then
		return
	end
	saveQueued = true
	task.delay(0.5, function()
		saveQueued = false
		Cloudy:SaveConfiguration()
	end)
end

----------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------

local notifyHolder

local function getNotifyHolder()
	if notifyHolder and notifyHolder.Parent then
		return notifyHolder
	end
	local gui = create("ScreenGui", {
		Name = "CloudyUI_Notifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 200,
	})
	notifyHolder = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 290, 1, -32),
		Parent = gui,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),
	})
	mountGui(gui)
	return notifyHolder
end

local notifyCount = 0

local NOTIFY_COLORS = {
	Success = rgb(72, 187, 120),
	Error = rgb(235, 87, 87),
	Warning = rgb(240, 173, 78),
}

-- Cloudy:Notify({ Title, Content, Duration, Type = "Info" | "Success" | "Warning" | "Error" })
function Cloudy:Notify(opts)
	opts = opts or {}
	local holder = getNotifyHolder()
	notifyCount += 1
	local duration = opts.Duration or 4
	local color = NOTIFY_COLORS[opts.Type] or self.Theme.Accent

	local wrap = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = notifyCount,
		Parent = holder,
	})
	local slide = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(1, 60, 0, 0),
		Parent = wrap,
	})
	local card = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "Background" },
		Parent = slide,
	}, {
		corner(12),
		stroke("Border"),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 14),
		}),
		list(4),
		text(opts.Title or "Notification", 14, Bold, "Text", {
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 1,
		}),
		text(opts.Content or "", 13, Regular, "SubText", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
		}),
	})
	-- colored pill on the left
	create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 3, 1, -24),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = slide,
	}, { corner(2) })
	-- time-left line
	local progress = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -7),
		Size = UDim2.new(1, -38, 0, 2),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = slide,
	}, { corner(1) })

	local dismissed = false
	card.InputBegan:Connect(function(input)
		if isPress(input) then
			dismissed = true
		end
	end)

	task.spawn(function()
		task.wait()
		task.wait()
		local height = card.AbsoluteSize.Y
		tween(wrap, 0.3, { Size = UDim2.new(1, 0, 0, height) })
		tween(slide, 0.45, { Position = UDim2.new(0, 0, 0, 0) })
		tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
		local elapsed = 0
		while elapsed < duration and not dismissed do
			elapsed += task.wait()
		end
		tween(slide, 0.4, { Position = UDim2.new(1, 60, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.wait(0.4)
		tween(wrap, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
		task.wait(0.25)
		wrap:Destroy()
	end)
end

----------------------------------------------------------------------
-- Elements (shared by tabs and sections)
----------------------------------------------------------------------

local Elements = {}
Elements.__index = Elements

local function nextOrder(container)
	container._order += 1
	return container._order
end

-- Base card used by every interactive element.
local function makeCard(container, name, description, class)
	local hasDesc = description ~= nil and description ~= ""
	local height = hasDesc and 54 or 40
	local card = create(class or "Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = nextOrder(container),
		Theme = { BackgroundColor3 = "Background" },
		Parent = container._holder,
	}, { corner(8), stroke("Border") })
	if card:IsA("TextButton") then
		card.Text = ""
		card.AutoButtonColor = false
	end

	local title = text(name or "", 13, Medium, "Text", {
		Position = UDim2.new(0, 12, 0, hasDesc and 9 or 0),
		Size = UDim2.new(0.55, -12, 0, hasDesc and 18 or 40),
		Parent = card,
	})
	if hasDesc then
		text(description, 12, Regular, "SubText", {
			Position = UDim2.new(0, 12, 0, 28),
			Size = UDim2.new(1, -24, 0, 16),
			Parent = card,
		})
	end
	return card, title, height
end

local function register(container, obj, frame, name, flag)
	local item = { Frame = frame, Name = string.lower(name or ""), Hidden = false }
	table.insert(container._items, item)
	obj.Frame = frame
	obj.Flag = flag

	function obj:SetVisible(visible)
		item.Hidden = not visible
		frame.Visible = visible
	end

	function obj:Destroy()
		local index = table.find(container._items, item)
		if index then
			table.remove(container._items, index)
		end
		if flag then
			Cloudy.Options[flag] = nil
			Cloudy.Flags[flag] = nil
		end
		frame:Destroy()
	end

	if flag then
		Cloudy.Options[flag] = obj
		Cloudy.Flags[flag] = obj.Value
	end
	return obj
end

local function changed(obj, callback, ...)
	if obj.Flag then
		Cloudy.Flags[obj.Flag] = obj.Value
		queueSave()
	end
	safeCall(callback, ...)
end

-- Section ------------------------------------------------------------

function Elements:CreateSection(name)
	local frame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(self),
		Parent = self._holder,
	}, { list(8) })

	local header = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		LayoutOrder = 0,
		Parent = frame,
	})
	local title = text(string.upper(name or "Section"), 11, Bold, "SubText", {
		Position = UDim2.new(0, 2, 0, 4),
		Size = UDim2.new(1, -24, 1, -4),
		Parent = header,
	})
	local arrow = text("›", 16, Medium, "SubText", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 2),
		Size = UDim2.new(0, 14, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Center,
		Rotation = 90,
		Parent = header,
	})
	local content = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = frame,
	}, { list(8) })

	local section = setmetatable({
		_holder = content,
		_window = self._window,
		_items = self._items,
		_order = 0,
		Frame = frame,
		Collapsed = false,
	}, Elements)

	function section:SetCollapsed(collapsed)
		self.Collapsed = collapsed
		content.Visible = not collapsed
		tween(arrow, 0.2, { Rotation = collapsed and 0 or 90 })
	end

	function section:SetName(newName)
		title.Text = string.upper(newName)
	end

	header.MouseButton1Click:Connect(function()
		section:SetCollapsed(not section.Collapsed)
	end)

	return section
end

-- Label / Paragraph / Divider ---------------------------------------

function Elements:CreateLabel(str)
	if typeof(str) == "table" then
		str = str.Text or str.Name
	end
	local label = text(str, 13, Regular, "SubText", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = nextOrder(self),
		Parent = self._holder,
	})
	create("UIPadding", { PaddingLeft = UDim.new(0, 2), Parent = label })

	local obj = {}
	function obj:Set(newText)
		label.Text = newText
	end
	return register(self, obj, label, str)
end

function Elements:CreateParagraph(opts)
	opts = opts or {}
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(self),
		Theme = { BackgroundColor3 = "Surface" },
		Parent = self._holder,
	}, { corner(10), stroke("Border"), padding(12), list(4) })

	local title = text(opts.Title or "", 13, Bold, "Text", {
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
		Parent = card,
	})
	local content = text(opts.Content or "", 13, Regular, "SubText", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		Parent = card,
	})

	local obj = {}
	function obj:Set(newOpts)
		if newOpts.Title then
			title.Text = newOpts.Title
		end
		if newOpts.Content then
			content.Text = newOpts.Content
		end
	end
	return register(self, obj, card, (opts.Title or "") .. " " .. (opts.Content or ""))
end

function Elements:CreateDivider()
	local wrap = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 9),
		LayoutOrder = nextOrder(self),
		Parent = self._holder,
	}, {
		create("Frame", {
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, 1),
			Theme = { BackgroundColor3 = "Border" },
		}),
	})
	local obj = {}
	function obj:Destroy()
		wrap:Destroy()
	end
	return obj
end

-- Button -------------------------------------------------------------

-- Variant = "Outline" (default) | "Primary" | "Secondary" | "Ghost" | "Destructive"
local BUTTON_VARIANTS = {
	--              fill          hover         text          outline
	Outline = { "Background", "Surface", "Text", "Border" },
	Primary = { "Accent", "Accent", "AccentText", "Accent" },
	Secondary = { "Surface", "SurfaceHover", "Text", "Surface" },
	Ghost = { "Background", "Surface", "Text", "Background" },
	Destructive = { "Danger", "Danger", nil, "Danger" },
}

function Elements:CreateButton(opts)
	opts = opts or {}
	local variant = BUTTON_VARIANTS[opts.Variant] or BUTTON_VARIANTS.Outline
	local fillKey, hoverKey, textKey, outlineKey = variant[1], variant[2], variant[3], variant[4]
	local filled = fillKey == hoverKey -- solid buttons dim on hover instead of changing color
	local hasDesc = opts.Description ~= nil and opts.Description ~= ""

	local card, title = makeCard(self, opts.Name, opts.Description, "TextButton")
	bind(card, "BackgroundColor3", fillKey)
	bind(card:FindFirstChildOfClass("UIStroke"), "Color", outlineKey)

	for _, child in ipairs(card:GetChildren()) do
		if child:IsA("TextLabel") then
			if textKey then
				bind(child, "TextColor3", textKey)
			else
				bindings[child] = nil
				child.TextColor3 = Color3.new(1, 1, 1)
			end
			if child ~= title and filled then
				child.TextTransparency = 0.25
			end
		end
	end

	if hasDesc then
		title.Size = UDim2.new(1, -24, 0, title.Size.Y.Offset)
	else
		-- plain button: centered label, like a web button
		card.Size = UDim2.new(1, 0, 0, 36)
		title.Position = UDim2.new(0, 12, 0, 0)
		title.Size = UDim2.new(1, -24, 1, 0)
		title.TextXAlignment = Enum.TextXAlignment.Center
	end

	card.MouseEnter:Connect(function()
		if filled then
			tween(card, 0.15, { BackgroundTransparency = 0.12 })
		else
			tween(card, 0.15, { BackgroundColor3 = Cloudy.Theme[hoverKey] })
		end
	end)
	card.MouseLeave:Connect(function()
		tween(card, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = Cloudy.Theme[fillKey] })
	end)

	local obj = { Type = "Button" }
	attachRipple(card)
	card.MouseButton1Click:Connect(function()
		safeCall(opts.Callback)
	end)

	function obj:SetName(name)
		title.Text = name
	end
	function obj:Fire()
		safeCall(opts.Callback)
	end
	return register(self, obj, card, opts.Name)
end

-- Toggle -------------------------------------------------------------

function Elements:CreateToggle(opts)
	opts = opts or {}
	local card, title = makeCard(self, opts.Name, opts.Description, "TextButton")
	hover(card, card, "Background", "Surface")

	local switch = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 20),
		BorderSizePixel = 0,
		Parent = card,
	}, { corner(10) })
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 14, 0, 14),
		BorderSizePixel = 0,
		Parent = switch,
	}, { corner(7) })

	local obj = { Type = "Toggle", Value = opts.Default == true }

	local function render(instant)
		local on = obj.Value
		local time = instant and 0 or 0.2
		tween(switch, time, { BackgroundColor3 = on and Cloudy.Theme.Accent or Cloudy.Theme.Track })
		tween(knob, time, {
			Position = UDim2.new(0, on and 19 or 3, 0.5, 0),
			BackgroundColor3 = on and Cloudy.Theme.AccentText or Cloudy.Theme.Knob,
		})
	end
	render(true)
	table.insert(Cloudy._refreshers, function()
		render(true)
	end)

	function obj:Set(value, silent)
		self.Value = value == true
		render()
		if silent then
			if self.Flag then
				Cloudy.Flags[self.Flag] = self.Value
			end
		else
			changed(self, opts.Callback, self.Value)
		end
	end
	function obj:SetName(name)
		title.Text = name
	end

	attachRipple(card)
	card.MouseButton1Click:Connect(function()
		obj:Set(not obj.Value)
	end)
	return register(self, obj, card, opts.Name, opts.Flag)
end

-- Slider -------------------------------------------------------------

function Elements:CreateSlider(opts)
	opts = opts or {}
	local range = opts.Range or { opts.Min or 0, opts.Max or 100 }
	local min, max = range[1], range[2]
	local increment = opts.Increment or 1
	local suffix = opts.Suffix and (" " .. opts.Suffix) or ""

	local card, title = makeCard(self, opts.Name, nil, "Frame")
	card.Size = UDim2.new(1, 0, 0, 56)
	title.Size = UDim2.new(0.6, -12, 0, 36)

	-- Click the value to type an exact number
	local valueLabel = create("TextBox", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.4, -12, 0, 36),
		Text = "",
		TextSize = 12,
		FontFace = Medium,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = true,
		Theme = { TextColor3 = "SubText" },
		Parent = card,
	})
	local hit = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 30),
		Size = UDim2.new(1, -24, 0, 22),
		Parent = card,
	})
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "Track" },
		Parent = hit,
	}, { corner(3) })
	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = bar,
	}, { corner(3) })
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "Knob" },
		Parent = bar,
	}, { corner(7), stroke("Accent") })

	local function snap(value)
		value = math.clamp(tonumber(value) or min, min, max)
		value = min + math.floor((value - min) / increment + 0.5) * increment
		value = math.clamp(value, min, max)
		return math.floor(value * 1e5 + 0.5) / 1e5
	end

	local obj = { Type = "Slider", Value = snap(opts.Default or min) }

	local function render(instant)
		local alpha = (max == min) and 0 or (obj.Value - min) / (max - min)
		local time = instant and 0 or 0.12
		tween(fill, time, { Size = UDim2.new(alpha, 0, 1, 0) })
		tween(knob, time, { Position = UDim2.new(alpha, 0, 0.5, 0) })
		valueLabel.Text = tostring(obj.Value) .. suffix
	end
	render(true)

	function obj:Set(value, silent)
		value = snap(value)
		if value == self.Value then
			return
		end
		self.Value = value
		render()
		if silent then
			if self.Flag then
				Cloudy.Flags[self.Flag] = value
			end
		else
			changed(self, opts.Callback, value)
		end
	end
	function obj:SetName(name)
		title.Text = name
	end

	dragInput(hit, function(position)
		local width = bar.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((position.X - bar.AbsolutePosition.X) / width, 0, 1)
		tween(knob, 0.15, { Size = UDim2.new(0, 18, 0, 18) })
		obj:Set(min + (max - min) * alpha)
	end, function()
		tween(knob, 0.2, { Size = UDim2.new(0, 14, 0, 14) })
	end)

	valueLabel.FocusLost:Connect(function()
		local typed = tonumber(string.match(valueLabel.Text, "%-?%d+%.?%d*") or "")
		if typed then
			obj:Set(typed)
		end
		render(true)
	end)

	return register(self, obj, card, opts.Name, opts.Flag)
end

-- Dropdown -----------------------------------------------------------

function Elements:CreateDropdown(opts)
	opts = opts or {}
	local multi = opts.Multi == true
	local options = table.clone(opts.Options or {})

	local card, title = makeCard(self, opts.Name, nil, "Frame")
	title.Size = UDim2.new(0.5, -12, 0, 40)

	local header = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		Parent = card,
	})
	local selectedLabel = text("", 12, Regular, "SubText", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -34, 0, 0),
		Size = UDim2.new(0.5, -34, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})
	local arrow = text("›", 18, Medium, "SubText", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -19, 0, 20),
		Size = UDim2.new(0, 14, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Center,
		Rotation = 90,
		Parent = card,
	})
	local listFrame = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 42),
		Size = UDim2.new(1, -16, 0, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Theme = { ScrollBarImageColor3 = "Track" },
		Parent = card,
	}, { list(2) })

	local obj = { Type = "Dropdown", Open = false }
	if multi then
		obj.Value = typeof(opts.Default) == "table" and table.clone(opts.Default) or {}
	else
		obj.Value = opts.Default
	end

	local optionButtons = {}

	local function isSelected(option)
		if multi then
			return table.find(obj.Value, option) ~= nil
		end
		return obj.Value == option
	end

	local function render()
		if multi then
			selectedLabel.Text = #obj.Value > 0 and table.concat(obj.Value, ", ") or "None"
		else
			selectedLabel.Text = obj.Value ~= nil and tostring(obj.Value) or "None"
		end
		for option, button in pairs(optionButtons) do
			local selected = isSelected(option)
			button.BackgroundColor3 = Cloudy.Theme.SurfaceHover
			button.BackgroundTransparency = selected and 0 or 1
			button.TextColor3 = selected and Cloudy.Theme.Text or Cloudy.Theme.SubText
			local dot = button:FindFirstChild("Dot")
			if dot then
				dot.Visible = selected
			end
		end
	end
	table.insert(Cloudy._refreshers, render)

	local function listHeight()
		return math.min(#options * 30, 150)
	end

	local function setOpen(open)
		obj.Open = open
		local height = listHeight()
		listFrame.Size = UDim2.new(1, -16, 0, height)
		tween(card, 0.25, { Size = UDim2.new(1, 0, 0, open and (40 + height + 10) or 40) })
		tween(arrow, 0.25, { Rotation = open and -90 or 90 })
	end

	local function build()
		for _, button in pairs(optionButtons) do
			button:Destroy()
		end
		table.clear(optionButtons)
		for index, option in ipairs(options) do
			local button = create("TextButton", {
				Size = UDim2.new(1, -4, 0, 28),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = tostring(option),
				TextSize = 12,
				FontFace = Medium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = index,
				Parent = listFrame,
			}, { corner(6), create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
			optionButtons[option] = button
			create("Frame", {
				Name = "Dot",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 6, 0, 6),
				BorderSizePixel = 0,
				Visible = false,
				Theme = { BackgroundColor3 = "Accent" },
				Parent = button,
			}, { corner(3) })
			button.MouseButton1Click:Connect(function()
				if multi then
					local found = table.find(obj.Value, option)
					if found then
						table.remove(obj.Value, found)
					else
						table.insert(obj.Value, option)
					end
					render()
					changed(obj, opts.Callback, obj.Value)
				else
					obj.Value = option
					render()
					setOpen(false)
					changed(obj, opts.Callback, option)
				end
			end)
		end
		render()
	end
	build()

	function obj:Set(value, silent)
		if multi then
			self.Value = typeof(value) == "table" and table.clone(value) or { value }
		else
			self.Value = value
		end
		render()
		if silent then
			if self.Flag then
				Cloudy.Flags[self.Flag] = self.Value
			end
		else
			changed(self, opts.Callback, self.Value)
		end
	end

	function obj:Refresh(newOptions, keepSelection)
		options = table.clone(newOptions or {})
		if not keepSelection then
			self.Value = multi and {} or nil
		end
		build()
		if self.Open then
			setOpen(true)
		end
	end

	function obj:SetName(name)
		title.Text = name
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not obj.Open)
	end)

	return register(self, obj, card, opts.Name, opts.Flag)
end

-- Input --------------------------------------------------------------

function Elements:CreateInput(opts)
	opts = opts or {}
	local card, title = makeCard(self, opts.Name, opts.Description, "Frame")

	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0, 26),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Text = opts.Default ~= nil and tostring(opts.Default) or "",
		PlaceholderText = opts.Placeholder or "Type here…",
		TextSize = 12,
		FontFace = Regular,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClipsDescendants = true,
		Theme = {
			BackgroundColor3 = "Background",
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		},
		Parent = card,
	}, { corner(6), stroke("Border"), padding(0, 8) })

	focusRing(box)

	local obj = { Type = "Input", Value = box.Text }

	if opts.Numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = string.gsub(box.Text, "[^%d%.%-]", "")
			if clean ~= box.Text then
				box.Text = clean
			end
		end)
	end

	local function commit()
		local value = box.Text
		if opts.Numeric then
			value = tonumber(value) or 0
		end
		obj.Value = value
		changed(obj, opts.Callback, value)
	end

	box.FocusLost:Connect(function()
		commit()
		if opts.ClearOnSubmit then
			box.Text = ""
		end
	end)

	function obj:Set(value, silent)
		box.Text = tostring(value)
		self.Value = opts.Numeric and (tonumber(value) or 0) or tostring(value)
		if silent then
			if self.Flag then
				Cloudy.Flags[self.Flag] = self.Value
			end
		else
			changed(self, opts.Callback, self.Value)
		end
	end
	function obj:SetName(name)
		title.Text = name
	end

	return register(self, obj, card, opts.Name, opts.Flag)
end

-- Keybind ------------------------------------------------------------

function Elements:CreateKeybind(opts)
	opts = opts or {}
	local card, title = makeCard(self, opts.Name, opts.Description, "TextButton")
	hover(card, card, "Background", "Surface")

	local default = opts.Default
	if typeof(default) == "EnumItem" then
		default = default.Name
	end

	local keyLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		TextSize = 12,
		FontFace = Medium,
		Theme = { BackgroundColor3 = "Background", TextColor3 = "Text" },
		Parent = card,
	}, { corner(6), stroke("Border"), padding(0, 10) })

	local obj = { Type = "Keybind", Value = default or "None", Listening = false }

	local keyStroke = keyLabel:FindFirstChildOfClass("UIStroke")
	local function render()
		keyLabel.Text = obj.Listening and "…" or obj.Value
		tween(keyStroke, 0.2, { Color = obj.Listening and Cloudy.Theme.Accent or Cloudy.Theme.Border })
	end
	render()

	function obj:Set(value, silent)
		if typeof(value) == "EnumItem" then
			value = value.Name
		end
		self.Value = value or "None"
		render()
		if self.Flag then
			Cloudy.Flags[self.Flag] = self.Value
			if not silent then
				queueSave()
			end
		end
		if not silent then
			safeCall(opts.ChangedCallback, self.Value)
		end
	end
	function obj:SetName(name)
		title.Text = name
	end

	card.MouseButton1Click:Connect(function()
		obj.Listening = true
		render()
	end)

	track(UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if obj.Listening then
			obj.Listening = false
			if input.KeyCode == Enum.KeyCode.Escape then
				render()
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				obj:Set("None")
			else
				obj:Set(input.KeyCode.Name)
			end
			return
		end
		if processed or obj.Value == "None" or input.KeyCode.Name ~= obj.Value then
			return
		end
		if opts.Hold then
			safeCall(opts.Callback, true)
		else
			safeCall(opts.Callback)
		end
	end))

	if opts.Hold then
		track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == obj.Value then
				safeCall(opts.Callback, false)
			end
		end))
	end

	return register(self, obj, card, opts.Name, opts.Flag)
end

-- Color picker -------------------------------------------------------

function Elements:CreateColorPicker(opts)
	opts = opts or {}
	local card, title = makeCard(self, opts.Name, nil, "Frame")
	title.Size = UDim2.new(0.6, -12, 0, 40)

	local header = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		Parent = card,
	})
	local swatch = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0, 20),
		Size = UDim2.new(0, 34, 0, 20),
		BorderSizePixel = 0,
		Parent = card,
	}, { corner(6), stroke("Border") })

	local sv = create("Frame", {
		Position = UDim2.new(0, 12, 0, 44),
		Size = UDim2.new(1, -52, 0, 110),
		BorderSizePixel = 0,
		Parent = card,
	}, {
		corner(6),
		create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, {
			corner(6),
			create("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
		}),
		create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0, 0, 0),
		}, {
			corner(6),
			create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90 }),
		}),
	})
	local svCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = sv,
	}, {
		corner(5),
		create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(60, 60, 60) }),
	})

	local hueKeys = {}
	for i = 0, 6 do
		table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	local hue = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 44),
		Size = UDim2.new(0, 18, 0, 110),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = card,
	}, {
		corner(6),
		create("UIGradient", { Color = ColorSequence.new(hueKeys), Rotation = 90 }),
	})
	local hueCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = hue,
	}, {
		corner(2),
		create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(60, 60, 60) }),
	})

	local hexBox = create("TextBox", {
		Position = UDim2.new(0, 12, 0, 162),
		Size = UDim2.new(1, -24, 0, 26),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		PlaceholderText = "#FFFFFF",
		TextSize = 12,
		FontFace = Medium,
		Theme = {
			BackgroundColor3 = "Background",
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		},
		Parent = card,
	}, { corner(6), stroke("Border") })

	focusRing(hexBox)

	local default = opts.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = default:ToHSV()
	local obj = { Type = "ColorPicker", Value = default, Open = false }

	local function render()
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(0.5, 0, h, 0)
		swatch.BackgroundColor3 = obj.Value
		hexBox.Text = "#" .. string.upper(obj.Value:ToHex())
	end
	render()

	local function update()
		obj.Value = Color3.fromHSV(h, s, v)
		render()
		changed(obj, opts.Callback, obj.Value)
	end

	dragInput(sv, function(position)
		local size = sv.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		s = math.clamp((position.X - sv.AbsolutePosition.X) / size.X, 0, 1)
		v = 1 - math.clamp((position.Y - sv.AbsolutePosition.Y) / size.Y, 0, 1)
		update()
	end)
	dragInput(hue, function(position)
		local height = hue.AbsoluteSize.Y
		if height <= 0 then
			return
		end
		h = math.clamp((position.Y - hue.AbsolutePosition.Y) / height, 0, 1)
		update()
	end)

	hexBox.FocusLost:Connect(function()
		local ok, color = pcall(Color3.fromHex, hexBox.Text)
		if ok and color then
			obj:Set(color)
		else
			render()
		end
	end)

	function obj:Set(color, silent)
		if typeof(color) ~= "Color3" then
			return
		end
		h, s, v = color:ToHSV()
		self.Value = color
		render()
		if silent then
			if self.Flag then
				Cloudy.Flags[self.Flag] = color
			end
		else
			changed(self, opts.Callback, color)
		end
	end
	function obj:SetName(name)
		title.Text = name
	end

	header.MouseButton1Click:Connect(function()
		obj.Open = not obj.Open
		tween(card, 0.25, { Size = UDim2.new(1, 0, 0, obj.Open and 200 or 40) })
	end)

	return register(self, obj, card, opts.Name, opts.Flag)
end

-- Add* aliases (Tab:AddButton == Tab:CreateButton)
do
	local aliases = {}
	for name, fn in pairs(Elements) do
		if typeof(fn) == "function" and string.sub(name, 1, 6) == "Create" then
			aliases["Add" .. string.sub(name, 7)] = fn
		end
	end
	for name, fn in pairs(aliases) do
		Elements[name] = fn
	end
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

local Window = {}
Window.__index = Window

local TOPBAR = 46
local SIDEBAR = 160

function Cloudy:CreateWindow(opts)
	opts = opts or {}
	if opts.Theme then
		self:SetTheme(opts.Theme)
	end
	if opts.ConfigurationSaving then
		local cfg = opts.ConfigurationSaving
		self._config.Enabled = cfg.Enabled ~= false
		self._config.FolderName = cfg.FolderName or "CloudyUI"
		self._config.FileName = cfg.FileName or "config"
	end

	local size = opts.Size or Vector2.new(600, 420)
	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	if typeof(toggleKey) == "string" then
		toggleKey = Enum.KeyCode[toggleKey]
	end
	local showProfile = opts.ShowProfile ~= false

	local gui = create("ScreenGui", {
		Name = "CloudyUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
	})

	local root = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, size.X, 0, size.Y),
		Parent = gui,
	})
	local scale = create("UIScale", { Parent = root })

	-- Soft drop shadow built from stacked rounded frames (no image asset needed)
	local SHADOW_LAYERS = 10
	local shadowLayers = {}
	for i = 1, SHADOW_LAYERS do
		local spread = i * 2.5
		shadowLayers[i] = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 5),
			Size = UDim2.new(1, spread * 2, 1, spread * 2),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = root,
		}, { corner(14 + spread) })
	end
	local function renderShadow()
		local strength = 1 - (tonumber(Cloudy.Theme.Shadow) or 0.8)
		for _, layer in ipairs(shadowLayers) do
			layer.BackgroundTransparency = 1 - strength * 0.11
		end
	end
	renderShadow()
	table.insert(Cloudy._refreshers, renderShadow)

	local main = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Background" },
		Parent = root,
	}, {
		corner(14),
		stroke("Border"),
	})

	-- Top bar
	local topbar = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TOPBAR),
		Parent = main,
	})
	local titleRow = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -310, 1, 0),
		ClipsDescendants = true,
		Parent = topbar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})
	if opts.Logo ~= false then
		makeCloud(titleRow, 16, { LayoutOrder = 0 }, opts.Icon)
	end
	local titleLabel = text(opts.Name or "CloudyUI", 14, Bold, "Text", {
		Size = UDim2.new(0, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = 1,
		Parent = titleRow,
	})
	local subtitleLabel = text(opts.Subtitle or "", 12, Regular, "SubText", {
		Size = UDim2.new(0, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = 2,
		Parent = titleRow,
	})

	local function topButton(glyph, offset)
		local button = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0),
			Size = UDim2.new(0, 28, 0, 28),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = glyph,
			TextSize = 18,
			FontFace = Regular,
			Theme = { BackgroundColor3 = "Background", TextColor3 = "SubText" },
			Parent = topbar,
		}, { corner(8) })
		hover(button, button, "Background", "SurfaceHover")
		return button
	end
	local closeButton = topButton("×", -10)
	closeButton.MouseEnter:Connect(function()
		tween(closeButton, 0.15, { BackgroundColor3 = rgb(235, 87, 87), TextColor3 = rgb(255, 255, 255) })
	end)
	closeButton.MouseLeave:Connect(function()
		tween(closeButton, 0.15, { TextColor3 = Cloudy.Theme.SubText })
	end)
	local minimizeButton = topButton("–", -42)

	local searchBox = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -80, 0.5, 0),
		Size = UDim2.new(0, 150, 0, 28),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Text = "",
		PlaceholderText = "Search",
		TextSize = 12,
		FontFace = Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		Theme = {
			BackgroundColor3 = "Surface",
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		},
		Parent = topbar,
	}, { corner(8), stroke("Border"), padding(0, 10) })

	create("Frame", {
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, TOPBAR),
		Size = UDim2.new(1, 0, 0, 1),
		Theme = { BackgroundColor3 = "Border" },
		Parent = main,
	})

	-- Body
	local body = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, TOPBAR + 1),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 1)),
		ClipsDescendants = true,
		Parent = main,
	})
	local sidebar = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, SIDEBAR, 1, showProfile and -57 or 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = body,
	}, { padding(10), list(4) })
	create("Frame", {
		BorderSizePixel = 0,
		Position = UDim2.new(0, SIDEBAR, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Theme = { BackgroundColor3 = "Border" },
		Parent = body,
	})
	-- Player card at the bottom of the sidebar
	if showProfile then
		local player = Players.LocalPlayer
		local footer = create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(0, SIDEBAR, 0, 56),
			Parent = body,
		}, {
			create("Frame", {
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1),
				Theme = { BackgroundColor3 = "Border" },
			}),
		})
		local avatar = create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(0, 32, 0, 32),
			BorderSizePixel = 0,
			Theme = { BackgroundColor3 = "Surface" },
			Parent = footer,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke("Border") })
		text(player.DisplayName, 12, Medium, "Text", {
			Position = UDim2.new(0, 54, 0, 12),
			Size = UDim2.new(1, -62, 0, 16),
			Parent = footer,
		})
		text("@" .. player.Name, 11, Regular, "SubText", {
			Position = UDim2.new(0, 54, 0, 28),
			Size = UDim2.new(1, -62, 0, 14),
			Parent = footer,
		})
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end)
			if ok and image then
				avatar.Image = image
			end
		end)
	end

	local pages = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDEBAR + 1, 0, 0),
		Size = UDim2.new(1, -(SIDEBAR + 1), 1, 0),
		Parent = body,
	})

	-- Mobile "open" pill, shown while the window is hidden on touch devices
	local openPill = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0, 0, 0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "Open " .. (opts.Name or "CloudyUI"),
		TextSize = 12,
		FontFace = Medium,
		Visible = false,
		Theme = { BackgroundColor3 = "Background", TextColor3 = "Text" },
		Parent = gui,
	}, { corner(16), stroke("Border"), padding(0, 16) })

	local window = setmetatable({
		Gui = gui,
		Root = root,
		Main = main,
		Tabs = {},
		CurrentTab = nil,
		Visible = true,
		Minimized = false,
		ToggleKey = toggleKey,
		_sidebar = sidebar,
		_pages = pages,
		_size = size,
		_scale = scale,
		_openPill = openPill,
		_title = titleLabel,
		_subtitle = subtitleLabel,
		_search = searchBox,
	}, Window)

	-- Fit small screens
	local camera = workspace.CurrentCamera
	local function targetScale()
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		return math.min(1, viewport.X / (window._size.X + 24), viewport.Y / (window._size.Y + 24))
	end
	window._targetScale = targetScale
	if camera then
		track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			scale.Scale = targetScale()
		end))
	end

	-- Dragging
	do
		local dragging, dragStart, startPos = false, nil, nil
		topbar.InputBegan:Connect(function(input)
			if not isPress(input) then
				return
			end
			dragging = true
			dragStart = input.Position
			startPos = root.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
				end
			end)
		end)
		track(UserInputService.InputChanged:Connect(function(input)
			if dragging and isMove(input) then
				local delta = input.Position - dragStart
				root.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end))
	end

	-- Search
	local noResults = text("No results", 13, Regular, "SubText", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -40, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 5,
		Parent = pages,
	})
	function window:_applySearch()
		local query = string.lower(searchBox.Text)
		local shown = 0
		for _, tab in ipairs(self.Tabs) do
			for _, item in ipairs(tab._items) do
				local visible = not item.Hidden
					and (query == "" or string.find(item.Name, query, 1, true) ~= nil)
				item.Frame.Visible = visible
				if visible and tab == self.CurrentTab then
					shown += 1
				end
			end
		end
		noResults.Visible = query ~= "" and shown == 0
	end
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		window:_applySearch()
	end)

	local searchStroke = searchBox:FindFirstChildOfClass("UIStroke")
	searchBox.Focused:Connect(function()
		tween(searchBox, 0.25, { Size = UDim2.new(0, 190, 0, 28) })
		tween(searchStroke, 0.25, { Color = Cloudy.Theme.Accent })
	end)
	searchBox.FocusLost:Connect(function()
		tween(searchBox, 0.25, { Size = UDim2.new(0, 150, 0, 28) })
		tween(searchStroke, 0.25, { Color = Cloudy.Theme.Border })
	end)

	-- Buttons & toggle key
	minimizeButton.MouseButton1Click:Connect(function()
		window:SetMinimized(not window.Minimized)
	end)
	closeButton.MouseButton1Click:Connect(function()
		window:SetVisible(false)
		if window.ToggleKey and (not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled) then
			Cloudy:Notify({
				Title = "Interface hidden",
				Content = "Press " .. window.ToggleKey.Name .. " to show it again.",
				Duration = 4,
			})
		end
	end)
	openPill.MouseButton1Click:Connect(function()
		window:SetVisible(true)
	end)
	track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:SetVisible(not window.Visible)
		end
	end))

	table.insert(Cloudy._refreshers, function()
		window:_renderTabs()
	end)

	-- Resize grip (bottom-right corner)
	if opts.Resizable ~= false then
		local grip = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.new(0, 18, 0, 18),
			ZIndex = 30,
			Parent = main,
		})
		for _, offset in ipairs({ Vector2.new(11, 11), Vector2.new(6, 11), Vector2.new(11, 6) }) do
			create("Frame", {
				Position = UDim2.new(0, offset.X, 0, offset.Y),
				Size = UDim2.new(0, 2, 0, 2),
				BorderSizePixel = 0,
				ZIndex = 30,
				Theme = { BackgroundColor3 = "SubText" },
				Parent = grip,
			}, { corner(1) })
		end

		local resizing, startInput, startSize, startPos = false, nil, nil, nil
		grip.InputBegan:Connect(function(input)
			if not isPress(input) or window.Minimized then
				return
			end
			resizing = true
			startInput = input.Position
			startSize = window._size
			startPos = root.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
					conn:Disconnect()
				end
			end)
		end)
		track(UserInputService.InputChanged:Connect(function(input)
			if not (resizing and isMove(input)) then
				return
			end
			local delta = input.Position - startInput
			local factor = math.max(scale.Scale, 0.01)
			local width = math.clamp(startSize.X + delta.X / factor, 480, 1100)
			local height = math.clamp(startSize.Y + delta.Y / factor, 300, 800)
			window._size = Vector2.new(width, height)
			root.Size = UDim2.new(0, width, 0, height)
			-- the window is centre-anchored, so shift it to keep the top-left corner still
			root.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + (width - startSize.X) * factor / 2,
				startPos.Y.Scale,
				startPos.Y.Offset + (height - startSize.Y) * factor / 2
			)
		end))
	end

	-- Intro splash
	if opts.Intro ~= false then
		local splash = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 40,
			Theme = { BackgroundColor3 = "Background" },
			Parent = main,
		}, { corner(14) })
		local splashTitle = text(opts.Name or "CloudyUI", 22, Bold, "Text", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 22),
			Size = UDim2.new(1, -40, 0, 28),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTransparency = 1,
			ZIndex = 41,
			Parent = splash,
		})
		local splashSub = text(opts.IntroText or "Loading…", 13, Regular, "SubText", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 48),
			Size = UDim2.new(1, -40, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTransparency = 1,
			ZIndex = 41,
			Parent = splash,
		})
		local _, fadeCloud = makeCloud(splash, 60, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -32),
			ZIndex = 41,
		}, opts.Icon)
		fadeCloud(0, 1)
		task.spawn(function()
			fadeCloud(0.5, 0)
			tween(splashTitle, 0.4, { TextTransparency = 0 })
			tween(splashSub, 0.4, { TextTransparency = 0 })
			task.wait(1.1)
			fadeCloud(0.3, 1)
			tween(splashTitle, 0.3, { TextTransparency = 1 })
			tween(splashSub, 0.3, { TextTransparency = 1 })
			tween(splash, 0.45, { BackgroundTransparency = 1 })
			task.wait(0.45)
			splash:Destroy()
		end)
	end

	mountGui(gui)
	table.insert(Cloudy._windows, window)

	-- Intro animation
	local target = targetScale()
	scale.Scale = target * 0.92
	tween(scale, 0.45, { Scale = target }, Enum.EasingStyle.Back)

	return window
end

function Window:_renderTabs()
	for _, tab in ipairs(self.Tabs) do
		local selected = tab == self.CurrentTab
		tab._page.Visible = selected
		tween(tab._button, 0.2, {
			BackgroundTransparency = selected and 0 or 1,
			BackgroundColor3 = Cloudy.Theme.Surface,
		})
		tween(tab._label, 0.2, { TextColor3 = selected and Cloudy.Theme.Text or Cloudy.Theme.SubText })
		if tab._icon then
			tween(tab._icon, 0.2, { ImageColor3 = selected and Cloudy.Theme.Text or Cloudy.Theme.SubText })
		end
		tween(tab._indicator, 0.3, { Size = UDim2.new(0, 3, 0, selected and 16 or 0) })
	end
end

function Window:SelectTab(tab)
	local switched = self.CurrentTab ~= tab
	self.CurrentTab = tab
	self:_renderTabs()
	self:_applySearch()
	if switched then
		-- slide the new page up into place
		tab._page.Position = UDim2.new(0, 0, 0, 16)
		tween(tab._page, 0.4, { Position = UDim2.new(0, 0, 0, 0) })
	end
end

function Window:CreateTab(name, icon)
	if typeof(name) == "table" then
		icon = name.Icon
		name = name.Name
	end
	name = name or "Tab"

	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BackgroundColor3 = Cloudy.Theme.Surface,
		Text = "",
		LayoutOrder = #self.Tabs + 1,
		Parent = self._sidebar,
	}, { corner(8) })

	local iconLabel
	if icon then
		iconLabel = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Image = typeof(icon) == "number" and ("rbxassetid://" .. icon) or tostring(icon),
			ImageColor3 = Cloudy.Theme.SubText,
			Parent = button,
		})
	end
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, icon and 34 or 12, 0, 0),
		Size = UDim2.new(1, icon and -42 or -20, 1, 0),
		Text = name,
		TextSize = 13,
		FontFace = Medium,
		TextColor3 = Cloudy.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	local page = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Theme = { ScrollBarImageColor3 = "Track" },
		Parent = self._pages,
	}, { padding(14), list(8) })

	-- accent pill shown on the selected tab
	local indicator = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 0),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = button,
	}, { corner(2) })

	-- big page title
	text(name, 19, Bold, "Text", {
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 0,
		Parent = page,
	})

	local tab = setmetatable({
		Name = name,
		_holder = page,
		_page = page,
		_button = button,
		_label = label,
		_icon = iconLabel,
		_indicator = indicator,
		_window = self,
		_items = {},
		_order = 0,
	}, Elements)

	function tab:Select()
		self._window:SelectTab(self)
	end

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	button.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then
			tween(button, 0.15, { BackgroundTransparency = 0.5 })
			tween(label, 0.15, { TextColor3 = Cloudy.Theme.Text })
		end
	end)
	button.MouseLeave:Connect(function()
		self:_renderTabs()
	end)

	table.insert(self.Tabs, tab)
	if not self.CurrentTab then
		self.CurrentTab = tab
	end
	self:_renderTabs()
	return tab
end
Window.AddTab = Window.CreateTab

function Window:SetVisible(visible)
	self.Visible = visible
	self.Root.Visible = visible
	self._openPill.Visible = not visible and UserInputService.TouchEnabled
	if visible then
		local target = self._targetScale()
		self._scale.Scale = target * 0.95
		tween(self._scale, 0.3, { Scale = target }, Enum.EasingStyle.Back)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:SetMinimized(minimized)
	self.Minimized = minimized
	self._search.Visible = not minimized
	tween(self.Root, 0.35, {
		Size = UDim2.new(0, self._size.X, 0, minimized and TOPBAR or self._size.Y),
	})
end

function Window:SetToggleKey(key)
	if typeof(key) == "string" then
		local ok, code = pcall(function()
			return Enum.KeyCode[key]
		end)
		key = ok and code or nil
	end
	self.ToggleKey = key
end

function Window:SetTitle(title, subtitle)
	self._title.Text = title
	if subtitle then
		self._subtitle.Text = subtitle
	end
end

-- Modal dialog: Window:Dialog({ Title, Content, Buttons = { { Name, Callback, Primary } } })
function Window:Dialog(opts)
	opts = opts or {}
	local overlay = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = self.Main,
	}, { corner(12) })
	tween(overlay, 0.2, { BackgroundTransparency = 0.55 })

	local box = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 320, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ZIndex = 51,
		Theme = { BackgroundColor3 = "Background" },
		Parent = overlay,
	}, { corner(12), stroke("Border"), padding(16), list(8) })

	text(opts.Title or "Dialog", 15, Bold, "Text", {
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 1,
		ZIndex = 52,
		Parent = box,
	})
	text(opts.Content or "", 13, Regular, "SubText", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		ZIndex = 52,
		Parent = box,
	})
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 3,
		ZIndex = 52,
		Parent = box,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})

	local function close()
		overlay:Destroy()
	end

	local buttons = opts.Buttons or { { Name = "OK", Primary = true } }
	for index, info in ipairs(buttons) do
		local primary = info.Primary == true
		local button = create("TextButton", {
			Size = UDim2.new(0, 0, 0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = info.Name or "OK",
			TextSize = 13,
			FontFace = Medium,
			LayoutOrder = index,
			ZIndex = 53,
			Theme = {
				BackgroundColor3 = primary and "Accent" or "Surface",
				TextColor3 = primary and "AccentText" or "Text",
			},
			Parent = row,
		}, { corner(8), stroke(primary and "Accent" or "Border"), padding(0, 16) })
		button.MouseButton1Click:Connect(function()
			close()
			safeCall(info.Callback)
		end)
	end

	return { Close = close }
end

-- Ready-made settings tab: theme picker, toggle key, unload.
function Window:CreateSettingsTab(name)
	local tab = self:CreateTab(name or "Settings")
	local window = self

	local appearance = tab:CreateSection("Appearance")
	appearance:CreateDropdown({
		Name = "Theme",
		Options = Cloudy:GetThemes(),
		Default = Cloudy.ThemeName,
		Flag = "CloudyUI_Theme",
		Callback = function(theme)
			if theme then
				Cloudy:SetTheme(theme)
			end
		end,
	})

	local interface = tab:CreateSection("Interface")
	interface:CreateKeybind({
		Name = "Toggle interface",
		Default = self.ToggleKey and self.ToggleKey.Name or "None",
		Flag = "CloudyUI_ToggleKey",
		ChangedCallback = function(key)
			window:SetToggleKey(key)
		end,
	})
	interface:CreateButton({
		Name = "Unload interface",
		Variant = "Destructive",
		Callback = function()
			window:Dialog({
				Title = "Unload interface?",
				Content = "This removes the interface and disconnects everything it created.",
				Buttons = {
					{ Name = "Cancel" },
					{
						Name = "Unload",
						Primary = true,
						Callback = function()
							Cloudy:Destroy()
						end,
					},
				},
			})
		end,
	})
	return tab
end

function Window:Destroy()
	self.Gui:Destroy()
	local index = table.find(Cloudy._windows, self)
	if index then
		table.remove(Cloudy._windows, index)
	end
end

----------------------------------------------------------------------
-- Teardown
----------------------------------------------------------------------

function Cloudy:Destroy()
	for _, conn in ipairs(self._connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	for _, gui in ipairs(self._guis) do
		pcall(function()
			gui:Destroy()
		end)
	end
	table.clear(self._connections)
	table.clear(self._guis)
	table.clear(self._windows)
	table.clear(self._refreshers)
	table.clear(self.Flags)
	table.clear(self.Options)
	table.clear(bindings)
	notifyHolder = nil
	if cloudImage then
		pcall(function()
			cloudImage:Destroy()
		end)
	end
	cloudImage = nil
end

return Cloudy

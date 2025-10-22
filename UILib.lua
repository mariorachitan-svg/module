-- UILib.lua
-- Single-file UILib for Roblox (loadstring-ready)
-- Dark theme, Oswald Bold Italic
-- Usage:
-- local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/You/Repo/main/UILib.lua"))()
-- local win = UILib:CreateWindow("My Window")
-- local page = UILib:CreateTab(win, "Main")
-- UILib:CreateButton(page, "Click", function() print("clicked") end)

local UILib = {}
UILib.LibModules = {}
UILib.Labels = {}
UILib.Buttons = {}
UILib.Images = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui root
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UILibScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- helpers
local function applyCorner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = inst
	return c
end

local function trySetOswaldBoldItalic(inst)
	local ok, face = pcall(function()
		return Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	end)
	if ok and face then
		inst.FontFace = face
	else
		-- fallback
		pcall(function() inst.Font = Enum.Font.Oswald end)
	end
end

local function hoverTextGrow(guiObj, amount)
	if not guiObj:IsA("TextLabel") and not guiObj:IsA("TextButton") then return end
	amount = amount or 3
	local original = guiObj.TextSize or 18
	local enterTween, leaveTween

	guiObj.MouseEnter:Connect(function()
		if enterTween then pcall(function() enterTween:Cancel() end) end
		enterTween = TweenService:Create(guiObj, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {TextSize = original + amount})
		enterTween:Play()
		pcall(function() if guiObj.BackgroundTransparency < 1 then guiObj.BackgroundColor3 = Color3.fromRGB(90,90,90) end end)
	end)
	guiObj.MouseLeave:Connect(function()
		if leaveTween then pcall(function() leaveTween:Cancel() end) end
		leaveTween = TweenService:Create(guiObj, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {TextSize = original})
		leaveTween:Play()
		pcall(function() if guiObj.BackgroundTransparency < 1 then guiObj.BackgroundColor3 = Color3.fromRGB(60,60,60) end end)
	end)
end

local function makeLabel(parent, text, size)
	local lbl = Instance.new("TextLabel")
	lbl.Size = size or UDim2.new(1, 0, 0, 28)
	lbl.BackgroundColor3 = Color3.fromRGB(60,60,60)
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.Text = text or ""
	lbl.TextSize = 16
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 0
	trySetOswaldBoldItalic(lbl)
	applyCorner(lbl, 8)
	lbl.Parent = parent
	hoverTextGrow(lbl, 2)
	table.insert(UILib.Labels, lbl)
	return lbl
end

local function makeButton(parent, text, callback, size)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(0, 200, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Text = text or "Button"
	btn.TextSize = 18
	btn.AutoButtonColor = false
	btn.TextWrapped = false
	trySetOswaldBoldItalic(btn)
	applyCorner(btn, 8)
	btn.Parent = parent
	hoverTextGrow(btn, 3)
	table.insert(UILib.Buttons, btn)

	if callback then
		btn.MouseButton1Click:Connect(function()
			pcall(callback)
		end)
	end
	return btn
end

-- Window drag helper
local function makeDraggable(frame, titleBar)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	if not titleBar then titleBar = frame end

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input)
		end
	end)
end

-- API: CreateWindow(title, w, h) -> wrapper {Window, TitleLabel, TabsBar, ContentArea, CreateTabFunc}
function UILib:CreateWindow(title, w, h)
	local W = w or 520
	local H = h or 360

	local window = Instance.new("Frame")
	window.Name = title and tostring(title) or "Window"
	window.Size = UDim2.new(0, W, 0, H)
	window.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
	window.BackgroundColor3 = Color3.fromRGB(36,36,36)
	applyCorner(window, 12)
	window.Parent = screenGui

	-- titlebar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = window

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -12, 1, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Window"
	titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	trySetOswaldBoldItalic(titleLabel)
	titleLabel.Parent = titleBar

	-- tabs bar (buttons)
	local tabsBar = Instance.new("Frame")
	tabsBar.Size = UDim2.new(1, -12, 0, 36)
	tabsBar.Position = UDim2.new(0, 6, 0, 42)
	tabsBar.BackgroundTransparency = 1
	tabsBar.Parent = window

	-- content area (holds pages)
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -12, 1, -92)
	contentArea.Position = UDim2.new(0, 6, 0, 84)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = window

	-- internal tabs table
	local tabs = {}
	local activePage = nil

	local function CreateTabFunc(tabName)
		local idx = #tabs + 1
		local btn = makeButton(tabsBar, tabName, nil, UDim2.new(0, 120, 0, 30))
		btn.Position = UDim2.new(0, 6 + (idx-1) * 126, 0, 3)
		btn.Parent = tabsBar

		local page = Instance.new("Frame")
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = contentArea

		btn.MouseButton1Click:Connect(function()
			if activePage then activePage.Visible = false end
			page.Visible = true
			activePage = page
		end)

		if not activePage then
			page.Visible = true
			activePage = page
		end

		tabs[tabName] = {Button = btn, Page = page}
		return page
	end

	-- make window draggable by titlebar
	makeDraggable(window, titleBar)

	local wrapper = {
		Window = window,
		TitleLabel = titleLabel,
		TabsBar = tabsBar,
		Content = contentArea,
		CreateTab = CreateTabFunc,
		_GetTabsInternal = tabs, -- internal, accessible if needed
		_ActivePage = function() return activePage end
	}
	return wrapper
end

-- CreateNotification({Name, Duration, Title, Description})
function UILib:CreateNotification(data)
	data = data or {}
	local dur = data.Duration or 3
	local name = data.Name or ("Notification_" .. tostring(math.random(1000,9999)))

	-- container frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 340, 0, 96)
	frame.AnchorPoint = Vector2.new(1, 1)
	-- Position it in lower-right; stack a bit by counting existing notifications
	local existingCount = 0
	for _, child in pairs(screenGui:GetChildren()) do
		if child.Name:match("^Notification_") then existingCount = existingCount + 1 end
	end
	frame.Position = UDim2.new(1, -12, 1, -12 - (existingCount * 100))
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	applyCorner(frame, 10)
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.new(0, 8, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = data.Title or "Notification"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	trySetOswaldBoldItalic(title)
	title.Parent = frame

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -16, 0, 54)
	desc.Position = UDim2.new(0, 8, 0, 36)
	desc.BackgroundTransparency = 1
	desc.Text = data.Description or ""
	desc.TextColor3 = Color3.fromRGB(200,200,200)
	desc.TextWrapped = true
	desc.TextSize = 15
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = frame

	-- slide in then out
	local targetPos = frame.Position
	frame.Position = UDim2.new(1, 400, targetPos.Y.Scale, targetPos.Y.Offset)
	TweenService:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Position = targetPos}):Play()

	delay(dur, function()
		if frame and frame.Parent then
			TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 400, targetPos.Y.Scale, targetPos.Y.Offset)}):Play()
			wait(0.24)
			pcall(function() frame:Destroy() end)
		end
	end)
end

-- CreateLabel(parentOrPage, text, size)
function UILib:CreateLabel(parent, text, size)
	parent = parent or screenGui
	-- if user passed a window wrapper, use Content
	if type(parent) == "table" and parent.Content then parent = parent.Content end
	-- if user passed a page (Frame) use it directly
	return makeLabel(parent, text, size)
end

-- CreateButton(parentOrPage, text, callback)
function UILib:CreateButton(parent, text, callback, size)
	parent = parent or screenGui
	if type(parent) == "table" and parent.Content then parent = parent.Content end
	return makeButton(parent, text, callback, size)
end

-- CreateList(name, width, height) -> {Frame, Content}
function UILib:CreateList(name, width, height)
	local w = width or 240
	local h = height or 220
	local frame = Instance.new("Frame")
	frame.Name = name or "List"
	frame.Size = UDim2.new(0, w, 0, h)
	frame.BackgroundColor3 = Color3.fromRGB(34,34,34)
	applyCorner(frame, 10)
	frame.Parent = screenGui

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -12, 1, -12)
	content.Position = UDim2.new(0, 6, 0, 6)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 6
	content.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Parent = content
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
	end)

	return {Frame = frame, Content = content}
end

-- Selection(listWrapper, dataTable) where dataTable = { ["Label"] = {Function = fn}, ... }
function UILib:Selection(listWrapper, dataTable)
	if not listWrapper or type(dataTable) ~= "table" then return end
	local content = listWrapper.Content or listWrapper
	for text, info in pairs(dataTable) do
		local fn = (type(info) == "table" and info.Function) or (type(info) == "function" and info) or nil
		local btn = self:CreateButton(content, tostring(text), fn, UDim2.new(1, -8, 0, 34))
		btn.Size = UDim2.new(1, -8, 0, 34)
		btn.Parent = content
	end
end

-- LibModules.OnlyModule: bind a frame, a list, and the window tabs bar to allow movement/switching
do
	local only = {}
	only._frame = nil
	only._listWrapper = nil
	only._windowWrapper = nil

	function only:BindFrame(frame)
		self._frame = frame
	end
	function only:BindList(listWrapper)
		self._listWrapper = listWrapper
	end
	function only:BindWindow(windowWrapper)
		self._windowWrapper = windowWrapper
	end

	function only:MoveToList(targetList)
		if not self._frame then return end
		local destination = nil
		if targetList and type(targetList) == "table" then
			destination = targetList.Content or targetList
		elseif self._listWrapper then
			destination = self._listWrapper.Content
		end
		if destination then
			self._frame.Parent = destination
			-- ensure layout updates
			pcall(function()
				local layout = destination:FindFirstChildOfClass("UIListLayout")
				if layout then
					layout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait()
				end
			end)
		end
	end

	function only:SwitchMenu()
		-- toggle the window's tabs bar (menu == tabs bar)
		if not self._windowWrapper then return end
		local bar = self._windowWrapper.TabsBar
		if bar then bar.Visible = not bar.Visible end
	end

	function only:SwitchList()
		if not self._listWrapper then return end
		local frame = self._listWrapper.Frame
		if frame then frame.Visible = not frame.Visible end
	end

	UILib.LibModules.OnlyModule = only
end

-- AddImage(parentOrPage, params)
-- params: { id = "rbxassetid://...", BGTransparency = 0, ITransparency = 0 }
function UILib:AddImage(parent, params)
	parent = parent or screenGui
	if type(parent) == "table" and parent.Content then parent = parent.Content end
	params = params or {}
	local id = params.id or params[1] or ""
	local bgT = params.BGTransparency or params.BG or 0
	local iT = params.ITransparency or params.I or 0

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 140, 0, 96)
	frame.BackgroundTransparency = bgT
	frame.Parent = parent
	applyCorner(frame, 8)

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1, -8, 1, -8)
	img.Position = UDim2.new(0, 4, 0, 4)
	img.BackgroundTransparency = 1
	img.Image = id
	img.ImageTransparency = iT
	img.Parent = frame
	table.insert(UILib.Images, img)
	return frame, img
end

-- AddImageButton(parent, params, callback)
function UILib:AddImageButton(parent, params, callback)
	parent = parent or screenGui
	if type(parent) == "table" and parent.Content then parent = parent.Content end
	params = params or {}
	local id = params.id or params[1] or ""
	local bgT = params.BGTransparency or params.BG or 0
	local iT = params.ITransparency or params.I or 0

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 140, 0, 96)
	frame.BackgroundTransparency = bgT
	frame.Parent = parent
	applyCorner(frame, 8)

	local btn = Instance.new("ImageButton")
	btn.Size = UDim2.new(1, -8, 1, -8)
	btn.Position = UDim2.new(0, 4, 0, 4)
	btn.BackgroundTransparency = 1
	btn.Image = id
	btn.ImageTransparency = iT
	btn.AutoButtonColor = false
	btn.Parent = frame
	table.insert(UILib.Images, btn)

	btn.MouseEnter:Connect(function()
		pcall(function() btn.ImageTransparency = math.max(0, btn.ImageTransparency - 0.08) end)
	end)
	btn.MouseLeave:Connect(function()
		pcall(function() btn.ImageTransparency = math.min(1, btn.ImageTransparency + 0.08) end)
	end)
	if callback then
		btn.MouseButton1Click:Connect(function() pcall(callback) end)
	end
	return frame, btn
end

-- AddToggle(parentOrPage, labeltext, default, callback)
function UILib:AddToggle(parent, labeltext, default, callback)
	parent = parent or screenGui
	if type(parent) == "table" and parent.Content then parent = parent.Content end
	default = default == true
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -8, 0, 34)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.7, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labeltext or "Toggle"
	lbl.TextSize = 16
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	trySetOswaldBoldItalic(lbl)
	lbl.Parent = container

	local tbtn = Instance.new("TextButton")
	tbtn.Size = UDim2.new(0, 60, 0, 26)
	tbtn.Position = UDim2.new(1, -66, 0.5, -13)
	tbtn.BackgroundColor3 = default and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,80)
	tbtn.Text = ""
	applyCorner(tbtn, 8)
	tbtn.Parent = container

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 18, 0, 18)
	circle.Position = default and UDim2.new(1, -18, 0.5, -9) or UDim2.new(0, 6, 0.5, -9)
	circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
	applyCorner(circle, 9)
	circle.Parent = tbtn

	local toggled = default
	local function setState(state, noCallback)
		toggled = not not state
		tbtn.BackgroundColor3 = toggled and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,80)
		local target = toggled and UDim2.new(1, -18, 0.5, -9) or UDim2.new(0, 6, 0.5, -9)
		TweenService:Create(circle, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Position = target}):Play()
		if callback and not noCallback then pcall(function() callback(toggled) end) end
	end

	tbtn.MouseButton1Click:Connect(function() setState(not toggled) end)
	return {Container = container, Set = setState, Get = function() return toggled end}
end

-- AddSlider(parentOrPage, labeltext, min, max, default, callback)
function UILib:AddSlider(parent, labeltext, min, max, default, callback)
	parent = parent or screenGui
	if type(parent) == "table" and parent.Content then parent = parent.Content end
	min = min or 0
	max = max or 100
	default = default or min

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -8, 0, 56)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = labeltext or "Slider"
	lbl.TextSize = 16
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	trySetOswaldBoldItalic(lbl)
	lbl.Parent = container

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 18)
	barBg.Position = UDim2.new(0, 0, 0, 28)
	barBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
	applyCorner(barBg, 8)
	barBg.Parent = container

	local fill = Instance.new("Frame")
	local rel = 0
	if max - min ~= 0 then rel = math.clamp((default - min) / (max - min), 0, 1) end
	fill.Size = UDim2.new(rel, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(120,160,240)
	applyCorner(fill, 8)
	fill.Parent = barBg

	local dragging = false
	local function updateFromInput(input)
		local relx = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(relx, 0, 1, 0)
		local value = min + relx * (max - min)
		if callback then pcall(function() callback(value) end) end
	end

	barBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromInput(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromInput(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	return {Container = container, Set = function(v)
		local r = math.clamp((v - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(r, 0, 1, 0)
	end}
end

-- quick accessors
function UILib:GetLabels() return UILib.Labels end
function UILib:GetButtons() return UILib.Buttons end
function UILib:GetImages() return UILib.Images end

-- Starter key system
UILib.UseKey = false       -- enable/disable
UILib.KeyLink = ""         -- could be URL or store
UILib.Key = ""             -- the correct key

if UILib.UseKey then
    -- simple key GUI
    local keyWin = UILib:CreateWindow("Enter Key", 300, 120)
    local page = UILib:CreateTab(keyWin, "Key")
    
    UILib:CreateLabel(page, "Please enter your key:")
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -12, 0, 28)
    textBox.Position = UDim2.new(0, 6, 0, 32)
    textBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    textBox.TextColor3 = Color3.fromRGB(255,255,255)
    textBox.ClearTextOnFocus = false
    trySetOswaldBoldItalic(textBox)
    applyCorner(textBox, 8)
    textBox.Parent = page

    UILib:CreateButton(page, "Submit", function()
        if textBox.Text == UILib.Key then
            keyWin.Window:Destroy()
            UILib:CreateNotification({
                Title = "Success",
                Description = "Correct key entered!",
                Duration = 2
            })
        else
            UILib:CreateNotification({
                Title = "Error",
                Description = "Incorrect key, try again!",
                Duration = 2
            })
        end
    end)
end


-- return lib for loadstring
return UILib


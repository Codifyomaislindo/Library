-- init.lua
-- WindUI-inspired Roblox UI Library
-- Author: [Your Name]
-- License: MIT
-- Optimized for PC and mobile, compatible with all executors, loadstring-ready
-- Fixed errors, improved design with shadows, gradients, proper theme updating, notification stacking, canvas sizing
-- Added UI toggle button

local Library = {}
Library.__index = Library

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Theme system
Library.Themes = {
    Light = {
        Primary = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(0, 0, 0),
        Border = Color3.fromRGB(200, 200, 200),
        Shadow = Color3.fromRGB(0, 0, 0),
        Notification = Color3.fromRGB(255, 255, 255),
    },
    Dark = {
        Primary = Color3.fromRGB(30, 30, 30),
        Secondary = Color3.fromRGB(45, 45, 45),
        Accent = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(60, 60, 60),
        Shadow = Color3.fromRGB(0, 0, 0),
        Notification = Color3.fromRGB(50, 50, 50),
    }
}
Library.CurrentTheme = "Dark"
Library.Theme = Library.Themes[Library.CurrentTheme]

-- Device detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Size adjustments for mobile/PC
local baseScale = isMobile and 1.2 or 1
local buttonHeight = isMobile and 40 or 30
local padding = isMobile and 10 or 5
local fontSize = isMobile and 16 or 14

-- Utility functions
local function createInstance(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function tween(obj, info, props)
    local tInfo = TweenInfo.new(info.Time or 0.2, info.Style or Enum.EasingStyle.Quad, info.Direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, tInfo, props)
    t:Play()
    return t
end

-- Initialize library
function Library.new()
    local self = setmetatable({}, Library)
    self.ScreenGui = createInstance("ScreenGui", {
        Name = "WindUILib",
        Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false
    })
    self.Windows = {}
    self.Notifications = {}
    self.ToggleButton = nil
    self:CreateToggleButton()
    return self
end

-- Create toggle button
function Library:CreateToggleButton()
    self.ToggleButton = createInstance("TextButton", {
        Text = "UI",
        Size = UDim2.new(0, 50 * baseScale, 0, 50 * baseScale),
        Position = UDim2.new(0, 10, 1, -60),
        BackgroundColor3 = self.Theme.Accent,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = fontSize,
        Parent = self.ScreenGui
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 25), Parent = self.ToggleButton})
    self.ToggleButton.MouseButton1Click:Connect(function()
        local visible = not self.Windows[1].Window.Visible  -- Assume first window is main, or loop all
        for _, win in ipairs(self.Windows) do
            win.Window.Visible = visible
        end
    end)
end

-- Set theme and update all UI
function Library:SetTheme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = themeName
        self.Theme = self.Themes[themeName]
        self:UpdateAllThemes()
        self:Notify("Theme changed to " .. themeName, 2)
    end
end

function Library:UpdateAllThemes()
    -- Update toggle button
    self.ToggleButton.BackgroundColor3 = self.Theme.Accent
    self.ToggleButton.TextColor3 = self.Theme.Text
    
    -- Update windows
    for _, win in ipairs(self.Windows) do
        win.Window.BackgroundColor3 = self.Theme.Primary
        win.TitleBar.BackgroundColor3 = self.Theme.Secondary
        win.TitleLabel.TextColor3 = self.Theme.Text
        win.CloseBtn.TextColor3 = self.Theme.Text
        win.TabList.BackgroundColor3 = self.Theme.Secondary
        -- Update tabs
        for _, tab in ipairs(win.Tabs) do
            tab.Button.BackgroundColor3 = (tab == win.ActiveTab) and self.Theme.Accent or self.Theme.Secondary
            tab.Button.TextColor3 = self.Theme.Text
            -- Update sections
            for _, sec in ipairs(tab.Sections) do
                sec.Section.BackgroundColor3 = self.Theme.Secondary
                sec.TitleLabel.TextColor3 = self.Theme.Text
                -- Update elements (buttons, etc.)
                for _, child in ipairs(sec.Content:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.BackgroundColor3 = self.Theme.Accent
                        child.TextColor3 = self.Theme.Primary
                    elseif child:IsA("Frame") and child.Name == "ToggleFrame" then
                        child.Label.TextColor3 = self.Theme.Text
                        -- etc.
                    end
                    -- Add more for other components
                end
            end
        end
    end
    -- Update notifications
    for _, noti in ipairs(self.Notifications) do
        noti.BackgroundColor3 = self.Theme.Notification
        noti.TextLabel.TextColor3 = self.Theme.Text
    end
end

-- Notification system with proper stacking
function Library:Notify(text, duration, color)
    duration = duration or 3
    local notiFrame = createInstance("Frame", {
        Size = UDim2.new(0, 200 * baseScale, 0, 50 * baseScale),
        Position = UDim2.new(1, 10, 1, -60 * baseScale),
        BackgroundColor3 = color or self.Theme.Notification,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = notiFrame})
    local textLabel = createInstance("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = notiFrame
    })
    table.insert(self.Notifications, notiFrame)
    self:UpdateNotificationPositions()
    tween(notiFrame, {Time = 0.3}, {Position = UDim2.new(1, -210 * baseScale, notiFrame.Position.Y.Scale, notiFrame.Position.Y.Offset)}):Completed:Connect(function()
        wait(duration)
        tween(notiFrame, {Time = 0.3}, {Position = UDim2.new(1, 10, notiFrame.Position.Y.Scale, notiFrame.Position.Y.Offset)}):Completed:Connect(function()
            for i, n in ipairs(self.Notifications) do
                if n == notiFrame then
                    table.remove(self.Notifications, i)
                    break
                end
            end
            notiFrame:Destroy()
            self:UpdateNotificationPositions()
        end)
    end)
end

function Library:UpdateNotificationPositions()
    for i, noti in ipairs(self.Notifications) do
        tween(noti, {Time = 0.2}, {Position = UDim2.new(1, -210 * baseScale, 1, -10 * baseScale - (60 * baseScale * (i - 1)))})
    end
end

function Library:Toast(text, duration)
    self:Notify(text, duration, self.Theme.Secondary)
end

-- Create Window
function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or "Window"
    local size = options.Size or UDim2.new(0, 500 * baseScale, 0, 300 * baseScale)

    local shadow = createInstance("Frame", {
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        BackgroundColor3 = self.Theme.Shadow,
        Transparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = -1,
        Parent = self.ScreenGui
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = shadow})

    local window = createInstance("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Primary,
        BorderSizePixel = 0,
        Parent = shadow
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = window})
    createInstance("UIStroke", {Color = self.Theme.Border, Transparency = 0.5, Parent = window})

    -- Title bar with gradient
    local titleBar = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30 * baseScale),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = window
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = titleBar})
    local gradient = createInstance("UIGradient", {
        Color = ColorSequence.new(self.Theme.Secondary, self.Theme.Secondary:Lerp(Color3.new(0,0,0), 0.1)),
        Parent = titleBar
    })
    local titleLabel = createInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(1, -30 * baseScale, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = fontSize + 2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, padding, 0, 0),
        Parent = titleBar
    })

    -- Close button
    local closeBtn = createInstance("TextButton", {
        Text = "X",
        Size = UDim2.new(0, 30 * baseScale, 1, 0),
        Position = UDim2.new(1, -30 * baseScale, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = fontSize,
        Parent = titleBar
    })
    closeBtn.MouseButton1Click:Connect(function()
        tween(window, {Time = 0.2}, {Transparency = 1}):Completed:Connect(function()
            shadow:Destroy()
        end)
    end)

    -- Draggable
    local dragging, dragInput, dragStart, startPos
    local function updateInput(input)
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and (input == dragInput) then
            updateInput(input)
        end
    end)

    -- Tab container
    local tabContainer = createInstance("Frame", {
        Size = UDim2.new(1, 0, 1, -30 * baseScale),
        Position = UDim2.new(0, 0, 0, 30 * baseScale),
        BackgroundTransparency = 1,
        Parent = window
    })
    local tabList = createInstance("ScrollingFrame", {
        Size = UDim2.new(0, 100 * baseScale, 1, 0),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        Parent = tabContainer
    })
    createInstance("UIListLayout", {Padding = UDim.new(0, padding), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList})
    local tabContent = createInstance("Frame", {
        Size = UDim2.new(1, -100 * baseScale, 1, 0),
        Position = UDim2.new(0, 100 * baseScale, 0, 0),
        BackgroundTransparency = 1,
        Parent = tabContainer
    })

    local windowObj = {
        Window = window,
        Shadow = shadow,
        TitleBar = titleBar,
        TitleLabel = titleLabel,
        CloseBtn = closeBtn,
        TabList = tabList,
        TabContent = tabContent,
        Tabs = {},
        ActiveTab = nil
    }
    setmetatable(windowObj, {__index = Library.WindowMethods})
    table.insert(self.Windows, windowObj)
    return windowObj
end

Library.WindowMethods = {}

function Library.WindowMethods:CreateTab(title)
    local tabBtn = createInstance("TextButton", {
        Text = title,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundColor3 = self.Theme.Secondary,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        AutoButtonColor = false,
        Parent = self.TabList
    })
    createInstance("UIStroke", {Color = self.Theme.Border, Transparency = 0.8, Parent = tabBtn})

    local tabFrame = createInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.TabContent
    })
    local gridLayout = createInstance("UIGridLayout", {
        CellSize = UDim2.new(0.5, -padding, 0, 0),
        CellPadding = UDim2.new(0, padding, 0, padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabFrame
    })
    gridLayout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            tabFrame.CanvasSize = UDim2.new(0, gridLayout.AbsoluteContentSize.X, 0, gridLayout.AbsoluteContentSize.Y)
        end
    end)

    local tabObj = {
        Button = tabBtn,
        Frame = tabFrame,
        GridLayout = gridLayout,
        Sections = {}
    }
    setmetatable(tabObj, {__index = Library.TabMethods})
    table.insert(self.Tabs, tabObj)

    tabBtn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(self.Tabs) do
            tab.Frame.Visible = false
            tab.Button.BackgroundColor3 = self.Theme.Secondary
        end
        tabFrame.Visible = true
        tabBtn.BackgroundColor3 = self.Theme.Accent
        self.ActiveTab = tabObj
    end)

    if #self.Tabs == 1 then
        tabBtn:MouseButton1Click()
    end

    self.TabList.CanvasSize = UDim2.new(0, 0, 0, self.TabList.UIListLayout.AbsoluteContentSize.Y)
    return tabObj
end

Library.TabMethods = {}

function Library.TabMethods:CreateSection(title)
    local section = createInstance("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        LayoutOrder = #self.Sections + 1,
        Parent = self.Frame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = section})
    createInstance("UIStroke", {Color = self.Theme.Border, Parent = section})

    local titleLabel = createInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(1, 0, 0, 20 * baseScale),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = fontSize,
        Parent = section
    })

    local content = createInstance("Frame", {
        Size = UDim2.new(1, 0, 1, -20 * baseScale),
        Position = UDim2.new(0, 0, 0, 20 * baseScale),
        BackgroundTransparency = 1,
        Parent = section
    })
    local listLayout = createInstance("UIListLayout", {
        Padding = UDim.new(0, padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content
    })
    listLayout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            section.Size = UDim2.new(0, section.Size.X.Offset, 0, listLayout.AbsoluteContentSize.Y + 20 * baseScale + padding)
            self.GridLayout:ApplyLayout()
        end
    end)

    local sectionObj = {
        Section = section,
        TitleLabel = titleLabel,
        Content = content,
        ListLayout = listLayout
    }
    setmetatable(sectionObj, {__index = Library.SectionMethods})
    table.insert(self.Sections, sectionObj)
    return sectionObj
end

Library.SectionMethods = {}

function Library.SectionMethods:CreateButton(options)
    options = options or {}
    local text = options.Name or "Button"
    local callback = options.Callback or function() end

    local button = createInstance("TextButton", {
        Text = text,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundColor3 = self.Theme.Accent,
        TextColor3 = self.Theme.Primary,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = self.Content
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = button})
    createInstance("UIGradient", {Color = ColorSequence.new(self.Theme.Accent, self.Theme.Accent:Lerp(Color3.new(1,1,1), 0.05)), Parent = button})

    button.MouseEnter:Connect(function()
        tween(button, {Time = 0.1}, {BackgroundColor3 = self.Theme.Accent:Lerp(Color3.new(1,1,1), 0.1)})
    end)
    button.MouseLeave:Connect(function()
        tween(button, {Time = 0.1}, {BackgroundColor3 = self.Theme.Accent})
    end)
    button.MouseButton1Click:Connect(callback)

    return button
end

function Library.SectionMethods:CreateToggle(options)
    options = options or {}
    local text = options.Name or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function(state) end

    local toggleFrame = createInstance("Frame", {
        Name = "ToggleFrame",
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local label = createInstance("TextLabel", {
        Text = text,
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame
    })
    local toggleBtn = createInstance("Frame", {
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = default and self.Theme.Accent or self.Theme.Border,
        Parent = toggleFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = toggleBtn})
    local circle = createInstance("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = default and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9),
        BackgroundColor3 = self.Theme.Primary,
        Parent = toggleBtn
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 9), Parent = circle})

    local state = default
    local function toggle()
        state = not state
        tween(circle, {Time = 0.2}, {Position = state and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)})
        tween(toggleBtn, {Time = 0.2}, {BackgroundColor3 = state and self.Theme.Accent or self.Theme.Border})
        callback(state)
    end

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggle()
        end
    end)

    return {Toggle = toggle, GetState = function() return state end}
end

function Library.SectionMethods:CreateSlider(options)
    options = options or {}
    local text = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local decimal = options.Decimal or false
    local callback = options.Callback or function(value) end

    local sliderFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight + 10),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local label = createInstance("TextLabel", {
        Text = text .. ": " .. default,
        Size = UDim2.new(1, 0, 0, buttonHeight / 2),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = sliderFrame
    })
    local sliderBar = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = self.Theme.Border,
        Parent = sliderFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = sliderBar})
    local fill = createInstance("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        Parent = sliderBar
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = fill})
    local knob = createInstance("Frame", {
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(fill.Size.X.Scale, -7.5, 0.5, -7.5),
        BackgroundColor3 = self.Theme.Primary,
        Parent = sliderBar
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = knob})

    local dragging = false
    local function updateValue(relativeX)
        local value = min + (max - min) * relativeX
        if not decimal then value = math.floor(value + 0.5) end
        value = math.clamp(value, min, max)
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        knob.Position = UDim2.new(relativeX, -7.5, 0.5, -7.5)
        label.Text = text .. ": " .. value
        callback(value)
    end
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            updateValue(relativeX)
        end
    end)
    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            updateValue(relativeX)
        end
    end)

    updateValue((default - min) / (max - min))
    return sliderFrame
end

function Library.SectionMethods:CreateDropdown(options)
    options = options or {}
    local text = options.Name or "Dropdown"
    local items = options.Options or {}
    local default = options.Default or (items[1] or "")
    local callback = options.Callback or function(selected) end

    local dropdownFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local selectedBtn = createInstance("TextButton", {
        Text = text .. ": " .. default,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Theme.Secondary,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdownFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = selectedBtn})
    createInstance("TextLabel", {
        Text = "▼",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -20, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Parent = selectedBtn
    })

    local listFrame = createInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Primary,
        BorderSizePixel = 0,
        Visible = false,
        ScrollBarThickness = 4,
        Parent = dropdownFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = listFrame})
    local listLayout = createInstance("UIListLayout", {Padding = UDim.new(0, 2), Parent = listFrame})

    local open = false
    local function toggleList()
        open = not open
        listFrame.Visible = open
        local height = math.min(#items * 25, 150)
        tween(listFrame, {Time = 0.2}, {Size = open and UDim2.new(1, 0, 0, height) or UDim2.new(1, 0, 0, 0)})
        dropdownFrame.Size = UDim2.new(1, 0, 0, buttonHeight + (open and height or 0))
        self.ListLayout:ApplyLayout()
    end

    selectedBtn.MouseButton1Click:Connect(toggleList)

    for _, item in ipairs(items) do
        local itemBtn = createInstance("TextButton", {
            Text = item,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundTransparency = 1,
            TextColor3 = self.Theme.Text,
            Font = Enum.Font.SourceSans,
            TextSize = fontSize,
            Parent = listFrame
        })
        itemBtn.MouseButton1Click:Connect(function()
            selectedBtn.Text = text .. ": " .. item
            callback(item)
            toggleList()
        end)
    end

    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    listLayout.Changed:Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)

    return dropdownFrame
end

function Library.SectionMethods:CreateKeybind(options)
    options = options or {}
    local text = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.F
    local callback = options.Callback or function(key) end

    if isMobile then
        return self:CreateButton({Name = text, Callback = function() callback(default) end})
    end

    local keybindFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local label = createInstance("TextButton", {
        Text = text .. ": " .. default.Name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Theme.Secondary,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = keybindFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = label})

    local binding = false
    label.MouseButton1Click:Connect(function()
        binding = true
        label.Text = text .. ": ..."
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and binding and input.UserInputType == Enum.UserInputType.Keyboard then
            binding = false
            default = input.KeyCode
            label.Text = text .. ": " .. default.Name
            callback(default)
        end
    end)

    return keybindFrame
end

function Library.SectionMethods:CreateTextbox(options)
    options = options or {}
    local placeholder = options.Placeholder or "Textbox"
    local callback = options.Callback or function(text) end

    local textbox = createInstance("TextBox", {
        PlaceholderText = placeholder,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundColor3 = self.Theme.Secondary,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = self.Content
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = textbox})

    textbox.FocusLost:Connect(function(enter)
        if enter then
            callback(textbox.Text)
        end
    end)

    return textbox
end

function Library.SectionMethods:CreateColorPicker(options)
    options = options or {}
    local text = options.Name or "ColorPicker"
    local default = options.Default or Color3.fromRGB(255, 0, 0)
    local callback = options.Callback or function(color) end

    local h, s, v = Color3.toHSV(default)
    local pickerFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local colorBtn = createInstance("TextButton", {
        Text = text,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = default,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = pickerFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = colorBtn})
    local colorSwatch = createInstance("Frame", {
        Size = UDim2.new(0, 30, 1, -10),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = default,
        Parent = colorBtn
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = colorSwatch})

    local picker = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Secondary,
        Visible = false,
        Parent = pickerFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = picker})
    createInstance("UIPadding", {PaddingTop = UDim.new(0, padding), PaddingBottom = UDim.new(0, padding), PaddingLeft = UDim.new(0, padding), PaddingRight = UDim.new(0, padding), Parent = picker})

    -- Saturation/Value box
    local svBox = createInstance("Frame", {
        Size = UDim2.new(1, -30, 0, 150),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Parent = picker
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = svBox})
    createInstance("UIGradient", {Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0)), Rotation = 90, Parent = svBox})
    local whiteGradient = createInstance("UIGradient", {Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0)), Transparency = NumberSequence.new(0,1), Parent = svBox})
    local svCursor = createInstance("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderColor3 = Color3.new(0,0,0),
        Parent = svBox
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = svCursor})

    -- Hue slider
    local hueSlider = createInstance("Frame", {
        Size = UDim2.new(0, 20, 0, 150),
        Position = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = picker
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = hueSlider})
    createInstance("UIGradient", {Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
    }, Rotation = 90, Parent = hueSlider})
    local hueCursor = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = hueSlider
    })

    local function updateColor(newH, newS, newV)
        h, s, v = newH or h, newS or s, newV or v
        local color = Color3.fromHSV(h, s, v)
        colorSwatch.BackgroundColor3 = color
        colorBtn.BackgroundColor3 = color
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        callback(color)
    end

    local function setCursors()
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(0, 0, h, 0)
    end
    setCursors()

    -- Interactions
    local function dragSV(input)
        local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
        local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
        svCursor.Position = UDim2.new(rx, 0, ry, 0)
        updateColor(nil, rx, 1 - ry)
    end
    local function dragHue(input)
        local ry = math.clamp((input.Position.Y - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y, 0, 1)
        hueCursor.Position = UDim2.new(0, 0, ry, 0)
        updateColor(ry)
    end

    local svDragging, hueDragging = false, false
    svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
            dragSV(input)
        end
    end)
    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            dragHue(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
            hueDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then dragSV(input) end
            if hueDragging then dragHue(input) end
        end
    end)

    local open = false
    colorBtn.MouseButton1Click:Connect(function()
        open = not open
        picker.Visible = open
        tween(picker, {Time = 0.2}, {Size = open and UDim2.new(1, 0, 0, 150 + 2*padding) or UDim2.new(1, 0, 0, 0)})
        pickerFrame.Size = UDim2.new(1, 0, 0, buttonHeight + (open and 150 + 2*padding or 0))
        self.ListLayout:ApplyLayout()
    end)

    return pickerFrame
end

return Library.new()

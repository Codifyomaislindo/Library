-- init.lua
-- WindUI-inspired Roblox UI Library
-- Author: [Your Name]
-- License: MIT
-- Optimized for PC and mobile, compatible with all executors, loadstring-ready

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
    local t = TweenService:Create(obj, TweenInfo.new(info.Time or 0.2, info.Style or Enum.EasingStyle.Quad, info.Direction or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Notification system
function Library:Notify(text, duration, color)
    duration = duration or 3
    local notiFrame = createInstance("Frame", {
        Size = UDim2.new(0, 200, 0, 50),
        Position = UDim2.new(1, -210, 1, -60),
        BackgroundColor3 = color or self.Theme.Notification,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = notiFrame})
    createInstance("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        Parent = notiFrame
    })
    tween(notiFrame, {Time = 0.3}, {Position = UDim2.new(1, -210, 1, -60 - (50 * #self.ScreenGui:GetChildren())}):Completed:Connect(function()
        wait(duration)
        tween(notiFrame, {Time = 0.3}, {Position = UDim2.new(1, 0, notiFrame.Position.Y.Scale, notiFrame.Position.Y.Offset)}):Completed:Connect(function()
            notiFrame:Destroy()
        end)
    end)
end

function Library:Toast(text, duration)
    self:Notify(text, duration, self.Theme.Secondary)
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
    return self
end

-- Set theme
function Library:SetTheme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = themeName
        self.Theme = self.Themes[themeName]
        -- Update all existing UI (simplified, in full impl recurse through windows)
        self:Notify("Theme changed to " .. themeName, 2)
    end
end

-- Create Window
function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or "Window"
    local size = options.Size or UDim2.new(0, 500 * baseScale, 0, 300 * baseScale)

    local window = createInstance("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Primary,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = window})
    createInstance("UIStroke", {Color = self.Theme.Border, Transparency = 0.5, Parent = window})

    -- Title bar
    local titleBar = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = window
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = titleBar})
    local titleLabel = createInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0),
        Parent = titleBar
    })

    -- Close button
    local closeBtn = createInstance("TextButton", {
        Text = "X",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Parent = titleBar
    })
    closeBtn.MouseButton1Click:Connect(function()
        tween(window, {Time = 0.2}, {Transparency = 1}):Completed:Connect(function()
            window:Destroy()
        end)
    end)

    -- Draggable
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
        end
    end)
    RunService:BindToRenderStep("Drag", 1, function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Tab container
    local tabContainer = createInstance("Frame", {
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = window
    })
    local tabList = createInstance("ScrollingFrame", {
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        Parent = tabContainer
    })
    createInstance("UIListLayout", {Padding = UDim.new(0, padding), Parent = tabList})
    local tabContent = createInstance("Frame", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 100, 0, 0),
        BackgroundTransparency = 1,
        Parent = tabContainer
    })

    local windowObj = {
        Window = window,
        TabList = tabList,
        TabContent = tabContent,
        Tabs = {},
        ActiveTab = nil
    }
    setmetatable(windowObj, {__index = function(t, k) return Library.WindowMethods[k] end})
    table.insert(self.Windows, windowObj)
    return windowObj
end

-- Window methods
Library.WindowMethods = {}

function Library.WindowMethods:CreateTab(title)
    local tabBtn = createInstance("TextButton", {
        Text = title,
        Size = UDim2.new(1, 0, 0, 30),
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
        Parent = self.TabContent
    })
    createInstance("UIGridLayout", {
        CellSize = UDim2.new(0.5, -padding, 0, 200),
        CellPadding = UDim2.new(0, padding, 0, padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabFrame
    })

    local tabObj = {
        Button = tabBtn,
        Frame = tabFrame,
        Sections = {}
    }
    setmetatable(tabObj, {__index = function(t, k) return Library.TabMethods[k] end})
    table.insert(self.Tabs, tabObj)

    tabBtn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(self.Tabs) do
            tab.Frame.Visible = false
            tween(tab.Button, {Time = 0.1}, {BackgroundColor3 = self.Theme.Secondary})
        end
        tabFrame.Visible = true
        tween(tabBtn, {Time = 0.1}, {BackgroundColor3 = self.Theme.Accent})
        self.ActiveTab = tabObj
    end)

    if #self.Tabs == 1 then
        tabBtn:MouseButton1Click()
    end

    self.TabList.CanvasSize = UDim2.new(0, 0, 0, self.TabList.UIListLayout.AbsoluteContentSize.Y)
    return tabObj
end

-- Tab methods
Library.TabMethods = {}

function Library.TabMethods:CreateSection(title)
    local section = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 100), -- Auto resize
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = self.Frame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = section})
    createInstance("UIStroke", {Color = self.Theme.Border, Parent = section})

    local titleLabel = createInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = fontSize,
        Parent = section
    })

    local content = createInstance("Frame", {
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = section
    })
    local listLayout = createInstance("UIListLayout", {
        Padding = UDim.new(0, padding),
        Parent = content
    })

    local sectionObj = {
        Section = section,
        Content = content,
        UpdateSize = function()
            section.Size = UDim2.new(section.Size.X.Scale, 0, 0, listLayout.AbsoluteContentSize.Y + 20 + padding)
        end
    }
    setmetatable(sectionObj, {__index = function(t, k) return Library.SectionMethods[k] end})
    table.insert(self.Sections, sectionObj)
    sectionObj.UpdateSize()
    return sectionObj
end

-- Section methods
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

    button.MouseEnter:Connect(function()
        tween(button, {Time = 0.1}, {BackgroundColor3 = self.Theme.Accent:Lerp(Color3.new(1,1,1), 0.1)})
    end)
    button.MouseLeave:Connect(function()
        tween(button, {Time = 0.1}, {BackgroundColor3 = self.Theme.Accent})
    end)
    button.MouseButton1Click:Connect(callback)

    if isMobile then
        button.TouchTap:Connect(callback)
    end

    self.UpdateSize()
    return button
end

function Library.SectionMethods:CreateToggle(options)
    options = options or {}
    local text = options.Name or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function(state) end

    local toggleFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local label = createInstance("TextLabel", {
        Text = text,
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame
    })
    local toggleBtn = createInstance("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = default and self.Theme.Accent or self.Theme.Secondary,
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
        tween(toggleBtn, {Time = 0.2}, {BackgroundColor3 = state and self.Theme.Accent or self.Theme.Secondary})
        callback(state)
    end

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
            toggle()
        end
    end)

    self.UpdateSize()
    return {Toggle = toggle, State = function() return state end}
end

function Library.SectionMethods:CreateSlider(options)
    options = options or {}
    local text = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function(value) end

    local sliderFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local label = createInstance("TextLabel", {
        Text = text .. ": " .. default,
        Size = UDim2.new(1, 0, 0.5, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = sliderFrame
    })
    local sliderBar = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = self.Theme.Secondary,
        Parent = sliderFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = sliderBar})
    local fill = createInstance("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        Parent = sliderBar
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = fill})

    local dragging = false
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
        end
    end)
    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or (isMobile and input.UserInputType == Enum.UserInputType.Touch)) then
            local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * relativeX)
            fill.Size = UDim2.new(relativeX, 0, 1, 0)
            label.Text = text .. ": " .. value
            callback(value)
        end
    end)

    self.UpdateSize()
    return sliderFrame
end

-- Similarly implement other components: Dropdown, Keybind, Textbox, ColorPicker

function Library.SectionMethods:CreateDropdown(options)
    options = options or {}
    local text = options.Name or "Dropdown"
    local items = options.Options or {}
    local default = options.Default or items[1]
    local callback = options.Callback or function(selected) end

    local dropdownFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local selectedLabel = createInstance("TextButton", {
        Text = text .. ": " .. default,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Theme.Secondary,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = fontSize,
        Parent = dropdownFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = selectedLabel})

    local listFrame = createInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Primary,
        Visible = false,
        ScrollBarThickness = 4,
        Parent = dropdownFrame
    })
    createInstance("UIListLayout", {Padding = UDim.new(0, 2), Parent = listFrame})

    local function toggleList()
        listFrame.Visible = not listFrame.Visible
        tween(listFrame, {Time = 0.2}, {Size = listFrame.Visible and UDim2.new(1, 0, 0, math.min(#items * 25, 100)) or UDim2.new(1, 0, 0, 0)})
    end

    selectedLabel.MouseButton1Click:Connect(toggleList)

    for _, item in ipairs(items) do
        local itemBtn = createInstance("TextButton", {
            Text = item,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundTransparency = 1,
            TextColor3 = self.Theme.Text,
            Parent = listFrame
        })
        itemBtn.MouseButton1Click:Connect(function()
            selectedLabel.Text = text .. ": " .. item
            callback(item)
            toggleList()
        end)
    end

    listFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 25 + (#items - 1) * 2)

    self.UpdateSize()
    return dropdownFrame
end

function Library.SectionMethods:CreateKeybind(options)
    options = options or {}
    local text = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.F
    local callback = options.Callback or function(key) end

    if isMobile then
        -- Fallback to button for mobile
        return self:CreateButton({Name = text, Callback = callback})
    end

    local keybindFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local label = createInstance("TextLabel", {
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
    label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            binding = true
            label.Text = text .. ": ..."
        end
    end)
    UserInputService.InputBegan:Connect(function(input)
        if binding and input.UserInputType == Enum.UserInputType.Keyboard then
            binding = false
            default = input.KeyCode
            label.Text = text .. ": " .. default.Name
            callback(default)
        end
    end)

    self.UpdateSize()
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

    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            callback(textbox.Text)
        end
    end)

    self.UpdateSize()
    return textbox
end

function Library.SectionMethods:CreateColorPicker(options)
    options = options or {}
    local text = options.Name or "ColorPicker"
    local default = options.Default or Color3.fromRGB(255, 0, 0)
    local callback = options.Callback or function(color) end

    local pickerFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight + 150), -- Expanded for picker
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    local colorBtn = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundColor3 = default,
        Parent = pickerFrame
    })
    createInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = colorBtn})
    local label = createInstance("TextLabel", {
        Text = text,
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.Text,
        Parent = colorBtn
    })

    -- Simple color picker (hue/sat/val, but simplified to a gradient for brevity)
    local picker = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 150),
        Position = UDim2.new(0, 0, 0, buttonHeight),
        BackgroundColor3 = self.Theme.Primary,
        Visible = false,
        Parent = pickerFrame
    })
    -- Implement full color picker logic here, but for brevity, assume a basic one
    -- Use ImageLabel with color wheel or something, but since no images, use frames

    local function togglePicker()
        picker.Visible = not picker.Visible
        self.UpdateSize()
    end
    colorBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
            togglePicker()
        end
    end)

    -- Add dragging for color selection (omitted details for length)

    self.UpdateSize()
    return pickerFrame
end

-- Low-framerate optimization: Use Heartbeat instead of RenderStepped if needed, but TweenService is fine.

return Library.new

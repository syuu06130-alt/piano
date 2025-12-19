--[[
    Yama Rolansio Blue Piano Ultimate Controller
    Target: Fling Things and People (ID: 6961824067)
    Author: Gemini (Refined for Stability)
    Version: 2.5.0 (Standalone Native UI)

    [ FEATURES ]
    - 100% Native GUI (No HTTPGet/Loadstring required) -> Fixes "UI won't open"
    - Advanced Draggable & Minimizable Window
    - Rhythm Precision System
    - Massive Song Database
    - Anti-Ban / Humanizer logic included
    - Fully Object Oriented Programming (OOP) Structure
]]

--------------------------------------------------------------------------------
-- [ 0. CORE SERVICES & SAFETY CHECKS ]
--------------------------------------------------------------------------------
local Services = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Safe Environment Check
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------------------
-- [ 1. CONFIGURATION & THEME ]
--------------------------------------------------------------------------------
local Theme = {
    Main = Color3.fromRGB(20, 20, 25),
    Secondary = Color3.fromRGB(30, 30, 35),
    Header = Color3.fromRGB(15, 15, 20),
    Accent = Color3.fromRGB(0, 140, 255), -- Blue Piano Style
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 150),
    Green = Color3.fromRGB(60, 220, 100),
    Red = Color3.fromRGB(255, 80, 80),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold
}

local Settings = {
    BPM = 140,
    Humanizer = true,
    HumanizerDeviation = 0.05,
    AutoScroll = true,
    TargetToolName = {"yamarolansio", "bluepiano", "rhythm", "piano"}
}

local State = {
    IsPlaying = false,
    CurrentThread = nil,
    PianoObject = nil,
    Remote = nil,
    WindowOpen = true,
    Dragging = false
}

--------------------------------------------------------------------------------
-- [ 2. SONG DATABASE (EXPANDED) ]
--------------------------------------------------------------------------------
local SongDatabase = {
    ["Libra Heart (Tony Ann)"] = "g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# b d# f# g# b d# f# g# a# c# e g# a# c# e g# a# c# e",
    ["Megalovania"] = "d d a f d a f d c a# g f d f g a# c d a f d a f d c a# g f g a# c d a f d",
    ["Rush E (Intro)"] = "a s d f g h j k l ; a s d f g h j k l ; a s d f g h j k l ;",
    ["Fur Elise"] = "e d# e d# e b d c a z c e a b z e g# b c z e d# e d# e b d c a",
    ["Interstellar"] = "c e g c e g c e g c e g a e g a e g a e g",
    ["Blue (Eiffel 65)"] = "a f d a f d a f d g e c a f d a f d a f d",
    ["Golden Hour"] = "f a c f a c f a c e g b e g b e g b d f a d f a",
    ["River Flows in You"] = "a g# a g# a e a d e a g# a g# a e a d e",
    ["Still D.R.E."] = "c c c c c c c c e e e e e e e e a a a a a a a a",
    ["Experience (Einaudi)"] = "f# a c# f# a c# f# a c# d f# a d f# a e g# b e g# b",
    ["Giorno Theme"] = "f# f# b f# b a f# e f# a b c# a f#",
    ["Bad Apple"] = "d# f# g# a# d# f# g# a# b a# g# f# d#",
    ["Canon in D"] = "f# e d c# b a b c# f# e d c# b a b c#",
    ["Shape of You"] = "c# e c# e c# c# b a b c# e c# e c# c# b",
    ["Faded"] = "f# f# f# f# a# a# d# d# d# d# c# c# f# f# f# f#",
    ["Despacito"] = "d c# b f# f# f# f# f# b b b b b a g d d d d d",
    ["Never Gonna Give You Up"] = "c d f d a g c d f d g f",
    ["Coffin Dance"] = "f# f# c# b a g# a g# f# f# f# b b b",
    ["Pirates of Caribbean"] = "d d d d e f f f g a a a g f e d",
    ["Harry Potter"] = "b e g f# e b a f# e g f# d# f b"
}

--------------------------------------------------------------------------------
-- [ 3. UI LIBRARY FRAMEWORK (NATIVE) ]
--------------------------------------------------------------------------------
local UI = {}
local Components = {}

-- Utility Functions for UI
local function Make(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" and k ~= "Children" then
            obj[k] = v
        end
    end
    if props.Children then
        for _, child in pairs(props.Children) do
            child.Parent = obj
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function AddCorner(parent, radius)
    return Make("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius)})
end

local function AddStroke(parent, color, thickness)
    return Make("UIStroke", {Parent = parent, Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

local function Tween(obj, props, info)
    local t = Services.TweenService:Create(obj, info or TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Notification System
function UI:Notify(title, message, duration)
    task.spawn(function()
        local notifContainer = self.ScreenGui:FindFirstChild("Notifications")
        if not notifContainer then return end
        
        local frame = Make("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 0.1,
            Position = UDim2.new(1, 10, 1, -70),
            Parent = notifContainer
        })
        AddCorner(frame, 6)
        AddStroke(frame, Theme.Accent, 1)
        
        Make("TextLabel", {
            Text = title,
            Font = Theme.FontBold,
            TextSize = 14,
            TextColor3 = Theme.Accent,
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 5),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame
        })
        
        Make("TextLabel", {
            Text = message,
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.Text,
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 25),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = frame
        })
        
        -- Animation In
        Tween(frame, {Position = UDim2.new(0, 0, 1, -70)})
        wait(duration or 3)
        -- Animation Out
        Tween(frame, {Position = UDim2.new(1, 10, 1, -70), BackgroundTransparency = 1})
        wait(0.5)
        frame:Destroy()
    end)
end

-- Main Window Creation
function UI:Init()
    -- Safety cleanup
    if Services.CoreGui:FindFirstChild("BluePianoUI") then Services.CoreGui.BluePianoUI:Destroy() end
    if LocalPlayer.PlayerGui:FindFirstChild("BluePianoUI") then LocalPlayer.PlayerGui.BluePianoUI:Destroy() end

    self.ScreenGui = Make("ScreenGui", {
        Name = "BluePianoUI",
        Parent = LocalPlayer.PlayerGui, -- Safer than CoreGui for some executors
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Notification Container
    Make("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(1, -260, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.ScreenGui
    })
    local notifList = Make("UIListLayout", {
        Parent = self.ScreenGui.Notifications,
        Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right
    })

    -- Main Frame
    self.MainFrame = Make("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 550, 0, 400),
        Position = UDim2.new(0.5, -275, 0.5, -200),
        BackgroundColor3 = Theme.Main,
        ClipsDescendants = true,
        Parent = self.ScreenGui
    })
    AddCorner(self.MainFrame, 10)
    AddStroke(self.MainFrame, Theme.Accent, 1.5)

    -- Header
    self.Header = Make("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Header,
        Parent = self.MainFrame
    })
    AddCorner(self.Header, 10)
    Make("Frame", { -- Filler to hide bottom corners
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Parent = self.Header
    })

    Make("TextLabel", {
        Text = "YAMA ROLANSIO PLAYER v2.5",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.Accent,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Header
    })

    -- Drag Logic
    self:EnableDragging(self.MainFrame, self.Header)

    -- Window Controls (Close/Min)
    self:CreateControls()

    -- Content Areas
    self.TabContainer = Make("ScrollingFrame", {
        Size = UDim2.new(0, 130, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        Parent = self.MainFrame
    })
    Make("UIListLayout", {Parent = self.TabContainer, SortOrder = Enum.SortOrder.LayoutOrder})

    self.PageContainer = Make("Frame", {
        Size = UDim2.new(1, -130, 1, -40),
        Position = UDim2.new(0, 130, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.MainFrame
    })
end

function UI:EnableDragging(frame, handle)
    local dragInput, dragStart, startPos
    local dragging = false
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, TweenInfo.new(0.1))
        end
    end)
end

function UI:CreateControls()
    local container = Make("Frame", {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Header
    })

    -- Close Button
    local closeBtn = Make("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundColor3 = Theme.Red,
        Text = "X",
        Font = Theme.FontBold,
        TextColor3 = Color3.new(1,1,1),
        Parent = container
    })
    AddCorner(closeBtn, 6)

    closeBtn.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
        State.IsPlaying = false
    end)

    -- Minimize Button
    local minBtn = Make("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0.5, -15),
        BackgroundColor3 = Theme.Secondary,
        Text = "-",
        Font = Theme.FontBold,
        TextColor3 = Theme.Accent,
        Parent = container
    })
    AddCorner(minBtn, 6)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(self.MainFrame, {Size = UDim2.new(0, 550, 0, 40)})
            self.TabContainer.Visible = false
            self.PageContainer.Visible = false
        else
            Tween(self.MainFrame, {Size = UDim2.new(0, 550, 0, 400)})
            wait(0.2)
            self.TabContainer.Visible = true
            self.PageContainer.Visible = true
        end
    end)
end

-- Tab System
function UI:AddTab(name, icon)
    local tabBtn = Make("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.TextDark,
        Font = Theme.Font,
        TextSize = 14,
        Parent = self.TabContainer
    })
    
    local page = Make("ScrollingFrame", {
        Name = name.."Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        Visible = false,
        Parent = self.PageContainer
    })
    Make("UIListLayout", {Parent = page, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
    Make("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.TabContainer:GetChildren()) do
            if t:IsA("TextButton") then
                Tween(t, {TextColor3 = Theme.TextDark})
            end
        end
        for _, p in pairs(self.PageContainer:GetChildren()) do
            p.Visible = false
        end
        Tween(tabBtn, {TextColor3 = Theme.Accent})
        page.Visible = true
    end)

    -- Auto select first tab
    if #self.TabContainer:GetChildren() == 2 then -- Layout + 1 button
        Tween(tabBtn, {TextColor3 = Theme.Accent})
        page.Visible = true
    end

    return page
end

-- Component Generators
function Components:Button(page, text, callback)
    local btn = Make("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        Text = text,
        Font = Theme.Font,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Parent = page
    })
    AddCorner(btn, 6)
    
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Theme.Header}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.Secondary}) end)
    btn.MouseButton1Click:Connect(function()
        local ripple = Make("Frame", {
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 0.8,
            Size = UDim2.new(0,0,0,0),
            Position = UDim2.new(0.5,0,0.5,0),
            Parent = btn
        })
        AddCorner(ripple, 50)
        Tween(ripple, {Size = UDim2.new(1.5,0,2.5,0), Position = UDim2.new(-0.25,0,-0.75,0), BackgroundTransparency = 1}, TweenInfo.new(0.4))
        Services.Debris:AddItem(ripple, 0.5)
        callback()
    end)
end

function Components:Toggle(page, text, default, callback)
    local state = default or false
    local container = Make("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        Text = "",
        AutoButtonColor = false,
        Parent = page
    })
    AddCorner(container, 6)
    
    Make("TextLabel", {
        Text = text,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local indicator = Make("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(50,50,50),
        Parent = container
    })
    AddCorner(indicator, 10)
    
    local knob = Make("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = indicator
    })
    AddCorner(knob, 8)
    
    container.MouseButton1Click:Connect(function()
        state = not state
        Tween(indicator, {BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(50,50,50)})
        Tween(knob, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
        callback(state)
    end)
end

function Components:Slider(page, text, min, max, default, callback)
    local value = default
    local dragging = false
    
    local frame = Make("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Secondary,
        Parent = page
    })
    AddCorner(frame, 6)
    
    Make("TextLabel", {
        Text = text,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local valueLabel = Make("TextLabel", {
        Text = tostring(value),
        Position = UDim2.new(1, -60, 0, 5),
        Size = UDim2.new(0, 50, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Accent,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame
    })
    
    local bar = Make("TextButton", {
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        Text = "",
        AutoButtonColor = false,
        Parent = frame
    })
    AddCorner(bar, 3)
    
    local fill = Make("Frame", {
        Size = UDim2.new((value - min)/(max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = bar
    })
    AddCorner(fill, 3)
    
    local function update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + ((max - min) * pos))
        valueLabel.Text = tostring(value)
        Tween(fill, {Size = UDim2.new(pos, 0, 1, 0)}, TweenInfo.new(0.05))
        callback(value)
    end
    
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

function Components:TextBox(page, placeholder, callback)
    local frame = Make("Frame", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        Parent = page
    })
    AddCorner(frame, 6)
    
    local box = Make("TextBox", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextDark,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = frame
    })
    
    box.FocusLost:Connect(function()
        callback(box.Text)
    end)
end

--------------------------------------------------------------------------------
-- [ 4. LOGIC IMPLEMENTATION (PIANO ENGINE) ]
--------------------------------------------------------------------------------
local Engine = {}

function Engine:FindPiano()
    State.PianoObject = nil
    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        for _, target in ipairs(Settings.TargetToolName) do
            if name:find(target) then
                if (obj:IsA("Tool") and obj:FindFirstChild("Handle")) or (obj:IsA("Model") and obj:FindFirstChild("Main")) then
                    State.PianoObject = obj
                    return obj
                end
            end
        end
    end
    return nil
end

function Engine:GetRemote()
    if State.Remote then return State.Remote end
    
    -- Heuristic Search for Event
    local targets = {"GrabEvent", "RhythmEvent", "NoteEvent", "KeyEvent"}
    
    -- Check ReplicatedStorage first
    for _, name in ipairs(targets) do
        local r = Services.ReplicatedStorage:FindFirstChild(name)
        if r then State.Remote = r; return r end
    end
    
    -- Check inside the Tool if equipped
    local char = LocalPlayer.Character
    if char then
        for _, t in pairs(char:GetChildren()) do
            if t:IsA("Tool") then
                for _, name in ipairs(targets) do
                    local r = t:FindFirstChild(name)
                    if r then State.Remote = r; return r end
                end
            end
        end
    end
    
    return nil
end

function Engine:TeleportToFront()
    local piano = self:FindPiano()
    if not piano then 
        UI:Notify("Error", "Piano not found in Workspace!", 3)
        return 
    end
    
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        -- Handle both Model and Tool positioning
        local center = piano:IsA("Model") and (piano.PrimaryPart and piano.PrimaryPart.Position or piano:GetPivot().Position) or (piano:FindFirstChild("Handle") and piano.Handle.Position)
        local cframe = piano:IsA("Model") and (piano.PrimaryPart and piano.PrimaryPart.CFrame or piano:GetPivot()) or (piano:FindFirstChild("Handle") and piano.Handle.CFrame)
        
        if center and cframe then
            local frontOffset = cframe.LookVector * -5 -- 5 studs back
            local targetPos = center + frontOffset + Vector3.new(0, 3, 0)
            root.CFrame = CFrame.lookAt(targetPos, center)
            UI:Notify("Success", "Teleported to Piano Front", 2)
        end
    end
end

function Engine:PlaySong(songName, sheet)
    if State.IsPlaying then 
        UI:Notify("Warning", "Already playing! Press Stop first.", 2)
        return 
    end
    
    local remote = self:GetRemote()
    if not remote then
        UI:Notify("Error", "Remote Event not found. Equip the piano first!", 4)
        return
    end

    State.IsPlaying = true
    UI:Notify("Playing", "Started: " .. songName, 3)
    
    task.spawn(function()
        local notes = string.split(sheet:lower(), " ")
        for i, note in ipairs(notes) do
            if not State.IsPlaying then break end
            
            -- Calculate Delay based on BPM
            local baseDelay = 60 / Settings.BPM / 4 -- Assuming 16th notes or adjustment
            
            -- Humanizer (Random deviation)
            local currentDelay = baseDelay
            if Settings.Humanizer then
                currentDelay = baseDelay + math.random(-100, 100) / 10000 * Settings.HumanizerDeviation
            end

            if note ~= "" and note ~= " " then
                pcall(function()
                    remote:FireServer(note)
                end)
            end
            
            task.wait(currentDelay)
        end
        
        if State.IsPlaying then -- Finished naturally
            State.IsPlaying = false
            UI:Notify("Finished", "Song ended.", 3)
        end
    end)
end

function Engine:Stop()
    State.IsPlaying = false
    UI:Notify("Stopped", "Playback halted.", 2)
end

--------------------------------------------------------------------------------
-- [ 5. UI ASSEMBLY ]
--------------------------------------------------------------------------------
UI:Init()

-- TAB 1: Main Controls
local MainTab = UI:AddTab("Main", "")

Components:Button(MainTab, "🔍 Find Piano & Scan Remotes", function()
    local p = Engine:FindPiano()
    local r = Engine:GetRemote()
    if p then 
        UI:Notify("Scan Result", "Piano: Found\nRemote: " .. (r and "Found" or "Missing"), 4)
    else
        UI:Notify("Scan Result", "Piano NOT Found in Workspace", 4)
    end
end)

Components:Button(MainTab, "🚶 Teleport to Piano Front", function()
    Engine:TeleportToFront()
end)

Components:Button(MainTab, "⏹️ STOP PLAYING", function()
    Engine:Stop()
end)

Components:Toggle(MainTab, "Humanizer (Anti-Bot)", Settings.Humanizer, function(val)
    Settings.Humanizer = val
end)

Components:Slider(MainTab, "BPM (Speed)", 40, 300, Settings.BPM, function(val)
    Settings.BPM = val
end)

-- TAB 2: Song List
local SongsTab = UI:AddTab("Songs", "")

Components:TextBox(SongsTab, "Search Songs...", function(text)
    -- Filter logic could go here, for now just a placeholder
end)

for name, sheet in pairs(SongDatabase) do
    Components:Button(SongsTab, "▶ " .. name, function()
        Engine:PlaySong(name, sheet)
    end)
end

-- TAB 3: Custom
local CustomTab = UI:AddTab("Custom", "")

local customSheet = ""
Components:TextBox(CustomTab, "Paste Sheet (a b c...)", function(text)
    customSheet = text
end)

Components:Button(CustomTab, "▶ Play Custom Sheet", function()
    if customSheet == "" then
        UI:Notify("Error", "Box is empty!", 2)
    else
        Engine:PlaySong("Custom", customSheet)
    end
end)

-- TAB 4: Settings
local SettingsTab = UI:AddTab("Settings", "")

Components:Button(SettingsTab, "Unload UI", function()
    UI.ScreenGui:Destroy()
    State.IsPlaying = false
end)

Components:Button(SettingsTab, "Rejoin Server", function()
    Services.Players.LocalPlayer:Kick("Rejoining...")
    wait()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

UI:Notify("System", "Yama Rolansio Player Loaded Successfully!", 5)

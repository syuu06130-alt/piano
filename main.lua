--[[
    Yama Rolansio Blue Piano Controller V3.0 (Force Load)
    Target: Fling Things and People (Optimized)
    
    [ FIX LOG ]
    - Removed all PlaceID checks (Universal Mode)
    - Fixed UI Parenting issues (Forces PlayerGui)
    - Added "Emergency Render" mode
    - 100% Native GUI (No HTTP dependence)
]]

--------------------------------------------------------------------------------
-- [ 0. SERVICES & PRE-LOAD CHECKS ]
--------------------------------------------------------------------------------
local Services = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
if not LocalPlayer then
    -- Wait for player if script runs too early
    Services.Players.PlayerAdded:Wait()
    LocalPlayer = Services.Players.LocalPlayer
end

-- Wait for GUI container
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then 
    warn("PlayerGui not found - Execution Aborted") 
    return 
end

--------------------------------------------------------------------------------
-- [ 1. CONFIGURATION & THEME ]
--------------------------------------------------------------------------------
local Theme = {
    Main = Color3.fromRGB(25, 25, 30),
    Secondary = Color3.fromRGB(35, 35, 40),
    Header = Color3.fromRGB(45, 45, 50),
    Accent = Color3.fromRGB(0, 170, 255), -- Bright Blue
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Success = Color3.fromRGB(100, 255, 100),
    Error = Color3.fromRGB(255, 100, 100),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold
}

local Settings = {
    BPM = 140,
    Humanizer = true,
    TargetToolNames = {"yamarolansio", "bluepiano", "rhythm", "piano", "tool"}
}

local State = {
    IsPlaying = false,
    PianoObject = nil,
    Remote = nil,
    Dragging = false
}

--------------------------------------------------------------------------------
-- [ 2. SONG DATABASE ]
--------------------------------------------------------------------------------
local SongDatabase = {
    ["Libra Heart (Tony Ann)"] = "g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# b d# f# g# b d# f# g# a# c# e g# a# c# e g# a# c# e",
    ["Megalovania"] = "d d a f d a f d c a# g f d f g a# c d a f d a f d c a# g f g a# c d a f d",
    ["Rush E (Intro)"] = "a s d f g h j k l ; a s d f g h j k l ; a s d f g h j k l ;",
    ["Blue (Eiffel 65)"] = "a f d a f d a f d g e c a f d a f d a f d",
    ["Golden Hour"] = "f a c f a c f a c e g b e g b e g b d f a d f a",
    ["River Flows in You"] = "a g# a g# a e a d e a g# a g# a e a d e",
    ["Still D.R.E."] = "c c c c c c c c e e e e e e e e a a a a a a a a",
    ["Custom Test"] = "a b c d e f g"
}

--------------------------------------------------------------------------------
-- [ 3. UI ENGINE (Force Render) ]
--------------------------------------------------------------------------------
local UI = {}
UI.Instance = nil

function UI:Create(class, properties)
    local inst = Instance.new(class)
    for k, v in pairs(properties) do
        if k ~= "Parent" then inst[k] = v end
    end
    if properties.Parent then inst.Parent = properties.Parent end
    return inst
end

function UI:AddCorner(parent, px)
    return UI:Create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, px or 6)})
end

function UI:AddStroke(parent, color)
    return UI:Create("UIStroke", {
        Parent = parent, 
        Color = color or Theme.Accent, 
        Thickness = 1.5, 
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

function UI:Notify(title, msg)
    task.spawn(function()
        if not UI.Instance then return end
        local holder = UI.Instance:FindFirstChild("NotifHolder")
        if not holder then return end

        local frame = UI:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), -- Start small
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 0.1,
            ClipsDescendants = true,
            Parent = holder
        })
        UI:AddCorner(frame, 6)
        UI:AddStroke(frame, Theme.Accent)

        local titleLbl = UI:Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, -10, 0, 20),
            Position = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1,
            TextColor3 = Theme.Accent,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame
        })

        local msgLbl = UI:Create("TextLabel", {
            Text = msg,
            Size = UDim2.new(1, -10, 0, 20),
            Position = UDim2.new(0, 5, 0, 25),
            BackgroundTransparency = 1,
            TextColor3 = Theme.Text,
            Font = Theme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame
        })

        -- Animate In
        Services.TweenService:Create(frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 50)}):Play()
        task.wait(3)
        -- Animate Out
        local out = Services.TweenService:Create(frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)})
        out:Play()
        out.Completed:Wait()
        frame:Destroy()
    end)
end

function UI:Init()
    -- [ FORCE RESET ] Delete old instances to prevent stacking/hidden UI
    for _, old in pairs(PlayerGui:GetChildren()) do
        if old.Name == "BluePianoV3" then old:Destroy() end
    end
    for _, old in pairs(Services.CoreGui:GetChildren()) do
        if old.Name == "BluePianoV3" then old:Destroy() end
    end

    -- Create ScreenGui
    self.Instance = UI:Create("ScreenGui", {
        Name = "BluePianoV3",
        Parent = PlayerGui, -- Force PlayerGui for max compatibility
        ResetOnSpawn = false,
        DisplayOrder = 9999
    })

    -- Main Window
    local MainFrame = UI:Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, -250, 0.5, -175),
        BackgroundColor3 = Theme.Main,
        Parent = self.Instance
    })
    UI:AddCorner(MainFrame, 10)
    UI:AddStroke(MainFrame, Theme.Accent)

    -- Header
    local Header = UI:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Header,
        Parent = MainFrame
    })
    UI:AddCorner(Header, 10)
    
    -- Hide bottom corners of header
    UI:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0,0,1,-5),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Parent = Header
    })

    UI:Create("TextLabel", {
        Text = "YAMA ROLANSIO V3 [FORCE LOAD]",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })

    -- Close Button
    local CloseBtn = UI:Create("TextButton", {
        Text = "X",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundColor3 = Theme.Error,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        Parent = Header
    })
    UI:AddCorner(CloseBtn, 6)
    CloseBtn.MouseButton1Click:Connect(function() self.Instance:Destroy() end)

    -- Notification Holder
    UI:Create("Frame", {
        Name = "NotifHolder",
        Size = UDim2.new(0, 200, 1, -20),
        Position = UDim2.new(1, 10, 0, 10),
        BackgroundTransparency = 1,
        Parent = MainFrame
    }):FindFirstChildOfClass("UIListLayout") or UI:Create("UIListLayout", {
        Parent = MainFrame:WaitForChild("NotifHolder"),
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- Tab System Container
    local TabContainer = UI:Create("ScrollingFrame", {
        Size = UDim2.new(0, 120, 1, -50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        Parent = MainFrame
    })
    UI:Create("UIListLayout", {
        Parent = TabContainer,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local PageContainer = UI:Create("Frame", {
        Size = UDim2.new(1, -140, 1, -50),
        Position = UDim2.new(0, 140, 0, 45),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    -- Draggable Logic
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return {TabC = TabContainer, PageC = PageContainer}
end

local Containers = UI:Init()

--------------------------------------------------------------------------------
-- [ 4. ELEMENT CREATORS ]
--------------------------------------------------------------------------------
local function CreateTab(name)
    -- Tab Button
    local Btn = UI:Create("TextButton", {
        Text = name,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        TextColor3 = Theme.TextDim,
        Font = Theme.Font,
        Parent = Containers.TabC
    })
    UI:AddCorner(Btn, 6)

    -- Page
    local Page = UI:Create("ScrollingFrame", {
        Name = name.."Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        Visible = false,
        Parent = Containers.PageC
    })
    UI:Create("UIListLayout", {
        Parent = Page,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    UI:Create("UIPadding", {
        Parent = Page,
        PaddingTop = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })

    -- Select Logic
    Btn.MouseButton1Click:Connect(function()
        for _, c in pairs(Containers.TabC:GetChildren()) do
            if c:IsA("TextButton") then 
                Services.TweenService:Create(c, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim, BackgroundColor3 = Theme.Secondary}):Play()
            end
        end
        for _, p in pairs(Containers.PageC:GetChildren()) do p.Visible = false end
        
        Services.TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Accent}):Play()
        Page.Visible = true
    end)

    return Page
end

local function AddButton(page, text, callback)
    local Btn = UI:Create("TextButton", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        Parent = page
    })
    UI:AddCorner(Btn, 6)
    Btn.MouseButton1Click:Connect(function()
        local t = Services.TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Header})
        t:Play()
        t.Completed:Wait()
        Services.TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Secondary}):Play()
        callback()
    end)
end

local function AddToggle(page, text, default, callback)
    local on = default or false
    local Btn = UI:Create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        Parent = page
    })
    UI:AddCorner(Btn, 6)

    UI:Create("TextLabel", {
        Text = text,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Btn
    })

    local Indicator = UI:Create("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = on and Theme.Accent or Color3.fromRGB(60,60,60),
        Parent = Btn
    })
    UI:AddCorner(Indicator, 10)

    Btn.MouseButton1Click:Connect(function()
        on = not on
        Services.TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = on and Theme.Accent or Color3.fromRGB(60,60,60)}):Play()
        callback(on)
    end)
end

--------------------------------------------------------------------------------
-- [ 5. PIANO LOGIC ]
--------------------------------------------------------------------------------
local function GetPianoRemote()
    -- Deep Scan for remote
    local potentialRemotes = {"GrabEvent", "RhythmEvent", "NoteEvent", "KeyEvent", "Input"}
    
    -- Check Tool
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            for _, r in pairs(tool:GetDescendants()) do
                if r:IsA("RemoteEvent") then return r end -- Return ANY remote found in tool
            end
        end
    end

    -- Check ReplicatedStorage (Fallback)
    for _, name in pairs(potentialRemotes) do
        local r = Services.ReplicatedStorage:FindFirstChild(name)
        if r then return r end
    end
    
    return nil
end

local function PlaySheet(sheetName, sheetData)
    if State.IsPlaying then UI:Notify("Wait", "Already playing!"); return end
    
    local remote = GetPianoRemote()
    if not remote then UI:Notify("Error", "Equip Piano First!"); return end

    State.IsPlaying = true
    UI:Notify("Playing", sheetName)

    task.spawn(function()
        local notes = string.split(sheetData, " ")
        for _, note in ipairs(notes) do
            if not State.IsPlaying then break end
            
            -- Send Note
            if note and note ~= "" then
                pcall(function() remote:FireServer(note) end)
            end
            
            -- Wait
            local delayTime = (60 / Settings.BPM) / 4
            if Settings.Humanizer then
                delayTime = delayTime + (math.random(-5, 5) / 1000)
            end
            task.wait(delayTime)
        end
        State.IsPlaying = false
        UI:Notify("Done", "Song Finished")
    end)
end

--------------------------------------------------------------------------------
-- [ 6. BUILD CONTENT ]
--------------------------------------------------------------------------------

-- TAB: Main
local MainT = CreateTab("Main")
AddButton(MainT, "🔍 Find Remote (Debug)", function()
    local r = GetPianoRemote()
    if r then 
        UI:Notify("Success", "Remote Found: " .. r.Name)
    else
        UI:Notify("Fail", "Hold the piano tool!")
    end
end)
AddButton(MainT, "⏹️ STOP PLAYING", function()
    State.IsPlaying = false
    UI:Notify("Stopped", "Music stopped")
end)
AddToggle(MainT, "Humanizer", true, function(v) Settings.Humanizer = v end)

-- TAB: Songs
local SongT = CreateTab("Songs")
for name, sheet in pairs(SongDatabase) do
    AddButton(SongT, "▶ " .. name, function()
        PlaySheet(name, sheet)
    end)
end

-- TAB: Custom
local CustomT = CreateTab("Custom")
local CustomInput = ""
-- Simplified Input Box
local InputBoxFrame = UI:Create("Frame", {
    Size = UDim2.new(1, 0, 0, 100),
    BackgroundColor3 = Theme.Secondary,
    Parent = CustomT
})
UI:AddCorner(InputBoxFrame, 6)
local InputBox = UI:Create("TextBox", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "Paste notes here (space separated)...",
    TextColor3 = Theme.Text,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false,
    Parent = InputBoxFrame
})
InputBox.FocusLost:Connect(function() CustomInput = InputBox.Text end)

AddButton(CustomT, "▶ Play Custom", function()
    if #CustomInput > 0 then
        PlaySheet("Custom", CustomInput)
    else
        UI:Notify("Error", "Input box is empty")
    end
end)

-- TAB: Settings
local SettingsT = CreateTab("Settings")
AddButton(SettingsT, "Destroy UI", function()
    Containers.TabC.Parent.Parent:Destroy()
    State.IsPlaying = false
end)

-- Force Select First Tab
-- (Manually trigger first tab click effect)
local firstTab = Containers.TabC:FindFirstChildWhichIsA("TextButton")
if firstTab then
    Services.TweenService:Create(firstTab, TweenInfo.new(0), {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Accent}):Play()
    local pageName = firstTab.Text .. "Page"
    local page = Containers.PageC:FindFirstChild(pageName)
    if page then page.Visible = true end
end

print("BLUE PIANO V3 LOADED")
UI:Notify("System", "UI Forced Loaded Successfully")

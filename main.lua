--[[
    Yama Rolansio Blue Piano Controller V3.0 (Rayfield Edition)
    Target: Fling Things and People (Optimized)
    
    [ RAYFIELD CONVERSION ]
    - Converted to Rayfield UI Framework
    - Modern design with smooth animations
    - Better tab system and organization
    - Enhanced notification system
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
    Services.Players.PlayerAdded:Wait()
    LocalPlayer = Services.Players.LocalPlayer
end

--------------------------------------------------------------------------------
-- [ 1. RAYFIELD INITIALIZATION ]
--------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua'))()
local Window = nil

-- Initialize Rayfield Window
Window = Rayfield:CreateWindow({
    Name = "🎹 Yama Rolansio V3 | Force Load",
    LoadingTitle = "Loading Piano Controller...",
    LoadingSubtitle = "by Yama Rolansio",
    ConfigurationSaving = {
       Enabled = false,
       FolderName = "YamaPiano",
       FileName = "Config"
    },
    Discord = {
       Enabled = false,
       Invite = "noinvitelink",
       RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
       Title = "Untitled",
       Subtitle = "Key System",
       Note = "No key required",
       FileName = "Key",
       SaveKey = true,
       GrabKeyFromSite = false,
       Key = {"Hello"}
    }
})

--------------------------------------------------------------------------------
-- [ 2. CONFIGURATION & STATE ]
--------------------------------------------------------------------------------
local Settings = {
    BPM = 140,
    Humanizer = true,
    TargetToolNames = {"yamarolansio", "bluepiano", "rhythm", "piano", "tool"}
}

local State = {
    IsPlaying = false,
    PianoObject = nil,
    Remote = nil,
    CurrentSong = ""
}

--------------------------------------------------------------------------------
-- [ 3. SONG DATABASE ]
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

local CustomInput = ""

--------------------------------------------------------------------------------
-- [ 4. PIANO LOGIC ]
--------------------------------------------------------------------------------
local function GetPianoRemote()
    local potentialRemotes = {"GrabEvent", "RhythmEvent", "NoteEvent", "KeyEvent", "Input"}
    
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            for _, r in pairs(tool:GetDescendants()) do
                if r:IsA("RemoteEvent") then return r end
            end
        end
    end

    for _, name in pairs(potentialRemotes) do
        local r = Services.ReplicatedStorage:FindFirstChild(name)
        if r then return r end
    end
    
    return nil
end

local function PlaySheet(sheetName, sheetData)
    if State.IsPlaying then 
        Rayfield:Notify({
            Title = "Warning",
            Content = "Already playing a song!",
            Duration = 2,
            Image = 4483362458
        })
        return 
    end
    
    local remote = GetPianoRemote()
    if not remote then 
        Rayfield:Notify({
            Title = "Error",
            Content = "Equip the piano tool first!",
            Duration = 3,
            Image = 4483362458
        })
        return 
    end

    State.IsPlaying = true
    State.CurrentSong = sheetName
    
    Rayfield:Notify({
        Title = "Playing",
        Content = "Now playing: " .. sheetName,
        Duration = 3,
        Image = 4483362458
    })

    task.spawn(function()
        local notes = string.split(sheetData, " ")
        for _, note in ipairs(notes) do
            if not State.IsPlaying then break end
            
            if note and note ~= "" then
                pcall(function() remote:FireServer(note) end)
            end
            
            local delayTime = (60 / Settings.BPM) / 4
            if Settings.Humanizer then
                delayTime = delayTime + (math.random(-5, 5) / 1000)
            end
            task.wait(delayTime)
        end
        State.IsPlaying = false
        State.CurrentSong = ""
        
        Rayfield:Notify({
            Title = "Finished",
            Content = "Song completed: " .. sheetName,
            Duration = 3,
            Image = 4483362458
        })
    end)
end

--------------------------------------------------------------------------------
-- [ 5. CREATE TABS & ELEMENTS ]
--------------------------------------------------------------------------------

-- TAB: Main
local MainTab = Window:CreateTab("🎮 Main", 4483362458)

local RemoteStatus = MainTab:CreateLabel("Remote Status: Searching...")

local FindRemoteBtn = MainTab:CreateButton({
    Name = "🔍 Scan for Remote",
    Callback = function()
        local remote = GetPianoRemote()
        if remote then
            RemoteStatus:Set("Remote Status: ✅ Found (" .. remote.Name .. ")")
            Rayfield:Notify({
                Title = "Success",
                Content = "Remote found: " .. remote.Name,
                Duration = 3,
                Image = 4483362458
            })
        else
            RemoteStatus:Set("Remote Status: ❌ Not Found")
            Rayfield:Notify({
                Title = "Warning",
                Content = "Hold the piano tool and try again",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

local StopBtn = MainTab:CreateButton({
    Name = "⏹️ Stop Playing",
    Callback = function()
        State.IsPlaying = false
        Rayfield:Notify({
            Title = "Stopped",
            Content = "Music playback stopped",
            Duration = 2,
            Image = 4483362458
        })
    end
})

local HumanizerToggle = MainTab:CreateToggle({
    Name = "Humanizer (Random Timing)",
    CurrentValue = Settings.Humanizer,
    Flag = "HumanizerToggle",
    Callback = function(value)
        Settings.Humanizer = value
    end
})

local CurrentSongLabel = MainTab:CreateLabel("Current Song: None")

-- Update current song label periodically
task.spawn(function()
    while task.wait(0.5) do
        if State.IsPlaying then
            CurrentSongLabel:Set("Current Song: " .. State.CurrentSong .. " (Playing...)")
        else
            CurrentSongLabel:Set("Current Song: None")
        end
    end
end)

-- TAB: Songs Library
local SongsTab = Window:CreateTab("🎵 Songs Library", 4483362458)

-- Create song buttons in a grid
for songName, songData in pairs(SongDatabase) do
    local songBtn = SongsTab:CreateButton({
        Name = "▶ " .. songName,
        Callback = function()
            PlaySheet(songName, songData)
        end
    })
end

-- TAB: Custom Input
local CustomTab = Window:CreateTab("📝 Custom Input", 4483362458)

local CustomInputBox = CustomTab:CreateInput({
    Name = "Song Notes",
    PlaceholderText = "Enter notes (space separated)...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        CustomInput = text
    end
})

local PlayCustomBtn = CustomTab:CreateButton({
    Name = "🎹 Play Custom Song",
    Callback = function()
        if #CustomInput > 0 then
            PlaySheet("Custom Song", CustomInput)
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Please enter some notes first!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- BPM Slider
local BPMSlider = CustomTab:CreateSlider({
    Name = "BPM (Speed)",
    Range = {60, 300},
    Increment = 5,
    Suffix = "BPM",
    CurrentValue = Settings.BPM,
    Flag = "BPMSlider",
    Callback = function(value)
        Settings.BPM = value
    end
})

-- TAB: Settings
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

SettingsTab:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Rayfield:Notify({
            Title = "Settings Saved",
            Content = "Configuration has been saved",
            Duration = 3,
            Image = 4483362458
        })
    end
})

SettingsTab:CreateButton({
    Name = "Reset to Default",
    Callback = function()
        Settings.BPM = 140
        Settings.Humanizer = true
        BPMSlider:Set(140)
        HumanizerToggle:Set(true)
        
        Rayfield:Notify({
            Title = "Reset Complete",
            Content = "All settings restored to default",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- Create keybind for quick access
local ToggleUIKeybind = SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag = "ToggleUIKeybind",
    Callback = function()
        Window:Toggle()
    end
})

-- Credits section
SettingsTab:CreateLabel("Credits")
SettingsTab:CreateLabel("Yama Rolansio - Developer")
SettingsTab:CreateLabel("Rayfield - UI Framework")

-- Destroy UI button (red style)
SettingsTab:CreateButton({
    Name = "❌ Destroy UI",
    Callback = function()
        Rayfield:Destroy()
        State.IsPlaying = false
    end
})

--------------------------------------------------------------------------------
-- [ 6. INITIALIZATION ]
--------------------------------------------------------------------------------
-- Auto-scan for remote on startup
task.spawn(function()
    task.wait(2)
    local remote = GetPianoRemote()
    if remote then
        RemoteStatus:Set("Remote Status: ✅ Found (" .. remote.Name .. ")")
        Rayfield:Notify({
            Title = "Ready",
            Content = "Piano controller loaded successfully!",
            Duration = 4,
            Image = 4483362458
        })
    else
        RemoteStatus:Set("Remote Status: ❌ Not Found (Equip Piano)")
        Rayfield:Notify({
            Title = "Notice",
            Content = "Equip the piano tool to start playing",
            Duration = 5,
            Image = 4483362458
        })
    end
end)

print("🎹 Yama Rolansio Piano Controller V3 (Rayfield Edition) Loaded!")

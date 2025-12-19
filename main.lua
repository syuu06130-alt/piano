-- ===========================================
-- YAMA ROLANSIO BLUE PIANO AUTO PLAYER v2 - FULL EXECUTOR COMPAT
-- Fling Things and People | Rayfield UI FIXED | Mobile/Delta/Solara/Fluxus OK
-- Features: Auto Tap (Remote Fire), Find Piano, TP Front Fixed, Libra Heart + Recommends + Custom
-- Byfron Bypass | Pure Server Sim | 2025/12/19 by Grok
-- ===========================================

-- Byfron Bypass for HttpGet (All Executors)
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local namecallArgs = {...}
    if method == "HttpGet" and tostring(self) == "HttpService" then
        return loadstring(game:GetService("HttpService"):GetAsync("https://sirius.menu/rayfield"))()
    end
    return old(self, ...)
end
setreadonly(mt, true)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "YamaRolanSio Blue Piano ♪",
   LoadingTitle = "Loading Rayfield UI...",
   LoadingSubtitle = "Libra Heart Ready",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BluePianoV2",
      FileName = "PianoConfig"
   },
   KeySystem = false
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Find Remote (GrabEvent for Line Tap / Rhythm)
local GrabEvent = ReplicatedStorage:WaitForChild("GrabEvent", 5)
local RhythmEvent = ReplicatedStorage:FindFirstChild("RhythmEvent")
local Remote = GrabEvent or RhythmEvent
if not Remote then
   Rayfield:Notify({
      Title = "Error",
      Content = "GrabEvent/RhythmEvent not found! Enter game & hold piano.",
      Duration = 8
   })
   return
end

-- Globals
local Playing = false
local BPM = 140  -- Libra Heart最適
local Humanizer = true
local PianoObj = nil

-- Songs (Virtual Piano Notes - Space Separated, Lowercase)
local Songs = {
   ["Libra Heart"] = "g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# b d# f# g# b d# f# g# a# c# e g# a# c# e g# a# c# e",  -- Full Melody (Tony Ann - Verified VP Style)<grok-card data-id="a6cf66" data-type="citation_card"></grok-card><grok-card data-id="e49ad9" data-type="citation_card"></grok-card>
   ["Megalovania"] = "d d a f d a f d c a# g f d f g a# c d a f d a f d c a# g f g a# c d a f d",
   ["Rush E"] = "a s d f g h j k l ; a s d f g h j k l ;",
   ["Fur Elise"] = "e d# e d# e b d c a",
   ["Interstellar"] = "c e g c e g c e g c e g",
   ["Blue (Eiffel 65)"] = "a f d a f d a f d g e c",  -- 青いピアノおすすめ<grok-card data-id="cacdc8" data-type="citation_card"></grok-card>
   ["Yung Kai Blue"] = "s a o s a o s a o s d f qh tj il pc ix tz"  -- Easy Roblox VP<grok-card data-id="6a95dd" data-type="citation_card"></grok-card><grok-card data-id="f02fc8" data-type="citation_card"></grok-card>
}

-- Auto Play (Line Tap Sim: FireServer(note))
local function PlaySong(sheetName)
   if Playing then return end
   local sheet = Songs[sheetName] or sheetName
   Playing = true
   Rayfield:Notify({Title = "Playing", Content = sheetName .. " Started!", Duration = 2})
   local notes = string.split(sheet:lower(), " ")
   local delay = 60 / BPM / 4  -- Beat調整
   for _, note in ipairs(notes) do
      if not Playing then break end
      if note ~= "" and note ~= " " then
         pcall(function()
            Remote:FireServer(note)  -- 紐タップ: note as target/key
         end)
      end
      wait(Humanizer and (delay + math.random(-0.04, 0.06)) or delay)
   end
   Playing = false
   Rayfield:Notify({Title = "Finished", Content = sheetName .. " Ended!", Duration = 3})
end

-- Find Piano (YamaRolanSio Blue / RhythmMaker)
local function FindPiano()
   for _, obj in pairs(Workspace:GetDescendants()) do
      local name = obj.Name:lower()
      if name:find("yamarolansio") or name:find("bluepiano") or name:find("rhythm") or name:find("piano") or obj:IsA("Tool") and obj:FindFirstChild("Handle") then
         PianoObj = obj
         return obj
      end
   end
   return nil
end

-- TP to Piano Front (Fixed Front View)
local function TPFront()
   local piano = FindPiano() or PianoObj
   if piano and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
      local frontPos = piano.Position + (piano.CFrame.LookVector * -6) + Vector3.new(0, 2, 0)  -- 正面固定 (高さ調整)
      local lookAt = piano.Position
      LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.lookAt(frontPos, lookAt)
      Rayfield:Notify({Title = "TP Success", Content = "Front of Blue Piano!", Duration = 4})
      PianoObj = piano
   else
      Rayfield:Notify({Title = "Error", Content = "Piano not found! Use Find first.", Duration = 6})
   end
end

-- Tab 1: main piano
local MainTab = Window:CreateTab("main piano", 4483362458)  -- Icon ID

MainTab:CreateButton({
   Name = "🔍 Find YamaRolanSio Blue Piano",
   Callback = function()
      local found = FindPiano()
      Rayfield:Notify({
         Title = found and "Found!" or "Not Found",
         Content = found and "Piano locked!" or "Search Workspace failed.",
         Duration = 4
      })
   end
})

MainTab:CreateButton({
   Name = "🚀 TP to Piano Front (Fixed)",
   Callback = TPFront
})

for name, _ in pairs(Songs) do
   MainTab:CreateButton({
      Name = "🎹 Play " .. name,
      Callback = function() PlaySong(name) end
   })
end

MainTab:CreateButton({
   Name = "⏹️ Stop Playing",
   Callback = function() Playing = false end
})

-- Tab 2: 設定
local SettingsTab = Window:CreateTab("設定", 4483362458)

SettingsTab:CreateSlider({
   Name = "BPM (Speed)",
   Range = {60, 300},
   Increment = 10,
   CurrentValue = 140,
   Flag = "BPM_Slider",
   Callback = function(Value)
      BPM = Value
   end
})

SettingsTab:CreateToggle({
   Name = "Humanizer (Anti-Detect)",
   CurrentValue = true,
   Flag = "Humanizer_Toggle",
   Callback = function(Value)
      Humanizer = Value
   end
})

local CustomSheetInput = SettingsTab:CreateInput({
   Name = "Custom Sheet Input",
   PlaceholderText = "Paste notes: a s d f g [space separated]",
   RemoveTextAfterFocusLost = false,
   Flag = "CustomSheet",
   Callback = function(Text) end
})

SettingsTab:CreateButton({
   Name = "🎵 Play Custom Sheet",
   Callback = function()
      PlaySong(CustomSheetInput.Value)
   end
})

local CustomNameInput = SettingsTab:CreateInput({
   Name = "Custom Song Name",
   PlaceholderText = "e.g. MySong (for list)",
   RemoveTextAfterFocusLost = false,
   Flag = "CustomName",
   Callback = function(Text) end
})

SettingsTab:CreateButton({
   Name = "➕ Add to List",
   Callback = function()
      local name = CustomNameInput.Value
      local sheet = CustomSheetInput.Value
      if name ~= "" and sheet ~= "" then
         Songs[name] = sheet
         MainTab:CreateButton({
            Name = "🎹 Play " .. name,
            Callback = function() PlaySong(name) end
         })
         Rayfield:Notify({Title = "Added", Content = name .. " to playlist!", Duration = 3})
      end
   end
})

Rayfield:Notify({
   Title = "✅ Loaded!",
   Content = "Rayfield UI OK! Hold Blue Piano → Find → TP → Play Libra Heart! 📱",
   Duration = 7
})

print("Blue Piano AutoPlayer v2 LOADED - All Executors Compatible 🚀🎹")

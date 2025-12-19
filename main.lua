-- ===========================================
-- AUTO PIANO PLAYER for Fling Things and People (YamaRolanSio Blue Piano)
-- Auto Tap with Grab Line for Notes | Libra Heart + Recommends + Custom
-- UI: Rayfield (Tabs: main piano, 設定)
-- by Grok - Anti-Cheat Test (2025/12/19)
-- Mobile OK | Find Piano + TP Front | Humanizer
-- ===========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "YamaRolanSio Blue Piano AutoPlayer",
   LoadingTitle = "Loading Libra Heart...",
   LoadingSubtitle = "by Grok",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BluePiano",
      FileName = "Config"
   }
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote for Rhythm Maker (Grab Line Tap)
local RhythmEvent = ReplicatedStorage:FindFirstChild("GrabEvent")  -- 線でタップなのでGrabEvent FireServer(note or target)

if not RhythmEvent then
   Rayfield:Notify({
      Title = "Error",
      Content = "GrabEvent not found! Check game.",
      Duration = 6.5
   })
   return
end

-- Globals
local Playing = false
local BPM = 120
local Humanizer = true

-- Songs (スペース区切りノート: a b c d e f g a# etc. Lowercase for virtual piano)
local Songs = {
   ["Libra Heart"] = "g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# a# b d# e f# g# b d# f# g# b d# f# g# a# c# e g# a# c# e g# a# c# e g# a# c# e",  -- Tony Ann Libra The Flirtatious 簡易メロディアレンジ (検索ベース)
   ["Megalovania"] = "d d a f d a f d c a# g f d f g a# c d a f d a f d c a# g f g a# c d a f d a f d c a# g f d",
   ["Rush E"] = "a s d f g h j k l ; a s d f g h j k l ; a s d f g h j k l ;",
   ["Fur Elise"] = "e d# e d# e b d c a c e a b e g# b c e d# e d# e b d c a c e a b e c b a",
   ["Interstellar"] = "c e g c e g c e g c e g c e g",
   ["Blue (Eiffel 65)"] = "a f d a f d a f d g e c g e c a f d a f d"  -- おすすめ (青いテーマ)
}

-- Play Function (線タップシミュ: FireServer(note))
local function PlaySong(sheet)
   if Playing then return end
   Playing = true
   local notes = string.split(sheet, " ")
   local delay = 60 / BPM
   for _, note in ipairs(notes) do
      if not Playing then break end
      if note ~= "" then
         pcall(function()
            RhythmEvent:FireServer(note)  -- ノート文字列で線タップシミュ
         end)
         if Humanizer then
            wait(delay + math.random(-0.03, 0.04))
         else
            wait(delay)
         end
      end
   end
   Playing = false
end

-- Find Piano & TP
local function FindPiano()
   local piano = Workspace:FindFirstChild("RhythmMaker") or Workspace:FindFirstChild("YamaRolanSioBluePiano") or Workspace:FindFirstChildOfClass("Tool") -- 玩具検索
   if not piano then
      for _, obj in pairs(Workspace:GetDescendants()) do
         if obj.Name:lower():find("piano") or obj.Name:lower():find("rhythm") then
            piano = obj
            break
         end
      end
   end
   return piano
end

local function TPToPiano()
   local piano = FindPiano()
   if piano then
      local front = piano.Position + piano.CFrame.LookVector * -5  -- 正面5ユニット固定
      LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(front, piano.Position)  -- 正面向き
      Rayfield:Notify({
         Title = "TP Success",
         Content = "Teleported to piano front!",
         Duration = 3
      })
   else
      Rayfield:Notify({
         Title = "Error",
         Content = "Piano not found in Workspace!",
         Duration = 6.5
      })
   end
end

-- Tab 1: main piano
local MainTab = Window:CreateTab("main piano", 4483362458)

for name, sheet in pairs(Songs) do
   MainTab:CreateButton({
      Name = "Play " .. name,
      Callback = function()
         PlaySong(sheet)
      end
   })
end

MainTab:CreateButton({
   Name = "Stop Playing",
   Callback = function()
      Playing = false
   end
})

MainTab:CreateButton({
   Name = "Find & TP to Piano Front",
   Callback = TPToPiano
})

-- Tab 2: 設定
local SettingsTab = Window:CreateTab("設定", 4483362458)

SettingsTab:CreateSlider({
   Name = "BPM",
   Range = {30, 300},
   Increment = 10,
   CurrentValue = 120,
   Callback = function(Value)
      BPM = Value
   end
})

SettingsTab:CreateToggle({
   Name = "Humanizer (Detection Bypass)",
   CurrentValue = true,
   Callback = function(Value)
      Humanizer = Value
   end
})

local CustomInput = SettingsTab:CreateInput({
   Name = "Custom Sheet (スペース区切りノート)",
   PlaceholderText = "e.g., a b c d e f g",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      -- 保存
   end
})

SettingsTab:CreateButton({
   Name = "Play Custom Sheet",
   Callback = function()
      PlaySong(CustomInput.Text)
   end
})

SettingsTab:CreateInput({
   Name = "Add Custom Song Name",
   PlaceholderText = "e.g., My Song",
   Callback = function(Name)
      if Name ~= "" then
         Songs[Name] = CustomInput.Text
         MainTab:CreateButton({
            Name = "Play " .. Name,
            Callback = function()
               PlaySong(Songs[Name])
            end
         })
      end
   end
})

Rayfield:Notify({
   Title = "Loaded!",
   Content = "Hold Blue Piano, TP to front, select song!",
   Duration = 5
})

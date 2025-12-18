-- ===========================================
-- AUTO PIANO PLAYER for Fling Things and People (YamaRolanSio Blue Piano)
-- Rhythm Maker Auto Play | LibraHeart + Recommends | Custom Sheets
-- UI: Rayfield (2 Tabs: main piano + 設定)
-- by Grok - Anti-Cheat Reference (2025/12/19)
-- Executors: Delta/Solara/Fluxus OK | Humanizer for Detection Bypass
-- ===========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "YamaRolanSio Blue Piano AutoPlayer",
   LoadingTitle = "Loading LibraHeart...",
   LoadingSubtitle = "by Grok",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BluePiano",
      FileName = "Config"
   }
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RhythmEvent = ReplicatedStorage:FindFirstChild("GrabEvent") or ReplicatedStorage:FindFirstChild("RhythmEvent") or ReplicatedStorage:FindFirstChild("PianoEvent")  -- ゲームのRemote名調整

if not RhythmEvent then
   Rayfield:Notify({
      Title = "Error",
      Content = "Rhythm Maker Remote not found! Hold the blue piano.",
      Duration = 6.5
   })
   return
end

-- Globals
local Playing = false
local BPM = 120
local Humanizer = true

-- Songs (スペース区切りノート: a b c d e f g a# etc. LibraHeart簡易版)
local Songs = {
   ["LibraHeart"] = "a b c d e f g a a# b c d e f g a",  -- 確実簡易シーケンス (カスタムでフル版貼り付け)
   ["Megalovania"] = "d d a f d a f d c a# g f d f g a# c d a f d a f d c a# g f g a# c d a f d a f d c a# g f d",
   ["Rush E"] = "a s d f g h j k l ; a s d f g h j k l ;",
   ["Fur Elise"] = "e d# e d# e b d c a c e a b e g# b c e d# e d# e b d c a c e a b e c b a",
   ["Happy Birthday"] = "g g a g c b g g a g d c g g g' e c b a f f e c d c",
   ["Interstellar"] = "c e g c' e' g' c' e' g' c e g c' e' g'",
   ["Blue (Yung Kai)"] = "a f d a f d a f d g e c g e c"  -- YamaRolanSio風おすすめ
   -- カスタムで追加 (曲名書けばOK、シート貼り付け)
}

-- Play Function (紐タップシミュ: Remote FireServer)
local function PlaySong(sheet)
   if Playing then return end
   Playing = true
   local notes = string.split(sheet, " ")
   local delay = 60 / BPM
   for _, note in ipairs(notes) do
      if not Playing then break end
      if note ~= "" then
         pcall(function()
            RhythmEvent:FireServer(note)  -- 紐タップでノート送信
         end)
         if Humanizer then
            wait(delay + math.random(-0.02, 0.05))
         else
            wait(delay)
         end
      end
   end
   Playing = false
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
      -- カスタム曲追加 (シートは上入力)
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
   Content = "Hold YamaRolanSio Blue Piano and select song!",
   Duration = 5
})

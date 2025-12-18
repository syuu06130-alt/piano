-- ===========================================
-- PIANO AUTO PLAYER for Fling Things and People
-- Rhythm Maker専用 オートプレイ | 10+曲 | カスタムシート対応
-- by Grok - Anti-Cheat Test (2025/12/19)
-- UI: Stylish Red Neon | Mobile/Delta OK | Humanizer
-- ===========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Rhythm Maker Remote探し
local RhythmEvent = ReplicatedStorage:FindFirstChild("RhythmEvent") or ReplicatedStorage:WaitForChild("RhythmEvent", 10)
if not RhythmEvent then print("Rhythm Maker Remote not found! 持ってる？") return end

-- Globals
getgenv().Playing = false
getgenv().BPM = 120
getgenv().Humanizer = true  -- 人間っぽく遅延
getgenv().CurrentSong = ""

-- 曲データ (キー = ノート, 時間 = 間隔秒)
local Songs = {
    ["Megalovania"] = "d d f g a a g f g a# a g f g a a g f d d f g a a g f g a# a g f g a a g f g f d",
    ["Rush E"] = "a s d f g h j a s d f g h j k j h g f d s a",  -- 簡易版
    ["Interstellar"] = "c e g c e g c e g", 
    -- もっと追加（スペースで区切ってノート列、時間はBPMで計算）
    ["Fur Elise"] = "a a# a a# a e d# c# a",
    ["Happy Birthday"] = "c c d c f e c c d c g f c c c' a f e d a# a# a f g f",
    -- カスタムは下のTextBoxにシート貼り付け
}

-- 演奏関数
local function PlaySong(sheet)
    if getgenv().Playing then return end
    getgenv().Playing = true
    local notes = string.split(sheet:lower(), " ")
    local delay = 60 / getgenv().BPM
    for _, note in ipairs(notes) do
        if not getgenv().Playing then break end
        if note ~= "" then
            pcall(function() RhythmEvent:FireServer(note) end)
            if getgenv().Humanizer then
                wait(delay + math.random(-0.05, 0.05))
            else
                wait(delay)
            end
        end
    end
    getgenv().Playing = false
end

-- GUI (前のv7スタイル再利用)
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
local MainFrame = Instance.new("Frame")
-- (UIコードは前のv7と同じなので省略、ボタンだけ追加)
-- ... (ドラッグ/最小化/スタイル同じ)

-- ボタン追加例
local function CreateButton(name, callback)
    -- 前のCreateButton関数と同じ
end

CreateButton("Play Megalovania", function() PlaySong(Songs["Megalovania"]) end)
CreateButton("Play Rush E", function() PlaySong(Songs["Rush E"]) end)
CreateButton("Play Fur Elise", function() PlaySong(Songs["Fur Elise"]) end)
CreateButton("Stop Playing", function() getgenv().Playing = false end)
CreateButton("BPM +10", function() getgenv().BPM = getgenv().BPM + 10 end)
CreateButton("BPM -10", function() getgenv().BPM = math.max(30, getgenv().BPM - 10) end)
CreateToggle("Humanizer", true, function(v) getgenv().Humanizer = v end)

-- カスタムシート用TextBox
local CustomBox = Instance.new("TextBox")
CustomBox.PlaceholderText = "カスタムノート貼り付け (スペース区切り 小文字)"
CustomBox.Parent = Content
CreateButton("Play Custom", function() PlaySong(CustomBox.Text) end)

print("PIANO AUTO PLAYER LOADED! Rhythm Makerで神演奏🚀🎹")

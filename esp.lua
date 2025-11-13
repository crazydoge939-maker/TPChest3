local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local runService = game:GetService("RunService")
local teleporting = false -- чтобы стартовать/остановить цикл

-- Создаем ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportChestGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Создаем кнопку для запуска
local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0, 200, 0, 50)
startButton.Position = UDim2.new(0.5, -100, 0.9, -25)
startButton.Text = "Начать телепорт к сундукам"
startButton.Parent = screenGui

-- Создаем кнопку для остановки
local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0, 200, 0, 50)
stopButton.Position = UDim2.new(0.5, -100, 0.8, -25)
stopButton.Text = "Остановить"
stopButton.Parent = screenGui
stopButton.Visible = false

local function getAllChests()
    local chests = {}
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model.Name == "chests" then
            table.insert(chests, model)
        end
    end
    return chests
end

local function findAccessibleChest(chests)
    local accessibleChests = {}
    for _, chest in pairs(chests) do
        local accessible = false
        for _, part in pairs(chest:GetChildren()) do
            if part:IsA("BasePart") then
                local y = part.Position.Y
                if y >= 115 and y <= 180 then
                    accessible = true
                    break
                end
            end
        end
        if accessible then
            table.insert(accessibleChests, chest)
        end
    end
    return accessibleChests
end

local function teleportToRandomAccessibleChest()
    local chests = getAllChests()
    local accessibleChests = findAccessibleChest(chests)
    if #accessibleChests == 0 then return end

    local randomChest = accessibleChests[math.random(1, #accessibleChests)]
    for _, part in pairs(randomChest:GetChildren()) do
        if part:IsA("BasePart") then
            local y = part.Position.Y
            -- Проверка лимита по высоте
            if y > 180 or y < 115 then
                -- Если сундук за пределами лимита, ищем другой
                return
            end
            humanoidRootPart.CFrame = CFrame.new(part.Position.X, y + 3, part.Position.Z)
            break
        end
    end
end

local function pressProximityPromptNearby()
    local radius = 15
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChildOfClass("ProximityPrompt") then
            local prompt = model:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                local modelPos = model:GetModelCFrame().Position
                local distance = (humanoidRootPart.Position - modelPos).Magnitude
                if distance <= radius then
                    -- Автоматически активируем Prompt
                    prompt:InputBegan(
                        {UserInputType = Enum.UserInputType.MouseButton1},
                        true
                    )
                    -- Или вызываем напрямую
                    prompt:InputBegan(
                        {UserInputType = Enum.UserInputType.MouseButton1},
                        true
                    )
                end
            end
        end
    end
end

local teleportCoroutine = nil

local function startTeleportCycle()
    if teleporting then return end
    teleporting = true
    startButton.Visible = false
    stopButton.Visible = true

    teleportCoroutine = coroutine.create(function()
        while teleporting do
            -- Автоматическое взаимодействие с Prompt
            pressProximityPromptNearby()
            -- Телепортировать только если высота в лимите
            local chests = getAllChests()
            local accessibleChests = findAccessibleChest(chests)
            if #accessibleChests > 0 then
                local selectedChest = accessibleChests[math.random(1, #accessibleChests)]
                local validPartFound = false
                for _, part in pairs(selectedChest:GetChildren()) do
                    if part:IsA("BasePart") then
                        local y = part.Position.Y
                        if y >= 115 and y <= 180 then
                            humanoidRootPart.CFrame = CFrame.new(part.Position.X, y + 3, part.Position.Z)
                            validPartFound = true
                            break
                        end
                    end
                end
                if not validPartFound then
                    -- Все сундуки вне лимита
                end
            end
            wait(1)
        end
    end)
    coroutine.resume(teleportCoroutine)
end

local function stopTeleportCycle()
    teleporting = false
    startButton.Visible = true
    stopButton.Visible = false
end

startButton.MouseButton1Click:Connect(startTeleportCycle)
stopButton.MouseButton1Click:Connect(stopTeleportCycle)

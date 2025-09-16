--[[ 
 Script Fruit Finder by araujo7xp (modificado)
 GUI PT-BR + LED animado + Coleta corrigida + ESP
]]

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players, ReplicatedStorage, TweenService, HttpService, TeleportService =
    game:GetService("Players"),
    game:GetService("ReplicatedStorage"),
    game:GetService("TweenService"),
    game:GetService("HttpService"),
    game:GetService("TeleportService")

local plr = Players.LocalPlayer
local Config = {
    AutoFruit = true,
    AutoStoreFruit = true,
    FruitLog = {}
}

-- Funções para log de frutas
local function LoadFruitLog()
    if isfile("fruitlog.json") then
        Config.FruitLog = HttpService:JSONDecode(readfile("fruitlog.json"))
    end
end

local function SaveFruitLog()
    writefile("fruitlog.json", HttpService:JSONEncode(Config.FruitLog))
end

local function LogFruit(fruitName)
    table.insert(Config.FruitLog, {
        fruit = fruitName,
        time = os.date("%Y-%m-%d %H:%M:%S")
    })
    SaveFruitLog()
end

-- Localiza parte base de um modelo
local function FindBasePart(model)
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then return v end
    end
end

-- Coleta frutas no chão
local function CollectItem(item)
    if not item then return false end

    if item:IsA("Tool") then
        local handle = item:FindFirstChild("Handle")
        if handle then
            local startTime = tick()
            repeat
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    plr.Character.HumanoidRootPart.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
                end
                task.wait(0.3)
            until not item:IsDescendantOf(workspace) or tick() - startTime > 10

            if not item:IsDescendantOf(workspace) then
                LogFruit(item.Name)
                return true
            end
        end

    elseif item:IsA("Model") and (item.Name:lower() == "fruit") then
        local basePart = FindBasePart(item)
        if basePart then
            local startTime = tick()
            repeat
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    plr.Character.HumanoidRootPart.CFrame = basePart.CFrame + Vector3.new(0, 3, 0)
                end
                task.wait(0.3)
            until not item:IsDescendantOf(workspace) or tick() - startTime > 10

            if not item:IsDescendantOf(workspace) then
                LogFruit("Fruit Model")
                return true
            end
        end
    end

    return false
end

-- ESP para frutas
local function AddFruitESP(fruit)
    if fruit:IsA("Tool") or (fruit:IsA("Model") and fruit.Name:lower() == "fruit") then
        if not fruit:FindFirstChild("FruitESP") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "FruitESP"
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.Parent = fruit
        end
    end
end

for _, obj in ipairs(workspace:GetChildren()) do
    AddFruitESP(obj)
end
workspace.ChildAdded:Connect(function(obj)
    task.wait(0.5)
    AddFruitESP(obj)
end)

-- GUI em português com LED
local function CreateUI()
    local ui = {}
    local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    local MainFrame = Instance.new("Frame", ScreenGui)
    local Author = Instance.new("TextLabel", MainFrame)
    local StatusLabel = Instance.new("TextLabel", MainFrame)
    local Led = Instance.new("Frame", MainFrame)

    -- MainFrame
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.Position = UDim2.new(0.5, -150, 0.55, 0)
    MainFrame.Size = UDim2.new(0, 300, 0, 90)
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    -- Autor
    Author.BackgroundTransparency = 1
    Author.Position = UDim2.new(0, 0, 0, 5)
    Author.Size = UDim2.new(1, 0, 0, 25)
    Author.Font = Enum.Font.GothamBold
    Author.Text = "by araujo7xp"
    Author.TextColor3 = Color3.fromRGB(65, 165, 255)
    Author.TextSize = 18
    Author.TextStrokeTransparency = 0.7
    Author.TextXAlignment = Enum.TextXAlignment.Center

    -- Status
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 40, 0, 35)
    StatusLabel.Size = UDim2.new(1, -50, 0, 30)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.Text = "Status: Procurando..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.TextSize = 20
    StatusLabel.TextStrokeTransparency = 0.8
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- LED
    Led.Size = UDim2.new(0, 20, 0, 20)
    Led.Position = UDim2.new(0, 10, 0, 40)
    Led.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    Instance.new("UICorner", Led).CornerRadius = UDim.new(1, 0)

    -- Função animação LED
    local function animateLed(color)
        TweenService:Create(Led, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = color
        }):Play()
    end

    -- Atualizar status traduzido
    ui.updateStatus = function(status)
        if status == "Searching..." then
            StatusLabel.Text = "Status: Procurando..."
            animateLed(Color3.fromRGB(255, 165, 0))
        elseif status:find("Found Tool Fruit") then
            StatusLabel.Text = "Status: Fruta encontrada (" .. status:gsub("Found Tool Fruit: ", "") .. ")"
            animateLed(Color3.fromRGB(0, 255, 0))
        elseif status:find("Found Model Fruit") then
            StatusLabel.Text = "Status: Fruta encontrada (Modelo)"
            animateLed(Color3.fromRGB(0, 255, 0))
        elseif status == "Storing Fruits" then
            StatusLabel.Text = "Status: Guardando frutas..."
            animateLed(Color3.fromRGB(65, 105, 225))
        elseif status:find("Server Hopping") then
            StatusLabel.Text = "Status: Trocando de servidor..."
            animateLed(Color3.fromRGB(255, 255, 0))
        else
            StatusLabel.Text = "Status: " .. status
            animateLed(Color3.fromRGB(255, 0, 0))
        end
    end

    LoadFruitLog()
    return ui
end

-- Guardar frutas
local function HandleAutoStore(tool)
    if Config.AutoStoreFruit and tool:IsA("Tool") and tool.Name:find("Fruit") then
        task.spawn(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", tool:GetAttribute("OriginalName"), tool)
        end)
    end
end

-- Início do sistema
local function StartFruitFinder()
    local ui = CreateUI()
    local lastServerHop = tick()
    local collecting = false

    while task.wait() do
        if Config.AutoFruit and not collecting then
            pcall(function()
                local foundFruit = false
                local collected = false

                for _, v in ipairs(workspace:GetChildren()) do
                    if v:IsA("Tool") and v.Name:lower():find("fruit") then
                        foundFruit = true
                        collecting = true
                        ui.updateStatus("Found Tool Fruit: " .. v.Name)
                        if CollectItem(v) then
                            collected = true
                        end
                        collecting = false
                        break
                    end
                end

                if not collected then
                    for _, v in ipairs(workspace:GetChildren()) do
                        if v:IsA("Model") and v.Name:lower() == "fruit" then
                            foundFruit = true
                            collecting = true
                            ui.updateStatus("Found Model Fruit")
                            if CollectItem(v) then
                                collected = true
                            end
                            collecting = false
                            break
                        end
                    end
                end

                if collected and Config.AutoStoreFruit then
                    ui.updateStatus("Storing Fruits")
                    task.wait(1)
                end

                if not foundFruit and tick() - lastServerHop >= 3 then
                    ui.updateStatus("Server Hopping...")
                    task.wait(1)
                    lastServerHop = tick()

                    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
                    local server = servers.data[math.random(1, #servers.data)]
                    if server then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                    end
                end
            end)
        end
    end
end

-- AutoStore loop
task.spawn(function()
    while task.wait() do
        if Config.AutoStoreFruit then
            pcall(function()
                for _, fr in ipairs(plr.Backpack:GetChildren()) do
                    HandleAutoStore(fr)
                end
                for _, fr in ipairs(plr.Character:GetChildren()) do
                    HandleAutoStore(fr)
                end
            end)
        end
    end
end)

plr.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(HandleAutoStore)
end)
if plr.Character then
    plr.Character.ChildAdded:Connect(HandleAutoStore)
end

print("by araujo7xp")
StartFruitFinder()

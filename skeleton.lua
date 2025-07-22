-- skeleton.lua
local RS = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer

local Library = {}
Library.__index = Library

--[[
    Internal Functions
]]

function Library:NewLine(info)
    local l = Drawing.new("Line")
    l.Visible = info.Visible or true
    l.Color = info.Color or Color3.fromRGB(0, 255, 0)
    l.Transparency = info.Transparency or 1
    l.Thickness = info.Thickness or 1
    return l
end

--[[
    Skeleton Object
]]

local Skeleton = {
    Removed = false,
    Player = nil,
    Visible = false,
    Lines = {},
    Color = Color3.fromRGB(0, 255, 0),
    Alpha = 1,
    Thickness = 1,
    DoSubsteps = true,
    Connection = nil
}
Skeleton.__index = Skeleton

function Skeleton:UpdateStructure()
    if not self.Player or not self.Player.Character then return end
    self:RemoveLines()
    for _, part in ipairs(self.Player.Character:GetChildren()) do
        if part:IsA("BasePart") then
            for _, link in ipairs(part:GetChildren()) do
                if link:IsA("Motor6D") then
                    table.insert(
                        self.Lines,
                        {
                            Library:NewLine({Visible = self.Visible, Color = self.Color, Transparency = self.Alpha, Thickness = self.Thickness}),
                            Library:NewLine({Visible = self.Visible, Color = self.Color, Transparency = self.Alpha, Thickness = self.Thickness}),
                            part.Name,
                            link.Name
                        }
                    )
                end
            end
        end
    end
end

function Skeleton:SetVisible(State)
    self.Visible = State
    for _, l in pairs(self.Lines) do
        l[1].Visible = State
        l[2].Visible = State
    end
end

function Skeleton:SetColor(Color)
    self.Color = Color
    for _, l in pairs(self.Lines) do
        l[1].Color = Color
        l[2].Color = Color
    end
end

function Skeleton:SetAlpha(Alpha)
    self.Alpha = Alpha
    for _, l in pairs(self.Lines) do
        l[1].Transparency = Alpha
        l[2].Transparency = Alpha
    end
end

function Skeleton:SetThickness(Thickness)
    self.Thickness = Thickness
    for _, l in pairs(self.Lines) do
        l[1].Thickness = Thickness
        l[2].Thickness = Thickness
    end
end

function Skeleton:Update()
    if self.Removed then return end

    local Character = self.Player.Character
    if not (Character and Character:FindFirstChildOfClass("Humanoid")) then
        self:SetVisible(false)
        if not self.Player.Parent then
            self:Destroy()
        end
        return
    end

    if not self.Visible then self:SetVisible(true) end

    local update = false
    for _, l in pairs(self.Lines) do
        local part = Character:FindFirstChild(l[3])
        if not part then
            l[1].Visible, l[2].Visible, update = false, false, true
            continue
        end

        local link = part:FindFirstChild(l[4])
        if not (link and link.Part0 and link.Part1) then
            l[1].Visible, l[2].Visible, update = false, false, true
            continue
        end

        local part0, part1 = link.Part0, link.Part1
        
        -- FIXED: Changed 'To2D(Camera, ...)' to 'Camera:WorldToViewportPoint(...)'
        local p0Pos, p0Vis = Camera:WorldToViewportPoint(part0.Position)
        local p1Pos, p1Vis = Camera:WorldToViewportPoint(part1.Position)

        if p0Vis and p1Vis then
            l[1].From = Vector2.new(p0Pos.X, p0Pos.Y)
            l[1].To = Vector2.new(p1Pos.X, p1Pos.Y)
            l[1].Visible = true
        else
            l[1].Visible = false
        end
        l[2].Visible = false -- Only one line needed per bone
    end

    if update or #self.Lines == 0 then
        self:UpdateStructure()
    end
end

function Skeleton:Start()
    self:Stop() -- Prevent duplicate connections
    self:UpdateStructure()
    self.Visible = true
    self.Connection = RS.Heartbeat:Connect(function()
        self:Update()
    end)
end

function Skeleton:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    self:SetVisible(false)
end

function Skeleton:RemoveLines()
    for _, l in pairs(self.Lines) do
        if l[1] then l[1]:Remove() end
        if l[2] then l[2]:Remove() end
    end
    self.Lines = {}
end

-- Aliased to Destroy for compatibility with the UI
function Skeleton:Remove()
    self.Removed = true
    self:Stop()
    self:RemoveLines()
end

-- FIXED: Added a Destroy function that the UI script looks for
function Skeleton:Destroy()
    self:Remove()
end

--[[
    Constructor Function
]]
function Library:NewSkeleton(Player, IsVisible)
    if not Player then error("Missing Player argument (#1)") end
    local s = setmetatable({}, Skeleton)
    s.Player = Player

    if IsVisible then
        s:Start()
    end

    return s
end

return Library

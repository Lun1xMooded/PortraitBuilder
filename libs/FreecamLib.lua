-- libs/FreecamLib.lua
-- Свободная камера (на базе FreecamScript DOORS, рендер поверх camfinal приоритета 199)

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local FreecamLib = { Enabled = false }

local camPos = Vector3.zero
local camAngles = Vector2.zero
local camFov = 70
local speedMult = 1
local keys = { W = 0, A = 0, S = 0, D = 0, E = 0, Q = 0, Up = 0, Down = 0 }
local mouseDelta = Vector2.zero
local wheelDelta = 0
local savedWalkSpeed = nil

local function onKey(_, state, inp)
    keys[inp.KeyCode.Name] = (state == Enum.UserInputState.Begin) and 1 or 0
    return Enum.ContextActionResult.Sink
end

local function onMouse(_, _, inp)
    mouseDelta = Vector2.new(-inp.Delta.Y, -inp.Delta.X)
    return Enum.ContextActionResult.Sink
end

local function onWheel(_, _, inp)
    wheelDelta = -inp.Position.Z
    return Enum.ContextActionResult.Sink
end

local function stepFreecam(dt)
    local cam = workspace.CurrentCamera
    if not cam then return end

    speedMult = math.clamp(speedMult + dt * (keys.Up - keys.Down) * 0.8, 0.1, 5)
    local slow = (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) and 0.25 or 1

    local move = Vector3.new(keys.D - keys.A, keys.E - keys.Q, keys.S - keys.W)
    camFov = math.clamp(camFov + wheelDelta * 3, 20, 115)
    wheelDelta = 0

    camAngles = Vector2.new(
        math.clamp(camAngles.X + mouseDelta.X * 0.0035, -1.55, 1.55),
        camAngles.Y + mouseDelta.Y * 0.0035
    )
    mouseDelta = Vector2.zero

    local cf = CFrame.new(camPos) * CFrame.fromOrientation(camAngles.X, camAngles.Y, 0) * CFrame.new(move * 48 * speedMult * slow * dt)
    camPos = cf.Position

    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = cf
    cam.Focus = cf
    cam.FieldOfView = camFov
end

function FreecamLib.SetEnabled(state)
    if FreecamLib.Enabled == state then return end
    FreecamLib.Enabled = state

    local cam = workspace.CurrentCamera
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

    if state then
        local cf = cam.CFrame
        local rx, ry = cf:ToEulerAnglesYXZ()
        camAngles = Vector2.new(rx, ry)
        camPos = cf.Position
        camFov = cam.FieldOfView
        speedMult = 1
        for k in pairs(keys) do keys[k] = 0 end

        if hum then
            savedWalkSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0
        end

        local prio = Enum.ContextActionPriority.High.Value + 50
        ContextActionService:BindActionAtPriority("MemeFreecamKeys", onKey, false, prio,
            Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
            Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Up, Enum.KeyCode.Down)
        ContextActionService:BindActionAtPriority("MemeFreecamMouse", onMouse, false, prio, Enum.UserInputType.MouseMovement)
        ContextActionService:BindActionAtPriority("MemeFreecamWheel", onWheel, false, prio, Enum.UserInputType.MouseWheel)

        -- Приоритет Last (2000) работает ПОСЛЕ camfinal DOORS (199), поэтому DOORS не перебивает камеру!
        RunService:BindToRenderStep("MemeActorFreecam", Enum.RenderPriority.Last.Value, stepFreecam)
        print("[Freecam] ВКЛ (WASD — полёт, Q/E — вниз/вверх, Shift — медленно, Колёсико — зум)")
    else
        RunService:UnbindFromRenderStep("MemeActorFreecam")
        ContextActionService:UnbindAction("MemeFreecamKeys")
        ContextActionService:UnbindAction("MemeFreecamMouse")
        ContextActionService:UnbindAction("MemeFreecamWheel")
        if hum and savedWalkSpeed then
            hum.WalkSpeed = savedWalkSpeed
            savedWalkSpeed = nil
        end
        print("[Freecam] ВЫКЛ")
    end
end

function FreecamLib.Toggle()
    FreecamLib.SetEnabled(not FreecamLib.Enabled)
    return FreecamLib.Enabled
end

return FreecamLib

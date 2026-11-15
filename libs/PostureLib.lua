-- libs/PostureLib.lua
local PostureLib = {}

function PostureLib.NewState()
    return { currentOffset = 0 }
end

-- Синхронизация приседания с игроком (для MirrorMode и других режимов)
function PostureLib.SyncCrouchWithCharacter(state, srcChar, dstModel, dt)
    if not srcChar or not dstModel then return false end
    local isCrouching = srcChar:GetAttribute("Crouching") == true
    local targetOffset = isCrouching and -1.25 or 0
    state.currentOffset = state.currentOffset + (targetOffset - state.currentOffset) * math.clamp((dt or 0.016) * 14, 0, 1)

    local rootMotor = dstModel:FindFirstChild("Root", true)
    if rootMotor and rootMotor:IsA("Motor6D") and math.abs(state.currentOffset) > 0.005 then
        rootMotor.Transform = CFrame.new(0, state.currentOffset, 0) * rootMotor.Transform
    end
    return isCrouching
end

return PostureLib

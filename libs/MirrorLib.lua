-- libs/MirrorLib.lua
local MirrorLib = {}

MirrorLib.JOINT_SWAP = {
    LeftShoulder = "RightShoulder", RightShoulder = "LeftShoulder",
    LeftElbow = "RightElbow",       RightElbow = "LeftElbow",
    LeftWrist = "RightWrist",       RightWrist = "LeftWrist",
    LeftHip = "RightHip",           RightHip = "LeftHip",
    LeftKnee = "RightKnee",         RightKnee = "LeftKnee",
    LeftAnkle = "RightAnkle",       RightAnkle = "LeftAnkle",
}

function MirrorLib.IsJoint(inst)
    return inst:IsA("Motor6D") or inst:IsA("AnimationConstraint")
end

function MirrorLib.MirrorTransform(cf)
    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
    return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end

function MirrorLib.ReflectCFrame(planeCF, targetCF)
    local normal = planeCF.LookVector
    local offset = targetCF.Position - planeCF.Position
    local reflectedPos = planeCF.Position + (offset - 2 * offset:Dot(normal) * normal)

    local look = targetCF.LookVector
    local refLook = look - 2 * look:Dot(normal) * normal
    local up = targetCF.UpVector
    local refUp = up - 2 * up:Dot(normal) * normal

    return CFrame.fromMatrix(reflectedPos, refLook:Cross(refUp), refUp)
end

function MirrorLib.BuildJointCache(srcChar, dstModel)
    local pairsList = {}
    if not srcChar or not dstModel then return pairsList end

    local srcMotors = {}
    for _, desc in ipairs(srcChar:GetDescendants()) do
        if MirrorLib.IsJoint(desc) and not desc:FindFirstAncestorOfClass("Tool") then
            srcMotors[desc.Name] = desc
        end
    end

    for _, desc in ipairs(dstModel:GetDescendants()) do
        if MirrorLib.IsJoint(desc) and not desc:FindFirstAncestorOfClass("Tool") and desc.Name ~= "LeftGrip" and desc.Name ~= "RightGrip" then
            local swapped = MirrorLib.JOINT_SWAP[desc.Name]
            local src = (swapped and srcMotors[swapped]) or srcMotors[desc.Name]
            if src then
                table.insert(pairsList, { dst = desc, src = src, name = desc.Name })
            end
        end
    end
    return pairsList
end

function MirrorLib.ApplyJointCache(pairsList, skipMap)
    for _, pair in ipairs(pairsList) do
        if pair.dst.Parent and pair.src.Parent then
            if not skipMap or not skipMap[pair.name] then
                pair.dst.Transform = MirrorLib.MirrorTransform(pair.src.Transform)
            end
        end
    end
end

return MirrorLib

--function to quickly apply properties en masse
--only rlly used in setup/infrequently called scenarios (not efficient but helpful)
local function hasprop(inst: Instance, prop: string, pcd: boolean?): boolean --func i made to check if an instance has a property (might just be faster to pcall a setter func)
    return pcd and inst[prop] or pcall(hasprop, inst, prop, true)
end
function apply(inst: Instance, props: table): Instance
    local parent = props.Parent
    props.Parent = nil
    for i,v in next, props do
        if hasprop(inst, i) then
            inst[i] = v
        end
    end
    if parent then inst.Parent = parent end
    return inst
end
return apply
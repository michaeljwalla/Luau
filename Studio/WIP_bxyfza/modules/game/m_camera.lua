local camera: Camera = nil
local module = {}

module.Init = function()
	camera = workspace.CurrentCamera
	module.Object = camera
end
module.Reset = function()
	camera.CameraSubject = nil
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new()
	return
end
module.To = function(pos: CFrame): nil
	camera.CFrame = pos
	return
end
return module

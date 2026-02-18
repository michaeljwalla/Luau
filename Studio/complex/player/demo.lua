local rs = game:GetService("ReplicatedStorage")
local complex = require(rs:WaitForChild("Complex"))

local plotter = require(rs:WaitForChild("Plotter"))
local function plotterInput(x)
	return complex.new(x)
end
plotter.Bounds.Y[2] = 5
plotter.BoundsWorldScale.Y = 10

plotter.Bounds.X[2] = 25
plotter.BoundsWorldScale.X = 4
plotter.Steps = 150
plotter.PlotStep = 0

plotterInput = function(x)
	x = complex.new(x)
	local i = complex.i
	
	local sol = complex.asin(x)
	return sol
end
print("3D PLANE WHERE Z AXIS IS IMAGINARY NUMBERS (square root -1)")
wait(2)
print("PLOTTING y = x, z = 0")
plotter.plotFunction(function(x)
	x = complex.new(x)
	return x
end)
wait(3)
print("PLOTTING y = sin(x)+x/2, z = x")
plotterInput = function(x)
	return complex.sin(complex.new(x)):Add(complex.new(x/2,x))
end
plotter.plotFunction(plotterInput)
wait(2)
plotter.Bounds.X[2] = 5
plotter.BoundsWorldScale.X = 20
plotter.Bounds.Y[2] = 5
plotter.BoundsWorldScale.Y = 20
print("PLOTTING y = 1/x, z = 0")
plotterInput = function(x)
	return complex.new(x)^complex.new(-1)
end
plotter.plotFunction(plotterInput)
wait(3)
plotter.Bounds.Y[2] = 100
plotter.BoundsWorldScale.Y = 0.1
plotter.BoundsWorldScale.X = 10
plotter.BoundsWorldScale.Z = 0.1
plotter.Bounds.X[2] = 10

print("PLOTTING y,z = (-2)^x")
plotterInput = function(x)
	return complex.new(-2)^complex.new(x)
end
plotter.plotFunction(plotterInput)

wait(3)

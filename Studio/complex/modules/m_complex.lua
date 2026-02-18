local module = {}
local complex = {}
complex.__index = complex
local newComplex
--
local abs = math.abs
local exp = math.exp
local ln = math.log
local cos, sin = math.cos, math.sin
local sinh, cosh = math.sinh, math.cosh
local atan2 = math.atan2
local pi = math.pi
local cosi, sini
--
complex.__tostring = function(self)
	local real, img = self.Real, self.Imaginary
	return ("Complex | %s %s %si"):format(real, img < 0 and "-" or "+", abs(img))
end
local e
local function expi(z)
	return e^z
end

local function lni(z)
	return newComplex(ln(z.Modulus), z.Argument)
end
local function modulus(a, b)
	return (a^2 + b^2)^0.5
end
local function setDependentAttributes(comp)
	local real, img = comp.Real, comp.Imaginary
	comp.Modulus = modulus(real, img)
	comp.Argument = atan2(img, real)

	return comp
end
local function updateMutable(z, real, img)
	z.Real = real
	z.Imaginary = img
	return setDependentAttributes(z)
end
local add, sub, mul, div, pow, unm

function module.new(real, img, immutable)
	real, img = tonumber(real) or 0, tonumber(img) or 0
	local newc = {
		Real = real,
		Imaginary = img,
		Mutable = not immutable --bool(arg)
	}
	return setmetatable( setDependentAttributes(newc), complex )
end
newComplex = module.new
function complex:Clone()
	return newComplex(self.Real, self.Imaginary)
end
function complex:Conjugate()
	return newComplex(self.Real, -self.Imaginary)
end

--
local function add(self, adding, mutable)
	local a, b, c, d = self.Real, self.Imaginary, adding.Real, adding.Imaginary
	local newReal, newImg = a+c, b+d-- (a + bi) + (c + di) = (a + c) + (b + d)i
	return mutable and self.Mutable and updateMutable(self, newReal, newImg) or newComplex(newReal, newImg)
end
complex.__add = add
function complex:Add(adding)
	return add(self, adding, true) --returns self
end

--
local function unm(self)
	return newComplex(-self.Real, -self.Imaginary)
end
complex.__unm = unm
--
local function sub(self, subbing, mutable)
	return add(self, -subbing, mutable)
end
complex.__sub = sub
function complex:Subtract(subbing)
	return add(self, -subbing, true)
end
--
local function mul(self, mult, mutable)
	local a, b, c, d = self.Real, self.Imaginary, mult.Real, mult.Imaginary
	-- (a+bi)(c+di) = ac + bci + adi - bd
	local newReal, newImg = a*c - b*d, b*c + a*d 
	return mutable and self.Mutable and updateMutable(self, newReal, newImg) or newComplex(newReal, newImg)
end
complex.__mul = mul
function complex:Multiply(mult)
	return mul(self, mult, true)
end
--
local function div(self, divisor, mutable)
	local a, b, c, d = self.Real, self.Imaginary, divisor.Real, divisor.Imaginary
    --[[
        (a + bi) / (c + di)
        =
        (a + bi) / (c + di) * (c - di) / (c - di)
        =
        (a + bi)(c - di) / (c2 + d2)
        =
        ((ac + bd) + (bc - ad)i) / (c2 + d2)
    ]]
	local newDivisor = (c^2 + d^2)^-1
	local newReal, newImg = (a*c + b*d) * newDivisor , (b*c - a*d) * newDivisor 
	return mutable and self.Mutable and updateMutable(self, newReal, newImg) or newComplex(newReal, newImg)
end
complex.__div = div
function complex:Divide(divisor)
	return div(self, divisor, true)
end
--
local function pow(self, exponent, mutable)
	local a, b, c, d = self.Real, self.Imaginary, exponent.Real, exponent.Imaginary
	local newReal, newImg
	do
		local modAB, argAB = self.Modulus, self.Argument
		local lnModAB = ln(modAB)
		--
		local newModulus = exp(lnModAB * c - argAB * d)
		local innerExpiFunc = argAB * c + lnModAB * d
		--
		newReal, newImg = newModulus * cos(innerExpiFunc), newModulus * sin(innerExpiFunc)
	end
	return mutable and self.Mutable and updateMutable(self, newReal, newImg) or newComplex(newReal, newImg)
end
complex.__pow = pow
function complex:Pow(exponent)
	return pow(self, exponent, true)
end
-- constants
local one = newComplex(1, 0, true)
module.one = one
local i = newComplex(0, 1, true)
module.i = i
local pi = newComplex(pi,0,true)
module.pi = pi
e = newComplex(exp(1), 0, true)
module.e = e
-- consts used in below funcs
local iUnm = -i
local two = newComplex(2)
local half = newComplex(0.5)
local iHalves = newComplex(0,0.5)
local piHalves = pi * half
--funcs
local sinhi, coshi
sinhi = function(z)
	local a, b = z.Real, z.Imaginary
	return newComplex(sinh(a)*cos(b), cosh(a)*sin(b))
end
module.sinh = sinhi
coshi = function(z)
	local a, b = z.Real, z.Imaginary
	return newComplex(cosh(a)*cos(b), sinh(a)*sin(b))
end
module.cosh = coshi
module.tanh = function(z)
	return sinh(z)/cosh(z)
end
module.asinh = function(z)
	return lni((one + z^two)^half + z)
end
module.acosh = function(z)
	return lni((z^two - one)^half + z)
end
module.atanh = function(z)
	return half * lni( (z + one)/(one - z) )
end
--
sini = function(z)
	z = newComplex(z.Imaginary, -z.Real)
	local component = expi(z)
	return iHalves * (component - one/component)
end
module.sin = sini
cosi = function(z)
	z = newComplex(-z.Imaginary, z.Real)
	local component = expi(z)
	return half * (component + one/component)
end
module.cos = cosi
module.tan = function(z)
	return sini(z)/cosi(z)
end

local asini
asini = function(z)
	return iUnm * lni( (one - z^two)^half + i*z )
end
module.asin = asini
module.acos = function(z)
	return piHalves - asini(z) 
end
module.atan = function(z)
	local iz = i * z
	return iHalves * lni( (one - iz) / (one + iz) )
end

--[[
    reciprocal trig is easy
    ex      cscx = 1/sinx
    and     acscx = asin(1/x)
]] --
module.exp = expi
module.log = lni
return module
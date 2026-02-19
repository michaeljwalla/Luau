local sqrt, exp, log, sin, cos, sinh, cosh, abs, atan2, asin, acos, pi, e = math.sqrt, math.exp, math.log, math.sin, math.cos, math.sinh, math.cosh, math.abs, math.atan2, math.asin, math.acos, math.pi, math.exp(1)
local ifactor = pi/2
local i, ihalf, one, half, two
local round = math.round
local function fround(x, place)
    place = place or 8
    local str = tostring(x)
    local placesbefore = str:find"%."
    if not placesbefore then return x end
    
    str = tostring(round(x*10^place))
    local attempt = tonumber(str:sub(1, placesbefore - 1).. "." .. str:sub(placesbefore))
    if not attempt then return end
    if abs(attempt-x) > 10^(-place/2) then
        return tonumber(x < 0 and ("-0."..-str) or ("0."..str))
    end
    return attempt
end

local functions = {}
local number = {}
local n_methods = {}
number.__index = n_methods
 
function number.real(n)
  n = tonumber(n)
  assert(n, "Expected number when calling real(), got "..type(n))
  return setmetatable({
    Real = n,
    Imaginary = 0,
    Type = "Real"
  }, number)
end
function number.imaginary(n)
  n = tonumber(n)
  assert(n, "Expected number when calling imaginary(), got "..type(n))
  return setmetatable({
    Imaginary = n,
    Real = 0,
    Type = "Imaginary"
  }, number)
end
function number.complex(a, b)
  a, b = tonumber(a), tonumber(b)
  assert(a and b, "Expected (number, number) when calling complex(), got ("..type(a)..", "..type(b)..")")
  return setmetatable({
    Real = a,
    Imaginary = b,
    Type = "Complex"
  }, number)
end
local real, img, comp = number.real, number.imaginary, number.complex
i = img(1)
ihalf = img(0.5)
one = real(1)
two = real(2)
half = real(0.5)

number.e, number.pi, number.i, number.one, number.two, number.half = e, pi, i, one, two, half

function number:finalize() --unstable for numbers w a lot of digits (cool)
    local type = self.Type
    if type == 'Real' then
        return real(fround(self.Real))
    elseif type == 'Imaginary' then
        return img(fround(self.Imaginary))
    end
    return comp(fround(self.Real), fround(self.Imaginary))
end

function number.isNumberClass(n)
    return type(n) == 'table' and ("Real Imaginary Complex"):find(n.Type) ~= nil
end
local isNumClass = number.isNumberClass
local tstring = {}
functions.__tostring = tstring

function n_methods.__tostring(self)
  return tstring[self.Type](self)  
end
function tstring.Real(self, catting)
  return self.Real..(catting or "")
end
function tstring.Imaginary(self, catting)
  local ival = self.Imaginary
  return (abs(ival) == 1 and '' or ival).."i"..(catting or "")
end
function tstring.Complex(self, catting)
  local ival = self.Imaginary
  if self.Imaginary < 0 then
    return (self.Real.." - "..(ival == -1 and '' or -ival).."i")..(catting or "")
  end
  return (self.Real.." + "..(ival == 1 and '' or abs(ival)).."i")..(catting or "")
end

local concat = {
  Real = tstring.Real,
  Imaginary = tstring.Imaginary,
  Complex = tstring.Complex
}
functions.__concat = concat
function n_methods.__concat(self, catting)
  return concat[self.Type](self, catting)
end

local eq = {}
functions.__eq = eq

local function baseeq(self, obj)
    return isNumClass(self) and isNumClass(obj) and self.Type == obj.Type
end
function n_methods.__eq(self, obj)
  local t1, t2 = type(self), type(obj)
  return baseeq(self, obj) and eq[self.Type](self, obj)
end

eq.Real = function(self, obj)
  return self.Real == obj.Real
end
eq.Imaginary = function(self, obj)
  return self.Imaginary == obj.Imaginary
end
eq.Complex = function(self, obj)
  return self.Real == obj.Real and self.Imaginary == obj.Imaginary
end

local lt = {}
functions.__lt = lt

function n_methods.__lt(self, obj)
  local t1, t2 = type(self), type(obj)
  assert(baseeq(self, obj), "Attempt to compare (lt) on "..self.Type.." and "..obj.Type)
  assert(self.Type ~= "Complex", "Attempt to compare (lt) with Complex number (use modulus)")
  return lt[self.Type](self, obj)
end

lt.Real = function(self, obj)
  return self.Real < obj.Real
end
lt.Imaginary = function(self, obj)
  return self.Imaginary < obj.Imaginary
end

local le = {}
functions.__le = le

function n_methods.__le(self, obj)
  local t1, t2 = type(self), type(obj)
  assert(baseeq(self, obj), "Attempt to compare (leq) on "..self.Type.." and "..obj.Type)
  assert(self.Type ~= "Complex", "Attempt to compare (leq) with Complex number (use modulus)")
  return le[self.Type](self, obj)
end

le.Real = function(self, obj)
  return self.Real <= obj.Real
end
le.Imaginary = function(self, obj)
  return self.Imaginary <= obj.Imaginary
end
local ln_, cos_, sin_, exp_, atan_
function number.atan(y, x)
    if typeof(y) ~= 'table' then return atan2(y, x) end
    return ihalf * ln_( (one - i*y) / (one + i*y) )
end
function number.asin(n)
    if typeof(n) ~= 'table' then return asin(n) end
    local part = one - n^two
    return -i * ln_( i*n + real(sqrt(part:modulus())) * exp_(half * i * real(part:argument())) )
end
function number.acos(n)
    if typeof(n) ~= 'table' then return acos(n) end
    local part = n^two - one
    return -i * number.ln(n + part^half)
end
function number.cos(theta)
    if typeof(theta) ~= 'table' then return cos(theta) end
    local real, img = theta.Real, theta.Imaginary
    return comp(cos(real) * cosh(img), -sin(real)*sinh(img))
end
function number.sin(theta)
    if typeof(theta) ~= 'table' then return sin(theta) end
    local real, img = theta.Real, theta.Imaginary
    return comp(sin(real)*cosh(img), cos(real)*sinh(img))
end
function number.tan(theta)
    return sin_(theta)/cos_(theta)
end

function number:modulus()
    return sqrt(self.Real^2 + self.Imaginary^2)
end
function number:argument()
    return atan_(self.Imaginary, self.Real)
end

local _exp = {}
functions.exp = _exp

function number.exp(n)
    if typeof(n) ~= 'table' then return exp(n) end
    return _exp[n.Type](n)
end

_exp.Real = function(n)
    return comp(exp(n.Real), 0)
end
_exp.Imaginary = function(n)
    return comp(cos(n.Imaginary), sin(n.Imaginary))
end
local er_, ei_ = _exp.Real, _exp.Imaginary
_exp.Complex = function(n)
    return er_(n) * ei_(n)
end

function number.ln(n)
    if typeof(n) ~= 'table' then return log(n) end
    return comp(log(n:modulus()), n:argument())
end
ln_, cos_, sin_, exp_, atan_ = number.ln, number.cos, number.sin, number.exp, number.atan
function number:conjugate()
    return comp(self.Real, -self.Imaginary)
end

local add = {}
functions.__add = add

function n_methods.__add(self, obj)
    assert(isNumClass(self) and isNumClass(obj), "Expected (Number, Number) when performing arithmetic")
    return add[self.Type](self, obj)
end

add.Real = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return real(self.Real + obj.Real)
    elseif type == 'Imaginary' then
        return comp(self.Real, self.Imaginary + obj.Imaginary)
    end
    return comp(self.Real + obj.Real, self.Imaginary + obj.Imaginary)
end
add.Imaginary = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return comp(self.Real + obj.Real, self.Imaginary)
    elseif type == 'Imaginary' then
        return img(self.Imaginary + obj.Imaginary)
    end
    return comp(self.Real + obj.Real, self.Imaginary + obj.Imaginary)
end
add.Complex = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return comp(self.Real + obj.Real, self.Imaginary)
    elseif type == 'Imaginary' then
        return comp(self.Real, self.Imaginary + obj.Imaginary)
    end
    return comp(self.Real + obj.Real, self.Imaginary + obj.Imaginary)
end

function n_methods.__unm(self)
    local type = self.Type
    if type == 'Real' then
        return real(-self.Real)
    elseif type == 'Imaginary' then
        return img(-self.Imaginary)
    end
    return comp(-self.Real, -self.Imaginary)
end

function n_methods.__sub(self, obj)
    assert(isNumClass(self) and isNumClass(obj), "Expected (Number, Number) when performing arithmetic")
    return add[self.Type](self, -obj)
end

local mul = {}
functions.__mul = mul

function n_methods.__mul(self, obj)
    assert(isNumClass(self) and isNumClass(obj), "Expected (Number, Number) when performing arithmetic")
    return mul[self.Type](self, obj)
end
mul.Real = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return real(self.Real * obj.Real)
    elseif type == 'Imaginary' then
        return img(self.Real * obj.Imaginary)
    end
    return comp(self.Real * obj.Real, self.Real * obj.Imaginary)
end
mul.Imaginary = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return img(self.Imaginary * obj.Real)
    elseif type == 'Imaginary' then
        return real(-self.Imaginary * obj.Imaginary)
    end
    return comp(-self.Imaginary * obj.Imaginary, self.Imaginary * obj.Real)
end
mul.Complex = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return comp(self.Real * obj.Real, self.Real * self.Imaginary)
    elseif type == 'Imaginary' then
        return comp(-obj.Imaginary * self.Imaginary, obj.Imaginary * self.Real)
    end
    local a,b,c,d = self.Real, self.Imaginary, obj.Real, obj.Imaginary
    return comp(a*c - b*d, a*d + b*c)
end

local div = {}
functions.__div = add

function n_methods.__div(self, obj)
    assert(isNumClass(self) and isNumClass(obj), "Expected (Number, Number) when performing arithmetic")
    return div[self.Type](self, obj)
end
div.Real = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return real(self.Real / obj.Real)
    elseif type == 'Imaginary' then
        return img(-self.Real / obj.Real)
    end
    
    local conj = obj:conjugate()
    local divisor = 1/(obj * conj).Real
    return comp(self.Real * conj.Real * divisor, self.Real * conj.Imaginary * divisor)
end
div.Imaginary = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return img(self.Imaginary/obj.Real)
    elseif type == 'Imaginary' then
        return real(self.Imaginary/obj.Imaginary)
    end
    local divisor = 1/(obj * obj:conjugate()).Real
    return comp(self.Imaginary * obj.Imaginary * divisor, self.Imaginary * obj.Real * divisor)
end
div.Complex = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return comp(self.Real/obj.Real, self.Imaginary/obj.Real)
    elseif type == 'Imaginary' then
        return comp(self.Imaginary/obj.Imaginary, -self.Real/obj.Imaginary)
    end
    local conj = obj:conjugate() 
    local dividend = self * conj --self/obj
    local divisor = 1/(obj * conj).Real
    return comp(dividend.Real * divisor, dividend.Imaginary * divisor)
end

local pow = {}
functions.__pow = pow

function n_methods.__pow(self, obj)
    assert(isNumClass(self) and isNumClass(obj), "Expected (Number, Number) when performing arithmetic")
    return pow[self.Type](self, obj)
end

pow.Real = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return real(self.Real^obj.Real)
    elseif type == 'Imaginary' then
        return exp_( 
            obj *
            ln_(self)
        )
    end
    return self^real(obj.Real) * self^img(obj.Imaginary)
end
pow.Imaginary = function(self, obj)
    local type = obj.Type
    if type == 'Real' then -- = a^n e^(i * n * pi/2)
        local x, n = self.Imaginary, obj.Real
        return real(self.Imaginary^obj.Real)*exp_(img(n * ifactor))
    elseif type == 'Imaginary' then
        return 
    end
    return
end
pow.Complex = function(self, obj)
    local type = obj.Type
    if type == 'Real' then
        return real(self:modulus()^obj.Real) * exp_( img( obj.Real * self:argument() ) )
    elseif type == 'Imaginary' then
        return exp_( real(-obj.Imaginary * self:argument()) + img(obj.Imaginary * ln_(self:modulus())) )
    end
    return self^real(obj.Real) * self^img(obj.Imaginary)
end

return number
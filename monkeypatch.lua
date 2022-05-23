do
	math.tau = math.pi * 2
	function math.sign(x)
		return
		  x > 0 and 1 or
		  x == 0 and 0 or
		  x < 0 and -1
	end
	function math.round(x)
		return math.floor(x + 0.5)
	end
	function math.lerp(a, b, i)
		return a + (b - a) * i
	end
end

do
	local list = require("lib.list")
	function list:elements() -- Convenient iterator
		local i = 1
		return function()
			local v = self:get(i)
			i = i + 1
			if v ~= nil then
				return v
			end
		end, self, 0
	end
	function list:find(obj) -- Same as List:has but without "and true"
		return self.pointers[obj]
	end
end

do
	function love.graphics.multiplyColor(r, g, b)
		if type(r) == "table" then
			r, g, b = r[1], r[2], r[3]
		end
		local curR, curG, curB = love.graphics.getColor()
		love.graphics.setColor(r * curR, g * curG, b * curB)
	end
end

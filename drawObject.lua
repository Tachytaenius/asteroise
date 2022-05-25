local drawObject = {}

function drawObject.ship(pos, angle, scale)
	love.graphics.push("all")
	love.graphics.translate(pos.x, pos.y)
	love.graphics.rotate(angle)
	love.graphics.scale(scale)
	love.graphics.setLineWidth(1/scale)
	love.graphics.polygon("line", 1,0, -1,1, 0,0, -1,-1)
	love.graphics.pop()
end

return drawObject

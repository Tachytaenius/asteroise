local consts = require("consts")

function love.conf(t)
	t.window.width = consts.gameWidth
	t.window.height = consts.gameHeight
	t.window.title = consts.windowTitle
	t.identity = consts.loveIdentity
	t.version = consts.loveVersion
end

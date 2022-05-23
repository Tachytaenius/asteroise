require("monkeypatch")
local list = require("lib.list")
local vec2 = require("lib.mathsies").vec2
local consts = require("consts")
local drawObject = require("drawObject")

local gamestate
local keyPressed, keyReleased

local function readHighscore()
	local highscoreText = love.filesystem.read("highscore.txt")
	local highscore = highscoreText and tonumber(highscoreText) or 0
	return highscore
end

local function tryWriteHighscore()
	if not gamestate.score then
		return false
	end
	local highscore = readHighscore()
	if gamestate.score > highscore then
		love.filesystem.write("highscore.txt", gamestate.score)
		return true
	end
	return false
end

function love.load()
	gamestate = {
		type = "title",
		highscore = readHighscore()
	}
	keyPressed, keyReleased = {}, {}
end

function love.quit()
	tryWriteHighscore()
end

function love.keypressed(key)
	keyPressed[key] = true
end

function love.keyreleased(key)
	keyReleased[key] = true
end

local function newPlayState(lives)
	gamestate = {
		type = "play",
		score = gamestate.score or 0, highscore = gamestate.highscore,
		lives = lives, player = {
			pos = vec2(consts.gameWidth / 2, consts.gameHeight / 2),
			vel = vec2(),
			angle = 0
		},
		bullets = list(), asteroids = list(),
		asteroidSpawnTimer = 2
	}
end

function love.update(dt)
	if gamestate.type == "title" then
		if keyPressed["return"] then
			newPlayState(consts.startingLives)
		end
	elseif gamestate.type == "play" then
		if keyPressed.escape then
			gamestate.paused = not gamestate.paused
		end
		if not gamestate.paused then
			if love.keyboard.isDown("left") then
				gamestate.player.angle = gamestate.player.angle - consts.playerTurnSpeed * dt
			end
			if love.keyboard.isDown("right") then
				gamestate.player.angle = gamestate.player.angle + consts.playerTurnSpeed * dt
			end
			gamestate.player.angle = gamestate.player.angle % math.tau
			local accel = love.keyboard.isDown("up") and consts.playerAcceleration or 0
			local directionVector = vec2.rotate(vec2(1, 0), gamestate.player.angle)
			gamestate.player.vel = gamestate.player.vel + directionVector * accel * dt
			if #gamestate.player.vel > consts.playerMaxSpeed then
				gamestate.player.vel = vec2.normalise(gamestate.player.vel) * consts.playerMaxSpeed
			end
			gamestate.player.pos = gamestate.player.pos + gamestate.player.vel * dt
			gamestate.player.pos.x = gamestate.player.pos.x % consts.gameWidth
			gamestate.player.pos.y = gamestate.player.pos.y % consts.gameHeight
			if keyPressed.space then
				if gamestate.bullets.size < consts.maxBullets then
					gamestate.bullets:add({
						pos = vec2.clone(gamestate.player.pos),
						vel = directionVector * consts.bulletSpeed
					})
				end
			end
			
			for bullet in gamestate.bullets:elements() do
				bullet.pos = bullet.pos + bullet.vel * dt
				if bullet.pos.x < 0 or bullet.pos.x > consts.gameWidth or bullet.pos.y < 0 or bullet.pos.y > consts.gameHeight then
					gamestate.score = math.max(0, gamestate.score - consts.bulletOffScreenScoreLoss)
					gamestate.bullets:remove(bullet)
				else
					for asteroid in gamestate.asteroids:elements() do
						if vec2.distance(bullet.pos, asteroid.pos) < asteroid.radius then
							gamestate.bullets:remove(bullet)
							gamestate.score = gamestate.score + consts.asteroidDestructionScore
							gamestate.asteroids:remove(asteroid)
							local angleOffset = love.math.random() * math.tau
							if asteroid.stages > 1 then
								for i = 1, consts.asteroidSplitCount do
									local angle = angleOffset + (i-1) / (consts.asteroidSplitCount) * math.tau
									local splitVelocity = vec2.rotate(vec2(consts.asteroidSplitSpeedBoost, 0), angle % math.tau)
									local newAsteroid = {
										pos = vec2.clone(asteroid.pos), vel = asteroid.vel + splitVelocity,
										stages = asteroid.stages - 1, radius = asteroid.radius / 2
									}
									newAsteroid.pos = newAsteroid.pos + splitVelocity * consts.asteroidSplitVelocityTimeBoost
									gamestate.asteroids:add(newAsteroid)
								end
							end
							break
						end
					end
				end
			end
			
			for asteroid in gamestate.asteroids:elements() do
				asteroid.pos = asteroid.pos + asteroid.vel * dt
				if asteroid.pos.x < -asteroid.radius or asteroid.pos.x > consts.gameWidth + asteroid.radius or asteroid.pos.y < -asteroid.radius or asteroid.pos.y > consts.gameHeight + asteroid.radius then
					gamestate.score = math.max(0, gamestate.score - consts.asteroidOffScreenScoreLoss)
					gamestate.asteroids:remove(asteroid)
				else
					if vec2.distance(gamestate.player.pos, asteroid.pos) < asteroid.radius + consts.playerRadius then
						gamestate.lives = gamestate.lives - 1
						if gamestate.lives <= 0 then
							local newHighscore = tryWriteHighscore()
							gamestate = {
								gameOver = true,
								newHighscore = newHighscore,
								score = gamestate.score,
								type = "title",
								highscore = readHighscore()
							}
							return
						else
							newPlayState(gamestate.lives)
						end
					end
				end
			end
			
			gamestate.asteroidSpawnTimer = gamestate.asteroidSpawnTimer - dt
			if gamestate.asteroidSpawnTimer <= 0 then
				gamestate.asteroidSpawnTimer = consts.asteroidSpawnTimer
				if gamestate.asteroids.size < consts.maxAsteroids then
					local i = love.math.random()
					local edgeDecider = love.math.random()
					local pos
					if edgeDecider < 0.25 then
						-- top
						pos = vec2(i * consts.gameWidth, 0)
					elseif edgeDecider < 0.5 then
						-- bottom
						pos = vec2(i * consts.gameWidth, consts.gameHeight)
					elseif edgeDecider < 0.75 then
						-- left
						pos = vec2(0, i * consts.gameHeight)
					else
						-- right
						pos = vec2(consts.gameWidth, i * consts.gameHeight)
					end
					gamestate.asteroids:add({
						pos = pos, vel = vec2.normalise(gamestate.player.pos - pos) * consts.newAsteroidSpeed,
						stages = consts.newAsteroidStages, radius = consts.newAsteroidRadius
					})
				end
			end
		end
	end
	keyPressed, keyReleased = {}, {}
end

function love.draw()
	if gamestate.type == "title" then
		love.graphics.print((gamestate.gameOver and "Game over! Score: " .. gamestate.score or "ASTEROISE!") .. (gamestate.newHighscore and "\nNew highscore: " or  "\nHighscore: ") .. gamestate.highscore .. "\nPress enter to play")
	elseif gamestate.type == "play" then
		love.graphics.print("Score: " .. gamestate.score .. "\nHighscore: " .. gamestate.highscore .. "\nLives: " .. gamestate.lives .. (gamestate.paused and "\nPaused" or ""))
		drawObject.ship(gamestate.player.pos, gamestate.player.angle, consts.playerRadius)
		for bullet in gamestate.bullets:elements() do
			love.graphics.points(bullet.pos.x, bullet.pos.y)
		end
		for asteroid in gamestate.asteroids:elements() do
			-- TODO
			love.graphics.circle("line", asteroid.pos.x, asteroid.pos.y, asteroid.radius)
		end
	end
end

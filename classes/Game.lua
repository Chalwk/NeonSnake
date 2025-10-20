-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert

local Snake = require("classes/Snake")
local Food = require("classes/Food")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.gridSize = 30
    instance.gridWidth = 0
    instance.gridHeight = 0
    instance.boardOffsetX = 0
    instance.boardOffsetY = 0

    instance.snake = nil
    instance.food = nil
    instance.score = 0
    instance.highScore = 0
    instance.gameOver = false
    instance.paused = false
    instance.difficulty = "medium"

    instance.particles = {}
    instance.effects = {}
    instance.activePowerUps = {}

    instance.sounds = {
        eat = love.audio.newSource("assets/sounds/eat.mp3", "static"),
        powerup = love.audio.newSource("assets/sounds/powerup.mp3", "static"),
        gameover = love.audio.newSource("assets/sounds/gameover.mp3", "static")
    }

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateGrid()
end

function Game:calculateGrid()
    self.gridWidth = math_floor((self.screenWidth - 100) / self.gridSize)
    self.gridHeight = math_floor((self.screenHeight - 200) / self.gridSize)
    self.boardOffsetX = (self.screenWidth - self.gridWidth * self.gridSize) / 2
    self.boardOffsetY = (self.screenHeight - self.gridHeight * self.gridSize) / 2 + 50
end

function Game:startNewGame(difficulty)
    self.difficulty = difficulty or "medium"
    self:calculateGrid()

    local startX = math_floor(self.gridWidth / 3) * self.gridSize
    local startY = math_floor(self.gridHeight / 2) * self.gridSize

    self.snake = Snake.new(self.gridSize, startX, startY)
    self.food = Food.new(self.gridSize)
    self.score = 0
    self.gameOver = false
    self.paused = false
    self.particles = {}
    self.effects = {}
    self.activePowerUps = {}

    -- Set initial speed based on difficulty
    if self.difficulty == "easy" then
        self.snake.speed = 4
    elseif self.difficulty == "medium" then
        self.snake.speed = 8
    else -- hard
        self.snake.speed = 10
    end

    -- Spawn initial food
    self.food:spawnFood(self.gridWidth, self.gridHeight, self.snake.body)
end

function Game:update(dt)
    if self.gameOver or self.paused then return end

    -- Update snake
    self.snake:update(dt, self.gridWidth, self.gridHeight)

    if not self.snake.alive then
        self.gameOver = true
        love.audio.play(self.sounds.gameover)
        if self.score > self.highScore then
            self.highScore = self.score
        end
        return
    end

    -- Update food system
    self.food:update(dt)

    -- Check for food collisions
    local head = self.snake:getHead()
    local collision, item = self.food:checkCollision(head.x, head.y)

    if collision == "food" then
        self:handleFoodCollision(item)
    elseif collision == "powerup" then
        self:handlePowerUpCollision(item)
    end

    -- Spawn new food if needed
    if #self.food.items == 0 then
        self.food:spawnFood(self.gridWidth, self.gridHeight, self.snake.body)
    end

    -- Randomly spawn power-ups
    self.food:spawnPowerUp(self.gridWidth, self.gridHeight, self.snake.body)

    -- Update particles
    self:updateParticles(dt)

    -- Update active power-ups
    self:updatePowerUps(dt)
end

function Game:handleFoodCollision(foodType)
    self.score = self.score + foodType.value
    self.snake:grow(foodType.growAmount)
    love.audio.play(self.sounds.eat)

    -- Create particle effect
    self:createEatEffect(self.snake:getHead().x, self.snake:getHead().y, foodType.color)

    -- Increase speed slightly
    self.snake:increaseSpeed(0.1)
end

function Game:handlePowerUpCollision(powerUpType)
    self.score = self.score + 25
    love.audio.play(self.sounds.powerup)

    -- Apply power-up effect
    self.activePowerUps[powerUpType.effect] = {
        duration = powerUpType.duration,
        startTime = love.timer.getTime()
    }

    if powerUpType.effect == "speed_boost" then
        self.snake.speed = self.snake.speed * 1.5
    elseif powerUpType.effect == "invincible" then
        -- Snake becomes invincible for duration
        self.snake.color = { 0.9, 0.9, 0.2 }
    end

    self:createPowerUpEffect(self.snake:getHead().x, self.snake:getHead().y, powerUpType.color)
end

function Game:updatePowerUps(dt)
    local currentTime = love.timer.getTime()

    for effect, powerUp in pairs(self.activePowerUps) do
        powerUp.duration = powerUp.duration - dt

        if powerUp.duration <= 0 then
            self.activePowerUps[effect] = nil

            -- Revert effects
            if effect == "speed_boost" then
                self.snake.speed = self.snake.speed / 1.5
            elseif effect == "invincible" then
                self.snake.color = { 0.2, 0.8, 0.3 }
            end
        end
    end
end

function Game:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Game:createEatEffect(x, y, color)
    for i = 1, 15 do
        table_insert(self.particles, {
            x = x + self.gridSize / 2,
            y = y + self.gridSize / 2,
            dx = (math_random() - 0.5) * 200,
            dy = (math_random() - 0.5) * 200,
            life = 0.8,
            size = math_random(3, 8),
            color = { color[1], color[2], color[3], 0.8 }
        })
    end
end

function Game:createPowerUpEffect(x, y, color)
    for i = 1, 25 do
        table_insert(self.particles, {
            x = x + self.gridSize / 2,
            y = y + self.gridSize / 2,
            dx = (math_random() - 0.5) * 150,
            dy = (math_random() - 0.5) * 150,
            life = 1.2,
            size = math_random(4, 10),
            color = { color[1], color[2], color[3], 0.9 }
        })
    end
end

function Game:draw()
    -- Draw game board
    self:drawBoard()

    -- Draw food and power-ups
    self.food:draw(self.boardOffsetX, self.boardOffsetY)

    -- Draw snake
    self.snake:draw(self.boardOffsetX, self.boardOffsetY)

    -- Draw particles
    self:drawParticles()

    -- Draw UI
    self:drawUI()

    if self.gameOver then
        self:drawGameOver()
    elseif self.paused then
        self:drawPaused()
    end
end

function Game:drawBoard()
    -- Board background
    love.graphics.setColor(0.05, 0.1, 0.05, 0.8)
    love.graphics.rectangle("fill",
        self.boardOffsetX,
        self.boardOffsetY,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize
    )

    -- Board border
    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        self.boardOffsetX,
        self.boardOffsetY,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize
    )
    love.graphics.setLineWidth(1)
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = particle.life * 0.8
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill",
            particle.x + self.boardOffsetX,
            particle.y + self.boardOffsetY,
            particle.size
        )
    end
end

function Game:drawUI()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)

    -- Score and high score
    love.graphics.print("Score: " .. self.score, 20, 20)
    love.graphics.print("High Score: " .. self.highScore, 20, 50)

    -- Difficulty
    love.graphics.printf("Difficulty: " .. self.difficulty:upper(),
        0, 20, self.screenWidth - 20, "right")

    -- Snake length
    love.graphics.printf("Length: " .. #self.snake.body,
        0, 50, self.screenWidth - 20, "right")

    -- Active power-ups
    local powerUpY = 90
    love.graphics.setFont(self.fonts.small)
    for effect, powerUp in pairs(self.activePowerUps) do
        local timeLeft = math_floor(powerUp.duration * 10) / 10
        love.graphics.print(effect:gsub("_", " "):upper() .. ": " .. timeLeft .. "s", 20, powerUpY)
        powerUpY = powerUpY + 20
    end

    -- Controls help
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("ARROWS/WASD: Move | P: Pause | R: Restart | ESC: Menu",
        0, self.screenHeight - 30, self.screenWidth, "center")
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2 - 30, self.screenWidth, "center")
    love.graphics.printf("High Score: " .. self.highScore, 0, self.screenHeight / 2, self.screenWidth, "center")
    love.graphics.printf("Length: " .. #self.snake.body, 0, self.screenHeight / 2 + 30, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:drawPaused()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, self.screenHeight / 2 - 50, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.printf("Press P to resume", 0, self.screenHeight / 2 + 20, self.screenWidth, "center")
end

function Game:handleKeypress(key)
    if key == "p" then
        self.paused = not self.paused
    elseif key == "r" then
        self:startNewGame(self.difficulty)
    elseif not self.paused and not self.gameOver then
        if key == "up" or key == "w" then
            self.snake:changeDirection("up")
        elseif key == "down" or key == "s" then
            self.snake:changeDirection("down")
        elseif key == "left" or key == "a" then
            self.snake:changeDirection("left")
        elseif key == "right" or key == "d" then
            self.snake:changeDirection("right")
        end
    end
end

function Game:isGameOver()
    return self.gameOver
end

function Game:setFonts(fonts)
    self.fonts = fonts
end

return Game
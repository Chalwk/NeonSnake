-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_floor = math.floor
local math_random = math.random
local math_sin = math.sin
local math_cos = math.cos
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
    instance.time = 0

    instance.particles = {}
    instance.effects = {}
    instance.activePowerUps = {}
    instance.boardPulse = 0

    -- sound system placeholder
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
    self.time = 0

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

    -- Start game effect
    self:createGameStartEffect()
end

function Game:createGameStartEffect()
    for i = 1, 50 do
        table_insert(self.particles, {
            x = self.boardOffsetX + math_random() * self.gridWidth * self.gridSize,
            y = self.boardOffsetY + math_random() * self.gridHeight * self.gridSize,
            dx = (math_random() - 0.5) * 300,
            dy = (math_random() - 0.5) * 300,
            life = 1.5,
            size = math_random(4, 12),
            color = {0.2, 0.8, 0.3, 0.9},
            type = "circle"
        })
    end
end

function Game:update(dt)
    self.time = self.time + dt
    self.boardPulse = math_sin(self.time * 3) * 0.5 + 0.5

    if self.gameOver or self.paused then
        -- Update particles even when paused/game over
        self:updateParticles(dt)
        return
    end

    -- Update snake
    self.snake:update(dt, self.gridWidth, self.gridHeight)

    if not self.snake.alive then
        self.gameOver = true
        love.audio.play(self.sounds.gameover)
        if self.score > self.highScore then
            self.highScore = self.score
        end
        self:createGameOverEffect()
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

function Game:createGameOverEffect()
    local head = self.snake:getHead()
    for i = 1, 100 do
        table_insert(self.particles, {
            x = head.x + self.boardOffsetX + self.gridSize / 2,
            y = head.y + self.boardOffsetY + self.gridSize / 2,
            dx = (math_random() - 0.5) * 400,
            dy = (math_random() - 0.5) * 400,
            life = 2,
            size = math_random(3, 10),
            color = {0.9, 0.2, 0.2, 0.8},
            type = math_random(1, 3) == 1 and "square" or "circle"
        })
    end
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
        self.snake.color = {0.9, 0.9, 0.2}
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
                self.snake.color = {0.2, 0.8, 0.3}
            end
        end
    end
end

function Game:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt

        -- Only update position if particle has velocity properties
        if particle.dx and particle.dy then
            particle.x = particle.x + particle.dx * dt
            particle.y = particle.y + particle.dy * dt
        end

        if particle.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Game:createEatEffect(x, y, color)
    for i = 1, 25 do
        local angle = (i / 25) * math.pi * 2
        local speed = math_random(80, 200)
        table_insert(self.particles, {
            x = x + self.gridSize / 2,
            y = y + self.gridSize / 2,
            dx = math_cos(angle) * speed,
            dy = math_sin(angle) * speed,
            life = 1.0,
            size = math_random(4, 10),
            color = {color[1], color[2], color[3], 0.9},
            type = "circle"
        })
    end

    -- Create a burst effect (static particles)
    for i = 1, 8 do
        table_insert(self.particles, {
            x = x + self.gridSize / 2,
            y = y + self.gridSize / 2,
            life = 0.8,
            startSize = 5,
            endSize = 40,
            color = {color[1], color[2], color[3], 0.6},
            type = "expand"
        })
    end
end

function Game:createPowerUpEffect(x, y, color)
    for i = 1, 40 do
        table_insert(self.particles, {
            x = x + self.gridSize / 2,
            y = y + self.gridSize / 2,
            dx = (math_random() - 0.5) * 200,
            dy = (math_random() - 0.5) * 200,
            life = 1.5,
            size = math_random(6, 15),
            color = {color[1], color[2], color[3], 0.9},
            type = math_random(1, 2) == 1 and "circle" or "square"
        })
    end

    -- Create rings (static particles)
    for i = 1, 3 do
        table_insert(self.particles, {
            x = x + self.gridSize / 2,
            y = y + self.gridSize / 2,
            life = 1.0,
            startSize = 10,
            endSize = 100 + i * 50,
            color = {color[1], color[2], color[3], 0.4},
            type = "ring",
            ringWidth = 3 + i
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
    -- Animated board background
    local pulseAlpha = 0.7 + self.boardPulse * 0.2
    love.graphics.setColor(0.05, 0.12, 0.05, pulseAlpha)
    love.graphics.rectangle("fill",
        self.boardOffsetX,
        self.boardOffsetY,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize, 5, 5
    )

    -- Pulsing board border
    love.graphics.setColor(0.2, 0.8, 0.2, 0.6 + self.boardPulse * 0.4)
    love.graphics.setLineWidth(3 + self.boardPulse)
    love.graphics.rectangle("line",
        self.boardOffsetX,
        self.boardOffsetY,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize, 5, 5
    )
    love.graphics.setLineWidth(1)

    -- Grid pattern with subtle animation
    love.graphics.setColor(0.3, 0.6, 0.3, 0.1 + self.boardPulse * 0.05)
    for x = 0, self.gridWidth do
        love.graphics.line(
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY,
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY + self.gridHeight * self.gridSize
        )
    end
    for y = 0, self.gridHeight do
        love.graphics.line(
            self.boardOffsetX,
            self.boardOffsetY + y * self.gridSize,
            self.boardOffsetX + self.gridWidth * self.gridSize,
            self.boardOffsetY + y * self.gridSize
        )
    end
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = particle.life

        if particle.type == "expand" then
            local progress = 1 - (particle.life / 0.8)
            local size = particle.startSize + (particle.endSize - particle.startSize) * progress
            love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha * 0.6)
            love.graphics.circle("line",
                particle.x,
                particle.y,
                size
            )
        elseif particle.type == "ring" then
            local progress = 1 - (particle.life / 1.0)
            local size = particle.startSize + (particle.endSize - particle.startSize) * progress
            love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha * 0.8)
            love.graphics.setLineWidth(particle.ringWidth)
            love.graphics.circle("line",
                particle.x,
                particle.y,
                size
            )
            love.graphics.setLineWidth(1)
        else
            love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
            if particle.type == "square" then
                love.graphics.rectangle("fill",
                    particle.x - particle.size / 2,
                    particle.y - particle.size / 2,
                    particle.size, particle.size, 2
                )
            else
                love.graphics.circle("fill",
                    particle.x,
                    particle.y,
                    particle.size
                )
            end
        end
    end
end

function Game:drawUI()
    local uiPulse = math_sin(self.time * 4) * 0.3 + 0.7

    love.graphics.setColor(1, 1, 1, uiPulse)
    love.graphics.setFont(self.fonts.medium)

    -- Score and high score with subtle glow
    love.graphics.setColor(0.8, 1.0, 0.8, uiPulse)
    love.graphics.print("Score: " .. self.score, 25, 25)
    love.graphics.print("High Score: " .. self.highScore, 25, 60)

    -- Difficulty with animation
    love.graphics.setColor(0.6, 0.9, 1.0, uiPulse)
    love.graphics.printf("Difficulty: " .. self.difficulty:upper(),
        0, 25, self.screenWidth - 25, "right")

    -- Snake length
    love.graphics.setColor(1.0, 0.8, 0.6, uiPulse)
    love.graphics.printf("Length: " .. #self.snake.body,
        0, 60, self.screenWidth - 25, "right")

    -- Active power-ups with pulsing effect
    local powerUpY = 100
    love.graphics.setFont(self.fonts.small)
    for effect, powerUp in pairs(self.activePowerUps) do
        local timeLeft = math_floor(powerUp.duration * 10) / 10
        local pulse = math_sin(self.time * 8) * 0.5 + 0.5
        love.graphics.setColor(0.3, 0.8, 1.0, 0.8 + pulse * 0.2)
        love.graphics.print(effect:gsub("_", " "):upper() .. ": " .. timeLeft .. "s", 25, powerUpY)
        powerUpY = powerUpY + 22
    end

    -- Controls help with fade
    love.graphics.setColor(1, 1, 1, 0.5 + math_sin(self.time * 2) * 0.2)
    love.graphics.printf("ARROWS/WASD: Move | P: Pause | R: Restart | ESC: Menu",
        0, self.screenHeight - 35, self.screenWidth, "center")
end

function Game:drawGameOver()
    -- Animated overlay
    local pulse = math_sin(self.time * 5) * 0.1 + 0.9
    love.graphics.setColor(0, 0, 0, 0.8 * pulse)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)

    -- Game Over text with glow
    for i = 1, 3 do
        local glow = i * 3
        love.graphics.setColor(0.9, 0.2, 0.2, 0.3 / i)
        love.graphics.printf("GAME OVER", -glow, self.screenHeight / 2 - 100 - glow, self.screenWidth, "center")
        love.graphics.printf("GAME OVER", glow, self.screenHeight / 2 - 100 + glow, self.screenWidth, "center")
    end

    love.graphics.setColor(1.0, 0.3, 0.3, 0.9)
    love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(1, 1, 1, 0.8 + math_sin(self.time * 3) * 0.2)
    love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2 - 30, self.screenWidth, "center")
    love.graphics.printf("High Score: " .. self.highScore, 0, self.screenHeight / 2, self.screenWidth, "center")
    love.graphics.printf("Length: " .. #self.snake.body, 0, self.screenHeight / 2 + 30, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.8, 0.8, 1.0, 0.6 + math_sin(self.time * 4) * 0.4)
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:drawPaused()
    -- Pulsing overlay
    local pulse = math_sin(self.time * 6) * 0.1 + 0.9
    love.graphics.setColor(0, 0, 0, 0.6 * pulse)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)

    -- Paused text with animation
    for i = 1, 2 do
        local offset = i * 2
        love.graphics.setColor(0.2, 0.8, 1.0, 0.4 / i)
        love.graphics.printf("PAUSED", -offset, self.screenHeight / 2 - 50 - offset, self.screenWidth, "center")
        love.graphics.printf("PAUSED", offset, self.screenHeight / 2 - 50 + offset, self.screenWidth, "center")
    end

    love.graphics.setColor(0.3, 0.9, 1.0, 0.9)
    love.graphics.printf("PAUSED", 0, self.screenHeight / 2 - 50, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.7 + math_sin(self.time * 3) * 0.3)
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
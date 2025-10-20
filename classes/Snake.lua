-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove

local Snake = {}
Snake.__index = Snake

function Snake.new(gridSize, startX, startY)
    local instance = setmetatable({}, Snake)

    instance.gridSize = gridSize
    instance.direction = "right"
    instance.nextDirection = "right"
    instance.body = {}
    instance.growthPending = 0
    instance.alive = true
    instance.speed = 8
    instance.moveTimer = 0
    instance.color = {0.2, 0.8, 0.3}
    instance.headColor = {0.1, 0.9, 0.2}
    instance.trailParticles = {}

    -- Initialize snake body
    for i = 1, 3 do
        table_insert(instance.body, {
            x = startX - i * gridSize,
            y = startY,
            age = 0
        })
    end

    return instance
end

function Snake:update(dt, gridWidth, gridHeight)
    if not self.alive then return end

    self.moveTimer = self.moveTimer + dt * self.speed

    -- Update body part ages
    for _, segment in ipairs(self.body) do
        segment.age = segment.age + dt
    end

    -- Update trail particles
    for i = #self.trailParticles, 1, -1 do
        local particle = self.trailParticles[i]
        particle.life = particle.life - dt
        if particle.life <= 0 then
            table_remove(self.trailParticles, i)
        end
    end

    if self.moveTimer >= 1 then
        self.moveTimer = 0
        self.direction = self.nextDirection

        -- Move snake
        local head = self.body[1]
        local newHead = {
            x = head.x,
            y = head.y,
            age = 0
        }

        if self.direction == "right" then
            newHead.x = newHead.x + self.gridSize
        elseif self.direction == "left" then
            newHead.x = newHead.x - self.gridSize
        elseif self.direction == "up" then
            newHead.y = newHead.y - self.gridSize
        elseif self.direction == "down" then
            newHead.y = newHead.y + self.gridSize
        end

        -- Wrap around screen
        if newHead.x < 0 then newHead.x = (gridWidth - 1) * self.gridSize end
        if newHead.x >= gridWidth * self.gridSize then newHead.x = 0 end
        if newHead.y < 0 then newHead.y = (gridHeight - 1) * self.gridSize end
        if newHead.y >= gridHeight * self.gridSize then newHead.y = 0 end

        -- Check collision with self
        for i, segment in ipairs(self.body) do
            if i > 1 and newHead.x == segment.x and newHead.y == segment.y then
                self.alive = false
                return
            end
        end

        table_insert(self.body, 1, newHead)

        -- Add trail particles
        for i = 1, 3 do
            table_insert(self.trailParticles, {
                x = head.x + math.random(-5, 5),
                y = head.y + math.random(-5, 5),
                life = 0.5,
                maxLife = 0.5,
                size = math.random(2, 5),
                color = {self.color[1], self.color[2], self.color[3], 0.7}
            })
        end

        -- Handle growth
        if self.growthPending > 0 then
            self.growthPending = self.growthPending - 1
        else
            table_remove(self.body)
        end
    end
end

function Snake:draw(offsetX, offsetY)
    -- Draw trail particles
    for _, particle in ipairs(self.trailParticles) do
        local alpha = particle.life / particle.maxLife
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x + offsetX, particle.y + offsetY, particle.size)
    end

    -- Draw snake body
    for i, segment in ipairs(self.body) do
        local segmentAlpha = math.min(1, segment.age * 2)
        local pulse = (math.sin(segment.age * 10) + 1) * 0.1

        if i == 1 then
            -- Head
            love.graphics.setColor(
                self.headColor[1] + pulse,
                self.headColor[2] + pulse,
                self.headColor[3] + pulse,
                segmentAlpha
            )
        else
            -- Body
            local ageFactor = math.min(1, segment.age * 0.5)
            love.graphics.setColor(
                self.color[1] + pulse * ageFactor,
                self.color[2] + pulse * ageFactor,
                self.color[3] + pulse * ageFactor,
                segmentAlpha
            )
        end

        local size = self.gridSize - 2
        love.graphics.rectangle("fill",
            segment.x + offsetX + 1,
            segment.y + offsetY + 1,
            size, size, 3, 3
        )

        -- Inner glow
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line",
            segment.x + offsetX + 2,
            segment.y + offsetY + 2,
            size - 2, size - 2, 2, 2
        )
    end
end

function Snake:changeDirection(newDir)
    -- Prevent 180-degree turns
    if (self.direction == "right" and newDir == "left") or
       (self.direction == "left" and newDir == "right") or
       (self.direction == "up" and newDir == "down") or
       (self.direction == "down" and newDir == "up") then
        return
    end
    self.nextDirection = newDir
end

function Snake:grow(amount)
    self.growthPending = self.growthPending + (amount or 1)
end

function Snake:getHead()
    return self.body[1]
end

function Snake:checkCollision(x, y)
    local head = self.body[1]
    return head.x == x and head.y == y
end

function Snake:increaseSpeed(amount)
    self.speed = math.min(20, self.speed + (amount or 0.5))
end

return Snake
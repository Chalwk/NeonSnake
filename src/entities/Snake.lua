-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_sin = math.sin
local math_min = math.min
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove
local ipairs = ipairs

local lg = love.graphics

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
    instance.time = 0
    instance.color = {0.2, 0.8, 0.3}
    instance.headColor = {0.1, 0.9, 0.2}
    instance.glowColor = {0.4, 1.0, 0.5}
    instance.trailParticles = {}

    -- Initialize snake body
    for i = 1, 3 do
        table_insert(instance.body, {
            x = startX - i * gridSize,
            y = startY,
            age = 0,
            pulse = 0
        })
    end

    return instance
end

function Snake:update(dt, gridWidth, gridHeight)
    if not self.alive then return end

    self.time = self.time + dt
    self.moveTimer = self.moveTimer + dt * self.speed

    -- Update body part ages and pulses
    for _, segment in ipairs(self.body) do
        segment.age = segment.age + dt
        segment.pulse = math_sin(self.time * 8 + segment.age * 5) * 0.5 + 0.5
    end

    -- Update trail particles
    for i = #self.trailParticles, 1, -1 do
        local particle = self.trailParticles[i]
        particle.life = particle.life - dt
        if particle.life <= 0 then
            table_remove(self.trailParticles, i)
        else
            -- Fade and shrink
            particle.size = particle.startSize * (particle.life / particle.maxLife)
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
            age = 0,
            pulse = 0
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

        -- Trail particles
        for i = 1, 5 do
            table_insert(self.trailParticles, {
                x = head.x + self.gridSize / 2 + math_random(-8, 8),
                y = head.y + self.gridSize / 2 + math_random(-8, 8),
                life = 0.8,
                maxLife = 0.8,
                startSize = math_random(3, 7),
                size = math_random(3, 7),
                color = {self.color[1], self.color[2], self.color[3], 0.6},
                driftX = math_random(-20, 20),
                driftY = math_random(-20, 20)
            })
        end

        -- Handle growth
        if self.growthPending > 0 then
            self.growthPending = self.growthPending - 1
        else
            table_remove(self.body)
        end
    end

    -- Update trail particles motion
    for _, particle in ipairs(self.trailParticles) do
        particle.x = particle.x + particle.driftX * dt
        particle.y = particle.y + particle.driftY * dt
    end
end

function Snake:draw(offsetX, offsetY)
    -- Draw trail particles
    for _, particle in ipairs(self.trailParticles) do
        local alpha = (particle.life / particle.maxLife) * 0.8
        lg.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        lg.circle("fill", particle.x + offsetX, particle.y + offsetY, particle.size)

        -- Glow effect
        lg.setColor(0.6, 1.0, 0.6, alpha * 0.3)
        lg.circle("fill", particle.x + offsetX, particle.y + offsetY, particle.size * 1.5)
    end

    -- Draw snake body
    for i, segment in ipairs(self.body) do
        local segmentAlpha = math_min(1, segment.age * 3)
        local pulse = segment.pulse
        local size = self.gridSize - 2

        if i == 1 then
            -- Head with glow
            local headPulse = math_sin(self.time * 10) * 0.3 + 0.7

            -- Head glow
            lg.setColor(
                self.glowColor[1],
                self.glowColor[2],
                self.glowColor[3],
                segmentAlpha * 0.4 * headPulse
            )
            lg.rectangle("fill",
                segment.x + offsetX + 1 - 3,
                segment.y + offsetY + 1 - 3,
                size + 6, size + 6, 5, 5
            )

            -- Head main
            lg.setColor(
                self.headColor[1] + pulse * 0.2,
                self.headColor[2] + pulse * 0.1,
                self.headColor[3] + pulse * 0.2,
                segmentAlpha
            )
            lg.rectangle("fill",
                segment.x + offsetX + 1,
                segment.y + offsetY + 1,
                size, size, 4, 4
            )

            -- Eyes based on direction
            lg.setColor(1, 1, 1, segmentAlpha)
            local eyeSize = 3
            if self.direction == "right" then
                lg.rectangle("fill", segment.x + offsetX + size - 6, segment.y + offsetY + 8, eyeSize, eyeSize)
                lg.rectangle("fill", segment.x + offsetX + size - 6, segment.y + offsetY + size - 8, eyeSize, eyeSize)
            elseif self.direction == "left" then
                lg.rectangle("fill", segment.x + offsetX + 6, segment.y + offsetY + 8, eyeSize, eyeSize)
                lg.rectangle("fill", segment.x + offsetX + 6, segment.y + offsetY + size - 8, eyeSize, eyeSize)
            elseif self.direction == "up" then
                lg.rectangle("fill", segment.x + offsetX + 8, segment.y + offsetY + 6, eyeSize, eyeSize)
                lg.rectangle("fill", segment.x + offsetX + size - 8, segment.y + offsetY + 6, eyeSize, eyeSize)
            elseif self.direction == "down" then
                lg.rectangle("fill", segment.x + offsetX + 8, segment.y + offsetY + size - 6, eyeSize, eyeSize)
                lg.rectangle("fill", segment.x + offsetX + size - 8, segment.y + offsetY + size - 6, eyeSize, eyeSize)
            end

        else
            -- Body segments with gradient
            local ageFactor = math_min(1, segment.age * 0.8)
            local segmentGlow = (i / #self.body) * 0.5

            -- Body glow
            lg.setColor(
                self.glowColor[1],
                self.glowColor[2],
                self.glowColor[3],
                segmentAlpha * 0.3 * segmentGlow
            )
            lg.rectangle("fill",
                segment.x + offsetX + 1 - 2,
                segment.y + offsetY + 1 - 2,
                size + 4, size + 4, 3, 3
            )

            -- Body main with pulse effect
            lg.setColor(
                self.color[1] + pulse * 0.15 * ageFactor,
                self.color[2] + pulse * 0.1 * ageFactor,
                self.color[3] + pulse * 0.15 * ageFactor,
                segmentAlpha
            )
            lg.rectangle("fill",
                segment.x + offsetX + 1,
                segment.y + offsetY + 1,
                size, size, 3, 3
            )
        end

        -- Inner glow for all segments
        lg.setColor(1, 1, 1, 0.4 * segmentAlpha)
        lg.rectangle("line",
            segment.x + offsetX + 2,
            segment.y + offsetY + 2,
            size - 2, size - 2, 2, 2
        )

        -- Segment connectors
        if i < #self.body then
            local nextSeg = self.body[i + 1]
            lg.setColor(
                self.color[1],
                self.color[2],
                self.color[3],
                segmentAlpha * 0.6
            )
            lg.setLineWidth(3)
            lg.line(
                segment.x + offsetX + self.gridSize / 2,
                segment.y + offsetY + self.gridSize / 2,
                nextSeg.x + offsetX + self.gridSize / 2,
                nextSeg.y + offsetY + self.gridSize / 2
            )
            lg.setLineWidth(1)
        end
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

function Snake:getHead() return self.body[1] end

function Snake:checkCollision(x, y)
    local head = self.body[1]
    return head.x == x and head.y == y
end

function Snake:increaseSpeed(amount)
    self.speed = math_min(20, self.speed + (amount or 0.5))
end

return Snake
-- Neon Snake - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.particles = {}
    instance.stars = {}
    instance.neonRings = {}
    instance.time = 0
    instance.pulse = 0
    instance:initParticles()
    instance:initStars()
    instance:initNeonRings()
    return instance
end

function BackgroundManager:initParticles()
    self.particles = {}
    for i = 1, 150 do
        table_insert(self.particles, {
            x = math_random() * 1200,
            y = math_random() * 800,
            size = math_random(2, 6),
            speed = math_random(20, 80),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(1, 4),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 4),
            life = math_random(8, 25),
            maxLife = math_random(8, 25),
            color = {
                math_random(0.1, 0.4),
                math_random(0.7, 1.0),
                math_random(0.1, 0.4)
            },
            trail = {}
        })
    end
end

function BackgroundManager:initStars()
    self.stars = {}
    for i = 1, 200 do
        table_insert(self.stars, {
            x = math_random() * 1200,
            y = math_random() * 800,
            size = math_random(0.5, 2),
            brightness = math_random(0.3, 1.0),
            twinkleSpeed = math_random(2, 6),
            phase = math_random() * math_pi * 2
        })
    end
end

function BackgroundManager:initNeonRings()
    self.neonRings = {}
    for i = 1, 8 do
        table_insert(self.neonRings, {
            x = math_random(200, 1000),
            y = math_random(150, 650),
            radius = math_random(50, 200),
            thickness = math_random(2, 8),
            speed = math_random(0.2, 1),
            phase = math_random() * math_pi * 2,
            color = {
                math_random(0.1, 0.3),
                math_random(0.6, 0.9),
                math_random(0.1, 0.3),
                0.1
            }
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt
    self.pulse = math_sin(self.time * 2) * 0.5 + 0.5

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt

        -- Add to trail
        table_insert(particle.trail, 1, {
            x = particle.x,
            y = particle.y,
            life = 0.3
        })

        -- Update trail
        for j = #particle.trail, 1, -1 do
            particle.trail[j].life = particle.trail[j].life - dt
            if particle.trail[j].life <= 0 then
                table.remove(particle.trail, j)
            end
        end

        if particle.life <= 0 then
            table.remove(self.particles, i)
        else
            particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

            -- Wrap around with buffer
            if particle.x < -100 then particle.x = 1300 end
            if particle.x > 1300 then particle.x = -100 end
            if particle.y < -100 then particle.y = 900 end
            if particle.y > 900 then particle.y = -100 end
        end
    end

    -- Add new particles
    while #self.particles < 150 do
        table_insert(self.particles, {
            x = math_random() * 1200,
            y = -50,
            size = math_random(2, 6),
            speed = math_random(20, 80),
            angle = math_random(0.3, 0.7) * math_pi,
            pulseSpeed = math_random(1, 4),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 4),
            life = math_random(8, 25),
            maxLife = math_random(8, 25),
            color = {
                math_random(0.1, 0.4),
                math_random(0.7, 1.0),
                math_random(0.1, 0.4)
            },
            trail = {}
        })
    end

    -- Update stars
    for _, star in ipairs(self.stars) do
        star.phase = star.phase + star.twinkleSpeed * dt
    end

    -- Update neon rings
    for _, ring in ipairs(self.neonRings) do
        ring.phase = ring.phase + ring.speed * dt
    end
end

function BackgroundManager:draw(gameState)
    local time = love.timer.getTime()

    -- Deep space gradient background
    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 0.8 + progress * 4) + 1) * 0.04

        local r = 0.02 + progress * 0.03 + pulse * 0.5
        local g = 0.1 + progress * 0.15 + pulse * 0.8
        local b = 0.05 + progress * 0.04 + pulse * 0.3

        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Draw stars
    for _, star in ipairs(self.stars) do
        local twinkle = (math_sin(star.phase) + 1) * 0.5
        local brightness = star.brightness * (0.7 + twinkle * 0.3)
        love.graphics.setColor(brightness, brightness * 1.2, brightness, 0.8)
        love.graphics.circle("fill", star.x, star.y, star.size)
    end

    -- Draw neon rings
    for _, ring in ipairs(self.neonRings) do
        local pulse = (math_sin(ring.phase) + 1) * 0.3
        love.graphics.setColor(ring.color[1], ring.color[2], ring.color[3], ring.color[4] + pulse * 0.2)
        love.graphics.setLineWidth(ring.thickness + pulse * 2)
        love.graphics.circle("line", ring.x, ring.y, ring.radius + pulse * 10)
    end
    love.graphics.setLineWidth(1)

    -- Draw grid pattern with pulse
    love.graphics.setColor(0.3, 0.6, 0.3, 0.15 + self.pulse * 0.1)
    local gridSize = 40
    for x = 0, screenWidth, gridSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, gridSize do
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Particles with trails
    for _, particle in ipairs(self.particles) do
        local lifeProgress = particle.life / particle.maxLife
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.5
        local currentSize = particle.size * (0.8 + pulse * 0.4)
        local alpha = lifeProgress * (0.3 + pulse * 0.4)

        -- Draw trail
        for i, point in ipairs(particle.trail) do
            local trailAlpha = alpha * (point.life / 0.3) * (i / #particle.trail)
            local trailSize = currentSize * (i / #particle.trail) * 0.6

            love.graphics.setColor(
                particle.color[1],
                particle.color[2],
                particle.color[3],
                trailAlpha * 0.5
            )

            love.graphics.circle("fill", point.x, point.y, trailSize)
        end

        -- Draw particle
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        if particle.type == 1 then
            -- Glowing circle
            love.graphics.circle("fill", particle.x, particle.y, currentSize)
            love.graphics.setColor(1, 1, 1, alpha * 0.6)
            love.graphics.circle("line", particle.x, particle.y, currentSize)
        elseif particle.type == 2 then
            -- Pulsing square
            love.graphics.rectangle("fill", particle.x - currentSize, particle.y - currentSize,
                                  currentSize * 2, currentSize * 2, 2)
        elseif particle.type == 3 then
            -- Diamond
            self:drawDiamond(particle.x, particle.y, currentSize)
        else
            -- Star
            self:drawStar(particle.x, particle.y, currentSize, 5)
        end
    end

    -- Scan line effect
    love.graphics.setColor(0, 0.3, 0.1, 0.05)
    local scanY = (time * 100) % (screenHeight + 100) - 50
    love.graphics.rectangle("fill", 0, scanY, screenWidth, 50)
end

function BackgroundManager:drawDiamond(x, y, size)
    love.graphics.polygon("fill",
        x, y - size,
        x + size, y,
        x, y + size,
        x - size, y
    )
end

function BackgroundManager:drawStar(x, y, size, points)
    local vertices = {}
    for i = 0, points * 2 do
        local angle = i * math_pi / points
        local radius = i % 2 == 0 and size or size * 0.4
        table_insert(vertices, x + math_cos(angle) * radius)
        table_insert(vertices, y + math_sin(angle) * radius)
    end
    love.graphics.polygon("fill", vertices)
end

return BackgroundManager
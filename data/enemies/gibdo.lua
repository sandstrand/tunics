local enemy = ...

local util = require 'lib/util'

-- Gibdo.
local started = false
local turning = false
function enemy:on_created()
  self:set_life(14)
  self:set_damage(4)
  self:set_pushed_back_when_hurt(false)
  self:set_push_hero_on_sword(false)
  self:set_size(16, 24)
  self:set_origin(8, 21)
end

local sprite = enemy:create_sprite("enemies/gibdo")

function enemy:on_restarted()
    turning = false
    self:on_movement_finished()
end

function enemy:on_obstacle_reached()
    
    self:on_movement_finished()
end

function enemy:on_movement_finished()
    local hero = self:get_map():get_hero()
    local _, _, layer = self:get_position()
    local _, _, hero_layer = hero:get_position()
    local near_hero =
        layer == hero_layer
        and self:is_in_same_region(hero)

    if near_hero and not turning then
        started = true
        self:turn_and_go()           
    end
end

function enemy:turn_and_go()
    local hero = self:get_map():get_hero()
    local hero_x, hero_y = hero:get_position()
    local self_x, self_y = self:get_position()
    local angle = sol.main.get_angle(self_x, self_y, hero_x, hero_y)
    local new_direction4 = util.get_direction4(angle)
    local direction4 = sprite:get_direction()
    local m = sol.movement.create("straight")
    local turn_direction4 = direction4

    sol.timer.start(self, 120, function()
        if turn_direction4 == new_direction4 then
            turning = false
            sprite:set_direction (turn_direction4) 
            m:set_angle(new_direction4 * math.pi / 2 )
            m:set_speed(54)
            m:set_max_distance(math.random(30,100))
            m:start(self)
                        
            return false
        else
            turning = true
            turn_direction4 = ( turn_direction4 + 1 ) % 4 
            sprite:set_direction (turn_direction4) 
            
            return true     
        end
    end)
end

function enemy:on_update()
    if not started then
        self:on_movement_finished()
    end
end    
     
local StyleBuilder = require 'lib/stylebuilder.lua'
local Prng = require 'lib/prng.lua'

local dungeon_styles = {
    {
        -- palette = 'dungeon.tower_of_hera.1';
        tier_introduction = 1,
        tileset = 'dungeon.tower_of_hera',
        floor = {
            scope = 'room',
            {
                high = { 'floor.12.a.high', 'floor.6.a.high' },
                low = { 'floor.13.a.low.' },
                p = 0.75,
            },
            {
                high = { 'floor.12.b.high', },
                low = { 'floor.13.a.low', },
                p = 0.25,
            },
        },
        wall_pillars = {
            scope = 'room',
            {
                socket = { 'pillar.4', },
                socketless = { 'pillar.4.socketless' },
            }
        },
        drapes = {
            scope = 'room',
            { nil },
        },
        statues = {
            scope = 'room',
            { 'statue.1', p = 0.25 },
            { 'statue.2'},
        },
        wall_statues = {
            scope = 'room',
            { 'wall_statue.6' },
        },
        barrier = {
            scope = 'dungeon',
            { 'barrier.1' },
        },
        hole = {
            scope = 'room',
            { 'hole' },
        },
        big_barrier = {
            scope = 'dungeon',
            { 'big_barrier.3' },
        },
        stage = {
            scope = 'dungeon',
            { 'stage.1' },
        },
        entrance = {
            scope = 'dungeon',
            { 'entrance.1' },
        },
        entrance_pillar = {
            scope = 'dungeon',
            { 'entrance_pillar.4' },
        },
        music = {
            scope = 'dungeon',
            { 'dungeon_light' },
        },
        destructibles = {
                pot = 'entities/vase',
                stone1 = 'entities/stone_white',
                stone2 = 'entities/stone_black',
        },
    },
};

local tier_complexity = {
    [1] = {
        keys=1,
        culdesacs=0,
        fairies=0,
        max_heads=3,
    },
    [3] = {
        keys=2,
        culdesacs=1,
        fairies=0,
        max_heads=4,
    },
    [5] = {
        keys=3,
        culdesacs=2,
        fairies=1,
        max_heads=5,
    },
    [10] = {
        keys=4,
        culdesacs=3,
        fairies=1,
        max_heads=6,
    },
}

local enemy_tier = {
    tentacle = 1,
    keese = 1,
    rat = 1,
    simple_green_soldier = 1,
    bari_blue = 2,
    rope = 2,
    crab = 2,
    green_knight_soldier = 2,
    bari_red = 3,
    poe = 3,
    blue_knight_soldier = 3,
    red_knight_soldier = 4,
    snap_dragon = 4,
    ropa = 4,
    hardhat_beetle_blue = 4,
    gibdo = 5,
    red_hardhat_beetle = 6,
    red_helmasaur = 6,
    bubble = 6,
}

local function choose_style(current_tier, rng)
    local mode = 'past'
    local styles = {}
    for _, style in pairs(dungeon_styles) do
        if style.tier_introduction == current_tier then
            if mode == 'past' then
                styles = {}
                mode = 'current'
            end
            table.insert(styles, style)
        elseif style.tier_introduction <= current_tier and mode == 'past' then
            table.insert(styles, style)
        end
    end
    local _, family = rng:ichoose(styles)
    return family
end

local function get_enemies(current_tier)
    local enemies = {}
    for enemy, tier in pairs(enemy_tier) do
        if tier <= current_tier then
            enemies[enemy] = tier
        end
    end
    return enemies
end

function get_complexity(current_tier)
    local max = 0
    local result = nil
    for tier, complexity in pairs(tier_complexity) do
        if tier <= current_tier and tier > max then
            max = tier
            result = complexity
        end
    end
    return result
end

local styles = {}

function styles.choose(current_tier, rng)

    function ident(elements)
        return elements
    end

    function scoped(elements, rng, f)
        f = f or ident
        if elements.scope == 'dungeon' then
            return function (self, room_name)
                local seq = rng:refine(current_tier):seq()
                local candidate = nil
                for _, element in ipairs(elements) do
                    if seq(element.p or 1.0) then
                        candidate = element
                    end
                end
                local _, result = rng:ichoose(f(candidate))
                return result
            end
        elseif elements.scope == 'room' then
            return function (self, room_name)
                zentropy.assert(room_name)
                local seq = rng:refine(current_tier):refine(room_name):seq()
                local candidate = nil
                for _, element in ipairs(elements) do
                    if seq(element.p or 1.0) then
                        candidate = element
                    end
                end
                local _, result = rng:ichoose(f(candidate))
                return result
            end
        else
            -- TODO trigger unknown-scope error
        end
    end

    local style_rng = Prng:new{ path=zentropy.game.get_seed() }:refine('style')
    local style_builder = StyleBuilder.new(style_rng)
    for _, v in ipairs(dungeon_styles) do
        style_builder:add_mapping(v)
    end
    style_builder = style_builder:dungeon(current_tier)

    local style = choose_style(current_tier, rng:refine('style'))
    local enemies = get_enemies(current_tier)
    local complexity = get_complexity(current_tier)
    local styles = {
        tileset=style.tileset,
        destructibles=style.destructibles,
        enemies=enemies,
        complexity=complexity,
        style_builder=style_builder,
    }
    return styles
end

return styles

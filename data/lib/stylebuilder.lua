local StyleBuilder = {}

local StyleBuilderProto = {}

local StyleBuilderMeta = {}

function StyleBuilderMeta.__index(table, key)
    return StyleBuilderProto[key]
end

function StyleBuilder.new(rng)
    o = {
        mappings = {},
        rng = rng,
    }
    o.quest_style = o,
    setmetatable(o, StyleBuilderMeta)
    return o
end

local group_names = {
    'barrier',
    'big_barrier',
    'drapes',
    'entrance',
    'entrance_pillar',
    'floor',
    'hole',
    'music',
    'stage',
    'statues',
    'wall_pillars',
    'wall_statues',
}

function StyleBuilderProto:_resolve_groups(scope)
    zentropy.assert(self.dungeon_style)
    local scope_style = self[scope .. '_style']
    local rng = scope_style.rng:refine('elect')
    scope_style.elect = {}
    for _, group_name in ipairs(group_names) do
        local group = self.dungeon_style.mapping[group_name]
        if group.scope == scope then
            local group_rng = rng:refine(group_name)
            local seq = group_rng:seq()
            local candidate
            for _, v in ipairs(group) do
                if seq(v.p or 1) then
                    candidate = v
                end
            end
            if table.getn(candidate) > 0 then
                local _, elect = group_rng:ichoose(candidate)
                scope_style.elect[group_name] = elect
            else
                scope_style.elect[group_name] = {}
                for k, v in pairs(candidate) do
                    if k ~= 'p' then
                        local _, elect = group_rng:refine(k):choose(v)
                        scope_style.elect[group_name][k] = elect
                    end
                end
            end
        end
    end
end

function StyleBuilderProto:dungeon(tier)
    local seq = self.quest_style.rng:seq()
    o = {
        quest_style = self.quest_style,
        tier = tier,
        rng = self.quest_style.rng:refine('tier_' .. tier),
        elect = {},
    }
    for _, mapping in ipairs(self.quest_style.mappings) do
        if tier >= mapping.tier_introduction then
            if seq(mapping.p or 1.0) then
                o.mapping = mapping
            end
        end
    end
    zentropy.assert(o.mapping)
    o.dungeon_style = o
    setmetatable(o, StyleBuilderMeta)
    o:_resolve_groups('dungeon')
    return o
end

function StyleBuilderProto:room(x, y)
    o = {
        quest_style = self.quest_style,
        dungeon_style = self.dungeon_style,
        x = x,
        y = y,
        rng = self.dungeon_style.rng:refine('room_' .. x .. '_' .. y),
        elect = {},
    }
    o.room_style = o
    setmetatable(o, StyleBuilderMeta)
    o:_resolve_groups('room')
    return o
end

function StyleBuilderProto:add_mapping(mapping)
    table.insert(self.quest_style.mappings, mapping)
    return o
end

function StyleBuilderProto:get_elect()
    local o = {}
    local mt = {}
    function mt.__index(t, k)
        return (self.room_style and self.room_style.elect[k]) or self.dungeon_style.elect[k]
    end
    setmetatable(o, mt)
    return o
end

return StyleBuilder

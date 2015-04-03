local zentropy = require 'lib/zentropy'
local util = require 'lib/util'
local Pause = require 'menus/pause'
local Prng = require 'lib/prng'

local dialog_box = require 'menus/dialog_box'

zentropy.init()

util.wdebug_truncate()

function sol.main:on_started()
    sol.language.set_language("en")

    local old_game = sol.game.load("zentropy1.dat")
    local overrides = {}
    for _, name in pairs{'override_seed', 'override_tileset', 'override_keys', 'override_fairies', 'override_culdesacs', 'override_treasure'} do
        overrides[name] = old_game:get_value(name)
    end

    sol.game.delete("zentropy1.dat")
    local game = sol.game.load("zentropy1.dat")
    game:set_ability("sword", 1)
    game:set_max_life(12)
    game:set_life(12)
    game:set_value('small_key_amount', 0)
    game:set_value('tier', 1)

    math.randomseed(os.time())
    game:set_value('seed', overrides.override_seed or math.random(32768 * 65536 - 1))
    print('Using seed: ' .. game:get_value('seed'))

    for name, value in pairs(overrides) do
        game:set_value(name, value)
    end

    local all_items = {
        'bomb',
        'hookshot',
        'lamp',
        'bow',
    }

    local rng = Prng.from_seed(game:get_value('seed'), game:get_value('tier'))
    local big_treasure = overrides.override_treasure or all_items[rng:random(#all_items)]
    for i, item_name in ipairs(all_items) do
        if item_name ~= big_treasure then
            local item = game:get_item(item_name)
            item:set_variant(1)
            item:on_obtained(item_name)
        end
    end

    game:save()

    require('lib/map_include.lua')
    sol.main.load_file("hud/hud")(game)

    game:set_starting_location('dungeons/dungeon1')

    game.dialog_box = dialog_box:new{game=game}

    local pause = Pause:new{game=game}

    function game:on_command_pressed(command)
        if command == 'pause' and game:is_paused() then
            game:save()
            print("saved")
        end
    end

    function game:on_paused()
        pause:start_pause_menu()
        self:hud_on_paused()
    end

    function game:on_unpaused()
        pause:stop_pause_menu()
        self:hud_on_unpaused()
    end
    
    function game:on_started()
        game:get_hero():set_walking_speed(160)
        self.dialog_box:initialize_dialog_box()
        self:initialize_hud()
    end

    -- Called by the engine when a dialog starts.
    function game:on_dialog_started(dialog, info)

        self.dialog_box.dialog = dialog
        self.dialog_box.info = info
        sol.menu.start(self, self.dialog_box)
    end

    -- Called by the engine when a dialog finishes.
    function game:on_dialog_finished(dialog)

        sol.menu.stop(self.dialog_box)
        self.dialog_box.dialog = nil
        self.dialog_box.info = nil
    end

    function game:on_finished()
        self:quit_hud()
        self.dialog_box:quit_dialog_box()
    end

    function game:on_map_changed(map)
        self:hud_on_map_changed(map)
    end

    game:start()
end

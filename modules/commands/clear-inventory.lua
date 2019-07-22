local Commands = require 'expcore.commands' --- @dep expcore.commands
local move_items = ext_require('expcore.common','move_items') --- @dep expcore.common
require 'config.expcore-commands.parse_roles'

Commands.new_command('clear-inventory','Clears a players inventory')
:add_param('player',false,'player-role-alive')
:add_alias('clear-inv','move-inventory','move-inv')
:register(function(player,action_player)
    local inv = action_player.get_main_inventory()
    move_items(inv.get_contents())
    inv.clear()
end)
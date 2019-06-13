--- Adds a module which can be used to avoid multiple requires and makes dev experce easier
--[[
    readme example

    local CustomModule =
    Construtor{
        on_custom_click = Construtor.event,
        global_data = Construtor.global,
        prototype = Construtor.prototype{
            name = Construtor.uid
            on_click = Construtor.event
            draw_data = {}
            some_boolean = false
        },
        other_data = {
            foo='test',
            bar=true
        },
    }

    will add to "CustomModule":
    _class - string - the id of the class
    new - function - returns a new instance of the class
    link - function - relinks an existing instance (because metatables not saved)
    get - function - gets the instance with the given id
    raise_event - function - will attempt to raise the even for the name given

    global_data - table - table it automatically synced with global module
    other_data - table - just a normal table with the keys shown above
    prototype - table - empty table where you can add functions, see below for what is added when created
    events.on_custom_click - number - event id returned by script.generate_event_name
    on_custom_click - function - adds a function as a handler for the on_custom_click event

    will add to "CustomModule.prototype":
    _class - string - the id of the class
    _uid - string - the id of the instance (starts at 1 for each class)
    raise_event - function - will attempt to call the function for the event given

    name - string - custom refrence to the uid
    draw_data - table - an empty table but each instance gets its own deapcopy
    some_boolean - boolean - a boolean value that is initiated to false
    events.on_click - function/nil - the current handler for the event if any
    on_click - function - registers a function as the handler for this event
]]

local Construtor = {}

return Construtor
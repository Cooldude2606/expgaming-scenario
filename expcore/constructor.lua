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

local Global = require 'utils.global'
local Event = require 'utils.event'
require 'table'

local Construtor = {
    global = {}, -- constant
    event = {}, -- constant
    classes = {},
    instances = {}
}

Global.register(Construtor.instances,function(tbl)
    Construtor.instances = tbl
end)

local function event_raise_factory(class)
    local events = class.events
    return function(name,event)
        local event_id = events[name]
        if not event_id then error('Event name '..name..' is not registered to this construct',2) end
        script.raise_event(event_id,event)
    end
end

local function event_handler_factory(event_id)
    return function(callback)
        Event.add(event_id,callback)
    end
end

local function new_prototype_factory(class)
    local classes = Construtor.classes
    local class_id = class._class
    local prototype = class._prototype
    local mt = {
        __call=prototype.__call,
        __index=prototype
    }
    local deapcopy = table.deapcopy
    local uid_alias = prototype._uid
    return function()
        local instance_id = #classes[class._class]+1
        local rtn = {
            _class = class_id,
            _uid = instance_id
        }
        if uid_alias then
            rtn[uid_alias] = instance_id
        end
        for key,value in pairs(prototype) do
            if type(value) ~= 'function' then
                rtn[key] = deapcopy(value)
            end
        end
        classes[class._class][instance_id] = rtn
        return setmetatable(rtn,mt)
    end
end

local function get_prototype_factory(class)
    local classes = Construtor.classes
    return function(instance_id)
        return classes[class._class][instance_id]
    end
end

local function raise_event_prototype_factory(prototype)
    local events = prototype.events
    return function(name,event)
        local handlers = events[name]
        if handlers then
            for _,callback in pairs(handlers) do
                callback(event)
            end
        else
            error('Event name '..name..' is not registered to this prototype',2)
        end
    end
end

local function event_handler_prototype_factory(name,prototype)
    local events = prototype.events
    return function(callback)
        local handlers = events[name]
        if handlers then
            handlers[#handlers+1] = callback
        else
            error('Event name '..name..' is not registered to this prototype',2)
        end
    end
end

function Construtor.class(data)
    local classes = Construtor.classes
    local class_id = #classes+1
    local rtn = {
        _class = class_id,
    }

    for key,value in pairs(data) do
        if value == Construtor.event then
            if not rtn.events then
                rtn.events = {}
                rtn.raise_event = event_raise_factory(rtn)
            end
            rtn.events[key] = script.generate_event_name()
            rtn[key] = event_handler_factory(rtn.events[key])

        elseif value == Construtor.global then
            rtn[key] = {}
            Global.register(rtn[key],function(tbl)
                rtn[key] = tbl
            end)

        elseif type(value) == 'table' then
            local tbl1 = value[1]
            if tbl1 == Construtor.prototype then
                local proto = value[2]
                proto._class = class_id
                rtn._prototype = proto
                rtn[key] = proto
                rtn.new = new_prototype_factory(rtn)
                rtn.get = get_prototype_factory(rtn)
            end
        end
    end

    classes[class_id] = rtn
    return rtn
end

function Construtor.prototype(data)
    local rtn = {}

    for key,value in pairs(data) do
        if value == Construtor.event then
            if not rtn.events then
                rtn.events = {}
                rtn.raise_event = raise_event_prototype_factory(rtn)
            end
            rtn.events[key] = {}
            rtn[key] = event_handler_prototype_factory(key,rtn)

        elseif value == Construtor.uid then
            rtn._uid = key
        end
    end

    return {Construtor.prototype,rtn}
end

return setmetatable(Construtor,{
    __call=function(self,data)
        return self.class(data)
    end
})
--[[
    使用范例
        local ps = require("base.properties").new()
        ps:on("hp", function (old, new)
            print("property changed", old, new)
        end)
        ps.hp = 10
        print(ps.hp)
        ps.hp = 20
        print(ps.hp)
]]


local type
type = setmetatable({
    __index = function (self, key)
        local member = type[key]
        if member then 
            return member
        end
        local dict = rawget(self, "__dict")
        local val = dict[key] 
        return val ~= nil and val or 0
    end, 

    __newindex = function (self, key, newValue)
        local dict = rawget(self, "__dict")
        local dict_val = dict[key] 
        local oldValue = dict_val ~= nil and dict_val or 0
        if oldValue ~= newValue then 
            dict[key] = newValue
            local ev = rawget(self, "__events")
            ev:dispatch(key, oldValue, newValue)
            ev:dispatch("", key, oldValue, newValue)
        end
    end, 

    foreach = function (self, callback)
        local dict = rawget(self, "__dict")
        for k, v in pairs(dict) do 
            callback(k, v)
        end
    end, 
    
    add = function (self, key, value)
        if value ~= 0 then 
            local dict = rawget(self, "__dict")
            local dict_val = dict[key] 
            local oldValue = dict_val ~= nil and dict_val or 0
            local newValue = oldValue + value
            
            dict[key] = newValue
            local ev = rawget(self, "__events")
            ev:dispatch(key, oldValue, newValue)
            ev:dispatch("", key, oldValue, newValue)
        end
    end, 

    on = function (self, key, handler)
        local ev = rawget(self, "__events")
        ev:add(key, handler)
    end, 

    clear = function (self)
        rawset(self, "__dict", {})
        local ev = rawget(self, "__events")
        ev:clear()
    end, 

    new = function ()
        local ps = {
            __dict = {},
            __events = require("base.events").new()
        }
        setmetatable(ps, type)
        return ps
    end, 
}, {
    __call = function (self)
        return type.new()
    end, 
})

return type

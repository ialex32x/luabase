--[[
    范例代码
        local e = enum { 
            "a", 
            "b", 
            "c", 
            ["d"] = "test", 
            ["e"] = 1, 
        }
        print(e.a, e.d)
        assert(e.a == e.a)
        assert(e.a ~= e.e)
        assert(e.d.class == e)
		print(e.b.rawValue)
		print(e.rawValue(2) == e.b)
]]

local enum_class = {
    __index = function (self, key)
        local raw = rawget(self, "__raw")
        return raw[key]
    end, 
}

local enum_value_class = {
    __tostring = function (self)
        if self.name == self.rawValue then 
            return self.name
        end
        return self.name .. "(" .. self.rawValue .. ")"
    end, 
    -- __eq = function (self, other)
    -- end, 
}

local make_enum_value = function (enum, ev_name, ev_val)
    local enum_value = {
        class = enum,
        name = ev_name, 
        rawValue = ev_val,
        equals = function (self, other)
            return other == self or other == ev_val
        end, 
    }
    setmetatable(enum_value, enum_value_class)
    return enum_value
end

local enum_inst_maker = function (self, kv)
    local raw = {}
    local index = 1
    local index_min = math.huge
    local fallback
    local enum = {
        __raw = raw,

        -- 从原始值返回枚举值
        rawValue = function (value)
            for k, v in pairs(raw) do 
                if v.rawValue == value then 
                    return v
                end
            end
            return fallback
        end, 
    }

    for ev_name, ev_val in pairs(kv) do 
        local enum_value
        if type(ev_name) == "number" then 
            enum_value = make_enum_value(enum, ev_val, index)
            raw[ev_val] = enum_value
            if fallback == nil or index < index_min then 
                index_min = index
                fallback = enum_value
            end
            index = index + 1
        else
            enum_value = make_enum_value(enum, ev_name, ev_val)
            raw[ev_name] = enum_value
            if type(ev_val) == "number" then 
                if fallback == nil or ev_val < index_min then 
                    index_min = ev_val
                    fallback = enum_value
                end
            end
        end
    end
    setmetatable(enum, enum_class)
    return enum 
end

return setmetatable({}, {
    __index = {
        strings = function (keys)
            local t = {}
            for _, v in ipairs(keys) do 
                t[v] = v
            end
            return enum_inst_maker(nil, t)
        end, 
    }, 
    __call = enum_inst_maker, 
})

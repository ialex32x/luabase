DelegateType = {}

function DelegateType:New(valueType)
    local delegateType = {}
    delegateType.valueType = valueType
	delegateType.callbacks = {}
    setmetatable(delegateType, self)
    self.__index = function(t, k)
		if k == "value" then
			return t["trick"]
		end
		
		return getmetatable(t)[k]
	end
    self.__newindex = function(t, k, v)
        if self.valueType ~= nil and type(v) ~= self.valueType then
            return
        end
		rawset(t, "trick", v)
		t.Call(t.callbacks, t)
	end
    return delegateType
end

function DelegateType:AddListener(func, caller)
    table.insert(self.callbacks, {func = func, caller = caller})
end

function DelegateType:RemoveListener(func, caller)
    for i = 1, #self.callbacks do
        if self.callbacks[i].func == func and self.callbacks[i].caller == caller then
            table.remove(self.callbacks, i)
            break
        end
    end
end

function DelegateType.Call(table, ...)
    for key, value in ipairs(table) do
        if value.caller then
            value.func(value.caller, ...)
        else
            value.func(...)
        end
    end
end
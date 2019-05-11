local super = require("bt.composite")
local states = super.states

return class {
    typename = "顺序节点", 
    super = super, 

    ctor = function (self, repeats, ...)
        super.ctor(self, ...)
        self.repeats = repeats or 0
    end,

    enter = function (self)
        local child
        self.repeated = 0
        self.index = 0
        while true do
            self.index = self.index + 1
            child = self.children[self.index]
            if not child then 
                self.repeated = self.repeated + 1
                if self.repeats > 0 and self.repeated >= self.repeats then 
                    return false
                end
                self.index = 0
            else
                if child:enter() then 
                    return true
                end 
            end
        end
    end, 

    update = function (self, dt)
        local child = self.children[self.index]
        if child then 
            local ret = child:update(dt)
            if ret == states.END then 
                while true do
                    self.index = self.index + 1
                    child = self.children[self.index]
                    if not child then 
                        self.repeated = self.repeated + 1
                        if self.repeats > 0 and self.repeated >= self.repeats then 
                            break
                        end
                        self.index = 0
                    else
                        if child:enter() then 
                            return states.RUN
                        end 
                    end
                end
                return states.END
            end
            return states.RUN
        end
        return states.END
    end, 

    clone = function (self)
        local inst = self.class.new(self.repeats)
        for _, child in ipairs(self.children) do 
            inst:add(child:clone())
        end
        return inst
    end, 
}
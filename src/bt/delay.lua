local super = require("bt.node")
local states = super.states

return class {
    super = super, 

    ctor = function (self, min, max)
        self.min = min
        self.max = max
    end, 

    enter = function (self)
        self.elapsed = math.random() * (self.min + self.max) - self.min
        return true
    end, 

    update = function (self, dt)
        self.elapsed = self.elapsed - dt
        if self.elapsed < 0 then 
            return states.END
        end
        return states.RUN
    end, 

    clone = function (self)
        return self.class.new(self.min, self.max)
    end, 
}
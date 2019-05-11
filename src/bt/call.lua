local super = require("bt.node")
local states = super.states

return class {
    super = super, 

    ctor = function (self, time, callback)
        self.time = time
        self.callback = callback
    end, 

    enter = function (self)
        self.elapsed = 0
        return true
    end, 
    
    setContext = function (self, ctx)
        self.ctx = ctx
    end, 

    destroy = function (self)
        self.ctx = nil
        super.destroy(self)
    end, 

    update = function (self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= self.time then 
            self.elapsed = 0
            return self.callback(self.ctx) and states.RUN or states.END
        end
        return states.RUN
    end, 

    clone = function (self)
        return self.class.new(self.time, self.callback)
    end, 
}
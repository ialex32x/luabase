local super = require("bt.composite")
local states = super.states

return class {
    typename = "并发节点", 
    super = super, 

    enter = function (self)
        
    end, 

    update = function (self, dt)
        return states.END
    end, 
}
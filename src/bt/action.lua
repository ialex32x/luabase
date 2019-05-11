local super = require("bt.node")

return class {
    super = super, 

    enter = function (self)
        return true
    end, 

    setContext = function (self, ctx)
        self.ctx = ctx
    end, 
}

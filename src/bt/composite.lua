local super = require("bt.node")

return class {
    super = super, 

    ctor = function (self, ...)
        self.children = { ... }
    end, 

    setContext = function (self, ctx)
        for _, child in ipairs(self.children) do 
            child:setContext(ctx)
        end
    end, 

    add = function (self, node)
        table.insert(self.children, node)
        return self
    end, 

    clone = function (self)
        local inst = self.class.new()
        for _, child in ipairs(self.children) do 
            inst:add(child:clone())
        end
        return inst
    end, 
}

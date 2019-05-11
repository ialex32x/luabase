
return class {
    states = enum {
        "RUN", "END", 
    }, 

    setContext = function (self, ctx)
    end, 

    destroy = function (self)
        if self.__mgr then 
            self.__mgr:add(self)
        end
    end, 
}

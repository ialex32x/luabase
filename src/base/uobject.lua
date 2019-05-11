return class {
    ctor = function (self, base)
        self.__base = base
    end, 

    actived = {
        getter = function (self)
            return self:GetActive()
        end, 
        setter = function (self, newValue)
            self:SetActive(newValue)
        end, 
    },

    parent = {
        getter = function (self)
            return self:GetParent()
        end, 
        setter = function (self, newValue)
            self:AttachTo(newValue)
        end,
    }, 

    destroy = function (self, is_force_destroy)
        if self.__base then 
            Object.DestroyImmediate(self.__base)
            self.__base = nil
        end
    end, 
}
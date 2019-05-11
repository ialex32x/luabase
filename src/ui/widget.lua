
return class {
    typename = "WrapWidget", 
    
    ctor = function (self, native)
        self.__base = native
    end, 

    visible = {
        getter = function (self)
            return self:GetActive()
        end, 
        setter = function (self, value)
            self:SetActive(value)
        end, 
    }, 

    -- interactable = {
    --     getter = function (self)
    --         return self.__native.interactable
    --     end, 
    --     setter = function (self, value)
    --         self.__native.interactable = value
    --     end, 
    -- }, 
}
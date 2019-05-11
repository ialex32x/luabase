local super = require "ui.widget"

return class {
    typename = "InputField", 
    super = super,
    
    ctor = function (self, native)
        super.ctor(self, native)
        
        if native then 
        end
    end, 

    -- text = {
    --     getter = function (self)
    --         return self.__native.text
    --     end, 
    --     setter = function (self, value)
    --         self.__native.text = value
    --     end, 
    -- }
}
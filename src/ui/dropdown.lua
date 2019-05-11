local super = require "ui.widget"

return class {
    typename = "Dropdown", 
    super = super,

    EVT_VALUE_CHANGED = "EVT_VALUE_CHANGED",
    
    ctor = function (self, native)
        self.__native = native

        super.ctor(self, native:Unwrap())
        self.events = unity.events()

        self._onValueChanged = function (value)
            self.events:dispatch(self.EVT_VALUE_CHANGED, value)
        end
        
        if native then 
        end
    end, 

    text = {
        getter = function (self)
            return self.__native.text
        end, 
    }, 

    value = {
        getter = function (self)
            return self.__native.value
        end, 
        setter = function (self, value)
            self.__native.value = value
        end, 
    }, 

    on = function (self, evt, fn)
        if evt == self.EVT_VALUE_CHANGED then 
            if self.events:sizeof(self.EVT_VALUE_CHANGED) == 0 then 
                self.__native:AddValueChangedListener(self._onValueChanged)
            end
            self.events:on(evt, fn)
        end
    end, 

    off = function (self, evt, fn)
        if evt == self.EVT_VALUE_CHANGED then 
            if fn then 
                self.events:off(evt, fn)
                if self.events:sizeof(self.EVT_VALUE_CHANGED) == 0 then 
                    self.__native:RemoveValueChangedListener(self._onValueChanged)
                end
            else
                self.events:clear(evt)
                self.__native:ClearValueChangedListener(self._onValueChanged)
            end
        end
    end, 

    clear = function (self)
        self.__native:Clear()
    end, 

    remove = function (self, option)
        return self.__native:RemoveOption(option)
    end, 

    add = function (self, option)
        return self.__native:AddOption(option)
    end, 
}
local super = require "ui.widget"

return class {
    typename = "WrapButton", 
    super = super,
    
    ctor = function (self, native)
        super.ctor(self, native)
        
        if native then 
            self._text = self:GetComponentInChildren(UnityEngine.UI.Text)
        end
    end, 

    text = {
        getter = function (self)
            return self._text.text
        end, 

        setter = function (self, text)
            self._text.text = text
        end, 
    }, 
}
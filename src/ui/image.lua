local super = require "ui.widget"

return class {
    typename = "WrapImage", 
    super = super,
    
    ctor = function (self, native)
        super.ctor(self, native)
    end, 

    -- deprecated: 直接通过 unity.extension (GameObject/Component) 支持
    -- SetSprite = function (self, filename)
    --     Fenix.UI.SpriteHandle.Load(self.gameObject, filename)
    -- end, 
}

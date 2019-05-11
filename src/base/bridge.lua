
return class {
    ctor = function (self, name)
        local fn = function (f)
                return functor.make(f, self)
        end
        self.bridge = Fenix.UnityBridge.CreateBridge(name, fn(self.onStart), fn(self.onEnable), fn(self.onDisable), fn(self.onDestroy))
        self.bridge:SetUpdate(function (dt)
            self:onUpdate(dt)
        end)
    end, 

    startCoroutine = function (self, fn)
        return self.bridge:StartCoroutine(fn)
    end, 

    -- 该函数构造时会被捕捉，如果要覆盖，比如采用继承的方式
    onStart = function (self)
    end, 

    -- 该函数构造时会被捕捉，如果要覆盖，比如采用继承的方式
    onEnable = function (self)
    end, 

    -- 该函数构造时会被捕捉，如果要覆盖，比如采用继承的方式
    onDisable = function (self)
    end, 

    -- 该函数构造时会被捕捉，如果要覆盖，比如采用继承的方式
    onDestroy = function (self)
        self.bridge = nil
    end, 

    -- 该函数可以直接修改实例变量进行修改
    onUpdate = function (self, deltaTime)
    end, 
}
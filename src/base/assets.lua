return class {
    typename = "资源组",
    description = "等待一组资源全部加载完毕", 

    alias = function (self, name)
        self.name = name
        return self
    end, 

    __index = function (self, key)
        return self:get(key)
    end, 

    ctor = function (self, assets)
        self.assets = {}
        self.loaded = 0
        self.events = unity.new("base.events")

        self.onLoaded = function ()
            self.loaded = self.loaded + 1
            if self.loaded == #self.assets then 
                self.events:dispatch("loaded", self)
                self.events:wipe()
            end
        end

        if assets then 
            for k, v in ipairs(assets) do 
                local asset
                if type(v) == "string" then 
                    asset = unity.asset(v)
                elseif v.class then
                    asset = v
                else
                    asset = unity.asset(v[1], v[2])
                end
                table.insert(self.assets, asset)
                asset:load(self.onLoaded)
            end
        end
    end, 

    get = function (self, index)
        if type(index) == "number" then 
            return self.assets[index]
        else
            for k, v in ipairs(self.assets) do 
                if v.name == index then 
                    return v
                end
            end
        end
    end, 

    add = function (self, asset)
        table.insert(self.assets, asset)
        asset:load(self.onLoaded)
        return self
    end, 

    load = function (self, fn)
        if self.loaded == #self.assets then 
            fn(self)
        else
            self.events:on("loaded", fn)
        end
    end, 
}
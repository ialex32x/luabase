--[[
-- 自动维护引用计数的资源封装, 通过gc自动触发引用计数修改

local asset = unity.asset("Assets/Art/Experimental/Cube.prefab")
print(game.frameCount)
asset:load(function (obj)
    print(obj, game.frameCount)
end)

game:startCoroutine(function ()
    coroutine.yield(nil)
    print(game.frameCount)
    asset = nil
    while true do 
        unity.gc()
        coroutine.yield(nil)
    end
end)

]]
return class {
    ctor = function (self, ...)
        local argc = select("#", ...)
        local assetPath, assetType, assetName

        if argc == 2 or argc == 3 then 
            assetPath, assetType, assetName = ...
        elseif argc == 1 then 
            local desc = ...
            if type(desc) == "table" then 
                assetPath, assetType, assetName = desc[1], desc[2], desc[3]
            end
        end
        if assetPath then 
            if assetType then 
                self.asset = AssetHelper.LoadAsync(assetPath, assetType)
            else
                self.asset = AssetHelper.LoadAsync(assetPath)
            end
            self.name = assetName or assetPath
        else 
            error("ctor got invalid arguments")
        end
    end, 

    alias = function (self, name)
        self.name = name
        return self
    end, 

    -- 快捷方式，假定当前资源为TextAsset
    text = {
        getter = function (self)
            return self.asset:Get().text
        end, 
    },

    object = {
        getter = function (self)
            return self.asset:Get()
        end, 
    },

    load = function (self, fn)
        if self.asset.isDone then 
            -- print("ready load")
            fn(self.asset:Get())
        else
            if not self.events then 
                self.events = unity.new("base.events")
                self.events:on("loaded", fn)
                self.asset:SetListener(function (obj)
                    self.events:dispatch("loaded", obj)
                    self.events:wipe()
                end)
            else 
                self.events:on("loaded", fn)
            end
        end
    end, 

    instantiate = function (self, fn)
        self:load(function (obj)
            fn(unity.instantiate(obj))
        end)
    end, 

    destroy = function (self)
        if self.asset then 
            self.asset:Dispose()
            self.asset = nil
        end

        if self.events then 
            self.events:clear()
            self.events = nil
        end
    end, 

    finalize = function (self)
        self.asset = nil -- 自动回收
        -- print("asset.lua finalize")
    end, 
}
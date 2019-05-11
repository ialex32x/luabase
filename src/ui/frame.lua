local ButtonWrapper = require("ui.button")
local ImageWrapper = require("ui.image")
local TextWrapper = require("ui.text")
local DropdownWrapper = require("ui.dropdown")
local InputFieldWrapper = require("ui.inputfield")
local WidgetWrapper = require("ui.widget")

return class {
    extensions = "ui/frame+handler.lua", 
    --__unsafe = true, 

    layer = {
        getter = function (self)
            return self.__layer
        end, 
        setter = function (self, value)
            if self.__layer ~= value then 
                self.__layer = value
                if self.__loader then 
                    self.__loader.layer = value
                end
            end
        end, 
    },

    -- params:
    --     parent 被创建frame的父节点(gameObject/transform), 同时也是 Frame 组件的容器
    ctor = function (self, parent, name)
        self.__layer = -1
        if parent and parent.gameObject then 
            self.__loader = unity.object(parent.gameObject:AddComponent(Fenix.Assets.PrefabLoader))
            self.__loader.layer = self.layer
        end
        self.name = name
        -- 通过 Find 查询的所有元素的 cache 记录 (结果经过 lua 封装, 不一定是直接本地类实例)
        self._transforms = {}
    end, 

    finalize = function (self)
        -- print("finalize frame", self.name)
    end, 

    visible = {
        getter = function (self)
            return self.__loader.enabled
        end, 
        setter = function (self, value)
            self.__loader.enabled = value
            if value then 
                self:onShow()
            else 
                self:onHide()
            end
        end, 
    }, 

    -- static
    _new = function (cls, args, ...)
        local inst = nil
        if type(args.parent) == "string" then 
            local parent = UnityEngine.GameObject.Find(args.parent)
            inst = cls.new(parent, args.name)
        else
            inst = cls.new(args.parent, args.name)
        end
        
        if inst then
            inst:onInit(...)
            inst.gameObject = args.gameObject
            if args.args then 
                for k, v in pairs(args.args) do 
                    inst[k] = v
                end
            end
            if args.events then 
                for k, v in pairs(args.events) do 
                    inst:on(k, v)
                end
            end
            if args.asset then 
                inst:load(args.asset)
            end
        end
        return inst
    end, 

    -- 静态方法, 创建指定的 frame 类
    -- template: string
    -- parent: gameObject or transform or string
    -- name: string
    -- asset: string or IAsset
    CreateFrame = function (args)
        local cls_name = args.class or args.template
        local cls = type(cls_name) == "string" and require(cls_name) or cls_name
        return cls:_new(args)
    end,

    load = function (self, asset)
        if self.__loader then 
            self.__loader:Load(asset, function (gameObject)
                self.isLoaded = true
                self._error = gameObject == nil
                self:onLoad(gameObject)
            end)
        end
    end, 

    destroy = function (self)
        if self.__loader then 
            self.__loader:destroy()
            self.__loader = nil
        end
        self:onUnload()
        self._transforms = nil
    end, 

    events = {
        getter = function (self)
            local events = self._events
            if events == nil then 
                events = require("base.events").new()
                self._events = events
            end
            return events
        end, 
    }, 
    
    dispatch = function (self, evt_name, ...)
        local events = self._events
        if events then 
            events:dispatch(evt_name, self, ...)
        end
    end, 
    
    -- it returns the handler entry id
    on = function (self, evt_name, handler)
        return self.events:add(evt_name, handler)
    end, 

    -- 可以传入 handle_id 或者 handler 本身
    off = function (self, evt_name, handler)
        return self.events:remove(evt_name, handler)
    end, 

    -- 构造完成时
    onInit = function (self)
    end, 

    -- 资源加载完成时
    onLoad = function (self)
    end, 

    -- 界面销毁时
    onUnload = function (self)
    end, 

    onShow = function (self)
    end, 

    onHide = function (self)
    end, 

    -- 设置文本组件的文本内容
    setText = function (self, name, str)
        local text = self:findText(name)
        if text then
            text.text = str 
        end
        return text
    end, 

    -- 设置name按钮文本
    setButtonText = function (self, name, str)
        local btn = self:findButton(name)
        if btn then
            btn.text = str 
        end
        return btn
    end, 

    setSprite = function (self, name, assetPath)
        --print(name, assetPath)
        local image = self:findImage(name)
        if image then
            image:SetSprite(assetPath) 
        end
        return image
    end, 

    find = function (self, name)
        if self.__loader then 
            return self.__loader:Find(name)
        end
    end, 

    findSlider = function (self, name)
        return self:_getWrapper(name, UnityEngine.UI.Slider)
    end, 

    findButton = function (self, name)
        return self:_getWrapper(name, UnityEngine.UI.Button)
    end, 

    findImage = function (self, name)
        return self:_getWrapper(name, UnityEngine.UI.Image)
    end, 

    findText = function (self, name)
        return self:_getWrapper(name, UnityEngine.UI.Text)
    end, 

    findInputField = function (self, name)
        return self:_getWrapper(name, UnityEngine.UI.InputField)
    end, 

    findDropdown = function (self, name)
        return self:_getWrapper(name, Fenix.UI.DropdownWrapper)
    end, 

    -- donot_wrap: 不产生lua包装器，直接将c#对象存入
    _getWrapper = function (self, path, type_cls, donot_wrap)
        local transform_wrap = self._transforms[path]

        if not transform_wrap then
            local result = self:find(path)
            if result then 
                transform_wrap = { result }
            else
                transform_wrap = { "nil" }
                print("transform", path, "[", self.transform, "] not exist for type", type_cls)
                -- logger.error("transform", path, "[", self.transform, "] not exist for type", type_cls)
            end
            self._transforms[path] = transform_wrap 
        end
        local transform = transform_wrap[1]
        if transform == "nil" then 
            return nil
        end

        local type_inst_wrap = transform_wrap[type_cls]
        if not type_inst_wrap then 
            if type_cls == UnityEngine.Transform then 
                type_inst_wrap = donot_wrap and transform or WidgetWrapper.new(transform)
            else
                local native_obj = transform:GetComponent(type_cls) or transform.gameObject:AddComponent(type_cls)

                if native_obj == nil then
                    type_inst_wrap = "nil"
                else 
                    if donot_wrap then 
                        type_inst_wrap = native_obj
                    else
                        if type_cls == UnityEngine.UI.Button then
                            type_inst_wrap = ButtonWrapper.new(native_obj)
                        elseif type_cls == UnityEngine.UI.InputField then
                            type_inst_wrap = InputFieldWrapper.new(native_obj)
                        elseif type_cls == Fenix.UI.DropdownWrapper then
                            type_inst_wrap = DropdownWrapper.new(native_obj)
                        elseif type_cls == UnityEngine.UI.Image then 
                            type_inst_wrap = ImageWrapper.new(native_obj)
                        elseif type_cls == UnityEngine.UI.Text then 
                            type_inst_wrap = TextWrapper.new(native_obj)
                        else
                            type_inst_wrap = WidgetWrapper.new(native_obj)
                            -- print("wrap", path, native_obj)
                        end 
                    end
                end
            end
            transform_wrap[type_cls] = type_inst_wrap
        end
        --print("GetWrapper", path, type_cls, type_inst_wrap)
        return type_inst_wrap == "nil" and nil or type_inst_wrap 
    end,

    clearScript = function (self, evt, name)
        if evt == "click" then -- 单击 (必须是 Button 组件)
            return self:UnregisterClick(name)
        elseif evt == "drag" then  -- 拖拽
            return self:UnregisterDrag(name)
        elseif evt == "drop" then  -- 拖拽放下
            return self:UnregisterDrop(name)
        elseif evt == "updown" then -- 按下/抬起
            return self:UnregisterUpDown(name)
        elseif evt == "single" then 
            -- 单击, 与 click 的区别在于有 eventData 参数, 可以判定出drag状态下产生的单击事件
            -- 另外 click 目标对象必须是 Button 组件, single 可以为任意组件
            return self:UnregisterSingleClick(name)
        elseif evt == "double" then  -- 双击
            return self:UnregisterDoubleClick(name)
        elseif evt == "hover" then  -- 悬停(enter/exit)
            return self:UnregisterHover(name)
        elseif evt == "scroll" then 
            return self:UnregisterScroll(name)
        end
        return nil
    end,

    setScript = function (self, evt, name, callback)
        if evt == "click" then -- 单击 (必须是 Button 组件)
            return self:RegisterClick(name, callback)
        elseif evt == "drag" then  -- 拖拽
            return self:RegisterDrag(name, callback)
        elseif evt == "drop" then  -- 拖拽放下
            return self:RegisterDrop(name, callback)
        elseif evt == "updown" then -- 按下/抬起
            return self:RegisterUpDown(name, callback)
        elseif evt == "single" then 
            -- 单击, 与 click 的区别在于有 eventData 参数, 可以判定出drag状态下产生的单击事件
            -- 另外 click 目标对象必须是 Button 组件, single 可以为任意组件
            return self:RegisterSingleClick(name, callback)
        elseif evt == "double" then  -- 双击
            return self:RegisterDoubleClick(name, callback)
        elseif evt == "hover" then  -- 悬停(enter/exit)
            return self:RegisterHover(name, callback)
        elseif evt == "scroll" then 
            return self:RegisterScroll(name, callback)
        end
        return nil
    end,
}
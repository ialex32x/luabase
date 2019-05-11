return {

    RegisterClick = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.ButtonHandler) 
        if handler then 
            handler:AddClickListener(function ()
                callback()
            end)
        end
        return handler
    end, 

    UnregisterClick = function (self, name)
        local handler = self:_getWrapper(name, Fenix.UI.ButtonHandler) 
        if handler then 
            handler:ClearClickListener()
        end
        return handler
    end, 

    RegisterDrag = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.DragHandler, true)
        if handler then 
            handler:AddBeginListener(function (eventData)
                callback(eventData, "begin")
            end)
            handler:AddDragListener(function (eventData)
                callback(eventData, "drag")
            end)
            handler:AddEndListener(function (eventData)
                callback(eventData, "end")
            end)
        end
        return handler
    end,

    UnregisterDrag = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.DragHandler, true)
        if handler then 
            handler:ClearBeginListener()
            handler:ClearDragListener()
            handler:ClearEndListener()
        end
        return handler
    end,

    RegisterDrop = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.DropHandler, true)
        if handler then 
            handler:AddDropListener(function (eventData)
                callback(eventData)
            end)
        end
        return handler
    end,

    UnregisterDrop = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.DropHandler, true)
        if handler then 
            handler:ClearDropListener()
        end
        return handler
    end,

    RegisterUpDown = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.PointerHandler, true)
        if handler then 
            handler:AddUpListener(function (eventData)
                callback(eventData, "up")
            end)

            handler:AddDownListener(function (eventData)
                callback(eventData, "down")
            end)
        end
        return handler
    end,

    UnregisterUpDown = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.PointerHandler, true)
        if handler then 
            handler:ClearUpListener()
            handler:ClearDownListener()
        end
        return handler
    end,

    RegisterSingleClick = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.PointerHandler, true)
        if handler then 
            handler:AddClickListener(function (eventData)
                callback(eventData)
            end)
        end
        return handler
    end,

    UnregisterSingleClick = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.PointerHandler, true)
        if handler then 
            handler:ClearClickListener()
        end
        return handler
    end,

    RegisterDoubleClick = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.PointerHandler, true)
        if handler then 
            handler:AddDoubleClickListener(function (eventData)
                callback(eventData)
            end)
        end
        return handler
    end,

    UnregisterDoubleClick = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.PointerHandler, true)
        if handler then 
            handler:ClearDoubleClickListener()
        end
        return handler
    end,

    RegisterHover = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.HoverHandler, true)
        if handler then 
            handler:AddEnterListener(function (eventData)
                callback(eventData, "enter")
            end)
            handler:AddExitListener(function (eventData)
                callback(eventData, "exit")
            end)
        end
        return handler
    end, 

    UnregisterHover = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.HoverHandler, true)
        if handler then 
            handler:ClearEnterListener()
            handler:ClearExitListener()
        end
        return handler
    end, 

    RegisterScroll = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.ScrollHandler, true)
        if handler then 
            handler:AddScrollListener(function (eventData)
                callback(eventData)
            end)
        end
        return handler
    end, 

    UnregisterScroll = function (self, name, callback)
        local handler = self:_getWrapper(name, Fenix.UI.ScrollHandler, true)
        if handler then 
            handler:ClearScrollListener()
        end
        return handler
    end, 
}
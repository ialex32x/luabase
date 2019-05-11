local _app = Fenix.App.GetInstance()
local _traceback = _app.debug

return class {
    gameObject = {
        getter = function (self)
            return _app.gameObject
        end, 
    },

    isEditor = {
        getter = function (self)
            return Application.isEditor
        end, 
    },

    traceback = {
        getter = function (self) return _traceback end , 
        setter = function (self, newValue)
            if newValue ~= _traceback then 
                _traceback = newValue
                Fenix.App.SetTracebackEnabled(_traceback)
            end
        end, 
    },

    quit = function (self)
        Application.Quit()
    end, 
    
    startCoroutine = function (self, func)
        _app:StartCoroutine(func)
    end, 
}.new()

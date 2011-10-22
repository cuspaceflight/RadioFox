
import wx
from wx import xrc

class wxMeta(object):
    def __init__(self, xrcfile, main_frame_name):
        object.__setattr__(self, '_res', xrc.XmlResource(xrcfile))
        frame = self._res.LoadFrame(None, main_frame_name)
        object.__setattr__(self, '_frame', frame)

    def __getattribute__(self, name):
        try:
            return object.__getattribute__(self, name)
        except:
            obj = xrc.XRCCTRL(self._frame, name)
            if obj:
                return obj
            else:
                raise AttributeError("'%s' is not an attribute or XRC name" % name)

    def __setattr__(self, name, value):
        (prefix, sep, control) = name.partition('_')
        if sep == '_':
            event_handlers = {
                    'OnClick':wx.EVT_BUTTON,
                    'OnPaint':wx.EVT_PAINT,
                    'OnIdle':wx.EVT_IDLE,
                    'OnMouse':wx.EVT_MOUSE_EVENTS,
                    'OnSpin':wx.EVT_SPINCTRL,
                    'OnClose':wx.EVT_CLOSE
            }
            try:
                #print "Event handler %s added to %s" % (prefix, control)
                #self._frame.Bind(event_handlers[prefix], value, self.__getattribute__(control))
                self.__getattribute__(control).Bind(event_handlers[prefix], value)

            except KeyError:
                raise AttributeError("Cannot set '%s', not an event handler" % name)
        else:
            raise AttributeError("Cannot set '%s', not an event handler" % name)

class SimpleApp(wx.App):
    def __init__(self, xrcfile, main_frame_name):
        self.__xrcfile = xrcfile
        self.__main_frame_name = main_frame_name
        wx.App.__init__(self, redirect=False)

    def OnInit(self):
        self.controls = wxMeta(self.__xrcfile, self.__main_frame_name)
        result = self.Init()
        self.controls._frame.Show()
        return result

    def Init(self):
        # user code overloads this function
        pass

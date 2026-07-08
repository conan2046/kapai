
local NewActiveCodeUI = LUIBase:New()
NewActiveCodeUI.__index = NewActiveCodeUI
--local this = LTcpSocket
function NewActiveCodeUI:New()
	local o = LUIBase:New()
	setmetatable(o,NewActiveCodeUI)	
    o:Init()
	return o
end


function NewActiveCodeUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/JihuomaLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local into = self.m_pUILayer:getChildByName("Jihuo"):getChildByName("Into")
    local input = into:getChildByName("Image_Bg"):getChildByName("Bg")
    local pInputTextTemp = input:getChildByName("TextField")
    self._fontSize = pInputTextTemp:getFontSize()
    self._fontName = pInputTextTemp:getFontName()

    if GameSdk.androidTruePhone then
        self._textField = pInputTextTemp
        self._textField:setCursorEnabled(true)
        self._textField:setInsertText(true)
        self._textField:setPlaceHolderColor(AppDef.UIColor.WHITE)
    else
        pInputTextTemp:setVisible(false)
        local sizeText = pInputTextTemp:getContentSize()
        local bg = cc.Scale9Sprite:create()
        self._textField = ccui.EditBox:create(cc.size(sizeText.width, sizeText.height),bg)
        self._textField:setPosition(pInputTextTemp:getPosition())
        self._textField:setAnchorPoint(pInputTextTemp:getAnchorPoint())
        input:addChild(self._textField)
        self._textField:setPlaceholderFontColor(AppDef.UIColor.WHITE)
        self._textField:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        self._textField:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
        self._textField:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        self._textField:setMaxLength(50)
    end

    local btn_Confirm = into:getChildByName("btn_Retrieve")
    local function ConfirmEvent( sender )
        local code = self:getFieldString()
        if string.len(code) <= 0 then
        	return
        end
        --print("NewActiveCodeUI:getFieldString",code)
        LuaNetSendMsg:QueryActiveCode(18, code)
        self._textField:setText("")
    end
    btn_Confirm:addClickEventListener(ConfirmEvent)
	self:MarkIntaractCObj(btn_Confirm)

    local closeBtn = into:getChildByName("Btn_close")
    closeBtn:addClickEventListener(function(sender)
        self:CloseUI()
    end)
end

function NewActiveCodeUI:getFieldString( ... )
    -- body
    local inputString 
    if GameSdk.androidTruePhone then
        inputString = self._textField:getString()
    else
        inputString = self._textField:getText()
    end
    return inputString
end

function NewActiveCodeUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Welfare.NewActiveCodeUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function NewActiveCodeUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return NewActiveCodeUI
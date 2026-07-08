
local PetBreakAdditionUI = LUIBase:New()
PetBreakAdditionUI.__index = PetBreakAdditionUI
--local this = LTcpSocket
function PetBreakAdditionUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetBreakAdditionUI)	
    o:Init(petData)
	return o
end

local maxSkillLv = 8

--注册事件
-- -----------------------------------
function PetBreakAdditionUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetBreakAdditionUI:ProcessEvent(msg)

end

function PetBreakAdditionUI:Init(petData)

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtianfuLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:initData(petData)
    self:InitControlUI()
    self:updateUI()
end

function PetBreakAdditionUI:initData( petData )
    -- body
    self._petData = petData
end


function PetBreakAdditionUI:InitControlUI( ... )
    -- body
    self._bg = self.m_pUILayer:getChildByName("bg")
    local Btn_close = self._bg:getChildByName("Btn_close")
    Btn_close:addClickEventListener(function( sender )
        -- body
        self:closeUI()
    end)

    self._listView = self._bg:getChildByName("ListView")

    local image = self._bg:getChildByName("Image")
    self._pCell = self._listView:getChildByName("Panel_2")
    local Text_skill = self._pCell:getChildByName("Text_skill")
    local text = Text_skill:getChildByName("Text")

    local Title = self._bg:getChildByName("Title")
    Title:setString(GUITips.RSI_TITLE_BREAKATTR)

    self._pCell:removeFromParent()
    self._pCell:retain()

end

function PetBreakAdditionUI:updateUI( ... )
    -- body
    local myBreakLv = self._petData.breakLevel
    local list = JsonConfig.m_petBreakCost.getList()
    for i=1, #list do
        local breakStr = PetkaPaiManager:getBreakAttrStrByLv(self._petData, list[i].break_level)
        local item = self._pCell:clone()
        self._listView:pushBackCustomItem(item)

        local openCon = item:getChildByName("Text")
        openCon:setString( string.format(GUITips.UI_Hero_TianFu_tips3, i))

        local text = item:getChildByName("Text_skill"):getChildByName("Text")
        local oldHeight = text:getContentSize().height
        local newText 
        if myBreakLv >= i then
            text:setTextColor(UICOLOR_GREEN)
            newText = Utils:CreateColorText3(text, true)
            newText:setString(breakStr)
            openCon:setTextColor(UICOLOR_GREEN)
        else
            newText = Utils:CreateColorText3(text, true)
            newText:setString(breakStr)
        end

        local txtHeight =  newText:getSize().height
        if txtHeight > oldHeight then
            local size = item:getContentSize()
            local adjustSp = txtHeight - oldHeight
            item:setContentSize(cc.size(size.width, size.height + adjustSp))

            local Image_7 = item:getChildByName("Image_7")
            Image_7:setPositionY(Image_7:getPositionY() + adjustSp)
            local Text_skill = item:getChildByName("Text_skill")
            Text_skill:setPositionY(Text_skill:getPositionY() + adjustSp)
            local Text = item:getChildByName("Text")
            Text:setPositionY(Text:getPositionY() + adjustSp)
        end

        newText:setVisible(true)
    end

end

function PetBreakAdditionUI:closeUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.PetBreakAdditionUI")
end

function PetBreakAdditionUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetBreakAdditionUI
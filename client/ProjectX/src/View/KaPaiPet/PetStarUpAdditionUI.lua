
local PetStarUpAdditionUI = LUIBase:New()
PetStarUpAdditionUI.__index = PetStarUpAdditionUI
--local this = LTcpSocket
function PetStarUpAdditionUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetStarUpAdditionUI)	
    o:Init(petData)
	return o
end

local maxSkillLv = 8

--注册事件
-- -----------------------------------
function PetStarUpAdditionUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetStarUpAdditionUI:ProcessEvent(msg)

end

function PetStarUpAdditionUI:Init(petData)

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

function PetStarUpAdditionUI:initData( petData )
    -- body
    self._petData = petData
end


function PetStarUpAdditionUI:InitControlUI( ... )
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

    self._pCell:removeFromParent()
    self._pCell:retain()

end

function PetStarUpAdditionUI:updateUI( ... )
    -- body
    local petConfigData = JsonConfig.m_heroCfg.getDefByID(self._petData.id)
    if #petConfigData.skills < 1 then
        return
    end

    local skillId = petConfigData.skills[1]
    local starConfig = JsonConfig.m_star.getDefByID(self._petData.star)
    if starConfig == nil then
        return
    end
    local mySkillLv = starConfig.skill_level
    for i=1, maxSkillLv do
        local item = self._pCell:clone()
        self._listView:pushBackCustomItem(item)

        local openCon = item:getChildByName("Text")
        if i == 1 then
            openCon:setString(GUITips.UI_Hero_TianFu_tips1)
        else
            openCon:setString( string.format(GUITips.UI_Hero_TianFu_tips2, i - 1))
        end


        local curDesc = LDataConstMgr:GetHeroSkillDesc(skillId, i)
        local text = item:getChildByName("Text_skill"):getChildByName("Text")
        local oldHeight = text:getContentSize().height

        local newText 
        if mySkillLv == i then
            text:setTextColor(UICOLOR_GREEN)
            newText = Utils:CreateColorText3(text, true)
            newText:setString(curDesc)
            openCon:setTextColor(UICOLOR_GREEN)
        else
            newText = Utils:CreateColorText3(text, true)

            curDesc = string.gsub(curDesc, "%[c3%]", "")
            curDesc = string.gsub(curDesc, "%[/c3%]", "")

            newText:setString(curDesc)
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

    end
end

function PetStarUpAdditionUI:closeUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.PetStarUpAdditionUI")
end

function PetStarUpAdditionUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetStarUpAdditionUI
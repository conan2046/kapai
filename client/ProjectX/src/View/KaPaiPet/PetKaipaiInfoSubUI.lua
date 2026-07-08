
local PetKaipaiInfoSubUI = LUIBase:New()
PetKaipaiInfoSubUI.__index = PetKaipaiInfoSubUI
--local this = LTcpSocket

function PetKaipaiInfoSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetKaipaiInfoSubUI)	
    o:Init()
	return o
end

local INNERCONTAINERWIDTH = 462
local INNERCONTAINERHEIGHT = 521
local ZENGJIACHANGDUBILI = 0  

--注册事件
-- -----------------------------------
function PetKaipaiInfoSubUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetKaipaiInfoSubUI:ProcessEvent(msg)

end

function PetKaipaiInfoSubUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongxinxiLayer.csb")

    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
end

function PetKaipaiInfoSubUI:initControlUI( ... )
    -- body
    local shenjiangInfoUI = self.m_pUILayer:getChildByName("shenjiangInfoUI")
    -- local chongwugaiming = shenjiangInfoUI:getChildByName("chongwugaiming")
    -- chongwugaiming:setVisible(false)
    
    local Info = shenjiangInfoUI:getChildByName("Info")

    self._ScrollView = Info:getChildByName("ScrollView_1")
    --临时代码,UI好了删除
    -- self._ScrollView:setPosition(cc.p(self._ScrollView:getPositionX() - 30, self._ScrollView:getPositionY()))

    self._ScrollView:setInnerContainerSize(cc.size(INNERCONTAINERWIDTH, INNERCONTAINERHEIGHT * (ZENGJIACHANGDUBILI + 1)))
    self._ScrollView:setScrollBarEnabled(false)

    self._orginalViewSize = self._ScrollView:getInnerContainerSize()

    self._adjustNode = {}
    self._adjustNodePos = {}
    local topNode = self._ScrollView:getChildByName("Info")
    table.insert(self._adjustNode, topNode)
    table.insert(self._adjustNodePos, cc.p(topNode:getPosition()))

    self._dingWei = self._ScrollView:getChildByName("Info"):getChildByName("dingwei"):getChildByName("Value")


    local jichu = self._ScrollView:getChildByName("jichu")
    table.insert(self._adjustNode, jichu)
    table.insert(self._adjustNodePos, cc.p(jichu:getPosition()))

    self._attrList = {}
    for i=1, 4 do
        local value = jichu:getChildByName("Attribute_"..i)
        table.insert(self._attrList, value)
    end

    local detailAttrBtn = jichu:getChildByName("Button")
    detailAttrBtn:addClickEventListener(function ( sender )
        -- body
        Utils:InitUI("KaPaiPet.KaPaiDetailAttrUI", AppDef.UIType.PopWindow,self.m_pPetData.id)
    end)

    local skill = self._ScrollView:getChildByName("Skill")
    table.insert(self._adjustNode, skill)
    table.insert(self._adjustNodePos, cc.p(skill:getPosition()))

    local Item = skill:getChildByName("Item")
    self._skillIcon = Item:getChildByName("Btn_Skill"):getChildByName("Icon")
    self._SkillName = Item:getChildByName("SkillName")
    self._skillBg = skill:getChildByName("Title"):getChildByName("Image_bg_5")
    self._skillBgPos=cc.p(self._skillBg:getPosition())
    self._skillBgSize = self._skillBg:getContentSize()
    local skillDec = Item:getChildByName("SkillInfo")
    self._skillDec = Utils:CreateColorText3(skillDec, true)

    local button = Item:getChildByName("Button")
    button:addClickEventListener(function ( sender )
        -- body
        Utils:InitUI("KaPaiPet.PetStarUpAdditionUI", AppDef.UIType.PopWindow, self.m_pPetData)
    end)

    --------------------------------------------------------------------------------
    local shengxingtianfu = self._ScrollView:getChildByName("shengxingtianfu")
    self._shengxingtianfu = shengxingtianfu
    table.insert(self._adjustNode, shengxingtianfu)
    table.insert(self._adjustNodePos, cc.p(shengxingtianfu:getPosition()))

    local item = shengxingtianfu:getChildByName("Item")
    self._skillTitle = item:getChildByName("Title")
    local _starSKillInfo =  item:getChildByName("SkillInfo")
    self._starSKillInfo = Utils:CreateColorText3(_starSKillInfo, true)
    ------------------------------------------------------------------------------
    local jinjietianfu = self._ScrollView:getChildByName("jinjietianfu")
    self._jinjietianfu = jinjietianfu
    table.insert(self._adjustNode, jinjietianfu)
    table.insert(self._adjustNodePos, cc.p(jinjietianfu:getPosition()))

    -- self._jinjietianfu = jinjietianfu
    self._breakCell = jinjietianfu:getChildByName("Item")
    ------------------------------------------------------------------------------
    local miaoshu = self._ScrollView:getChildByName("miaoshu")
    table.insert(self._adjustNode, miaoshu)
    table.insert(self._adjustNodePos, cc.p(miaoshu:getPosition()))

    self._Content = miaoshu:getChildByName("Item"):getChildByName("Content")
    -------------------------------------------------------------------------------

    --位置调整
    for i=1, #self._adjustNode do
        local node = self._adjustNode[i]
        local adjust = 0
        if i == 4 or i ==5 then
            adjust = 30
        end
        -- node:setPosition(cc.p(node:getPositionX(), node:getPositionY() + INNERCONTAINERHEIGHT * ZENGJIACHANGDUBILI + adjust))
        node:setPosition(cc.p(node:getPositionX(), node:getPositionY()  - adjust))
    end
end

function PetKaipaiInfoSubUI:UpdateData( petData )
    -- body
    print("UpdateData ===========>")
    self:resetUI()
    self.m_pPetData = petData

    self:updateUI()


end

function PetKaipaiInfoSubUI:resetUI( ... )
    -- body

    for i=1, #self._adjustNodePos do
        self._adjustNode[i]:setPosition(self._adjustNodePos[i])
    end

    self._ScrollView:setInnerContainerSize(self._orginalViewSize)
    self._skillBg:setContentSize(self._skillBgSize)
    self._skillBg:setPosition(self._skillBgPos)
   
    --位置调整
    for i=1, #self._adjustNode do
        local node = self._adjustNode[i]
        local adjust = 0
        if i == 4 or i ==5 then
            adjust = 30
        end
        -- node:setPosition(cc.p(node:getPositionX(), node:getPositionY() + INNERCONTAINERHEIGHT * ZENGJIACHANGDUBILI + adjust))
        node:setPosition(cc.p(node:getPositionX(), node:getPositionY()  - adjust))
    end

    -- self.m_pUILayer:removeFromParent()
    -- self:Init()

end

function PetKaipaiInfoSubUI:updateUI()
    -- self:resetUI()
    for i=1, 4 do
        self._attrList[i]:setString(PetkaPaiManager:getAttrName(i))
        self._attrList[i]:getChildByName("Value"):setString(self.m_pPetData.attrs[i])
    end

    --技能
    local petConfigData = JsonConfig.m_heroCfg.getDefByID(self.m_pPetData.id)
    local skillId = petConfigData.skills[1]
    if skillId == nil then
        skillId = 101
    end
    local imagefile = string.format("Skill/UI/skill_%d.png", skillId)
    self._skillIcon:loadTexture(imagefile, ccui.TextureResType.localType)

    local skillLevel = PetkaPaiManager:GetPetSkillLvByStar(self.m_pPetData.star)
    self._skillTitle:setString(string.format(GUITips.UI_Hero_TianFu_tips2, self.m_pPetData.star))
    local curDesc = LDataConstMgr:GetHeroSkillDesc(skillId, skillLevel)
    self._skillDec:setString(curDesc)

    

    local size1 = self._skillDec:getSize()
    print("size1 === 22222222222222>", size1.height)
    local oldSize = self._skillBg:getContentSize()
    local addValue = size1.height - 66 + 10

    if addValue > 0 then
        self._skillBg:setContentSize(cc.size(oldSize.width, oldSize.height + addValue))
        self._skillBg:setPositionY(self._skillBg:getPositionY() - addValue / 2)
        local curSize = self._ScrollView:getInnerContainerSize()
        self._ScrollView:setInnerContainerSize(cc.size(curSize.width, curSize.height + addValue))
        self:addJustPos(addValue)
    end
    

    local skillData = LSkillMgr:getSkillById(skillId)
    self._SkillName:setString(skillData.name)

    self._starSKillInfo:setString(curDesc)
    local size = self._starSKillInfo:getSize()
    print("size1 ===111111111111 >", size.height)
    local add2 = (size.height - 21) + 10

    print("========================= add2", add2)
    if add2 > 0 then
        local curSize = self._ScrollView:getInnerContainerSize()
        self._ScrollView:setInnerContainerSize(cc.size(curSize.width, curSize.height + add2 ))
        self:addJustPos(add2)
        self._jinjietianfu:setPositionY(self._jinjietianfu:getPositionY() - add2 / 2)

        --调整
        if size1.height > 150 then
            self._shengxingtianfu:setPositionY(self._shengxingtianfu:getPositionY() - add2 / 2)
            self._jinjietianfu:setPositionY(self._jinjietianfu:getPositionY() - add2)
        end

    end
    
    if self.m_pPetData.breakLevel < 1 then
        local attr = self._breakCell:getChildByName("TalentInfo")
        attr:setString(GUITips.RSI_ZQX_TUPO_TIANFU0)
    else
        for i=1, self.m_pPetData.breakLevel do
            local breakStr = PetkaPaiManager:getBreakAttrStrByLv( self.m_pPetData , i)
            if i == 1 then
                local attr = self._breakCell:getChildByName("TalentInfo")
                attr:setString(breakStr)
            else
                local itemCell = self._breakCell:clone()
                self._jinjietianfu:pushBackCustomItem(itemCell)
                local attr = itemCell:getChildByName("TalentInfo")
                attr:setString(breakStr)
            end
            local curSize = self._ScrollView:getInnerContainerSize()
            self._ScrollView:setInnerContainerSize(cc.size(curSize.width, curSize.height + 30))

            self:addJustPos(30)
        end
    end

    self._dingWei:setString(petConfigData.feature)

end


function PetKaipaiInfoSubUI:addJustPos(value)
    -- body
    for i=1, #self._adjustNode do
        local node = self._adjustNode[i]
        local adjust = value
        -- node:setPosition(cc.p(node:getPositionX(), node:getPositionY() + INNERCONTAINERHEIGHT * ZENGJIACHANGDUBILI + adjust))
        node:setPosition(cc.p(node:getPositionX(), node:getPositionY() + adjust))
    end
end

function PetKaipaiInfoSubUI:getCurPetIsShowRed( ... )
    -- body
    return false
end

function PetKaipaiInfoSubUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetKaipaiInfoSubUI

local PetStarUpSucUI = LUIBase:New()
PetStarUpSucUI.__index = PetStarUpSucUI
--local this = LTcpSocket
function PetStarUpSucUI:New(id)
	local o = LUIBase:New()
	setmetatable(o,PetStarUpSucUI)	
    o:Init(id)
	return o
end

--注册事件
-- -----------------------------------
function PetStarUpSucUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetStarUpSucUI:ProcessEvent(msg)

end

function PetStarUpSucUI:Init(id)
    self.Script = "KaPaiPet.PetStarUpSucUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongshengxingendLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:InitData()
    self:AddTouchEvt()
    self:InitUserData(id)
    self:ShowInfo()
    self:ShowModel()
    self:ShowStars()
    self:RegisterGuide()
end

function PetStarUpSucUI:InitData()
    local panel = self.m_pUILayer:getChildByName("shengxingchenggongUI")
    self.m_colseBtn = panel:getChildByName("Mask")
    --信息
    local infoPanel = panel:getChildByName("Info")
    --战力
    local powerPanel = infoPanel:getChildByName("bg_zhanli")
    self.m_powerLabel_1 = powerPanel:getChildByName("Value")
    self.m_powerLabel_2 = powerPanel:getChildByName("add")
    self.m_skillDec = infoPanel:getChildByName("Value_1")

    self._skillDes = Utils:CreateColorText3(self.m_skillDec, false)
    self.m_skillDec:setVisible(true)
    self.m_skillDec:setString("")

    --属性
    self._attrList = {}
    for i =1,4 do
        local attrNameLabel = self.m_pUILayer:getChildByName("Attribute_"..i)
        table.insert(self._attrList, attrNameLabel)
        self["m_attrlabel"..i.."_1"] = attrNameLabel:getChildByName("Value_1")
        self["m_attrlabel"..i.."_2"] = attrNameLabel:getChildByName("Value_2")
        self["m_attrlabel"..i.."_3"] = attrNameLabel:getChildByName("Value_3")
    end
    --星星
    self.m_starImg = panel:getChildByName("Item_Star")
    --模型
    local leftPanel = panel:getChildByName("Left")
    self.m_starNode_1 = leftPanel:getChildByName("Star")
    local leftNode = leftPanel:getChildByName("Node")
    self.m_petModelNode_1 = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    leftNode:addChild(self.m_petModelNode_1)
    self.m_dizuoImg_1 = leftPanel:getChildByName("dizuo")

    local rightPanel = panel:getChildByName("Right")
    self.m_starNode_2 = rightPanel:getChildByName("Star")
    local rightNode = rightPanel:getChildByName("Node")
    self.m_petModelNode_2 = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    rightNode:addChild(self.m_petModelNode_2)
    self.m_dizuoImg_2 = rightPanel:getChildByName("dizuo")
    -----------------------------------------------------
    self._Icon2 = panel:findChildByName("Info/Value_1/Icon2")
    self._SkillName = self._Icon2:getChildByName("name")
    self._skillLv = self._Icon2:getChildByName("Level")
    self._toLevel= self._Icon2:getChildByName("toLevel")
    self._close = panel:getChildByName("Close")
end

function PetStarUpSucUI:AddTouchEvt()
    local function onClose(sender)
        self:CloseUI()
    end
    self.m_colseBtn:addClickEventListener(onClose)
    self:MarkIntaractCObj(self.m_colseBtn)
end

function PetStarUpSucUI:InitUserData(id)
    self.m_id = id
    local petInfo = LRoleDataMgr.Pet:GetPetById(self.m_id)
    if petInfo == nil then
       return
    end
    self.m_pPetData = petInfo.baseData
    self.m_attrs = petInfo.attrs
    self.m_star = petInfo.star
    self.m_powerValue = petInfo.zhandouli
    if self.m_star > AppDef.Pet.MaxStar then
        self.m_star = AppDef.Pet.MaxStar
    end
end

function PetStarUpSucUI:ShowModel()
    if self.m_pPetData == nil then
        return
    end
    for i=1,2 do
        self["m_petModelNode_"..i]:InitAni(AppDef.CEnum.ModelAniType.MonsterBig, self.m_pPetData.pic)
        self["m_petModelNode_"..i]:PlayStand(0)
        self:PetEffectAnim(self["m_dizuoImg_"..i])
    end
end

function PetStarUpSucUI:PetEffectAnim(pAnimNode)
    if pAnimNode == nil then
        return
    end
    local pAnim = ImodAnim:createWithFileSync("res2/fx/shenqizhanshi")
    pAnim:setIgnoreAnchorPointForPosition(false)
    pAnim:setAnchorPoint(cc.p(0.5, 0))
    pAnim:PlayActionRepeat(0)
    pAnim:setPosition(cc.p(pAnimNode:getContentSize().width/2, pAnimNode:getContentSize().height/2+20))
    pAnimNode:addChild(pAnim)
end

function PetStarUpSucUI:ShowInfo()
    local petInfo = LRoleDataMgr.Pet:GetPetById(self.m_id)
    if petInfo == nil then
       return
    end

    -- dump(self.m_attrs, "my cur attr == 1111111111111>")
    -- dump(LRoleDataMgr.tempPetUpStarData.attrs, "Old attr == 2222222222222222222222222 >")
    local attrType = {}
    local attrValue = {}
    for k,v in pairs(self.m_attrs) do
        local old = LRoleDataMgr.tempPetUpStarData.attrs[k]
        if old and old ~= v then
            table.insert(attrType, k)
            table.insert(attrValue, v - old)
        end
    end
    --属性
    for i =1,4 do  
        local rightStr = ""
        local leftStr = tostring(self.m_attrs[i]) 
        for k = 1,#attrType do 
            if attrType[k] == i then
                rightStr = attrValue[k]
                local temp = self.m_attrs[i]-attrValue[k]
                if temp < 0 then
                    temp = 0
                end
                leftStr = tostring(temp)  
                break
            end
        end
        self._attrList[i]:setString(PetkaPaiManager:getAttrName(i) .. ": ")
        self["m_attrlabel"..i.."_2"]:setString(tostring(self.m_attrs[i]))       
        self["m_attrlabel"..i.."_1"]:setString(leftStr)
        self["m_attrlabel"..i.."_3"]:setString(rightStr)
    end

    --战力
    local powerAdd = self.m_powerValue - LRoleDataMgr.tempPetUpStarData.zhandouli
    local power = self.m_powerValue - powerAdd
    if power < 0 then power = 0 end
    self.m_powerLabel_1:setString(""..Utils:getPowerStr(power))
    self.m_powerLabel_2:setString("+"..Utils:getPowerStr(powerAdd))


    

    print("petInfo.star ===>", petInfo.star, LRoleDataMgr.tempPetUpStarData.star)
    local starConfig = JsonConfig.m_star.getDefByID(petInfo.star)
    if starConfig == nil then
        return
    end
    self._skillLv:setString(starConfig.skill_level - 1)
    self._toLevel:setString(starConfig.skill_level)

    local petConfigData = JsonConfig.m_heroCfg.getDefByID(self.m_id)
    print("PetStarUpSucUI:ShowInfo ==>", self.m_id)
    if #petConfigData.skills > 0 then
        local skillId = petConfigData.skills[1]
        local imagefile = string.format("Skill/UI/skill_%d.png", skillId)
        self._Icon2:loadTexture(imagefile, ccui.TextureResType.localType)
        local skillData = LSkillMgr:getSkillById(skillId)
        self._SkillName:setString(skillData.name)

        local curDesc = LDataConstMgr:GetHeroSkillDesc(skillId, starConfig.skill_level)
        self._skillDes:setString(curDesc)
        self.m_skillDec:setContentSize(cc.size(self._skillDes:getSize().width,self._skillDes:getSize().height+55))
    end
end

function PetStarUpSucUI:ShowStars()

    local oldStar = self.m_star-1
    local size = self.m_starImg:getContentSize().width
    local startX = 5+(6-oldStar)*((size+2)/2)
    for i=1,oldStar do
        local starImg = self.m_starImg:clone()       
        starImg:setAnchorPoint(cc.p(0,0))
        starImg:setPosition(cc.p(startX+(i-1)*(size+2),0))
        self.m_starNode_1:addChild(starImg)
    end
    startX =5+(6-self.m_star)*((size+2)/2)
    for i=1,self.m_star do
        local starImg = self.m_starImg:clone()
        starImg:setAnchorPoint(cc.p(0,0))
        starImg:setPosition(cc.p(startX+(i-1)*(size+2),0))
        self.m_starNode_2:addChild(starImg)
    end
end

function PetStarUpSucUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetStarUpSucUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function PetStarUpSucUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen3_8)
    self.m_pUILayer = nil
    self:Destory()
    Utils:CheckGuide(GuideDef.StepId.Guide_FuBen3_9, true)
end

function PetStarUpSucUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen3_8, self._close, handler(self, PetStarUpSucUI.RemoveUI), nil, true)
end

return PetStarUpSucUI
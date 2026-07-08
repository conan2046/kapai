--[[
lua里面的游戏逻辑控制
神将-升星成功展示UI
]]

local PetStarUpgradeShowUI = LUIBase:New()
PetStarUpgradeShowUI.__index = PetStarUpgradeShowUI
function PetStarUpgradeShowUI:New(id)
    local o = LUIBase:New()
    setmetatable(o, PetStarUpgradeShowUI)
    o:Init(id)
    return o
end


function PetStarUpgradeShowUI:Init(id)
    -- self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shengxingchenggongLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    --self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
    self:InitUserData(id)
    self:ShowInfo()
    self:ShowModel()
    self:ShowStars()
end

function PetStarUpgradeShowUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

------[[
----注册UI消息
----]]
--function PetStarUpgradeShowUI:RegistMsgs()
--   self.msgIds =
--   {
--        LUIPetEvent.ComposionPet,
--   }
--   self:RegistSelf(self, self.msgIds)
--end

--function PetStarUpgradeShowUI:ProcessEvent(msg)
--   if msg.msgId == LUIPetEvent.ComposionPet then
--       self:updateItem(msg.value)
--   end

--end

function PetStarUpgradeShowUI:InitData()
    local panel = self.m_pUILayer:getChildByName("shengxingchenggongUI")
    self.m_colseBtn = panel:getChildByName("Mask")
    --信息
    local infoPanel = panel:getChildByName("Info")
    --战力
    local powerPanel = infoPanel:getChildByName("bg_zhanli")
    self.m_powerLabel_1 = powerPanel:getChildByName("Value")
    self.m_powerLabel_2 = powerPanel:getChildByName("add")
    --属性
    for i =1,8 do
        local attrNameLabel = infoPanel:getChildByName("Attribute_"..i)
        if i < 5 then
            attrNameLabel:setString(LDataConstMgr:GetItemAttrName(i))
        else
            attrNameLabel:setString(AppDef.EAttrGrowName[i-4] or "")
        end
        ccui.Helper:doLayout(attrNameLabel)
        self["m_attrlabel"..i.."_1"] = attrNameLabel:getChildByName("Value_1")
        self["m_attrlabel"..i.."_2"] = attrNameLabel:getChildByName("Value_2")
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
end

function PetStarUpgradeShowUI:AddTouchEvt()
    local function onClose(sender)
        self:CloseUI()
    end
    self.m_colseBtn:addClickEventListener(onClose)
	self:MarkIntaractCObj(self.m_colseBtn)
end

function PetStarUpgradeShowUI:InitUserData(id)
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

function PetStarUpgradeShowUI:ShowModel()
    if self.m_pPetData == nil then
        return
    end
    for i=1,2 do
        self["m_petModelNode_"..i]:InitAni(AppDef.CEnum.ModelAniType.Monster, self.m_pPetData.pic)
        self["m_petModelNode_"..i]:PlayStand(self.m_pPetData.defaultFace)
        self:PetEffectAnim(self["m_dizuoImg_"..i])
    end
end

function PetStarUpgradeShowUI:PetEffectAnim(pAnimNode)
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

function PetStarUpgradeShowUI:ShowInfo()
    local petInfo = LRoleDataMgr.Pet:GetPetById(self.m_id)
    if petInfo == nil then
       return
    end

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
                rightStr = "+"..attrValue[k]
                local temp = self.m_attrs[i]-attrValue[k]
                if temp < 0 then
                    temp = 0
                end
                leftStr = tostring(temp)  
                break
            end
        end
        self["m_attrlabel"..i.."_2"]:setString(rightStr)       
        self["m_attrlabel"..i.."_1"]:setString(leftStr)
    end
    local olddata = LDataConstMgr:GetPetGrowAttr(self.m_id, self.m_star-1)
    local newdata = LDataConstMgr:GetPetGrowAttr(self.m_id, self.m_star)
    if olddata and newdata then
        for i=5,8 do
            local oldvalue = olddata[i-4]
            local newvalue = newdata[i-4]
            if oldvalue and newvalue then
                self["m_attrlabel"..i.."_1"]:setString(oldvalue)
                local rightStr = "+"..math.max(newvalue-oldvalue, 0)
                self["m_attrlabel"..i.."_2"]:setString(rightStr or "")
            end
        end
    end
    --战力
    local powerAdd = self.m_powerValue - LRoleDataMgr.tempPetUpStarData.power
    local power = self.m_powerValue - powerAdd
    if power < 0 then power = 0 end
    self.m_powerLabel_1:setString(""..Utils:getPowerStr(power))
    self.m_powerLabel_2:setString("+"..Utils:getPowerStr(powerAdd))
end

function PetStarUpgradeShowUI:ShowStars()

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

function PetStarUpgradeShowUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetStarUpgradeShowUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return PetStarUpgradeShowUI
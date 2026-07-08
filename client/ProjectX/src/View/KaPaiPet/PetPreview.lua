--[[
   神将预览
]]
local PetPreview = LUIBase:New()
PetPreview.__index = PetPreview
function PetPreview:New(userData)
    local o = LUIBase:New()
    setmetatable(o, PetPreview)
    o:Init(userData)
    return o
end
function PetPreview:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/chouka/shenjiangyulan.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitVariable(userData[1])
    self:InitData()
    self:InitEvt()
    self:ShowPetInfo()
   -- local panel = self.m_pUILayer:getChildByName("Panel")
   
 
end
function PetPreview:onExit()
    Utils:SendMsg(LUILogicEvent.ClosePetInfo)
    self.m_pUILayer = nil
    self:Destory()
end

function PetPreview:InitVariable(id)
    self.m_pPetId=id
    self.m_pPetData=LDataConstMgr:GetPetData(id)
end

function PetPreview:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    local leftPanel =panel:getChildByName("Panel_left")
    local rightPanel=panel:findChildByName("shenjiangInfoUI/Info/ScrollView_1")
    self:InitRightPanel(rightPanel)
    self:InitLeftPanel(leftPanel)
end
function PetPreview:InitRightPanel(panel)
    panel:setScrollBarEnabled(false)
    self.m_pAttType= panel:findChildByName("Info/dingwei/Value")
    self.m_pAttBase={}
    for i=1,8 do
        self.m_pAttBase[i]=panel:findChildByName("jichu/Attribute_"..i)
    end
    self.m_pSkill=panel:findChildByName("Skill/Item")
    self.m_pBeakAtt=panel:findChildByName("jinjietianfu")


    local info =  panel:findChildByName("Info")
    local jichu =  panel:findChildByName("jichu")
    local jinjietianfu =  panel:findChildByName("jinjietianfu")
    local skill = panel:findChildByName("Skill") 
   
    local panelPos = cc.p(panel:getPosition())
    local infoPos = cc.p(info:getPosition())   
    local jichuPos = cc.p(jichu:getPosition())
    local skillPos=cc.p(skill:getPosition())
    local jinjietianfuPos = cc.p(jinjietianfu:getPosition())

    local height = 0
    height=height+info:getContentSize().height
    height=height+jichu:getContentSize().height
    height=height+skill:getContentSize().height
    height=height+jinjietianfu:getContentSize().height
    panel:setInnerContainerSize(cc.size(462,height+50))
    info:setPositionY(panel:getInnerContainerSize().height-2)
    jichu:setPositionY(panel:getInnerContainerSize().height-2-info:getContentSize().height)
    skill:setPositionY(panel:getInnerContainerSize().height-2-info:getContentSize().height-jichu:getContentSize().height)
    jinjietianfu:setPositionY(panel:getInnerContainerSize().height-2-info:getContentSize().height-jichu:getContentSize().height-skill:getContentSize().height-jinjietianfu:getContentSize().height)
end
function PetPreview:setSkillContentHeight()
   
end

function PetPreview:InitLeftPanel(panel)
    self.m_pName=panel:getChildByName("Name")
    self.m_pQuality=panel:findChildByName("bg_Quality/Value")
    self.m_pPowerPanel = panel:getChildByName("RolePowerBase")
    self.m_pPowerPanel:setVisible(false)
    self.m_pModelNode=panel:getChildByName("Node_1"):getChildByName("Node")
    self.m_pPartBtn=panel:findChildByName("suipian/Btn_add")
    self.m_pLoadingBar=panel:findChildByName("suipian/Slider_Bg/LoadingBar")
    self.m_pBarValue=panel:findChildByName("suipian/Slider_Bg/Value")
end

function PetPreview:InitEvt()
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetPreview")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.UI_Shenjiang_TabName1)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self.m_pPartBtn:addClickEventListener(function ()
        local item = {}
        item.itemType ="CItem"
        item.itemData ={m_item=LItemMgr:getItem(self.m_pPetData.itemId)}  
        item.showFrom=true
        Utils:SendMsg(LUILogicEvent.ShowItemInfo, item)      
    end)
end

function PetPreview:ShowPetInfo()
    
    self:ShowName()
    self:ShowModel()
    self:ShowSkills()
    self:ShowPartBar()
    self:ShowQuality() 
    self:ShowAttrInfo()
    self:ShowBreakSkills()
  
end

--[[
显示品质评分
]]
function PetPreview:ShowQuality()
    AppDef:GetPetQualityScore(self.m_pQuality,self.m_pPetData.quality)
end

--[[
显示碎片数
]]
function PetPreview:ShowPartBar()
    local num =LRoleDataMgr.Equip:CountItemNumById(self.m_pPetData.itemId)   
    local needNum =  0      
    for i=1,#hecheng_dat do
        --print("hecheng_dat")
        if hecheng_dat[i].item[1][1]==self.m_pPetData.itemId then
          --  dump({hecheng_dat[i].item[1],hecheng_dat[i].item[3]},"显示碎片数")
            needNum=hecheng_dat[i].item[1][3]
            break
        end
    end
    
    self.m_pBarValue:setString(num.."/"..needNum)
    self.m_pLoadingBar:setPercent(num/needNum*100)
   
end
--[[
显示名字
]]
function PetPreview:ShowName()
    self.m_pName:setString(self.m_pPetData.name)
    local color = AppDef:GetPetQualityColor(self.m_pPetData.quality)
    self.m_pName:setTextColor(color)
    self.m_pName:enableShadow()
end

--[[
显示技能
]]
function PetPreview:ShowSkills() 

    local skillId = self.m_pPetData.skills[1]
    local skillData = LSkillMgr:getSkillById(skillId)
    local des=  LDataConstMgr:GetHeroSkillDesc(skillId, 1)
    local imagefile = string.format("Skill/UI/skill_%d.png", skillId)
    local icon = self.m_pSkill:findChildByName("Btn_Skill/Icon")
    icon:loadTexture(imagefile, ccui.TextureResType.localType)
    local name = self.m_pSkill:findChildByName("SkillName")
    name:setString(skillData.name) 
    local desNode = self.m_pSkill:findChildByName("SkillInfo"):clone()
    desNode:setString(des)
    local listView = self.m_pSkill:findChildByName("ListView_1")
    desNode:setPosition(cc.p(listView:getPosition()))
    listView:pushBackCustomItem(desNode)
    local tempDesNode = Utils:CreateColorText3(desNode, false)
    desNode:setVisible(true)
    tempDesNode:setString(des)
    desNode:setContentSize(tempDesNode:getSize())
    

    --print("打印信息desNode",desNode:getPositionX(),desNode:getPositionY())
    --print("打印信息tempDesNode",tempDesNode:getPositionX(),tempDesNode:getPositionY())

    --print("打印信息锚点desNode",tempDesNode:getAnchorPoint().x,tempDesNode:getAnchorPoint().y)

    --print("打印信息锚点tempDesNode",tempDesNode:getAnchorPoint().x,tempDesNode:getAnchorPoint().y)


    listView:refreshView()
    desNode:setVisible(false)
   -- print("打印信息desNode",desNode:getPositionX(),desNode:getPositionY())
    tempDesNode:setPosition(cc.p(desNode:getPosition()))
end
--[[
显示天赋技能
]]
function PetPreview:ShowBreakSkills()
    local skillStr = "" 
    local list = JsonConfig.m_petBreakCost.getList()
    for i=1, #list do
        local breakStr = PetkaPaiManager:getBreakAttrStrByLv(self.m_pPetData, list[i].break_level)
        print(breakStr, list[i].break_level)
        skillStr=skillStr..string.format(GUITips.UI_Hero_TianFu_tips3, i).."\n"..breakStr.."\n\n"
    end
    self.m_pBeakAtt:findChildByName("TalentInfo"):setString(skillStr)
end

--[[
点击技能框
ind:点击的技能下表
]]
function PetPreview:ShowSkillTips(ind)
--     local id = self.m_pPetData.skills[ind]
--     if id == nil then return end
--     local userdata = 
--     {
--         itemType = "CPetSkill",
--         itemData = LSkillMgr:getSkillById(id),
--         pos = ind,
--         petQuality = self.m_pPetData.quality
--     }
--     LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, userdata)
--     self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
function PetPreview:GetAttValue(id)
    if id==1 then
        return self.m_pPetData.gongji

    elseif id==2 then  
        return self.m_pPetData.wufang 
    elseif id==3 then 
        return self.m_pPetData.fashang  
    elseif id==4 then 
        return self.m_pPetData.qixue
    elseif id==5 then
        return self.m_pPetData.gongji_lv
    elseif id==6 then  
        return self.m_pPetData.wufang_lv 
    elseif id==7 then 
        return self.m_pPetData.fafang_lv  
    elseif id==8 then 
        return self.m_pPetData.qixue_lv
    end   
     return 0
end
function PetPreview:SetAtrrData(ind,name,Value)
    local tempUI =self.m_pAttBase[ind]
    tempUI:setString(name..":")
    local width =tempUI:getContentSize().width
    local tempValue = tempUI:getChildByName("Value")

    tempValue:setPositionX(tempValue:getPositionX()+width/2)
    tempValue:setString(Value)
end
--[[
显示属性信息
]]
function PetPreview:ShowAttrInfo()
    self.m_pAttType:setString(self.m_pPetData.feature)

    self:SetAtrrData(1,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_ATTACK],self:GetAttValue(AppDef.EAttrType.EAT_ATTACK))
    self:SetAtrrData(2,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_HP],self:GetAttValue(AppDef.EAttrType.EAT_HP))
    self:SetAtrrData(3,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_DEFENSE],self:GetAttValue(AppDef.EAttrType.EAT_DEFENSE))
    self:SetAtrrData(4,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_MAGICD_EFENSE],self:GetAttValue(AppDef.EAttrType.EAT_MAGICD_EFENSE))
    self:SetAtrrData(5,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_ATTACK]..GUITips.UI_PetPreview_Tips,self:GetAttValue(5))
    self:SetAtrrData(6,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_HP]..GUITips.UI_PetPreview_Tips,self:GetAttValue(6))
    self:SetAtrrData(7,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_DEFENSE]..GUITips.UI_PetPreview_Tips,self:GetAttValue(7))
    self:SetAtrrData(8,AppDef.EAttrTypeName[AppDef.EAttrType.EAT_MAGICD_EFENSE]..GUITips.UI_PetPreview_Tips,self:GetAttValue(8))
end

--显示模型
function PetPreview:ShowModel()
     if self.m_pPetData == nil then
        self.m_pPetModelNode:setVisible(false)
        return
    end
    self._pMyRoleModel = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, self.m_pPetId,nil, true)
    if self._pMyRoleModel ~= nil then
         self.m_pModelNode:addChild(self._pMyRoleModel)
        self._pMyRoleModel:PlayStand(1)
    end
end

return PetPreview
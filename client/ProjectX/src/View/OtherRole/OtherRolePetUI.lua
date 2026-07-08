--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    
end
local OtherRolePetUI = LUIBase:New()
OtherRolePetUI.__index = OtherRolePetUI

function OtherRolePetUI:New()
    local o = LUIBase:New()
    setmetatable(o,OtherRolePetUI)    
    o:Init()
    return o
end


function OtherRolePetUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowPetList()
    self:ShowPetInfo()
end

function OtherRolePetUI:RegistMsgs()
    self.msgIds = 
    {

    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function OtherRolePetUI:ProcessEvent(msg)
end

function OtherRolePetUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/PetShowLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function OtherRolePetUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_idx = nil
    self.m_pPetModelNode = nil
    self.m_petNameLabels = nil
    self.m_chooseImgs = nil
    self.m_petBtns = nil
    self.m_listViews = nil
    self.m_equipGrids = nil
    self.m_equips = nil
    self.m_equipNameLabels = nil
end

function OtherRolePetUI:OnEnter()
    --print("OtherRolePetUI:onEnter",idx,self.m_idx)
    local idx = LRoleDataMgr.OtherHeroInfo.m_PetIdx
    if self.m_idx == idx or idx == 0 then
        return
    end
    self.m_idx = idx or 1
    self:ShowPetInfo()
end

--[[
初始化成员变量
]]
function OtherRolePetUI:InitMemberVariable()
    self.m_idx = LRoleDataMgr.OtherHeroInfo.m_PetIdx
    print("self.m_idx",self.m_idx)
    self.m_pPetModelNode = nil--宠物动画节点
    self.m_petNameLabels = {}
    self.m_chooseImgs = {}
    self.m_petBtns = {}
    self.m_attrValLabels = {}
    self.m_listViews = {}
    self.m_equipGrids = {}
    self.m_equips = {}
    self.m_equipNameLabels = {}
end

function OtherRolePetUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("Panel")
    --左
    local leftPanel = panel:getChildByName("Panel_left")
    self.m_pPetNode = leftPanel:getChildByName("Node_1"):getChildByName("Node")
    self.m_pPetNode:setScale(0.8)
    self.m_pPetModelNode =  ModelAniNode:create(AppDef.CEnum.ModelAniType.MonsterBig, 0)
    self.m_pPetNode:addChild(self.m_pPetModelNode)

    self.m_pNameLabel = leftPanel:getChildByName("Name")
    self.m_pLvLabel = self.m_pNameLabel:getChildByName("Level")
    self.m_pUpLabel = self.m_pNameLabel:getChildByName("tupo")
    self.m_pQualityImg = leftPanel:getChildByName("bg_Quality"):getChildByName("Value")
    self.m_pPowerLabel = leftPanel:getChildByName("RolePowerBase"):getChildByName("PowerNum")
    self.m_pStarListView = leftPanel:getChildByName("StarsList")
    self.m_pStarCell = self.m_pStarListView:getChildByName("Star")
    self.m_pStarCell:retain()
    self.m_pStarCell:removeFromParent()

    self.m_leftBtn = leftPanel:getChildByName("Button_L")
    self.m_rightBtn = leftPanel:getChildByName("Button_R")
    --右
    local rightPanel = panel:getChildByName("Panel_right")
    --右上
    local petPanel = rightPanel:getChildByName("Panel_shenjiang")
    for i=1,5 do
        self.m_petBtns[i] = petPanel:getChildByName("bg_Head"..i)
        self.m_petBtns[i].userObject = i
        self.m_petBtns[i]:setTouchEnabled(true)
        self.m_petBtns[i]:addClickEventListener(handler(self,OtherRolePetUI.ChooseCallBack))
        self.m_petNameLabels[i] = self.m_petBtns[i]:getChildByName("Name")
        self.m_chooseImgs[i] =  self.m_petBtns[i]:getChildByName("Choose")
    end
    self.m_starCell = petPanel:getChildByName("Star")
    self.m_starCell:retain()
    self.m_starCell:removeFromParent()
    --右下
    self.m_infoListView = rightPanel:getChildByName("ListView_1")
    self.m_infoListView:setClippingEnabled(true)
    self.m_skillPanel = rightPanel:getChildByName("Panel_skill")
    local skillPanel = self.m_skillPanel:getChildByName("Item")
    local skillBgImg = skillPanel:getChildByName("Btn_Skill")
    self.m_skillImg = skillBgImg:getChildByName("Icon")
    self.m_skillNameLabel = skillPanel:getChildByName("SkillName")
    self.m_skillDescLabel = skillPanel:getChildByName("ListView"):getChildByName("SkillInfo")
    self.m_skillDescLabel:setString("")
    local size = self.m_skillDescLabel:getContentSize()
    self.m_skillDescLabel:setContentSize(cc.size(size.width-10, size.height))
    self.m_txtCell = Utils:CreateColorText3(self.m_skillDescLabel, true)
    --属性
    self.m_attrPanel = rightPanel:getChildByName("Info")
    local attrPanel = self.m_attrPanel:getChildByName("shuxing")
    self.m_typeLabel = attrPanel:getChildByName("Type"):getChildByName("text")
    local idxs = {1,2,3,4,11,12,13,14,15,16,17,18}
    local types = {1,4,2,3,6,7,8,9,22,19,20,21}
    for i = 1,#idxs do
        self.m_attrValLabels[types[i]] = attrPanel:getChildByName("Attribute_"..idxs[i]):getChildByName("Value")
    end
    --装备
    self.m_equipPanel = rightPanel:getChildByName("Panel_equip")
    local equipPanel = self.m_equipPanel:getChildByName("Item")
    for i= 1,6 do
        local equip = equipPanel:getChildByName("EquipIcon"..i)
        equip.userObject = i
        equip:addClickEventListener(handler(self,OtherRolePetUI.EquipCallBack))
        self.m_equipGrids[i] = equip:getChildByName("IconBase")
        self.m_equipNameLabels[i] = equip:getChildByName("name")
    end 
    --修炼
    self.m_xiuLianPanel = rightPanel:getChildByName("Panel_xiulian")
    
    self.m_xlAttrLabel = self.m_xiuLianPanel:getChildByName("txt_3")
    self.m_xlAddLabel = self.m_xiuLianPanel:getChildByName("txt_4")
    self.m_xlNameLabel = self.m_xiuLianPanel:findChildByName("Image_bg/txt_2")

    self.m_xiuLianPanel:retain()
    self.m_xiuLianPanel:removeFromParent()
    self.m_equipPanel:retain()
    self.m_equipPanel:removeFromParent()
    self.m_attrPanel:retain()
    self.m_attrPanel:removeFromParent()
    self.m_skillPanel:retain()
    self.m_skillPanel:removeFromParent()
end

function OtherRolePetUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self.m_leftBtn:addClickEventListener(handler(self,OtherRolePetUI.LeftCallBack))
    self.m_rightBtn:addClickEventListener(handler(self,OtherRolePetUI.RightCallBack))
end


function OtherRolePetUI:ShowPetInfo()
    if self.m_idx == 0 then
        self.m_idx = 1 
    end
    self.m_curData = LRoleDataMgr.OtherHeroInfo.VecFightPet[self.m_idx]
    if self.m_curData == nil then
        self.m_idx = 0
    end
    if self.m_curData ~= nil then
        self.m_curCfg = LPetDataMgr:FindPetDataById(self.m_curData.id)
        if self.m_curCfg == nil then
            self.m_idx = 0
        end
    end
    self:ShowChooseSign()
    self:ShowPetModel()
    self:ShowPower()
    self:ShowPetSoundEffect()

    self:ShowName()
    self:ShowLv()
    self:ShowQuality()
    self:ShowType()
    self:ShowAdd()
    self:ShowStars()
    self:ShowButton()
    self:ShowPetRightInfo()
end

function OtherRolePetUI:ShowPetRightInfo()
    self:ShowSkill()
    self:ShowAttrs()
    self:ShowXiuLian()
    self:ShowEquipList()
    self:ShowFaBaoList()
    local cnt = self.m_infoListView:getChildrenCount()
    if cnt == 0 then
        self.m_infoListView:pushBackCustomItem(self.m_attrPanel)
        self.m_infoListView:pushBackCustomItem(self.m_skillPanel)
        self.m_infoListView:pushBackCustomItem(self.m_equipPanel)
    end
    if self.m_curData ~= nil then
        if self.m_curData.XLLv > 0 and (cnt == 3 or cnt == 0) then  
            self.m_infoListView:insertCustomItem(self.m_xiuLianPanel,2)
        elseif self.m_curData.XLLv == 0 and cnt == 4 then
            self.m_xiuLianPanel:removeFromParent()
        end
    end
    self.m_infoListView:requestRefreshView()
end

function OtherRolePetUI:ShowChooseSign()
    if self.m_idx == 0 then
        return
    end
    self.m_chooseImgs[self.m_idx]:setVisible(true)
    for i=1,5 do
        if self.m_idx ~= i then
            self.m_chooseImgs[i]:setVisible(false)
        end
    end
end

--[[
显示技能
]]
function OtherRolePetUI:ShowSkill()
    self.m_skillNameLabel:setString("")
    self.m_txtCell:setString("")
    if self.m_curCfg == nil or self.m_curData == nil then
        return
    end
    local id = self.m_curCfg.skills[1] or 0
    local skillData = self.m_curData.skills
    local level = 1
    local strDesc = ""
    local strName = ""
    --dump(skillData)
    for k,v in pairs(skillData) do
        if v.level > 0 and id == v.skDetail.id then
            level = v.level
            strDesc = LDataConstMgr:GetHeroSkillDesc(id, level)
            strName = v.skDetail.name
        end
    end
    --print("OtherRolePetUI:ShowSkill",level,strName,strDesc)
    if id > 0 then
        self.m_skillImg:loadTexture(string.format("Skill/UI/skill_%d.png",id), ccui.TextureResType.localType)
    end
    self.m_skillNameLabel:setString(strName.."( LV."..level.." )")
    self.m_txtCell:setString(strDesc)
end

function OtherRolePetUI:ShowType()
    self.m_typeLabel:setString("")
    if self.m_curCfg == nil then
        return
    end
    self.m_typeLabel:setString(self.m_curCfg.feature or "")
end

--[[
显示+99
]]
function OtherRolePetUI:ShowAdd()
    self.m_pUpLabel:setString("")
    if self.m_curData == nil then
        return
    end
    --self.m_pUpLabel:setString(self.m_curData.)
end


--[[
显示品质评分
]]
function OtherRolePetUI:ShowQuality()
    self.m_pQualityImg:setVisible(false)
    if self.m_curCfg == nil then
        return
    end
    self.m_pQualityImg:setVisible(true)
    AppDef:GetPetQualityScore(self.m_pQualityImg, self.m_curCfg.quality)
end

--[[
显示战斗力
]]
function OtherRolePetUI:ShowPower()
    self.m_pPowerLabel:setString("")
    if self.m_curData == nil then
        return
    end
    self.m_pPowerLabel:setString(Utils:getPowerStr(self.m_curData.zhandouli))
end

--[[
显示名字
]]
function OtherRolePetUI:ShowName()
    self.m_pNameLabel:setString("")
    if self.m_curData == nil then
        return
    end
    self.m_pNameLabel:setString(self.m_curData.name)
    local color = AppDef:GetPetQualityColor(self.m_curCfg.quality)
    self.m_pNameLabel:setTextColor(color)
end

--[[
显示等级
]]
function OtherRolePetUI:ShowLv()
    self.m_pLvLabel:setString("")
    if self.m_curData == nil then
        return
    end
    self.m_pLvLabel:setString("Lv." .. self.m_curData.level)
end

--[[
显示宠物模型
]]
function OtherRolePetUI:ShowPetModel()
    self.m_pPetModelNode:setVisible(false)
    if self.m_curData == nil or self.m_curCfg == nil then
        return
    end
    self.m_pPetModelNode:setVisible(true)
    self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.MonsterBig, self.m_curCfg.pic)
    self.m_pPetModelNode:PlayStand(0)
end

function OtherRolePetUI:ShowAttrs()
    for k,v in pairs(self.m_attrValLabels) do
        v:setString("0")
    end
    if self.m_curData == nil then
        return
    end
    for k,v in pairs(self.m_curData.attrs) do
        local str = ""..v
        if k > AppDef.EAttrType.EAT_RESISIT_CRIT and v > 0 then
            str = str.."%"
        end
        if self.m_attrValLabels[k] ~= nil then
            self.m_attrValLabels[k]:setString(str)
        end
    end
end

function OtherRolePetUI:ShowStars()
    self.m_pStarListView:removeAllItems()
    if self.m_curData == nil then
        return
    end
    for i=1,self.m_curData.star do
        local cell = self.m_pStarCell:clone()
        self.m_pStarListView:pushBackCustomItem(cell)
    end
end

--显示宠物头像列表
function OtherRolePetUI:ShowPetList()
    local info = LRoleDataMgr.OtherHeroInfo.VecFightPet
    if info == nil then
        return
    end
    for  i=1, 5 do
        data = info[i]
        self:ShowPet(i,data)
    end
end

function OtherRolePetUI:ShowPet(idx,data)
    if idx == nil or idx < 1 or idx > 5 then
        return
    end
    self.m_petBtns[idx]:setVisible(false)
    if data == nil or data.id == 0 then
        return
    end
    local cfg = LDataConstMgr:GetPetData(data.id)
    if cfg == nil then
        return
    end
    local headImg = self.m_petBtns[idx]:getChildByName("Icon")
    local colorImg = self.m_petBtns[idx]:getChildByName("Color")
    local lvLabel = self.m_petBtns[idx]:getChildByName("Value")
    local starList = self.m_petBtns[idx]:getChildByName("Stars")
    if self.m_listViews[idx] == nil then
        self.m_listViews[idx] = Utils:CreateListView(starList,LISTVIEW_DIR_HORIZONTAL,1)
    end
    starList:setVisible(false)
    self.m_chooseImgs[idx]:setVisible(false)
    self.m_petBtns[idx]:setVisible(true)
    self.m_petNameLabels[idx]:setString(data.name)

    Utils:ShowPetHeadImg(headImg, cfg.pic, colorImg, cfg.quality)
    lvLabel:setString(""..data.level)
    self.m_listViews[idx]:removeAllItems()
    for i=1,data.star do
        local cell = self.m_starCell:clone()
        self.m_listViews[idx]:pushBackCustomItem(cell)
    end

    if self.m_idx == idx then
        self.m_chooseImgs[idx]:setVisible(true)
    end
end

function OtherRolePetUI:ChooseCallBack(sender)
    self.m_idx = sender.userObject
    print("ChooseCallBack",self.m_idx)
    self:ShowPetInfo()
end

function OtherRolePetUI:LeftCallBack(sender)
    if self.m_idx == 0 or self.m_idx == 1 then
        return
    end
    self.m_idx = self.m_idx -1
    self:ShowPetInfo()
end

function OtherRolePetUI:RightCallBack(sender)
    if self.m_idx == 0 or self.m_idx == 5 then
        return
    end
    self.m_idx = self.m_idx + 1
    self:ShowPetInfo()
end

function OtherRolePetUI:ShowPetSoundEffect()
    if self.m_curCfg == nil then
        return
    end
    local playFile = PetkaPaiManager:GetCV(self.m_curCfg)
    if string.len(playFile) > 0 then
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, playFile)
        self:SendMsg(LGameMsg.m_audioMsg)
    end
end

function OtherRolePetUI:ShowButton()
    self.m_leftBtn:setVisible(false)
    self.m_rightBtn:setVisible(false)
    if self.m_curData == nil or self.m_curCfg == nil or self.m_idx == 0 then
        return
    end
    if self.m_idx > 1 then
        self.m_leftBtn:setVisible(true)
    end
    if self.m_idx < 5 then
        self.m_rightBtn:setVisible(true)
    end
end

function OtherRolePetUI:ShowEquipList()
    if self.m_curData == nil then
        return
    end
    local data = LRoleDataMgr.OtherHeroInfo.MapEquip[self.m_curData.fightPos]
    if data == nil then
        for i=1,4 do
            if self.m_equips[i] ~= nil then
                self.m_equips[i]:UpdateItem(nil)
            end
            self.m_equipNameLabels[i]:setString("")
        end
        return
    end
    for i=1,4 do
        local value = data[i]
        if value ~= nil then
            --dump(value.cultivateLevel,"value.cultivateLevel value.cultivateLevel")
            self.m_equips[i] = Utils:GetEquipCellValue(self.m_equipGrids[i],self.m_equips[i],value.m_id,value.m_uid,value.cultivateLevel[1],value.cultivateLevel[2],value.cultivateLevel[4],value.cultivateLevel[3],false,true,true)
            self.m_equipNameLabels[i]:setString(Utils:getItemNameByID(AppDef.RewardItem.RD_ITEM_EQUIP,value.m_id))
        elseif self.m_equips[i] ~= nil then
            self.m_equips[i]:UpdateItem(nil)
            self.m_equipNameLabels[i]:setString("")
        end
    end
end

function OtherRolePetUI:ShowFaBaoList()
    if self.m_curData == nil then
        return
    end
    local data = LRoleDataMgr.OtherHeroInfo.MapFaBao[self.m_curData.fightPos]
    if data == nil then
        for i=5,6 do
            if self.m_equips[i] ~= nil then
                self.m_equips[i]:UpdateItem(nil)
            end
            self.m_equipNameLabels[i]:setString("")
        end
        return
    end
    for i=5,6 do
        local value = data[i]
        if value ~= nil then
            self.m_equips[i] = Utils:GetFaBaoCellValue(self.m_equipGrids[i],self.m_equips[i],value.m_id,value.m_uid, false, 0, value.cultivateLevel[5],value.cultivateLevel[6],false,true)
            self.m_equipNameLabels[i]:setString(Utils:getItemNameByID(AppDef.RewardItem.RD_ITEM_FABAO,value.m_id))
        elseif self.m_equips[i] ~= nil then
            self.m_equips[i]:UpdateItem(nil)
            self.m_equipNameLabels[i]:setString("")
        end
    end
end

function OtherRolePetUI:ShowXiuLian()
    if self.m_curData == nil then
        return
    end
    --self.m_curData.XLLv=self.m_idx-1
    --print("ShowXiuLian ShowXiuLian ShowXiuLian",self.m_curData.XLLv)
    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(self.m_curData.XLLv)
    if xiulian == nil then
        return ""
    end
    local str = PetkaPaiManager:getXLAttrStr(self.m_curData)
    --print("ShowXiuLian str1",str)
    self.m_xlAttrLabel:setString(str)
    str = PetkaPaiManager:getXLExtraAttrStr(self.m_curData)
    if #str > 0 then
        str = GUITips.RSI_XIULIAN_TIPS1.."："..str
    end
    --print("ShowXiuLian str1",str)
    self.m_xlAddLabel:setString(str)
    self.m_xlNameLabel:setString(xiulian.name)
end

function OtherRolePetUI:EquipCallBack(sender)
    if self.m_curData == nil then
        return
    end
    local  part = sender.userObject
    if part < 1 or part > 6 then
        return
    end
    if part < 5 then
        local data = LRoleDataMgr.OtherHeroInfo.MapEquip[self.m_curData.fightPos][part]
        if data == nil then
            return
        end
        local data = 
        {
            uid = data.m_uid,
            id = data.m_id,
            heroPos = self.m_curData.fightPos,
        }
        Utils:InitUI("PetEquip.EquipInfoUI",AppDef.UIType.PopWindow,data)
    else
        local data = LRoleDataMgr.OtherHeroInfo.MapFaBao[self.m_curData.fightPos][part]
        if data == nil then
            return
        end
        local data = 
        {
            uid = data.m_uid,
            id = data.m_id,
            heroPos = self.m_curData.fightPos,
            wPos = part
        }
        Utils:InitUI("FaBao.FaBaoInfo",AppDef.UIType.PopWindow,data)
    end
    
end

return OtherRolePetUI

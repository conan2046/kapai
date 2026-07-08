--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    
end
local PetSkillSubUI = LUIBase:New()
PetSkillSubUI.__index = PetSkillSubUI

function PetSkillSubUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetSkillSubUI)	
    o:Init(petData)
	return o
end


function PetSkillSubUI:Init(petData)
    self:RegistMsgs()
    self:InitMemberVariable(petData)
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowSkills()
    self:SetSkillSelect(1)
end

function PetSkillSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.SelectedPet,
        LUIPetEvent.PetDataChanged,
        LUIPetEvent.ChangePetSkill,
        LUIPetEvent.ChangePetLv,
		LUIPetEvent.UpdatePetData,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetSkillSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.SelectedPet then
        self:SetPetData(msg.value)
    elseif msg.msgId == LUIPetEvent.ChangePetSkill then
        self:SkillChanged(msg.value)
    elseif msg.msgId == LUIPetEvent.ChangePetLv then
        self:CheckPetLvChanged(msg.value.pid)
    -- elseif msg.msgId == LUIBagEvent.BagDataChanged then
    --     self:BagItemChanged()
	elseif msg.msgId == LUIPetEvent.UpdatePetData then
		self:SetPetData(msg.value)
    end
end

function PetSkillSubUI:CheckPetLvChanged(pid)
    if self.m_pPetData.id ~= pid then
        return
    end
    --检查天书技能格子开启
    for i = AppDef.Pet.MaxBornSkillNum + 1, AppDef.Pet.MaxSkillNum do
        local curSk = self.m_pPetData.skills[i]
        if curSk.skDetail == nil then
            if self.m_pPetData.star >= AppDef.Pet.LearnOpenStar[i - AppDef.Pet.MaxBornSkillNum] then
                self.m_pSkLockImgs[i]:setVisible(false)
                self.m_pNameLabels[i]:setString(GUITips.RSI_PET_MSG29)
            end
        end
    end
end

function PetSkillSubUI:SkillChanged(skInd)
    --print("SkillChanged",skInd)
    --天赋技能
    if skInd <= AppDef.Pet.MaxBornSkillNum then
        -- print(debug.traceback())
        local curSk = self.m_pPetData.skills[skInd]
        self:ShowBornSkill(curSk, skInd)

        local redPoint = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, skInd)
        if skInd < AppDef.Pet.MaxBornSkillNum and not Utils:ToBool(redPoint) then
            local nextInd = nil
            for i=1,AppDef.Pet.MaxBornSkillNum do
                if LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, i) then
                    nextInd = i
                    break
                end
            end
            if nextInd then
                self:SetSkillSelect(nextInd)
            end
        end
    else
        --
        self:InitPackSkillBooks()
        self:ShowBookSkill(self.m_pPetData.skills[skInd],skInd)
        self:CheckBookSkillRedPoint()
        if self.m_curTab == 1 then--背包
            self.m_pListTableView:reloadData()
        end
    end
    if self.m_curSkInd == skInd then
        self:ShowCurSkillInfo()
    end

    --
    local ani = ImodAnim:createWithFileSync("res2/fx/shengji_yuan")
    local function AniPlayEndCallback(sender)
        sender:removeFromParent()
    end
    ani:registerScriptEndCBHandler(AniPlayEndCallback)
    ani:PlayAction(0)
    local btnSize = self.m_pSkBtns[skInd]:getContentSize()
    ani:setPosition(cc.p(btnSize.width/2,btnSize.height/2))
    self.m_pSkBtns[skInd]:addChild(ani)
end

--[[
重新检查所有的天书技能红点
]]
function PetSkillSubUI:CheckBookSkillRedPoint()
    for i = AppDef.Pet.MaxBornSkillNum + 1, AppDef.Pet.MaxSkillNum do
        local curSk = self.m_pPetData.skills[i]
        local redPoint = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, i)
        self.m_pSkRedPointImgs[i]:setVisible(redPoint)
    end
end

function PetSkillSubUI:SetPetData(petData)
    self.m_pPetData = petData
    --self.m_curSkInd = 0
    self.m_bIsReplaceSkill = false
    self:InitRecommendSkiiList()
    self:ShowSkills()
    self:SetSkillSelect(1,true)
end

function PetSkillSubUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangSkillLayer2.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function PetSkillSubUI:onExit()
    --节点放在主节点上删除
    self:Destory()
    --self.m_pUILayer = nil
    self.m_pPetData = nil--当前选中的宠物数据
    self.m_pSkBtns = nil---技能按钮数组
    self.m_pSkChooseImgs = nil---选中效果数组
    self.m_pSkIcons = nil---技能icon显示数组
    self.m_pSkLockImgs = nil---技能锁数组
    self.m_pSkRedPointImgs = nil--技能红点数组
    self.m_pLvLabels = nil---技能名字数组
    self.m_pNameLabels = nil---技能名字数组

    self.m_pBornSkInfoPanel = nil--天赋技能信息层
    self.m_pBookSkUpgradePanel = nil--天书技能升级层
    self.m_pBookSkLearnPanel = nil--天书技能学习层

------------------------------天生技能列表变量--------------------------------------------------------
    self.m_pBagBtn = nil--背包按钮
    self.m_pAllBtn = nil--全部技能按钮
    self.m_pRecommendBtn = nil--推荐技能按钮
    self.m_pListPanel = nil--列表容器
    self.m_pListTableView = nil
    self.m_pLearnSkCell = nil--天书技能子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_curTab = nil--当前页签，1背包2全部3推荐
    self.m_curLearnSkInd = 0--当前选中要学习的下表

    self.m_bagSkillList = nil--背包里面可以学习的技能数组LBookSkStudyData
    self.m_allSkillList = nil--所有可以学习的技能数组LBookSkStudyData
    self.m_recommendSkillList = nil--推荐学习的技能数组LBookSkStudyData
    self.m_bIsReplaceSkill = nil--是否是替换技能
    self.m_pBornSkDescLabel = nil--天生技能描述
    self.m_pBornSkAttrUpLabel = nil--天生技能属性提升描述
    self.m_pBornSkAttrListView = nil
    --self.m_pBornSkNextDescLabel = nil--天生技能描述
---------------------------------------------------------------------------------------

    self.m_curSkInd = nil--当前选中的技能下标

    self.m_tmpLeftSkPosX = nil--天书技能学习左侧的技能图片X的位置
    self.m_tmpMidSkPosX = nil--天书技能学习左侧的技能图片X的位置,中间位置的坐标
    self.m_tmpRepBtnPosx = nil--天书技能替换按钮X位置
    self.m_tmpRepBtnMisPosx = nil--天书技能替换按钮中间X位置
    
end

--[[
初始化成员变量
]]
function PetSkillSubUI:InitMemberVariable(petData)
    self.m_pPetData = petData--当前选中的宠物数据
    self.m_pSkBtns = {}--技能按钮数组
    self.m_pSkChooseImgs = {}--选中效果数组
    self.m_pSkIcons = {}--技能icon显示数组
    self.m_pSkLockImgs = {}--技能锁数组
    self.m_pSkRedPointImgs = {}--技能红点数组
    self.m_pLvLabels = {}--技能名字数组
    self.m_pNameLabels = {}--技能名字数组

    self.m_pBornSkInfoPanel = nil--天赋技能信息层
    self.m_pBookSkUpgradePanel = nil--天书技能升级层
    self.m_pBookSkLearnPanel = nil--天书技能学习层

------------------------------天生技能列表变量--------------------------------------------------------
    self.m_pBagBtn = nil--背包按钮
    self.m_pAllBtn = nil--全部技能按钮
    self.m_pRecommendBtn = nil--推荐技能按钮
    self.m_pListPanel = nil--列表容器
    self.m_pListTableView = nil
    self.m_pLearnSkCell = nil--天书技能子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_curTab = 0--当前页签，1背包2全部3推荐
    self.m_curLearnSkInd = 0--当前选中要学习的下表
    self.m_bagSkillList = nil--背包里面可以学习的技能id数组
    self.m_allSkillList = nil--所有可以学习的技能id数组
    self.m_recommendSkillList = nil--推荐学习的技能id数组
    self.m_bIsReplaceSkill = false--是否是替换技能
    self.m_pBornSkDescLabel = nil--天生技能描述
    self.m_pBornSkAttrUpLabel = nil--天生技能属性提升描述
    self.m_pBornSkAttrListView = nil
    self.m_pBookSkDescLabel = nil--天书技能描述

    self.m_pBookSkAttrUpLabel = nil--天生技能属性提升描述
    self.m_pBookSkAttrListView = nil
    self.m_pBookNextSkDescLabel = nil--天书技能描述
---------------------------------------------------------------------------------------

    self.m_curSkInd = 0--当前选中的技能下标

    self.m_tmpLeftSkPosX = 0--天书技能学习左侧的技能图片X的位置
    self.m_tmpMidSkPosX = 0--天书技能学习左侧的技能图片X的位置,中间位置的坐标
    self.m_tmpRepBtnPosx = 0--天书技能替换按钮X位置
    self.m_tmpRepBtnMisPosx = 0--天书技能替换按钮中间X位置
end

function PetSkillSubUI:ShowBornSkill(curSk, ind)
    local redPoint = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, ind)
    self.m_pSkRedPointImgs[ind]:setVisible(redPoint)
    if curSk.skDetail == nil then
        --未开启，未知技能
        self.m_pSkLockImgs[ind]:setVisible(true)
        self.m_pLvLabels[ind]:setVisible(false)
        self.m_pSkIcons[ind]:setVisible(false)
        self.m_pNameLabels[ind]:setVisible(false)
    else
        if curSk.level == 0 then
            --未开启，等级0
            self.m_pSkLockImgs[ind]:setVisible(true)
            self.m_pLvLabels[ind]:setVisible(false)
            self.m_pNameLabels[ind]:setString("" .. ind .. GUITips.UI_XingKaiqi)

        else
            self.m_pSkLockImgs[ind]:setVisible(false)
            self.m_pLvLabels[ind]:setVisible(true)
            self.m_pLvLabels[ind]:setString(curSk.level)
            self.m_pNameLabels[ind]:setString(curSk.skDetail.name)
        end
        
        self.m_pSkIcons[ind]:loadTexture(string.format("Skill/UI/skill_%d.png", curSk.skDetail.id), ccui.TextureResType.localType)
        self.m_pSkIcons[ind]:setScale(0.80)
    end
end

function PetSkillSubUI:ShowBookSkill(curSk, ind)
    local redPoint = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, ind)
    self.m_pSkRedPointImgs[ind]:setVisible(redPoint)
    if curSk.skDetail == nil then
        --未开启，未知技能
        self.m_pSkLockImgs[ind]:setVisible(true)
        self.m_pLvLabels[ind]:setVisible(false)
        self.m_pSkIcons[ind]:setVisible(false)
        --print("ind=",ind)
        if self.m_pPetData.star >= AppDef.Pet.LearnOpenStar[ind - AppDef.Pet.MaxBornSkillNum] then
            self.m_pSkLockImgs[ind]:setVisible(false)
            self.m_pNameLabels[ind]:setString(GUITips.RSI_PET_MSG29)
        else
            self.m_pSkLockImgs[ind]:setVisible(true)
            local tips = "" .. AppDef.Pet.LearnOpenStar[ind - AppDef.Pet.MaxBornSkillNum] .. GUITips.UI_XingKaiqi
            self.m_pNameLabels[ind]:setString(tips)
        end
        

    else
        
        if curSk.level == 0 then
            --未开启，等级0
            self.m_pSkLockImgs[ind]:setVisible(true)
            self.m_pLvLabels[ind]:setVisible(false)

        else
            self.m_pSkLockImgs[ind]:setVisible(false)
            self.m_pLvLabels[ind]:setVisible(false)
            self.m_pLvLabels[ind]:setString(curSk.level)
        end
        local skName = self:GetBookSkillName(curSk.skDetail.name, curSk.level)
        self.m_pNameLabels[ind]:setString(skName)
        self.m_pSkIcons[ind]:setVisible(true)
        self.m_pSkIcons[ind]:loadTexture(string.format("Skill/UI/skill_%d.png", curSk.skDetail.id), ccui.TextureResType.localType)
        self.m_pSkIcons[ind]:setScale(0.80)
    end
end

--[[
获取天书技能的名称
@param1：技能表里的名称
@param2:技能等级
]]
function PetSkillSubUI:GetBookSkillName(skName, lv)
    return GUITips["UI_PET_LearnSkill_LV" .. lv] .. skName
end

function PetSkillSubUI:ShowSkills()
    --天赋技能
    for i = 1, AppDef.Pet.MaxBornSkillNum do
        local curSk = self.m_pPetData.skills[i]
        self:ShowBornSkill(curSk,i)
    end

    --天书技能
    for i = AppDef.Pet.MaxBornSkillNum + 1, AppDef.Pet.MaxSkillNum do
        local curSk = self.m_pPetData.skills[i]
        self:ShowBookSkill(curSk,i)
    end
end

function PetSkillSubUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("shenjiangSkillUI")
    local skillPanel = panel:getChildByName("Show")
    local infoPanel = panel:getChildByName("Info")
    for i = 1, AppDef.Pet.MaxSkillNum do
        self.m_pSkBtns[i] = skillPanel:getChildByName("Skill_" .. i)
        self.m_pSkChooseImgs[i] = self.m_pSkBtns[i]:getChildByName("Choose")
        self.m_pSkChooseImgs[i]:setVisible(false)
        self.m_pSkIcons[i] = self.m_pSkBtns[i]:getChildByName("Icon")
        self.m_pSkLockImgs[i] = self.m_pSkBtns[i]:getChildByName("Mask")
        self.m_pLvLabels[i] = self.m_pSkBtns[i]:getChildByName("Level")
        self.m_pNameLabels[i] = self.m_pSkBtns[i]:getChildByName("Name")
        self.m_pSkRedPointImgs[i] = self.m_pSkBtns[i]:getChildByName("Prompt")
    end

    self.m_pBornSkInfoPanel = infoPanel:getChildByName("Panel_1")--天赋技能信息层
    self.m_pBookSkUpgradePanel = infoPanel:getChildByName("Panel_2")--天书技能升级层
    self.m_pBookSkLearnPanel = infoPanel:getChildByName("Panel_3")--天书技能学习层

    local xiaoguoPanel = self.m_pBornSkInfoPanel:getChildByName("xiajixiaoguo")
    self.m_pBornSkAttrListView = xiaoguoPanel:getChildByName("ListView")
    self.m_pBornSkAttrUpLabel = xiaoguoPanel:getChildByName("Attribute")
    self.m_pBornSkAttrUpLabel:setVisible(false)
    local xiaoguoPanel = self.m_pBookSkUpgradePanel:getChildByName("xiajixiaoguo")
    self.m_pBookSkAttrListView = xiaoguoPanel:getChildByName("ListView")
    self.m_pBookSkAttrUpLabel = xiaoguoPanel:getChildByName("Attribute")
    self.m_pBookSkAttrUpLabel:setVisible(false)
    -- self.m_pBagBtn = self.m_pBookSkLearnPanel:getChildByName("Bag")--背包按钮
    -- self.m_pAllBtn = self.m_pBookSkLearnPanel:getChildByName("All")--全部技能按钮
    -- self.m_pRecommendBtn = self.m_pBookSkLearnPanel:getChildByName("Recommend")--推荐技能按钮
    -- self.m_pLearnSkCell = self.m_pBookSkLearnPanel:getChildByName("Item")--推荐技能按钮

end

function PetSkillSubUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function SkillClicked(sender)
        local ind = sender:getTag()
        self:SetSkillSelect(ind)
    end

    for i = 1, AppDef.Pet.MaxSkillNum do
        self.m_pSkBtns[i]:addClickEventListener(SkillClicked)
		self:MarkIntaractCObj(self.m_pSkBtns[i])
        self.m_pSkBtns[i]:setTag(i)
    end

    local function BornSkillLvUpBtnCallback(sender)
		if self.m_pbuyGold then
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
			return
		end
        local tag = sender:getTag()
        if tag == 4 then
            LuaNetSendMsg:QueryPetBornSkillLvUp(self.m_pPetData.id, self.m_curSkInd - 1)
        elseif tag == 14 then
            LuaNetSendMsg:QueryQuickPetBornSkillLvUp(self.m_pPetData.id, self.m_curSkInd-1)
        end
    end

    local consumePanel = self.m_pBornSkInfoPanel:getChildByName("Consume")
    local btn = consumePanel:getChildByName("btn_Upgrade")
    btn:setTag(4)
    btn:addClickEventListener(BornSkillLvUpBtnCallback)
	self:MarkIntaractCObj(btn)

    local btn2 = consumePanel:getChildByName("btn_Upgrade_0")
    btn2:setTag(14)
    btn2:addClickEventListener(BornSkillLvUpBtnCallback)
    self:MarkIntaractCObj(btn2)
end

function PetSkillSubUI:HandleReplaceBookSkill()
    local curSkId = 0
    local curSkStudyData
    if self.m_curTab == 1 then--背包
        curSkStudyData = self.m_bagSkillList[self.m_curLearnSkInd+1]
    elseif self.m_curTab == 2 then--全部

        curSkStudyData = self.m_allSkillList[self.m_curLearnSkInd+1]
    else--推荐
        curSkStudyData = self.m_recommendSkillList[self.m_curLearnSkInd+1]
    end
    curSkId = curSkStudyData.skId
    local hasSk = false
    local curSk
    for i = 1, #self.m_pPetData.skills do
        if self.m_pPetData.skills[i].skDetail ~= nil 
            and self.m_pPetData.skills[i].skDetail.id == curSkId then
            if (curSkStudyData.skLv == 1 and (self.m_pPetData.skills[i].level == 1 or self.m_pPetData.skills[i].level == 2) )
                or (curSkStudyData.skLv == 3 and (self.m_pPetData.skills[i].level == 3 or self.m_pPetData.skills[i].level == 4) ) then
                hasSk = true
                curSk = self.m_pPetData.skills[i]
                break
            end
        end
    end
    if hasSk then
        local strSkName = self:GetBookSkillName(curSk.skDetail.name,curSk.level)
        local tipsMsg = string.format(GUITips.UI_Pet_Skill_Forget_Tip, strSkName)
        local function OKCallback()
            LuaNetSendMsg:QueryPetBookSkillForget(self.m_pPetData.id, self.m_curSkInd - 1)
        end
        local function CancelCallback()
        end
        Utils:ShowDialogOKCancel(tipsMsg,OKCallback,CancelCallback)
        return
    end
    local itemId = curSkStudyData.itemId
    local skId = curSkStudyData.skId
    local skLv = curSkStudyData.skLv
    local skDetail = LSkillMgr:getSkillById(skId)
    local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    if itemNum > 0 then
        local oldSk = self.m_pPetData.skills[self.m_curSkInd]
        local strSkName1 = self:GetBookSkillName(oldSk.skDetail.name,oldSk.level)
        local strSkName2 = self:GetBookSkillName(skDetail.name,skLv)
        local tipsMsg = string.format(GUITips.UI_Pet_Skill_Replace_Tip, strSkName1, strSkName2)
        local function OKCallback()
			if self.m_pPetData ~= nil then
				LuaNetSendMsg:QueryPetBookSkillStudy(self.m_pPetData.id, self.m_curSkInd - 1, itemId)
			end
        end
        local function CancelCallback()
        end
        Utils:ShowDialogOKCancel(tipsMsg,OKCallback,CancelCallback)
        
    else
        LFastShopDataMgr:ShowNeedBuyMaterial(self._materialArr, AppDef.upgradeMaterial_ID.FM_Pet_Skill)
    end
end

function PetSkillSubUI:HandleLearnBookSkill()
    local curSkId = 0
    local curSkStudyData = nil
    if self.m_curTab == 1 then--背包
        curSkStudyData = self.m_bagSkillList[self.m_curLearnSkInd+1]
    elseif self.m_curTab == 2 then--全部

        curSkStudyData = self.m_allSkillList[self.m_curLearnSkInd+1]
    else--推荐
        curSkStudyData = self.m_recommendSkillList[self.m_curLearnSkInd+1]
    end
    if curSkStudyData == nil then
        return
    end
    curSkId = curSkStudyData.skId
    local skLv = 0
    local hasSk = false
    local curSk = nil
    for i = 1, #self.m_pPetData.skills do
        if self.m_pPetData.skills[i].skDetail ~= nil 
            and self.m_pPetData.skills[i].skDetail.id == curSkId then
            if (curSkStudyData.skLv == 1 and (self.m_pPetData.skills[i].level == 1 or self.m_pPetData.skills[i].level == 2) )
                or (curSkStudyData.skLv == 3 and (self.m_pPetData.skills[i].level == 3 or self.m_pPetData.skills[i].level == 4) ) then
                hasSk = true
                curSk = self.m_pPetData.skills[i]
                skLv = self.m_pPetData.skills[i].level
                break
            end
        end
    end
    if hasSk then
        local strSkName = self:GetBookSkillName(curSk.skDetail.name,curSk.level)
        local tipsMsg = string.format(GUITips.UI_Pet_Skill_Forget_Tip, strSkName)
        local function OKCallback()
            LuaNetSendMsg:QueryPetBookSkillForget(self.m_pPetData.id, self.m_curSkInd - 1)
        end
        local function CancelCallback()
        end
        Utils:ShowDialogOKCancel(tipsMsg,OKCallback,CancelCallback)
        return
    end
    local itemId = curSkStudyData.itemId

    local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    if itemNum > 0 then
        LuaNetSendMsg:QueryPetBookSkillStudy(self.m_pPetData.id, self.m_curSkInd - 1, itemId)
    else
        LFastShopDataMgr:ShowNeedBuyMaterial(self._materialArr, AppDef.upgradeMaterial_ID.FM_Pet_Skill)
    end
end

--[[
设置技能选择
]]
function PetSkillSubUI:SetSkillSelect(ind,isReset)
    isReset = isReset or false
    if not isReset and self.m_curSkInd == ind then
        return
    end
    local curSk = self.m_pPetData.skills[ind]
    if curSk.skDetail == nil and ind > AppDef.Pet.MaxBornSkillNum then
        if self.m_pPetData.star < AppDef.Pet.LearnOpenStar[ind - AppDef.Pet.MaxBornSkillNum] then
            local tips = string.format(GUITips.UI_Pet_Book_Skill_OpenLv, AppDef.Pet.LearnOpenStar[ind - AppDef.Pet.MaxBornSkillNum])
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,tips)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
    end
    if self.m_curSkInd > 0 then
        self.m_pSkChooseImgs[self.m_curSkInd]:setVisible(false)
    end
    self.m_curSkInd = ind
    self.m_pSkChooseImgs[self.m_curSkInd]:setVisible(true)
    self:ShowCurSkillInfo()
end

--[[
显示当前选中的技能信息
]]
function PetSkillSubUI:ShowCurSkillInfo()
    if self.m_curSkInd <= AppDef.Pet.MaxBornSkillNum then
        self.m_pBornSkInfoPanel:setVisible(true)
        self.m_pBookSkUpgradePanel:setVisible(false)
        self.m_pBookSkLearnPanel:setVisible(false)
        self:ShowCurBornSkillInfo()
    else
        self.m_pBornSkInfoPanel:setVisible(false)
        self:ShowCurBookSkillInfo()
    end
end

--[[
显示当前选中的天赋技能信息
]]
function PetSkillSubUI:ShowCurBornSkillInfo()
    --print("ShowCurBornSkillInfo")
    local curSk = self.m_pPetData.skills[self.m_curSkInd]

    local consumePanel = self.m_pBornSkInfoPanel:getChildByName("Consume")
    local btn = consumePanel:getChildByName("btn_Upgrade")
    local btn2 = consumePanel:getChildByName("btn_Upgrade_0")
    local redPointImg = btn:getChildByName("Prompt")
    local redPointImg2 = btn2:getChildByName("Prompt")
    if curSk.skDetail == nil then
        redPointImg:setVisible(false)
        redPointImg2:setVisible(false)
        return
    end
    local redPointVisible = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, self.m_curSkInd)
    redPointImg:setVisible(redPointVisible)
    redPointImg2:setVisible(redPointVisible)

    local skPanel = self.m_pBornSkInfoPanel:getChildByName("bg_Skill")
    local skIcon = skPanel:getChildByName("Icon")

    skIcon:setVisible(true)
    skIcon:loadTexture(string.format("Skill/UI/skill_%d.png", curSk.skDetail.id), ccui.TextureResType.localType)
    skIcon:setScale(0.80)

    local nameLabel = skPanel:getChildByName("Name")
    nameLabel:setString(curSk.skDetail.name)
    local lvLabel = skPanel:getChildByName("Level")
    lvLabel:setString("Lv." .. curSk.level)

    local nextAttrPanel = self.m_pBornSkInfoPanel:getChildByName("xiajixiaoguo")
    local descScrollView = self.m_pBornSkInfoPanel:getChildByName("ScrollView")
    if self.m_pBornSkDescLabel == nil then
        local descLabel = descScrollView:getChildByName("Describe")
        local fontSize = descLabel:getFontSize()
        local defalutColor = descLabel:getTextColor()
        local color = cc.c3b(defalutColor.r,defalutColor.g,defalutColor.b)
        self.m_pBornSkDescLabel = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width - 10,fontSize,color,false)
        self.m_pBornSkDescLabel:setPosition(descLabel:getPosition())
        descScrollView:addChild(self.m_pBornSkDescLabel)
        descLabel:setVisible(false)

        -- descLabel = nextAttrPanel:getChildByName("Describe")
        -- fontSize = descLabel:getFontSize()
        -- defalutColor = descLabel:getTextColor()
        -- color = cc.c3b(defalutColor.r,defalutColor.g,defalutColor.b)
        -- self.m_pBornSkNextDescLabel = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width,fontSize,color,false)
        -- self.m_pBornSkNextDescLabel:setPosition(descLabel:getPosition())
        -- nextAttrPanel:addChild(self.m_pBornSkNextDescLabel)
        -- descLabel:setVisible(false)
    end

    self.m_pBornSkAttrListView:removeAllItems()

    local curDesc = LDataConstMgr:GetHeroSkillDesc(curSk.skDetail.id, curSk.level)
    self.m_pBornSkDescLabel:setString(curDesc)

    local tipsLabel = nextAttrPanel:getChildByName("Tips")
    
    if curSk.level == 0 then
        consumePanel:setVisible(false)
        nextAttrPanel:setString(GUITips.Skill_Info_UnlockTitle2)
        local tips = string.format(GUITips.UI_Pet_Born_Skill_UnLock_Tip,self.m_curSkInd)
        tipsLabel:setString(tips)
        tipsLabel:setVisible(true)
        return
    end
    nextAttrPanel:setString(GUITips.Skill_Info_NextLvAttrTitle)
    consumePanel:setVisible(true)
    local isMax = false
    local lvUpData = LDataConstMgr:GetPetBornSKLvUpData(self.m_curSkInd, curSk.level)
    if lvUpData == nil then
        isMax = true
    end

    if isMax then
        consumePanel:setVisible(false)
        tipsLabel:setVisible(true)
        tipsLabel:setString(GUITips.Skill_Info_MaxLv)
        --self.m_pBornSkNextDescLabel:setVisible(false)
        return
    end
    local attrs = LDataConstMgr:GetSkillAttrDesc(curSk.skDetail.id, curSk.level)
    for i = 1, #attrs do
        local label = self.m_pBornSkAttrUpLabel:clone()
        label:setVisible(true)
        label:setString(attrs[i][1] .. ":")
        local vlabel = label:getChildByName("Value")
        vlabel:setString(attrs[i][2] .. "→" .. attrs[i][3])
        self.m_pBornSkAttrListView:pushBackCustomItem(label)
    end

    tipsLabel:setVisible(false)
    consumePanel:setVisible(true)
    local petLvLabel = consumePanel:getChildByName("Level"):getChildByName("Value")
    petLvLabel:setString(lvUpData.needLv)

    if self.m_pPetData.level < lvUpData.needLv then
        petLvLabel:setTextColor(AppDef.UIColor.RED)
    else
        petLvLabel:setTextColor(AppDef.UIColor.GREEN)
    end

    -- local goldLabel = consumePanel:getChildByName("Money1"):getChildByName("Value")

    -- goldLabel:setString(tostring(LRoleDataMgr.MyHeroInfo:GetDetailData().potential.."/"..lvUpData.costItemNum[2]))
    -- if lvUpData.costItemNum[2] > LRoleDataMgr.MyHeroInfo:GetDetailData().potential then
    --     goldLabel:setTextColor(AppDef.UIColor.RED)
    -- else
    --     goldLabel:setTextColor(AppDef.UIColor.GREEN)
    -- end
    

    local yuanbaoLabel = consumePanel:getChildByName("Money2"):getChildByName("Value")
    yuanbaoLabel:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().Money.."/"..lvUpData.costItemNum[1])
    if lvUpData.costItemNum[1] > LRoleDataMgr.MyHeroInfo:GetDetailData().Money then
        yuanbaoLabel:setTextColor(AppDef.UIColor.RED)
		self.m_pbuyGold = true
    else
        yuanbaoLabel:setTextColor(AppDef.UIColor.GREEN)
		self.m_pbuyGold = false
    end
end

--[[
显示当前选中的天书技能信息
]]
function PetSkillSubUI:ShowCurBookSkillInfo()
    local curSk = self.m_pPetData.skills[self.m_curSkInd]
    if curSk.skDetail == nil then
        self.m_bIsReplaceSkill = false
        self:ShowBookSkillList()
        return
    end
    self.m_pBookSkLearnPanel:setVisible(false)
    self:ShowBookSkUpgrade()
end

--[[
处理技能升级
]]
function PetSkillSubUI:HandleBookSkillLvUp()
    if self.m_pPetData.skills[self.m_curSkInd] == nil 
        or self.m_pPetData.skills[self.m_curSkInd].skDetail == nil then
        return
    end
    local curSkId = self.m_pPetData.skills[self.m_curSkInd].skDetail.id

    --print("QueryPetBookSkillLvUp",curSkId)
    LuaNetSendMsg:QueryPetBookSkillLvUp(self.m_pPetData.id, curSkId)
end

function PetSkillSubUI:SortBagSkillByRecommend()
    if self.m_bagSkillList == nil then
        self:InitPackSkillBooks()
    end
    if self.m_recommendSkillList then
        local temp = {}
        for i=1,#self.m_recommendSkillList do
            temp[self.m_recommendSkillList[i].skId] = true
        end
        for i=1,#self.m_bagSkillList do
            local data = self.m_bagSkillList[i]
            if data then
                local skId = self.m_bagSkillList[i].skId
                if temp[skId] then
                    table.remove(self.m_bagSkillList, i)
                    table.insert(self.m_bagSkillList, 1, data)
                end
            end
        end
    end
end

--[[
显示可以学习的技能列表
]]
function PetSkillSubUI:ShowBookSkillList()
    self:SortBagSkillByRecommend()
    self.m_pBookSkLearnPanel:setVisible(true)
    self.m_pBookSkUpgradePanel:setVisible(false)
    if self.m_pBagBtn == nil then
        self:InitBookSkillList()
    end
    self:SetDefalutLearnSkTab()
    -- self.m_curTab = 1--当前页签，1背包2全部3推荐
    -- self.m_curLearnSkInd = 0
    -- self.m_pListTableView:reloadData()
end

function PetSkillSubUI:InitPackSkillBooks()
    --初始化背包里面可以学习的技能
    self.m_bagSkillList = {}--背包里面可以学习的技能id数组
    self.m_allSkillList = LDataConstMgr:GetPetBookSkillList()--所有可以学习的技能id数组


    --插入背包技能列表
    local function InsertBagSkillList(studyData)
        local isExsit = false
        for k = 1, #self.m_bagSkillList do
            if self.m_bagSkillList[k] == studyData then
                isExsit = true
                break
            end
        end
        if not isExsit then
            table.insert(self.m_bagSkillList, studyData)
        end
    end

    for i = 1, #self.m_allSkillList do
        local consumeItemData = self.m_allSkillList[i]
        local itemId = consumeItemData.itemId
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)

        if itemNum > 0 then
            InsertBagSkillList(self.m_allSkillList[i])
        end
    end
end

--[[
初始化可以学习的技能列表
]]
function PetSkillSubUI:InitLearnSkillListData()
    
    self:InitPackSkillBooks()
    self:InitRecommendSkiiList()
    self:SortBagSkillByRecommend()
end

--[[
初始化推荐技能列表，每个宠物都不一样
]]
function PetSkillSubUI:InitRecommendSkiiList()
    self.m_recommendSkillList = {}--推荐学习的技能id数组
    for i = 1, #self.m_pPetData.baseData.recommend_skill do
        local data = LDataConstMgr:GetPetBookSkillStudyData(self.m_pPetData.baseData.recommend_skill[i])
        table.insert(self.m_recommendSkillList,data)
    end
end

--[[
初始化
]]
function PetSkillSubUI:InitBookSkillList()
    self:InitLearnSkillListData()
    self.m_pBagBtn = self.m_pBookSkLearnPanel:getChildByName("Bag")--背包按钮
    self.m_pAllBtn = self.m_pBookSkLearnPanel:getChildByName("All")--全部技能按钮
    self.m_pRecommendBtn = self.m_pBookSkLearnPanel:getChildByName("Recommend")--推荐技能按钮
    self.m_pLearnSkCell = self.m_pBookSkLearnPanel:getChildByName("Item")--推荐技能按钮
    self.m_cellSize = self.m_pLearnSkCell:getContentSize()
    self.m_pListPanel = self.m_pBookSkLearnPanel:getChildByName("ListView")--列表容器

    self:InitLearnSkillListTableView(self.m_pListPanel)

    local function TabClicked(sender)
        --print("TabClicked")
        local ind = sender:getTag()
        if self.m_curTab == ind then
            sender:setSelected(false)
            return
        end
        self:SetLearnSkTabSelected(ind)
    end

    
    self.m_pBagBtn:addClickEventListener(TabClicked)
	self:MarkIntaractCObj(self.m_pBagBtn)
    self.m_pBagBtn:setTag(1)
    self.m_pAllBtn:addClickEventListener(TabClicked)
	self:MarkIntaractCObj(self.m_pAllBtn)
    self.m_pAllBtn:setTag(2)
    self.m_pRecommendBtn:addClickEventListener(TabClicked)
	self:MarkIntaractCObj(self.m_pRecommendBtn)
    self.m_pRecommendBtn:setTag(3)

    local btn = self.m_pBookSkLearnPanel:getChildByName("btn_Study")
    local function StudyClicked(sender)
        if self.m_bIsReplaceSkill == true then
            self:HandleReplaceBookSkill()
        else
            self:HandleLearnBookSkill()
        end
        
    end
    btn:addClickEventListener(StudyClicked)
	self:MarkIntaractCObj(btn)
    -- self.m_pListTableView = nil
    -- self.m_pLearnSkCell = nil--天书技能子元素
    
end


--[[
设置默认选中
]]
function PetSkillSubUI:SetDefalutLearnSkTab()
    self.m_curTab = 1
    self.m_pBagBtn:setSelected(true)
    self.m_pAllBtn:setSelected(false)
    self.m_pRecommendBtn:setSelected(false)
    self.m_curLearnSkInd = 0
    self.m_pListTableView:reloadData()

    self:ShowLearnSkillItem()
end

function PetSkillSubUI:SetLearnSkTabSelected(ind)
    if self.m_curTab == ind then
        return
    end
    if self.m_curTab == 1 then
        self.m_pBagBtn:setSelected(false)
    elseif self.m_curTab == 2 then
        self.m_pAllBtn:setSelected(false)
    elseif self.m_curTab == 3 then
        self.m_pRecommendBtn:setSelected(false)
    end
    self.m_curTab = ind
    self.m_curLearnSkInd = 0
    self.m_pListTableView:reloadData()
    self:ShowLearnSkillItem()
end

function PetSkillSubUI:SkillCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pLearnSkCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowBookSkillCellInfo(cellChild,idx)

    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curLearnSkInd then 
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end
    return cell
end

function PetSkillSubUI:ShowBookSkillCellInfo(cell, ind)
    local curSkId = 0
    local curSkStudyData
    if self.m_curTab == 1 then--背包
        curSkStudyData = self.m_bagSkillList[ind+1]
    elseif self.m_curTab == 2 then--全部

        curSkStudyData = self.m_allSkillList[ind+1]
    else--推荐
        curSkStudyData = self.m_recommendSkillList[ind+1]
    end
    curSkId = curSkStudyData.skId
    local skDetail = LSkillMgr:getSkillById(curSkId)


    local descLabel = cell:getChildByName("NewDescribe")
    --
    if descLabel == nil then
        local oldLabel = cell:getChildByName("Describe")
        local fontSize = oldLabel:getFontSize()
        local defalutColor = oldLabel:getTextColor()
        local color = cc.c3b(defalutColor.r,defalutColor.g,defalutColor.b)
        descLabel = CCAysLabel:createWithFixedWidth(oldLabel:getContentSize().width,fontSize,color,false)
        descLabel:setPosition(oldLabel:getPosition())
        cell:addChild(descLabel)
        descLabel:setName("NewDescribe")
        oldLabel:removeFromParent()
    end
    --
    local curDesc = LDataConstMgr:GetHeroSkillDesc(curSkId, curSkStudyData.skLv)
    descLabel:setString(curDesc)

    local nameLabel = cell:getChildByName("Name")
    local strName = self:GetBookSkillName(skDetail.name, curSkStudyData.skLv)
    nameLabel:setString(strName)
    local iconImg = cell:getChildByName("bg_Skill"):getChildByName("Icon")
    iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", skDetail.id), ccui.TextureResType.localType)
    iconImg:setScale(0.80)

    local markLabel = cell:getChildByName("Mark")
    
    local curSk
    local isLearned = false
    for i = 1, AppDef.Pet.MaxSkillNum do
        curSk = self.m_pPetData.skills[i]
        if curSk.skDetail ~= nil and curSk.skDetail.id == curSkId and curSk.level > 0 then
            if (curSkStudyData.skLv == 1 and curSk.level >= 1) or (curSkStudyData.skLv == 3 and curSk.level >= 3) then
                isLearned = true
                break
            end
        end
    end
    markLabel:setVisible(isLearned)
    local recommandMarkLabel = cell:getChildByName("Mark_0")
    if recommandMarkLabel then
        recommandMarkLabel:setVisible(false)
        if self.m_curTab == 1 and (not isLearned) then--背包
            for i=1,#self.m_recommendSkillList do
                if curSkId == self.m_recommendSkillList[i].skId then
                    recommandMarkLabel:setVisible(true)
                    break
                end
            end
        end
    end
    -- if isLearned == true then
    --     print("isLearned",isLearned,"curSk.level",curSk.level)
    --     markLabel:setString(GUITips["UI_PET_LearnSkill_LV" .. curSk.level] .. GUITips.UI_Pet_Book_Skill_Learned)
    -- end
end


--[[
初始化右侧天生技能列表框
]]
function PetSkillSubUI:InitLearnSkillListTableView()
    local tableView = cc.TableView:create(self.m_pListPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pListPanel:getAnchorPoint())
    tableView:setPosition(cc.p(self.m_pListPanel:getPosition()))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pListPanel:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:LearnSkillCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_cellSize.width
        local height = self.m_cellSize.height
        --print("cellSizeForTable",width, height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:SkillCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local cnt = 0
        if self.m_curTab == 1 then--背包
            cnt = #self.m_bagSkillList
        elseif self.m_curTab == 2 then--全部
            cnt = #self.m_allSkillList
        else--推荐
            cnt = #self.m_recommendSkillList
        end
        return cnt
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pListTableView = tableView

    self.m_pListPanel:removeFromParent()
    self.m_pListPanel = nil
end

function PetSkillSubUI:LearnSkillCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    if self.m_curLearnSkInd == ind then
        return
    end

    local oldCell = self.m_pListTableView:cellAtIndex(self.m_curLearnSkInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nil then
            local selectImg = oldCellChild:getChildByName("Choose")
            selectImg:setVisible(false)
            --oldCellChild:setSelected(false)
        end
    end
    self.m_curLearnSkInd = ind
    --cellChild:setSelected(true)
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)

    self:ShowLearnSkillItem()
end

--[[
显示替换界面
]]
function PetSkillSubUI:ShowReplaceSkillInfo()
    local curSkId = 0
    local curSkStudyData
    if self.m_curTab == 1 then--背包
        curSkStudyData = self.m_bagSkillList[self.m_curLearnSkInd+1]
    elseif self.m_curTab == 2 then--全部

        curSkStudyData = self.m_allSkillList[self.m_curLearnSkInd+1]
    else--推荐
        curSkStudyData = self.m_recommendSkillList[self.m_curLearnSkInd+1]
    end
    local tipsLabel = self.m_pBookSkLearnPanel:getChildByName("Tips")
    if curSkStudyData == nil then
        local btn = self.m_pBookSkLearnPanel:getChildByName("btn_Study")
        btn:setVisible(false)
        local itemPanel = self.m_pBookSkLearnPanel:getChildByName("ConsumeItem")
        itemPanel:setVisible(false)
        tipsLabel:setVisible(true)
        return
    end
    tipsLabel:setVisible(false)
    curSkId = curSkStudyData.skId
    local skLv = 0
    local hasSk = false
    local curSk = nil
    for i = 1, #self.m_pPetData.skills do
        if self.m_pPetData.skills[i].skDetail ~= nil 
            and self.m_pPetData.skills[i].skDetail.id == curSkId then
            if (curSkStudyData.skLv == 1 and (self.m_pPetData.skills[i].level == 1 or self.m_pPetData.skills[i].level == 2) )
                or (curSkStudyData.skLv == 3 and (self.m_pPetData.skills[i].level == 3 or self.m_pPetData.skills[i].level == 4) ) then
                hasSk = true
                curSk = self.m_pPetData.skills[i]
                skLv = self.m_pPetData.skills[i].level
                break
            end
        end
    end
    local btn = self.m_pBookSkLearnPanel:getChildByName("btn_Study")
    btn:setVisible(true)
    local redPointImg = btn:getChildByName("Prompt")
    local itemPanel = self.m_pBookSkLearnPanel:getChildByName("ConsumeItem")
    itemPanel:setVisible(true)
    local btnTextLabel = btn:getChildByName("Text")

    --替换技能
    if hasSk then
        --已经学了不能替换
        --隐藏学习按钮
        redPointImg:setVisible(false)
        btnTextLabel:setString(GUITips.UI_Shengjiang_Btn_Forget)
        itemPanel:setVisible(false)
        return
    end

    local redPointVisible = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, self.m_curSkInd)
    
    redPointImg:setVisible(redPointVisible)
    btnTextLabel:setString(GUITips.UI_Shengjiang_Btn_Replace)


    btn:setVisible(true)
    itemPanel:setVisible(true)


    if curSkId == 0 or curSkId == nil then
        return
    end

    btn:setVisible(true)
    local itemId
    local itemNum
    --local consumeItemData = LDataConstMgr:GetPetBookSkillStudyData(curSkId)
    itemId = curSkStudyData.itemId--consumeItemData.itemId
    itemNum = 1

    
    local itemIconImg = itemPanel:getChildByName("Icon")
    local citem = LDataConstMgr:getCItemByID(itemId)
    local num = itemNum
    itemIconImg:loadTexture(string.format("item/equip%d.png", citem.m_pic), ccui.TextureResType.localType)
    --itemIconImg:setScale(0.80)
    local itemNameLabel = itemPanel:getChildByName("Name")
    itemNameLabel:setString(citem.m_name)

    local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)

    local itemNumLabel = itemPanel:getChildByName("Value")
    itemNumLabel:setString( "" .. itemNum .. "/" .. num)
    if itemNum >= num then
        itemNumLabel:setTextColor(UICOLOR_GREEN)
    else
        itemNumLabel:setTextColor(UICOLOR_RED)
        self:addLackItemData(itemId, num - itemNum)
    end

    
    local btnTextLabel = btn:getChildByName("Text")
    btnTextLabel:setString(GUITips.UI_Shengjiang_Btn_Replace)
end

function PetSkillSubUI:ShowLearnSkillItem()
    --print(debug.traceback())
    --self.m_curLearnSkInd
    self:clearLackItemData()
    if self.m_bIsReplaceSkill == true then
        self:ShowReplaceSkillInfo()
        return
    end

    --[[
    显示学习
    ]]
    local curSkId = 0
    local curSkStudyData
    if self.m_curTab == 1 then--背包
        curSkStudyData = self.m_bagSkillList[self.m_curLearnSkInd+1]
    elseif self.m_curTab == 2 then--全部
        curSkStudyData = self.m_allSkillList[self.m_curLearnSkInd+1]
    else--推荐
        curSkStudyData = self.m_recommendSkillList[self.m_curLearnSkInd+1]
    end
    if curSkStudyData == nil then
        local btn = self.m_pBookSkLearnPanel:getChildByName("btn_Study")
        btn:setVisible(false)
        local itemPanel = self.m_pBookSkLearnPanel:getChildByName("ConsumeItem")
        itemPanel:setVisible(false)
        return
    end

    curSkId = curSkStudyData.skId
    local skLv = 0
    local hasSk = false
    local curSk = nil
    for i = 1, #self.m_pPetData.skills do
        if self.m_pPetData.skills[i].skDetail ~= nil 
            and self.m_pPetData.skills[i].skDetail.id == curSkId then
            if (curSkStudyData.skLv == 1 and (self.m_pPetData.skills[i].level == 1 or self.m_pPetData.skills[i].level == 2) )
                or (curSkStudyData.skLv == 3 and (self.m_pPetData.skills[i].level == 3 or self.m_pPetData.skills[i].level == 4) ) then
                hasSk = true
                curSk = self.m_pPetData.skills[i]
                skLv = self.m_pPetData.skills[i].level
                break
            end
        end
    end
    local btn = self.m_pBookSkLearnPanel:getChildByName("btn_Study")
    local itemPanel = self.m_pBookSkLearnPanel:getChildByName("ConsumeItem")
    btn:setVisible(true)
    itemPanel:setVisible(true)

    local tipsLabel = self.m_pBookSkLearnPanel:getChildByName("Tips")

    if curSkId == 0 or curSkId == nil then
        tipsLabel:setVisible(true)
        return
    end
    tipsLabel:setVisible(false)
    
    local itemId = curSkStudyData.itemId
    local btnText = btn:getChildByName("Text")
    local redPointImg = btn:getChildByName("Prompt")
    local itemNum = 1
    if hasSk == false then
        local redPointVisible = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, self.m_curSkInd)
        redPointImg:setVisible(redPointVisible)
        btnText:setString(GUITips.UI_Shengjiang_Btn_Learn)
        itemPanel:setVisible(true)
    else
        redPointImg:setVisible(false);
        btnText:setString(GUITips.UI_Shengjiang_Btn_Forget)
        itemPanel:setVisible(false)
        return
    end

    
    local itemIconImg = itemPanel:getChildByName("Icon")
    local citem = LDataConstMgr:getCItemByID(itemId)
    local num = itemNum
    itemIconImg:loadTexture(string.format("item/equip%d.png", citem.m_pic), ccui.TextureResType.localType)
    --itemIconImg:setScale(0.80)

    local itemNameLabel = itemPanel:getChildByName("Name")
    itemNameLabel:setString(citem.m_name)

    local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)

    local itemNumLabel = itemPanel:getChildByName("Value")
    itemNumLabel:setString( "" .. itemNum .. "/" .. num)
    if itemNum >= num then
        itemNumLabel:setTextColor(UICOLOR_GREEN)
    else
        itemNumLabel:setTextColor(UICOLOR_RED)
        self:addLackItemData(itemId, num - itemNum)
    end

    
    local btnTextLabel = btn:getChildByName("Text")
    btnTextLabel:setString(GUITips.UI_Shengjiang_Btn_Learn)
end

--[[
显示天书技能升级
]]
function PetSkillSubUI:ShowBookSkUpgrade()
    local curSk = self.m_pPetData.skills[self.m_curSkInd]
    if curSk.skDetail == nil then
        return
    end
    self.m_pBookSkUpgradePanel:setVisible(true)

    

    local leftIconPanel = self.m_pBookSkUpgradePanel:getChildByName("bg_Skill_1")
    local arrow = self.m_pBookSkUpgradePanel:getChildByName("Arrows")
    if self.m_tmpLeftSkPosX == 0 then
        --第一次初始化位置
        self.m_tmpLeftSkPosX = leftIconPanel:getPositionX()
        self.m_tmpMidSkPosX = arrow:getPositionX()
    end
    
    local iconImg = leftIconPanel:getChildByName("Icon")
    iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", curSk.skDetail.id), ccui.TextureResType.localType)
    iconImg:setScale(0.80)
    local nameLabel = leftIconPanel:getChildByName("Name")
    local strName = AppDef:GetPetLearnSkillName(curSk.skDetail.id, curSk.level)
    nameLabel:setString(strName)


    local rightIconPanel = self.m_pBookSkUpgradePanel:getChildByName("bg_Skill_2")
    local isMax = false
    if curSk.level >= AppDef.Pet.MaxLearnSkillLv then
        --达到最高等级左侧图标移到中间位置，隐藏右边图片
        leftIconPanel:setPositionX(self.m_tmpMidSkPosX)
        rightIconPanel:setVisible(false)
        isMax = true
    else
        leftIconPanel:setPositionX(self.m_tmpLeftSkPosX)
        rightIconPanel:setVisible(true)

        iconImg = rightIconPanel:getChildByName("Icon")
        iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", curSk.skDetail.id), ccui.TextureResType.localType)
        iconImg:setScale(0.80)
        nameLabel = rightIconPanel:getChildByName("Name")
        strName = AppDef:GetPetLearnSkillName(curSk.skDetail.id, curSk.level + 1)
        nameLabel:setString(strName)
    end


    local nextAttrPanel = self.m_pBookSkUpgradePanel:getChildByName("xiajixiaoguo")
    local descScrollView = self.m_pBookSkUpgradePanel:getChildByName("ScrollView")
     if self.m_pBookSkDescLabel == nil then
        local descLabel = descScrollView:getChildByName("Describe")
        local fontSize = descLabel:getFontSize()
        local defalutColor = descLabel:getTextColor()
        local color = cc.c3b(defalutColor.r,defalutColor.g,defalutColor.b)
        self.m_pBookSkDescLabel = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width - 10,fontSize,color,false)
        self.m_pBookSkDescLabel:setPosition(descLabel:getPosition())
        descScrollView:addChild(self.m_pBookSkDescLabel)
        descLabel:setVisible(false)
    end
    local curDesc = LDataConstMgr:GetHeroSkillDesc(curSk.skDetail.id, curSk.level)
    self.m_pBookSkDescLabel:setString(curDesc)

    --
    
    local repBtn = self.m_pBookSkUpgradePanel:getChildByName("btn_Replace")
    local upgradeBtn = self.m_pBookSkUpgradePanel:getChildByName("btn_Upgrade")

    local redPointVisible = LRoleDataMgr:PetCheckSkillLvUp(self.m_pPetData, self.m_curSkInd)
    local redPointImg = upgradeBtn:getChildByName("Prompt");
    redPointImg:setVisible(redPointVisible)

    if self.m_tmpRepBtnPosx == 0 then
        --第一次初始化
        self.m_tmpRepBtnPosx = repBtn:getPositionX()
        self.m_tmpRepBtnMisPosx = self.m_tmpRepBtnPosx + (upgradeBtn:getPositionX() - self.m_tmpRepBtnPosx)/2


        local function ReplaceSkillClicked(sender)
            print("ReplaceSkillClicked")
            self.m_bIsReplaceSkill = true
            self:ShowBookSkillList()
        end
        repBtn:addClickEventListener(ReplaceSkillClicked)
		self:MarkIntaractCObj(repBtn)
        local function UpgradeSkillClicked(sender)
            print("UpgradeSkillClicked")
            self:HandleBookSkillLvUp()
        end
        upgradeBtn:addClickEventListener(UpgradeSkillClicked)
		self:MarkIntaractCObj(upgradeBtn)
    end
    self.m_pBookSkAttrListView:removeAllItems()
    local itemPanel = self.m_pBookSkUpgradePanel:getChildByName("ConsumeItem")
    if isMax then
        --显示满级
        itemPanel:setVisible(false)
        local tip = nextAttrPanel:getChildByName("Tips")
        tip:setVisible(true)
        arrow:setVisible(false)
        upgradeBtn:setVisible(false) 
        repBtn:setPositionX(self.m_tmpRepBtnMisPosx)
    else
        --显示下一级效果
        arrow:setVisible(true)
        itemPanel:setVisible(true)
        upgradeBtn:setVisible(true) 

        local attrs = LDataConstMgr:GetSkillAttrDesc(curSk.skDetail.id, curSk.level)
        for i = 1, #attrs do
            local label = self.m_pBookSkAttrUpLabel:clone()
            label:setVisible(true)
            label:setString(attrs[i][1])
            local vlabel = label:getChildByName("Value")
            vlabel:setString(attrs[i][2] .. "→" .. attrs[i][3])
            self.m_pBookSkAttrListView:pushBackCustomItem(label)
        end

        repBtn:setPositionX(self.m_tmpRepBtnPosx)
        



        local tip = nextAttrPanel:getChildByName("Tips")
        tip:setVisible(false)

        local itemIconImg = itemPanel:getChildByName("Icon")

        --
        local itemId
        local itemNum
        local consumeItemData = LDataConstMgr:GetPetLearnSkillLvUpData(curSk.skDetail.id, curSk.level)
        itemId = consumeItemData.itemId
        itemNum = consumeItemData.itemNum
        --
        local citem = LDataConstMgr:getCItemByID(itemId)
        local num = itemNum
        itemIconImg:loadTexture(string.format("item/equip%d.png", citem.m_pic), ccui.TextureResType.localType)
        --itemIconImg:setScale(0.80)

        local itemNameLabel = itemPanel:getChildByName("Name")
        itemNameLabel:setString(citem.m_name)

        local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)

        local itemNumLabel = itemPanel:getChildByName("Value")
        itemNumLabel:setString( "" .. itemNum .. "/" .. num)
        if itemNum >= num then
            itemNumLabel:setTextColor(UICOLOR_GREEN)
        else
            itemNumLabel:setTextColor(UICOLOR_RED)
            self:addLackItemData(itemId, num - itemNum)
        end

    end
end

--材料升级
function PetSkillSubUI:addLackItemData(id, num)
    -- body
    if self._materialArr then
        local material = {}
        material.id = id
        material.num = num
        table.insert(self._materialArr, material)
    end
end

function PetSkillSubUI:clearLackItemData( ... )
    -- body
    self._materialArr = {}
end

return PetSkillSubUI
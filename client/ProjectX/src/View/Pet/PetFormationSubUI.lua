--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    
end
local PetFormationSubUI = LUIBase:New()
PetFormationSubUI.__index = PetFormationSubUI

function PetFormationSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetFormationSubUI)	
    o:Init()
	return o
end


function PetFormationSubUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowFightModel()
    self:ShowFormation()
    
end

function PetFormationSubUI:ShowFormation()
    self:ShowCurFormation()
    self:ShowFormationAttr()
    self:clearLackItemData()
    self:ShowMatItem()
    self:ShowBtnTitle()
    self:CheckUseBtnVisible()
end

function PetFormationSubUI:ShowBtnTitle()

    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local fdata = LDataConstMgr:GetFormationLvUpData(data.id,1)

    local myFData = LRoleDataMgr.myFormation

    local lv = myFData:GetMyZhenfaLvById(data.id)
    local textLabel = self.m_pStudyBtn:getChildByName("Text")
    if lv > 0 then
        textLabel:setString(GUITips.UI_Shengjiang_Btn_LvUp)
    else
        textLabel:setString(GUITips.UI_Shengjiang_Btn_Learn)
    end

    local ret = LRoleDataMgr:FormationCheckUp(self.m_curInd + 1)
    local redImg = self.m_pStudyBtn:getChildByName("Prompt")
    redImg:setVisible(ret)
    
end

--[[
显示升级需要的材料
]]
function PetFormationSubUI:ShowMatItem()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local myFData = LRoleDataMgr.myFormation
    local lv = myFData:GetMyZhenfaLvById(data.id)

    local fdata
    local isMax = false
    if lv == 10 then
        --没有找到默认到了最大级
        isMax = true
        lv = 10
        fdata = LDataConstMgr:GetFormationLvUpData(data.id,lv)
    else
        fdata = LDataConstMgr:GetFormationLvUpData(data.id,lv)
    end

    

	if #fdata.cost == 0 then
		self.m_pCoinPanel:setVisible(false)
		self.zhenfabg:setVisible(false)
		self.m_pbgName:setVisible(false)
		self.m_pIconBtn:setVisible(false)
		self.m_pStudyBtn:setVisible(false)
        return
    end
	self.m_pCoinPanel:setVisible(true)
	self.zhenfabg:setVisible(true)
	self.m_pIconBtn:setVisible(true)
	self.m_pbgName:setVisible(true)
	self.m_pStudyBtn:setVisible(true)
	self.curFData = fdata
	local coinId = fdata.cost[2][1]
	local coinNum = fdata.cost[2][3]
	local coinitem = LDataConstMgr:getCItemByID(coinId)
	local coinIconImg = self.m_pCoinPanel:getChildByName("Icon")
	local path = "item/"..coinitem.pic..".png"
    Utils:SafeLoadTexture(coinIconImg, path, ccui.TextureResType.localType)
    local coinNumLabel = self.m_pCoinPanel:getChildByName("Num")
    coinNumLabel:setString(coinNum)

    local itemId = fdata.cost[1][1]--fdata.costItemId
    local itemNum = fdata.cost[1][3]--fdata.costItemNum
	
    local citem = LDataConstMgr:getCItemByID(itemId)

    local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    local itemIconImg = self.m_pIconBtn:getChildByName("Icon")
    itemIconImg:loadTexture(string.format("item/equip%d.png", citem.pic), ccui.TextureResType.localType)
    local itemNumLabel = self.m_pIconBtn:getChildByName("Value")
    itemNumLabel:setString( "" .. myItemNum .. "/" .. itemNum)
    if isMax or myItemNum >= itemNum then
        itemNumLabel:setTextColor(UICOLOR_GREEN)
    else
        itemNumLabel:setTextColor(UICOLOR_RED)
        self:addLackItemData(itemId, itemNum - myItemNum)
    end
    self.m_pMatNameLabel:setString(citem.name)
end

function PetFormationSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFormationEvent.PetFight,
        LUIFormationEvent.ChangePos,
        LUIFormationEvent.UseZhenfaChanged,
        LUIFormationEvent.ZhenfaChanged,
        LUILogicEvent.buyItemSucEvent,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetFormationSubUI:ProcessEvent(msg)
    if msg.msgId == LUIFormationEvent.PetFight then
        self:PetFightStateChanged(msg.value)
    elseif msg.msgId == LUIFormationEvent.ChangePos then
        self:ChangeFightPos(msg.value[1],msg.value[2])
    elseif msg.msgId == LUIFormationEvent.UseZhenfaChanged then
        self:UseZhenfa()
    elseif msg.msgId ==  LUIFormationEvent.ZhenfaChanged then
        self:ZhenfaUpdate()
    elseif msg.msgId == LUILogicEvent.buyItemSucEvent  then
        if LFastShopDataMgr.m_curUseMattrial == AppDef.upgradeMaterial_ID.FM_Pet_Formation then
            self:ZhenfaUpdate()
            LuaNetSendMsg:QueryFormationLvUp(data.id)
        end
    end
end

--[[
阵法升级或学习
]]
function PetFormationSubUI:ZhenfaUpdate()
    self:FormationUpdate()
    self:ShowFormationAttr()
    self:clearLackItemData()
    self:ShowMatItem()
    self:ShowBtnTitle()
end

function PetFormationSubUI:UseZhenfa()
    self:FormationUpdate()
    self:ShowCurFormation()
    
end

--[[
新学习了阵法或者阵法升级
@param1:fid需要更新的阵法id
]]
function PetFormationSubUI:FormationUpdate(fid)
    local list = LDataConstMgr:GetFormationDataList()
    local myFData = LRoleDataMgr.myFormation
    --检测导航条的红点
    local isRedPot = false
    for i = 1, #list do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            cell = cell:getChildByTag(123)
            local tmpPanel = cell:getChildByName("bg_Formation")
            local lvLabel = tmpPanel:getChildByName("Level")
            local useFlagImg = cell:getChildByName("Tag")
            if myFData.useId == list[i].id then
                useFlagImg:setVisible(true)
            else
                useFlagImg:setVisible(false)
            end

            local ret = LRoleDataMgr:FormationCheckUp(i)
            if ret then
                isRedPot = true
            end
            local redImg = cell:getChildByName("Prompt")
            redImg:setVisible(ret)

            local lv = myFData:GetMyZhenfaLvById(list[i].id)
            if lv > 0 then
                lvLabel:setString("Lv." .. lv)
            else
                lvLabel:setString(GUITips.RSI_PAGE_MSG1)
            end
        end
    end
    self:CheckUseBtnVisible()
    --self:checkNavigationRedPot(isRedPot)
end


function PetFormationSubUI:checkNavigationRedPot(RedPot)
    -- body
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {5, RedPot})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetFormationSubUI:ChangeFightPos(oldPos, newPos)
    local oldInd
    local newInd
    for i = 1, #self.m_fightArr do
        if self.m_fightArr[i][2] == oldPos then
            oldInd = i
        elseif self.m_fightArr[i][2] == newPos then
            newInd = i
        end
    end
    local oldArr = self.m_fightArr[oldInd]
	if oldArr == nil then
		return
	end
    local newArr = self.m_fightArr[newInd]
    if newArr == nil then
        self.m_pModelNodeList[oldArr[2]]:setVisible(false)
        oldArr[2] = newPos
        if oldArr[1] == 0 then
            self:ShowHeroFightUnit(oldArr[2])
        else
            local petData = LRoleDataMgr.Pet:GetPetById(oldArr[1])
            self:ShowPetFightUnit(oldArr[2],petData)
        end
        return
    end
    oldArr[2] = newPos
    newArr[2] = oldPos
    if oldArr[1] == 0 then
        self:ShowHeroFightUnit(oldArr[2])
    else
        local petData = LRoleDataMgr.Pet:GetPetById(oldArr[1])
        self:ShowPetFightUnit(oldArr[2],petData)
    end

    if newArr[1] == 0 then
        self:ShowHeroFightUnit(newArr[2])
    else
        local petData = LRoleDataMgr.Pet:GetPetById(newArr[1])
        self:ShowPetFightUnit(newArr[2],petData)
    end
end

function PetFormationSubUI:ShowHeroFightUnit(fightPos)
    local data = LRoleDataMgr.MyHeroInfo
	if fightPos > AppDef.BTConst.MaxHalfUnitNum or fightPos <= 0 then
		return
	end
    self.m_pModelNodeList[fightPos]:setVisible(true)
    self.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            data:GetModel(), 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            0,
                                            0,
                                            0)
    self.m_pModelNodeList[fightPos]:PlayStand(1, true)
end

function PetFormationSubUI:PetFightStateChanged(showPos)

    if showPos > 0 then
        local petData = LRoleDataMgr.Pet:GetPetByFightPosFormation(showPos)
        if petData == nil then
            return
        end
        for i = 1, #self.m_fightArr do
            if self.m_fightArr[i][1] == pid then
                return
            end
        end
        table.insert(self.m_fightArr, {pid,petData.fightPos})
        self:ShowPetFightUnit(petData.fightPos, petData)
    else
        for i = 1, #self.m_fightArr do
            if self.m_fightArr[i][1] == pid then
                self:ShowPetFightUnit(self.m_fightArr[i][2])
                table.remove(self.m_fightArr, i)
                return
            end
        end
    end
end

--[[
显示宠物出站位模型
]]
function PetFormationSubUI:ShowPetFightUnit(fightPos, petData)
    -- dump(petData, "ShowPetFightUnit ===>")
    if petData == nil then
        self.m_pModelNodeList[fightPos]:setVisible(false)
        return
    end
    print("ShowPetFightUnit ==== pos>", fightPos, petData.baseData.pic)
    self.m_pModelNodeList[fightPos]:setVisible(true)
    self.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Monster, petData.baseData.pic)
    -- self.m_pModelNodeList[fightPos] = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, petData.id)
    self.m_pModelNodeList[fightPos]:PlayStand(1, true)
end

function PetFormationSubUI:ShowFightModel()
    for i = 1, #self.m_fightArr do
        if self.m_fightArr[i][1] == 0 then
            self:ShowHeroFightUnit(self.m_fightArr[i][2])
        else
            local petData = LRoleDataMgr.Pet:GetPetById(self.m_fightArr[i][1])
            self:ShowPetFightUnit(self.m_fightArr[i][2],petData)
        end
    end
end
--[[
使用阵容
]]
function PetFormationSubUI:ShowCurFormation()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    if finfo == nil then
        return
    end

    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local ind = self:GetCurFormationPos(i)
        if ind > 0 then
            self.m_pPosNumList[i]:setVisible(true)
            local numLabel = self.m_pPosNumList[i]
            numLabel:setString(ind)
            self.m_pPosBtnList[i]:setOpacity(255)--40%透明度
            if finfo.posOpenLvList[ind] > LRoleDataMgr.MyHeroInfo.level then
                self.m_pPosLockList[i]:setVisible(true)
                local unlockText = self.m_pPosLockList[i]:getChildByName("Text")
                local strUnlock = string.format(unlockText:getString(), finfo.posOpenLvList[ind])
--                print("the string is ", finfo.posOpenLvList[ind], strUnlock, unlockText:getString())
                unlockText:setString(strUnlock)
            else
                self.m_pPosLockList[i]:setVisible(false)
            end
        else
            self.m_pPosBtnList[i]:setOpacity(102)--40%透明度
            self.m_pPosLockList[i]:setVisible(false)
            self.m_pPosNumList[i]:setVisible(false)
        end
    end

    for i = 1, AppDef.Formation.MaxFightNum do

        local pos = finfo.posList[i]
        self.m_pModelNodeList[i]:retain()
        self.m_pModelNodeList[i]:removeFromParent()
        self.m_pNodeList[pos]:addChild(self.m_pModelNodeList[i])
        self.m_pModelNodeList[i]:release()
    end

    for i = 1, #self.m_fightArr do
        self.m_pModelNodeList[self.m_fightArr[i][2]]:setVisible(true)
        self.m_pModelNodeList[self.m_fightArr[i][2]]:PlayStand(1, true)
    end
end

function PetFormationSubUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/shenjiangzhenxingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function PetFormationSubUI:onExit()
    --节点放在主节点上删除
    --self.m_pUILayer = nil
    self.m_pLayout = nil--阵型列表
    self.m_pCell = nil--阵型子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_pTableView = nil--阵型tableView
    self.m_pUseBtn = nil--使用按钮

    self.m_pPosBtnList = nil
    self.m_pPosPanelList = nil
    self.m_pModelNodeWorldPosList = nil
    self.m_pPosLockList = nil
    self.m_pPosNumList = nil
    self.m_pPosPanelList = nil
    --出站模型父节点列表，9个
    self.m_pNodeList = nil
    --出站模型列表，5个
    self.m_pModelNodeList = nil


    self.m_pIconBtn = nil--阵型icon
    self.m_pMatNameLabel = nil--升级材料的名字
    self.m_pAddAttrLabels = nil--属性加成Label
    self.m_pKezhiLabel = nil--克制Label
    self.m_pStudyBtn = nil--学习按钮
    self.m_curInd = nil--当前选中的阵型

    self.m_curMoveInd = nil--当前选中需要切换位置的模型下表
    self.m_pTouchBeganPos = nil

    --[[
    出站宠物id列表
    {
        {pid, fightpos},
        {pid, fightpos},
        ...
        如果pid==0就是英雄
    }
    ]]
    self.m_fightArr = nil
    self:Destory()
end

--[[
初始化成员变量
]]
function PetFormationSubUI:InitMemberVariable()
    self.m_pLayout = nil--阵型列表
    self.m_pCell = nil--阵型子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_pTableView = nil--阵型tableView

    self.m_pPosBtnList = {}
    self.m_pPosPanelList = {}
    self.m_pModelNodeWorldPosList = {}
    self.m_pPosLockList = {}
    self.m_pPosNumList = {}
    --出站模型父节点列表，9个
    self.m_pNodeList = {}
    --出站模型列表，5个
    self.m_pModelNodeList = {}


    self.m_pIconBtn = nil--阵型icon
    self.m_pMatNameLabel = nil--升级材料的名字
    self.m_pAddAttrLabels = {}--属性加成Label
    self.m_pKezhiLabel = nil--克制Label
    self.m_pStudyBtn = nil--学习按钮
    self.m_curInd = 0--当前选中的阵型

    local myFData = LRoleDataMgr.myFormation
    local flist = LDataConstMgr:GetFormationDataList()
    for i = 1, #flist do
        if flist[i].id == myFData.useId then
            self.m_curInd = i - 1
            break
        end
    end
    
    self.m_curMoveInd = 0--当前选中需要切换位置的模型下表
    self.m_pTouchBeganPos = cc.p(0,0)

    --[[
    出站宠物id列表
    {
        {pid, fightpos},
        {pid, fightpos},
        ...
        如果pid==0就是英雄
    }
    ]]
    self.m_fightArr = {}
    self:InitFightUnitData()
    
end

--[[
初始化出站单位数据
]]
function PetFormationSubUI:InitFightUnitData()
    -- dump(LRoleDataMgr.Pet.petlist, "===========================>")
    for i = 1, #LRoleDataMgr.Pet.petlist do
        if LRoleDataMgr.Pet.petlist[i].fightPos > 0 then
            table.insert(self.m_fightArr, {LRoleDataMgr.Pet.petlist[i].id,LRoleDataMgr.Pet.petlist[i].fightPos})
        end
    end

end

function PetFormationSubUI:CheckUseBtnVisible()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]

    local myFData = LRoleDataMgr.myFormation

    local lv = myFData:GetMyZhenfaLvById(data.id)

    if myFData.useId == data.id or lv == 0 then
        self.m_pUseBtn:setVisible(false)
    else

        self.m_pUseBtn:setVisible(true)
    end
end


function PetFormationSubUI:InitUICtr()

    -- local function closeCallback()
    --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetFormationSubUI")
    --     self:SendMsg(LGameMsg.m_initUIMsg)
    -- end
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local panel = self.m_pUILayer:getChildByName("FormationUI")
    local listPanel = panel:getChildByName("List_Formation")
    self.m_pLayout = listPanel:getChildByName("ListView")--阵型列表
    self.m_pUseBtn = listPanel:getChildByName("btn_Use")
    self.m_pCell = listPanel:getChildByName("Item")--阵型子元素
    self.m_cellSize = self.m_pCell:getContentSize()--子元素尺寸

    local formationPanel = panel:getChildByName("Show")
    local posPanel = formationPanel:getChildByName("Formation")
	posPanel:setTouchEnabled(false)
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosBtnList[i] = posPanel:getChildByName("Position" .. i)
        self.m_pPosPanelList[i] = self.m_pPosBtnList[i]:getChildByName("Panel")
        self.m_pPosLockList[i] = self.m_pPosBtnList[i]:getChildByName("Lock")
        self.m_pPosNumList[i] = self.m_pPosBtnList[i]:getChildByName("Num")
        self.m_pNodeList[i] = posPanel:getChildByName("Node_" .. i)
        self.m_pModelNodeWorldPosList[i] = self.m_pNodeList[i]:convertToWorldSpace(cc.p(0,0))
    end

    
    --出站模型列表，5个
    self.m_pModelNodeList = {}
    local infoPanel = formationPanel:getChildByName("Info")
    for i = 1, AppDef.Formation.MaxFightNum do
        self.m_pModelNodeList[i] = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
        self.m_pNodeList[i]:addChild(self.m_pModelNodeList[i])
        local tmp = infoPanel:getChildByName("Attribute" .. i)
        self.m_pAddAttrLabels[i] = tmp:getChildByName("Content")
    end
    self.m_pCoinPanel = infoPanel:getChildByName("CoinBg")
	self.zhenfabg = infoPanel:getChildByName("Image_zhenfabg")
    self.m_pIconBtn = infoPanel:getChildByName("btn_Material")
    self.m_pKezhiLabel = infoPanel:getChildByName("Restriction"):getChildByName("Content")
    self.m_pStudyBtn = infoPanel:getChildByName("btn_Upgrade")
	self.m_pbgName = infoPanel:getChildByName("bg_Name")
    self.m_pMatNameLabel = infoPanel:getChildByName("bg_Name"):getChildByName("Name")

    local BG = self.m_pUILayer:getChildByName("Bg")
    local Popup = BG:getChildByName("Popup")
    local Btn_close = Popup:getChildByName("Btn_close")
    Btn_close:addClickEventListener(function ( sender )
        -- body
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetFormationSubUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)

    self:InitTableView()
end

function PetFormationSubUI:InitTableView()
    local tableView = cc.TableView:create(self.m_pLayout:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pLayout:getAnchorPoint())
    tableView:setPosition(self.m_pLayout:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pLayout:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:PetCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_cellSize.width
        local height = self.m_cellSize.height
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:FormationCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local list = LDataConstMgr:GetFormationDataList()
        local cnt = #list
        return cnt
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTableView = tableView

    self.m_pLayout:removeFromParent()
    self.m_pLayout = nil
end

function PetFormationSubUI:PetCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    if self.m_curInd == ind then
        return
    end

    local oldCell = self.m_pTableView:cellAtIndex(self.m_curInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nil then
            local selectImg = oldCellChild:getChildByName("Choose")
            selectImg:setVisible(false)
            --oldCellChild:setSelected(false)
        end
    end
    self.m_curInd = ind
    --cellChild:setSelected(true)
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)
    
    self:ShowFormation()
end

function PetFormationSubUI:ShowFormationAttr()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local myFData = LRoleDataMgr.myFormation
    local lv = myFData:GetMyZhenfaLvById(data.id)
    if lv == 0 then
        lv = 1
    end
    local fdata = LDataConstMgr:GetFormationLvUpData(data.id,lv)

    -- dump(fdata, "ShowFormationAttr fdata ===>")

    --每个站位对应两个附加属性值
    local attrType
    local attrValue
    local arrName
    local strAttr = ""
    local tmp = ""
    for i = 1, AppDef.Formation.MaxFightNum do
        strAttr = ""
        for j = 1,#fdata.addAttrType[i] do
            attrType = fdata.addAttrType[i][j]
            -- print("attrType",attrType)
            if attrType == AppDef.EAttrType.EAT_ATTACK then
                arrName = GUITips.Item_Info_Attr145
            else
                arrName = LDataConstMgr:GetItemAttrName(attrType)
            end
            attrValue = fdata.addAttrValue[i][j]
            if AppDef:IsRatioAttr(attrType) then
                attrValue = attrValue / 100.0
                tmp = "%"
            else
                tmp = ""
            end

            if attrValue > 0 then
                strAttr = strAttr .. arrName .. "+" .. attrValue .. tmp .. "  "
            else
                strAttr = strAttr .. arrName .. attrValue .. tmp .. "  "
            end
        end
    
        self.m_pAddAttrLabels[i]:setString(strAttr)
    end

    strAttr = ""
    for i = 1, #data.restraintList do
        local kezhiData = LDataConstMgr:GetFormationDataById(data.restraintList[i])
        strAttr = strAttr .. kezhiData.name .. "  "
    end
    self.m_pKezhiLabel:setString(strAttr)
end

function PetFormationSubUI:FormationCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowFormationCellInfo(cellChild,idx)

    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curInd then 
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end
    return cell
end

function PetFormationSubUI:ShowFormationCellInfo(cell, ind)

    local myFData = LRoleDataMgr.myFormation


    local flist = LDataConstMgr:GetFormationDataList()
    local fdata = flist[ind + 1]
    
    local tmpPanel = cell:getChildByName("bg_Formation")
    local lvLabel = tmpPanel:getChildByName("Level")

    local nameLabel = tmpPanel:getChildByName("Name")
    nameLabel:setString(fdata.name)

    local useFlagImg = cell:getChildByName("Tag")

    if myFData.useId == fdata.id then
        useFlagImg:setVisible(true)
    else
        useFlagImg:setVisible(false)
    end

    local ret = LRoleDataMgr:FormationCheckUp(ind + 1)
    local redImg = cell:getChildByName("Prompt")
    redImg:setVisible(ret)

    local lv = myFData:GetMyZhenfaLvById(fdata.id)
    if lv > 0 then
        lvLabel:setString("Lv." .. lv)
    else
        lvLabel:setString(GUITips.RSI_PAGE_MSG1)
    end


    local iconImg = tmpPanel:getChildByName("Icon")
    local iconRes = AppDef.Formation.IconRes .. fdata.id .. ".png"
    iconImg:loadTexture(iconRes,ccui.TextureResType.localType)
end

function PetFormationSubUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function MatItemClicked(sender)
        local flist = LDataConstMgr:GetFormationDataList()
        local data = flist[self.m_curInd + 1]

        local fdata = LDataConstMgr:GetFormationLvUpData(data.id,1)
        local itemId = fdata.cost[1][1]--fdata.costItemId

        local citem = LDataConstMgr:getCItemByID(itemId)
        local item = 
        {
            itemType = "CItem",
            itemData = {m_item = citem},
			showFrom = true,
        }
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self.m_pIconBtn:addClickEventListener(MatItemClicked)
	self:MarkIntaractCObj(self.m_pIconBtn) 
    local function StudyBtnClicked(sender)
        self:HandleStudy()
    end
    self.m_pStudyBtn:addClickEventListener(StudyBtnClicked)
	self:MarkIntaractCObj(self.m_pStudyBtn) 

    local function ChangePosBtnTouched(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.began then
            self.m_pTouchBeganPos = pTouch:getTouchBeganPosition()
            local ind = pTouch:getTag()
            self:PosBtnTouchBegan(ind)
        elseif pEvent == ccui.TouchEventType.moved then
            local movePos = pTouch:getTouchMovePosition()
            self:PosBtnTouchMoved(movePos)
        elseif pEvent == ccui.TouchEventType.ended
                or pEvent == ccui.TouchEventType.canceled then
            self:PosBtnTouchEnd()
        end
    end

    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosPanelList[i]:addTouchEventListener(ChangePosBtnTouched)
		self:MarkIntaractCObj(self.m_pPosPanelList[i])
        self.m_pPosPanelList[i]:setTag(i)
        self.m_pPosPanelList[i]:setTouchEnabled(true)
    end

    local function UseZhenfaClicked( sender )
        -- body
        local flist = LDataConstMgr:GetFormationDataList()
        local data = flist[self.m_curInd + 1]
        local myFData = LRoleDataMgr.myFormation

        local lv = myFData:GetMyZhenfaLvById(data.id)
        if lv > 0 then
            LuaNetSendMsg:QueryFormationUse(data.id)
        end
    end
    self.m_pUseBtn:addClickEventListener(UseZhenfaClicked)
	self:MarkIntaractCObj(self.m_pUseBtn) 
end


function PetFormationSubUI:PosBtnTouchMoved(movePos)
    if self.m_curMoveInd <= 0 then
        return
    end
    local offx = movePos.x - self.m_pTouchBeganPos.x
    local offy = movePos.y - self.m_pTouchBeganPos.y
    self.m_pTouchBeganPos = movePos
    local modelPos = cc.p(self.m_pModelNodeList[self.m_curMoveInd]:getPosition())
    self.m_pModelNodeList[self.m_curMoveInd]:setPosition(cc.p(modelPos.x + offx, modelPos.y + offy))
end

--[[
根据9宫格下标获取出站位置
]]
function PetFormationSubUI:GetCurFormationPos(ind)
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    for i = 1, AppDef.Formation.MaxFightNum do
        if finfo.posList[i] == ind then
            return i
        end
    end
    return 0
end

function PetFormationSubUI:PosBtnTouchBegan(posInd)
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    
    local ind = self:GetCurFormationPos(posInd)
    if ind == 0 then
        return
    end

    if finfo.posOpenLvList[ind] > LRoleDataMgr.MyHeroInfo.level then
        return
    end
    self.m_curMoveInd = ind
end

function PetFormationSubUI:PosBtnTouchEnd()
    if self.m_curMoveInd <= 0 then
        return
    end
    local modeNode = self.m_pModelNodeList[self.m_curMoveInd]
    local endPos = cc.p(self.m_pModelNodeList[self.m_curMoveInd]:getPosition())
    local endWorldPos = modeNode:convertToWorldSpace(cc.p(0,0))
    self.m_pModelNodeList[self.m_curMoveInd]:setPosition(cc.p(0,0))
    local minDis = 1000000
    local minInd = 0
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local dis = cc.pDistanceSQ(endWorldPos, self.m_pModelNodeWorldPosList[i])
        if minDis > dis then
            minDis = dis
            minInd = i
        end
        
    end

    local oldPos = self.m_curMoveInd
    local newPos = self:GetCurFormationPos(minInd)
    self.m_curMoveInd = 0
    if oldPos ~= newPos
        and minDis <= 1000 then
        LuaNetSendMsg:QueryFormationChangePos(oldPos, newPos)
    end
end

function PetFormationSubUI:HandleStudy()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
	local coinid = self.curFData.cost[2][1]
	local coinnum = self.curFData.cost[2][3]
	local coinitem = LDataConstMgr:getCItemByID(coinid)
	local myCoinNum = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
	local itemid = self.curFData.cost[1][1]
	local itemnum = self.curFData.cost[1][3]
	local pitem = LDataConstMgr:getCItemByID(itemid)
	local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemid)
	if myItemNum < itemnum then
		Utils:ShowScrollTips( string.format(GUITips.RSI_SHOP_TIPS3,  pitem.name))
		return
	elseif myCoinNum < coinnum then
		Utils:ShowScrollTips( string.format(GUITips.RSI_SHOP_TIPS3,  coinitem.name))
		return
	end
	
    if self._materialArr == nil then
        self:clearLackItemData()
    end

    if #self._materialArr > 0 then
        LFastShopDataMgr:ShowNeedBuyMaterial(self._materialArr, AppDef.upgradeMaterial_ID.FM_Pet_Formation)
        return
    end
    LuaNetSendMsg:QueryFormationLvUp(data.id)
end

--材料升级
function PetFormationSubUI:addLackItemData(id, num)
    -- body
    local material = {}
    material.id = id
    material.num = num
    table.insert(self._materialArr, material)
end

function PetFormationSubUI:clearLackItemData( ... )
    -- body
    self._materialArr = {}
end 


return PetFormationSubUI
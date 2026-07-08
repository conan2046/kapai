--[[
lua里面的游戏逻辑控制
]]
local PetFormationUI = LUIBase:New()
PetFormationUI.__index = PetFormationUI
PetFormationUI.IsHideInBattle = true
function PetFormationUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,PetFormationUI)	
    o:Init(userData)
	return o
end


function PetFormationUI:Init(userData)
    self:RegistMsgs()
    self:InitMemberVariable(userData)
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowCurFormation()
    self:ShowEnemyFormation()
    self:ShowPassContent()
    self:ShowKeZhi()
end

function PetFormationUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFormationEvent.ChangePos,
        LUIFormationEvent.UseZhenfaChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetFormationUI:ProcessEvent(msg)
    if msg.msgId == LUIFormationEvent.ChangePos then
        self:ChangeFightPos(msg.value[1],msg.value[2])
    elseif msg.msgId == LUIFormationEvent.UseZhenfaChanged then
        self:UseZhenfa()
    end
end

function PetFormationUI:UseZhenfa()
    local offset = self.m_pTableView:getContentOffset()
    self:RefreshIconItem()                                         
    self.m_pTableView:setContentOffset(offset)

    self:InitFightUnitData()
    self:ShowCurFormation()
    self:ShowKeZhi()
end

function PetFormationUI:ChangeFightPos(oldPos, newPos)
    self:InitFightUnitData()
    self:ShowCurFormation()
end

--[[
显示出战英雄Icon显示
]]
function PetFormationUI:ShowPetFightUnit(fightPos, petId)
    local headPanel = self.m_pPosHeadList[fightPos]
    headPanel:setVisible(false)
    if fightPos == 0 or petId == 0 then
        return
    end
    local petData = LRoleDataMgr.Pet:GetPetById(petId)
    if petData == nil then
        return
    end
    headPanel:setVisible(true)
    local colorImg = headPanel:getChildByName("Color")
    local iconImg = headPanel:getChildByName("Icon")
    local lvLabel = headPanel:getChildByName("Value")
    Utils:ShowPetHeadImg(iconImg,petData.baseData.pic,colorImg,petData.baseData.quality, PetkaPaiManager:IsShiny(petData.baseData))
    lvLabel:setString(petData.level)
end

--[[
敌方出战英雄Icon显示
]]
function PetFormationUI:ShowEnemyFightUnit(fightPos,monsterId)
    local headPanel = self.m_pPosEHeadList[fightPos]
    headPanel:setVisible(false)
    --print("PetFormationUI:ShowEnemyFightUnit",fightPos,monsterId)
    if fightPos == 0 or monsterId == 0 then
        return
    end
    local cfg = nil--LDataConstMgr:GetMonsterData(monsterId)
    --print("cfg",cfg)
    if self.m_isRole == true then
		cfg = JsonConfig.m_heroCfg.getDefByID(monsterId)
		local petData = LRoleDataMgr:getOtherRolePetDataById(monsterId)
		cfg.level = petData.level
        if cfg == nil then
			return
		end
	else
		cfg = LDataConstMgr:GetMonsterData(monsterId)
    end
    headPanel:setVisible(true)
    local colorImg = headPanel:getChildByName("Color")
    local iconImg = headPanel:getChildByName("Icon")
    local lvLabel = headPanel:getChildByName("Value")
    Utils:ShowPetHeadImg(iconImg,cfg.pic,colorImg,cfg.quality, false)
    lvLabel:setString(cfg.level)
  
    lvLabel:setVisible(not self.m_pHideLevel)
end

function PetFormationUI:ShowEnemyFormation()
    --print("ShowEnemyFormation",self.m_enemyZhenfaId)
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosEHeadList[i]:setVisible(false)
        self.m_pPosENumList[i]:setVisible(false)
    end
    if self.m_enemyZhenfaId == 0 then
        return
    end
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local ind = self:GetCurFormationPos(i,self.m_enemyZhenfaId)
        --print("ShowEnemyFormation",i,ind)
        if ind > 0 then
            self.m_pPosENumList[i]:setVisible(true)
            local numLabel = self.m_pPosENumList[i]:getChildByName("Value")
            numLabel:setString(ind)
            self.m_pPosEBtnList[i]:setOpacity(255)
        else
            self.m_pPosEBtnList[i]:setOpacity(102)--40%透明度
        end
    end
    --dump(self.m_eFightArr,"self.m_eFightArr")
    for i=1,#self.m_eFightArr do
        local value = self.m_eFightArr[i]
        self:ShowEnemyFightUnit(value[2],value[1])
    end
    local finfo = LDataConstMgr:GetFormationDataById(self.m_enemyZhenfaId)
    if finfo == nil then
        return
    end
    local pic = AppDef.Formation.IconRes .. self.m_enemyZhenfaId.. ".png"
    Utils:SafeLoadTexture(self.m_enemyZIconImg,pic,ccui.TextureResType.localType)
    local str = finfo.name..GUITips.RSI_XUEZHAN_TIP9..": "
    for i = 1, #finfo.restraintList do
        local kezhiData = LDataConstMgr:GetFormationDataById(finfo.restraintList[i])
        str = str .. kezhiData.name .. "  "
    end
    self.m_enemyDescLabel:setString(str)
end

--[[
使用阵容
]]
function PetFormationUI:ShowCurFormation()

    -- dump(self.m_zhenFaDatas, "ShowCurFormation ==>")

    local data = self.m_zhenFaDatas[self.m_curInd + 1]
    --print("ShowCurFormation == 22222222222 >", self.m_curInd)
    if data == nil then
        return
    end
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    if finfo == nil then
        return
    end

    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local ind = self:GetCurFormationPos(i)
        if ind > 0 then
            self.m_pPosNumList[i]:setVisible(true)
            local numLabel = self.m_pPosNumList[i]:getChildByName("Value")
            numLabel:setString(ind)
            self.m_pPosBtnList[i]:setOpacity(255)
            -- if finfo.posOpenLvList[ind] <= LRoleDataMgr.MyHeroInfo.level then
            --     self.m_pPosNumList[i]:setVisible(false)
            -- end
        else
            self.m_pPosBtnList[i]:setOpacity(102)--40%透明度
            self.m_pPosNumList[i]:setVisible(false)
        end
        self.m_pPosHeadList[i]:setVisible(false)
    end

    --dump(self.m_fightArr, "ShowCurFormation == 22222222222222222>")

    for i = 1,#self.m_fightArr  do
        local value = self.m_fightArr[i]
        self:ShowPetFightUnit(value[2],value[1])
    end
    local pic = AppDef.Formation.IconRes .. data.id.. ".png"
    Utils:SafeLoadTexture(self.m_myZIconImg,pic,ccui.TextureResType.localType)
    local str = finfo.name..GUITips.RSI_XUEZHAN_TIP9..": "
    for i = 1, #finfo.restraintList do
        local kezhiData = LDataConstMgr:GetFormationDataById(finfo.restraintList[i])
        str = str .. kezhiData.name .. "  "
    end
    self.m_myDescLabel:setString(str)
end

function PetFormationUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/buzhenLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function PetFormationUI:onExit()
    self.m_pPosBtnList = nil
    self.m_pPosPanelList = nil
    self.m_pModelNodeWorldPosList = nil
    self.m_pPosHeadList = nil
    self.m_pPosList = nil
    self.m_pPosNumList = nil
    self.m_pPosEBtnList = nil
    self.m_pPosEHeadList = nil
    self.m_pPosENumList = nil

    self.m_curInd = nil--当前选中的阵型
    self.m_curMoveInd = nil--当前选中需要切换位置的模型下表
    self.m_pTouchBeganPos = nil
    self.m_fightArr = nil
    self.m_eFightArr = nil
    self.m_type = nil
    self.m_enemyZhenfaId = nil
    self.m_enemyInfos = nil
    self.m_callback = nil
    self:Destory()
end

function PetFormationUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.PetFormationUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function PetFormationUI:onCloseBtnClicked()
    self:CloseUI()
    Utils:SendMsg(LUIFuBenMapEvent.FormationUIClosed);
end

--[[
初始化成员变量
]]
function PetFormationUI:InitMemberVariable(userData)
    self.m_pLayout = nil--阵型列表
    self.m_pCell = nil--阵型子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_pTableView = nil--阵型tableView

    self.m_pPosBtnList = {}
    self.m_pPosPanelList = {}
    self.m_pModelNodeWorldPosList = {}
    self.m_pPosHeadList = {}
    self.m_pPosList = {}
    self.m_pPosNumList = {}

    self.m_pPosEBtnList = {}
    self.m_pPosEHeadList = {}
    self.m_pPosENumList = {}

    self.m_curInd = 0--当前选中的阵型
    self.m_type = userData["type"] or 0
    self.m_enemyZhenfaId = userData["enemyZhenfaId"] or 0
    self.m_enemyInfos = userData["enemyInfos"] or {}
    self.m_callback = userData["callback"]
	self.m_isRole = userData["isrole"] or false

    -- local myFData = LRoleDataMgr.myFormation
    -- local flist = LDataConstMgr:GetFormationDataList()
    -- for i = 1, #flist do
    --     if flist[i].id == myFData.useId then
    --         self.m_curInd = i - 1
    --         break
    --     end
    -- end

    
    self.m_curMoveInd = 0--当前选中需要切换位置的Icon下标
    self.m_pTouchBeganPos = cc.p(0,0)
    self.m_pHideLevel=userData["hideLevel"] or false --是否隐藏等级
   
end

--[[
初始化出站单位数据
]]
function PetFormationUI:InitFightUnitData()
    self.m_fightArr = {}
    self.m_eFightArr = {}
    for i = 1, #LRoleDataMgr.Pet.petlist do
        local value = LRoleDataMgr.Pet.petlist[i]
        if value.fightPos > 0 then
            local data = self.m_zhenFaDatas[self.m_curInd + 1]
            if data ~= nil then
                local ind = self:GetIdxByPos(data.id,value.fightPos)
                if ind > 0 then
                    table.insert(self.m_fightArr, {value.id,ind})
                end
            end
        end
    end
    --敌方
    if self.m_enemyZhenfaId == 0 then
        --self.m_fightBtn:setVisible(false)
        self.m_enemyZIconImg:setVisible(false)
        self.m_enemyDescLabel:setString("")
        return
    end
    if self.m_type == AppDef.FormationType.XueZhan or self.m_type == 0 then
        for i = 1,AppDef.Formation.MaxFightNum do
            if self.m_enemyInfos[i] ~= nil and self.m_enemyInfos[i] > 0 then
                local ind = self:GetIdxByPos(self.m_enemyZhenfaId,i)
                if ind > 0 then
                    table.insert(self.m_eFightArr, {self.m_enemyInfos[i],ind})
                end
            end
        end
    end
end

function PetFormationUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("Panel_buzhen")
    panel:setTouchEnabled(false)
    panel:getChildByName("Panel_bg"):getChildByName("SubBtnList"):setTouchEnabled(false)
    local leftPanel = panel:getChildByName("Panel")
    leftPanel:setTouchEnabled(false)
    local listPanel = panel:getChildByName("List")
    self.m_pLayout = listPanel:getChildByName("Panel")--阵型列表
    self.m_pCell = listPanel:getChildByName("Item")--阵型子元素
    self.m_pCell:getChildByName("btn_Item"):setVisible(false)
    self.m_pCell:setTouchEnabled(false)
    self.m_pCell:setAnchorPoint(cc.p(0,0))
    self.m_cellSize = self.m_pCell:getContentSize()--子元素尺寸
    self.m_pCell:retain()
    self.m_pCell:removeFromParent()

    local effect = leftPanel:getChildByName("effect_zhandoujiesuan_6")
	local effcet = self:SetEffect()
    effcet:setName("effcet") 
    effect:addChild(effcet)

    local formationPanel = leftPanel:getChildByName("my")--阵容
    formationPanel:setTouchEnabled(false)
    local posPanel = formationPanel:getChildByName("Formation")
    posPanel:setTouchEnabled(false)
    self.m_myZIconImg = formationPanel:getChildByName("Icon")
    self.m_myDescLabel = formationPanel:getChildByName("restraint")
    self.m_myTipsPanel = formationPanel:getChildByName("tips")
    self.m_myTipsLabel = self.m_myTipsPanel:getChildByName("Text")
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosBtnList[i] = posPanel:getChildByName("Position" .. i)
        self.m_pPosPanelList[i] = self.m_pPosBtnList[i]:getChildByName("Panel")
        self.m_pPosNumList[i] = self.m_pPosBtnList[i]:getChildByName("bg_Num")
        self.m_pPosHeadList[i] = self.m_pPosBtnList[i]:getChildByName("bg_Head")
        self.m_pPosList[i] = cc.p(self.m_pPosBtnList[i]:getPositionX(),self.m_pPosBtnList[i]:getPositionY()+self.m_pPosHeadList[i]:getPositionY()*2/3)
        self.m_pPosHeadList[i]:retain()
        self.m_pPosHeadList[i]:removeFromParent()
        posPanel:addChild(self.m_pPosHeadList[i])
        self.m_pPosHeadList[i]:setPosition(self.m_pPosList[i])
        --print("self.m_pPosList[i]",i,self.m_pPosHeadList[i]:getPositionX(),self.m_pPosHeadList[i]:getPositionY())

        
        self.m_pModelNodeWorldPosList[i] = posPanel:convertToWorldSpace(self.m_pPosList[i])
    end

    local enemyPanel = leftPanel:getChildByName("enemy")--敌方阵容
    enemyPanel:setTouchEnabled(false)
    local posEPanel = enemyPanel:getChildByName("Formation")
    posEPanel:setTouchEnabled(false)
    self.m_enemyZIconImg = enemyPanel:getChildByName("Icon")
    self.m_enemyDescLabel = enemyPanel:getChildByName("restraint")
    self.m_enemyTipsPanel = enemyPanel:getChildByName("tips")
    self.m_enemyTipsLabel = self.m_enemyTipsPanel:getChildByName("Text")
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosEBtnList[i] = posEPanel:getChildByName("Position" .. i)
        local posPanel = self.m_pPosEBtnList[i]:getChildByName("Panel")
        posPanel:setTouchEnabled(false)
        self.m_pPosEHeadList[i] = self.m_pPosEBtnList[i]:getChildByName("bg_Head")
        self.m_pPosENumList[i] = self.m_pPosEBtnList[i]:getChildByName("bg_Num")
    end
    
    self.m_fightBtn = panel:getChildByName("btn_buzhen")--战斗按钮
    self.m_conditionPanel = self.m_fightBtn:getChildByName("Text2")
    self.m_conditionLabel = self.m_conditionPanel:getChildByName("condition")--通关条件
    self:InitTableView()
    self:RefreshIconItem()
    self:InitFightUnitData()
    listPanel:getChildByName("Image"):setLocalZOrder(9)
end

function PetFormationUI:SetEffect()
    local bgAnim = "res2/animation/effect_zhandoujiesuan_6"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end

function PetFormationUI:RefreshIconItem()
    local list = LDataConstMgr:GetFormationDataList()
    local myFData = LRoleDataMgr.myFormation
    self.m_zhenFaDatas = {}
    for i=1,#list do
        local lv = myFData:GetMyZhenfaLvById(list[i].id)
        if lv > 0 then
            local value = {}
            value.useSign = false
            value.lv = lv
            value.id = list[i].id
            value.name = list[i].name
            if myFData.useId == value.id then
                value.useSign = true
            end
            table.insert(self.m_zhenFaDatas,value)
        end
    end

    for i=1, #self.m_zhenFaDatas do
        if self.m_zhenFaDatas[i].useSign then
            self.m_curInd = i-1
            break
        end
    end

    print("RefreshIconItem === self.m_curInd >", self.m_curInd)

    self.m_curGridNum = #self.m_zhenFaDatas

    self.m_pTableView:reloadData()
end

function PetFormationUI:InitTableView()
    local tableView = cc.TableView:create(self.m_pLayout:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pLayout:getAnchorPoint())
    tableView:setPosition(self.m_pLayout:getPosition())
    tableView:setDelegate() 
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
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
        return self.m_curGridNum
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

function PetFormationUI:PetCellTouched(cell)
    local ind = cell:getIdx()
    print("PetCellTouched",ind)
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
        end
    end
    self.m_curInd = ind
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)
    --self:ShowCurFormation()

    self:ChangeZhenfa()
end

function PetFormationUI:FormationCellAtIndex(sender, idx)
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

function PetFormationUI:ShowFormationCellInfo(cell, ind)
    local fdata = self.m_zhenFaDatas[ind + 1]
    if fdata == nil then
        return
    end
    local tmpPanel = cell:getChildByName("bg_Formation")
    local lvLabel = tmpPanel:getChildByName("Level")
  


    local nameLabel = tmpPanel:getChildByName("Name")
    nameLabel:setString(fdata.name)

    local useFlagImg = cell:getChildByName("Tag")
    useFlagImg:setVisible(fdata.useSign)

    lvLabel:setString("")
    if fdata.lv > 0 then
        lvLabel:setString("Lv." .. fdata.lv)
    end

    local iconImg = tmpPanel:getChildByName("Icon")
    local iconRes = AppDef.Formation.IconRes .. fdata.id .. ".png"
    iconImg:loadTexture(iconRes,ccui.TextureResType.localType)
end

function PetFormationUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_BuZhen)
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,PetFormationUI.onCloseBtnClicked))

    local function ChangePosBtnTouched(pTouch, pEvent)
        --print("ChangePosBtnTouched",pEvent)
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

    self.m_fightBtn:addClickEventListener(function (sender)
        if self.m_callback ~= nil then
            self.m_callback()
        end
        Utils:DeleteUI("FuBenMap.StageInfoUI")
        self:CloseUI()
    end)

    if self.m_callback == nil then
        self.m_fightBtn:setVisible(false)
    end
end

function PetFormationUI:ChangeZhenfa()
    local data = self.m_zhenFaDatas[self.m_curInd + 1]
    if data == nil then
        return
    end
    LuaNetSendMsg:QueryFormationUse(data.id)
end

function PetFormationUI:PosBtnTouchMoved(movePos)
    if self.m_curMoveInd <= 0 then
        return
    end
    local offx = movePos.x - self.m_pTouchBeganPos.x
    local offy = movePos.y - self.m_pTouchBeganPos.y
    self.m_pTouchBeganPos = movePos
    local modelPos = cc.p(self.m_pPosHeadList[self.m_curMoveInd]:getPosition())
    self.m_pPosHeadList[self.m_curMoveInd]:setPosition(cc.p(modelPos.x + offx, modelPos.y + offy))
    --print("PosBtnTouchMoved",offx,offy,modelPos.x + offx,modelPos.y + offy)
end

--[[
根据9宫格下标获取出站位置
]]
function PetFormationUI:GetCurFormationPos(ind,id)
    if id == nil then
        local data = self.m_zhenFaDatas[self.m_curInd + 1]
        if data == nil then
            return 0
        end
        id = data.id
    end
    local finfo = LDataConstMgr:GetFormationDataById(id)
    if finfo ~= nil then
        for i = 1, AppDef.Formation.MaxFightNum do
            if finfo.posList[i] == ind then
                return i
            end
        end
    end
    return 0
end

--[[
根据站位取出9宫下标
]]
function PetFormationUI:GetIdxByPos(id,pos)
    local finfo = LDataConstMgr:GetFormationDataById(id)
    if finfo == nil then
        return 0
    end
    return finfo.posList[pos] or 0
end

function PetFormationUI:PosBtnTouchBegan(posInd)
    --print("PosBtnTouchBegan",posInd)
    local data = self.m_zhenFaDatas[self.m_curInd + 1]
    if data == nil then
        return
    end
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    if finfo == nil then
        return
    end
    local ind = self:GetCurFormationPos(posInd)
    if ind == 0 then
        return
    end
    local sign = true
    for i=1, #self.m_fightArr do
        if self.m_fightArr[i][2] == posInd then
            sign = false
            break
        end
    end
    if sign then
        return
    end
    self.m_curMoveInd = posInd
    for k,v in pairs(self.m_pPosHeadList) do
        v:setLocalZOrder(1)
    end
    self.m_pPosHeadList[self.m_curMoveInd]:setLocalZOrder(99)
end

function PetFormationUI:PosBtnTouchEnd()
    if self.m_curMoveInd <= 0 then
        return
    end
    local modeNode = self.m_pPosBtnList[self.m_curMoveInd]
    local endPos = cc.p(self.m_pPosHeadList[self.m_curMoveInd]:getPosition())
    local endWorldPos = modeNode:getParent():convertToWorldSpace(cc.p(endPos.x,endPos.y))
    self.m_pPosHeadList[self.m_curMoveInd]:setPosition(self.m_pPosList[self.m_curMoveInd])
    local minDis = 1000000
    local minInd = 0
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local dis = cc.pDistanceSQ(endWorldPos, self.m_pModelNodeWorldPosList[i])
        if minDis > dis then
            minDis = dis
            minInd = i
        end
    end

    local oldPos = self:GetCurFormationPos(self.m_curMoveInd)
    local newPos = self:GetCurFormationPos(minInd)
    self.m_curMoveInd = 0
    --print("PetFormationUI:PosBtnTouchEnd",oldPos, newPos,minDis)
    if oldPos ~= newPos and minDis <= 1000 then
        LuaNetSendMsg:QueryFormationChangePos(oldPos, newPos)
    end
end

function PetFormationUI:ShowPassContent()
    self.m_conditionLabel:setString("")
    self.m_conditionPanel:setVisible(false)
    if self.m_type == AppDef.FormationType.XueZhan then
        local data = LActivityManager:GetXueZhanData()
        if data.m_levelId == nil or data.m_levelId == 0 then
            return
        end
        local cfg = JsonConfig.m_bloodBattle.getDefByID(data.m_levelId)
        if cfg == nil then
            return
        end
        local str = ""
        for i=1,#cfg.condition do
            local value = cfg.condition[i]
            local tmp = string.format(GUITips["RSI_XUEZHAN_TIPC"..value[1]],value[2])
            str = str..tmp..","
        end
        str = string.sub(str,1,-2)
        str = str..GUITips.RSI_XUEZHAN_TIP8
        self.m_conditionLabel:setString(str)
        self.m_conditionPanel:setVisible(true)
    end
end

function PetFormationUI:ShowKeZhi()
    --克制Or被克制
    self.m_enemyTipsPanel:setVisible(false)
    self.m_myTipsPanel:setVisible(false)
    if self.m_enemyZhenfaId == 0 or self.m_zhenFaDatas[self.m_curInd + 1] == nil then
        return
    end
    local zhenfaId = self.m_zhenFaDatas[self.m_curInd + 1].id or 0
    if zhenfaId == 0 then
        return
    end
    --敌人阵法
    local finfo = LDataConstMgr:GetFormationDataById(self.m_enemyZhenfaId)
    if finfo == nil then
        return
    end
    local  sign = false
    for i = 1, #finfo.restraintList do
        if finfo.restraintList[i] == zhenfaId then
            self.m_enemyTipsLabel:setString(GUITips.RSI_XUEZHAN_TIP9)
            self.m_myTipsLabel:setString(GUITips.RSI_XUEZHAN_TIP12)
            self.m_enemyTipsPanel:setVisible(true)
            self.m_myTipsPanel:setVisible(true)
            sign = true
            break
        end
    end
    if sign then
        return
    end
    local info = LDataConstMgr:GetFormationDataById(zhenfaId)
    for i = 1, #info.restraintList do
        if info.restraintList[i] == self.m_enemyZhenfaId then
            self.m_enemyTipsLabel:setString(GUITips.RSI_XUEZHAN_TIP12)
            self.m_myTipsLabel:setString(GUITips.RSI_XUEZHAN_TIP9)
            self.m_enemyTipsPanel:setVisible(true)
            self.m_myTipsPanel:setVisible(true)
            break
        end
    end
end

return PetFormationUI
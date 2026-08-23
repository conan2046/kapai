
local PetZhengRongUI = LUIBase:New()
PetZhengRongUI.__index = PetZhengRongUI
--local this = LTcpSocket
function PetZhengRongUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetZhengRongUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetZhengRongUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.PetDataChanged,
        LUIPetEvent.ComposionPet,
        LUIFormationEvent.PetFight,
        LUIPetEvent.PetEquipWear,
        LUIFormationEvent.ChangeShowPos,
        LUIRedDotEvent.UpdateRedDotState,
        --LUIRedDotEvent.SetRedDotState,
        LUIFaBaoEvent.FaBaoWearSuc,
        LUIFaBaoEvent.FaBaoTakeOffSuc,
        LUIFormationEvent.updateZhengRongUI,
        LUIFaBaoEvent.PetQHSuc,
        LUIFaBaoEvent.PetJLSuc,
        LUIFuBenMapEvent.getSingleNodeSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetZhengRongUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.PetDataChanged then
        self:updateUI()
    elseif msg.msgId == LUIPetEvent.ComposionPet then
        self:updateUI()
    elseif msg.msgId == LUIFormationEvent.PetFight then
        self:updateData(msg.value)
        self:updateUI()
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        if curPet ~= nil then
            local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
            self:ShowEquipList(showPos)
            self:ShowFaBaoList(showPos)
			self:UpdateRedDotUI(true)
        end
    elseif msg.msgId == LUIPetEvent.PetEquipWear then
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
        if curPet == nil or showPos ~= msg.value[1] then
            return
        end
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
        self:ShowEquipList(showPos)
		self:UpdateRedDotUI(true)
        Utils:CheckGuide(GuideDef.StepId.Guide_Equip_5,true)
    elseif msg.msgId == LUIFormationEvent.ChangeShowPos then
        -- print("=============================== 111111111111111111 >")
        --已修改
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:UpdateRedDot(msg.value)
    elseif msg.msgId==LUIRedDotEvent.SetRedDotState then
         self:UpdateRedDot(msg.value)
    elseif msg.msgId == LUIFaBaoEvent.FaBaoWearSuc then
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
        if curPet == nil or showPos ~= msg.value.m_fpos then
            return
        end
        self:ShowFaBaoList(showPos)
		self:UpdateRedDotUI(true)
    elseif msg.msgId == LUIFaBaoEvent.FaBaoTakeOffSuc then
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
        print("==================>", msg.value[1], showPos)
        if curPet == nil or showPos ~= msg.value.m_fpos then
            return
        end
        self:ShowFaBaoList(showPos)
		self:UpdateRedDotUI(true)
    elseif msg.msgId == LUIFormationEvent.updateZhengRongUI then
        --更新UI
        self:InitData()
        self:updateUI()
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        if curPet ~= nil then
            local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
            self:ShowEquipList(showPos)
            self:ShowFaBaoList(showPos)
			self:UpdateRedDotUI(true)
        end
    elseif msg.msgId == LUIFaBaoEvent.PetQHSuc then
        self:updateUIAfterQhSuc(msg.value)
    elseif msg.msgId == LUIFaBaoEvent.PetJLSuc then
        self:updateUIAfterJLSuc(msg.value)
    elseif msg.msgId == LUIFuBenMapEvent.getSingleNodeSuc then
        self:UpdateStageInfo(msg.value)
    end
end

function PetZhengRongUI:Init()

    self.ScriptPath = "KaPaiPet.PetZhenRongUI"
    self:CreateUINode("csd/shenjiangyangcheng/yingxiongListLayer.csb")
    self._bg = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongInfoLayer.csb")
    self._bg:setPosition(cc.p(0, 0))
    self._bg:setContentSize(AppDef.frameSize)
    self.m_pUILayer:addChild(self._bg)
    ccui.Helper:doLayout(self._bg)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self:RegistMsgs()
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:InitControlUI()
    self:setZhenRongRed()
    self:InitPosOpen()

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Team_Lineup)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.ZhenRong)

    --默认数据
    local curPet = self.m_pPetList[self.m_curPetInd + 1]
    self:showPetDetailInfo(curPet)
    self:ShowAddHeroUI(curPet.id <= 0)

    if curPet ~= nil then
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
        self:ShowEquipList(showPos)
        self:ShowFaBaoList(showPos)
		self:UpdateRedDotUI(true)
    end
    self:RegisterGuide()
  
end

function PetZhengRongUI:InitData()
    -- LRoleDataMgr.Pet:SortPetList()
    -- LRoleDataMgr:UpdatePetUpItems()
    -- self.m_pPetList = {}
    -- for i=1, #LRoleDataMgr.Pet.petlist do
    --     local petData = LRoleDataMgr.Pet.petlist[i]
    --     print("petData.fightPos ===>", petData.fightPos)
    --     if petData.fightPos > 0 then
    --         -- table.insert(self.m_pPetList, petData)
    --         self.m_pPetList[petData.fightPos] = petData
    --     else
    --         --减少循环次数(排过序的)
    --         break
    --     end
    -- end


    self.m_pPetList = {}
    for i=1, 5 do
        local pid = LRoleDataMgr.Pet.ShowPosList[i]
        print("InitData ===> ShowPosList pid", pid, i)
        if pid > 0 then
            local data = LRoleDataMgr.Pet:GetPetById(pid)
            table.insert(self.m_pPetList, data)
        else
            local data = LPetData:New(0)
            -- dump(data, 'InitData ========================>')
            table.insert(self.m_pPetList, data)
        end
    
    end

    -- dump(self.m_pPetList, "PetZhengRongUI:InitData 111111 ===>")

    --当前选中宠物下标
    if self.m_curPetInd == nil then
        self.m_curPetInd = 0
    end
end


function PetZhengRongUI:updateData( showPos )
    -- body
    -- local showPos = LRoleDataMgr.Pet:GetPetPos()
    -- print("PetZhengRongUI:updateData ===>", showPos)
    if showPos > 0 then
        local petData = LRoleDataMgr.Pet:GetPetByFightPos(showPos)
        self.m_pPetList[showPos] = petData
    end
end

function PetZhengRongUI:InitControlUI( ... )
    -- body
    local EquipUI = self._bg:getChildByName("EquipUI")
    local Bg = EquipUI:getChildByName("Bg")

    ---------------------------------------------------------
    local leftUI = Bg:getChildByName("bg")
    self._bgLeft = leftUI
    local leftBottom = leftUI:getChildByName("Image_bg")
    self._leftBottom = leftBottom
    local yancheng = leftBottom:getChildByName("Btn_3_1_0")
    self._yangChengBtn = yancheng
    self._YCPrompt = self._yangChengBtn:getChildByName("Prompt")
    yancheng:addClickEventListener(handler(self,PetZhengRongUI.YangChengCallBack))

    self._bg_Quality = leftUI:getChildByName("bg_Quality")
    self._StarList = leftBottom:getChildByName("StarList")

    local duanzao = leftBottom:getChildByName("Button1")
    duanzao:addClickEventListener(function( sender )
        --    AppDef.UIType.FirstClassLayer, {1, 0, self.m_curPetInd + 1})
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
		local equips = Utils:GetEquipsByfPos(showPos)
		local fabaos = Utils:GetFaBaoByfPos(showPos)
		local isOpen = 0
		
		if table.length(equips) < 4 then
			isOpen = isOpen + 1
		end
		if fabaos == nil or table.length(fabaos) < 2 then
			isOpen = isOpen + 1
		end
		if isOpen == 2 then
			Utils:ShowScrollTips(GUITips.RSI_QiangHuaDaShi_Open)
			return
		end
		local qhInd = 1
		if table.length(equips) >= 4 then
			qhInd = 1 --装备强化大师
		elseif table.length(fabaos) >=2 then
			qhInd = 5 --法宝强化大师
		end

        --Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, curPet.id)

		LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.QiangHuaDaShiUI", AppDef.UIType.PopFirstClassLayer, {fightPos = showPos, ind = qhInd})
		LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    end)
    local change = leftBottom:getChildByName("Button2")
    self._changePetBtn = change
    change:addClickEventListener(function( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_CHANGE_PET)
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        -- print("PetZhengRongUI:InitControlUI === curPet.id>", self.m_curPetInd + 1)
        local curId = 0
        if curPet then
            curId = curPet.id
        end

        Utils:SendMsg(LUIKaPaiPetEvent.ChangePetInitData, {pid=curId, pos=self.m_curPetInd + 1})
    end)
    local image = leftUI:getChildByName("Image")
    self._centerImage = image
    self._petNode = image:getChildByName("BaseImage"):getChildByName("Node")

    local zhanli = leftBottom:getChildByName("bg_zhanli")
    self._zhanliValue = zhanli:getChildByName("Value")

    ----------------------------------------------------------------
    self._addnew = Bg:getChildByName("Panel_new")
    self._addnew:setVisible(false)
    self._addnewBtn = self._addnew:getChildByName("addnew")
    self._addnewBtn:addClickEventListener(handler(self, PetZhengRongUI.addHeroToFight))
    ----------------------------------------------------------------
    self._equipNodes = {}
    self._equipIcons = {}
    self._equipNameLabels = {}
	self._equipPrompts = {}
    --装备
    for i=1, AppDef.Pet.MaxEquipPosNum do
         local btn = leftUI:getChildByName("EquipIcon"..i)
         self._equipNodes[i] = btn:getChildByName("IconBase")
         self._equipNameLabels[i] = btn:getChildByName("name")
		 self._equipPrompts[i] = btn:getChildByName("Prompt")
         btn:addClickEventListener(handler(self,PetZhengRongUI.PosCallBack))
    end
     local Btn_xiangxi =Bg:findChildByName("bg/Btn_xiangxi")
     self._Btn_xiangxi = Btn_xiangxi
     Btn_xiangxi:addClickEventListener(function ()
        Utils:InitUI("KaPaiPet.KaPaiDetailAttrUI", AppDef.UIType.PopWindow,self.m_pPetList[self.m_curPetInd + 1].id)
         -- body
     end)

    ---------------------------------------------------------
    --装备属性
    local shuxing = Bg:getChildByName("Equip")
    self._shuxing = shuxing
    self._atk = shuxing:getChildByName("Text_1")
    self._hp = shuxing:getChildByName("Text_2")
    self._wuFang = shuxing:getChildByName("Text_3")
    self._faFang = shuxing:getChildByName("Text_4")
    self._petType = shuxing:getChildByName("Text_0")
    --------------------------------------------------------
    local btnSkill = Bg:getChildByName("Btn_Skill")
    self._btnSkill = btnSkill
    self._Icon1 = btnSkill:getChildByName("Icon")

    self._itemCell = Bg:getChildByName("ItemList")

    local Panel_skill = btnSkill:getChildByName("Panel_skill")
    self._skillName = Panel_skill:getChildByName("Text")

    self._ListView = Panel_skill:getChildByName("ListView")
    self._txtCell = self._ListView:getChildByName("Text_miaoshu")
    self._txtCell = Utils:CreateColorText3(self._txtCell, true)
    ------------------------------------------------------------------
    --左边神将列表
    self:InitUICtr()

end

function PetZhengRongUI:OnEquipPosClick(part)
    local ind =  self.m_curPetInd+1
    if #self.m_pPetList == 0 or ind > #self.m_pPetList or part < 1 or  part > 4 then
        return
    end
    --是否有装备
    local curPet = self.m_pPetList[ind]
    local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
    if curPet == nil or showPos == 0 then
        return
    end
    local equips = Utils:GetEquipsByfPos(showPos)
    if equips == nil or equips[part] == nil or equips[part] == 0 then
        if LRoleDataMgr:CheckPetEquipUnused(part) then
            --更换界面
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "PetEquip.PetEquipChangeUI",AppDef.UIType.PopWindow,{part, showPos})
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            self:ShowItemSource(part)
        end
    else
        local data = 
        {
            uid = equips[part],
            isShowBtn = true
        }
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "PetEquip.EquipInfoUI",AppDef.UIType.PopWindow,data)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function PetZhengRongUI:ShowEquipList(fightPos)
    local equips = Utils:GetEquipsByfPos(fightPos)
    if equips == nil then
        equips = {}
    end
    for i=1,4 do
        local uid = equips[i] or 0
        local sign = true
        if uid ~= nil and uid > 0 then
            local info = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
            if info ~= nil then
                local jxLv = info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
                local qhLv = info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
                local jlLv = info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
                local szLv = info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
                self._equipIcons[i] = Utils:GetEquipCellValue(self._equipNodes[i],self._equipIcons[i],info.m_id,uid,qhLv,jlLv,szLv,jxLv,false, true)
				self._equipIcons[i].userObject = info.m_uid
                self._equipNameLabels[i]:setString(info.m_name)
                sign = false
            end
        end
        if sign then
            self._equipIcons[i] = Utils:GetEquipCellValue(self._equipNodes[i],self._equipIcons[i],0,0,0,0,0,0,false, true)
			self._equipIcons[i].userObject = 0
            self._equipNameLabels[i]:setString("")
			self._equipPrompts[i]:setVisible(false)
        end
		self:UpdateEquipPosRedDot(i, uid)
    end
end


function PetZhengRongUI:ShowFaBaoList(fightPos)
    local faBaos = Utils:GetFaBaoByfPos(fightPos)
    if faBaos == nil then
        faBaos = {}
    end
    for i=5, AppDef.Pet.MaxEquipPosNum do
        local uid = faBaos[i] or 0
        local sign = true
        if uid ~= nil and uid > 0 then
            local info = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid]
            if info ~= nil then

                local qhLv = info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
                local jlLv = info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0

                self._equipIcons[i] = Utils:GetFaBaoCellValue(self._equipNodes[i],self._equipIcons[i],info.m_id, info.m_uid, false, 0, qhLv,jlLv,false, true)
                self._equipIcons[i].userObject = info.m_uid
                self._equipNameLabels[i]:setString(info.baseData.name)
                sign = false

            end
        end
        if sign then
            self._equipIcons[i] = nil --Utils:GetFaBaoCellValue(self._equipNodes[i],self._equipIcons[i],0, 0, false, 0, 0,0,false, true)
            self._equipNodes[i]:removeAllChildren()
            self._equipNameLabels[i]:setString("")
			self._equipPrompts[i]:setVisible(false)
        end
		self:UpdateFaBaoPosRedDot(i,fightPos, uid)
    end
end

function PetZhengRongUI:updateUIAfterQhSuc( data )
    -- body
    local info = LRoleDataMgr.Pet:GetFaBaoById(data.uid)
    local jlLelvel = info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
    for i=1, AppDef.Pet.MaxEquipPosNum do
		local uid = 0
		if self._equipIcons[i] ~= nil then
			if data.uid == self._equipIcons[i].userObject then
				self._equipIcons[i] = Utils:GetFaBaoCellValue(self._equipNodes[i],self._equipIcons[i],info.m_id, info.m_uid, false, 0, data.curQhLv, jlLelvel, false, true)
			end
			uid = self._equipIcons[i].userObject
		end
		if i <= 4 then
			self:UpdateEquipPosRedDot(i, uid)
		elseif i > 4 then
			self:UpdateFaBaoPosRedDot(i,info.m_fpos, uid)
		end
    end
end

function PetZhengRongUI:updateUIAfterJLSuc( data )
    -- body
    local info = LRoleDataMgr.Pet:GetFaBaoById(data.uid)
    local curQhLv = info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
    for i=1, AppDef.Pet.MaxEquipPosNum do
		local uid = 0
		if self._equipIcons[i] ~= nil then
			if data.uid == self._equipIcons[i].userObject then
				self._equipIcons[i] = Utils:GetFaBaoCellValue(self._equipNodes[i],self._equipIcons[i],info.m_id, info.m_uid, false, 0, curQhLv, data.toLevel, false, true)
			end
			uid = self._equipIcons[i].userObject
		end
		if i <= 4 then
			self:UpdateEquipPosRedDot(i, uid)
		elseif i > 4 then
			self:UpdateFaBaoPosRedDot(i,info.m_fpos, uid)
		end
    end
end

function PetZhengRongUI:OnFaBaoPosClick(part)
    local ind = self.m_curPetInd + 1
    --是否有装备
    print("OnFaBaoPosClick ==>", ind)
    local curPet = self.m_pPetList[ind]
    local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
    if curPet == nil or showPos == 0 then
        return
    end
    local faBaos = Utils:GetFaBaoByfPos(showPos)
    print("OnFaBaoPosClick ===>", part, showPos)
    if faBaos == nil or faBaos[part] == nil or faBaos[part] == 0 then
        if LRoleDataMgr:CheckFaBaoUnused() then
            --更换界面
            print("OnFaBaoPosClick ===>", part, showPos)
            Utils:InitUI("FaBao.PetFaBaoChangeUI", AppDef.UIType.PopWindow, {part, showPos})
        else
            self:ShowItemSource(part)
        end
    else
        --显示法宝信息
        local data = 
        {   
            id = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[faBaos[part]].m_id,
            uid = faBaos[part],
            isShowBtn = true,
        }
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FaBao.FaBaoInfo", AppDef.UIType.PopWindow, data)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function PetZhengRongUI:showPetModel( pid )
    -- body
    if self._pMyRoleModel ~= nil then
        self._pMyRoleModel:removeFromParent()
        self._pMyRoleModel = nil
    end
    print("PetZhengRongUI:showPetModel ===>", pid)
    self._pMyRoleModel = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, pid,nil, true)
    if self._pMyRoleModel ~= nil then
        self._petNode:addChild(self._pMyRoleModel)
        self._pMyRoleModel:PlayStand(1)
    end
    
end

function PetZhengRongUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("shenjiangListUI"):getChildByName("List")
    self.m_pListPanel = panel:getChildByName("Panel")
    self.m_pPetCell = panel:getChildByName("Item")
    self.m_pStarImg = panel:getChildByName("Star")

    self.m_pCellSize = self.m_pPetCell:getContentSize()

    
    self.m_pFormationBtn = panel:getChildByName("btn_buzhen")
    self.m_pFormationBtn:addClickEventListener(handler(self,PetZhengRongUI.FormationClicked))
    self:MarkIntaractCObj(self.m_pFormationBtn)
    self.m_pFormationBtnRedPImg = self.m_pFormationBtn:getChildByName("Prompt")
    self.m_pFormationBtnRedPImg:setVisible(false)


    self.m_pBZBtnLabel = self.m_pFormationBtn:getChildByName("Text")

    --self:CheckTujianRedPoint()
    -- self:CheckFormationRedPoint()
    self:InitTableView()
end

function PetZhengRongUI:FormationClicked(sender)
    -- if self.m_fIsOpen == nil or not self.m_fIsOpen then
    --     self.m_fIsOpen = true
    --     self.m_preUIInd =  self.m_curUIInd
    --     if #LRoleDataMgr.Pet.petlist == 0 then
    --         Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
    --         return
    --     end
    --     Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
    --     self.m_pBZBtnLabel:setString(GUITips.RSI_PET_DIS_TIPS4)
    -- else
    --     self.m_fIsOpen = false
    --     self.m_pBZBtnLabel:setString(GUITips.RSI_PET_DIS_TIPS3)
    -- end

    self.m_preUIInd =  self.m_curUIInd
    if #LRoleDataMgr.Pet.petlist == 0 then
        Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
        return
    end
    Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)

end

function PetZhengRongUI:InitTableView()
    local tableView
    if self.m_pListPanel == nil then
        --有可能是复用的UI，所以这个时候就是空的
        return
    else
        tableView = self.m_pListPanel:getChildByName("PetTableView")
        if tableView == nil then
            tableView = cc.TableView:create(self.m_pListPanel:getContentSize())
            tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
            tableView:setAnchorPoint(cc.p(0, 0))
            tableView:setDelegate()
            tableView:setSwallowsTouches(false)
            tableView:setBounceable(false)
            tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
            tableView:setName("PetTableView")
            self.m_pListPanel:addChild(tableView)
        else
            ScriptHandlerMgr:getInstance():removeObjectAllHandlers(tableView)
        end
    end
    

    local function tableCellTouched(sender,cell)
        -- print("tableCellTouched ======================= 1111 >")
        self:PetCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pCellSize.width
        local height = self.m_pCellSize.height - 8
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:PetCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        -- local cnt = #self.m_pPetList
        local cnt = 5
        return cnt
    end
    
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTableView = tableView
    self:MarkIntaractCObj(self.m_pTableView)
end

function PetZhengRongUI:PetCellSelected(cellChild, ind)
    print("PetZhengRongUI:PetCellSelected 222222222222222222222 ====================>")
    if self.m_curPetInd == ind then
        return
    end

    local oldCell = self.m_pTableView:cellAtIndex(self.m_curPetInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nil then
            local selectImg = oldCellChild:getChildByName("Choose")
            selectImg:setVisible(false)
            --oldCellChild:setSelected(false)
        end
    end
    self.m_curPetInd = ind
    --cellChild:setSelected(true)

    local petLength = #self.m_pPetList
    if Utils:CheckModelNotOpened(AppDef.PetFightPos[ind + 1], true) then
        local level = Utils:getFucnOpenLevel(AppDef.PetFightPos[ind + 1])
        Utils:ShowScrollTips(string.format(GUITips.RSI_ZQX_CHOUKA_TIPS7, level))
        return
    end

    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)
    
    local curPet = self.m_pPetList[self.m_curPetInd + 1]
    if curPet.id <= 0 then
        self:ShowAddHeroUI(true)
        Utils:CheckGuide(GuideDef.StepId.Guide_Pet_8, true)
    else
        self:ShowAddHeroUI(false)
        LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.SelectedPet, curPet)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self:ShowPetSoundEffect()
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        self:showPetDetailInfo(curPet)
        local showPos = LRoleDataMgr.Pet:GetPetPos(curPet.id)
        self:ShowEquipList(showPos)
        self:ShowFaBaoList(showPos)
		self:UpdateRedDotUI(true)
    end
end

function PetZhengRongUI:ShowAddHeroUI( isShow )
    -- body
    self._addnew:setVisible(isShow)
    self._shuxing:setVisible(not isShow)
    self._btnSkill:setVisible(not isShow)
    self._Btn_xiangxi:setVisible(not isShow)
    self._bgLeft:setVisible(not isShow)
    for i=1, #self._equipNodes do
        local node = self._equipNodes[i]
        node:getParent():setVisible(not isShow)
    end

    self._centerImage:setVisible(not isShow)
    self._leftBottom:setVisible(not isShow) 
    self._bg_Quality:setVisible(not isShow)
end

function PetZhengRongUI:ShowPetSoundEffect()
    if #self.m_pPetList == 0 or self.m_curPetInd >= #self.m_pPetList then
        return
    end
    local curPet = self.m_pPetList[self.m_curPetInd + 1]
    local playFile = PetkaPaiManager:GetCV(curPet)
    if string.len(playFile) > 0 then
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, playFile)
        self:SendMsg(LGameMsg.m_audioMsg)

        -- local soundPath = curPet.baseData.cv
        -- LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, soundPath)
        -- self:SendMsg(LGameMsg.m_audioMsg)
    end

end

function PetZhengRongUI:PetCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    self:PetCellSelected(cellChild, ind)
    --self:SelServerArea(ind)
end

function PetZhengRongUI:PetCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pPetCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)

    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowPetCellInfo(cellChild,idx)

    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curPetInd then 
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end
    return cell
end

function PetZhengRongUI:ShowPetCellInfo(cell, ind)
    local headPanel = cell:getChildByName("bg_Head")
    local headImg = headPanel:getChildByName("Icon")

    local colorImg = headPanel:getChildByName("Color")
    colorImg:setVisible(false)
    local attrImg = headPanel:getChildByName("Attribute")--属性
    local lvLabel = headPanel:getChildByName("Value")
    local nameLabel = headPanel:getChildByName("Name")
    nameLabel:setVisible(false)
    local starListView = headPanel:getChildByName("Stars")
    --starListView:removeAllItems()
    local bg_add = cell:getChildByName("bg_add")
    bg_add:setVisible(true)
    -- bg_add:setTouchEnabled(true)
    -- bg_add:setSwallowTouches(false)
    -- bg_add:setTag(ind + 1)
    -- bg_add:addClickEventListener(handler(self, PetZhengRongUI.addHeroToFight))

    local bg_Lock = cell:getChildByName("bg_Lock")
    local isPosLock = Utils:CheckModelNotOpened(AppDef.PetFightPos[ind + 1], true)
    bg_Lock:setVisible(isPosLock)

    local locakLevel = bg_Lock:getChildByName("level")
    if isPosLock then
        local level = Utils:getFucnOpenLevel(AppDef.PetFightPos[ind + 1])
        locakLevel:setString(level)
    end
    
    local redPointImg = cell:getChildByName("Prompt")
	local key = "EquipShengJiang"..(ind + 1)

    local isShowToFight =  Utils:GetRedDotState(RedDotDef.ID.ShenJiang_ShangZhen) and (not isPosLock) and LRoleDataMgr.Pet.ShowPosList[ind + 1] <= 0
    --可上阵
	redPointImg:setVisible(isShowToFight)

    local length = #self.m_pPetList
    if length < ind + 1 then
        if not isPosLock then
        end
        return
    end

    local curPet = self.m_pPetList[ind+1]
    if curPet == nil or curPet.id == 0 then
        return
    end

    curPet.isCanYangCheng = false
    curPet.isCanChangePet = false
    --可换将
    if not redPointImg:isVisible() then
        --可换将
        local isCanChangePet = PetkaPaiManager:getPetCanChange(curPet.baseData.quality)
        curPet.isCanChangePet = isCanChangePet
        --可养成
        local isCanYangCheng = PetkaPaiManager:getPetCangeStrengthUp(curPet)
        curPet.isCanYangCheng = isCanYangCheng
        print("ShowPetCellInfo ==>", isCanChangePet, curPet.isCanYangCheng)
        local isShow =  Utils:GetRedDotState(RedDotDef.ID[key]) or isCanChangePet or isCanYangCheng
        redPointImg:setVisible(isShow)
    end

    cell.userObject = curPet.id
    AppDef:ShowProAttrImg(attrImg, curPet.baseData.petType)
    
    lvLabel:setString(curPet.level)
    Utils:ShowPetHeadImg(headImg, curPet.baseData.pic, headPanel, curPet.baseData.quality, curPet:IsShiny())
    bg_add:setVisible(false)
    bg_Lock:setVisible(false)
    self:ShowStars(starListView, curPet.star)
 
	
end

function PetZhengRongUI:addHeroToFight( sender )
    -- body
    performWithDelay(AppDef.CurScene, function( ... )
            -- body
        -- print("addHeroToFight 111111111111111111111111 =============>", self.m_curPetInd)
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_CHANGE_PET)
        Utils:SendMsg(LUIKaPaiPetEvent.ChangePetInitData, {pid=0, pos=self.m_curPetInd + 1})
    end, 0.2)
end

function PetZhengRongUI:YangChengCallBack(sender)
    Utils:InitUI("KaPaiPet.PetKaPaiMainUI", AppDef.UIType.FirstClassLayer, 1)
    local curPet = self.m_pPetList[self.m_curPetInd + 1]
    Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, curPet)
end

--检查--位置开启条件
function PetZhengRongUI:InitPosOpen()
    local ids = {1045,1046,1047,1048}
    self.m_stageList = {}
    for i=1,#ids do
        local cfg = JsonConfig.m_functionConfig.getDefByID(ids[i])
        if cfg ~= nil then
            for k=1,#cfg.open_condition do
                local value = cfg.open_condition[k]
                if value[1] == 8 and value[2] > 0 then
                    local mapId = JsonConfig.getMapIdByStageID(value[2])
                    LuaNetSendMsg:QueryFuBenInfo(1,mapId,value[2])
                    local tmp = {}
                    tmp.id = value[2]
                    tmp.open = false
                    table.insert(self.m_stageList,tmp)
                end
            end
        end
    end
end

function PetZhengRongUI:UpdateStageInfo(value)
    if value == nil then
        return
    end
    for i=1,#self.m_stageList do
        local tmp = self.m_stageList[i]
        if tmp.id == value.nodeId then
            tmp.open = (value.star ~= 0xff)
            break
        end
    end
end

function PetZhengRongUI:CheckStageOpen(stageId)
    if stageId == nil or stageId == 0 then
        return
    end
    for i=1,#self.m_stageList do
        local tmp = self.m_stageList[i]
        if tmp.id == stageId then
            return tmp.open
        end
    end
    return false
end

--检查--位置开启条件
function PetZhengRongUI:CheckPosOpen(pos)
    if pos < 1 or pos > 6 then
        return false
    end
    local ids = {1045,1046,1047,1048,1180,1180}
    local cfg = JsonConfig.m_functionConfig.getDefByID(ids[pos])
    if cfg == nil then
        return false
    end
    for i=1,#cfg.open_condition do
        local value = cfg.open_condition[i]
        if value[1] == 1 then
            local lv = LRoleDataMgr.MyHeroInfo.level
            if lv < value[2] then
                --提示
                Utils:ShowScrollTips(string.format(GUITips.RSI_Open_Tips1,value[2]))
                return false
            end
        elseif value[1] == 8 and value[2] > 0 then
            if not self:CheckStageOpen(value[2]) then
                --提示
                local cfg = JsonConfig.m_stageNodeConfig.getDefByID(value[2])
                if cfg ~= nil then
                    local nodeId = (value[2]%100-1)%10+1
                    Utils:ShowScrollTips(string.format(GUITips.RSI_Open_Tips2,cfg.mapid%1000,nodeId))
                end
                return false
            end
        end
    end
    return true
end

function PetZhengRongUI:ShowItemSource(pos)
    pos = pos or 0
    if pos < 1 or pos > 6 then
        return
    end
    local datas = {{60005,1001,1},{60005,1002,1},{60005,1003,1},{60005,1004,1}
        ,{60028,1001,1},{60028,1002,1}}
    Utils:ShowItemSource(datas[pos])
end

function PetZhengRongUI:PosCallBack(sender)
    local name = sender:getName()
    local pos = tonumber(string.match(name,"%d"))
    if not self:CheckPosOpen(pos) then
        return
    end
    if pos > 4 then
        --法宝
        self:OnFaBaoPosClick(pos)
    else
        self:OnEquipPosClick(pos)
    end
end

function PetZhengRongUI:ShowStars(starLayout, star)
    starLayout:removeAllChildren()
    print("ShowStars ===>", star)
    local panelSize = starLayout:getContentSize()
    local size = self.m_pStarImg:getContentSize()
    local sizeWith =size.width
    if star>6 then
     sizeWith =size.width-5
    end
    local width = sizeWith*star
    local sx = (panelSize.width - width)/2 + sizeWith/2
    local sy = size.height/2
    for i = 1, star do

        local starImg = self.m_pStarImg:clone()
        starLayout:addChild(starImg)
        starImg:setPosition(cc.p(sx, sy))
        sx = sx + sizeWith
    end
end


function PetZhengRongUI:updateTableView( ... )
    -- body
    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData();
    self.m_pTableView:setContentOffset(offset)
end

function PetZhengRongUI:updateUI( ... )
    -- body
    
    self:updateTableView()
    --print("updateUI ===================== 11111111111111111 >>", self.m_curPetInd)

    -- dump(self.m_pPetList, "PetZhengRongUI:updateTableView ==?>> ")

    local curPet = self.m_pPetList[self.m_curPetInd + 1]
    self:ShowAddHeroUI(curPet.id <= 0)
    --有数据才会显示
    if curPet and curPet.id > 0 then
        self:showPetDetailInfo(curPet)
    end
    
end

function PetZhengRongUI:showPetDetailInfo( petInfo )
    -- body
    if petInfo == nil or petInfo.id <= 0  then
        return
    end
    local Tips_2 = self._leftBottom:getChildByName("Tips_2")
    Tips_2:setString(string.format(GUITips.RSI_YINGXIONG_TIPS1, petInfo.level, petInfo.name, petInfo.breakLevel))

    --关卡星星
    -- for i=1, petInfo.star do
    --     local star = self._leftBottom:getChildByName("laingxing_".. i -1)
    --     star:setVisible(true)

    --     local starGrey = self._leftBottom:getChildByName("anxing_".. i -1)
    --     starGrey:setVisible(false)
    -- end

    local curRes = AppDef.Pet.QualityScoreRes[petInfo.baseData.quality]
    print("curRes ===>", curRes)
    local value = self._bg_Quality:getChildByName("Value")
    Utils:SafeLoadTexture(value ,curRes, ccui.TextureResType.plistType)

    self._zhanliValue:setString(Utils:getPowerStr(petInfo.zhandouli))

    self:showPetModel(petInfo.id)

    local curAtk = petInfo.attrs[AppDef.EAttrType.EAT_ATTACK]
    self._atk:setString(GUITips.Item_Attack..curAtk)
    local curHp = petInfo.attrs[AppDef.EAttrType.EAT_HP]
    self._hp:setString(GUITips.Item_Hp..curHp)
    local curDef = petInfo.attrs[AppDef.EAttrType.EAT_DEFENSE]
    self._wuFang:setString(GUITips.Item_WuFang..curDef)
    local curFaFang = petInfo.attrs[AppDef.EAttrType.EAT_MAGICD_EFENSE]
    self._faFang:setString(GUITips.Item_FaFang..curFaFang)

    if petInfo.baseData.attack_type == 1 then
        self._petType:setString(GUITips.Pet_AttackType_Tip2)
    else
        self._petType:setString(GUITips.Pet_AttackType_Tip1)
    end

    local petConfigData = JsonConfig.m_heroCfg.getDefByID(petInfo.id)
    -- print("petInfo.id ===", petInfo.id)
    -- --dump(petConfigData.skills, "333333333333")
    if #petConfigData.skills > 0 then
        local skillId = petConfigData.skills[1]
        local imagefile = string.format("Skill/UI/skill_%d.png", skillId)
        self._Icon1:loadTexture(imagefile, ccui.TextureResType.localType)

        local skillData = LSkillMgr:getSkillById(skillId)

        -- --dump(skillData, "showPetDetailInfo ===>")

        local level = PetkaPaiManager:GetPetSkillLvByStar(petInfo.star)
        local attrStr = LDataConstMgr:GetHeroSkillDesc(skillId, level)

        self._skillName:setString(skillData.name)
        self._txtCell:setString(attrStr)
    end

    
    PetkaPaiManager:ShowStars(self._StarList, petInfo.star)

    -- local isShow = Utils:GetRedDotState(RedDotDef.ID.ShenJiang_Change)
    print("showPetDetailInfo ==========>", petInfo.isCanChangePet)
    self._changePetBtn:getChildByName("Prompt"):setVisible(petInfo.isCanChangePet)

    self._YCPrompt:setVisible(petInfo.isCanYangCheng)
end

function PetZhengRongUI:updateUIAfterChangePos( posValue )
    -- body
    --重置数据
    local temp = self.m_pPetList[posValue[1]]
    self.m_pPetList[posValue[1]] = self.m_pPetList[posValue[2]]
    self.m_pPetList[posValue[2]] = temp

    self:updateUI()
end

function PetZhengRongUI:setZhenRongRed()
    local function FomationCheck()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJBUZHEN, true) then
            return false
        end
        local show = false
        local list = LDataConstMgr:GetFormationDataList()
        local cnt = #list
        for i=1, cnt do
            show = LRoleDataMgr:FormationCheckUp(i)
            if show then break end
        end
        return show
    end
    self.m_pFormationBtnRedPImg:setVisible(FomationCheck())
end


function PetZhengRongUI:UpdateRedDot(data)
    -- dump(data,"PetZhengRongUI:UpdateRedDot(data)====>")
    --养成按钮红点
    if data.id == RedDotDef.ID.ShenJiangYangCheng then
        local _ = self._YCPrompt and self._YCPrompt:setVisible(data.isShow)
	elseif data.id == RedDotDef.ID.EquipZhenRong then
		self:UpdateRedDotUI(true)
    elseif data.id==RedDotDef.ID.ShenJiang_BuZhen then
        self.m_pFormationBtnRedPImg:setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.ShenJiang_Change then
        -- self._changePetBtn:getChildByName("Prompt"):setVisible(data.isShow)
    end
end

function PetZhengRongUI:closeUI( ... )
    -- body
    Utils:DeleteUI(self.ScriptPath)
end

function PetZhengRongUI:onExit()
    local guideIds = {GuideDef.StepId.Guide_Pet_7,GuideDef.StepId.Guide_Pet_8,GuideDef.StepId.Guide_FuBen2_5
        ,GuideDef.StepId.Guide_FuBen2_10,GuideDef.StepId.Guide_FuBen3_5,GuideDef.StepId.Guide_FuBen3_10
        ,GuideDef.StepId.Guide_Equip_3,GuideDef.StepId.Guide_Equip_5,GuideDef.StepId.Guide_Equip_9
        ,GuideDef.StepId.Guide_Pet1_3,GuideDef.StepId.Guide_Pet1_6,GuideDef.StepId.Guide_XunBao_10}
    for i=1,#guideIds do
        Utils:SendMsg(LUIGuideEvent.UnRegisterStep,guideIds[i])
    end
    guideIds = {GuideDef.StepId.Guide_Pet_11,GuideDef.StepId.Guide_FuBen2_11,GuideDef.StepId.Guide_FuBen3_11
        ,GuideDef.StepId.Guide_Equip_10,GuideDef.StepId.Guide_Pet1_Finish,GuideDef.StepId.Guide_XunBao_Finish}
    for i=1,#guideIds do
        Utils:CheckGuide(guideIds[i],true)
    end
    self.m_pUILayer = nil
    self:Destory()
end

function PetZhengRongUI:RegisterGuide()
    for i=1, 5 do
        local pid = LRoleDataMgr.Pet.ShowPosList[i]
        if pid == 0 then
            local cell = self.m_pTableView:cellAtIndex(i-1)
            if cell ~= nil then
                local cellChild = cell:getChildByTag(123)
                if cellChild ~= nil then
                    Utils:RegisterGuide(GuideDef.StepId.Guide_Pet_7, cellChild:getChildByName("bg_add"), function()
                        self:PetCellTouched(cell)
                    end, nil, true)
                    break
                end
            end
        end
    end
    --------------------------------------------
    Utils:RegisterGuide(GuideDef.StepId.Guide_Pet_8, self._addnewBtn, handler(self, PetZhengRongUI.addHeroToFight), nil)
    --------------------------------------------
    if self._yangChengBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen2_5, self._yangChengBtn, handler(self, PetZhengRongUI.YangChengCallBack), nil,true)
        Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen3_5, self._yangChengBtn, handler(self, PetZhengRongUI.YangChengCallBack), nil,true)
        Utils:RegisterGuide(GuideDef.StepId.Guide_Pet1_3, self._yangChengBtn, handler(self, PetZhengRongUI.YangChengCallBack), nil,true)
    end
    --------------------------------------------
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_Pet_10)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_FuBen2_10)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_FuBen3_10)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_Equip_9)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_Pet1_6)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_XunBao_12)
    --------------------------------------------
    local equipBtn = self._equipNodes[1]
        if equipBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Equip_3, equipBtn, function()
            self:PosCallBack(equipBtn:getParent())
        end, nil,true)
    end
    --------------------------------------------
    if self._equipIcons[1] ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Equip_5, self._equipIcons[1].m_pNode, function()
            self._equipIcons[1]:SetCanClick(true)
            self._equipIcons[1]:ClickCallback()
            --print("111111")
        end, nil,true)
    end
    --------------------------------------------
    local fabaoBtn = self._equipNodes[5]
        if fabaoBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_10, fabaoBtn, function()
            self:PosCallBack(fabaoBtn:getParent())
        end, nil,true)
    end
    --------------------------------------------
end

function PetZhengRongUI:UpdateRedDotUI(ischeck)
	if ischeck == true then
		LRedDotCheckMgr:EquipZhenRongRedDotCheck()
	end
	--检查红点
	tableView = self.m_pListPanel:getChildByName("PetTableView")
	tableView:reloadData()
end

function PetZhengRongUI:UpdateEquipPosRedDot(i, uid)
	if uid ~= 0 then
		local isqianghua, isjinglian, isjuexing, isshenzhu = LRedDotCheckMgr:EquipCultivateRedDotCheck(uid)
		local isShow = isqianghua or isjinglian or isjuexing or isshenzhu
		if isShow == false then
			isShow = LRedDotCheckMgr:EquipChangeRedDotCheck(i,uid)
		end
		self._equipPrompts[i]:setVisible(isShow)
	else
		local isShow = LRedDotCheckMgr:EquipChangeRedDotCheck(i,uid)
		self._equipPrompts[i]:setVisible(isShow)
	end
end

function PetZhengRongUI:UpdateFaBaoPosRedDot(i,fightpos, uid)
	if uid ~= 0 then
		local isqianghua, isjinglian = LRedDotCheckMgr:FaBaoCultivateRedDotCheck(uid)
		local isShow = isqianghua or isjinglian
		if isShow == false then
			isShow = LRedDotCheckMgr:FaBaoChangeRedDotCheck(fightpos,uid)
		end
		self._equipPrompts[i]:setVisible(isShow)
	else
		local isShow = LRedDotCheckMgr:FaBaoChangeRedDotCheck(fightpos,uid)
		self._equipPrompts[i]:setVisible(isShow)
	end
end

return PetZhengRongUI

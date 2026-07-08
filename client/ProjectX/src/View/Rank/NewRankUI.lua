-- 排行榜逻辑
local _RC = require("View.Rank.NewRankConfig")
local RankContentDelegate = require("View.Rank.RankContentDelegate")
local MeiLiRankRecordDelegate = require("View.Rank.MeiLiRankRecordDelegate")

local NewRankUI = LUIBase:New()
NewRankUI.__index = NewRankUI

local spaceOfItem = 4

-----------------------------------
function NewRankUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_pLeftData)
    self.m_pLeftData = nil
    Utils:FreeTable(self.m_pLeftMapData)
    self.m_pLeftMapData = nil
    Utils:FreeTable(self.m_pFolderConfig)
    self.m_pFolderConfig = nil
    Utils:FreeTable(self.m_openFolder)
    self.m_openFolder = nil
    Utils:FreeTable(self.m_pSubConfig)
    self.m_pSubConfig = nil

    self.m_selectId = nil
    Utils:FreeTable(self.m_pChildren)
    self.m_pChildren = nil
    self.RoundNum = nil

    if self.m_pRankDelegate then
        self.m_pRankDelegate:onExit()
        self.m_pRankDelegate = nil
    end
    if self.m_pMeiLiRankRecordDelegate then
        self.m_pMeiLiRankRecordDelegate:onExit()
        self.m_pMeiLiRankRecordDelegate = nil
    end
    self.m_pTouchPanel = nil
    self.m_pLeftTableList = nil
    self.m_pLeftFolderCell = nil
    self.m_pLeftSubCell = nil

    Utils:FreeTable(self.m_pTitleLabels)
    self.m_pTitleLabels = nil
    self.m_pMyRankCell = nil
    self.m_pMyRankNum = nil
    self.m_pMyRankName = nil
    self.m_pMyRankCareer = nil
    self.m_pMyRankPower = nil
    self.m_pMyRankTitle = nil
    self.m_pMyRankMeiLiButton = nil
end
-----------------------------------
function NewRankUI:New()
    local o = {}
    setmetatable(o, NewRankUI)
    o:Init()
    return o
end
-----------------------------------
function NewRankUI:Init()
    self.Script = "Rank.NewRankUI"
    self.m_pLeftData = nil
    self.m_pLeftMapData = nil
    self.m_pFolderConfig = nil
    self.m_openFolder = nil
    self.m_selectId = 0
    self.m_pChildren = {}
    self.RoundNum = 0
    -----------------------------------
    self:InitData()
    self:InitRes()
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    if #self.m_pLeftData > 0 then
        self:SetCurrentSelectedRank(self.m_pLeftData[1].id)
    end
    -- self:SetCurrentSelectedRank(_RC.Types.XiuXianLiLian)
end
-----------------------------------
function NewRankUI:InitData()
    --左侧列表
    local Types = _RC.Types
    self.m_pLeftData = {}
    table.insert(self.m_pLeftData, {id = Types.DengJi})
    table.insert(self.m_pLeftData, {id = Types.ZhanLi})
    if not LRoleDataMgr.m_bIsCrossServer then
        table.insert(self.m_pLeftData, {id = Types.MeiLi})
    end
    table.insert(self.m_pLeftData, {id = Types.CaiFu})
    table.insert(self.m_pLeftData, {id = Types.ShenJiang})
    table.insert(self.m_pLeftData, {id = Types.BangHui})
    table.insert(self.m_pLeftData, {id = Types.HuoDong})

    self.m_pLeftMapData = {}
    for i=1,#self.m_pLeftData do
        self.m_pLeftMapData[self.m_pLeftData[i].id] = true
    end

    --文件夹功能配置
    self.m_pFolderConfig = {}
    self.m_pFolderConfig[Types.HuoDong] = {Types.LiLianTa, Types.XiuXianLiLian}

    self.m_pSubConfig = {}
    for k,v in pairs(self.m_pFolderConfig) do
        if k and v then
            for i=1,#v do
                self.m_pSubConfig[v[i]] = k
            end
        end    
    end
    --已开启文件夹
    self.m_openFolder = {}
end
-----------------------------------
function NewRankUI:InitRes()
    
end
-----------------------------------
function NewRankUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TheChartsLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
-----------------------------------
function NewRankUI:InitUIControl()
    self.m_pTouchPanel = self.m_pUILayer:getChildByName("Panel1")
    self.m_pTouchPanel:setSwallowTouches(false)
    self:InitLeftPanel()
    self:InitRightPanel()
end
-----------------------------------
function NewRankUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, NewRankUI.RemoveUI))
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_RANK_TITLE)
end
-----------------------------------
function NewRankUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRankEvent.RankListInfo,
        LUIXianHuaRankEvent.XianHuaRankListInfo,
        LUIRankEvent.ShowIndexRank,
    }
    self:RegistSelf(self,self.msgIds)
end
-----------------------------------
function NewRankUI:ProcessEvent(msg)
    if msg.msgId == LUIRankEvent.RankListInfo then
        self:OnRecvRankDataEvent(msg.value)
    elseif msg.msgId == LUIXianHuaRankEvent.XianHuaRankListInfo then
        self:OnRecvXianHuaRankDataEvent(msg.value)
    elseif msg.msgId == LUIRankEvent.ShowIndexRank then
        self:SetCurrentSelectedRank(msg.value)
    end
end
-----------------------------------
function NewRankUI:InitLeftPanel()
    local panel = self.m_pUILayer:getChildByName("Panel")
    self.m_pLeftTableList = panel:getChildByName("TheChartsList")
    self.m_pLeftTableList:setScrollBarEnabled(false)
    
    self.m_pLeftFolderCell = panel:getChildByName("Button2")
    self.m_pLeftSubCell = panel:getChildByName("SubcontrolBtn")

    self:InitLeftTableView()
end
----------------------------------
function NewRankUI:InitLeftTableView()
    if self.m_pLeftTableList == nil then
        return
    end
    self.m_pLeftTableList:removeAllChildren()
    local size = self.m_pLeftTableList:getContentSize()
    for i=1,#self.m_pLeftData do
        local info = self.m_pLeftData[i]
        if info then
            local pItem = self:createOneLeftItem(info, self.m_pLeftFolderCell)
            if pItem then
                table.insert(self.m_pChildren, pItem)
                pItem:setPositionX(size.width/2)
                self.m_pLeftTableList:addChild(pItem)
            end
        end
    end
    Utils:AlignNodes(self.m_pLeftTableList:getInnerContainer(), self.m_pChildren, {spaceOfItem}, 4, true)
end
----------------------------------
function NewRankUI:createOneLeftItem(info, pModel)
    if info == nil or info.id == nil or pModel == nil then
        return nil
    end
    local pCell = pModel:clone()
    pCell:setVisible(true)
    pCell:setTag(info.id)
    pCell:setTouchEnabled(true)
    pCell:setSwallowTouches(false)
    pCell:addClickEventListener(handler(self, NewRankUI.ClickLeftItem))
    self:SetLeftItemSelect(pCell, false)
    self:SetLeftItemName(pCell, info)
    self:SetLeftItemOpenClose(pCell, info)
    return pCell
end
----------------------------------
function NewRankUI:ClickLeftItem(sender)
    if sender == nil then
        return
    end
    local id = sender:getTag()
    if id <= 0 then
        return
    end
    self:SetCurrentSelectedRank(id)
end
----------------------------------
function NewRankUI:ResetLeftItem(id)
    if id == nil then
        return
    end
    local idx = self:GetIndex(id)
    if idx == nil then
        return
    end
    local pChildren = self.m_pChildren
    local pCell = pChildren[idx]
    self:SetLeftItemSelect(pCell, false)
    self:SetLeftItemOpenClose(pCell, self.m_pLeftData[idx])
end
----------------------------------
function NewRankUI:SelectLeftItem(id)
    if id == nil then
        return
    end
    local idx = self:GetIndex(id)
    if idx == nil then
        return
    end
    local pChildren = self.m_pChildren
    local pCell = pChildren[idx]
    self:SetLeftItemSelect(pCell, true)
    self:SetLeftItemOpenClose(pCell, self.m_pLeftData[idx])
end
----------------------------------
function NewRankUI:SetLeftItemSelect(cell, isSelect)
    if cell == nil then
        return
    end
    local pChooseBg = cell:getChildByName("ChooseBg")
    local _ = pChooseBg and pChooseBg:setVisible(isSelect)
end
----------------------------------
function NewRankUI:SetLeftItemName(cell, info)
    if cell == nil or info == nil then
        return
    end
    local pBtnName = cell:getChildByName("BtnName")
    if pBtnName then
        local data = _RC:GetRankConfigByTypeId(info.id)
        if data then
            pBtnName:setString(data.name or "")
        else
            pBtnName:setString("")
        end
    end
end
----------------------------------
function NewRankUI:SetLeftItemOpenClose(cell, info)
    if cell == nil or info == nil then
        return
    end
    local pOpenImage = cell:getChildByName("OpenImage")
    if pOpenImage == nil then
        return
    end
    local pCloseImage = cell:getChildByName("CloseImage")
    if pCloseImage == nil then
        return
    end
    local isFolder = self:IsFolder(info.id)

    if isFolder then
        local isOpen = self:IsOpen(info.id)
        pOpenImage:setVisible(isOpen)
        pCloseImage:setVisible(not isOpen)
    else
        pOpenImage:setVisible(false)
        pCloseImage:setVisible(false)
    end
end
----------------------------------
function NewRankUI:SetCurrentSelectedRank(tid)
    -- dump({tid, self.m_selectId}, "SetCurrentSelectedRank-->")
    if tid  == nil or tid == 0 then
        return
    end
    -- dump(self:IsFolder(tid), "self:IsFolder(tid)--->")
    if self:IsFolder(tid) then
        if self.m_selectId > 0 then
            self:ResetLeftItem(self.m_selectId)
            if self:IsSub(self.m_selectId) then
                local pid = self:GetFolderId(self.m_selectId)
                if pid and pid ~= tid and self:IsOpen(pid) then
                    self:RemoveFoldItem(pid)
                    self:ResetLeftItem(pid)
                end
            end
        end
        local temp = self.m_selectId
        self.m_selectId = tid
        -- dump(self.m_selectId, "self.m_selectId = tid---IsFolder>")
        
        if self:IsOpen(tid) then
            self:RemoveFoldItem(tid)
        else
            self:InsertFoldItem(tid)
            local cid = self:IsChild(tid, temp) and temp or self:GetFolderFirstChild(tid)
            self:SetCurrentSelectedRank(cid)
        end
        self:SelectLeftItem(tid)
        return
    end
    if self.m_selectId == tid then
        return
    end

    local temp = self.m_selectId
    self.m_selectId = tid
    -- dump(self.m_selectId, "self.m_selectId = tid---IsNotFolder>")

    local isLastSub = self:IsSub(temp)
    local isCurSub = self:IsSub(tid)
    -- dump({isLastSub, isCurSub}, "{isLastSub, isCurSub}-->")
    if isLastSub == isCurSub then
        self:ResetLeftItem(temp)
    elseif isLastSub then
        local pid = self:GetFolderId(temp)
        -- self:RemoveFoldItem(pid)
        self:ResetLeftItem(pid)
        self:ResetLeftItem(temp)
    elseif isCurSub then
        local pid = self:GetFolderId(tid)
        if not self:IsOpen(pid) then
            self:SetCurrentSelectedRank(pid)
            if self:GetFolderFirstChild(tid) ~= tid then
                self:SetCurrentSelectedRank(tid)
            end
            return
        end
    end
    self:SelectLeftItem(tid)
    self:UpdateRankTitle(tid)
    self:QueryNetMsg(tid)
    self:JumpToSelectItem(tid)
end
----------------------------------
function NewRankUI:InitRightPanel()
    local panel = self.m_pUILayer:getChildByName("Panel")
    local pTheCharts = panel:getChildByName("TheCharts")
    local pTitleImage = pTheCharts:getChildByName("TitleImage")
    self.m_pTitleLabels = {}
    for i=1,4 do
        table.insert(self.m_pTitleLabels, pTitleImage:getChildByName("TitleName"..i))
    end

    self.m_pRankDelegate = RankContentDelegate:New(pTheCharts, self.m_pTouchPanel)

    self.m_pMyRankCell = pTheCharts:getChildByName("PersonalBg")
    self.m_pMyRankNum = self.m_pMyRankCell:getChildByName("PersonalNum")
    self.m_pMyRankName = self.m_pMyRankCell:getChildByName("PersonalName")
    self.m_pMyRankCareer = self.m_pMyRankCell:getChildByName("CareerName")
    self.m_pMyRankPower = self.m_pMyRankCell:getChildByName("PowerNum")
    self.m_pMyRankTitle = self.m_pMyRankCell:getChildByName("Title")

    self.m_pMyRankMeiLiButton = self.m_pMyRankCell:getChildByName("Button_1")
    self.m_pMyRankMeiLiButton:addClickEventListener(handler(self, NewRankUI.ShowMeiLiRecordList))

    local pMeiLiPanel = self.m_pUILayer:getChildByName("Panel_21")
    self.m_pMeiLiRankRecordDelegate = MeiLiRankRecordDelegate:New(pMeiLiPanel)
    if self.m_pMeiLiRankRecordDelegate then
        self.m_pMeiLiRankRecordDelegate:SetClickCallback(function(index)
            if self.m_curRound ~= index then
                local conf = _RC:GetRankConfigByTypeId(_RC.Types.MeiLi)
                if conf then
                    LuaNetSendMsg:QueryXianHuaInfoNew(conf.opid, index)
                end
            end
        end)
    end
end
-----------------------------------
function NewRankUI:IsFolder(id)
    return self.m_pFolderConfig[id] ~= nil
end
-----------------------------------
function NewRankUI:IsChild(pid, cid)
    if pid == nil or cid == nil then
        return false
    end
    return self.m_pSubConfig[cid] == pid
end
-----------------------------------
function NewRankUI:IsSub(cid)
    if cid == nil then
        return false
    end
    return self.m_pSubConfig[cid] ~= nil
end
-----------------------------------
function NewRankUI:IsOpen(id)
    if id == nil then
        return false
    end
    return self.m_openFolder[id] ~= nil
end
-----------------------------------
function NewRankUI:GetFolderId(cid)
    return self.m_pSubConfig[cid]
end
-----------------------------------
function NewRankUI:GetIndex(id)
    if id == nil then
        return nil
    end
    for i=1,#self.m_pLeftData do
        local info = self.m_pLeftData[i]
        if info and info.id == id then
            return i
        end
    end
    return nil
end
-----------------------------------
function NewRankUI:GetFolderFirstChild(id)
    local info = self.m_pFolderConfig[id]
    if info == nil or #info == 0 then
        return nil
    end
    return info[1]
end
-----------------------------------
function NewRankUI:QueryNetMsg(id)
    if self:IsFolder(id) then
        return
    end
    local conf = _RC:GetRankConfigByTypeId(id)
    if conf then
        if id == _RC.Types.MeiLi then
            LuaNetSendMsg:QueryXianHuaInfoNew(conf.opid, 0)
        else
            LuaNetSendMsg:QueryRankList(conf.opid)
        end
        local _ = self.m_pRankDelegate and self.m_pRankDelegate:Reset()
    end
end
-----------------------------------
function NewRankUI:InsertFoldItem(id)
    local idx = self:GetIndex(id)
    if idx == nil then
        return
    end
    local info = self.m_pFolderConfig[id]
    if info == nil then
        return
    end

    for i=1,#info do
        local cid = info[i]
        if self.m_pLeftMapData[cid] then
            return
        end
        self.m_pLeftMapData[cid] = true
    end
    local size = self.m_pLeftTableList:getContentSize()
    local temp = self.m_pLeftTableList:getInnerContainerPosition()
    for i=1,#info do
        local cid = info[i]
        local data = {id = cid}
        local pItem = self:createOneLeftItem(data, self.m_pLeftSubCell)
        if pItem then
            table.insert(self.m_pLeftData, idx + i, data)
            table.insert(self.m_pChildren, idx + i, pItem)
            pItem:setPositionX(size.width/2)
            self.m_pLeftTableList:addChild(pItem)
        end
    end
    Utils:AlignNodes(self.m_pLeftTableList:getInnerContainer(), self.m_pChildren, {spaceOfItem}, 4, true)
    self.m_pLeftTableList:setInnerContainerPosition(temp)
    self.m_openFolder[id] = true
end
-----------------------------------
function NewRankUI:RemoveFoldItem(id)
    local info = self.m_pFolderConfig[id]
    if info == nil then
        return
    end
    local temp = self.m_pLeftTableList:getInnerContainerPosition()
    for i=1,#info do
        local cid = info[i]
        self.m_pLeftMapData[cid] = nil
        local idx = self:GetIndex(cid)
        if idx then
            table.remove(self.m_pLeftData, idx)
            local pItem = self.m_pChildren[idx]
            table.remove(self.m_pChildren, idx)
            self.m_pLeftTableList:removeChild(pItem, true)
        end
    end
    Utils:AlignNodes(self.m_pLeftTableList:getInnerContainer(), self.m_pChildren, {spaceOfItem}, 4, true)
    self.m_pLeftTableList:setInnerContainerPosition(temp)
    self.m_openFolder[id] = nil
end
-----------------------------------
function NewRankUI:UpdateRankTitle(id)
    if id == nil or self.m_pTitleLabels == nil then
        return
    end
    local conf = _RC:GetRankConfigByTypeId(id)
    if conf then
        for i=1,#self.m_pTitleLabels do
            self.m_pTitleLabels[i]:setString(conf.titles[i])
        end
    end
end
-----------------------------------
function NewRankUI:JumpToSelectItem(tid)
    if tid == nil then
        return
    end
    local index = self:GetIndex(tid)
    if index == nil then
        return
    end
    local pItem = self.m_pChildren[index]
    if pItem then
        local innerPos = self.m_pLeftTableList:getInnerContainerPosition()
        local pos = cc.p(pItem:getPosition())
        pos.y = pos.y - pItem:getContentSize().height*pItem:getAnchorPoint().y
        pos.y = pos.y + innerPos.y
        local isUpdate = false
        if pos.y < 0 then
            innerPos.y = innerPos.y - pos.y
            isUpdate = true
        end
        if isUpdate == false then
            local offset = pos.y - self.m_pLeftTableList:getContentSize().height + pItem:getContentSize().height
            if offset > 0 then
                innerPos.y = innerPos.y - offset
                isUpdate = true
            end
        end
        if isUpdate then
            innerPos.y = math.max(innerPos.y, self.m_pLeftTableList:getContentSize().height - self.m_pLeftTableList:getInnerContainerSize().height)
            innerPos.y = math.min(innerPos.y, 0)
            self.m_pLeftTableList:setInnerContainerPosition(innerPos)
        end
    end
end
-----------------------------------
function NewRankUI:UpdateRankData(data)
    if data == nil or data.op == nil then
        return
    end
    local conf = _RC:GetRankConfigByTypeId(self.m_selectId)
    if conf == nil or conf.opid ~= data.op then
        return
    end

    if self.m_pRankDelegate then
        self.m_pRankDelegate:updateData(data.rankdata, self.m_selectId)
    end
end
-----------------------------------
function NewRankUI:OnRecvRankDataEvent(data)
    Utils:FreeTable(self.m_myRankData)
    self.m_myRankData = nil
    self.m_myRankData = data
    self:UpdateRankData(data)
    self:UpdateMyNomalRank()
end
-----------------------------------
function NewRankUI:OnRecvXianHuaRankDataEvent(data)
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_3)
        return
    end

    self.RoundNum = math.max(math.max(data.round, 1), self.RoundNum)
    self.m_curRound = math.max(data.round, 1)

--    dump(data.rankdata, "rankdata")
--    print("OnRecvXianHuaRankDataEvent", self.RoundNum)
    if #data.rankdata < 1 and self.RoundNum > 1 then
        local conf = _RC:GetRankConfigByTypeId(self.m_selectId)
        if conf then
            if self.m_selectId == _RC.Types.MeiLi then
                LuaNetSendMsg:QueryXianHuaInfoNew(conf.opid, 1)
            end
        end
    else
        Utils:FreeTable(self.m_myRankData)
        self.m_myRankData = nil
        self.m_myRankData = data
        self:UpdateRankData(data)
        self:UpdateMyMeiLiRank()
    end
end
-----------------------------------
function NewRankUI:GetRankString(rank)
    if rank == nil or rank == 0 or rank > 1000000 then
        return GUITips.RSI_WELFARE_MSG29
    else
        return tostring(rank)
    end
end
-----------------------------------
function NewRankUI:GetRankName()
    if self.m_selectId == _RC.Types.BangHui then -- 帮派
        if LRoleDataMgr.MyHeroInfo.FactionId == 0 then
            return GUITips.RSI_FACTION_MSG70
        else
            return LRoleDataMgr.MyHeroInfo.FactionName
        end
    else
        return LRoleDataMgr.MyHeroInfo.name
    end
end
-----------------------------------
function NewRankUI:GetRankInfo()
    if self.m_selectId ~= _RC.Types.MeiLi and self.m_selectId ~= _RC.Types.ShenJiang and self.m_selectId ~= _RC.Types.BangHui then
        return AppDef:GetHeroProfessionalName(LRoleDataMgr.MyHeroInfo:Getprofessional())
    elseif self.m_selectId == _RC.Types.ShenJiang then
        if LRoleDataMgr.Pet.bestPet ~= nil then
            return LRoleDataMgr.Pet.bestPet.name
        else
            return GUITips.UI_No_Shenjiang_Tips
        end
    elseif self.m_selectId == _RC.Types.BangHui then
        if LRoleDataMgr.MyHeroInfo.FactionId == 0 then
            return GUITips.RSI_FACTION_MSG70
        else
            return LRoleDataMgr.Faction.Info.bangZhuName
        end
    end
end
-----------------------------------
function NewRankUI:GetRankValue()
    if self.m_selectId == _RC.Types.DengJi then -- 等级
        return tostring(LRoleDataMgr.MyHeroInfo.level)
    elseif self.m_selectId == _RC.Types.ZhanLi then -- 战斗力
        return tostring(LRoleDataMgr.MyHeroInfo.zhanDouLiInAll)
    elseif self.m_selectId == _RC.Types.CaiFu then -- 金币 
        return tostring(LRoleDataMgr.MyHeroInfo.DetailData.Money)
    elseif self.m_selectId == _RC.Types.ShenJiang then -- 宠物战斗力
        if LRoleDataMgr.Pet.bestPet then
            return tostring(LRoleDataMgr.Pet.bestPet.zhandouli)
        end
        return "0"
    elseif self.m_selectId == _RC.Types.BangHui then -- 帮会等级
        if LRoleDataMgr.MyHeroInfo.FactionId == 0 then
            return GUITips.RSI_FACTION_MSG70
        else
            return tostring(LRoleDataMgr.Faction.Info.level)
        end
    elseif self.m_selectId == _RC.Types.LiLianTa  then -- 积分
        local stageNum = 0
        if self.m_myRankData and self.m_myRankData.mydata and self.m_myRankData.mydata.info_3 then
            stageNum = self.m_myRankData.mydata.info_3
        end
        return string.format(GUITips.RSI_EVERYDAY_PASSSTAGE, stageNum)
    elseif  self.m_selectId == _RC.Types.XiuXianLiLian then
        return self.m_myRankData.info_3 or ""
    elseif type(self.m_selectId) == "number" then
        return string.format("to do %d", self.m_selectId)
    else
        return ""
    end
end
-----------------------------------
function NewRankUI:UpdateMyNomalRank()
    if self.m_pMyRankCell == nil then
        return
    end
    local data = self.m_myRankData
    local myRankData = data.mydata

    self.m_pMyRankNum:setString(self:GetRankString(data.myrank or 0))

    local isInRank = data.myrank ~= 0

    if isInRank then
        self.m_pMyRankName:setString(myRankData.info_1 or "")
        self.m_pMyRankCareer:setString(myRankData.info_2 or "")
        self.m_pMyRankPower:setString(myRankData.info_3 or "")
    else
        self.m_pMyRankName:setString(self:GetRankName())
        self.m_pMyRankCareer:setString(self:GetRankInfo())
        self.m_pMyRankPower:setString(self:GetRankValue())
    end
    local quality = 0
    if isInRank then
        if self.m_selectId == _RC.Types.ShenJiang then
            local data = LDataConstMgr:GetPetData(myRankData.petId)
            if data then
                quality = data.quality
            end
        end
    else
        if LRoleDataMgr.Pet.bestPet and LRoleDataMgr.Pet.bestPet.baseData then
            quality = LRoleDataMgr.Pet.bestPet.baseData.quality
        else
            quality = 1
        end
    end
    local color = nil
    if self.m_selectId == _RC.Types.ShenJiang then
        color = AppDef:GetPetQualityColor(quality)
    else
        color = cc.c3b(110, 56, 48)
    end
    if color then
        self.m_pMyRankCareer:setTextColor(color)
    end
    self.m_pMyRankNum:setVisible(true)
    self.m_pMyRankName:setVisible(true)
    self.m_pMyRankCareer:setVisible(true)
    self.m_pMyRankPower:setVisible(true)
    self.m_pMyRankTitle:setVisible(false)
    self.m_pMyRankMeiLiButton:setVisible(false)
end
-----------------------------------
function NewRankUI:UpdateMyMeiLiRank()
    if self.m_pMyRankCell == nil then
        return
    end
    local data = self.m_myRankData

--    print("UpdateMyMeiLiRank", self.RoundNum, self.m_curRound)

    local strRound = string.format(GUITips.RSI_TARGET_RD_TIPS20, self.m_curRound)
    self.m_pMyRankMeiLiButton:getChildByName("Text"):setString(strRound)

    self.m_pMyRankNum:setVisible(false)
    self.m_pMyRankName:setVisible(false)
    self.m_pMyRankCareer:setVisible(false)
    self.m_pMyRankPower:setVisible(false)
    self.m_pMyRankTitle:setVisible(false)
    self.m_pMyRankMeiLiButton:setVisible(true)
end
-----------------------------------
function NewRankUI:ShowMeiLiRecordList(sender)
    if self.m_pMeiLiRankRecordDelegate then
        self.m_pMeiLiRankRecordDelegate:updateData(self.RoundNum)
    end
end
-----------------------------------
return NewRankUI
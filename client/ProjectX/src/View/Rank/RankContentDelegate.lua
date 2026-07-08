local _RC = require("View.Rank.NewRankConfig")

local RankContentDelegate = {}
RankContentDelegate.__index = RankContentDelegate

local MAXCHENHAONUM = 64
local RankDataIndexOffset = 1000
local XianHuaRankDataIndexOffset = 2000
-----------------------------------
function RankContentDelegate:New(uiLayer, pTouchLayer)
	if uiLayer == nil then
		return nil
	end
    local o = {}
    setmetatable(o, RankContentDelegate)
    o:Init(uiLayer, pTouchLayer)
    return o
end
-----------------------------------
function RankContentDelegate:Init(uiLayer, pTouchLayer)
	self.m_pUILayer = uiLayer
	self.m_pTouchPanel = pTouchLayer
	self.m_tableCount = 0
	self.m_isDragging = false
	self.m_pTableView = nil
	self.m_pGridCell = nil
	self.m_pGridCellSize = nil
	self.m_pTablePanel = nil
	self.m_datas = nil
    -----------------------------------
    self:InitUIControl()
end
-----------------------------------
function RankContentDelegate:onExit()
    self.m_pUILayer = nil
	self.m_pTouchPanel = nil
	self.m_tableCount = nil
	self.m_isDragging = nil
	self.m_pTableView = nil
	self.m_pGridCell = nil
	self.m_pGridCellSize = nil
	self.m_pTablePanel = nil
	self.m_datas = nil
    self.m_pClickCallback = nil
    self.m_rType = nil
end
-----------------------------------
function RankContentDelegate:InitUIControl()
	self.m_pTablePanel = self.m_pUILayer:getChildByName("List")

	self.m_pGridCell = self.m_pUILayer:getChildByName("Name")
	self.m_pGridCell:setTouchEnabled(false)
	self.m_pGridCellSize = self.m_pGridCell:getContentSize()

	self.m_pTableView = self:InitTableView(self.m_pTablePanel)
end
-----------------------------------
function RankContentDelegate:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCellSize.width
        local height = self.m_pGridCellSize.height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx + 1)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    cfg.tableCellTouched = function(sender, cell)
        return self:TableCellTouched(sender, cell)
    end

    return Utils:createTableView(cfg)
end
-----------------------------------
function RankContentDelegate:TableCellTouched(sender, cell)
	if sender == nil or cell == nil or self.m_pTouchPanel == nil then
		return
	end
	local index = cell:getIdx()
	local child = cell:getChildByTag(123)
	
	if self.m_selectIdx and self.m_selectIdx >= 0 then
		local pCell = sender:cellAtIndex(self.m_selectIdx)
		if pCell then
			local panel = pCell:getChildByTag(123)
			if panel then
				self:UpdateChooseBg(panel, false)
			end
		end
	end

	self:UpdateChooseBg(child, true)
	self.m_selectIdx = index

	local function queryOtherRoleInfo()
		if self.m_datas == nil then
			return
		end
	    local info = self.m_datas[index + 1]
	    if info then
	    	if self.m_rType == _RC.Types.ShenJiang then
	    	    LuaNetSendMsg:QueryPetInfo(info.role_id, info.petId)
	    	else
	    	    LuaNetSendMsg:QueryOtherPlayer(info.role_id)
	    	end
	    end
	end

	local userData = {
	    {GUITips.UI_Team_MemberInfo,queryOtherRoleInfo},
	    pos = self.m_pTouchPanel:getTouchEndPosition(),
	}
	Utils:InitUI("Common.BtnBoxUI",AppDef.UIType.PopWindow, userData)
end
-----------------------------------
function RankContentDelegate:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)

        local pTitle = cellChild:getChildByName("Title")
        if pTitle then
        	pTitle:setScale9Enabled(false)
        	pTitle:ignoreContentAdaptWithSize(true)
        end
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx], idx)
    end
    return cell
end
-----------------------------------
function RankContentDelegate:updateItem(cell, info, idx)
	if cell == nil or info == nil or idx == nil then
		return
	end
	self:UpdateBg(cell, idx)
	self:UpdateChooseBg(cell, false)
	self:UpdateRank(cell, idx)
	self:UpdateName(cell, info.info_1)
	self:UpdateVIP(cell, info.vipLevel)
	self:UpdateCareer(cell, info.info_2, self.m_rType, info.petId)
	self:UpdatePowerOrTitle(cell, info.info_3, self.m_rType)
end
-----------------------------------
function RankContentDelegate:updateData(datas, rType)
	if self.m_pTableView == nil then
		return
	end
	-- dump(datas, "updateData--->")
	self.m_rType = rType or _RC.Types.DengJi
	self.m_datas = datas or {}
	self.m_tableCount = #self.m_datas
	self.m_pTableView:reloadData()
	self.m_pTableView:setVisible(true)
end
-----------------------------------
function RankContentDelegate:UpdateBg(cell, idx)
	local pBg = cell:getChildByName("Bg")
	local _ = pBg and pBg:setVisible((idx % 2) == 1)
end

function RankContentDelegate:UpdateChooseBg(cell, isShow)
	local pChooseBg = cell:getChildByName("ChooseBg")
	local _ = pChooseBg and pChooseBg:setVisible(isShow)
end
-----------------------------------
function RankContentDelegate:UpdateRank(cell, idx)
	for i=1,3 do
		local pPlaceImage = cell:getChildByName("PlaceImage"..i)
		local _ = pPlaceImage and pPlaceImage:setVisible(i == idx)
	end
	local pPlaceNum = cell:getChildByName("PlaceNum")
	if pPlaceNum then
		pPlaceNum:setVisible(idx > 3)
		if idx > 3 then
			pPlaceNum:setString(tostring(idx))
		end
	end
end
-----------------------------------
function RankContentDelegate:UpdateName(cell, info)
	local pPlaceName = cell:getChildByName("PlaceName")
	local _ = pPlaceName and pPlaceName:setString(info or "")
end
-----------------------------------
function RankContentDelegate:UpdateVIP(cell, info)
	local pVipImage = cell:getChildByName("VIPImage")
	if pVipImage then
	    if info and info > 0 then
	        pVipImage:setVisible(true)
	        pVipImage:getChildByName("AtlasLabel"):setString(info or 0)
	    else
	        pVipImage:setVisible(false)
	    end
	end
end
-----------------------------------
function RankContentDelegate:UpdateCareer(cell, info, rType, petId)
	local pCareer = cell:getChildByName("CareerName")
	if pCareer then
		pCareer:setString(info or "")
	end
    if rType == _RC.Types.ShenJiang and petId then
    	local petData = LDataConstMgr:GetPetData(petId)
    	if petData then
    	    pCareer:setTextColor(AppDef:GetPetQualityColor(petData.quality))
    	end
    else
    	pCareer:setTextColor(cc.c3b(110,56,48))
    end
end
-----------------------------------
function RankContentDelegate:UpdatePowerOrTitle(cell, info, rType)
	local pPowerNum = cell:getChildByName("PowerNum")
	local pTitle = cell:getChildByName("Title")

	if rType == _RC.Types.MeiLi then -- 魅力
	    self:SetTitle(cell, info)
	else
		pTitle:setVisible(false)
		pPowerNum:setVisible(true)
	    pPowerNum:setString(info)
	end
end
-----------------------------------
function RankContentDelegate:SetTitle(cell, titleId)
	local pPowerNum = cell:getChildByName("PowerNum")
	local pTitle = cell:getChildByName("Title")
	if titleId ~= nil and titleId > 0 and titleId <= MAXCHENHAONUM then
		local path = string.format(AppDef.GUIRes.Res_Titile_Format, titleId)
		pTitle:loadTexture(path, UI_TEX_TYPE_PLIST)
		pPowerNum:setVisible(false)
		pTitle:setVisible(true)
	else
		pPowerNum:setVisible(false)
		pTitle:setVisible(false)
		pPowerNum:setString(GUITips.Res_No_Title)
	end
end
-----------------------------------
function RankContentDelegate:Reset()
	if self.m_pTableView then
		self.m_pTableView:setVisible(false)
	end
end
-----------------------------------
return RankContentDelegate
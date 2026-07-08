local FaBaoChongShengUI = LUIBase:New()
FaBaoChongShengUI.__index = FaBaoChongShengUI

FaBaoChongShengUI.IsHideInBattle = true
local EVERYLINENUM = 5
function FaBaoChongShengUI:New()
    local o = {}
    setmetatable(o, FaBaoChongShengUI)
    o:Init()
    return o
end

function FaBaoChongShengUI:RegistMsgs()
    self.msgIds = 
    {
        LHuiShouEvent.SelectFaBao,
		LHuiShouEvent.FaBaoChaXun,
		LHuiShouEvent.FaBaoChongSheng,
    }
    self:RegistSelf(self, self.msgIds)
end

function FaBaoChongShengUI:ProcessEvent(msg)
	if msg.msgId == LHuiShouEvent.SelectFaBao then
		self:UpdateFaBaoInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.FaBaoChaXun then
		self:UpdateRewardInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.FaBaoChongSheng then
		self:ResetUI()
	end
end

function FaBaoChongShengUI:Init()
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self.canchongsheng = true
	self.m_icon = nil
	self.m_pFaBaoId = 0
	self:RegistMsgs()
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
end

function FaBaoChongShengUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/fabaochongsheng.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function FaBaoChongShengUI:InUIControl()
	local fabaochongsheng = self.m_pUILayer:getChildByName("fabaochongshengUI")
	local bglayer = fabaochongsheng:getChildByName("Bg")
	self.text = fabaochongsheng:getChildByName("Text")
	self.chongsheng = fabaochongsheng:getChildByName("chongsheng")
	self.chongsheng:setVisible(false)
	self.m_iconNode = bglayer:getChildByName("Bg_0")
	self.m_icon = bglayer:getChildByName("Model")
	self.m_icon:setVisible(false)
	self.addBtn = bglayer:getChildByName("Btn_add")
	self.addBtn:addClickEventListener(handler(self,FaBaoChongShengUI.OpenFaBaoChooseUI))
	self.name = bglayer:getChildByName("Name")
	self.name:setVisible(false)
	self.level = self.name:getChildByName("Level")

	self.changeBtn = bglayer:getChildByName("Btn_Change")
	self.changeBtn:addClickEventListener(handler(self,FaBaoChongShengUI.OpenFaBaoChooseUI))
	self.changeBtn:setVisible(false)

	local chongshengBtn = self.chongsheng:getChildByName("Btn_chongsheng")
	chongshengBtn:addClickEventListener(handler(self,FaBaoChongShengUI.onChongShengClicked))
	self:MarkIntaractCObj(chongshengBtn)

	local fanhuan = self.chongsheng:getChildByName("fanhuan")
	self.tableviewPanel = fanhuan:getChildByName("TableView")
	self.itemlist = fanhuan:getChildByName("ItemList")
	self.itemlist:setVisible(false)
	self.item = fanhuan:getChildByName("Item")
	self.item:setVisible(false)
	self:InitTableView()
end

function FaBaoChongShengUI:ResetUI()
	self.chongsheng:setVisible(false)
	self.name:setVisible(false)
	self.changeBtn:setVisible(false)
	self.addBtn:setVisible(true)
	self.text:setVisible(true)
	self.m_iconNode:setVisible(true)
	self.m_icon:setVisible(false)
	self.m_pFaBaoId = 0
end

function FaBaoChongShengUI:UpdateFaBaoInfo(fid)
	self.m_pFaBaoId = fid
	print("=============",fid)
	LuaNetSendMsg:SendPetFaBaoChongSheng(34, fid)
	local fabaoList = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
	local fabaodata = fabaoList[fid]

	self.addBtn:setVisible(false)
	self.text:setVisible(false)
	self.changeBtn:setVisible(true)
	self.chongsheng:setVisible(true)
	self.name:setVisible(true)
	self.name:setString( fabaodata.baseData.name )
	self.level:setString(string.format("%d级", fabaodata.qhLv))
	self.m_iconNode:setVisible(false)
	self.m_icon:setVisible(true)
	local shuxing = self.chongsheng:getChildByName("shuxing")
	local attr1 = shuxing:getChildByName("Atrribute_1")
	attr1:getChildByName("Value_1"):setString( string.format("%d级",fabaodata.qhLv))
	local attr2 = shuxing:getChildByName("Atrribute_2")
	attr2:getChildByName("Value_1"):setString( string.format("%d级",fabaodata.jlLv))
	local cfg = JsonConfig.m_faBaoConfig.getDefByID(fabaodata.m_id)
	local path = "item/"..cfg.pic..".png"
    Utils:SafeLoadTexture(self.m_icon, path, ccui.TextureResType.localType)
	local cost = self.chongsheng:getChildByName("ConsumeBg"):getChildByName("Value")
	local icon = self.chongsheng:getChildByName("ConsumeBg"):getChildByName("Text"):getChildByName("Icon")
	local cfg = JsonConfig.m_config.getDefByID(18)
	local value = json.decode(cfg.value)
	cost:setString(value[3])
	local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
	if myMoney < value[3] then
		self.canchongsheng = false
	end
	local cfg = JsonConfig.m_Item.getDefByID(value[1])
	local path = "res/UI/Icon/ui_huobi_icon/huobi_"..cfg.pic..".png"
	Utils:SafeLoadTexture(icon, path,ccui.TextureResType.plistType)
end

function FaBaoChongShengUI:UpdateRewardInfo(data)
	self.m_pRewardList = data
	self.m_pTableView:reloadData()
end

function FaBaoChongShengUI:InitTableView()
	local tableView = cc.TableView:create(self.tableviewPanel:getContentSize())
    tableView:setContentSize(self.tableviewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	--tableView:setBounceable(false)
    self.tableviewPanel:addChild(tableView)

    local function cellSizeForTable(sender,idx)
        local width = self.itemlist:getContentSize().width
        local height = self.itemlist:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
		return math.ceil(#self.m_pRewardList / EVERYLINENUM)
    end

    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

	self.m_pTableView = tableView
end

function FaBaoChongShengUI:TableCellAtIndex(sender, idx)
	local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.itemlist:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
		cellChild:setSwallowTouches(false)
		for i=1, EVERYLINENUM do
			local index = idx * EVERYLINENUM + i
			local data = self.m_pRewardList[index]
			
			if data ~= nil then
				local itemNode = self.item:clone()
				itemNode:setTouchEnabled(false)
				itemNode:setVisible(true)
				itemNode:setName("Item"..i)
				itemNode:setTag(index)
				Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
				cellChild:pushBackCustomItem(itemNode)
			end
        end      
    else
        cellChild = cell:getChildByTag(123)
		for i=1, EVERYLINENUM do
			local index = idx*EVERYLINENUM+i
			local data = self.m_pRewardList[index]
			if data ~= nil then
				local itemNode = cellChild:getChildByName("Item"..i)
				if itemNode == nil then
					local itemNode = self.item:clone()
					itemNode:setVisible(true)
					itemNode:setName("Item"..i)
					itemNode:setTag(index)
					itemNode:setTouchEnabled(false)
					local pitem = Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
					pitem:setSwallowTouches(false)
					cellChild:pushBackCustomItem(itemNode)
				else
					itemNode:setVisible(true)
					Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
				end
			else
				local itemNode = cellChild:getChildByName("Item"..i)
				if itemNode ~= nil then
					itemNode:setVisible(false)
				end
			end
        end
    end
    
    return cell
end

function FaBaoChongShengUI:OpenFaBaoChooseUI(sender)
	Utils:OpenFunction(AppDef.EModuleID.EMID_FABAO_CHOOSE)
end

function FaBaoChongShengUI:onChongShengClicked(sender)
	if self.canchongsheng == false then
		Utils:ShowScrollTips(GUITips.RSI_LD_TIP11)
		return
	end
	local data = {}
	data.fabaoid = self.m_pFaBaoId
	data.fanhuanlist = self.m_pRewardList
	Utils:OpenFunction(AppDef.EModuleID.EMID_CHONGSHENG_CONFIRM, data)
end

function FaBaoChongShengUI:SetVisible(isShow)
	self.m_pUILayer:setVisible(true)
	self:CheckFaBao()
end

function FaBaoChongShengUI:CheckFaBao()
	if self.m_pFaBaoId == 0 then
		return
	end
	local data = LRoleDataMgr.Pet:GetFaBaoById(self.m_pFaBaoId)
	if data == nil then
		self:ResetUI()
	end
end

function FaBaoChongShengUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function FaBaoChongShengUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function FaBaoChongShengUI:CloseUI()
	Utils:DeleteUI("HuiShou.FaBaoChongShengUI")
end

return FaBaoChongShengUI

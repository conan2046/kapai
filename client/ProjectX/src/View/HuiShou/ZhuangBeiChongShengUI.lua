local ZhuangBeiChongShengUI = LUIBase:New()
ZhuangBeiChongShengUI.__index = ZhuangBeiChongShengUI

ZhuangBeiChongShengUI.IsHideInBattle = true
local EVERYLINENUM = 5
function ZhuangBeiChongShengUI:New()
    local o = {}
    setmetatable(o, ZhuangBeiChongShengUI)
    o:Init()
    return o
end

function ZhuangBeiChongShengUI:RegistMsgs()
    self.msgIds = 
    {
        LHuiShouEvent.SelectZhuangBei,
		LHuiShouEvent.ZhuangBeiChaXun,
		LHuiShouEvent.ZhuangBeiChongSheng,
    }
    self:RegistSelf(self, self.msgIds)
end

function ZhuangBeiChongShengUI:ProcessEvent(msg)
	if msg.msgId == LHuiShouEvent.SelectZhuangBei then
		self:UpdateEquipInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.ZhuangBeiChaXun then
		self:UpdateRewardInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.ZhuangBeiChongSheng then
		self:ResetUI()
	end
end

function ZhuangBeiChongShengUI:Init()
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self.canchongsheng = true
	self.m_icon = nil
	self:RegistMsgs()
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
end

function ZhuangBeiChongShengUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/zhuangbeichongsheng.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function ZhuangBeiChongShengUI:InUIControl()
	local zhuangbeichongsheng = self.m_pUILayer:getChildByName("zhuangbeichongshengUI")
	local bglayer = zhuangbeichongsheng:getChildByName("Bg")
	self.text = zhuangbeichongsheng:getChildByName("Text")
	self.chongsheng = zhuangbeichongsheng:getChildByName("chongsheng")
	self.chongsheng:setVisible(false)
	self.m_iconNode = bglayer:getChildByName("Bg_0")
	self.m_icon = bglayer:getChildByName("Model")
	self.m_icon:setVisible(false)
	self.addBtn = bglayer:getChildByName("Btn_add")
	self.addBtn:addClickEventListener(handler(self,ZhuangBeiChongShengUI.OpenZhuangbeiChooseUI))
	self.name = bglayer:getChildByName("Name")
	self.name:setVisible(false)
	self.level = self.name:getChildByName("Level")

	self.changeBtn = bglayer:getChildByName("Btn_Change")
	self.changeBtn:addClickEventListener(handler(self,ZhuangBeiChongShengUI.OpenZhuangbeiChooseUI))
	self.changeBtn:setVisible(false)

	local chongshengBtn = self.chongsheng:getChildByName("Btn_chongsheng")
	chongshengBtn:addClickEventListener(handler(self,ZhuangBeiChongShengUI.onChongShengClicked))
	self:MarkIntaractCObj(chongshengBtn)

	local fanhuan = self.chongsheng:getChildByName("fanhuan")
	self.tableviewPanel = fanhuan:getChildByName("TableView")
	self.itemlist = fanhuan:getChildByName("ItemList")
	self.itemlist:setVisible(false)
	self.item = fanhuan:getChildByName("Item")
	self.item:setVisible(false)
	self:InitTableView()
end

function ZhuangBeiChongShengUI:ResetUI()
	self.chongsheng:setVisible(false)
	self.name:setVisible(false)
	self.changeBtn:setVisible(false)
	self.addBtn:setVisible(true)
	self.text:setVisible(true)
	self.m_iconNode:setVisible(true)
	self.m_icon:setVisible(false)
end

function ZhuangBeiChongShengUI:UpdateEquipInfo(eid)
	self.m_pEquipId = eid
	LuaNetSendMsg:SendPetEquipChongSheng(32, eid)
	local equipList = LRoleDataMgr.Pet.equipList.m_petEquips
	local equipdata = equipList[eid]

	self.addBtn:setVisible(false)
	self.text:setVisible(false)
	self.changeBtn:setVisible(true)
	self.chongsheng:setVisible(true)
	self.name:setVisible(true)
	self.name:setString( equipdata.m_name )
	local qhlv = equipdata.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
	self.level:setString( string.format("%d级", qhlv) )
	self.m_iconNode:setVisible(false)
	self.m_icon:setVisible(true)
	local cfg = JsonConfig.m_equipConfig.getDefByID(equipdata.m_id)
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

function ZhuangBeiChongShengUI:UpdateRewardInfo(data)
	self.m_pRewardList = data
	self.m_pTableView:reloadData()
end

function ZhuangBeiChongShengUI:InitTableView()
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

function ZhuangBeiChongShengUI:TableCellAtIndex(sender, idx)
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
				local pitem = Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
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
					local pitem = Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
					pitem:setSwallowTouches(false)
					cellChild:pushBackCustomItem(itemNode)
				else
					itemNode:setVisible(true)
					Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
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

function ZhuangBeiChongShengUI:OpenZhuangbeiChooseUI(sender)
	Utils:OpenFunction(AppDef.EModuleID.EMID_ZHUANGBEI_CHOOSE)
end

function ZhuangBeiChongShengUI:onChongShengClicked(sender)
	if self.canchongsheng == false then
		Utils:ShowScrollTips(GUITips.RSI_LD_TIP11)
		return
	end
	local data = {}
	data.equipid = self.m_pEquipId
	data.fanhuanlist = self.m_pRewardList
	Utils:OpenFunction(AppDef.EModuleID.EMID_CHONGSHENG_CONFIRM, data)
end

function ZhuangBeiChongShengUI:SetVisible(isShow)
	self.m_pUILayer:setVisible(true)
	self:CheckEquip()
end

function ZhuangBeiChongShengUI:CheckEquip()
	if self.m_pEquipId == 0 then
		return
	end
	local data = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_pEquipId]
	if data == nil then
		self:ResetUI()
	end
end

function ZhuangBeiChongShengUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function ZhuangBeiChongShengUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function ZhuangBeiChongShengUI:CloseUI()
	Utils:DeleteUI("HuiShou.ZhuangBeiChongShengUI")
end

return ZhuangBeiChongShengUI

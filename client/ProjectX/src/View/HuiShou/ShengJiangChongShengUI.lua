local ShengJiangChongShengUI = LUIBase:New()
ShengJiangChongShengUI.__index = ShengJiangChongShengUI

ShengJiangChongShengUI.IsHideInBattle = true
local EVERYLINENUM = 5
function ShengJiangChongShengUI:New()
    local o = {}
    setmetatable(o, ShengJiangChongShengUI)
    o:Init()
    return o
end

function ShengJiangChongShengUI:RegistMsgs()
    self.msgIds = 
    {
        LHuiShouEvent.SelectShengJiang,
		LHuiShouEvent.ShengJiangChaXun,
		LHuiShouEvent.ShengJiangChongSheng
    }
    self:RegistSelf(self, self.msgIds)
end

function ShengJiangChongShengUI:ProcessEvent(msg)
	if msg.msgId == LHuiShouEvent.SelectShengJiang then
		self:UpdatePetInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.ShengJiangChaXun then
		self:UpdateRewardInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.ShengJiangChongSheng then
		self:ResetUI()
	end
end

function ShengJiangChongShengUI:Init()
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self.canchongsheng = true
	self:RegistMsgs()
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
end

function ShengJiangChongShengUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/shenjiangchongsheng.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function ShengJiangChongShengUI:InUIControl()
	local shenjiangchongsheng = self.m_pUILayer:getChildByName("shenjiangchongshengUI")
	local bglayer = shenjiangchongsheng:getChildByName("bg")
	self.chongsheng = shenjiangchongsheng:getChildByName("chongsheng")
	self.chongsheng:setVisible(false)
	local attrstarlist = self.chongsheng:getChildByName("shuxing"):getChildByName("Atrribute_3"):getChildByName("StarList")
	self.attrstar = attrstarlist:getChildByName("Star")
	self.attrstar:removeFromParent()
	self.attrstar:retain()
	self.addBtn = bglayer:getChildByName("Btn_add")
	self.addBtn:addClickEventListener(handler(self,ShengJiangChongShengUI.OpenShenJiangChooseUI))
	self.img = bglayer:getChildByName("Image1")
	self.modelNode = bglayer:getChildByName("Image"):getChildByName("ModelNode")
	self.starList = bglayer:getChildByName("StarList")
	self.starList:setVisible(false)
	self.star = self.starList:getChildByName("Star")
	self.star:removeFromParent()
	self.star:retain()
	self.name = bglayer:getChildByName("Name")
	self.name:setVisible(false)
	self.changeBtn = bglayer:getChildByName("Btn_Change")
	self.changeBtn:addClickEventListener(handler(self,ShengJiangChongShengUI.OpenShenJiangChooseUI))
	self.changeBtn:setVisible(false)
	self.tipText = shenjiangchongsheng:getChildByName("Text")
	self.tipText:setVisible(true)

	local chongshengBtn = self.chongsheng:getChildByName("Btn_chongsheng")
	chongshengBtn:addClickEventListener(handler(self,ShengJiangChongShengUI.onChongShengClicked))
	self:MarkIntaractCObj(chongshengBtn)

	local fanhuan = self.chongsheng:getChildByName("fanhuan")
	self.tableviewPanel = fanhuan:getChildByName("TableView")
	self.itemlist = fanhuan:getChildByName("ItemList")
	self.itemlist:setVisible(false)
	self.item = fanhuan:getChildByName("Item")
	self.item:setVisible(false)
	self:InitTableView()
end

function ShengJiangChongShengUI:ResetUI()
	self.chongsheng:setVisible(false)
	self.name:setVisible(false)
	self.changeBtn:setVisible(false)
	self.starList:setVisible(false)
	self.img:setVisible(true)
	self.addBtn:setVisible(true)
	self.tipText:setVisible(true)
	self.modelNode:removeAllChildren()
end

function ShengJiangChongShengUI:UpdatePetInfo(petId)
	print("===========UpdatePetInfo==============>", petId)
	if self.m_pPetId == petId then
		return
	end

	self.m_pPetId = petId
	LuaNetSendMsg:SendPetChongSheng(8, petId)
	local petlist = LRoleDataMgr.Pet.petlist
	local data = nil
	for i=1, #petlist do
		if petlist[i].id == petId then
			data = petlist[i]
			break
		end
	end

	self.tipText:setVisible(false)
	self.addBtn:setVisible(false)
	self.img:setVisible(false)
	self.changeBtn:setVisible(true)
	self.modelNode:removeAllChildren()
	self.m_pModelAni = ModelAniNode:create(AppDef.CEnum.ModelAniType.MonsterBig,0)
	self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.MonsterBig, data.baseData.pic)
	self.modelNode:addChild(self.m_pModelAni)
	self.m_pModelAni:PlayStand(0)
	
	self.starList:setVisible(true)
	self.starList:removeAllItems()
	local starSize = self.star:getContentSize()
	self.starList:setContentSize(cc.size(starSize.width * data.star, starSize.height))
	for i=1, data.star do
		local starclone = self.star:clone()
		self.starList:pushBackCustomItem(starclone)
	end

	self.name:setVisible(true)
	self.name:setString( string.format("%d级  %s  +%d", data.level, data.name, data.breakLevel) )

	self.chongsheng:setVisible(true)

	local shuxing = self.chongsheng:getChildByName("shuxing")
	local attr1 = shuxing:getChildByName("Atrribute_1"):getChildByName("Value_1")
	attr1:setString( string.format("%d级", data.level))
	local attr2 = shuxing:getChildByName("Atrribute_2"):getChildByName("Value_1")
	attr2:setString( string.format("+%d", data.breakLevel))
	--local attr3 = shuxing:getChildByName("Atrribute_3"):getChildByName("Value_1")
	--attr3:setString( string.format("%d级", data.star))
	local starlist = shuxing:getChildByName("Atrribute_3"):getChildByName("StarList")
	for i=1, data.star do
		local attrstarclone = self.attrstar:clone()
		starlist:pushBackCustomItem(attrstarclone)
	end
	--重生消耗
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

function ShengJiangChongShengUI:UpdateRewardInfo(data)
	self.m_pRewardList = data
	--资源返还
	self.m_pTableView:reloadData()
end

function ShengJiangChongShengUI:InitTableView()
	local tableView = cc.TableView:create(self.tableviewPanel:getContentSize())
    tableView:setContentSize(self.tableviewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	tableView:setBounceable(false)
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

function ShengJiangChongShengUI:TableCellAtIndex(sender, idx)
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
		for i=1, EVERYLINENUM do
			local index = idx * EVERYLINENUM + i
			local data = self.m_pRewardList[index]
			if data ~= nil then
				local itemNode = self.item:clone()
				itemNode:setVisible(true)
				itemNode:setName("Item"..i)
				itemNode:setTag(index)
				local pitem = Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
				pitem:setSwallowTouches(false)
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

function ShengJiangChongShengUI:onChongShengClicked(sender)
	if self.canchongsheng == false then
		Utils:ShowScrollTips(GUITips.RSI_LD_TIP11)
		return
	end

	local data = {}
	data.petid = self.m_pPetId
	data.fanhuanlist = self.m_pRewardList
	Utils:OpenFunction(AppDef.EModuleID.EMID_CHONGSHENG_CONFIRM, data)
end

function ShengJiangChongShengUI:OpenShenJiangChooseUI()
	Utils:OpenFunction(AppDef.EModuleID.EMID_SHENJIANG_CHOOSE)
end

function ShengJiangChongShengUI:SetVisible(isShow)
	self.m_pUILayer:setVisible(isShow)
end

function ShengJiangChongShengUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function ShengJiangChongShengUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function ShengJiangChongShengUI:CloseUI()
	Utils:DeleteUI("HuiShou.ShengJiangChongShengUI")
end

return ShengJiangChongShengUI
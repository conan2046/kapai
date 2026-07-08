local QiangHuaDaShiUI = LUIBase:New()
QiangHuaDaShiUI.__index = QiangHuaDaShiUI

QiangHuaDaShiUI.IsHideInBattle = true
function QiangHuaDaShiUI:New(data)
    local o = {}
    setmetatable(o, QiangHuaDaShiUI)
    o:Init(data)
    return o
end

function QiangHuaDaShiUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFClassBgEvent.UpdateUI
    }
    self:RegistSelf(self, self.msgIds)
end

function QiangHuaDaShiUI:ProcessEvent(msg)
	if msg.msgId == LUIFClassBgEvent.UpdateUI then
		self:UpdateUI()
	end
end

function QiangHuaDaShiUI:Init(data)
	-- dump(data,"=========QiangHuaDaShiUI==========>")
	self.m_qhInd = data.ind or 1
	self.curPetPos = data.fightPos
	
	self.shenjiangNodeList = {}
	self.equipNodeList = {}
	self.equipIcons = {}
	self:RegistMsgs()
	self:InitViewSize()
	self:InUIControl()
	self:LoadData()
	self:setCloseCallback()
end

function QiangHuaDaShiUI:InitViewSize()
	self:CreateUINode("csd/zhuangbeiyangcheng/qianghuadashi.csb")

    self.m_pQiangHuaLayer = self.m_pUILayer
 --     = cc.Node:create()
	-- self.m_pUILayer:setContentSize(AppDef.frameSize)
	-- self.m_pQiangHuaLayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/qianghuadashi.csb")
	-- ccui.Helper:doLayout(self.m_pQiangHuaLayer)
	-- self.m_pUILayer:addChild(self.m_pQiangHuaLayer)
 --    ccui.Helper:doLayout(self.m_pUILayer)
end

function QiangHuaDaShiUI:InUIControl()
	Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_QiangHuaDaShi_Title)
	local function tabBtnClicked(ind)
		self:TabClicked(ind)
    end
	self.tabNames = {GUITips.RSI_Equip_QiangHua, GUITips.RSI_Equip_JingLian,GUITips.RSI_Equip_JueXing,GUITips.RSI_Equip_ShenZhou,GUITips.RSI_FaBao_QiangHua,GUITips.RSI_FaBao_JingLian}
	--self.tabNames = {GUITips.RSI_QHDS_Equip_QiangHua, GUITips.RSI_QHDS_Equip_JingLian,GUITips.RSI_QHDS_Equip_JueXing,GUITips.RSI_QHDS_Equip_ShenZhou,GUITips.RSI_QHDS_FaBao_QiangHua,GUITips.RSI_QHDS_FaBao_JingLian}
	self.tipNames = {GUITips.RSI_Equip_QiangHua, GUITips.RSI_Equip_JingLian,GUITips.RSI_Equip_JueXing,GUITips.RSI_Equip_ShenZhou,GUITips.RSI_FaBao_QiangHua,GUITips.RSI_FaBao_JingLian}
	self.btnNames = {GUITips.RSI_Button_Equip_Qianghua,GUITips.RSI_Button_Equip_JingLian,GUITips.RSI_Button_Equip_JueXing,GUITips.RSI_Button_Equip_ShenZhou,GUITips.RSI_Button_FaBao_QiangHua,GUITips.RSI_Button_FaBao_JingLian}
	local tabValues = 
    {
        self.tabNames,
        tabBtnClicked
    }
	self.attrNames = {GUITips.RSI_QHDS_ATTR1,GUITips.RSI_QHDS_ATTR2,GUITips.RSI_QHDS_ATTR3,GUITips.RSI_QHDS_ATTR4}
    Utils:SendMsg(LUIPopFClassBgEvent.AddTabBtn, tabValues)

    Utils:SendMsg(LUIPopFClassBgEvent.SelectTab, self.m_qhInd)
	
	local qianghuadashilayer = self.m_pQiangHuaLayer:getChildByName("qianghuadashi_layer")
	local shenjianglist = qianghuadashilayer:getChildByName("shenjianglist")

	for i=1, 5 do
		local shenjiangNode = shenjianglist:getChildByName("shenjiang"..i)
		table.insert(self.shenjiangNodeList, shenjiangNode)
		local hero = shenjiangNode:getChildByName("hero")
		hero:addClickEventListener(handler(self,QiangHuaDaShiUI.onPetClicked))
		self:MarkIntaractCObj(hero)
	end

	local itemlist = qianghuadashilayer:getChildByName("ItemList")
	for i=1, 4 do
		local itemNode = itemlist:getChildByName("Item"..i)
		table.insert(self.equipNodeList, itemNode)
		local qhBtn = itemNode:getChildByName("Btn_yangcheng")
		qhBtn:addClickEventListener(handler(self,QiangHuaDaShiUI.onGoUpgradeClicked))
		self:MarkIntaractCObj(qhBtn)
	end
	local shuxinglayer = qianghuadashilayer:getChildByName("shuxinglayer")
	self.leftLayer = shuxinglayer:getChildByName("left_layer")
	self.rightLayer = shuxinglayer:getChildByName("right_layer")
end

function QiangHuaDaShiUI:LoadData()
	self.m_pPetList = {}
    --for i=1, #LRoleDataMgr.Pet.petlist do
    --    local petData = LRoleDataMgr.Pet.petlist[i]
    --    if petData.fightPos > 0 then
    --        self.m_pPetList[petData.fightPos] = petData
    --    else
    --        break
    --    end
    --end
	local petlist = LRoleDataMgr.Pet.ShowPosList
	for i=1,#petlist do
		if petlist[i] ~= 0 then
			local petData = LRoleDataMgr.Pet:GetPetByFightPos(i)
			self.m_pPetList[i] = petData
		end
	end
	for j = 1, #self.shenjiangNodeList do
		if self.m_pPetList[j] then
			self.shenjiangNodeList[j]:setVisible(true)
			self:InitShengJiangNode(j, self.shenjiangNodeList[j],self.m_pPetList[j])
		else
			self.shenjiangNodeList[j]:setVisible(false)
		end
	end
	self.m_pMasterLevels = {0,0,0,0,0,0}
	local data = LRoleDataMgr.Pet.masterList[self.curPetPos]
	local mastertypedata = data.masterTypeList
	for k,v in pairs(mastertypedata) do
		self.m_pMasterLevels[k] = v.lv
	end
	
    self:TabClicked(self.m_qhInd)
end

function QiangHuaDaShiUI:UpdateData()
	local equips = Utils:GetEquipsByfPos(self.curPetPos)
	local fabaos = Utils:GetFaBaoByfPos(self.curPetPos)
	local data = LRoleDataMgr.Pet.masterList[self.curPetPos]
	local mastertypedata = data.masterTypeList
	for k,v in pairs(mastertypedata) do
		self.m_pMasterLevels[k] = v.lv
	end
	if self.m_qhInd > 4 then
		self:UpdateFaBaoItem(fabaos)
	else
		self:UpdateEquipItem(equips)
	end
	self:updateAttr(self.m_qhInd)
end

function QiangHuaDaShiUI:UpdateUI()
	self:UpdateData()
end

function QiangHuaDaShiUI:InitShengJiangNode(ind, pItem, petData)
	local hero = pItem:getChildByName("hero")
	--hero:setTag(petData.fightPos)
	hero:setTag(ind)
	local headPanel = hero:getChildByName("bg_Head")
	local headImg = headPanel:getChildByName("icon")
	Utils:GetPetHeadCellValue(headImg, nil, petData,true)
	--Utils:ShowPetHeadImg(headImg, petData.baseData.pic, headPanel, petData.baseData.quality, petData:IsShiny())
	if self.curPetPos == ind then
		local choose = pItem:getChildByName("Choose")
		choose:setVisible(true)
	else
		local choose = pItem:getChildByName("Choose")
		choose:setVisible(false)
	end
end

function QiangHuaDaShiUI:UpdateEquipItem(equips)
	for i=1,#self.equipNodeList do
		local item = self.equipNodeList[i]
		item:setVisible(true)
		local uid = equips[i]
		item:setTag(i)
		local iconImg = item:getChildByName("Icon")
		local name = item:getChildByName("Name")
		local barlist = item:getChildByName("barlist")
		local expbar = barlist:getChildByName("EXPBar")
		local text = barlist:getChildByName("Text")
		local btnName =item:getChildByName("Btn_yangcheng"):getChildByName("Text")
		btnName:setString(self.btnNames[self.m_qhInd])
		local info = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
		if info ~= nil then
			local jxLv = info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
			local qhLv = info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
			local jlLv = info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
			local szLv = info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
			Utils:GetEquipCellValue(iconImg,self.equipIcons[i],info.m_id,uid,qhLv,jlLv,szLv,jxLv,false, true)
			name:setString(info.m_name)
			local masterlv = self.m_pMasterLevels[self.m_qhInd]
			local nextData = LDataConstMgr:GetMasterData(self.m_qhInd, masterlv + 1)
			if nextData then
				text:setString((info.cultivateLevel[self.m_qhInd] or 0) .."/"..nextData.condition)
				expbar:setPercent((info.cultivateLevel[self.m_qhInd] or 0)/nextData.condition)
			end
		end
	end
end

function QiangHuaDaShiUI:UpdateFaBaoItem(fabaos)
	for i=1,#self.equipNodeList do
		if i > 2 then
			self.equipNodeList[i]:setVisible(false)
		else
			local item = self.equipNodeList[i]
			local uid = fabaos[i + 4]
			item:setTag(i + 4)
			local iconImg = item:getChildByName("Icon")
			local name = item:getChildByName("Name")
			local barlist = item:getChildByName("barlist")
			local expbar = barlist:getChildByName("EXPBar")
			local text = barlist:getChildByName("Text")
			local btnName =item:getChildByName("Btn_yangcheng"):getChildByName("Text")
			btnName:setString(self.btnNames[self.m_qhInd])
			local info = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid]
			if info ~= nil then
				local qhLv = info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
				local jlLv = info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
				Utils:GetFaBaoCellValue(iconImg,self.equipIcons[i+4],info.m_id,uid,false,0,qhLv,jlLv,false, true)
				name:setString(info.m_name)
				local masterlv = self.m_pMasterLevels[self.m_qhInd]
				local nextData = LDataConstMgr:GetMasterData(self.m_qhInd, masterlv + 1)
				if nextData then
					text:setString((info.cultivateLevel[self.m_qhInd] or 0) .."/"..nextData.condition)
					expbar:setPercent((info.cultivateLevel[self.m_qhInd] or 0)/nextData.condition)
				end
			end
		end
	end
end

function QiangHuaDaShiUI:updateAttr(ind)
	local masterlevel = self.m_pMasterLevels[ind]
	--left
	local left_typename = self.leftLayer:getChildByName("type")
	left_typename:setString(self.tabNames[ind])
	local left_value = left_typename:getChildByName("Value")
	left_value:setString(string.format(GUITips.UI_Text_Level_Index, masterlevel))
	local left_attrNodes = {}
	local defaultData = LDataConstMgr:GetMasterData(ind, 1)
	local attrs = defaultData.attr
	for i = 1,4 do
		local attr = self.leftLayer:getChildByName("Attribute"..i)
		if i <= #attrs and masterlevel == 0 then
			attr:setVisible(false):setVisible(true)
			local attrcfg = JsonConfig.m_AttrType.getDefByID(attrs[i][1])
			attr:setString(string.format(GUITips.RSI_QHDS_ATTR, attrcfg.attrName))
			local value = attr:getChildByName("Value")
			if attrs[i][1] > 9 then
				value:setString(string.format("%d%%", 0))
			else
				value:setString("0")
			end
		else
			attr:setVisible(false)
		end
		table.insert(left_attrNodes, attr)
	end

	if masterlevel > 0 then
		local leftData = LDataConstMgr:GetMasterData(ind, masterlevel)
		if leftData then
			local attrs = leftData.attr
			for i = 1,#left_attrNodes do
				if i <= #attrs then
					local attrcfg = JsonConfig.m_AttrType.getDefByID(attrs[i][1])
					left_attrNodes[i]:setVisible(true)
					left_attrNodes[i]:setString(string.format(GUITips.RSI_QHDS_ATTR, attrcfg.attrName))
					local value = left_attrNodes[i]:getChildByName("Value")
					if attrs[i][1] > 9 then
						value:setString(string.format("%d%%", attrs[i][2] / 100))
					else
						value:setString(attrs[i][2])
					end
				end
			end
		end
	end

	--right
	local right_typename = self.rightLayer:getChildByName("type")
	right_typename:setString(self.tabNames[ind])
	local right_value = right_typename:getChildByName("Value")
	right_value:setString(string.format(GUITips.UI_Text_Level_Index, masterlevel + 1))
	local right_attrNodes = {}
	for i = 1,4 do
		local attr = self.rightLayer:getChildByName("Attribute"..i)
		attr:setVisible(false)
		table.insert(right_attrNodes, attr)
	end
	local rightData = LDataConstMgr:GetMasterData(ind, masterlevel + 1)
	local tipslayer = self.rightLayer:getChildByName("tips_layer")
	tipslayer:setString(string.format(GUITips.RSI_QHDS_TIPS, self.tipNames[ind], rightData.condition))
	if rightData then
		local attrs = rightData.attr
		for i = 1,#right_attrNodes do
			if i <= #attrs then
				local attrcfg = JsonConfig.m_AttrType.getDefByID(attrs[i][1])
				right_attrNodes[i]:setVisible(true)
				right_attrNodes[i]:setString(string.format(GUITips.RSI_QHDS_ATTR, attrcfg.attrName))
				local value = right_attrNodes[i]:getChildByName("Value")
				if attrs[i][1] > 9 then
					value:setString(string.format("%d%%", attrs[i][2] / 100))
				else
					value:setString(attrs[i][2])
				end
			end 
		end
	end
end

function QiangHuaDaShiUI:TabClicked(ind)
	if ind > 4 then
		local fabaos = Utils:GetFaBaoByfPos(self.curPetPos)
		if table.length(fabaos) < 2 then
			Utils:ShowScrollTips(GUITips.RSI_QiangHuaDaShi_FaBao_Open)
			Utils:SendMsg(LUIPopFClassBgEvent.SelectTab, self.m_qhInd)
			return
		end
	else
		local equips = Utils:GetEquipsByfPos(self.curPetPos)
		if table.length(equips) < 4 then
			Utils:ShowScrollTips(GUITips.RSI_QiangHuaDaShi_Equip_Open)
			Utils:SendMsg(LUIPopFClassBgEvent.SelectTab, self.m_qhInd)
			return
		end
	end
	self.m_qhInd = ind
	self:UpdateData()
end

function QiangHuaDaShiUI:onPetClicked(sender)
	local pos = sender:getTag()
	if pos == self.curPetPos then
		return;
	end
	local fabaos = Utils:GetFaBaoByfPos(pos)
	local equips = Utils:GetEquipsByfPos(pos)
	if table.length(equips) == 4 then
		self.m_qhInd = 1
	elseif table.length(fabaos) == 2 then
		self.m_qhInd = 5
	else
		Utils:ShowScrollTips(GUITips.RSI_QiangHuaDaShi_Open)
		return
	end
	Utils:SendMsg(LUIPopFClassBgEvent.SelectTab, self.m_qhInd)
	self.curPetPos = pos
	local mastertypedata = LRoleDataMgr.Pet.masterList[self.curPetPos].masterTypeList
	for k,v in pairs(mastertypedata) do
		self.m_pMasterLevels[k] = v.lv
	end
	for i = 1, #self.shenjiangNodeList do
		local pitem = self.shenjiangNodeList[i]
		local choose = pitem:getChildByName("Choose")
		if pos == i then
			choose:setVisible(true)
		else
			choose:setVisible(false)
		end
	end
	self:UpdateData()
end	

function QiangHuaDaShiUI:onGoUpgradeClicked(sender)
	local index = sender:getParent():getTag()
	if self.m_qhInd > 4 then
		local fabaos = Utils:GetFaBaoByfPos(self.curPetPos)
		--Utils:HideUI("Activity.QiangHuaDaShiUI")
		Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA, {self.m_qhInd - 4 , fabaos[index]})
		self:CloseMasterUI()
	else
		local equips = Utils:GetEquipsByfPos(self.curPetPos)
		--Utils:HideUI("Activity.QiangHuaDaShiUI")
		Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH, {self.m_qhInd, equips[index]})
		self:CloseMasterUI()
	end

end

function QiangHuaDaShiUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, QiangHuaDaShiUI.CloseMasterUI))
end

function QiangHuaDaShiUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pQiangHuaLayer = nil
end

function QiangHuaDaShiUI:CloseMasterUI()
    Utils:DeleteUI("Activity.QiangHuaDaShiUI")
end

return QiangHuaDaShiUI
--[[
lua里面的游戏逻辑控制
]]


local EquipCultivateMainUI = LUIBase:New()
EquipCultivateMainUI.__index = EquipCultivateMainUI
--local this = LTcpSocket
function EquipCultivateMainUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,EquipCultivateMainUI)   
    o:Init(userData)
    return o
end

function EquipCultivateMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleEquipChangeEvent.EquipeShuaXin,
        LUIRoleEquipChangeEvent.EquipeJXCost,
    }
    self:RegistSelf(self, self.msgIds)

end

function EquipCultivateMainUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleEquipChangeEvent.EquipeShuaXin then
        local data = msg.value
        --local equip = LRoleDataMgr.Pet.equipList.m_petEquips[data.uid]
        --local curLevel = equip.cultivateLevel[data.atype] or 0
        --equip.cultivateLevel[data.atype] = curLevel + data.addlevel
        --if self.m_uid == data.uid then
            self:UpdateData(true)
            self:UpdateSelectEquip()
            self:showPetEquipList()
			self:ShowEffectAnim()
        --end
        if data.atype == 4 then
            --self:ShowAni()
        end
        if self.m_curUIInd == 1 then
            Utils:CheckGuide(GuideDef.StepId.Guide_Equip_8,true)
        end
		self:UpdateRedDotUI()
    end
    if msg.msgId == LUIRoleEquipChangeEvent.EquipeJXCost then
        self:ShowJuexingCost(msg.value)
    end
end

function EquipCultivateMainUI:Init(userData)
    self:InitMembers(userData)
    self:FunctionRegister(userData[1])
    self:UpdateSelectEquip()
    self:showPetEquipList()
    self:RegistMsgs()
    self:RegisterGuide()
	self:UpdateRedDotUI()
end

function EquipCultivateMainUI:InitMembers(userData)
    self:CreateUINode("csd/zhuangbeiyangcheng/zhuangbeiyangcheng.csb");
    self._bg = self.m_pUILayer
    -- self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_uid =  0
    if userData ~= nil then
        self.m_uid = userData[2] or 0
    end

    -- dump(userData, "EquipCultivateMainUI:InitMembers ==== 1111>> ")

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    -- self._bg = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeiyangcheng.csb")

    -- self._bg:setPosition(cc.p(0, 0))
    -- self.m_pUILayer:addChild(self._bg)
    self.headNode = self._bg:getChildByName("zhuangbeiyangchengUI")
    local zhuangbeiBg = self.headNode:getChildByName("zhuangbei")
	zhuangbeiBg:setTouchEnabled(false)

    local bg = zhuangbeiBg:getChildByName("Bg")
    self._Bg1 = bg:getChildByName("Bg_1")
    self._Bg2 = bg:getChildByName("Bg_2")
    self._Bg2:setVisible(false)
	self._Bg3 = bg:getChildByName("Image_1")

    self.selectBg = zhuangbeiBg:getChildByName("Panel_zhujue")
    self.headIcon = self.selectBg:getChildByName("Icon")
    self.leftBtn = self.selectBg:getChildByName("Button_L")
    self.rightBtn = self.selectBg:getChildByName("Button_R")
    self.shenzhuGroup = zhuangbeiBg:getChildByName("shenzhu")
    self.shenzhuGroup:setSwallowTouches(false)
    self.juexingGroup = zhuangbeiBg:getChildByName("juexing")
  
    self.qianghuaBtn = zhuangbeiBg:getChildByName("Btn_yijianqianghua")
	local function OneKeyStrongBtnCallback(sender)
		local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
		local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_uid]
		local curLevel = equip.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
		local nextLevel = curLevel
		if nextLevel < #JsonConfig.m_equip_qianghua.getList() then nextLevel = nextLevel + 1 end
		local scfg = JsonConfig.m_equip_qianghua.getDefByID(nextLevel)
		if LRoleDataMgr.MyHeroInfo.equip_fenjie_tips == false then
			if money < scfg.cost[3] then
				Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
				return
			end
			LuaNetSendMsg:SendEquipAutoQiangHua(self._selectPos)
		else
			local function okFunc()
				if money < scfg.cost[3] then
					Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
					return
				end
				LuaNetSendMsg:SendEquipAutoQiangHua(self._selectPos)
				end
				local function cancelFunc()
			end
			Utils:ShowOneKeyStrengthDialog(GUITips.UI_Equip_Strongth_tips,GUITips.UI_Equip_Title_tips,okFunc,cancelFunc);
		end
	end
    self.qianghuaBtn:addClickEventListener(OneKeyStrongBtnCallback)
    self:MarkIntaractCObj(self.qianghuaBtn)
    self.equipNode = zhuangbeiBg:getChildByName("Node")
    self._equipIcon = zhuangbeiBg:getChildByName("equip")
    self.equipName = zhuangbeiBg:getChildByName("Name")
    self._addNum = self.equipName:getChildByName("addnum")
    local jxList = self.juexingGroup:getChildByName("List_juexing")
    self._jxListView = ccui.ListView:create()
    self._jxListView:setDirection(LISTVIEW_DIR_HORIZONTAL)
    self._jxListView:setContentSize(jxList:getContentSize())
    self._jxListView:setAnchorPoint(cc.p(0, 0))
    self._jxListView:setPosition(cc.p(0, 0))
    -- 关闭惯性滑动
    self._jxListView:setBounceEnabled(false)
    self._jxListView:setSwallowTouches(false)
    -- 设置间距
    self._jxListView:setItemsMargin(2)
    -- 隐藏滚动条
    self._jxListView:setScrollBarEnabled(false)
    jxList:addChild(self._jxListView)

    self._itemCell = jxList:getChildByName("Item")
    self._itemCell:removeFromParent()
    self._itemCell:retain()

    self.yijianDuihuan = self.juexingGroup:getChildByName("Btn_yijianshengxing")
    self.duihuanBtn = self.juexingGroup:getChildByName("Btn_yijianduihuan")

    self.teXiaoBtn = self.shenzhuGroup:getChildByName("Btn_shenzhutexiao")
    self.shengJieBtn = self.shenzhuGroup:getChildByName("Btn_yijianshengjie")
    self.shengCengBtn = self.shenzhuGroup:getChildByName("Btn_yijianshengceng")

    self._level_text = zhuangbeiBg:getChildByName("level_text"):getChildByName("levelnum")

    self._EquipList = zhuangbeiBg:getChildByName("List")
    self._EquipCell = self._EquipList:getChildByName("item_layer")

    self._EquipCell:removeFromParent()
    self._EquipCell:retain()


    self._selectPos = 1

    self:BtnStateCheck()
    local function leftEvent( sender )
        local next = self._selectPos - 1
        if next < 1 then
            next = 5
        end
        local list, pos = self:GetPosEquipList(next, -1)
        print("addClickEventListener pos ======>", pos, self._selectPos)
        if self._selectPos == pos then
            return
        end
        self._selectPos = pos

        self:ChangeSelectPet(self._selectPos)
        --排序
        self.m_uid = list[1].m_uid
        self.selectEquipId = list[1].m_id
        self:UpdateSelectEquip()
        self:showPetEquipList(list)
        self:UpdateData()
    end
    self.leftBtn:addClickEventListener(leftEvent)

    local function rightEvent( sender )
        local next = self._selectPos + 1
        if next > 5 then
            next = 1
        end
        local list, pos = self:GetPosEquipList(next, 1)

        if self._selectPos == pos then
            return
        end
        self._selectPos = pos
        self:ChangeSelectPet(self._selectPos)
        self.m_uid = list[1].m_uid
        self.selectEquipId = list[1].m_id
        self:UpdateSelectEquip()
        self:showPetEquipList(list)
        self:UpdateData()
    end
    self.rightBtn:addClickEventListener(rightEvent)
	self.m_pEffectNodes = {}
	for i = 1,9 do
		local effectnode = zhuangbeiBg:getChildByName("effect_zhuangbeiyangcheng_"..i)
		table.insert(self.m_pEffectNodes, effectnode)
	end
end

function EquipCultivateMainUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Equip_8)
    self:Destory()
    self.m_pUILayer = nil
    for i = 1,4 do
        self.m_pSubLayer[i] = nil
    end
    self.m_pSubLayer = nil
    self.m_curUIInd = nil
    self._bg = nil
    self.headNode = nil
    self.heroList = nil
    self.shenzhuGroup = nil
    self.juexingGroup = nil
    self.qianghuaBtn = nil
    self.equipNode = nil
    self.equipName = nil
    --self.showEquip = nil
    self.headImg = nil
    self.headIcon = nil
    self.selectIdx = nil
    self._selectPos = nil
    self.jxList = nil
    self.yijianDuihuan = nil
    self.duihuanBtn = nil
    self.teXiaoBtn = nil
    self.shengJieBtn = nil
    self.shengCengBtn = nil
    Utils:CheckGuide(GuideDef.StepId.Guide_Equip_9)
end

function EquipCultivateMainUI:BtnStateCheck()

end

function EquipCultivateMainUI:ChangeSelectPet(selectPos)
    local pet = LRoleDataMgr.Pet:GetPetByFightPos(selectPos)
    if pet ~= nil then
        self.headIcon:setVisible(true)
        Utils:ShowPetHeadImg(self.headIcon, pet.baseData.pic, self.headImg, pet.baseData.quality, pet:IsShiny())
        -- self:UpdateListView()
        -- self:UpdateSelectEquip()
    else
        self.headIcon:setVisible(false)
    end
end

function EquipCultivateMainUI:FunctionRegister( openTab )
    if  LRoleDataMgr.m_bIsCrossServer==true then 
       LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_KuafuWorldMap)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    else

      LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.Item_Info_EquipType4)
      self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

   
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "EquipCultivate.EquipCultivateMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
		Utils:ShowUI("Activity.QiangHuaDaShiUI")
		Utils:SendMsg(LUIRedDotEvent.UpdateRedDotState, {id = RedDotDef.ID.EquipZhenRong})
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)                                                                                                                                                                                                                                                                                                                                                       
        self:TabClicked(ind)
    end

    local tabValues = 
    {
        {
            GUITips.RSI_ZQX_QEUIP_CULTIVATE1,
            GUITips.RSI_ZQX_QEUIP_CULTIVATE2,
            GUITips.RSI_ZQX_QEUIP_CULTIVATE3,
            GUITips.RSI_ZQX_QEUIP_CULTIVATE4,
        },
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local ind = 1
    if openTab ~= nil and openTab > 0 then
        ind = openTab
    end

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, ind)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(ind)
end

function EquipCultivateMainUI:UpdateData(change)
    -- body
    --更新数据
    if self.m_pSubLayer[self.m_curUIInd].UpdateData ~= nil then
        self.m_pSubLayer[self.m_curUIInd]:UpdateData(self.m_uid, change)
    end
end

function EquipCultivateMainUI:TabClicked(ind)
    if self.m_curUIInd == ind then
        return
    end
	local data = self:CheckFunction(ind)
	if data[1] == false then
		Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2,data[2]))
		LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
		self:SendMsg(LGameMsg.m_baseMsgWithOne)
		return
	end
	--需要先判断装备的品质 神铸是红色以上 觉醒是橙色以上
	local info = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_uid]
	if ind == 3 then
		if info.m_quality < 5 then
			Utils:ShowScrollTips(GUITips.UI_Equip_JueXing_tips)
			LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
			return
		end
	elseif ind == 4 then
		if info.m_quality < 6 then
			Utils:ShowScrollTips(GUITips.UI_Equip_ShenZhu_tips)
			LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
			return
		end
	end

    local function goBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        Utils:ShowScrollTips(GUITips.RSI_MAP_TIPS_1)
    end

    local currMapSid = LRoleDataMgr.MyHeroInfo.sid
    if currMapSid == 47 and ind == 1 then
        goBack(self.m_curUIInd)
        return
    end    

    if self.m_curUIInd ~= 0 then
		self:HideEffectAnim()
		self:HideCurUI()
    end
     self.m_curUIInd = ind
  
     self:ShowCurUI()
end

function EquipCultivateMainUI:CheckFunction(ind)
	local level = LRoleDataMgr.MyHeroInfo.level
	local func = nil
	if ind == 1 then
		func = JsonConfig.m_functionConfig.getDefByID(1120)
	elseif ind == 2 then
		func = JsonConfig.m_functionConfig.getDefByID(1130)
	elseif ind == 3 then
		func = JsonConfig.m_functionConfig.getDefByID(1140)
	elseif ind == 4 then
		func = JsonConfig.m_functionConfig.getDefByID(1150)
	end
	if func~= nil and level < func.open_condition[1][2] then
		return {false, func.open_condition[1][2]}
	end
	return {true}
end

function EquipCultivateMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function EquipCultivateMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
      
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
	if self.m_curUIInd == 1 then
		self.shenzhuGroup:setVisible(false)
        self.juexingGroup:setVisible(false)
        self.qianghuaBtn:setVisible(true)
	elseif self.m_curUIInd == 2 then
		self.shenzhuGroup:setVisible(false)
        self.juexingGroup:setVisible(false)
		self.qianghuaBtn:setVisible(false)
    elseif self.m_curUIInd == 3 then
        self:ShowJuexing()
    elseif self.m_curUIInd == 4 then
        self:ShowShenZhu()
		self:ShowEffectAnim()
        --self:ShowAni()
    end
end

function EquipCultivateMainUI:DelayLoadSubUI(tabInd)
    local uinames = {
        "View.EquipCultivate.EquipStrongUpUI",
        "View.EquipCultivate.CultivateJingLianUI",
        "View.EquipCultivate.CultivateJueXingUI",
        "View.EquipCultivate.CultivateShenZhuUI",
        }
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        self:UpdateData()
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function EquipCultivateMainUI:GetPosEquipList(Pos, dir)
    -- body
    local EquipList = {}
    for k,v in pairs(LRoleDataMgr.Pet.equipList.m_petEquips) do
        if v.m_fpos == Pos then
            table.insert(EquipList, v)
        end
    end

    if #EquipList > 0 then
        table.sort(EquipList, function ( a, b )
            -- body
            return a.m_wpos < b.m_wpos
        end)
        return EquipList, Pos
    else
        local next = Pos + dir
        if next > 5 then
            next = 1
        end
        if next < 1 then
            next = 5
        end
        return self:GetPosEquipList(next, dir)
    end
end

function EquipCultivateMainUI:UpdateSelectEquip()
    if self.m_uid == 0 then
        --self.showEquip:UpdateItem(nil)
        return
    end
    local info = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_uid]
    if info == nil or info.m_id == 0 then
        --self.showEquip:UpdateItem(nil)
        return
    end
    local cfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
    if cfg == nil then
        return
    end
    local qhLevel = info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
    local petEquipData = {
        id = info.m_id,
        star = info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0,
        qhLv = qhLevel,
        jlLv = info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0,
        szLv = info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0,
    }
    self._equipIcon:removeAllChildren()
	--Utils:GetEquipCellValue(self._equipIcon,nil,info.m_id,info.m_uid,0,0,0,0,false,false,false)
    --Utils:GetEquipCellValueVec2(self._equipIcon, nil, info, true, true, false)
	local path = "item/"..cfg.pic..".png"
    Utils:SafeLoadTexture(self._equipIcon, path, ccui.TextureResType.localType)
	if self.m_curUIInd == 1 then
		self.qianghuaBtn:setVisible(info.m_fpos ~= 0)
	end
    self.equipName:setString(info.m_name)
    self._addNum:setString("+"..tostring(petEquipData.jlLv))
    self._level_text:setString(string.format(GUITips.UI_Text_Level_Index, qhLevel))

    self._selectPos = info.m_fpos
    self.selectEquipId = info.m_id
    local petData = LRoleDataMgr.Pet:GetPetByFightPos(info.m_fpos)
	if petData ~= nil then
		Utils:ShowPetHeadImg(self.headIcon, petData.baseData.pic, headPanel, petData.baseData.quality, petData:IsShiny())
	else
		self._EquipList:setVisible(false)
		self._Bg3:setVisible(false)
		self.selectBg:setVisible(false)
	end
end

function EquipCultivateMainUI:GetPetEquipList( ... )
    -- body
    local petEquip = PetkaPaiManager:getPetEquipByPos(self._selectPos)
    return petEquip
end

function EquipCultivateMainUI:showPetEquipList(petEquip)
    -- body

    if petEquip == nil then
        petEquip = self:GetPetEquipList()
    end
    
    if petEquip == nil then
        return
    end

    self._EquipList:removeAllItems()
    for i=1, #petEquip do
        local item = self._EquipCell:clone()
        local equipData = petEquip[i]
        local choose = item:getChildByName("Choose")
        choose:setVisible(false)
        if self.selectEquipId == equipData.m_id then
            choose:setVisible(true)
            self._lastSelcet = item
        end
        local zhuangbeiIcon = item:getChildByName("zhuangbeiIcon")
        print("EquipCultivateMainUI ===>", equipData.m_id)
        Utils:GetEquipCellValueVec2(zhuangbeiIcon, nil, equipData, false, true)
        item.userObject = equipData.m_uid
        self._EquipList:pushBackCustomItem(item)
        item:addClickEventListener(handler(self, EquipCultivateMainUI.EquipSelectEvent))
    end

end

function EquipCultivateMainUI:EquipSelectEvent( sender )
    -- body
    local uid = sender.userObject
    print("EquipSelectEvent ====>", uid)
	local info = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
	if self.m_curUIInd == 3 then
		if info.m_quality < 5 then
			Utils:ShowScrollTips(GUITips.UI_Equip_JueXing_tips)
			return
		end
	elseif self.m_curUIInd == 4 then
		if info.m_quality < 6 then
			Utils:ShowScrollTips(GUITips.UI_Equip_ShenZhu_tips)
			return
		end
	end

    if self._lastSelcet ~= nil then
        self._lastSelcet:getChildByName("Choose"):setVisible(false)
    end
    sender:getChildByName("Choose"):setVisible(true)
    self._lastSelcet = sender
    self.m_uid = uid

    self:UpdateData(false)
    self:UpdateSelectEquip()
	if self.m_curUIInd == 4 then
		self:ShowEffectAnim()
	end
end

function EquipCultivateMainUI:ShowJuexing()
    self.shenzhuGroup:setVisible(false)
    self.juexingGroup:setVisible(true)
    self.qianghuaBtn:setVisible(false)
    self.juexingGroup:setSwallowTouches(false)

    local function duihuanBtnCallBack()
        Utils:InitUI("EquipCultivate.CultivateDuiHuanUI", AppDef.UIType.PopWindow, uid)
    end
    self.duihuanBtn:addClickEventListener(duihuanBtnCallBack)
    self:MarkIntaractCObj(self.duihuanBtn)

    local function yijianDuihuanBtnCallBack()
        Utils:InitUI("EquipCultivate.EquipAutoStarUpUI", AppDef.UIType.PopWindow, uid)
        
    end
    self.yijianDuihuan:addClickEventListener(yijianDuihuanBtnCallBack)
    self:MarkIntaractCObj(self.yijianDuihuan)
end

function EquipCultivateMainUI:ShowJuexingCost(cost)
    self._jxListView:removeAllItems()
    if cost == nil or #cost < 0 then return end
    for i=1, #cost do
        local item = self._itemCell:clone()
        Utils:GetItemCellValue(item, 0, cost[i][1], true, true, cost[i][3], nil, false, false)
        item:getChildByName("Text_0"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5,
            cost[i][3], LRoleDataMgr.Equip:CountItemNumById(cost[i][1])))

        self._jxListView:pushBackCustomItem(item)
    end
end

function EquipCultivateMainUI:ShowShenZhu()
    self.shenzhuGroup:setVisible(true)
    self.juexingGroup:setVisible(false)
    self.qianghuaBtn:setVisible(false)

    self.m_pAniImod = {}
    for i=1,5 do
        local icon = self.shenzhuGroup:getChildByName(tostring(i))
        local size = icon:getContentSize()
        self.m_pAniImod[i] = ImodAnim:create()
        self.m_pAniImod[i]:setPosition(cc.p(size.width/2, size.height/2))
        local png = string.format(AppDef.GUIRes.Linqi_Fire_Format, 5-i, AppDef.GUIRes.Res_Suffix_Png)
        local ani = string.format(AppDef.GUIRes.Linqi_Fire_Format, 5-i, AppDef.GUIRes.Res_Suffix_Ani)
        self.m_pAniImod[i]:initAnimWithName(png, ani)
        icon:addChild(self.m_pAniImod[i],5,666)
    end

    local function teXiaoBtnCallBack()
        Utils:InitUI("EquipCultivate.ShenZhuTeXiaoUI", AppDef.UIType.PopWindow, self.m_uid)
    end
    self.teXiaoBtn:addClickEventListener(teXiaoBtnCallBack)
    self:MarkIntaractCObj(self.teXiaoBtn)


    local function cengBtnCallBack()
        Utils:InitUI("EquipCultivate.EquipAutoShenZhuUI", AppDef.UIType.PopWindow, false)
    end
    self.shengJieBtn:addClickEventListener(cengBtnCallBack)
    self:MarkIntaractCObj(self.shengJieBtn)

    local function jieBtnCallBack()
        Utils:InitUI("EquipCultivate.EquipAutoShenZhuUI", AppDef.UIType.PopWindow, true)
    end
    self.shengCengBtn:addClickEventListener(jieBtnCallBack)
    self:MarkIntaractCObj(self.shengCengBtn)
end

function EquipCultivateMainUI:ShowAni()
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_uid]
    local curLevel = equip.cultivateLevel[4] or 0
    local idx = curLevel % 5
    for i=1,5 do
        if i <= idx then
            self.m_pAniImod[i]:PlayNewAction(0, true)
            self.m_pAniImod[i]:getParent():setVisible(true)
            self.m_pAniImod[i]:setVisible(true)
        else
            self.m_pAniImod[i]:PlayNewAction(0, false)
            self.m_pAniImod[i]:setVisible(false)
        end
    end
end

function EquipCultivateMainUI:ShowEffectAnim()
	local parent = nil
	local ind = 0
	local time = 1
	if self.m_curUIInd == 1 then
		parent = self.m_pEffectNodes[1]
		ind = 1
		time = 1
	elseif self.m_curUIInd == 2 then
		parent = self.m_pEffectNodes[2]
		ind = 2
		time = 1
	elseif self.m_curUIInd == 3 then
		parent = self.m_pEffectNodes[3]
		ind = 3
		time = 1.5
	elseif self.m_curUIInd == 4 then
		local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_uid]
		local curLevel = equip.cultivateLevel[4] or 0
		if curLevel == 0 then
			self:HideEffectAnim()
			return
		end
		local idx = curLevel % 5
		if idx == 0 then idx = 5 end
		local function PlayShenZhuAnim()
			for i=1,5 do
				ind = 3 + i
				parent = self.m_pEffectNodes[ind]
				time = 3
				if i <= idx then
					self:SetEffect(parent, ind, time, true)
				else
					self:StopEffect(parent)
				end
			end
		end
		if idx == 5 then
			--进阶特效
			performWithDelay(self.m_pUILayer, function()
				for i=1,5 do
					local index = 3 + i
					self:StopEffect(self.m_pEffectNodes[index])
				end
				ind = 9
				parent = self.m_pEffectNodes[9]
				time = 2
				self:SetEffect(parent, ind, time)
			end,0.5)
		end
		PlayShenZhuAnim()
		return
	end
	if parent == nil or ind == 0 then
		return
	end
	self:SetEffect(parent, ind, time)
end

function EquipCultivateMainUI:SetEffect(parent, ind, time, isrepeat)
	local m_pBgAni = parent:getChildByTag(111)
	if m_pBgAni ~= nil then
		m_pBgAni:setVisible(true)
		if isrepeat == true then
			m_pBgAni:PlayActionRepeat(0)
		else
			m_pBgAni:PlayAction(0,time)
		end
		if isrepeat == true then
			return
		end
		performWithDelay(self.m_pUILayer, function()
			m_pBgAni:setVisible(false)
		end,time)
		return
	end
    local bgAnim = "res2/animation/effect_zhuangbeiyangcheng_"..ind
    m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
	if isrepeat == true then
		m_pBgAni:PlayActionRepeat(0)
	else
		m_pBgAni:PlayAction(0,time)
	end
	m_pBgAni:setTag(111)
	parent:addChild(m_pBgAni)
	if isrepeat == true then
		return
	end
	performWithDelay(self.m_pUILayer, function()
			m_pBgAni:setVisible(false)
		end,time)
end

function EquipCultivateMainUI:HideEffectAnim()
	for i = 1,#self.m_pEffectNodes do
		parent = self.m_pEffectNodes[i]
		self:StopEffect(parent)
	end
end

function EquipCultivateMainUI:StopEffect(parent)
	local m_pBgAni = parent:getChildByTag(111)
	if m_pBgAni ~= nil then
		m_pBgAni:stop()
		m_pBgAni:setVisible(false)
	end
end

function EquipCultivateMainUI:RegisterGuide()
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_Equip_8)
end

function EquipCultivateMainUI:UpdateRedDotUI()
	local isqianghua, isjinglian, isjuexing, isshenzhu = LRedDotCheckMgr:EquipCultivateRedDotCheck(self.m_uid)
	Utils:SendMsg(LUIFClassBgEvent.RedDotState, {1, isqianghua})
	Utils:SendMsg(LUIFClassBgEvent.RedDotState, {2, isjinglian})
	Utils:SendMsg(LUIFClassBgEvent.RedDotState, {3, isjuexing})
	Utils:SendMsg(LUIFClassBgEvent.RedDotState, {4, isshenzhu})
end

return EquipCultivateMainUI
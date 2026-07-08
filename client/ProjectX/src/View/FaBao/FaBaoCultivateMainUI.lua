--[[
lua里面的游戏逻辑控制
]]


local FaBaoCultivateMainUI = LUIBase:New()
FaBaoCultivateMainUI.__index = FaBaoCultivateMainUI
--local this = LTcpSocket
function FaBaoCultivateMainUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,FaBaoCultivateMainUI)   
    o:Init(userData)
    return o
end

function FaBaoCultivateMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleEquipChangeEvent.EquipeShuaXin,
        LUIRoleEquipChangeEvent.EquipeJXCost,
        LUIFaBaoEvent.PetQHSuc,
        LUIFaBaoEvent.PetJLSuc,
    }
    self:RegistSelf(self, self.msgIds)

end

function FaBaoCultivateMainUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleEquipChangeEvent.EquipeShuaXin then
        local data = msg.value
        if self.m_uid == data.uid then
            self:UpdateData(true)
            self:UpdateSelectFaBao()
            self:showpetFaBaoList()
        end
        if data.atype == 4 then
            self:ShowAni()
        end
    elseif msg.msgId == LUIRoleEquipChangeEvent.EquipeJXCost then
        self:ShowJuexingCost(msg.value)
    elseif msg.msgId == LUIFaBaoEvent.PetQHSuc then
        self:updateUIAfterStrengthSuc(msg.value, 1)
		self:UpdateRedDotUI()
    elseif msg.msgId == LUIFaBaoEvent.PetJLSuc then
        self:updateUIAfterStrengthSuc(msg.value, 2)
		self:UpdateRedDotUI()
    end
end

function FaBaoCultivateMainUI:Init(userData)
    self:RegistMsgs()
    self:InitMembers(userData)
    self:FunctionRegister(userData[1])
    self:UpdateSelectFaBao()
    if self._selectPos > 0 then
        -- self:showpetFaBaoList()
        self._FaBaoList:setPosition(self._FaBaoListPos)
    else
        -- self._FaBaoList:setVisible(false)
        self._FaBaoList:setPosition(cc.p(74, 74.3))
    end

    self:showpetFaBaoList()

	self:UpdateRedDotUI()
end

function FaBaoCultivateMainUI:InitMembers(userData)
    self:CreateUINode("csd/zhuangbeiyangcheng/zhuangbeiyangcheng.csb")
    self._bg  = self.m_pUILayer
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_uid = userData[2] or 0
    self._selectNum = 0
    -- dump(userData, "FaBaoCultivateMainUI:InitMembers ==== 1111>> ")

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self.headNode = self._bg:getChildByName("zhuangbeiyangchengUI")
    local zhuangbeiBg = self.headNode:getChildByName("zhuangbei")

    local bg = zhuangbeiBg:getChildByName("Bg")
    self._Bg1 = bg:getChildByName("Bg_1")
    self._Bg2 = bg:getChildByName("Bg_2")
    self._Bg2:setVisible(false)

    local selectBg = zhuangbeiBg:getChildByName("Panel_zhujue")
    self._selectBg = selectBg
    self.headIcon = selectBg:getChildByName("Icon")
    self.leftBtn = selectBg:getChildByName("Button_L")
    self.rightBtn = selectBg:getChildByName("Button_R")
    self.shenzhuGroup = zhuangbeiBg:getChildByName("shenzhu")
    self.shenzhuGroup:setSwallowTouches(false)
    self.juexingGroup = zhuangbeiBg:getChildByName("juexing")
  
    self.qianghuaBtn = zhuangbeiBg:getChildByName("Btn_yijianqianghua")
    self.qianghuaBtn:setVisible(false)
    self.equipNode = zhuangbeiBg:getChildByName("Node")
    self._equipIcon = zhuangbeiBg:getChildByName("equip")
    self.equipName = zhuangbeiBg:getChildByName("Name")
    self._addNum = self.equipName:getChildByName("addnum")
    local jxList = self.juexingGroup:getChildByName("List_juexing")
    self._jxListView = ccui.ListView:create()
    self._jxListView:setDirection(LISTVIEW_DIR_VERTICAL)
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

    self._FaBaoList = zhuangbeiBg:getChildByName("List")
    self._FaBaoListPos = cc.p(self._FaBaoList:getPosition())
    self._FaBaoCell = self._FaBaoList:getChildByName("item_layer")

    self._FaBaoCell:removeFromParent()
    self._FaBaoCell:retain()


    self._selectPos = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self.m_uid].m_fpos

    self:BtnStateCheck()
    local function leftEvent( sender )
        local next = self._selectPos - 1
        if next < 1 then
            next = 5
        end
        local list, pos = self:GetPosEquipList(next, -1)
        if self._selectPos == pos then
            return
        end
        self._selectPos = pos

        self:ChangeSelectPet(self._selectPos)
        --排序
        self.m_uid = list[1].m_uid
        self.selectFaBaoId = list[1].m_id
        self:UpdateSelectFaBao()
        self:showpetFaBaoList(list)
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
        self.selectFaBaoId = list[1].m_id
        self:UpdateSelectFaBao()
        self:showpetFaBaoList(list)
        self:UpdateData()
    end
    self.rightBtn:addClickEventListener(rightEvent)
end

function FaBaoCultivateMainUI:onExit()
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
    self.showEquip = nil
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
end

function FaBaoCultivateMainUI:BtnStateCheck()

end

function FaBaoCultivateMainUI:ChangeSelectPet(selectPos)
    if selectPos > 0 then
        local pet = LRoleDataMgr.Pet:GetPetByFightPos(selectPos)
        self._selectBg:setVisible(true)
        Utils:ShowPetHeadImg(self.headIcon, pet.baseData.pic, self.headImg, pet.baseData.quality, pet:IsShiny())
        -- self:UpdateListView()
        -- self:UpdateSelectFaBao()
    else
        self._selectBg:setVisible(false)
    end
end

function FaBaoCultivateMainUI:FunctionRegister( openTab )
    
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_PetFaBaoCul)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FaBao.FaBaoCultivateMainUI")
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
            GUITips.UI_Title_PetFaBao_cul1,
            GUITips.UI_Title_PetFaBao_cul2,
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

function FaBaoCultivateMainUI:UpdateData(change)
    -- body
    --更新数据
    if self.m_pSubLayer[self.m_curUIInd].UpdateData ~= nil then
        self.m_pSubLayer[self.m_curUIInd]:UpdateData(self.m_uid, change)
    end
end

function FaBaoCultivateMainUI:TabClicked(ind)

    if self.m_curUIInd == ind then
        return
    end
    
    if ind == 2 then
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_JINGLIAN) then
            return
        end
    end

    if self.m_curUIInd ~= 0 then
        self:HideCurUI()
    end
     self.m_curUIInd = ind
  
     self:ShowCurUI()
end

function FaBaoCultivateMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function FaBaoCultivateMainUI:ShowCurUI()
    
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
      
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end

    self.shenzhuGroup:setVisible(false)
    self.juexingGroup:setVisible(false)
    self.qianghuaBtn:setVisible(false)
    
end

function FaBaoCultivateMainUI:DelayLoadSubUI(tabInd)
    local uinames = {
        "View.FaBao.FaBaoQiangHuaUI",
        "View.FaBao.FaBaoJingLianUI",
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

function FaBaoCultivateMainUI:GetPosEquipList(Pos, dir)
    -- body
    local faBaoList = {}
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        if v.m_fpos == Pos then
            table.insert(faBaoList, v)
        end
    end

    if #faBaoList > 0 then
        table.sort(faBaoList, function ( a, b )
            -- body
            return a.m_wpos < b.m_wpos
        end)
        return faBaoList, Pos
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

function FaBaoCultivateMainUI:UpdateSelectFaBao()

    local info = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self.m_uid]

    -- print("UpdateSelectFaBao ===>", self.m_uid)
    -- dump(LRoleDataMgr.Pet.faBaoList.m_petFaBaos, "UpdateSelectFaBao ==============>")

    if info == nil or info.m_id == 0 then
        return
    end
    local cfg = JsonConfig.m_faBaoConfig.getDefByID(info.m_id)
    if cfg == nil then
        return
    end
    local qhLevel = info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
    local jlLelvel = info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
    local petFaBaoData = {
        id = info.m_id,
        qhLv = qhLevel,
        jlLv = jlLelvel,
    }
    -- self._equipIcon:removeAllChildren()
    -- Utils:GetFaBaoCellValue(self._equipIcon, nil, info.m_id, info.m_uid, false, 0, qhLevel, jlLelvel, true, true)

    local path = "item/"..cfg.pic..".png"
    Utils:SafeLoadTexture(self._equipIcon, path, ccui.TextureResType.localType)

    -- self.qianghuaBtn:setVisible(info.m_fpos ~= 0)
    self.equipName:setString(info.baseData.name)
    self._addNum:setString("+"..tostring(jlLelvel))
    self._level_text:setString(string.format(GUITips.UI_Text_Level_Index, qhLevel))

    self._selectPos = info.m_fpos
    self.selectFaBaoId = info.m_id
    if info.m_fpos > 0 then
        local petData = LRoleDataMgr.Pet:GetPetByFightPos(info.m_fpos)
        Utils:ShowPetHeadImg(self.headIcon, petData.baseData.pic, headPanel, petData.baseData.quality, petData:IsShiny())
    else
        self._selectBg:setVisible(false)
    end
end

function FaBaoCultivateMainUI:GetpetFaBaoList( ... )
    -- body
    if self._selectPos <= 0 then
        return self:getUnWearFaBaoData()
    end
    local petFaBao = PetkaPaiManager:getpetFaBaoByPos(self._selectPos)
    return petFaBao
end

function FaBaoCultivateMainUI:getUnWearFaBaoData( ... )
    -- body
    local faBaoList = {}
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        if v.m_fpos <= 0 and v.m_id > AppDef.fabaoExpItemID.high_fbExp then
            table.insert(faBaoList, v)
        end
    end

    local function sortFuc(m1, m2)
        return PetkaPaiManager:getFabaoProp(m1) > PetkaPaiManager:getFabaoProp(m2)
    end
    table.sort(faBaoList, sortFuc)

    self._selectNum = 0
    for i=1, #faBaoList do
        local data = faBaoList[i]
        if data.m_uid == self.m_uid then
            self._selectNum = i
            break
        end
    end

    return faBaoList
end

function FaBaoCultivateMainUI:showpetFaBaoList(petFaBao)
    -- body

    if petFaBao == nil then
        petFaBao = self:GetpetFaBaoList()
    end

    if petFaBao == nil then
        return
    end

    self._FaBaoList:removeAllItems()
    for i=1, #petFaBao do
        local item = self._FaBaoCell:clone()
        local faBaoData = petFaBao[i]
        local choose = item:getChildByName("Choose")
        choose:setVisible(false)
        -- print("FaBaoCultivateMainUI:showpetFaBaoList ==>", self.m_uid, faBaoData.m_uid)
        if self.m_uid == faBaoData.m_uid then
            choose:setVisible(true)
            self._lastSelcet = item
        end
        local zhuangbeiIcon = item:getChildByName("zhuangbeiIcon")
        -- Utils:GetEquipCellValueVec2(zhuangbeiIcon, nil, faBaoData, false, true)
        zhuangbeiIcon:removeAllChildren()
        Utils:GetFaBaoCellValue(zhuangbeiIcon, nil, faBaoData.m_id, faBaoData.m_uid, false, 0, faBaoData.qhLv, faBaoData.jlLv, false, true)
        item.userObject = faBaoData.m_uid
        self._FaBaoList:pushBackCustomItem(item)
        item:addClickEventListener(handler(self, FaBaoCultivateMainUI.FaBaoSelectEvent))
    end

    print("self._selectNum =============>", self._selectNum)
    if self._selectNum > 4 then
        self._FaBaoList:jumpToItem(self._selectNum, cc.p(0, 0), cc.p(0.5, 0.5))
    end

end

function FaBaoCultivateMainUI:FaBaoSelectEvent( sender )
    -- body
    local uid = sender.userObject
    if self._lastSelcet ~= nil then
        self._lastSelcet:getChildByName("Choose"):setVisible(false)
    end
    sender:getChildByName("Choose"):setVisible(true)
    self._lastSelcet = sender
    self.m_uid = uid

    self:UpdateData(false)
    self:UpdateSelectFaBao()
end

function FaBaoCultivateMainUI:ShowJuexing()
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

function FaBaoCultivateMainUI:ShowJuexingCost(cost)
    self._jxListView:removeAllItems()
    if cost == nil or #cost < 0 then return end
    for i=1, #cost do
        local item = self._itemCell:clone()
        Utils:GetItemCellValue(item, 0, cost[i][1], true, false, 1, nil, false, false)
        item:getChildByName("Text_0"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5,
            cost[i][3], LRoleDataMgr.Equip:CountItemNumById(cost[i][1])))

        self._jxListView:pushBackCustomItem(item)
    end
end

function FaBaoCultivateMainUI:ShowShenZhu()
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

function FaBaoCultivateMainUI:ShowAni()
    local equip = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self.m_uid]
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

function FaBaoCultivateMainUI:updateUIAfterStrengthSuc( data, type )
    -- print("FaBaoQiangHuaUI:ProcessEvent msg.value.curQhLv ==>", data.curQhLv)
    -- dump(data, "updateUIAfterStrengthSuc ===>")

    local info = LRoleDataMgr.Pet:GetFaBaoById(data.uid)
    local qhLv = 0
    local jlLelvel = 0
    if type == 1 then
        qhLv = data.curQhLv
        info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] = qhLv
        jlLelvel = info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
        self._level_text:setString(string.format(GUITips.UI_Text_Level_Index, data.curQhLv))
    else
        qhLv = info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
        jlLelvel = data.toLevel
        info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] = jlLelvel
        
        self._addNum:setString("+"..tostring(jlLelvel))
    end

    -- self._equipIcon:removeAllChildren()
    -- Utils:GetFaBaoCellValue(self._equipIcon, nil, info.m_id, info.m_uid, false, 0, qhLv, jlLelvel, true, true)

    local ItemList = self._FaBaoList:getItems()
    for i=1, #ItemList do
        local item = ItemList[i]
        -- print("updateUIAfterStrengthSuc ===>", item.userObject, data.uid)
        if item.userObject == data.uid then
            local zhuangbeiIcon = item:getChildByName("zhuangbeiIcon")
            -- print("FaBaoCultivateMainUI ===>", info.m_id)
            -- Utils:GetEquipCellValueVec2(zhuangbeiIcon, nil, faBaoData, false, true)
            zhuangbeiIcon:removeAllChildren()
            Utils:GetFaBaoCellValue(zhuangbeiIcon, nil, info.m_id, info.m_uid, false, 0, qhLv, jlLelvel, false, true)
        end
    end

end

function FaBaoCultivateMainUI:UpdateRedDotUI()
	if self.m_uid == nil or self.m_uid == 0 then
		return
	end
	local isqianghua, isjinglian = LRedDotCheckMgr:FaBaoCultivateRedDotCheck(self.m_uid)
	Utils:SendMsg(LUIFClassBgEvent.RedDotState, {1, isqianghua})
	Utils:SendMsg(LUIFClassBgEvent.RedDotState, {2, isjinglian})
	LRedDotCheckMgr:FaBaoBeiBaoRedDotCheck()
end

return FaBaoCultivateMainUI
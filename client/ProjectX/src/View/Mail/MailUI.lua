--  ----------------------------------------------
-- 邮件UI逻辑
local MailUI = LUIBase:New()
MailUI.__index = MailUI

--  ----------------------------------------------
-- 1. 没有邮件时显示写邮件ui
-- 2. 有邮件时显示收邮件ui

-- ----------------------------------------------
-- 常量区
local ScriptPath = "Mail.MailUI"
local CsbFilePath = "csd/MailLayer.csb"
local MaxMailListLen = 30

-- ---------------------------------
local _DEBUG = false
local function Debug(msg)
    -- if not _DEBUG then return end
end



-- ----------------------------------------------
local function _ShowImage(image , show)
    local show = show or false 
    image:setVisible(show)
end

-- ----------------------------------------------
local function _DrawTexture(image, texture, type)
    local type = type or ccui.TextureResType.localType
    image:loadTexture(texture, type)
end

-- ----------------------------------------------
local function _DrawText(text, str)
    if text == nil then
        return 
    end
    if str == nil then
        return
    end
    text:setString(str)
end

-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end

-- ----------------------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	--MailUI:MarkIntaractCObj(btn)
end

-- ----------------------------------------------
function MailUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMailEvent.OpenMail,        -- op = 0 打开信使 
        LUIMailEvent.SendMail,        -- op = 1 发送结果 
        LUIMailEvent.QueryMailList,   -- op = 2 信使列表 
        LUIMailEvent.SaveMail,        -- op = 3 收信结果 
        LUIMailEvent.ReadMail,        -- op = 4 已读邮件服务端删除 
        LUIMailEvent.NewMail,         -- op = 5 收到新邮件 
        LUIMailEvent.QueryMail,   -- 
    }
    self:RegistSelf(self,self.msgIds)
end

-- ----------------------------------------------

function MailUI:InitTestData()
    local mails_len = 10;
    local rsp = {}
    for i = 1, mails_len do
        local m = LMailData:New()
        m.id = i -- 邮件id
        m.from_id =  i
        m.from_name = "名字" .. i
        m.money = 10
        m.yuanbao = 10
        m.bdyuanbao = 10
        m.shenhun = 10
        m.endTime = 10
        local itemNum = 3
        for i = 1, itemNum do
            table.insert(m.itemNum, itemNum)
            local item = LPItem:New()
            item.m_id = 2730
            -- LuaNetRecvdMsg.ReadItemData(item, s)
            if item.m_id >= 0 then
                table.insert(m.item, item)
            end
        end

        local petNum = 0
        for i = 1, petNum do
            -- local pid = s:ReadWord()
            -- if pid > 0 then 
            --     local data = LPetData:New(pid)
            --     LuaNetRecvdMsg.ReadPetInfo(data, s)
            --     table.insert(m.pet, data)
            -- end
        end

        -- local otherNum = 0
        -- for i=1, otherNum do
        --     local otherItem = {}
        --     otherItem.m_id = s:ReadWord()
        --     otherItem.m_num = s:ReadUInt()
        --     table.insert(m.otherItems, otherItem)
        -- end

        -- local petEquipNum = s:ReadByte()
        -- for i=1, petEquipNum do
        --     local petEquip = LPetEquipInfo:New()
        --     this.ReadPetEquipData(petEquip, s)
        --     table.insert(m.petEquips, petEquip)
        -- end

        m.message = "测试消息" .. i
        table.insert(rsp, m)
        
    end
    LRoleDataMgr.Social.NewMailData = rsp
end
function MailUI:ProcessEvent(msg)
    if msg.msgId == LUIMailEvent.OpenMail then
        self:OnOpenMail(msg.value)
    end

    if msg.msgId == LUIMailEvent.SendMail then
        self:OnSendMail(msg.value)
    end

    if msg.msgId == LUIMailEvent.QueryMailList then
        --self:InitTestData()
        self:OnMailList()
        self:SetMailVisible()
    end

    if msg.msgId == LUIMailEvent.SaveMail then
        self:OnSaveMail(msg.value)
    end

    if msg.msgId == LUIMailEvent.ReadMail then
        self:OnReadMail(msg.value)
    end

    if msg.msgId == LUIMailEvent.NewMail then
        self:OnNewMail(msg.value)
    end

    if msg.msgId == LUIMailEvent.QueryMail then
        self:OnQueryMail()
    end

end

-- ----------------------------------------------
function MailUI:OnNewMail()
    --Debug("OnNewMail")
    self:QueryMails()
end

-- ----------------------------------------------
function MailUI:OnReadMail()
    --Debug("OnReadMail")
end

-- ----------------------------------------------
function MailUI:OnQueryMail()
    --Debug("OnReadMail")
    self:QueryMails()
end


-- ----------------------------------------------
function MailUI:OnSendMail(rsp)
    --Debug("OnSendMail")
    --Debug(rsp)
    local errmsg = nil
    errmsg = rsp.errmsg
    if not errmsg then return end 
    _ShowTipsWindow(self,errmsg)
    self:ResetWriteMailCtrol(false)
end

-- ----------------------------------------------
function MailUI:OnOpenMail(rsp)
    --Debug("OnOpenMail")
end

-- ----------------------------------------------
function MailUI:OnMailList()

    -- self:updateMail()

    self.mail_list = Utils:deepCopy(LRoleDataMgr.Social.NewMailData)
--    dump(self.mail_list, "===============")

    local function sorFuc(a, b)
        -- body
        return a.endTime > b.endTime
    end
    table.sort(self.mail_list, sorFuc)

    local userId = LRoleDataMgr.MyHeroInfo.id
    LRoleDataMgr.Social:ReadMail(userId)

    local oldMailList = LRoleDataMgr.Social.OldMailData
--    dump(oldMailList, "oldMailList")
    for i = 1, #oldMailList do
        table.insert(self.mail_list, oldMailList[i])
    end

    self._MailNum = #self.mail_list
    --print("self._MailNum", self._MailNum)

    if self.lpanel.tv then
        self.lpanel.tv:reloadData()
    end

    -- local contentctl = self.rpanel.wrmail_panel:getChildByName("MailBg"):getChildByName("WriteBg"):getChildByName("MailContent")
    -- local isInWrite = string.len(contentctl:getString()) > 0
    -- if  not isInWrite then
    --     self:ShowRightPanel(self._MailNum)
    --     self:DrawRightPanel()
    -- end
    self:ShowRightPanel(self._MailNum)
    self:DrawRightPanel()

    self:RightLVAddItem(0)

--转到写信状态
    if string.len(self._WirteToRoleName) > 0 then
        self:ShowWriteMail()
    end
end

-- ----------------------------------------------
function MailUI:OnSaveMail(rsp)
    local errmsg = nil
    if rsp.errcode and  rsp.errcode > 0 then 
        errmsg = rsp.errmsg
        self:QueryMails()
    elseif rsp.errcode and  rsp.errcode <= 0 then
        errmsg = rsp.errmsg
    end

    if not errmsg then return end 
    _ShowTipsWindow(self,errmsg)
    --[[

        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, errmsg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
    ]]

end

-- ----------------------------------------------
function MailUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self._WirteToRoleName = nil
    self.lpanel = nil
    Utils:FreeTable(self.mail_list)
    self._MailNum = nil
end

-- ----------------------------------------------
function MailUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- -----------------------------------
function MailUI:DrawWindowTitle()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, "")
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- ----------------------------------------------
function MailUI:Init()
    self._MailNum = 0
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:BindButtonFunction()
    self:RegisterQuik()
    self:InitLeftTableView()
    self:SetMailVisible();

    -- self:QueryMails()
    --self:ShowWriteMail()

    -- if #LRoleDataMgr.Social:GetFriendData() == 0 then
    --     LuaNetSendMsg:QueryFriendList();
    -- end

    self._WirteToRoleName = ""

end


function MailUI:SetMailVisible()
    if self._MailNum <= 0 then
        self.m_pUILayer:getChildByName("None"):setVisible(true);
        self.m_pUILayer:getChildByName("Panel"):setVisible(false);
    else
        self.m_pUILayer:getChildByName("None"):setVisible(false);
        self.m_pUILayer:getChildByName("Panel"):setVisible(true);
    end
end

-- ----------------------------------------------
function MailUI:New()
    local o = LUIBase:New()
    setmetatable(o, MailUI)
    o:Init()
    return o
end

-- ----------------------------------------------
function MailUI:InitUIControl()
    self:InitLeftPanel()
    self:InitRightPanel()
end

-- ----------------------------------------------
function MailUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    local RootPanel = self.m_pUILayer:getChildByName("Panel")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end


-- ----------------------------------------------
function MailUI:InitLeftPanel()
    local rp = self.m_pUILayer:getChildByName("Panel")
    if self.lpanel == nil then self.lpanel = {} end
    self.lpanel.tv_contain = rp:getChildByName("MailList"):getChildByName("MailBg"):getChildByName("MailListView")
    self.lpanel.tv_cell_template = rp:getChildByName("MailList"):getChildByName("MailBg"):getChildByName("MailListView"):getChildByName("MailBtn")
    if self.lpanel.tv_cell_template then 
        self.lpanel.tv_cell_template:setTouchEnabled(false);
        self.lpanel.tv_cell_template:setVisible(false);
    end
    self.lpanel.cur_cell_index = 0
end


-- ----------------------------------------------
function MailUI:GetCellTemplateByIdx()
    local cell_template = self.lpanel.tv_cell_template
    return  cell_template
end

-- ----------------------------------------------
local rpanel_tv_tagid = 1886
function MailUI:InitLeftTableView()

    local tv_contain = self.lpanel.tv_contain
    local otv = tv_contain:getParent():getChildByTag(rpanel_tv_tagid)
    if otv then 
        tv_contain:getParent():removeChildByTag(rpanel_tv_tagid)
    end

    local tv = cc.TableView:create(tv_contain:getContentSize())
    tv:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tv:setAnchorPoint(tv_contain:getAnchorPoint())
    tv:setPosition(tv_contain:getPosition())
    tv:setDelegate()
    tv:setSwallowsTouches(false)
    tv:setBounceable(false)
    tv:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tv_contain:getParent():getParent():addChild(tv)

    local function scrollViewDidScroll(view)
    end

    local function tableCellTouched(sender, cell)
        self:TableViewCellSelected(cell)
    end

    local function cellSizeForTable(sender, index)
        local cell_template = self:GetCellTemplateByIdx()
        local width = cell_template:getContentSize().width
        local height = cell_template:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, index)
        --Debug("tableCellAtIndex idx = "..index)
        return self:LeftTableViewAddCell(sender, index)
    end

    local function numberOfCellsInTableView()
        return self._MailNum
    end

    --tv:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    tv:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   
    tv:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   
    tv:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   
    tv:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW) 

    self.lpanel.tv = tv
end

-- ----------------------------------------------
function MailUI:LeftTableViewAddCell(sender , index)
    --Debug("LeftTableViewAddCell idx = "..index)
    local cell = sender:dequeueCell()
    local cell_template = self:GetCellTemplateByIdx()
    local ccs 
    if not cell then
        cell = cc.TableViewCell:new()
        ccs = cell_template:clone()
        ccs:setTag(123)
        ccs:setPosition(cc.p(0,0))
        ccs:setVisible(true)
        ccs:setTouchEnabled(false)
        cell:addChild(ccs)
    else
        ccs = cell:getChildByTag(123)
    end
    self:DrawLeftTVCell(ccs, index)
    return cell
end

-- ----------------------------------------------
function MailUI:TableViewCellSelected(cell)
    local index = cell:getIdx()
    local ccs = cell:getChildByTag(123)
    if self.lpanel.cur_cell_index ~= index then 
        local cell = self.lpanel.tv:cellAtIndex(self.lpanel.cur_cell_index)
        if cell ~= nil then 
            local ccs = cell:getChildByTag(123)
            ccs:getChildByName("ChooseBg"):setVisible(false)
        end
    end
    self.lpanel.cur_cell_index = index
    ccs:getChildByName("ChooseBg"):setVisible(true)

    -- ================
    -- 画右侧区域

    self:ShowRightPanel(1)
    self:DrawRightPanel()
    self:RightLVAddItem(index)
    self:ReadMail(index, ccs)

end

function MailUI:ReadMail(index, ccs)
    -- body

    local m = self:GetMailByCellIndex(index)
	if m == nil then
		return
	end
    --print("index", index, m)
    if LRoleDataMgr.Social:isMailRead(m.id) then
        return
    end

    if #m.item > 0 then
        return
    end

    if #m.pet > 0 then
        return
    end

    if m.money > 0 then
        return
    end

    if m.yuanbao > 0 then
        return
    end

    if m.bdyuanbao > 0 then
        return
    end

    if m.shenhun > 0 then
        return
    end

    if #m.otherItems > 0 then
        return
    end

    if #m.petEquips > 0 then
        return
    end

    LuaNetSendMsg:DelMails(m.id)

    local userId = LRoleDataMgr.MyHeroInfo.id
    LRoleDataMgr.Social:saveMail(0, userId, m.id, m)
    LRoleDataMgr.Social:ReadMail(userId)
    LRoleDataMgr.Social:delNewMailData(m.id)

    ccs:getChildByName("OpenImage"):setVisible(false)
    ccs:getChildByName("CloseImage"):setVisible(true)
--    ccs:getChildByName("Time"):setVisible(false)

    --检测社交红点
    LRedDotCheckMgr:SocialCheck()
    -- self:updateMail()
end


-- ----------------------------------------------
local function _CatMailTitle(from_name)
    if from_name == GUITips.RSI_UI_GM_NAME then
        from_name = GUITips.RSI_UI_GM_MAIL_NAME
    end
    local str = string.format(GUITips.Rsi_Mail_Msg1,from_name)
    return str
end

-- ----------------------------------------------
function MailUI:GetMailByCellIndex(index)
    if self.mail_list ==  nil then return nil end
    if #self.mail_list <= 0 then return nil end 
    local m = self.mail_list[index + 1] 
    return m
end

-- ----------------------------------------------
function MailUI:GetRightTVCellNums()
    if not self:IsHaveMail() then
        return 0
    end
    local index = self.lpanel.cur_cell_index
    local s = self:GetMailAttachmentLenByCellIndex(index) + self:GetMailPetLenByCellIndex(index)
    local a = self:GetMailAttachmentLenByCellIndex(index)
    local p = self:GetMailPetLenByCellIndex(index)
    local bg = 0
    local g = 0
    local c = 0
    local sh = 0

    local m = self:GetMailByCellIndex(index)
    if m == nil then return end 
    if m.money and m.money > 0   then c = 1 end
    if m.yuanbao and m.yuanbao > 0 then g = 1 end
    if m.bdyuanbao and  m.bdyuanbao  > 0 then bg = 1 end 
    if m.shenhun and  m.shenhun  > 0 then sh = 1 end
    return s, a , p , bg, g, c, sh
end

-- ----------------------------------------------
function MailUI:DrawLeftTVCell(ccs, index)
    local m = self:GetMailByCellIndex(index)
    if m == nil then return end
--    print("index =", index)
--    dump(m, "DrawLeftTVCell")
    -- ===================
    -- 画邮件标题
    local text = ccs:getChildByName("Name")
    local str = _CatMailTitle(m.from_name)
    _DrawText(text, str)

    -- ===================
    -- 画邮件时间
    local time = 0
    if m.endTime then
        time = m.endTime - 3600 * 24 * 3
    end

    str = os.date("%Y-%m-%d", time)
--    print("the time is ", m.endTime, time, str)
--    str = os.date(Rsi_Time_Date_Format, m.endTime)
    text = ccs:getChildByName("Time")
    text:setVisible(true)
    _DrawText(text, str)
    if self.lpanel.cur_cell_index == index then 
        ccs:getChildByName("ChooseBg"):setVisible(true)

--默认读取第一个邮件
        if self.lpanel.cur_cell_index == 0 then
            if not LRoleDataMgr.Social:isMailRead(m.id) then
                self:ReadMail(0, ccs)
            end
        end
    else 
        ccs:getChildByName("ChooseBg"):setVisible(false)
    end


    if LRoleDataMgr.Social:isMailRead(m.id) then
        ccs:getChildByName("OpenImage"):setVisible(false)
        ccs:getChildByName("CloseImage"):setVisible(true)
--        text:setVisible(false)
    else
        ccs:getChildByName("OpenImage"):setVisible(true)
        ccs:getChildByName("CloseImage"):setVisible(false)
    end

end

-- ----------------------------------------------
function MailUI:InitRightPanel()
    local rp = self.m_pUILayer:getChildByName("Panel")
    if self.rpanel == nil then self.rpanel = {} end
    self.rpanel.mail_show_panel = rp:getChildByName("MailScreem")
    --self.rpanel.wrmail_panel = rp:getChildByName("WriteMail")
    local scrollView1 = self.rpanel.mail_show_panel:getChildByName("MailBg"):getChildByName("ScrollView_1")
    self._scrollView1 = scrollView1
    scrollView1:setScrollBarEnabled(false)
    scrollView1:setBounceEnabled(false)
    local content = scrollView1:getChildByName("MailContent")
    self._MailContent = Utils:CreateColorText3(content, true)
    --self.rpanel.wrmail_panel:setVisible(false)
    self.rpanel.mail_show_btns = rp:getChildByName("MailBtn")
    self.rpanel.wrmail_btns = rp:getChildByName("WriteBtn")
    self.rpanel.lv_cell_template = rp:getChildByName("MailScreem"):getChildByName("BtnBg"):getChildByName("IconBg")
    self.rpanel.lv_cell_template:getChildByName("EquipIcon"):setVisible(false)
    self.rpanel.petCell = rp:getChildByName("MailScreem"):getChildByName("BtnBg"):getChildByName("IconColor")
    self.rpanel.petCell:setVisible(false)
    self.rpanel.lv_cell_template:getChildByName("EquipNum"):setVisible(false)
    self.rpanel.list_view = rp:getChildByName("MailScreem"):getChildByName("BtnBg"):getChildByName("ListView")
    self.rpanel.list_view:setScrollBarEnabled(false)
end

-- ----------------------------------------------
function MailUI:GetMailAttachmentByCellIndex(i)
    local as = self:GetMailAllAttachmentByCellIndex(self.lpanel.cur_cell_index)
    local a = as[i]
    if not a then return nil end
    return a
end

-- ----------------------------------------------
function MailUI:GetMailPetByCellIndex(i)
    local ps = self:GetMailAllPetByCellIndex(self.lpanel.cur_cell_index)
    local p = ps[i]
    if not p then return nil end
    return p
end

-- ----------------------------------------------
local function _CatItemIconStr(item)
    -- TODO 
    if not item or item.m_item == nil then 
        return "item/equip107.png"
    end 

    local ficon = {}
    table.insert(ficon, "item/equip107.png")
    table.insert(ficon, "item/equip292.png")
    table.insert(ficon, "item/equip207.png")
    table.insert(ficon, "item/equip527.png")
    table.insert(ficon, "item/equip5275.png")
    
    local hash = item.m_item.pic % 5
    local str = ficon[hash + 1]  
    str = "item/equip" .. item.m_item.pic .. ".png" 
    return str
end

-- ----------------------------------------------
-- 右侧ListView添加Cell
function MailUI:RightLVAddItem(index)

    local DeleteTime = self.rpanel.mail_show_panel:getChildByName("MailBg"):getChildByName("DeleteTime")
    local m = self.mail_list[index + 1]
    if m == nil then 
        DeleteTime:setVisible(false)
        return
    end

--    print("m.endTime", m.endTime)
    if m.endTime > 0 then
        local str = os.date(GUITips.Rsi_Time_Format, m.endTime)
        DeleteTime:setString(string.format(GUITips.Rsi_Mail_Delete_Format, str))
    else
        DeleteTime:setVisible(false)
    end
    
    self.rpanel.list_view:removeAllItems()
    -- --金币
    -- if m.money > 0 then
    --     local awardui = self.rpanel.lv_cell_template:clone()
    --     Utils:GetItemCellValue(awardui, 0, AppDef.AwrdItem.AWRD_ITEM_COIN, true, true, m.money, nil, true)
    --     self.rpanel.list_view:pushBackCustomItem(awardui)
    -- end
    -- --元宝
    -- if m.yuanbao > 0 then
    --     local awardui = self.rpanel.lv_cell_template:clone()
    --     Utils:GetItemCellValue(awardui, 0, AppDef.AwrdItem.AWRD_ITEM_YUANBAO, true, true, m.yuanbao, nil, true)
    --     self.rpanel.list_view:pushBackCustomItem(awardui)
    -- end

    -- --绑元
    -- if m.bdyuanbao > 0 then
    --     local awardui = self.rpanel.lv_cell_template:clone()
    --     Utils:GetItemCellValue(awardui, 0, AppDef.AwrdItem.AWRD_ITEM_BDYB, true, true, m.bdyuanbao, nil, true)
    --     self.rpanel.list_view:pushBackCustomItem(awardui)
    -- end

    -- --神魂
    -- if m.shenhun > 0 then
    --     local awardui = self.rpanel.lv_cell_template:clone()
    --     Utils:GetItemCellValue(awardui, 0, AppDef.AwrdItem.AWRD_ITEM_SHENPO, true, true, m.shenhun, nil, true)
    --     self.rpanel.list_view:pushBackCustomItem(awardui)
    -- end

--物品
    for i=1, #m.item do
       print("m.item[i].m_id", m.item[i].m_id, m.item[i].m_num)
        local awardui = self.rpanel.lv_cell_template:clone()
        -- Utils:GetItemCellValue(awardui, 0, m.item[i].m_id, true, true, m.item[i].m_num, nil, true)
        Utils:ShowItemByConfigData(m.item[i], awardui, nil, true, true)
        self.rpanel.list_view:pushBackCustomItem(awardui)
    end

-- --积分等 60000以后
--     for i=1, #m.otherItems do
-- --        print("m.item[i].m_id", m.item[i].m_id, m.item[i].m_num)
--         local awardui = self.rpanel.lv_cell_template:clone()
--         Utils:GetItemCellValue(awardui, 0, m.otherItems[i].m_id, true, true, m.otherItems[i].m_num, nil, true)
--         self.rpanel.list_view:pushBackCustomItem(awardui)
--     end

--宠物
    for i = 1, #m.pet do
        local awardui = self.rpanel.petCell:clone()
        awardui:setVisible(true)
--        Utils:ShowPetHeadImg(awardui, m.pet[i].baseData.pic, headPanel, m.pet[i].baseData.quality, m.pet[i]:IsShiny())
        Utils:ShowPet(m.pet[i].id, self.rpanel.list_view, awardui, false)
        self.rpanel.list_view:pushBackCustomItem(awardui)
    end

    --宠物装备
    for i = 1, #m.petEquips do
        local info = m.petEquips[i]
        local cfgData = LDataConstMgr:GetPetEquipCfgData(info.m_id)
        local awardui = self.rpanel.petCell:clone()
        awardui:setVisible(true)
        local itemValue = {}
        local resFile = string.format("item/%s.png", cfgData.pic)
        local userDefine = {picFilePath = resFile,quality = cfgData.quality, star = info.m_star, strengthenLv = info.m_stoneLevel}
        itemValue.userDefine = userDefine
        pItem = ItemCellUI:New(awardui, itemValue)
        pItem:SetCanClick(true)
        self.rpanel.list_view:pushBackCustomItem(awardui)
    end
end

-- ----------------------------------------------
-- 得到右侧Tableview Cell的控件模版 
function MailUI:GetRightTVCellTemplate()
    local cell_template = self.rpanel.lv_cell_template
    return  cell_template
end

-- ----------------------------------------------
function MailUI:IsHaveMail()
    if self.mail_list == nil or #self.mail_list <= 0 then 
        return false
    end
    return true
end

-- ----------------------------------------------
function MailUI:ShowRightPanel(len)
    self._writeLen = len
    if len > 0 then
        self.rpanel.mail_show_panel:setVisible(true) 
        self.rpanel.mail_show_btns:setVisible(true)
        --self.rpanel.wrmail_panel:setVisible(false)
        -- self.rpanel.wrmail_btns:setVisible(false)
    else
        self.rpanel.mail_show_panel:setVisible(false) 
        self.rpanel.mail_show_btns:setVisible(false)
        --self.rpanel.wrmail_panel:setVisible(true)
        -- self.rpanel.wrmail_btns:setVisible(true)
    end

end

-- ----------------------------------------------
function MailUI:DrawRightPanel()
    if not self:IsHaveMail() then return end
    local index = self.lpanel.cur_cell_index
    local m = self.mail_list[index + 1] 
    if not m then 
        Debug("DrawRightPanel m is nil index = "..index)
        return 
    end
    local title = _CatMailTitle(m.from_name)
    local text = self.rpanel.mail_show_panel:getChildByName("MailBg"):getChildByName("TitleBg"):getChildByName("TitleName")
    _DrawText(text, title)

    self.rpanel.mail_show_panel:setVisible(true) 
    -- text = self.rpanel.mail_show_panel:getChildByName("MailBg"):getChildByName("MailContent")
    -- text = Utils:CreateColorText3(text, true)
    _DrawText(self._MailContent, m.message)
    
    local scrollViewSize = self._scrollView1:getInnerContainerSize()
    local contentSize = self._MailContent:getSize()
    if contentSize.height > scrollViewSize.height then
        local offsetY = contentSize.height - scrollViewSize.height
        self._scrollView1:setInnerContainerSize(cc.size(scrollViewSize.width, contentSize.height))
        self._scrollView1:jumpToTop()
        self._MailContent:setPositionY(self._MailContent:getPositionY() + offsetY)
        self._scrollView1:setBounceEnabled(true)
    else
        self._scrollView1:setBounceEnabled(false)
    end

    if LRoleDataMgr.Social:isMailRead(m.id) then
        self.m_pUILayer:findChildByName("Panel/MailBtn/ReceiveBtn"):setVisible(true);
        self.m_pUILayer:findChildByName("Panel/MailBtn/ReceiveBtn/BtnName"):setString(GUITips.RSI_SOCIAL_DELETE);
    else
        if self:isMailHasReward(m.id) then
            self.m_pUILayer:findChildByName("Panel/MailBtn/ReceiveBtn"):setVisible(true);
            self.m_pUILayer:findChildByName("Panel/MailBtn/ReceiveBtn/BtnName"):setString(GUITips.RSI_FACTION_MSG203);
        else
            self.m_pUILayer:findChildByName("Panel/MailBtn/ReceiveBtn"):setVisible(false);
        end
    end
    
end

function MailUI:ReciveRewardFromMail(mind)
    local newMailList = LRoleDataMgr.Social.NewMailData
    if newMailList and #newMailList < mind then
        return
    end 
    local i = mind
    local canGet = false
    if #newMailList[i].item > 0 then
        if LRoleDataMgr.Equip:IsPackFull() then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_SL_TIP3)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        canGet = true
    elseif #newMailList[i].pet > 0 then
        canGet = true
    elseif newMailList[i].money > 0 or newMailList[i].yuanbao > 0 or newMailList[i].bdyuanbao > 0 then
        canGet = true
    elseif #newMailList[i].petEquips > 0 then
        canGet = true;
    elseif #newMailList[i].otherItems > 0 then
        canGet = true;
    end

    if canGet then
        LuaNetSendMsg:SaveMails(newMailList[i].id, 0)
    end
end

function MailUI:isMailHasReward(id)
    id = id or 0
    local newMailList = LRoleDataMgr.Social.NewMailData
    if newMailList == nil or id == 0 then
        return false
    end 
    local i = 0
    for k=1,#newMailList do
        if newMailList[k].id == id then
            i = k
            break
        end
    end
    local canGet = false
    if #newMailList[i].item > 0 then
        canGet = true
    elseif #newMailList[i].pet > 0 then
        canGet = true
    elseif newMailList[i].money > 0 or newMailList[i].yuanbao > 0 or newMailList[i].bdyuanbao > 0 then
        canGet = true
    elseif #newMailList[i].petEquips > 0 then
        canGet = true;
    elseif #newMailList[i].otherItems > 0 then
        canGet = true;
    end  
    return canGet 
end

-- ----------------------------------------------
function MailUI:BindButtonFunction()
    local btns = self.rpanel.mail_show_btns
    local wrmail_btns = self.rpanel.wrmail_btns
    -- local wrmail_panel = self.rpanel.wrmail_panel
    local getBtn = self.m_pUILayer:findChildByName("Panel/MailBtn/ReceiveBtn");
    local function onGetClicked(sender)
        --print("self.lpanel.cur_cell_index",self.lpanel.cur_cell_index)

        local index = self.lpanel.cur_cell_index
        local m = self.mail_list[index + 1] 

        if m and LRoleDataMgr.Social:isMailRead(m.id) then
            local userId = LRoleDataMgr.MyHeroInfo.id
            LRoleDataMgr.Social:DeleteMail(userId, m.id)
            self:OnMailList()
            self:SetMailVisible()

        else
            local idx = 0
            local newMailList = LRoleDataMgr.Social.NewMailData
            for i=1,#newMailList do
                if newMailList[i].id == m.id then
                    idx = i
                end
            end
            if idx > 0 then
                self:ReciveRewardFromMail(idx)
            end
        end
        
    end
    getBtn:addClickEventListener(onGetClicked)

    local getAllBtn = self.m_pUILayer:findChildByName("Panel/MailList/MailBg/ReceiveBtn");
    local function onGetAllClicked(sender)
        -- print("self.lpanel.cur_cell_index",self.lpanel.cur_cell_index)
        local newMailList = LRoleDataMgr.Social.NewMailData
        if not newMailList then
            return
        end
        for i=1, #newMailList do
            self:ReciveRewardFromMail(i)
        end
        -- self:ReciveRewardFromMail(self.lpanel.cur_cell_index)
    end
    getAllBtn:addClickEventListener(onGetAllClicked)

    local deleteAllBtn = self.m_pUILayer:findChildByName("Panel/MailList/MailBg/DeleteBtn");
    local function onDeleteAllClicked(sender)
        -- print("self.lpanel.cur_cell_index",self.lpanel.cur_cell_index)
        local oldMailList = LRoleDataMgr.Social.OldMailData
        if oldMailList and #oldMailList > 0 then
            LRoleDataMgr.Social:DeleteAll()
            self:OnMailList()
            self:SetMailVisible()
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI48)
        else
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI47)
        end
        -- local newMailList = LRoleDataMgr.Social.NewMailData
        -- if not newMailList then
        --     return
        -- end
        -- for i=1, #newMailList do
        --     LuaNetSendMsg:DelMails(newMailList[i].id)
        -- end
    end
    deleteAllBtn:addClickEventListener(onDeleteAllClicked)
    -- ======================
    -- 领取邮件
    -- local function OnReceiveBtnClick(sender)
    --     local newMailList = LRoleDataMgr.Social.NewMailData
    --     for i=1, #newMailList do
    --         if #newMailList[i].item > 0 then
    --             if LRoleDataMgr.Equip:IsPackFull() then
    --                 LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_SL_TIP3)
    --                 self:SendMsg(LGameMsg.m_scrollTipsMsg)
    --                 return
    --             end
    --             LuaNetSendMsg:SaveMails(newMailList[i].id, 1)
    --             break;
    --         elseif #newMailList[i].pet > 0 then
    --             LuaNetSendMsg:SaveMails(newMailList[i].id, 1)
    --             break;
    --         elseif newMailList[i].money > 0 or newMailList[i].yuanbao > 0 or newMailList[i].bdyuanbao > 0 then
    --             LuaNetSendMsg:SaveMails(newMailList[i].id, 1)
    --             break;
    --         elseif #newMailList[i].petEquips > 0 then
    --             LuaNetSendMsg:SaveMails(newMailList[i].id, 1)
    --             break
    --         elseif #newMailList[i].otherItems > 0 then
    --             LuaNetSendMsg:SaveMails(newMailList[i].id, 1)
    --             break
    --         end
    --     end
    --     Utils:SendMsg(LUIMailEvent.delAllMail)
    -- end
    -- local ReceiveBtn = btns:getChildByName("ReceiveBtn") 
    -- _BindClickFunctionToButton(ReceiveBtn, OnReceiveBtnClick)

    -- ======================
    -- 删除邮件
    -- local function OnDeleteBtnClick(sender)
    --     --Debug("OnDeleteBtnClick")
    --     self:DeleteMail()
    -- end
    -- local DeleteBtn = btns:getChildByName("DeleteBtn") 
    -- _BindClickFunctionToButton(DeleteBtn, OnDeleteBtnClick)

    -- ======================
    -- 回复邮件
    -- local function OnReplayBtnClick(sender)
    --     --Debug("OnReplayBtnClick")
    --     self:ShowRightPanel(0)
    --     self:ResetWriteMailCtrol(true)
    -- end
    -- local ReplayBtn = btns:getChildByName("ReplayBtn")
    -- _BindClickFunctionToButton(ReplayBtn, OnReplayBtnClick)

    -- ======================
    -- 写邮件
    -- local function OnWriteBtnClick(sender)
    --     --Debug("OnWriteBtnClick")
    --     self:ShowRightPanel(0)
    --     self:ResetWriteMailCtrol(false)
    -- end
    -- local WriteBtn = btns:getChildByName("WriteBtn") 
    -- _BindClickFunctionToButton(WriteBtn, OnWriteBtnClick)


    -- ======================
    -- 发送
    -- local function OnSendBtnClick(sender)
    --     --Debug("OnSendBtnClick")
    --     self:SendMail()
    -- end

    -- local SendBtn = wrmail_btns:getChildByName("ReceiveBtn") 
    -- _BindClickFunctionToButton(SendBtn, OnSendBtnClick)

    -- ======================
    -- 好友
    -- local function OnFriendBtnClick(sender)
    --     local fun = function(roleName)
    --         local fromctl = wrmail_panel:getChildByName("MailBg"):getChildByName("Title"):getChildByName("TitleBg"):getChildByName("TitleName")
    --         fromctl:setString(roleName)
    --     end
    --     local data = {}
    --     data.roledatas = LRoleDataMgr.Social:GetFriendData()
    --     data.callback = fun
    --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.RoleListUI",AppDef.UIType.PopWindow, data)
    --     self:SendMsg(LGameMsg.m_initUIMsg)
    -- end
    -- local FriendBtn = wrmail_panel:getChildByName("MailBg"):getChildByName("Title"):getChildByName("SelectBtn") 
    -- _BindClickFunctionToButton(FriendBtn, OnFriendBtnClick)

end

-- ----------------------------------------------
-- function MailUI:ResetWriteMailCtrol(i)
--     local wrmail_panel = self.rpanel.wrmail_panel
--     local fromctl = wrmail_panel:getChildByName("MailBg"):getChildByName("Title"):getChildByName("TitleBg"):getChildByName("TitleName")
--     if i then 
--         local index = self.lpanel.cur_cell_index
--         local m = self:GetMailByCellIndex(index)
--         fromctl:setString(m.from_name)

--     else
--         fromctl:setString("")
--     end 
--     local contentctl = wrmail_panel:getChildByName("MailBg"):getChildByName("WriteBg"):getChildByName("MailContent")
--     contentctl:setString("")

--     local data = os.time() + 3600 * 24 * 3
--     local str = os.date(GUITips.Rsi_Time_Format, data)
--     self.rpanel.wrmail_panel:getChildByName("DeleteTime"):setString(string.format(GUITips.Rsi_Mail_Delete_Format, str))
--     self.rpanel.wrmail_panel:getChildByName("DeleteTime"):setVisible(false)
-- end

-- ----------------------------------------------
function MailUI:DeleteMail()
    local oldMail = LRoleDataMgr.Social.OldMailData
--    print("DeleteMail ==============", #oldMail)
--    Utils:dump(oldMail)
    local didDel = false
    for i = 1, #oldMail do
        local affix = #oldMail[i].item > 0 and #oldMail[i].pet > 0
        if not affix and oldMail[i].money <= 0 and oldMail[i].bdyuanbao <= 0 and oldMail[i].yuanbao <= 0 then
            didDel = true
--            print("MailUI:DeleteMail ===============================")
            local userId = LRoleDataMgr.MyHeroInfo.id
            LRoleDataMgr.Social:DeleteMail(userId, oldMail[i].id)
        end
    end

    if didDel then
        self:QueryMails()
    end

    Utils:SendMsg(LUIMailEvent.delAllMail)

end

-- ----------------------------------------------
-- function MailUI:SendMail()
--     local m = LMailData:New() 
--     local wrmail_panel = self.rpanel.wrmail_panel
--     local fromctl = wrmail_panel:getChildByName("MailBg"):getChildByName("Title"):getChildByName("TitleBg"):getChildByName("TitleName")
--     m.from_name = fromctl:getString()
--     local contentctl = wrmail_panel:getChildByName("MailBg"):getChildByName("WriteBg"):getChildByName("MailContent")
--     m.message = contentctl:getString()
--     if m.message == "" then 
--         _ShowTipsWindow(self, "邮件内容不能为空") 
--         return
--     end

--     LuaNetSendMsg:SendMails(m)
-- end

-- ----------------------------------------------
function MailUI:QueryMails()
    --Debug("MailUI:QueryMails")
    LuaNetSendMsg:QueryMails(2)
end

-- ----------------------------------------------
-- function MailUI:ShowWriteMail()
--     Debug("ShowWriteMail")
--     self:ShowRightPanel(0)
--     self.rpanel.wrmail_panel:getChildByName("DeleteTime"):setVisible(false)
--     self:ResetWriteMailCtrol(false)
--         if string.len(self._WirteToRoleName) > 0 then
--         --print("self.rpanel.wrmail_panel", self._WirteToRoleName)
--         local fromctl = self.rpanel.wrmail_panel:getChildByName("MailBg"):getChildByName("Title"):getChildByName("TitleBg"):getChildByName("TitleName")
--         fromctl:setString(self._WirteToRoleName)
--     end
-- end


function MailUI:setShowMail(roleName)
    -- body
    self._WirteToRoleName = roleName;
end

function MailUI:showWriteMailDirect(roleName)
    -- body
    self._WirteToRoleName = roleName
    if string.len(self._WirteToRoleName) > 0 then
        self:ShowWriteMail()
    end
end

-- function MailUI:updateMail()
--     -- body
--     local isShow = #LRoleDataMgr.Social.NewMailData > 0
--     LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {1, isShow})
--     self:SendMsg(LGameMsg.m_baseMsgWithOne)
-- end

-- ----------------------------------------------
return MailUI
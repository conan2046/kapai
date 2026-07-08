local XunBaoPopUI = LUIBase:New()
XunBaoPopUI.__index = XunBaoPopUI
--local this = LTcpSocket
function XunBaoPopUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,XunBaoPopUI) 
    o:Init(userData)
    return o
end

function XunBaoPopUI:SetClickCallback(func, tag)
    local panel = self.m_pUILayer:getChildByName("btn_skill")
    if tag ~= nil then
        panel:setTag(tag)
    end
    panel:addClickEventListener(func)
end


function XunBaoPopUI:Init(userData)
    self.Script = "WanFa.XunBaoPopUI"
    self.m_tab = userData[1] or 0
    self.m_id = userData[2] or 0
    self:CreateUINode("csd/wanfa/Xunbao_popupLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/wanfa/Xunbao_popupLayer.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:ShowLayer()
    self:RegisterGuide()
end

--[[
注册UI消息
]]
function XunBaoPopUI:RegistMsgs()
    self.msgIds = 
    {
        LUITaskDataEvent.WanFaDailyTaskInfo,
        LUITaskDataEvent.WanFaDailyTaskReward,
    }
    self:RegistSelf(self,self.msgIds)
end

function XunBaoPopUI:ProcessEvent(msg)
    if msg.msgId == LUITaskDataEvent.WanFaDailyTaskInfo then
        local value = msg.value
        if #value ~= 2 or value[1] ~= 3 then
            return
        end
        self.m_datas = value[2] or {}
        self:DataSort()
        self:ShowRewardList()
    elseif msg.msgId == LUITaskDataEvent.WanFaDailyTaskReward then
        local value = msg.value
        if #value ~= 3 or value[1] ~= 3 then
            return
        end
        self:SetTaskState(value[2])
        self:SetTaskData(value[3] or {})
        self:DataSort()
        self:ShowRewardList()
        self:TaskRedCheck()
        -- if self.m_getBtn:isVisible() then
        --     self:OnKeyGetCallBack()
        -- end
    end
end

function XunBaoPopUI:InitData()
    --合成成功界面
    self.m_heChengPanel = self.m_pUILayer:getChildByName("Hecheng")
    local maskImg = self.m_heChengPanel:getChildByName("Black")
    maskImg:addClickEventListener(handler(self,XunBaoPopUI.CloseUI))
    self.m_iconImg = self.m_heChengPanel:getChildByName("Bg"):getChildByName("Icon")
    self.m_nameLabel = self.m_heChengPanel:getChildByName("NameBg"):getChildByName("Name")
    self.m_descLabel = self.m_heChengPanel:getChildByName("TextBg"):getChildByName("Text_3")
    self.m_titleLabel = self.m_heChengPanel:getChildByName("Title")
    self.m_titleLabel:setScale(2)
    self.m_closeBtn = self.m_nameLabel
    --self.m_titleLabel:setOpacity(0)

    --一键寻宝界面
    self.m_oneKeyPanel = self.m_pUILayer:getChildByName("Popup")
    local oneKeyBg = self.m_oneKeyPanel:getChildByName("bg")
    local closeBtn1 = oneKeyBg:getChildByName("Btn_close")
    closeBtn1:addClickEventListener(handler(self,XunBaoPopUI.CloseUI))
    local boxPanel = oneKeyBg:getChildByName("Panel_1")
    self.nameLabel2 = boxPanel:getChildByName("text"):getChildByName("Name")
    self.tmpLabel = self.nameLabel2:getChildByName("Text1")
    closeBtn2 = self.m_oneKeyPanel:getChildByName("Btn_2")
    closeBtn2:addClickEventListener(handler(self,XunBaoPopUI.CloseUI))
    local okBtn = self.m_oneKeyPanel:getChildByName("Btn_1")
    okBtn:addClickEventListener(handler(self,XunBaoPopUI.OneKeyCallBack))
    self.m_checkBox1 = self.m_oneKeyPanel:getChildByName("CheckBox_0")
    self.m_checkBox1:addEventListener(handler(self, XunBaoPopUI.CheckBox1Callback))
    self.m_checkBox1:setSelected(false)
    self.m_checkBox2 = boxPanel:getChildByName("CheckBox")
    self.m_checkBox2:addEventListener(handler(self, XunBaoPopUI.CheckBox2Callback))
    self.m_checkBox2:setSelected(true)
    self.m_oneKeySign = 0--本次登录不提示
    self.m_autoUse = 1--自动使用

    --奖励界面
    self.m_rewardPanel = self.m_pUILayer:getChildByName("Rewards")
    self.m_rewardPanel:setVisible(false)
    local popupPanel3 = self.m_rewardPanel:getChildByName("Popup")
    self.m_rewardCell = popupPanel3:getChildByName("Reward")
    self.m_rankRewardIcon = popupPanel3:getChildByName("IconBg")
    local bg3 = popupPanel3:getChildByName("bg")
    self.m_rewardListView = bg3:getChildByName("Image2"):getChildByName("ListView")
    self.m_tzCntLabel = bg3:getChildByName("Times"):getChildByName("Text")
    local closeBtn3 = popupPanel3:getChildByName("Btn_close")
    closeBtn3:addClickEventListener(handler(self,XunBaoPopUI.CloseUI))
    self.m_getBtn = bg3:getChildByName("Btn")
    --self.m_getBtn:addClickEventListener(handler(self,XunBaoPopUI.OnKeyGetCallBack))
    self.m_getBtn:setVisible(false)
    self.m_cntLabels = {}
    self.m_drawImgs = {}
    self.m_drawBtns = {}
end

function XunBaoPopUI:ShowHeChengInfo()
    if self.m_id == 0 then
        return
    end
    local cfg = JsonConfig.m_faBaoConfig.getDefByID(self.m_id)
    if cfg == nil then
        return
    end
    self.m_nameLabel:setString(cfg.name.."X1")
    self.m_nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    local str = ""
    if #cfg.attr == 2 then
        str = Utils:getAttrStr(cfg.attr[1], cfg.attr[2])
    end
    self.m_descLabel:setString(str)
    local imgPath = "item/"..cfg.pic..".png"
    Utils:SafeLoadTexture(self.m_iconImg,imgPath,ccui.TextureResType.localType)
end

function XunBaoPopUI:ShowOneKeyInfo()
    if self.m_id == 0 then
        return
    end
    local cfg = JsonConfig.m_faBaoConfig.getDefByID(self.m_id)
    if cfg == nil then
        return
    end
    self.nameLabel2:setString(cfg.name)
    self.tmpLabel:setPositionX(self.nameLabel2:getAutoRenderSize().width)
end

function XunBaoPopUI:ShowLayer()
    self.m_heChengPanel:setVisible(false)
    self.m_oneKeyPanel:setVisible(false)
    self.m_rewardPanel:setVisible(false)
    if self.m_tab == nil or self.m_tab == 0 then
        return
    end
    if self.m_tab == 1 then
        self.m_heChengPanel:setVisible(true)
        local fadeIn = cc.FadeIn:create(0.33)
        local scaleto = cc.ScaleTo:create(0.17, 1)
        local seq = cc.Sequence:create(fadeIn,scaleto)
        self.m_titleLabel:runAction(seq)
        local action = cc.CSLoader:createTimeline("csd/wanfa/Xunbao_popupLayer.csb")
        self.m_pUILayer:runAction(action)
        action:pause()
        action:gotoFrameAndPlay(0,120,true)
        self:ShowHeChengInfo()
    elseif self.m_tab == 2 then
        self.m_oneKeyPanel:setVisible(true)
        self:ShowOneKeyInfo()
    elseif self.m_tab == 3 then
        self.m_rewardPanel:setVisible(true)
        LuaNetSendMsg:QueryGotTaskList(3)
        --self:ShowRewardList()
    end
end

--寻宝,一键
function XunBaoPopUI:OneKeyCallBack(sender)
    if self.m_id == 0 then
        return
    end
    local data = LActivityManager:GetXunBaoData()
    data.m_oneKeySign = self.m_oneKeySign
    data.m_autoUse = self.m_autoUse
    LuaNetSendMsg:SendXunBaoOneKeyReq(self.m_id,self.m_autoUse)
    --print("XunBaoPopUI:OneKeyCallBack",self.m_id)
    self:CloseUI()
end

function XunBaoPopUI:CheckBox1Callback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        self.m_oneKeySign = 1
    elseif eventType == ccui.CheckBoxEventType.unselected then
        self.m_oneKeySign = 0
    end
end

function XunBaoPopUI:CheckBox21Callback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        self.m_autoUse = 1
    elseif eventType == ccui.CheckBoxEventType.unselected then
        self.m_autoUse = 0
    end
end

function XunBaoPopUI:ShowRewardList()
    --print("KaPaiArenaUI:ShowRecordList",tab)
    self.m_rewardListView:removeAllItems()
    local datas = self.m_showIds--LRoleDataMgr.Task:GetTaskDataByType(3)
    local id = self:GetLastId()
    local cnt = 0
    local sign = false
    for i=1,#datas do
        local cell = self.m_rewardCell:clone()
        cell.userObject = i
        self.m_rewardListView:pushBackCustomItem(cell)
        local data = self:GetTaskData(datas[i].id)
        self:ShowOneReward(cell,data,cnt)
        if id == data.task_id then
            cnt = data.taskActiveNum
        end
        if data.state == 1 then
            sign = true
        end
    end
    self.m_tzCntLabel:setString(""..cnt)
    --self.m_getBtn:setVisible(sign)
end

function XunBaoPopUI:GetTaskData(id)
    if id == nil then
        return nil
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.task_id == id then
            return data
        end
    end
    return nil
end


function XunBaoPopUI:GetTaskState(id)
    if id == nil then
        return 0
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.task_id == id then
            return data.state
        end
    end
    return 2
end

function XunBaoPopUI:SetTaskState(id)
    if id == nil or self.m_datas == nil then
        return
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.task_id == id then
            data.state = 2
            break
        end
    end
    --print("SetTaskState",id,self:GetTaskState(id))
end

function XunBaoPopUI:SetTaskData(datas)
    for i=1,#datas do
        local data = self:GetTaskData(datas[i].task_id)
        if data ~= nil then
            data.state = datas[i].state
            data.taskActiveNum = datas[i].taskActiveNum
        else
            table.insert(self.m_datas,datas[i])
        end
    end
end

function XunBaoPopUI:GetLastId()
    local id = 0
    local cfgs = JsonConfig.GetDailyByType(3)
    for i=1,#cfgs do
        if cfgs[i].daily == 1 and cfgs[i].condition[1] == 14 then
            id = cfgs[i].id
        end
    end
    return id
end

function XunBaoPopUI:DataSort()
    self.m_showIds = {}
    local dels = {}
    --dump(self.m_datas)
    for i=1,#self.m_datas do
        local cfg = JsonConfig.m_dailyConfig.getDefByID(self.m_datas[i].task_id)
        if cfg ~= nil and (cfg.show == 0 or self:GetTaskState(cfg.show) == 2) then
            if cfg.show > 0 then
                table.insert(dels,cfg.show)
            end
            local value = {}
            value.id = cfg.id
            value.state = self:GetTaskState(cfg.id)
            if value.state == 0 then
                value.state = 1 
            elseif value.state == 1 then
                value.state = 0
            end
            table.insert(self.m_showIds,value)
        end
    end
    for i=1,#dels do
        for k=1,#self.m_showIds do
            if self.m_showIds[k].id == dels[i] then
                table.remove(self.m_showIds,k)
                break
            end
        end
    end
    --table.sort(self.m_showIds)
    local function sortFuc(m1, m2)
        if m1.state == m2.state then
            return m1.id < m2.id
        end
        return m1.state < m2.state
    end
    table.sort(self.m_showIds, sortFuc)
end

function XunBaoPopUI:ShowOneReward(sender,data)
    local idx = sender.userObject
    local tipLabel = sender:getChildByName("Num")
    self.m_cntLabels[idx] = sender:getChildByName("Value")

    local listView = sender:getChildByName("ListView")
    self.m_drawImgs[idx] = sender:getChildByName("Get")
    self.m_drawBtns[idx] = sender:getChildByName("Btn")
    self.m_drawBtns[idx].userObject = data.task_id
    self.m_drawBtns[idx]:addClickEventListener(function(sender)--领取奖励
        local id = sender.userObject
        LuaNetSendMsg:QueryGotTaskAward(3, id)
    end)
    
    --self.m_drawBtns[idx]:setVisible(false)
    self.m_drawBtns[idx]:setVisible(true)
    self.m_drawImgs[idx]:setVisible(false)
    self.m_drawBtns[idx]:setEnabled(false)
    
    listView:setTouchEnabled(false)
    listView:removeAllItems()
    local cfgData = JsonConfig.m_dailyConfig.getDefByID(data.task_id)
    if cfgData == nil then
        return
    end
    for i=1,#cfgData.reward do
        local value = cfgData.reward[i]
        local cell = self.m_rankRewardIcon:clone()
        --local iconImg = cell:getChildByName("Icon")
        --local cntLabel = cell:getChildByName("Text_5")
        --local imgPath = LDataConstMgr:GetRewardItemPicPath(value)
        --Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
        --cntLabel:setString(""..value[3])
        if value[1] == AppDef.RewardItem.RD_ITEM_FABAO then
            Utils:GetFaBaoCellValue(cell,nil,value[2],0, true, value[3], 0,0,true,true)
        elseif value[1] == AppDef.RewardItem.RD_ITEM_EQUIP then
            Utils:GetEquipCellByEquipID(cell, nil, value[2], true, true,true)
        elseif value[1] == AppDef.RewardItem.RD_ITEM_PET then
            local petData = LPetData:New(value[2])
            Utils:GetPetHeadCellValue(cell, nil, petData, true, true, true)
        else
            local item = Utils:GetItemCellValue(cell, 0, value[1], true, true, value[3], nil, true, true)
            item:SetShowFrom(false)
        end

        listView:pushBackCustomItem(cell)
    end
    local max = cfgData.condition[2]
    tipLabel:setString(cfgData.des)
    --curCnt = 0
    local cnt  = 0
    -- if cfgData.daily == 1 then
    --     curCnt = data.taskActiveNum
    -- end
    cnt  = data.taskActiveNum
    if cnt > max then
        cnt = max
    end
    if cnt == max then
        if data.state == 1 then
            self.m_drawBtns[idx]:setEnabled(true)
        elseif data.state == 2 then
            self.m_drawBtns[idx]:setVisible(false)
            self.m_drawImgs[idx]:setVisible(true)
        end
    end  
    self.m_cntLabels[idx]:setString(""..cnt.."/"..max) 
end

function XunBaoPopUI:OnKeyGetCallBack(sender)
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.state == 1 then
            LuaNetSendMsg:QueryGotTaskAward(3,data.task_id)
            break
        end
    end
end

function XunBaoPopUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "WanFa.XunBaoPopUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XunBaoPopUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_XunBao_7)
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_id = nil
    self.Script  = nil
    self.m_cntLabels = nil
    self.m_drawImgs = nil
    self.m_drawBtns = nil
    self.m_datas = nil
    Utils:CheckGuide(GuideDef.StepId.Guide_XunBao_8)
end

function XunBaoPopUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_7, self.m_closeBtn, handler(self,XunBaoPopUI.CloseUI), nil, true)
end 

--每日任务-寻宝
function XunBaoPopUI:TaskRedCheck(value)
    local show = false
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.state == 1 then
            show = true
            break
        end
    end
    Utils:SetRedDotState(RedDotDef.ID.XunBaoTask, show)
end

return XunBaoPopUI
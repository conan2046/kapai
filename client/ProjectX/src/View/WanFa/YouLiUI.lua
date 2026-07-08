local TimerLabelUI = require("View.Common.TimerLabelUI")
local YouLiUI = LUIBase:New()
YouLiUI.__index = YouLiUI
YouLiUI.IsHideInBattle = true
function YouLiUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,YouLiUI) 
    o:Init(userData)
    return o
end

--[[
注册消息
]]
function YouLiUI:RegistMsgs()
    self.msgIds = 
    {
         LHuiShouEvent.SelectShengJiang,
         LUIActivityEvent.RefreshYouLiUI,
    }
    self:RegistSelf(self,self.msgIds)
end

function YouLiUI:ProcessEvent(msg)
    if msg.msgId == LHuiShouEvent.SelectShengJiang then
        self.m_heroId = msg.value or 0
        self:ShowYouLiInfo() 
    elseif msg.msgId == LUIActivityEvent.RefreshYouLiUI then
        self:ShowYouLiInfo() 
    end
end


function YouLiUI:Init(userData)
    self.Script = "WanFa.YouLiUI"
    self:CreateUINode("csd/youli/youli.csb")
    
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData(userData)
    self:initControlUI()
    self:ShowBg()
    self:ShowYouLiInfo()
end

function YouLiUI:InitData(userData)
    self.m_id = userData or 0
    if self.m_id > 0 then
        self.m_cfgData = JsonConfig.m_youliConfig.getDefByID(self.m_id)
    end
    self.m_heroId = 0
    self.m_mType = 0
    self.m_tType = 0
    self.m_cells = {}
    self.m_timers = {}
    self.m_infoPanels = {}
    self.m_modeCheckBoxs = {}
    self.m_timeCheckBoxs = {}
end

function YouLiUI:initControlUI()
    local panel = self.m_pUILayer:getChildByName("youliUI")
    panel:setTouchEnabled(false)
    self.m_addBtnImg = panel:getChildByName("Btn_add")
    self.m_addBtnImg:setTouchEnabled(false)
    self.m_addBtn = self.m_addBtnImg:getChildByName("Image")
    self.m_addBtn:setTouchEnabled(true)
    self.m_addLabel = panel:getChildByName("Text")
    self.m_changeBtn = panel:getChildByName("Btn_Change")
    self.m_changeLabel = panel:getChildByName("Tips")
    self.m_iconNode = panel:getChildByName("Node")
    for i=1,3 do
        self.m_infoPanels[i] = panel:getChildByName("Info_"..i)
    end
    self.m_startBtn = self.m_infoPanels[2]:getChildByName("Btn_youli")
    self.m_lingquBtn = self.m_infoPanels[3]:getChildByName("Btn_Get")
    self.m_lingquLabel1 = self.m_lingquBtn:getChildByName("Text_1")
    self.m_lingquLabel2 = self.m_lingquBtn:getChildByName("Text_2")
    self.m_nextTimeLabel = self.m_infoPanels[3]:findChildByName("Panel_1/Time")
    self.m_endTimeLabel = self.m_infoPanels[3]:getChildByName("Time")

    self.m_addBtn:addClickEventListener(handler(self,YouLiUI.AddHeroCallBack))
    self.m_changeBtn:addClickEventListener(handler(self,YouLiUI.AddHeroCallBack))
    self.m_startBtn:addClickEventListener(handler(self,YouLiUI.StartCallBack))
    self.m_lingquBtn:addClickEventListener(handler(self,YouLiUI.LingQuCallBack))
end

function YouLiUI:ShowBg()
    if self.m_cfgData ~= nil then
        Utils:SendMsg(LUIFClassBgEvent.SetTitle, self.m_cfgData.name)
        local path = "res2/InstancesBg"..self.m_cfgData.pic2
        Utils:SendMsg(LUIFClassBgEvent.BGChange,path)
    end
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,YouLiUI.RemoveUI))
end

function YouLiUI:ShowYouLiInfo()
    self:GetData()
    self:ShowInfo()
end

function YouLiUI:GetData()
    local data = LActivityManager:GetYouLiData()
    for i=1,#data.m_youlis do
        local value = data.m_youlis[i]
        if value.id == self.m_id then
            self.m_data = value
            if self.m_heroId == 0 then
                self.m_heroId = self.m_data.heroId
            end
            if self.m_data.heroId > 0 then
                self.m_mType = self.m_data.mType
                self.m_tType = self.m_data.tType
            end
            break
        end
    end
end

function YouLiUI:ShowInfo()
    if self.m_data == nil then
        return
    end
    if self.m_data.heroId == 0 then
        if self.m_heroId == 0 then
            self:ShowRight1()
        else
            self:ShowRight2()
        end
    else
        self:ShowRight3()
    end
    self:ShowIcon()
end

function YouLiUI:ShowIcon()
    local str = AppDef.ColorKuangArr[1]
    self.m_addBtnImg:loadTextureNormal(str,ccui.TextureResType.plistType)
    if self.m_heroId == 0 then
        self.m_changeBtn:setVisible(false)
        self.m_addBtn:setVisible(true)
        self.m_addLabel:setVisible(true)
        self.m_changeLabel:setString("")
        if self.m_petCell ~= nil then
            self.m_petCell.m_pUILayer:setVisible(false)
        end
        return
    end

    self.m_addBtn:setVisible(false)
    self.m_addLabel:setVisible(false)
    self.m_changeBtn:setVisible(true)
    local cfg = JsonConfig.m_heroCfg.getDefByID(self.m_heroId)
    if cfg ~= nil then
        self.m_changeLabel:setString(string.format(GUITips.RSI_WANFA_TIPS13,cfg.name,cfg.name))
        local str = AppDef.ColorKuangArr[cfg.quality]
        self.m_addBtnImg:loadTextureNormal(str,ccui.TextureResType.plistType)
        if self.m_data.heroId > 0 then
            self.m_changeBtn:setVisible(false)
        end
    end
    if self.m_petCell == nil then
        self.m_petCell = PetCellUI:New(self.m_addBtnImg, {self.m_heroId})
    else
        self.m_petCell.m_pUILayer:setVisible(true)
        self.m_petCell:UpdateItem({self.m_heroId})
    end
end

function YouLiUI:ShowRight1()
    self.m_infoPanels[1]:setVisible(true)
    self.m_infoPanels[2]:setVisible(false)
    self.m_infoPanels[3]:setVisible(false)
    self.m_infoPanels[1]:findChildByName("Panel_2/Title_2"):setVisible(false)
    self.m_infoPanels[1]:findChildByName("Panel_2/ListView_2"):setVisible(false)
    local listview = self.m_infoPanels[1]:findChildByName("Panel_2/ListView_1")
    local cell = self.m_infoPanels[1]:findChildByName("Panel_2/Item")
    local titleLabel = self.m_infoPanels[1]:findChildByName("Panel_2/Title_1")
    titleLabel:setString(GUITips.RSI_WANFA_TIPS12)
    local descLabel = self.m_infoPanels[1]:findChildByName("Panel_3/Desc")
    descLabel:setString("")
    if self.m_cfgData == nil then
        return
    end
    local mapLabel = self.m_infoPanels[1]:findChildByName("Panel_3/Title")
    mapLabel:setString(self.m_cfgData.name)
    --descLabel:setString(self.m_cfgData.des)
    listview:removeAllItems()
    for i=1,#self.m_cfgData.show do
        local item = cell:clone()
        local value = self.m_cfgData.show[i]
        Utils:ShowItemByConfigData(value, item, nil, false, true,false)
        listview:pushBackCustomItem(item)
    end
end

function YouLiUI:ShowRight2()
    self.m_infoPanels[2]:setVisible(true)
    self.m_infoPanels[1]:setVisible(false)
    self.m_infoPanels[3]:setVisible(false)
    local listview = self.m_infoPanels[2]:findChildByName("Panel_1/ListView_1")
    local cell = self.m_infoPanels[2]:findChildByName("Panel_1/Item")
    listview:removeAllItems()
    if self.m_heroId > 0 then
        local cfg = JsonConfig.m_heroCfg.getDefByID(self.m_heroId)
        if cfg ~= nil then
            local item = cell:clone()
            Utils:ShowItemByConfigData({cfg.itemId,0,1}, item, nil, false, true,false)
            listview:pushBackCustomItem(item)
        end
    end
    for i=1,#self.m_cfgData.show do
        local item = cell:clone()
        local value = self.m_cfgData.show[i]
        Utils:ShowItemByConfigData(value, item, nil, false, true,false)
        listview:pushBackCustomItem(item)
    end
    local panel2 = self.m_infoPanels[2]:getChildByName("Panel_2")
    self.m_modeCheckBoxs[1] = panel2:findChildByName("chuji/CheckBox")
    self.m_modeCheckBoxs[2] = panel2:findChildByName("zhongji/CheckBox")
    self.m_modeCheckBoxs[3] = panel2:findChildByName("gaoji/CheckBox")
    for i=1,3 do
        self.m_modeCheckBoxs[i].userObject = i
        self.m_modeCheckBoxs[i]:addEventListener(handler(self, YouLiUI.ModeCallback))
        local lock = self.m_modeCheckBoxs[i]:getParent():getChildByName("Lock")
        if lock ~= nil then
            lock:setVisible(false)
        end
    end
    for i=1,3 do
        self.m_timeCheckBoxs[i] = self.m_infoPanels[2]:findChildByName("Panel_3/CheckBox_"..i)
        self.m_timeCheckBoxs[i].userObject = i
        self.m_timeCheckBoxs[i]:addEventListener(handler(self, YouLiUI.TimeCallback))
    end
    if self.m_mType == 0 then
        self:ModeCallback(self.m_modeCheckBoxs[1],ccui.CheckBoxEventType.selected)
    end
    if self.m_tType == 0 then
        self:TimeCallback(self.m_timeCheckBoxs[3],ccui.CheckBoxEventType.selected)
    end
    self:ShowCost()
end

function YouLiUI:ShowCost()
    if self.m_mType == 0 or self.m_tType == 0 or self.m_heroId == 0 then
        return
    end
    local costImg = self.m_infoPanels[2]:findChildByName("ConsumeBg/Text/Icon")
    local costLabel = self.m_infoPanels[2]:findChildByName("ConsumeBg/Value")
    --local cnt = self:GetCnt()
    local costCfg = JsonConfig.m_youliCost.getDefByID(self.m_mType)
    if costCfg ~= nil then
        local imgPath = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(costCfg.cost[1][1])..".png"
        Utils:SafeLoadTexture(costImg,imgPath,ccui.TextureResType.plistType)
        local v = 0
        for k=1,#costCfg.cost do
            if costCfg.cost[k][1] == costCfg.cost[1][1] then
                v = v +costCfg.cost[k][3]
            end
        end
        costLabel:setString(""..v*self.m_tType)
    end
end

function YouLiUI:ModeCallback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        local idx = sender.userObject
        self.m_modeCheckBoxs[idx]:setTouchEnabled(false)
        for i=1,3 do
            if i ~= idx then
                self.m_modeCheckBoxs[i]:setTouchEnabled(true)
                self.m_modeCheckBoxs[i]:setSelected(false)
            end
        end
        self.m_mType = idx
        self:ShowCost()
    end
end

function YouLiUI:TimeCallback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        local idx = sender.userObject
        self.m_timeCheckBoxs[idx]:setTouchEnabled(false)
        for i=1,3 do
            if i ~= idx then
                self.m_timeCheckBoxs[i]:setTouchEnabled(true)
                self.m_timeCheckBoxs[i]:setSelected(false)
            end
        end
        self.m_tType = idx
        self:ShowCost()
    end
end

function YouLiUI:ShowRight3()
    self.m_infoPanels[3]:setVisible(true)
    self.m_infoPanels[1]:setVisible(false)
    self.m_infoPanels[2]:setVisible(false)
    --self.m_lingquBtn = self.m_infoPanels[3]:getChildByName("Btn_Get")
    local listview1 = self.m_infoPanels[3]:findChildByName("Panel_1/ListView")
    local cell1 = self.m_infoPanels[3]:findChildByName("Panel_1/Item")
    local listview2 = self.m_infoPanels[3]:findChildByName("Panel_2/ListView")
    local cell2 = self.m_infoPanels[3]:findChildByName("Panel_2/Item")
    listview1:removeAllItems()
    self.m_nextTimeLabel:setString("")
    self.m_endTimeLabel:setString("")
    self.m_lingquBtn:setEnabled(false)
    self.m_lingquLabel1:setVisible(false)
    self.m_lingquLabel2:setVisible(true)
    if self.m_heroId == 0 or self.m_data == nil then
        return
    end
    local heroCfg = JsonConfig.m_heroCfg.getDefByID(self.m_heroId)
    if heroCfg == nil then
        return
    end
    if self.m_data.rewards == nil then
        return
    end
    listview2:removeAllItems()
    for i=1,#self.m_data.rewards do
        local rewards = self.m_data.rewards[i] or {}
        for k=1,#rewards do
            local item = cell2:clone()
            local value = rewards[k]
            Utils:ShowItemByConfigData(value, item, nil, false, true,true)
            listview2:pushBackCustomItem(item)
        end
    end
    if self.m_data.dialogIds == nil then
        return
    end
    for i=1,#self.m_data.dialogIds do
        local cfg = JsonConfig.m_youliDialog.getDefByID(self.m_data.dialogIds[i])
        if cfg ~= nil then
            local item = Utils:CreateColorText3(cell1, false)
            local str = cfg.des
            string.gsub(str,"%e",heroCfg.name)
            local strReward = ""
            local rewards = self.m_data.rewards[i] or {}
            for k=1,#rewards do
                strReward = strReward.." "..Utils:getItemNameByID(rewards[k][1],rewards[k][2]).."x"..rewards[k][3]
            end
            string.gsub(str,"%d",strReward)
            item:setString(cfg.des)
            listview1:pushBackCustomItem(item)
        end
    end
    if self.m_data.endTime == nil or self.m_data.lastTime == nil then
        return
    end
    local now = LDataConstMgr.m_serverTime--os.time()
    print("now now now now ",now)
    if now >= self.m_data.endTime then
        self.m_lingquBtn:setEnabled(true)
        self.m_lingquLabel1:setVisible(true)
        self.m_lingquLabel2:setVisible(false)
        return
    end
    if self.m_endTimer == nil then
        self.m_endTimer = TimerLabelUI:New(self.m_endTimeLabel,self.m_data.endTime - now,handler(self,YouLiUI.OnEndTimerEnd),nil,false,0)
    end
    self.m_endTimer:start()
    if self.m_mType > 0 then
        local time = 0
        local cfg = JsonConfig.m_youliCost.getDefByID(self.m_mType)
        if cfg ~= nil then
            local tmpTime = now-self.m_data.lastTime
            if tmpTime < 0 then tmpTime = 0 end
            time = cfg.interval*60 - tmpTime
        end
        if time < 0 then time = 1 end
        if self.m_nextTimer == nil then
            self.m_nextTimer = TimerLabelUI:New(self.m_nextTimeLabel,time,handler(self,YouLiUI.OnNextTimerEnd),handler(self,YouLiUI.OnNextTimerUpdate),false,0)
        end
        self.m_nextTimer:start()
    end
end

function YouLiUI:OnEndTimerEnd()
    self.m_lingquBtn:setVisible(true)
    self.m_lingquLabel1:setVisible(true)
    self.m_lingquLabel2:setVisible(false)
    self.m_endTimeLabel:setString("")
end

function YouLiUI:OnNextTimerUpdate(label,h,m,s,leftTime)
    label:setString(string.format(GUITips.RSI_WANFA_TIPS14,h,m,s))
end

function YouLiUI:OnNextTimerEnd()
    LuaNetSendMsg:QueryYouLiInfo()--请求数据
end

function YouLiUI:AddHeroCallBack(sender)
    if self.m_data == nil then
        return
    end
    local cfg = JsonConfig.m_youliConfig.getDefByID(self.m_id)
    if cfg == nil then
        return
    end
    local data = LActivityManager:GetYouLiData()
    local heroIds = {}
    for i=1,#data.m_youlis do
        if data.m_youlis[i].heroId > 0 then
            table.insert(heroIds,data.m_youlis[i].heroId)
        end
    end
    table.insert(heroIds,self.m_heroId)
    Utils:InitUI("HuiShou.ShengJiangChooseUI",AppDef.UIType.PopFirstClassLayer,{1,cfg.quality,heroIds}) 
end

function YouLiUI:StartCallBack(sender)
    if self.m_data == nil then
        return
    end
    if self.m_heroId == 0 then
        return
    end
    if self.m_mType == 0 or self.m_tType == 0 then
        return
    end
    local cfg = JsonConfig.m_youliCost.getDefByID(self.m_mType)
    if cfg == nil then
        return
    end
    --local cnt = self:GetCnt()
    for i=1,#cfg.cost do
        local tmp = {}
        tmp[1] = cfg.cost[i][1]
        tmp[2] = 0
        tmp[3] = cfg.cost[i][3]*self.m_tType
        if not LRoleDataMgr:CheckIsEnough(tmp) then
            Utils:ShowScrollTips(string.format(GUITips.RSI_SHOP_TIPS3,AppDef.SpecialItemName[cfg.cost[i][1]]))
            return
        end
    end
    local value = {}
    value.id = self.m_id
    value.heroId = self.m_heroId
    value.mType = self.m_mType
    value.tType = self.m_tType
    LuaNetSendMsg:SendYouLiStartReq({value})
end

function YouLiUI:LingQuCallBack(sender)
    if self.m_id == 0 then
        return
    end
    LuaNetSendMsg:SendYouLiPrizeReq({self.m_id})
end

function YouLiUI:GetCnt()
    local cfg = JsonConfig.m_youliCost.getDefByID(self.m_mType)
    if cfg == nil or self.m_heroId == 0  then
        return 0
    end
    --print("GetCnt m_tType m_mType",self.m_tType,self.m_mType)
    local hours = {4,8,12}
    local mTimes = {30,20,10}
    if cfg.interval == 0 then cfg.interval = mTimes[self.m_mType] end
    local cnt = math.floor(hours[self.m_tType]*60/cfg.interval)
    return cnt
end

function YouLiUI:onExit()
    if self.m_petCell ~= nil then
        self.m_petCell:onExit()
    end
    self.m_petCell = nil
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_heroId = nil
    self.m_mType = nil
    self.m_tType = nil
    self.m_cells = nil
    self.m_timers = nil
    self.m_infoPanels = nil
    self.m_modeCheckBoxs = nil
    self.m_timeCheckBoxs = nil
end

function YouLiUI:OnEnter()
    self:ShowBg()
end

return YouLiUI
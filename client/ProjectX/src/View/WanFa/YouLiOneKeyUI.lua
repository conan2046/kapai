--local TimerLabelUI = require("View.Common.TimerLabelUI")
local YouLiOneKeyUI = LUIBase:New()
YouLiOneKeyUI.__index = YouLiOneKeyUI
YouLiOneKeyUI.IsHideInBattle = true
function YouLiOneKeyUI:New()
    local o = LUIBase:New()
    setmetatable(o,YouLiOneKeyUI) 
    o:Init()
    return o
end

--[[
注册消息
]]
function YouLiOneKeyUI:RegistMsgs()
    self.msgIds = 
    {
         LHuiShouEvent.SelectShengJiang,
         LUIActivityEvent.CloseShenJiangChooseUI,
         LUIActivityEvent.YouLiModeChoose,
         LUIActivityEvent.YouLiTimeChoose,
    }
    self:RegistSelf(self,self.msgIds)
end

function YouLiOneKeyUI:ProcessEvent(msg)
    if msg.msgId == LHuiShouEvent.SelectShengJiang then
        if self.m_idx == 0 or self.m_idx > #self.m_datas then
            return
        end
        local value = self.m_datas[self.m_idx]
        value.heroId = msg.value
        if value.heroId > 0 then
            self:ShowOneYouLi(self.m_cells[self.m_idx],value)
            self:ShowCost()
        end
        self.m_idx = 0
    elseif msg.msgId == LUIActivityEvent.CloseShenJiangChooseUI then
        self:SetVisible(true)
    elseif msg.msgId == LUIActivityEvent.YouLiModeChoose then
        self:ShowMode(self.m_idx,msg.value)
        self.m_idx = 0
    elseif msg.msgId == LUIActivityEvent.YouLiTimeChoose then
        self:ShowTime(self.m_idx,msg.value)
        self.m_idx = 0
    end
end


function YouLiOneKeyUI:Init()
    self.Script = "WanFa.YouLiOneKeyUI"
    self:CreateUINode("csd/youli/yijianyouli.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/fengshenliezhuan/fengshenliezhuanlLayer.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:initControlUI()
    self:ShowYouLiList()
    self:ShowCost()
end

function YouLiOneKeyUI:InitData()
    self.m_cells = {}
    self.m_datas = {}
    self.m_costImgs = {}
    self.m_costLabels = {}
    self.m_idx = 0
    local str = LUserConfigMgr:GetYouLiInfo()
    local list = {}
    if #str > 0 then
        --print("YouLiOneKeyUI InitData",str)
        list = json.decode(str)
        if list == nil then
            list = {}
        end
    end
    local saveInfos = {}
    for i=1,#list do
        local value = list[i]
        saveInfos[value[1]] = {}
        saveInfos[value[1]].heroId = value[2]
        saveInfos[value[1]].mType = value[3]
        saveInfos[value[1]].tType = value[4]
    end
    local level = LRoleDataMgr.MyHeroInfo.level
    local datas = JsonConfig.m_youliConfig.getList()
    for i=1,#datas do
        local value = datas[i]
        if value.unlock < level then
            local tmp = {}
            tmp.id = value.id
            tmp.heroId = 0
            tmp.mType = 1
            tmp.tType = 1
            if saveInfos[value.id] ~= nil then
                tmp.heroId = saveInfos[value.id].heroId
                tmp.mType = saveInfos[value.id].mType
                tmp.tType = saveInfos[value.id].tType
                if tmp.mType < 1 then tmp.mType = 1 end
                if tmp.tType < 1 then tmp.tType = 1 end
                if tmp.mType > 3 then tmp.mType = 3 end
                if tmp.tType > 3 then tmp.tType = 3 end
            end
            table.insert(self.m_datas,tmp)
        end
    end
end

function YouLiOneKeyUI:initControlUI()
    --关卡
    local panel = self.m_pUILayer:getChildByName("Popup")
    self.m_listView = panel:getChildByName("ListView")
    self.m_cell = panel:getChildByName("Item")
    self.m_cell:retain()
    self.m_cell:removeFromParent()

    self.m_costPanel = panel:getChildByName("ConsumeBg")
    for i=1,2 do
        local bg = self.m_costPanel:getChildByName("Consume"..i)
        self.m_costImgs[i] = bg:getChildByName("Icon")
        self.m_costLabels[i] = bg:getChildByName("Value")
    end

    local saveBtn = panel:getChildByName("Btn_Save")
    saveBtn:addClickEventListener(handler(self,YouLiOneKeyUI.SaveCallBack))
    local startBtn = panel:getChildByName("Btn_Start")
    startBtn:addClickEventListener(handler(self,YouLiOneKeyUI.StartCallBack))
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self,YouLiOneKeyUI.RemoveUI))
end

function YouLiOneKeyUI:ShowCost()
    self.m_costPanel:setVisible(false)
    if #self.m_datas == 0 then
        return
    end
    local costs = {}
    for i=1,#self.m_datas do
        local value = self.m_datas[i]
        --self:GetCnt(i)
        self:CheckCost(value.mType,value.heroId,value.tType,costs)
    end
    if next(costs) ~= nil then
        self.m_costPanel:setVisible(true)
    end
    local num = 1
    for k,v in pairs(costs) do
        if k > 0 then
            self.m_costLabels[num]:getParent():setVisible(true)
            local imgPath = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(k)..".png"
            Utils:SafeLoadTexture(self.m_costImgs[num],imgPath,ccui.TextureResType.plistType)
            self.m_costLabels[num]:setString(""..v)
        end
        num = num +1
    end
    for i=num,2 do
        self.m_costLabels[i]:getParent():setVisible(false)
    end
end

function YouLiOneKeyUI:CheckCost(mType,heroId,cnt,costs)
    local cfg = JsonConfig.m_youliCost.getDefByID(mType)
    if cfg == nil then
        return
    end
    cnt = cnt or 1
    for k=1,#cfg.cost do
        local cost = cfg.cost[k]
        if #cost == 3 and cost[1] > 0 then
            if costs[cost[1]] == nil then
                costs[cost[1]] = 0
            end
            if heroId > 0 then
                costs[cost[1]] = costs[cost[1]] + cost[3]*cnt
            end
        end
    end

end

function YouLiOneKeyUI:ShowYouLiList()
    for i=1,#self.m_datas do
        local value = self.m_datas[i]
        if self.m_cells[i] == nil then
            self.m_cells[i] = self.m_cell:clone()
            self.m_listView:pushBackCustomItem(self.m_cells[i])
            self.m_cells[i]:setTouchEnabled(false)
            local addBtn = self.m_cells[i]:findChildByName("Icon/Btn_add")
            addBtn.userObject = i
            addBtn:addClickEventListener(handler(self,YouLiOneKeyUI.AddHeroCallBack))
            local closeBtn = self.m_cells[i]:findChildByName("Icon/Btn_Close")
            closeBtn.userObject = i
            closeBtn:addClickEventListener(handler(self,YouLiOneKeyUI.DelHeroCallBack))
            local modeBtn = self.m_cells[i]:getChildByName("Btn_Level")
            modeBtn.userObject = i
            modeBtn:addClickEventListener(handler(self,YouLiOneKeyUI.ModeBtnCallBack))
            local timeBtn = self.m_cells[i]:getChildByName("Btn_Time")
            timeBtn.userObject = i
            timeBtn:addClickEventListener(handler(self,YouLiOneKeyUI.TimeBtnCallBack))
        end
        self:ShowOneYouLi(self.m_cells[i],value)
    end
end

function YouLiOneKeyUI:ModeBtnCallBack(sender)
    self.m_idx = sender.userObject
    Utils:InitUI("WanFa.YouLiModeUI",AppDef.UIType.PopWindow)
end

function YouLiOneKeyUI:TimeBtnCallBack(sender)
    self.m_idx = sender.userObject
    Utils:InitUI("WanFa.YouLiTimeUI",AppDef.UIType.PopWindow)
end

function YouLiOneKeyUI:ShowOneYouLi(sender,value)
    sender.userObject = value.id
    local nameLabel = sender:getChildByName("Name")
    local HeroNameLabel = sender:findChildByName("shenjiang/Value")
    local modeBtn = sender:getChildByName("Btn_Level")
    local modeLabel = modeBtn:getChildByName("Value")
    local timeBtn = sender:getChildByName("Btn_Time")
    local timeLabel = timeBtn:getChildByName("Value")
    local bgImg = sender:getChildByName("Icon")
    local addBtn = bgImg:getChildByName("Btn_add")
    local closeBtn = bgImg:getChildByName("Btn_Close")
    closeBtn:setLocalZOrder(99)
    local cfg = JsonConfig.m_youliConfig.getDefByID(value.id)
    if cfg == nil then
        return
    end
    nameLabel:setString(cfg.name)
    local color = 1
    if value.heroId == 0 then
        closeBtn:setVisible(false)
        addBtn:setVisible(true)
        HeroNameLabel:setString("")
        local icon = bgImg:getChildByName("petCell")
        if icon ~= nil then
            icon:removeFromParent()
        end
    else
        local heroCfg = JsonConfig.m_heroCfg.getDefByID(value.heroId)
        if heroCfg ~= nil then
            color = heroCfg.quality
            HeroNameLabel:setString(heroCfg.name)
            local icon = bgImg:getChildByName("petCell")
            if icon == nil then
                cellUI = PetCellUI:New(bgImg, {value.heroId})
                cellUI.m_pUILayer:setLocalZOrder(0)
                cellUI.m_pUILayer:setName("petCell")
            end
        end
        closeBtn:setVisible(true)
        addBtn:setVisible(false) 
    end
    local str = AppDef.ColorKuangArr[color]
    Utils:SafeLoadTexture(bgImg,str,ccui.TextureResType.plistType)
    local strModel = GUITips["UI_PET_LearnSkill_LV"..value.mType]..GUITips.RSI_WANFA_TIPS8
    modeLabel:setString(strModel)
    local hours = {4,8,12}
    timeLabel:setString(string.format(GUITips.RSI_WANFA_TIPS7,hours[value.tType]))
end

function YouLiOneKeyUI:ShowMode(idx,mType)
    mType = mType or 0
    local sender = self.m_cells[idx]
    if sender == nil then
        return
    end
    local value = self.m_datas[idx]
    if value == nil then
        return
    end
    if mType > 0 then
        value.mType = mType
    end
    local modeBtn = sender:getChildByName("Btn_Level")
    local modeLabel = modeBtn:getChildByName("Value")
    local strModel = GUITips["UI_PET_LearnSkill_LV"..value.mType]..GUITips.RSI_WANFA_TIPS8
    modeLabel:setString(strModel)
    if value.heroId > 0 then
        self:ShowCost()
    end
end

function YouLiOneKeyUI:ShowTime(idx,tType)
    tType = tType or 0
    local sender = self.m_cells[idx]
    if sender == nil then
        return
    end
    local value = self.m_datas[idx]
    if value == nil then
        return
    end
    if tType > 0 then
        value.tType = tType
    end
    local timeBtn = sender:getChildByName("Btn_Time")
    local timeLabel = timeBtn:getChildByName("Value")
    local hours = {4,8,12}
    timeLabel:setString(string.format(GUITips.RSI_WANFA_TIPS7,hours[value.tType]))
    if value.heroId > 0 then
        self:ShowCost()
    end
end

function YouLiOneKeyUI:AddHeroCallBack(sender)
    local idx = sender.userObject or 0
    if id == 0 then
        return
    end
    local data = self.m_datas[idx]
    if data == nil then
        return
    end
    local cfg = JsonConfig.m_youliConfig.getDefByID(data.id)
    if cfg == nil then
        return
    end
    local heroIds = {}
    for i=1,#self.m_datas do
        if self.m_datas[i].heroId > 0 then
            table.insert(heroIds,self.m_datas[i].heroId)
        end
    end
    self.m_idx = idx
    --Utils:OpenFunction(AppDef.EModuleID.EMID_SHENJIANG_CHOOSE)
    self:SetVisible(false)
    Utils:InitUI("HuiShou.ShengJiangChooseUI",AppDef.UIType.PopFirstClassLayer,{1,cfg.quality,heroIds}) 
end

function YouLiOneKeyUI:DelHeroCallBack(sender)
    local idx = sender.userObject or 0
    if id == 0 then
        return
    end
    local data = self.m_datas[idx]
    if data == nil then
        return
    end
    data.heroId = 0
    self:ShowOneYouLi(self.m_cells[idx],data)
    self:ShowCost()
end

function YouLiOneKeyUI:SaveCallBack(sender)
    if #self.m_datas == 0 then
        return
    end
    local infos = {}
    for i=1,#self.m_datas do
        local value = self.m_datas[i]
        if value.heroId > 0 then
            table.insert(infos,value)
        end
    end
    if #infos == 0 then
        --提示需要选择一个神将
        Utils:ShowScrollTips(GUITips.RSI_WANFA_TIPS10)
        return
    end
    LUserConfigMgr:SetYouLiInfo(infos)
    Utils:ShowScrollTips(GUITips.RSI_WANFA_TIPS11)
end

function YouLiOneKeyUI:StartCallBack(sender)
    local data = LActivityManager:GetYouLiData()
    if data.m_youlis == nil then
        return
    end
    local sign = false
    for i=1,#data.m_youlis do
        if data.m_youlis[i].heroId > 0 then
            sign = true
            break
        end
    end
    if sign then
        --提示只有空闲才可以一键
        Utils:ShowScrollTips(GUITips.RSI_WANFA_TIPS9)
        return
    end
    if #self.m_datas == 0 then
        return
    end
    local infos = {}
    for i=1,#self.m_datas do
        local value = self.m_datas[i]
        if value.heroId > 0 then
            --self:GetCnt(i)
            table.insert(infos,value)
            local cfg = JsonConfig.m_youliCost.getDefByID(value.mType)
            if cfg ~= nil then
                for k=1,#cfg.cost do
                    local tmp = {}
                    tmp[1] = cfg.cost[k][1]
                    tmp[2] = 0
                    tmp[3] = cfg.cost[k][3]*value.tType
                    if not LRoleDataMgr:CheckIsEnough(tmp) then
                        Utils:ShowScrollTips(string.format(GUITips.RSI_SHOP_TIPS3,AppDef.SpecialItemName[cfg.cost[k][1]]))
                        return
                    end
                end
            end
        end
    end
    if #infos == 0 then
        --提示需要选择一个神将
        Utils:ShowScrollTips(GUITips.RSI_WANFA_TIPS10)
        return
    end
    LuaNetSendMsg:SendYouLiStartReq(infos)
    self:RemoveUI()
end

function YouLiOneKeyUI:GetCnt(idx)
    local hours = {4,8,12}
    local mTimes = {30,20,10}
    local value = self.m_datas[idx]
    if value == nil then
        return
    end
    if value.heroId > 0 then
        local cfg = JsonConfig.m_youliCost.getDefByID(value.mType)
        if cfg ~= nil then
            if cfg.interval == 0 then cfg.interval = mTimes[value.mType] end
            value.cnt = math.floor(hours[value.tType]*60/cfg.interval)
        end
    end
end

function YouLiOneKeyUI:CheckHero(id)
    local data = LActivityManager:GetYouLiData()
    if data.m_youlis == nil then
        return false
    end
    local sign = false
    for i=1,#data.m_youlis do
        if data.m_youlis[i].heroId == id then
            return false
        end
    end
    return true
end

function YouLiOneKeyUI:SetVisible(show)
    self.m_pUILayer:setVisible(show)
end

function YouLiOneKeyUI:onExit()
    --Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
    --LActivityManager:YouLiFree()
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_cells = nil
    self.m_datas = nil
    self.m_idx = nil
    self.m_costImgs = nil
    self.m_costLabels = nil
end

--function YouLiOneKeyUI:OnEnter()
    --Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
--end

return YouLiOneKeyUI
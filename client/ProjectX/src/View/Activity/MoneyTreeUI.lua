--[[
lua里面的游戏逻辑控制
玩法-摇钱树
]]

local MoneyTreeUI = LUIBase:New()
MoneyTreeUI.__index = MoneyTreeUI
function MoneyTreeUI:New(parent)
    local o = LUIBase:New()
    setmetatable(o, MoneyTreeUI)
    o:Init(parent)
    return o
end


function MoneyTreeUI:Init(parent)
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/GoldTreeLayer.csb")
    parent:addChild(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()

    --请求摇钱树信息
    LuaNetSendMsg:SendMoneyTreeReq(1,0)
end

function MoneyTreeUI:onExit()
    EffectUtils:GoldEffectFree()
    self.m_pUILayer = nil
    self:Destory()
end

--[[
注册UI消息
]]
function MoneyTreeUI:RegistMsgs()
    self.msgIds =
    {
        LUIActivityEvent.RefreshMoneyTreeUI,-- 刷新页面
        LUIActivityEvent.MoneyEffectPlay
    }
    self:RegistSelf(self, self.msgIds)
end

function MoneyTreeUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshMoneyTreeUI then
        self:ShowInfo()
    elseif msg.msgId == LUIActivityEvent.MoneyEffectPlay then        
        self:ShowEffect(msg.value)
    end
end

function MoneyTreeUI:ShowEffect(type)
    if type == 1 or type ==2 then
        self:DelParitical()
        self:ShowCashEffect(type)
    end
end

--刷新界面
function MoneyTreeUI:ShowInfo()
    local info = LActivityManager.m_moneyTreeData
    if info == nil or #info == 0 then
        --LuaNetSendMsg:SendMoneyTreeReq(1,0)
        return
    end
    for i=1,1 do
        if info[i] ~= nil then
            self["m_getMoneyLabel"..i]:setString(tostring(info[i].getValue))
            self["m_costLabel"..i]:setString(tostring(info[i].costValue))
            local leftNum = info[i].maxNum - info[i].useNum
            if leftNum < 0 then leftNum = 0 end
            self["m_countLabel"..i]:setString(""..leftNum.."/"..info[i].maxNum)
            local freeCnt = info[i].freeNum - info[i].useNum
            local str = ""
            if freeCnt > 0 then 
                str = "("..freeCnt..")" 
                self["m_btnLabel"..i]:setString(GUITips.RSI_MONEYTREE_BTN_3)
				self["m_btnLabel"..i]:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
            else
                self["m_btnLabel"..i]:setString(GUITips["RSI_MONEYTREE_BTN_"..i])
				self["m_btnLabel"..i]:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
            end
            self["m_freeCntLabel"..i]:setString(str)
        end
    end
end

function MoneyTreeUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")

    -- 金币树
    local goldTreePanel = panel:getChildByName("Coin")
    self.m_goldBtn = goldTreePanel:getChildByName("BuyBtn")
    self.m_goldBtn.userObject = 1
    self.m_btnLabel1 = self.m_goldBtn:getChildByName("Text")
    self.m_freeCntLabel1 = self.m_btnLabel1:getChildByName("Value")
    self.m_getMoneyLabel1 = goldTreePanel:getChildByName("TitleBg"):getChildByName("CoinIcon"):getChildByName("Num")--可获取金钱
    local descPanel1 = goldTreePanel:getChildByName("DesBg")
    self.m_costLabel1 = descPanel1:getChildByName("Bg2"):getChildByName("Num")--花费元宝
    local countPanel1 = descPanel1:getChildByName("Bg1")
    self.m_countLabel1 = countPanel1:getChildByName("Num")--次数
    self.m_goldAddCntBtn = countPanel1:getChildByName("Button")
    self.m_goldAddCntBtn.userObject = 1
end

--弹提示框
function MoneyTreeUI:ShowDialog(msg)
     local function okFun()
     end
     Utils:ShowDialogOKCancel(msg,okFun)
end

function MoneyTreeUI:AddTouchEvt()
    --点击摇钱
    local function OnConsumeClick(sender)
        local type = sender.userObject
        local info = LActivityManager.m_moneyTreeData
        if info ~= nil and info[type] ~= nil then
            local leftNum = info[type].maxNum - info[type].useNum
            if leftNum <= 0 then
                 --弹提示框
                 self:ShowDialog(GUITips.RSI_MONEYTREE_MSG1)
                 return
            end
        end
       
        LuaNetSendMsg:SendMoneyTreeReq(2,type)
    end
    self.m_goldBtn:addClickEventListener(OnConsumeClick)
	self:MarkIntaractCObj(self.m_goldBtn)

    --增加次数
    local function OnAddCountClick(sender)
        local type = sender.userObject
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.VipMainUI",AppDef.UIType.FirstClassLayer, vipLimit)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_goldAddCntBtn:addClickEventListener(OnAddCountClick)
	self:MarkIntaractCObj(self.m_goldAddCntBtn)
end

function MoneyTreeUI:ShowCashEffect(type)
    local str = "CopyRes/jinbi.plist"
    if type == 2 then
        str = "CopyRes/yuanbao.plist"
    end
    self:DelParitical()
    self.m_partical = cc.ParticleSystemQuad:create(str)
    self.m_partical:setPosition(cc.p(AppDef.frameSize.width/2,AppDef.frameSize.height))
    self.m_partical:setAutoRemoveOnFinish(true)
    self.m_partical:setDuration(3)
    self.m_pUILayer:addChild(self.m_partical)
end

function MoneyTreeUI:DelParitical()
    if self.m_partical ~= nil then
        self.m_pUILayer:removeChild(self.m_partical,true)
    end
end

function MoneyTreeUI:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end

return MoneyTreeUI
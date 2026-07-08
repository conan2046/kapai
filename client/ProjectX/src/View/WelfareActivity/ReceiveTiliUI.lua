
local ReceiveTiliUI = LUIBase:New()
ReceiveTiliUI.__index = ReceiveTiliUI
--local this = LTcpSocket
function ReceiveTiliUI:New(parent)
	local o = LUIBase:New()
	setmetatable(o,ReceiveTiliUI)	
    o:Init(parent)
	return o
end

--注册事件
-- -----------------------------------
function ReceiveTiliUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleDataChangeEvent.GetTiliSuc,
        LUIRoleDataChangeEvent.GetFreeTili,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function ReceiveTiliUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.GetTiliSuc then
        self:updateUI(msg.value)

        local configData = JsonConfig.m_staminaConfig.getDefByID(msg.value)
        local arr = {configData.value[1],0,configData.value[3]}
        local name = Utils:getItemNameByConfigArr(arr)
        local str = string.format(GUITips.UI_MoneyTips,name,configData.value[2])
        Utils:ShowScrollTips(str);
    elseif msg.msgId == LUIRoleDataChangeEvent.GetFreeTili then
        self:updateTili(msg.value)
    end
end

function ReceiveTiliUI:updateTili(datas)
    --[[
    local tiliData = {}
    local receiveTimes = stream:ReadByte()
    for i=1, receiveTimes do
        local oneData = {}
        oneData.index = stream:ReadByte()
        oneData.state = stream:ReadByte()
        table.insert(tiliData, oneData)
    end
    ]]
    self._datas = datas;
    --0 不可领取 1 可领取 2 元宝领取 3已经领取
    for i=1, 3 do
        local Panel = self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Image_gaizi");
        if datas[i] and (datas[i] == 1 or datas[i] == 2) then
            self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Image_gaizi"):setVisible(false);
            if datas[i] == 1 then
                self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_1"):setVisible(true);
                self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_2"):setVisible(false);
            else
                self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_1"):setVisible(false);
                self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_2"):setVisible(true);

                local info = JsonConfig.m_staminaConfig.getDefByID(i);
                self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_2"):setString(string.format(GUITips.RSI_TILI_TIPS4,info.cost[2]))
            end
        else
            self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Image_gaizi"):setVisible(true);
            self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_1"):setVisible(false);
            self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(i + 2) .. "/Text_2"):setVisible(false);
            if datas[i] == 3 then
                self:updateUI(i)
            end
        end
        
    end
end


function ReceiveTiliUI:initData()
    self._datas = {}
    LuaNetSendMsg:QueryTiLiInfo(2);
end

function ReceiveTiliUI:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end
function ReceiveTiliUI:Init(parent)
    self:CreateUINode("csd/huodong/tililingquLayer.csb")
    parent:addChild(self.m_pUILayer)
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/tililingquLayer.csb")
    -- parent:addChild(self.m_pUILayer)
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
    self:initData();
end

function ReceiveTiliUI:initControlUI( ... )
    -- body
    self._panelList = {}
    local Panel_lingtili = self.m_pUILayer:getChildByName("Panel_lingtili")
    for i=1, 3 do
        local Panel = Panel_lingtili:getChildByName("Panel_"..(i + 2))
        table.insert(self._panelList, Panel)
        local button = Panel:getChildByName("Button_bg")
        button:setTag(i)
        button:addClickEventListener(handler(self, ReceiveTiliUI.GetTiliEvent))

        local configData = JsonConfig.m_staminaConfig.getDefByID(i)
        local beginTime = configData.time[1] / 100
        local endTime = configData.time[2] / 100

        local conPanel = Panel:getChildByName("Panel_1")
        local Text_tili = conPanel:getChildByName("Text_tili")
        Text_tili:setString(string.format(GUITips.UI_QiRi_Shop_tips5, configData.value[2]))

        local Text_time = conPanel:getChildByName("Text_time")
        Text_time:setString(string.format("%d:00-%d:00", beginTime, endTime))

    end
end

function ReceiveTiliUI:GetTiliEvent( sender )
    -- body
    local tag = sender:getTag()
    print("ReceiveTiliUI:GetTiliEvent ==>", tag)

    local configData = JsonConfig.m_staminaConfig.getDefByID(tag)
    local curTili = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Tili)

    if curTili + configData.value[2] > AppDef.Max_TiLi then
        Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips4)
        return
    end

    local function OKCallback()
        LuaNetSendMsg:QueryTiLiInfo(3, tag,1)
    end
    if self._datas[tag] == 2 then
        Utils:ShowBuyTiliDialog(20, OKCallback)
        return
    end
    
     LuaNetSendMsg:QueryTiLiInfo(3, tag,0)
    
end

function ReceiveTiliUI:updateUI( tiliType )
    -- body
    self._datas[tiliType] = 3;
    self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(tiliType + 2) .. "/Panel_1"):setVisible(false);
    self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(tiliType + 2) .. "/Text_1"):setVisible(false);
    self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(tiliType + 2) .. "/Text_2"):setVisible(false);
    self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(tiliType + 2) .. "/Image_gaizi"):setVisible(false);
    self.m_pUILayer:findChildByName("Panel_lingtili/Panel_"..(tiliType + 2) .. "/Button_bg"):setVisible(false);


    self:CheckTiliRedDot();
end

function ReceiveTiliUI:CheckTiliRedDot()
    local canget = false
    for i=1, 3 do
        if self._datas[i] == 1 or self._datas[i] == 2 then
            canget = true
            break
        end
        
    end
    if canget == false then
        Utils:SetRedDotState(RedDotDef.ID.Fuli_Tili, false)
    end
end

function ReceiveTiliUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return ReceiveTiliUI
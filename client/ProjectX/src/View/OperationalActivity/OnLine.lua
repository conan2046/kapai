--[[
za
]]
local TimerLabelUI = require("View.Common.TimerLabelUI")
local OnLine = LUIBase:New()
OnLine.__index = OnLine
function OnLine:New()
	local o = LUIBase:New()
	setmetatable(o,OnLine)	
    o:Init()
	return o
end
function OnLine:Init()
    self:CreateUINode("csd/huodong/OnlineLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/OnlineLayer.csb")
    -- ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitPanel()
    self:InitData()
    self:AddTouchEvt()
    self:CreateUI()
    self:InitItemList()
    self:UpdateTime()
    LGameMsg.m_baseMsgWithOne:Change(LOnLineEvent.AddTimeFun,{finish=handler(self,OnLine.TimeFinish),update=handler(self,OnLine.UpdateTimeText)     })
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
function OnLine:CreateUI()
    local function callback(frame)
    end
  --  Utils:PlayAction("csd/huodong/OnlineLayer.csb",0,30,30,callback)
    local action = cc.CSLoader:createTimeline("csd/huodong/OnlineLayer.csb")
    local timeline = ccs.Timeline:create()
    local frame = ccs.EventFrame:create()
    frame:setEvent("End")
    frame:setFrameIndex(30)
    timeline:addFrame(frame)
    action:addTimeline(timeline)
    self.m_pUILayer:runAction(action)
    action:pause()
    action:clearFrameEventCallFunc()
    action:gotoFrameAndPlay(0,30,false)
    action:setFrameEventCallFunc(callback)
end
function OnLine:onExit()
     self:UnRegistSelf(self,self.msgIds)
    LGameMsg.m_baseMsgWithOne:Change(LOnLineEvent.DeleteTimeFun,nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end
function OnLine:InitData()
    self.m_OnLineData=LRoleDataMgr.MyHeroInfo.OnLine
    self.m_Config=JsonConfig.m_OnLineConfig
    self.m_OnLineTimer=nil
end

--[[
注册UI消息
]]
function OnLine:RegistMsgs()
    self.msgIds = 
    {
       LOnLineEvent.UpdateTime,
    }
    self:RegistSelf(self,self.msgIds)
end



function OnLine:ProcessEvent(msg)
    if  msg.msgId== LOnLineEvent.UpdateTime then
      --  if  self.m_OnLineData.isFinish==true then
            self:UpdateTime()
            self:UpdateItemState()
       -- return
    -- else
    --     
    --     self:UpdateItemState()
    end
  
end

function OnLine:InitPanel()
    self.m_pItem=self:FindNode("Bg.Item")
    self.m_pItem:setPosition(cc.p(-2000,-2000))
    self.m_pItemList=self:FindNode("Bg.ListView_1")
    self.m_pItemList:setClippingEnabled(true)
    self.m_pTime=self:FindNode("Bg.Time")
    self.m_pGetBtn=self:FindNode("Bg.Btn")
    self.m_pExitBtn=self:FindNode("Bg.R.Button_1")

end
function OnLine:TimeFinish()
    self:SetGetState(false)
   
end
function OnLine:SetGetState(isV)
   self.m_pTime:setVisible(isV)
   self.m_pGetBtn:setVisible(not isV)
end
function OnLine:UpdateTime()
    self:SetGetState(true)

end
function OnLine:UpdateTimeText( _h, _m, _s)
    self.m_pTime:setString(string.format("%02d:%02d:%02d", _h, _m, _s))
end
function OnLine:UpdateItemState()

    local ind = self.m_OnLineData.ind
    local btn =self:FindNode("Bg.ListView_1."..ind-1)
    self:SetItemState(btn,true)

    -- body
end

function OnLine:AddTouchEvt()
    self.m_pExitBtn:addClickEventListener(function(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "OperationalActivity.OnLine")
         print("执行关闭LuaNetSendMsg:AwardOnlineAward()")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)
    self.m_pGetBtn:addClickEventListener(function (sender)
       
        LuaNetSendMsg:AwardOnlineAward()
    end)
end
function OnLine:InitItemList()
    for i=1,#self.m_Config.getList() do
        local cellChild =self.m_pItem:clone()
        cellChild:setTag(i)
        cellChild:setName(i)
        cellChild:setAnchorPoint(cc.p(0,0))
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        self.m_pItemList:addChild(cellChild)
        self:UpdateOne(cellChild)
    end
    self.m_pItemList:jumpToPercentHorizontal(self.m_OnLineData.ind/#self.m_Config.getList()*100)
end
function OnLine:UpdateOne(cell)
    local ind = cell:getTag()
    local data = self.m_Config.getDefByID(ind)
    local timeText = cell:getChildByName("Line"):getChildByName("Time")
    local item=cell:getChildByName("Mask"):getChildByName("Lingqu_0")
    item:setVisible(true)
    local barBg = cell:getChildByName("Line"):getChildByName("Bg")
    if ind== #self.m_Config.getList() then
       barBg:setVisible(false)
    end


    timeText:setString(data.time..GUITips.UI_Arena_Msg3)
    self:SetItemState(cell,self:CheckIsGetReward(ind))
    local num =0
    if data.reward[2]>0 then
       num=data.reward[2]
    else
        num=data.reward[3]

    end
    Utils:GetItemCellValue(item,0,data.reward[1],true,true,num,nil,true)
end

function OnLine:SetItemState(cell,isGet)
    local isGetNode = cell:getChildByName("Mask"):getChildByName("Lingqu")
 
    local barBg = cell:getChildByName("Line"):getChildByName("Bg")
    local bar = barBg:getChildByName("LoadingBar")
    local tipImage =cell:getChildByName("Line"):getChildByName("bg"):getChildByName("Image") 
    tipImage:setVisible(isGet)
    isGetNode:setVisible(isGet)
    if  isGet==true then
        bar:setPercent(100)
    else
        bar:setPercent(0)
    end
end
function OnLine:CheckIsGetReward(ind)
   return self.m_OnLineData:CheckIsGet(ind)
end
function OnLine:FindNode(str)
    if string.len(str)<1 then
        return
    end
    local nodeName = string.split(str,'.')
    local node = self.m_pUILayer:getChildByName("Panel")
    for i=1,#nodeName do
        node=node:getChildByName(nodeName[i])     
    end
    if node==nil then
        print("获取node失败")
    end
    return node
end
return OnLine
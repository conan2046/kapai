--[[
lua里面的游戏逻辑控制
]]

local WorldMapSubUI = LUIBase:New()
WorldMapSubUI.__index = WorldMapSubUI
--local this = LTcpSocket
function WorldMapSubUI:New()
	local o = LUIBase:New()
    setmetatable(o,WorldMapSubUI)   
    o:Init()
	return o
end


function WorldMapSubUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/WorldMapLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    self:SetCurAniPos()
end

function WorldMapSubUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pMapIds = nil
    self.m_pCurAni = nil
    self.m_pMapPanel = nil
end
--检查当前所在的服务器
function  WorldMapSubUI:CheckCurSever()
     if  LRoleDataMgr.m_bIsCrossServer==true then
        self:DisplayCrossSeverMap()
     else
        self:DisplaySeverMap()
     end

end

function WorldMapSubUI:DisplayCrossSeverMap()
     self:isDisplayLabel(true)
end
function WorldMapSubUI:DisplaySeverMap()
      self:isDisplayLabel(false)
end
function WorldMapSubUI:isDisplayLabel(isDisplay)
    for i=1,12 do
      local btn = self.m_pMapPanel:getChildByName("btn_" .. i)
     -- print("btn_"..i..self.m_pMapPanel.name)
      local label = btn:getChildByName("Label")
      if isDisplay==true then
         if i==12 then
            btn:setVisible(true)
         end
           label:setVisible(true)
      else
         if i==12 then
            btn:setVisible(false)
         end
          label:setVisible(false)
      end
    end


    
end


function WorldMapSubUI:InitData()
    self.m_pMapIds = 
    {
        2,7,4,5,3,11,6,9,8,1,10,12
    }
    self.m_pMapPanel = self.m_pUILayer:getChildByName("Panel_13")
    self.m_pCurAni = ImodAnim:createWithFileSync("UI/role")
    self.m_pCurAni:PlayActionRepeat(0)
    self.m_pCurAni:setAnchorPoint(cc.p(0.5,0))
    self.m_pMapPanel:addChild(self.m_pCurAni)
    self:CheckCurSever()
end

function WorldMapSubUI:SetCurAniPos()

    --默认放在主城
    local currMapSid = LRoleDataMgr.MyHeroInfo.sid
    local ind= 7
    for i = 1, #self.m_pMapIds do
        if self.m_pMapIds[i] == currMapSid then
            ind = i
            break
        end
    end
    if LRoleDataMgr.MyHeroInfo.sid==70 then
        ind=12
    end
    

    self.m_pCurAni:setPosition(self.m_pMapPanel:getChildByTag(self.m_pMapIds[ind]):getPosition())
end

function WorldMapSubUI:AddTouchEvt()
    local function MapBtnClicked(sender)
        local ind = sender:getTag()
        if ind==2 and LRoleDataMgr.MyHeroInfo.level<11 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG33)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif ind==3 and LRoleDataMgr.MyHeroInfo.level<31 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG35)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif ind==4 and LRoleDataMgr.MyHeroInfo.level<41 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG36)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif ind==5 and LRoleDataMgr.MyHeroInfo.level<51 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG37)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif ind==6 and LRoleDataMgr.MyHeroInfo.level<61 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG38)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
		elseif ind ==7 and LRoleDataMgr.MyHeroInfo.level<71 then
			LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG41)
			self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif ind==8 and LRoleDataMgr.MyHeroInfo.level<81 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG42)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)			
		elseif ind ==9 and LRoleDataMgr.MyHeroInfo.level<91 then
			LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG43)
			self:SendMsg(LGameMsg.m_scrollTipsMsg)						
		elseif ind ==10 then
			LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG32)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        --[[        测试期间屏蔽主城
            elseif ind==11 and LRoleDataMgr.MyHeroInfo.level<20 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_PET_MSG34)
                self:SendMsg(LGameMsg.m_scrollTipsMsg)
        ]]
		else
			self:ChangeScene(ind)
		end				
        --self:ChangeScene(ind)
    end
    for i = 1, #self.m_pMapIds do
        local tag = self.m_pMapIds[i]
        local btn = self.m_pMapPanel:getChildByName("btn_" .. tag)
        btn:addClickEventListener(MapBtnClicked)
		self:MarkIntaractCObj(btn) 
        --昆仑山和金鳖岛对调
        if tag == 7 then
            tag = 8
        elseif tag == 8 then
            tag = 7
        end

        btn:setTag(tag)
    end
end

function WorldMapSubUI:ChangeScene(dirSid)
    local currMapSid = LRoleDataMgr.MyHeroInfo.sid
    if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false
    and LRoleDataMgr.MyHeroInfo:IsTeamPause() == false then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_VAWL_TIP_MIN)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end
    if currMapSid == dirSid then
        return
    end
    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
    self:SendMsg(LGameMsg.m_cBaseMsg)

   if dirSid==12 then
    LuaNetSendMsg:QueryChangeCity(70)
   else
     LuaNetSendMsg:QueryChangeCity(dirSid)
   end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "WorldMap.WorldMapMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return WorldMapSubUI
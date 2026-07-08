
local FirstRechargeTips = LUIBase:New()
FirstRechargeTips.__index = FirstRechargeTips
--local this = LTcpSocket

local EVERYOPENTIME = 10
local OPENLEVEL = AppDef.FirstRecharge.show_Lv1
local OPENLEVEL2 = AppDef.FirstRecharge.show_Lv2
local OPENLEVEL3 = AppDef.FirstRecharge.show_Lv3
local OPENLEVEL4 = AppDef.FirstRecharge.show_Lv4
local CLOSELEVEL = AppDef.FirstRecharge.show_Lv5

--战斗中是否隐藏
-- FirstRechargeTips.IsHideInBattle = true
function FirstRechargeTips:New()
	local o = LUIBase:New()
	setmetatable(o,FirstRechargeTips)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function FirstRechargeTips:RegistMsgs()
self.msgIds = 
  {
    LUIActivityEvent.EnterFubBen,
    LUIActivityEvent.ExitFuBen,
    LUIActivityEvent.RefreshFirstRechargeUI,
    LUIMainEvent.CheckFirstRechargeBtn,
    LUILogicEvent.paymentSuccess,
    LUIActivityEvent.RefreshFirstRechargeUI,
    LUIRoleDataChangeEvent.LvUp,
    LUILogicEvent.PlotChatModel,
    LUILogicEvent.EnterBattle,
    LUILogicEvent.ExitBattle,
  }
self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FirstRechargeTips:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.EnterFubBen then
        self.m_pUILayer:setVisible(false)
        self._isEnterFuben = true
    end

    if msg.msgId == LUIActivityEvent.ExitFuBen then
        -- if self._coolTime > 1 then
        --   return
        -- end
        self._isEnterFuben = false
        if self._isShow == true and not LRoleDataMgr.isInBattle then
          self.m_pUILayer:setVisible(true)
        end
        
    end

    if msg.msgId == LUILogicEvent.EnterBattle then
      self.m_pUILayer:setVisible(false)
    end

    if msg.msgId == LUILogicEvent.ExitBattle then
        if self._isShow == true and not self._isEnterFuben then
          self.m_pUILayer:setVisible(true)
        end
    end

    if msg.msgId == LUIActivityEvent.RefreshFirstRechargeUI then
        self:InitUI()
    end

    if msg.msgId == LUIRoleDataChangeEvent.LvUp then
      local roleLv = LRoleDataMgr.MyHeroInfo:Getlevel()
      if roleLv < OPENLEVEL then
        return
      end

      if LRoleDataMgr.m_bIsInBattle then
        return
      end

      print("my Level = ", roleLv, OPENLEVEL, OPENLEVEL2, OPENLEVEL3)
      if roleLv == OPENLEVEL or  roleLv == OPENLEVEL2 or roleLv == OPENLEVEL3 or roleLv == OPENLEVEL4 then
        self._isShow = true
        self.m_pUILayer:setVisible(true)
        self:TimerCallBack()
      end


      if roleLv >= CLOSELEVEL then
        self:closeUI()
      end
    end

    if msg.msgId == LUIMainEvent.CheckFirstRechargeBtn then
      local data = LRechargeDataMgr:GetFirstRechargeData()
      if data.isPaid then
        self:closeUI()
      end
    end
    
    if msg.msgId == LUIMainEvent.paymentSuccess then
      self:closeUI()
    end

    if msg.msgId == LUIActivityEvent.RefreshFirstRechargeUI then
      local data = LRechargeDataMgr:GetFirstRechargeData()
      if data.isPaid then
        self:closeUI()
      end
    end

    if msg.msgId == LUILogicEvent.PlotChatModel then
      if msg.value == false and self._isShow == true then 
        self.m_pUILayer:setVisible(not msg.value)
      end
    end
end

function FirstRechargeTips:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/ShouChongLayer.csb")
    local roleLv = LRoleDataMgr.MyHeroInfo:Getlevel()
    self.m_pUILayer:setVisible(false)
--    self.m_pUILayer:setVisible(true)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:addTouchEvt()
    self:initData()
    self:InitUI()
end

function FirstRechargeTips:addTouchEvt( ... )
    -- body
   local panel = self.m_pUILayer:getChildByName("Panel_1_0")
   local closeBtn = panel:getChildByName("closeBtn")
   local function closeEvent( sender )
       -- body
      local roleLv = LRoleDataMgr.MyHeroInfo:Getlevel()
      if roleLv >= CLOSELEVEL then
        self:closeUI()
      else
        self._isShow = false
        if self.m_pUILayer ~= nil then
          self.m_pUILayer:setVisible(false)
        end
      end
--      self:closeUI()
   end
   closeBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeBtn)
   local buyBtn = panel:getChildByName("BuyBtn")
   local function toChargeUI( sender )
       -- body
       Utils:OpenRechargeMainUI()
       self.m_pUILayer:setVisible(false)
       self._isShow = false
   end
   buyBtn:addClickEventListener(toChargeUI)
	self:MarkIntaractCObj(buyBtn)
end

function FirstRechargeTips:TimerCallBack( ... )
  -- body
  local space = 1
  self._coolTime = EVERYOPENTIME
  local function tick(dt)
    
    -- if LRoleDataMgr.m_bIsInBattle then
    --   return
    -- end

    if self.m_pUILayer == nil then
      return
    end

    self._coolTime = self._coolTime - 1
--    print("self._coolTime", self._coolTime)
    if self._coolTime < 1 then
      if self.m_pUILayer:isVisible() then
        self.m_pUILayer:setVisible(false)
        self._coolTime = 0
        self._isShow = false
        Utils:unschedule(nil, self.m_EffectSchedulerID)
        return
      end
    end
  end
  self.m_EffectSchedulerID = Utils:schedule(nil, tick, space, false)
end

function FirstRechargeTips:initData( ... )
  -- body
  local panel = self.m_pUILayer:getChildByName("Panel_1_0")
  self._base = panel:getChildByName("Base")
  self._Node = self._base:getChildByName("Node_1")
  self._RolePower = panel:getChildByName("RolePowerBase"):getChildByName("PowerNum")
  self._coolTime = 0
  self._isShow = false
  self._isEnterFuben = false
end

function FirstRechargeTips:InitUI( ... )
  -- body
  local data = LRechargeDataMgr:GetFirstRechargeData()
  local info = data.petList
  if #info < 1 then
    return
  end

--  dump(info,"InitUI info list")
  local dPet =  LPetDataMgr:FindPetDataById(data.petList[1].id)
  if dPet == nil then return end
  if self.m_pPetModelNode == nil then
    self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    self._Node:addChild(self.m_pPetModelNode)
  end
  self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, dPet.pic)
  self.m_pPetModelNode:PlayStand(dPet.defaultFace)

--  dump(dPet.baseAttrs, "FirstRechargeTips pet")
--计算战斗力
  local attrTypeArr = {}
  local attrValueArr = {}

  for k,v in pairs(dPet.baseAttrs) do
    table.insert( attrTypeArr, k)
    table.insert( attrValueArr, v)
  end

  local zhandouli = LDataConstMgr:GetAttrPower(attrTypeArr, attrValueArr)
  self._RolePower:setString(Utils:getPowerStr(zhandouli))

end

function FirstRechargeTips:closeUI( ... )
  -- body
  LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Recharge.FirstRechargeTips")
  self:SendMsg(LGameMsg.m_initUIMsg)
end

function FirstRechargeTips:onExit()
    self.m_pUILayer = nil
    self._base = nil
    self._Node = nil
    self._RolePower = nil
    self._coolTime = nil
    self._isShow = nil
    self._isEnterFuben = nil
    Utils:unschedule(nil, self.m_EffectSchedulerID)
    self:Destory()
end

return FirstRechargeTips
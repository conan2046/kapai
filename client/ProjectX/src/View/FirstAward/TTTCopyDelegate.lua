local NomalCopyDelegate = require("View.FirstAward.NomalCopyDelegate")
local TTTCopyDelegate = NomalCopyDelegate:New()
TTTCopyDelegate.__index = TTTCopyDelegate

----------------------------------------------
function TTTCopyDelegate:New()
    local o = {}
    setmetatable(o, TTTCopyDelegate)
    o:Init()
    return o
end
----------------------------------------------
function TTTCopyDelegate:onExit()
    self:EndSchedule()
    self.m_pUILayer = nil
    self.m_pUI = nil
    self.m_data = nil
end
----------------------------------------------
function TTTCopyDelegate:updateTips()
    local pPanel = self.m_pUILayer
    local pTipsText = pPanel:getChildByName("TipsText")
    pTipsText:setVisible(true)
    local pText = pTipsText:getChildByName("AtlasLabel_1")
    pText:setString(self.m_data.attachData)
    local Iconbg = pPanel:getChildByName("IconBg")
    local list = Iconbg:getChildByName("List")

    for i=1,#self.m_data.itemVal1 do
      local itemId = self.m_data.itemId[i]
        local btn = list:getChildByName("IconBtn"..i)
        local name = btn:getChildByName("Name")
        name:setString(Utils:getItemNameByID(itemId))
        name:setVisible(true)
    end
end

function TTTCopyDelegate:setData(cfg)
    if cfg == nil then
        return
    end
    self.m_pUI = cfg[1]
    self.m_pUILayer = cfg[2]
    self.m_data = cfg[3]
    self:RegisterQuik()
    self:UpdateUI()
    Utils:PlayEffect("GuideBGM", "id", 2)
end

function TTTCopyDelegate:updateButton()
    local pBtnList = self.m_pUILayer:getChildByName("BtnList")
    pBtnList:setVisible(true)
    ---------------------------------------------------------------------------
    local PClose_Btn = pBtnList:getChildByName("Btn_1")
    local CloseText=PClose_Btn:getChildByName("Text")
    CloseText:setString(GUITips.RSI_TTT_TIPS1)
    PClose_Btn:addClickEventListener(handler(self, TTTCopyDelegate.GetBtnClick))
    ---------------------------------------------------------------------------
    local pContinue_Btn = pBtnList:getChildByName("Btn_2")
    pContinue_Btn:addClickEventListener(handler(self, TTTCopyDelegate.ContinueClick))

    self.m_pContinueText = pContinue_Btn:getChildByName("Text")
    
    self:EndSchedule()
    self.m_schedule = Utils:schedule(nil, handler(self, TTTCopyDelegate.CountDownCallback), 1)
    self.m_count = 5
    self:CountDownCallback(0)
end
function TTTCopyDelegate:ContinueClick(sender)
    self:EndSchedule()
    LuaNetSendMsg:QueryTowerInfo(3, nil)
    local _ = self.m_pUI and self.m_pUI:RemoveUI()
end
function TTTCopyDelegate:GetBtnClick(sender)
    self:EndSchedule()
    local _ = self.m_pUI and self.m_pUI:RemoveUI()
end

function TTTCopyDelegate:EndSchedule()
  if self.m_schedule then
      Utils:unschedule(nil, self.m_schedule)
      self.m_schedule = nil
  end
end

function TTTCopyDelegate:CountDownCallback(dt)
  local time = math.floor(self.m_count - dt)
  if time <= 0 then
      self:ContinueClick(nil)
      return
  end
  self.m_pContinueText:setString(string.format("%s(%d)", GUITips.RSI_TTT_TIPS2, time))
  self.m_count = time
end

return TTTCopyDelegate
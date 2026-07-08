local LunDaoTaskDelegate = {}
LunDaoTaskDelegate.__index = LunDaoTaskDelegate
-----------------------------------
function LunDaoTaskDelegate:New(uiLayer)
    local o = {}
    setmetatable(o, LunDaoTaskDelegate)
    o:Init(uiLayer)
    return o
end
-----------------------------------
function LunDaoTaskDelegate:Init(uiLayer)
    self.Script = "Activity.LunDaoTaskDelegate"
    --------------------------------------------------
    self.m_pUILayer = uiLayer
    self.m_taskData = nil
    --------------------------------------------------
    self.m_pTitle = nil
    self.m_pTarget = nil
    self.m_pReward1 = nil
    self.m_pReward2 = nil
    self.m_pFinish = nil
    --------------------------------------------------
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
end
-----------------------------------
function LunDaoTaskDelegate:onExit()
    self.m_taskData = nil
    self.m_datas = nil
    --------------------------------------------------
    self.m_pUILayer = nil
    self.m_pTitle = nil
    self.m_pTarget = nil
    self.m_pReward1 = nil
    self.m_pReward2 = nil
    self.m_pFinish = nil
end
-----------------------------------
function LunDaoTaskDelegate:InitUIControl()
    self.m_pTitle = self.m_pUILayer:getChildByName("Title")
    self.m_pTitle:setVisible(false)

    self.m_pTarget = self.m_pUILayer:getChildByName("Target"):getChildByName("Target")
    self.m_pTarget:setVisible(false)

    local pReward = self.m_pUILayer:getChildByName("Reward")
    self.m_pReward1 = pReward:getChildByName("Reward1")
    self.m_pReward1:setVisible(false)

    self.m_pReward2 = pReward:getChildByName("Reward2")
    self.m_pReward2:setVisible(false)

    self.m_pFinish = self.m_pUILayer:getChildByName("Finish")
    self.m_pFinish:setVisible(false)
end
-----------------------------------
function LunDaoTaskDelegate:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------
function LunDaoTaskDelegate:UpdateData(datas, killNum)
    if datas == nil or type(datas) ~= 'table' then
        return
    end
    self.m_datas = datas
    self:UpdateProgress(killNum)
    self:UpdateTitle()
    self:UpdateReward1()
    self:UpdateReward2()
    self:UpdateFinish()
end
----------------------------------
function LunDaoTaskDelegate:UpdateTitle()
    if self.m_taskData == nil then
        return
    end
    self.m_pTitle:setString(string.format(GUITips.Rei_Quest_Kuohao, self.m_taskData.taskName))
    self.m_pTitle:setVisible(true)
end
----------------------------------
function LunDaoTaskDelegate:UpdateTarget()
    if self.m_taskData == nil then
        return
    end
    self.m_pTarget:setString(self.m_taskData.targetDesc)
    self.m_pTarget:setVisible(true)
    self.m_pTarget:setString(string.format("%s(%d/%d)", self.m_taskData.targetDesc, self.m_killNum, self.m_taskData.killNum))
end
----------------------------------
function LunDaoTaskDelegate:UpdateReward1()
    if self.m_taskData == nil then
        return
    end
    self.m_pReward1:setString(self.m_taskData.award1 or "")
    self.m_pReward1:setVisible(true)
end
----------------------------------
function LunDaoTaskDelegate:UpdateReward2()
    if self.m_taskData == nil then
        return
    end
    self.m_pReward2:setString(self.m_taskData.award2 or "")
    self.m_pReward2:setVisible(true)
end
----------------------------------
function LunDaoTaskDelegate:UpdateFinish()
    if self.m_taskData == nil then
        return
    end
    self.m_pFinish:setVisible(self.m_taskData.isComplete)
end
----------------------------------
function LunDaoTaskDelegate:UpdateProgress(killNum)
    self.m_taskData = nil
    for i=1,#self.m_datas do
        local item = self.m_datas[i]
        if not item.isComplete or i== #self.m_datas then
            local curNum = killNum
            if killNum > item.killNum then
                curNum = item.killNum
            end
            self.m_taskData = item
            self.m_killNum = curNum
            break
        end
    end
    self:UpdateTarget()
end
----------------------------------
return LunDaoTaskDelegate
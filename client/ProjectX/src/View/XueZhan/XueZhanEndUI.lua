local XueZhanEndUI = LUIBase:New()
XueZhanEndUI.__index = XueZhanEndUI
XueZhanEndUI.IsHideInBattle = true
function XueZhanEndUI:New()
    local o = LUIBase:New()
    setmetatable(o,XueZhanEndUI) 
    o:Init()
    return o
end

function XueZhanEndUI:Init()
    self.Script = "XueZhan.XueZhanEndUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/Xuezhanend.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:ShowInfo()

    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,XueZhanEndUI.CloseUI))
end

function XueZhanEndUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Popup")

    --确定按钮
    local closeBtn  = panel:getChildByName("btn_lingqu")
    closeBtn:addClickEventListener(handler(self, XueZhanEndUI.CloseUI))

    local paihangBtn = panel:getChildByName("btn_paihangbang")
    paihangBtn:setVisible(false)
    paihangBtn:addClickEventListener(function (sender)
        -- 排行榜按钮
        Utils:OpenRankUI(AppDef.EModuleID.EMID_RANK_XueZhan)
        --self:CloseUI()
    end)
    
    self.m_levelLabel = panel:getChildByName("text_1"):getChildByName("Num")--本次章节
    self.m_starLabel = panel:getChildByName("text_2"):getChildByName("Num")--本次星数

    self.m_maxLvLabel = panel:getChildByName("text_3"):getChildByName("Num")--最高章节
    self.m_maxStarLabel = panel:getChildByName("text_4"):getChildByName("Num")--最高星数
end

function XueZhanEndUI:ShowInfo()
    local data = LActivityManager:GetXueZhanData()
    self.m_levelLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP7,data.m_chapterId)..string.format(GUITips.RSI_XUEZHAN_TIP11,data.m_levelId))
    self.m_starLabel:setString(""..data.m_totalStar)
    self.m_maxLvLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP7,data.m_maxChapterId)..string.format(GUITips.RSI_XUEZHAN_TIP11,data.m_maxLevelId))
    self.m_maxStarLabel:setString(""..data.m_maxLevelStar)
end

function XueZhanEndUI:CloseUI()
    --LuaNetSendMsg:QueryXueZhanInfo(6)--请求重置
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "XueZhan.XueZhanEndUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)

    local data = LActivityManager:GetXueZhanData()
    if data.m_cnt > 0 then
        LuaNetSendMsg:QueryXueZhanInfo(6)--请求重置
    else
        --关闭章节界面
        Utils:DeleteUI("XueZhan.XueZhanChapterUI")
        --打开主界面
        Utils:InitUI("XueZhan.XueZhanMainUI", AppDef.UIType.FirstClassLayer)
    end
end

function XueZhanEndUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.Script  = nil
end

return XueZhanEndUI

local WanFaInfoUI = LUIBase:New()
WanFaInfoUI.__index = WanFaInfoUI
--local this = LTcpSocket
function WanFaInfoUI:New(id)
	local o = LUIBase:New()
	setmetatable(o,WanFaInfoUI)	
    o:Init(id)
	return o
end

local ICONPATH = "res2/Icon/ui_main_icon/"

--注册事件
-- -----------------------------------
function WanFaInfoUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function WanFaInfoUI:ProcessEvent(msg)

end

function WanFaInfoUI:Init(id)

    self.m_pUILayer = cc.CSLoader:createNode("csd/TaskPopupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI(id)
    self:updateData()
end

function WanFaInfoUI:initControlUI( id )
    -- body
    self.m_id = id
    self.m_panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    --button
    self.m_btnPanel = self.m_panel:getChildByName("bg")
    self.m_enterButton = self.m_btnPanel:getChildByName("ListView"):getChildByName("Btn_1")
    local infoPanel = self.m_panel:getChildByName("Panel")
    --信息部分  
    local taskPanel = infoPanel:getChildByName("TaskIcon")
    self.m_nameLabel = taskPanel:getChildByName("Text")
    self.m_iconImg = taskPanel:getChildByName("Icon")
    self.m_cntNameLabel = infoPanel:getChildByName("cishu")
    self.m_cntLabel = self.m_cntNameLabel:getChildByName("Text")
    self._Activity = infoPanel:getChildByName("Activity")
    self.m_activeValLabel = self._Activity:getChildByName("Text")
    self._openTime = infoPanel:getChildByName("Time")
    self.m_timeLabel = self._openTime:getChildByName("Text")
    self.m_lvLabel = infoPanel:getChildByName("Level"):getChildByName("Text")
    self.m_teamLabel = infoPanel:getChildByName("Team"):getChildByName("Text")
    local descPanel = infoPanel:getChildByName("Desc")
    self.m_text = descPanel:getChildByName("Text")
    self.m_descListView = descPanel:getChildByName("ListView")
    self.m_drawListView = infoPanel:getChildByName("Reward"):getChildByName("ListView")
    self.m_iconBg = infoPanel:getChildByName("Reward"):getChildByName("IconBg")

    local function OnCloseCallBack(sender)
        self:CloseUI()
    end
    self.m_panel:addClickEventListener(OnCloseCallBack)
    self:MarkIntaractCObj(self.m_panel)

end

function WanFaInfoUI:updateData( ... )
    -- body
   local data = LDataConstMgr.m_pFunctionLevelMap[self.m_id]
   if data == nil then
      return
   end
   local iconPath = ICONPATH .. data.icon .. ".png"
   self.m_iconImg:loadTexture( iconPath, ccui.TextureResType.localType)

   self.m_nameLabel:setString(data.name)
   self.m_cntNameLabel:setVisible(false)
   self._Activity:setVisible(false)
   self.m_text:setString(data.des)

    for i=1, #data.show  do
       local data = data.show[i]
       local iconBg = self.m_iconBg:clone()
       Utils:GetItemCellValue(iconBg, 0, data[1], true, data[3] > 0, data[3], nil, true)
       self.m_drawListView:pushBackCustomItem(iconBg)
    end

    self._openTime:setVisible(false)
    local level = Utils:getFucnOpenLevel( self.m_id )
    self.m_lvLabel:setString(tostring(level) .. GUITips.UI_JiKaiqi)

   local isFuncionNotOpen = Utils:CheckModelNotOpened(self.m_id, true)
    self.m_btnPanel:setVisible(not isFuncionNotOpen)

    self.m_enterButton:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(self.m_id)
        self:CloseUI()
        Utils:DeleteUI("Main.WanFaEntranceUI")
    end)

end

function WanFaInfoUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("Main.WanFaInfoUI")
end

function WanFaInfoUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return WanFaInfoUI
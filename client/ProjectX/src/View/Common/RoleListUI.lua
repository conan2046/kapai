--[[
通用按钮列表弹出框
data:{
    roledatas = {},
    callback = ,
}
]]
local RoleListUI = LUIBase:New()
RoleListUI.__index = RoleListUI
local ScriptPath = "Common.RoleListUI"
function RoleListUI:New(data)
    data = data or {}
    local o = LUIBase:New()
    setmetatable(o,RoleListUI)    
    o:Init(data)
    return o
end

function RoleListUI:Init(data)
    self.m_pUILayer = cc.CSLoader:createNode("csd/RoleListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pData = data
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:InitRoleList()
end

--[[
注册UI消息
]]
function RoleListUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     LUIMsgBoxEvent.ShowMsgBox,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

function RoleListUI:ProcessEvent(msg)
    -- if msg:GetMsgId() == LUIMsgBoxEvent.ShowMsgBox then
    --     self:UpdateUserData(msg.value)
    -- end
end

function RoleListUI:onExit()
    self.m_pUILayer = nil
    self.m_pUserData = nil
    self.m_pListView = nil
    self:Destory()
end

function RoleListUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    self.m_pViewBg = panel:getChildByName("BtnList")
    self.m_pCell = panel:getChildByName("FriendBtn_1")
    local function CloseCallBack(sender)
        self:CloseSelf()
    end
    panel:getChildByName("Panel_1"):addClickEventListener(CloseCallBack)
	self:MarkIntaractCObj(panel:getChildByName("Panel_1"))
end

function RoleListUI:CloseSelf(isDelay)

    local function close()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    if isDelay then
        performWithDelay(self.m_pUILayer, close, 1/60)
    else
        close()
    end
end

function RoleListUI:InitRoleList()
    local cfg = {}
    cfg.tbPanel = self.m_pViewBg

    cfg.tableCellTouched = function(sender,cell)
        self:TableCellTouched(cell:getIdx() + 1)
    end

    cfg.cellSizeForTable = function(sender,idx)
        local size = self.m_pCell:getContentSize()
        return size.width, size.height
    end

    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return #self.m_pData.roledatas
    end

    self.m_pRoleTblView = Utils:createTableView(cfg)
    self.m_pRoleTblView:reloadData()
end

function RoleListUI:TableCellTouched(idx)
    local oneData = self.m_pData.roledatas[idx]
    self.m_pData.callback(oneData.name)
    self:CloseSelf(true)
end

function RoleListUI:TableCellAtIndex(sender,idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()
        
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end

    self:ShowRoleInfo(cellChild, idx + 1)
    return cell
end

function RoleListUI:ShowRoleInfo(cellChild, idx)
    local oneData = self.m_pData.roledatas[idx]

    cellChild:getChildByName("Offline"):setVisible(oneData.mapId > 0 or oneData.id == 0)
    local strHeadImage = AppDef:GetHeroPicFileName(oneData.prof, AppDef.HeadType.HERO_IMAGE_HEAD);
    if oneData.id == 0 then
        strHeadImage = "res2/Monster_Bust/302_tou.png"
    end

    cellChild:getChildByName("Image"):loadTexture(strHeadImage, ccui.TextureResType.localType)
    -- 友好度

    local GoodFeel = cellChild:getChildByName("GoodFeel")
    local optValTemp = LRoleDataMgr.Social:getQingMiDu(oneData.qingMiDu)
    local str = string.format("res/UI/ui_shejiao/friend_chenghao_%d.png", optValTemp) 
    GoodFeel:loadTexture(str, ccui.TextureResType.plistType)


    local Name = cellChild:getChildByName("Name")
    Name:setString(oneData.name)
    local LevelNum = cellChild:getChildByName("LevelNum")
    LevelNum:setString(GUITips.Item_Info_Lv .. oneData.level)
    local Career = cellChild:getChildByName("Career")
    Career:setString(oneData.profession)

    if oneData.id == 0 then
        GoodFeel:setVisible(false)
        LevelNum:setVisible(false)
        Career:setVisible(false)
    end
end

return RoleListUI
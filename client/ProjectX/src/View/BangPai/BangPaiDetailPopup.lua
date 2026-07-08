local BangPaiDetailPopup = LUIBase:New()
BangPaiDetailPopup.__index = BangPaiDetailPopup

-----------------------------------
--[[
data:{
    item:{pic, isLocal}--{图标路径,是否是本地资源}
    name:--名称
    count:--次数
    maxCount:--最大次数
    desc:--描述
    liveness:--活跃度
    actTime:--默认全天
    levelLimit:--等级限制
    taskType:任务形式
    actItems:{{id=,pic=,num=},...}--活动奖励id:道具ID pic:图片路径，id和pic只取其一
    btns:{{txt,callback}}--按钮文本以及回调
}
]]
-----------------------------------
function BangPaiDetailPopup:New(data)
    local o = {}
    setmetatable(o, BangPaiDetailPopup)
    o:Init(data)
    return o
end

-----------------------------------
function BangPaiDetailPopup:Init(data)
    self.Script = "BangPai.BangPaiDetailPopup"
    self.m_data = data

    if data == nil then
        self:RemoveUI()
        return 
    end
    self:InitViewSize()
    self:setCloseCallback()
    self:InitUIControl()
end

-----------------------------------
function BangPaiDetailPopup:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_data = nil
end
-----------------------------------
function BangPaiDetailPopup:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function BangPaiDetailPopup:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TaskPopupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-----------------------------------
function BangPaiDetailPopup:InitUIControl()
    if self.m_data == nil then
        return
    end
    local panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    self:setDefalutNodes(panel)
    ---------------------------------------------
    self:setButtonList(panel)
    ---------------------------------------------
    local pPanel = panel:getChildByName("Panel")
    if pPanel then
        pPanel:setVisible(true)
        local nodes = pPanel:getChildren()
        for i=1,#nodes do
            nodes[i]:setVisible(false)
        end
        self:setIcon(pPanel)
        self:setName(pPanel)
        self:setCount(pPanel)
        self:setDesc(pPanel)
        self:setLiveness(pPanel)
        self:setActTime(pPanel)
        self:setLevelLimit(pPanel)
        self:setTaskType(pPanel)
        self:setReward(pPanel)
    end
end

function BangPaiDetailPopup:setDefalutNodes(panel)
    if panel == nil then
        return
    end
    panel:addClickEventListener(function(sender)
        self:RemoveUI()
    end)
	self:MarkIntaractCObj(panel)
    --防止后期添加节点，默认所有节点不显示，只把需要的节点显示出来
    local nodes = panel:getChildren()
    for i=1,#nodes do
        nodes[i]:setVisible(false)
    end
    ---------------------------------------------
    local pImage_1_0 = panel:getChildByName("Image_1_0")
    pImage_1_0:setVisible(true)

    local pNPC = panel:getChildByName("NPC")
    pNPC:setVisible(true)

    local pbg_Name = panel:getChildByName("bg_Name")
    pbg_Name:setVisible(true)
end

function BangPaiDetailPopup:setButtonList(panel)
    if panel == nil then
        return
    end
    local btns = self.m_data.btns
    local pBg = panel:getChildByName("bg")
    pBg:setVisible(#btns > 0)

    local pListView = pBg:getChildByName("ListView")
    local pBtn_1 = pListView:getChildByName("Btn_1")
    pBtn_1:retain()
    pBtn_1:removeFromParent(false)

    local num = math.min(#btns, 4)
    pListView:setContentSize(cc.size(pListView:getContentSize().width, num*(pBtn_1:getContentSize().height+1)))
    pBg:setContentSize(cc.size(pBg:getContentSize().width, pListView:getContentSize().height+12+52.5))
    ccui.Helper:doLayout(pBg)

    for i=1,#btns do
        local pBtn = pBtn_1:clone()
        pBtn:setTitleText(btns[i][1])
        pBtn:setSwallowTouches(false)
        pBtn:setTag(i)
        pBtn:addClickEventListener(handler(self, BangPaiDetailPopup.buttonCallback))
		self:MarkIntaractCObj(pBtn)
        pListView:pushBackCustomItem(pBtn)
    end
    pBtn_1:release()
end

function BangPaiDetailPopup:setIcon(panel)
    if self.m_data.item==nil or self.m_data.item[1]==nil then
        return
    end
    local pTaskIcon = panel:getChildByName("TaskIcon")
    local pIcon = pTaskIcon:getChildByName("Icon")
    local pType = self.m_data.item[2] and UI_TEX_TYPE_LOCAL or UI_TEX_TYPE_PLIST
    pIcon:loadTexture(self.m_data.item[1], pType)
    pTaskIcon:setVisible(true)
end

function BangPaiDetailPopup:setName(panel)
    if self.m_data.name==nil then
        return
    end
    local pTaskIcon = panel:getChildByName("TaskIcon")
    local pText = pTaskIcon:getChildByName("Text")
    pText:setString(self.m_data.name)
    pTaskIcon:setVisible(true)
end

function BangPaiDetailPopup:setCount(panel)
    if self.m_data.count==nil or self.m_data.maxCount==nil then
        return
    end

    local pCishu = panel:getChildByName("cishu")
    local pText = pCishu:getChildByName("Text")
    pText:setString(string.format("%d/%d", self.m_data.count, self.m_data.maxCount))
    pCishu:setVisible(self.m_data.maxCount > 0)
end

function BangPaiDetailPopup:setDesc(panel)
    if self.m_data.desc==nil then
        return
    end
    local pDesc = panel:getChildByName("Desc")
    local pText = pDesc:getChildByName("Text")
    pText:setString(self.m_data.desc)
    pDesc:setVisible(true)
end

function BangPaiDetailPopup:setLiveness(panel)
    if self.m_data.liveness==nil then
        return
    end
    local pActivity = panel:getChildByName("Activity")
    local pText = pActivity:getChildByName("Text")
    pText:setString(self.m_data.liveness)
    pActivity:setVisible(true)
end

function BangPaiDetailPopup:setActTime(panel)
    local str = self.m_data.actTime or GUITips.RSI_FACTION_MSG200
    local pTime = panel:getChildByName("Time")
    local pText = pTime:getChildByName("Text")
    pText:setString(str)
    pTime:setVisible(true)
end

function BangPaiDetailPopup:setLevelLimit(panel)
    if self.m_data.levelLimit==nil or self.m_data.levelLimit==0 then
        return
    end
    local str = string.format(GUITips.RSI_FACTION_MSG201, self.m_data.levelLimit)
    local pLevel = panel:getChildByName("Level")
    local pText = pLevel:getChildByName("Text")
    pText:setString(str)
    pLevel:setVisible(true)
end

function BangPaiDetailPopup:setTaskType(panel)
    if self.m_data.taskType==nil then
        return
    end

    local str = self.m_data.taskType
    local pTeam = panel:getChildByName("Team")
    local pText = pTeam:getChildByName("Text")
    pText:setString(str)
    pText:setVisible(true)
end

function BangPaiDetailPopup:setReward(panel)
    if self.m_data.actItems == nil or #self.m_data.actItems == 0 then
        return
    end
    local pReward = panel:getChildByName("Reward")
    local pListView = pReward:getChildByName("ListView")
    local pIconBg = pReward:getChildByName("IconBg")
    pIconBg:setTouchEnabled(false)

    for i=1,#self.m_data.actItems do
        local cfg = self.m_data.actItems[i]
        local item = pIconBg:clone()
        if cfg.id and cfg.id > 0 then
            local _ = Utils:GetItemCellValue(item, 0, cfg.id, true, cfg.num > 0, cfg.num, nil, true)    
        else
            local pIcon = cc.CSLoader:createNode("csd/ItemIconLayer.csb")
            local pItemIcon = pIcon:getChildByName("ItemIcon")
            pItemIcon:setVisible(true)
            pItemIcon:loadTexture(cfg.pic, UI_TEX_TYPE_LOCAL)
            local pItemNum = pIcon:getChildByName("ItemNum")
            pItemNum:setVisible(Utils:ToBool(cfg.num))
            if pItemNum:isVisible() then
                pItemNum:setString(cfg.num)
            end
            pIcon:setAnchorPoint(cc.p(0.5, 0.5))
            pIcon:setPosition(cc.p(item:getContentSize().width/2, item:getContentSize().height/2))
            item:addChild(pIcon)

            local pItemQuality = pIcon:getChildByName("ItemQuality")
            if pItemQuality then
                pItemQuality:setVisible(false)
            end
            local pItemState = pIcon:getChildByName("ItemState")
            if pItemState then
                pItemState:setVisible(false)
            end
        end
        pListView:pushBackCustomItem(item)
    end
    pReward:setVisible(true)
end

function BangPaiDetailPopup:buttonCallback(sender)
    local tag = sender:getTag()
    local data = self.m_data.btns[tag]
    if data[2] and type(data[2]) == "function" then
        data[2]()
    end
    self:RemoveUI()
end

return BangPaiDetailPopup
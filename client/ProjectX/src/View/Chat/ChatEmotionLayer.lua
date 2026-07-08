--[[
lua chat 表情
]]

local ChatEmotionLayer = LUIBase:New()
ChatEmotionLayer.__index = ChatEmotionLayer

function ChatEmotionLayer:New()
	local o = LUIBase:New()
	setmetatable(o,ChatEmotionLayer)	
    o:Init()
	return o
end

--[[
注册消息
]]
function ChatEmotionLayer:RegistMsgs()
    self.msgIds = 
    {
        
    }
    self:RegistSelf(self,self.msgIds)
end

function ChatEmotionLayer:ProcessEvent(msg)
   
end

function ChatEmotionLayer:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/ExpressionLayer.csb")
    ccui.Helper:doLayout(self.m_pUILayer)

    self:InitData()
    self:AddTouchEvt();
end

function ChatEmotionLayer:InitData()
    
    local swallowTouchbg = self.m_pUILayer:getChildByName("swallowTouchbg")
    swallowTouchbg:setSwallowTouches(true)

    local panel =  self.m_pUILayer:getChildByName("ExpressionUI")
    self.m_pTvPanel = panel:getChildByName("List")
    self.m_pCell = self.m_pTvPanel:getChildByName("Row")
    self.SelcetFace = nil;
    self.m_pCell:setVisible(false)
    local CC_WINSIZE = cc.Director:getInstance():getWinSize()
    panel:setPosition(ccp(CC_WINSIZE.width / 2, CC_WINSIZE.height / 2));
    self:InitFaceTabView();
    self.m_pFaceTableView:reloadData();

end 

function ChatEmotionLayer:AddTouchEvt()
    
    local function ccTouchBegin(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.ended then
            self:ccTouchBegin(pTouch, pEvent);
        end
    end
    
    local swallowTouchbg = self.m_pUILayer:getChildByName("swallowTouchbg")
    swallowTouchbg:addTouchEventListener(ccTouchBegin)
	self:MarkIntaractCObj(swallowTouchbg)
end

function ChatEmotionLayer:onExit()
    self.m_pUILayer = nil
    self:Destory();
end

function ChatEmotionLayer:InitFaceTabView(panel)
    
    local tableView = cc.TableView:create(self.m_pTvPanel:getContentSize())
    --print("width = ".. self.m_pTvPanel:getContentSize().width .. "height = " .. self.m_pTvPanel:getContentSize().height);
    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self.m_pTvPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pTvPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched".. cell:getIdx())
        self:FaceTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        --print("cellSizeForTable idx = ".. idx )
        return self:FaceTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView() 
        return 8
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pFaceTableView = tableView

    --print("ChatEmotionLayer:InitFaceTabView")
end


--点击选中处理
function ChatEmotionLayer:FaceTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    --print("tableview touched " ..ind.." ") 
end 


function ChatEmotionLayer:FaceTableCellAtIndex(sender, idx)

    local function FaceGridTouched(sender)--表情点击
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
        
        LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.addEmotion, ind)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

--        self.SelcetFace:setBright(true);
--        sender:setBright(false)
    
        if self.SelcetFace ~= nil then
            self.SelcetFace:getChildByName("Choose"):setVisible(false)
        end
         
         sender:getChildByName("Choose"):setVisible(true)

        self.SelcetFace = sender;
    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()

        cellChild = self.m_pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i=1,5 do
            local faceGrid = cellChild:getChildByName("Button_0"..i)
            --实现选中状态
            faceGrid:setBright(true)
            faceGrid:setSwallowTouches(false)
            local index = idx*5+i
            faceGrid:setTag(index)
            faceGrid:addClickEventListener(FaceGridTouched)
			self:MarkIntaractCObj(faceGrid)
            faceGrid:getChildByName("Choose"):setVisible(false)
            if self.SelcetFace ~= nil then
                if index == self.SelcetFace:getTag() then
                    self.SelcetFace:getChildByName("Choose"):setVisible(false)
                end
            end

            local face = faceGrid:getChildByName("Image_0" .. i)
            face:loadTexture("res/UI/cm_biaoqing/bq_".. index ..".png", ccui.TextureResType.plistType);
        end      
    else
        cellChild = cell:getChildByTag(123)

        for i=1,5 do
            local faceGrid = cellChild:getChildByName("Button_0"..i)

            local pre = faceGrid:getTag()
            local index = idx*5+i
            faceGrid:setTag(index)
            faceGrid:addClickEventListener(FaceGridTouched)
			self:MarkIntaractCObj(faceGrid)
            faceGrid:getChildByName("Choose"):setVisible(false)
            if self.SelcetFace ~= nil then
                if index == self.SelcetFace:getTag() then
                    self.SelcetFace:getChildByName("Choose"):setVisible(false)
                end
            end

            local face = faceGrid:getChildByName("Image_0" .. i)
            face:loadTexture("res/UI/cm_biaoqing/bq_".. index ..".png", ccui.TextureResType.plistType);

        end

    end
    --print("cell idx"..idx)
    self:ShowFaceCellInfo(cellChild, idx)
    return cell
end


function ChatEmotionLayer:ShowFaceCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    if cellChild ~= nil then
    end
end

function ChatEmotionLayer:ccTouchBegin(pTouch, pEvent) 
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Chat.ChatEmotionLayer")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return ChatEmotionLayer
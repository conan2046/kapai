local m_pLayer = nil
local NormalFuBenUI = LUIBase:New()
NormalFuBenUI.__index = NormalFuBenUI
--local this = LTcpSocket
function NormalFuBenUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,NormalFuBenUI)	
    o:Init(data)
	return o
end

local CONSTPAGENUM = 5
local ZXCJOPENCHP = 1003

--注册事件
-- -----------------------------------
function NormalFuBenUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFuBenMapEvent.refrashBigMapUI,
        LUILogicEvent.EnterBattle,
        LUILogicEvent.ExitBattle,
        LUIFuBenMapEvent.refrashUIAfterFight,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
        LUILogicEvent.PlotChatOver,
        LUIFuBenMapEvent.getBoxAwardSuc,
        LUIRedDotEvent.UpdateRedDotState,
        LUIFuBenMapEvent.tongGuanEvent,
    }
    self:RegistSelf(self, self.msgIds)
end
-- -----------------------------------
function NormalFuBenUI:ProcessEvent(msg)
    local msgId = msg:GetMsgId()
    print("NormalFuBenUI:ProcessEvent ==>", LUIRedDotEvent.UpdateRedDotState, msgId)
    if msgId == LUIFuBenMapEvent.refrashBigMapUI then
        self:GotChapterList(msg.value)
	    self:RegisterGuide()
        if self._datas.curStageID == 10011 then
            Utils:CheckGuide(GuideDef.StepId.Guide_FuBen4,true)
        end
        if self.openChapterData~=nil and self.openChapterData.openCurChapter==true  then
            self:OpenCurChapter()
        end
       
    elseif msgId ==LUILogicEvent.EnterBattle then
        self.m_pUILayer:setVisible(false)
    elseif  msgId ==  LUILogicEvent.ExitBattle then
        self.m_pUILayer:setVisible(true)
    elseif msgId == LUIFuBenMapEvent.refrashUIAfterFight then
        self:updateData(msg.value)
    elseif msgId == LUIRoleDataChangeEvent.MoneyChanged then
        local myMoney = Utils:getGoldStr()
        self._coin:setString(myMoney)
    elseif msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._Gold:setString(myGold)
    elseif msgId == LUIRoleDataChangeEvent.TiliChanged then
        local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        self._TiLi:setString(Utils:getTiliStr(myTili))
    elseif msgId == LUILogicEvent.PlotChatOver then
        if not msg.value then
            self:openStageScene()
        end
    elseif msgId == LUIFuBenMapEvent.getBoxAwardSuc then
        self:updateChapterOwnBoxData(msg.value)
    elseif msgId == LUIRedDotEvent.UpdateRedDotState then
        --更新红点
        self:UpdateRedDot()
    elseif LUIFuBenMapEvent.tongGuanEvent then
        if self._needOpenZXCJ then
            self._Button_zhuxianchengjiu:setVisible(true)
            self:OpenAchievent()
            self._needOpenZXCJ = false
        end
    end
end

function NormalFuBenUI:GotChapterList(datas)
    self.m_pUILayer:setVisible(true)
    self:refrashData(datas)
    self:ShowCurPage();
    -- self:InitPageNum()
    self:refreshDropBox()
    -- self:RegisterGuide()
end

function NormalFuBenUI:ShowCurPage()
    local curPage = self._mapIndex
    self._curPageNum = curPage
    print("ShowCurPage",self._curPageNum)
    local leftPage = curPage - 1;
    local rightPage = curPage + 1;
    if leftPage <= 0 then
        leftPage = curPage;
        rightPage = curPage + 2;
    elseif rightPage >= self._pageNum then
        rightPage = self._pageNum
        leftPage = rightPage - 2
    end
 print("leftPage",leftPage)
    for i = 1, 3 do
        if self._pageCellCtrlArr[i] == nil then
            local page
            if i == 1 then
                page = self._pageCell;
            else
                page = self._pageCell:clone();
                -- self.m_pUILayer:addChild(page);
            end
            -- print("leftPage",leftPage)
            page:setVisible(true)
            self._pageCellCtrlArr[i] = require("View.FuBenMap.BigMapPage"):New(self, leftPage + i - 1, page, self._pageView)
        else
            self._pageCellCtrlArr[i]:UpdatePage(i + leftPage)
        end
        
    end
    self._pageView:setCurrentPageIndex(curPage - 1)
    self._leftBtn:setVisible(curPage - 1 > 0)
    self._rightBtn:setVisible(curPage - 1 < self._pageNum - 1)

    print("NormalFuBenUI:updateData ==>", self._datas.curChapterId, ZXCJOPENCHP)
    self._Button_zhuxianchengjiu:setVisible(self._datas.curChapterId >= ZXCJOPENCHP)
end

function NormalFuBenUI:InitPageNum()
    local chpaterNum = PetkaPaiManager:getMapNumByType(1)
    self._pageNum = math.ceil(chpaterNum / 5)
    for i= 2, self._pageNum do
        local cell = self.m_pCell:clone()
        self._pageView:addPage(cell)
    end

    -- for i = 1,3 do
    --     local page
    --     if i == 1 then
    --         page = self._pageCell;
    --     else
    --         page = self._pageCell:clone();
    --         -- self.m_pUILayer:addChild(page);
    --     end
    --     page:setVisible(true)
    --     local pageCtrl = require("View.FuBenMap.BigMapPage"):New(self, i, page, self._pageView)
    --     table.insert(self._pageCellCtrlArr,pageCtrl);
    -- end

    -- while(self._curShow<=self._mapIndex) do
    --     self:addPage()
    --     self:refreshUI()
    --     self._curShow = self._curShow + 5
    -- end
    -- self._pageView:scrollToPage(self._mapIndex-1,0)
    -- self._leftBtn:setVisible(self:getPageNumByChapter(self._curChapterId)-1 > 0)
    -- self._rightBtn:setVisible(self:getPageNumByChapter(self._curChapterId)-1 < self._pageNum - 1)
    -- self._curPageNum=self:getPageNumByChapter(self._curChapterId)
end

-- function NormalFuBenUI:UpdateUserData()
--     if m_pLayer~=nil then
--         self:InitPageNum()
--         print("NormalFuBenUI:Init()")
--         m_pLayer:setVisible(true)
--         return
--     end
-- end
function NormalFuBenUI:Init(data)
    
    self.m_pUILayer = cc.CSLoader:createNode("csd/fuben/WorldMapNewLayer.csb")
   -- m_pLayer= self.m_pUILayer
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    self:RegistMsgs()

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self.openChapterData=data 
    self._UILayer = cc.CSLoader:createNode("csd/fuben/DadituuiLayer.csb")
    self._UILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self._UILayer)
    self._UI = self._UILayer
    self._UILayer:setPosition(cc.p(0, 0))
    self.m_pUILayer:addChild(self._UILayer)
    self._isShow = false
    self:InitControlUI()
    self:InitPageNum()
    self.m_pUILayer:setVisible(false)
    self.m_guideBtn1 = nil
    self.m_guideBtn2 = nil
    LuaNetSendMsg:QueryDituInfo(1, 1) --查询
    
end
function NormalFuBenUI:FrameEventCallFunc( sender )
end

-- function NormalFuBenUI:LoadNewPages()
--     local function load()
--         self:addPage()
--         self:refreshUI()
--         self._curShow = self._curShow + 5

--         self._pageView:setCurrentPageIndex(self._curPageNum - 1)
--     end
--     load();
--     --Utils:DelayToCallFunc(self.m_pUILayer, 0.1, load)
-- end

--[[
往左滑
]]
function NormalFuBenUI:PageTurnLeft(changePage)
    --[[
    原来中间页移到左边,右边页移到中间
    把左边页移到右边页,然后只刷新右边页就行
    ]]
    if changePage == self._pageNum or changePage == 2 then
        --滑倒最右边了,这个时候不变
        --从最左边滑1格的时候不变
        return
    end
    local leftToRightPage = self._pageCellCtrlArr[1];
    table.remove(self._pageCellCtrlArr,1)
    table.insert(self._pageCellCtrlArr,leftToRightPage)
    leftToRightPage:UpdatePage(changePage + 1)
end

--[[
往右滑
]]
function NormalFuBenUI:PageTurnRight(changePage)
    --[[
    原来中间页移到右边,左边页移到中间
    把右边页移到左边页,然后只刷新左边页就行
    ]]
    if changePage == 1 or changePage == self._pageNum - 1 then
        --滑倒最左边,这时候不用改变
        --从最右边滑1格的时候不变
        return
    end
    local rightToLeftPage = self._pageCellCtrlArr[3];
    table.remove(self._pageCellCtrlArr,3)
    table.insert(self._pageCellCtrlArr,1,rightToLeftPage)
    rightToLeftPage:UpdatePage(changePage - 1)
end

function NormalFuBenUI:TurnPage(curPage, oldPage)
    local turnNum = math.abs(curPage - oldPage);
    --
    if oldPage > curPage then
        for i = 1, turnNum do
            self:PageTurnRight(oldPage - i)
        end
        
    elseif oldPage < curPage then
        for i = 1, turnNum do
            self:PageTurnLeft(oldPage + i)
        end
    end
end

function NormalFuBenUI:InitControlUI( ... )
    self._pageCell = self.m_pUILayer:getChildByName("chapterPage")
    self._pageCell:setVisible(false);
    self._pageCellCtrlArr = {};
    self._pageView = self.m_pUILayer:getChildByName("PageView")
    local function viewTurning(sender, eventType)
        --[[
        只会在拖动的时候才会触发
        ]]
        local curIndex =  self._pageView:getCurrentPageIndex()
        -- print("viewTurning",curIndex,self._curPageNum)
        if curIndex + 1 ~= self._curPageNum then
            self:ChangePage(curIndex,false)
        end
        
        -- local curIndex =  self._pageView:getCurrentPageIndex()
        -- self._leftBtn:setVisible(curIndex > 0)
        -- self._rightBtn:setVisible(curIndex < self._pageNum - 1)
        -- local oldPage = self._curPageNum
        -- self._curPageNum = curIndex + 1
        
        -- print("self._curPageNum ====>", self._curPageNum)
        -- local index = curIndex * 5 + 1


        -- if #self._allPageData >= index then
        --     self._curChapterId = self._allPageData[index].chapterId

        --     -- self._fubenName:setString(self._allPageData[index].chapterName)
        -- end

        -- local afterIndex = curIndex * 5 + 5
        -- self:updateRLTipsUI(curIndex, afterIndex)
        -- self:TurnPage(self._curPageNum, oldPage);
        -- local turnNum = math.abs(self._curPageNum - oldPage);
        -- --
        -- if oldPage > self._curPageNum then
        --     for i = 1, turnNum do
        --         self:PageTurnRight(oldPage - i)
        --     end
            
        -- elseif oldPage < self._curPageNum then
        --     for i = 1, turnNum do
        --         self:PageTurnLeft(oldPage + i)
        --     end
        -- end
        -- dump(self._pageCellCtrlArr,"self._pageCellCtrlArr")

        --print("self._curPageNum ===>", self._curPageNum, self._curShow - 1)
        --分段式加载
        -- if self._curPageNum == self._curShow - 1 then
        --     self:LoadNewPages();
        --     -- self:addPage()
        --     -- --self:refreshUI()
        --     -- self._curShow = self._curShow + 5
        --     -- -- self._pageView:scrollToPage(self._curPageNum - 1, 0.1)
        -- end

    end
    --[[
    滚动结束和滚动中都要
    ]]
    -- self._pageView:addEventListener(viewTurning)
    self._pageView:addScrollingEventListener(viewTurning)
    self.m_pCell = self._pageView:getChildByName("Panel_1")
      

    self._leftBtn = self.m_pUILayer:getChildByName("Button_1")
    self._leftBtn:setVisible(false)
    self._leftBtn:addClickEventListener(handler(self, NormalFuBenUI.leftEvent))
    self._rightBtn = self.m_pUILayer:getChildByName("Button_2")
    self._rightBtn:addClickEventListener(handler(self, NormalFuBenUI.rightEvetn))

    self._Image_qipao_L = self.m_pUILayer:getChildByName("Image_qipao_L")
    self._Image_qipao_R = self.m_pUILayer:getChildByName("Image_qipao_R")
    ------------------------------------------------------------------------
    local GoldCheck = self._UILayer:getChildByName("GoldCheck")
    self._coin = GoldCheck:getChildByName("GoldIcon1"):getChildByName("GoldNumBg"):getChildByName("Num")
    local myMoney = Utils:getGoldStr()
    self._coin:setString(myMoney)
    local coinAddBtn = GoldCheck:findChildByName("GoldIcon1/AddBtn")
    coinAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    self._Gold =  GoldCheck:getChildByName("GoldIcon3"):getChildByName("GoldNumBg"):getChildByName("Num")
    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self._Gold:setString(myGold)
    local goldAddBtn = GoldCheck:findChildByName("GoldIcon3/AddBtn")
    goldAddBtn:setEnabled(false)
    self._TiLi = GoldCheck:getChildByName("GoldIcon4"):getChildByName("GoldNumBg"):getChildByName("Num")
    local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    self._TiLi:setString(Utils:getTiliStr(tili))
    local tiliAddBtn = GoldCheck:findChildByName("GoldIcon4/AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    --------------------------------------------------------------------------------------------
    local Panel_zuoshang = self._UI:getChildByName("Panel_zuoshang")
    local Image_bg2 = Panel_zuoshang:getChildByName("Image_bg2")
    self._fubenName = Image_bg2:getChildByName("guanqia")
    
    local Button_xiala = Panel_zuoshang:getChildByName("Button_xiala")
    Button_xiala:addClickEventListener(function ( sender )
        -- body
        self:showFastList(not self._isShow)
    end)
    self._dropBox= self._UI:getChildByName("Popup")
    self._dropBox:setTouchEnabled(false)
    ------------------------------------------------------------------------
    local title = self._UILayer:getChildByName("Title")
    title:setTouchEnabled(false)
    title:getChildByName("bg"):setTouchEnabled(false)
    local guanbi = title:getChildByName("CloseBtn")
    guanbi:addClickEventListener(handler(self, NormalFuBenUI.closeDialog))
    self.m_guideBtn = guanbi

    local panel1 = self._UI:getChildByName("Panel_1") 
    panel1:setVisible(false)
    ------------------------------------------------------------------------------------
    local Panel_youxia = self._UI:getChildByName("Panel_youxia")
    local doushenzhilu = Panel_youxia:getChildByName("Button_fengshenshilian")
    self._fssl = doushenzhilu:getChildByName("Prompt")
    doushenzhilu:addClickEventListener(function ( sender )
		local funccfg = JsonConfig.m_functionConfig.getDefByID(1020)
		if LRoleDataMgr.MyHeroInfo.level < funccfg.open_condition[1][2] then
			Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2, funccfg.open_condition[1][2]))
			return
		end
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FENGSHEN)
    end)

    local Button_zhuxianchengjiu = Panel_youxia:getChildByName("Button_zhuxianchengjiu")
    self._Button_zhuxianchengjiu = Button_zhuxianchengjiu
    self._achiPrompt = Button_zhuxianchengjiu:getChildByName("Prompt")
    Button_zhuxianchengjiu:addClickEventListener(function ( sender )
        -- body
        self:OpenAchievent()
    end)
    self:UpdateRedDot()
end


function NormalFuBenUI:OpenAchievent( ... )
    -- body
    local ownTatalStar = 0
    if self._datas then
        ownTatalStar = self._datas.ownTotalStarNum
    end
    Utils:InitUI("FuBenMap.FuBenAchievementsUI", AppDef.UIType.SpecialLayer, ownTatalStar)
end

function NormalFuBenUI:addPage( ... )
    -- body
    if self._curShow > self._pageNum then
        return
    end
    local addNum = 4
    if self._curShow == 1 then
        addNum = 3
    end
    --print("addPage",self._curShow,self._curShow + addNum)
    for i=self._curShow, self._curShow + addNum do
        local cell = self.m_pCell:clone()
        for i = 1, 15 do
            cell:findChildByName("Bg1/btn_" .. i):setVisible(false);
        end
        -- cell:setTag(i)
        -- cell:setPosition(cc.p(0, 0))
        self._pageView:addPage(cell)
    end
end
-- function NormalFuBenUI:PlayBoxAndHead(node)
--     local move = cc.MoveTo:create(0.4,cc.p(node:getPositionX(),node:getPositionY()+5))
--     local move1 = cc.MoveTo:create(0.4,cc.p(node:getPositionX(),node:getPositionY()-5))
--     local moveAction = {}
--     table.insert(moveAction, move)
--     table.insert(moveAction, cc.DelayTime:create(0.2))
--     table.insert(moveAction, move1)
--     local actRepeat=cc.RepeatForever:create(cc.Sequence:create(moveAction))
--     node:stopAllActions()
--     node:runAction(actRepeat)
-- end

function NormalFuBenUI:showFastList( b)
    -- body
    self._isShow = b
    if(not b) then
        -- self.m_pUILayer:runAction(self._action)
        --动画
        Utils:PlayAction("csd/fuben/DadituuiLayer.csb", 60, 80, 80, NormalFuBenUI.FrameEventCallFunc)        
    else

        Utils:PlayAction("csd/fuben/DadituuiLayer.csb", 0, 20, 80, NormalFuBenUI.FrameEventCallFunc)
    end 
end

function NormalFuBenUI:refreshDropBox()
    local lisView = self._dropBox:getChildByName("ListView")
    self.dropBoxCell = lisView:getChildByName("Button_1")
    self.dropBoxCell:setVisible(false)
    local tableView = cc.TableView:create(lisView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0,0))  
    tableView:setPosition(cc.p(0,0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    lisView:addChild(tableView)




    local function tableCellTouched(sender,cell)
        self:moveToPage(cell)
    end
    local function cellSizeForTable(sender,idx)
       local size = self.dropBoxCell:getContentSize()
       return size.width, size.height+5
    end
    local function tableCellAtIndex(sender, idx)
       return self:cellAtIndex(sender, idx)
    end
    local function numberOfCellsInTableView()
        return  #self._datas.passList   --self:getPageNumByChapter(self._curChapterId)
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量  
    tableView:reloadData()
    self.m_pTableView = tableView
end

function NormalFuBenUI:moveToPage(cell)
    local ind = cell:getIdx()
    local page = math.ceil((ind+1) / 5-1)
    self._pageView:scrollToPage(page,0.5)
   -- self._fubenName:setString((ind+1).."、"..self._allPageData[ind+1].chapterName)
end


--[[
刷新下拉内容
]]
function NormalFuBenUI:cellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.dropBoxCell:clone()
        cellChild:setVisible(true)
        cellChild:setTag(123)
        cellChild:setAnchorPoint(cc.p(0,0))
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end
   -- dump(idx+1,"刷新下拉内容")
    local data = self._datas.passList[idx+1]
    self:refreshDropCell(cellChild,data,idx+1)
    return cell  
end

function NormalFuBenUI:refreshDropCell(cell,data,ind)
    local starNum = cell:findChildByName("xing/xing_num")
    local zhangjie = cell:findChildByName("zhangjie")
    local maxStarNum = self:getChapterMaxStarNum(data.chapterId)
    local myStatNum = data.ownStarNum
    starNum:setString(myStatNum.."/"..maxStarNum)
    zhangjie:setString(ind.."章")--(ind-1)*5+1.."-"..ind*5    
end





function NormalFuBenUI:getIsStageUnLock( stageId )
    -- body
    for i=1, #self._datas.mapNodeList do
        if self._datas.mapNodeList[i].stageId == stageId then
            return true
        end
    end
    return false
end
--[[
获取当前小关卡的星星数量
]]
function NormalFuBenUI:getStageStartNum(stageId)
    if PetkaPaiManager.m_StageInfo then
       for i=1,#PetkaPaiManager.m_StageInfo.stageNodeList do
           local tempData = PetkaPaiManager.m_StageInfo.stageNodeList[i]
           if tempData.stageId==stageId then
              return tempData.getStarNum
           end        
       end
    end
    return 0
    -- body
end
--[[获得Node索引]]
function NormalFuBenUI:getTransInd(chapterId)
    return ((chapterId%1000)-1) % CONSTPAGENUM + 1
end

function NormalFuBenUI:updateData( data )
    local showShowStarNum = 0
    local curFightChapterId = 0  --当前战斗所在的关卡
    local isReload = false
    if data.starNum > 0 then
        for i=1, #self._datas.passList do
            if self._datas.passList[i].chapterId == JsonConfig.getMapIdByStageID(data.curStageId) then            
                curFightChapterId=self._datas.passList[i].chapterId

                local curStageStarNum = self:getStageStartNum(data.curStageId)

                local getStartNum = data.starNum-curStageStarNum

                if 0>getStartNum then getStartNum=0 end
                if getStartNum>0 then
                   isReload=true
                end
                showShowStarNum = self._datas.passList[i].ownStarNum + getStartNum
                self._datas.passList[i].ownStarNum = showShowStarNum
                self._datas.ownTotalStarNum = self._datas.ownTotalStarNum +getStartNum
                if data.unLockBox>0 then
                    print("data.unLockBox",data.unLockBox)
                   
                   self._datas.passList[i].ownBoxNum=self._datas.passList[i].ownBoxNum+1
                end
                if data.unLockstarBox > 0 then
                
                    self._datas.passList[i].ownBoxNum=self._datas.passList[i].ownBoxNum+1
                end

            end
        end
    end

    if data.unLockMap == nil then
        return
    end

    --[[解锁新地图]]
    -- print("data.unLockMap",data.unLockMap)
    if data.unLockMap > 0 and data.unLockMap ~= self._datas.curChapterId  then --and 

        LUserConfigMgr:SetChpaterDialogOver(false)
        -- self:setLastNode(lastNode,self._datas.curChapterId)--设置上一个关卡
        self._datas.curChapterId = data.unLockMap

        self._mapIndex = self:getPageNumByChapter(self._datas.curChapterId)
        self._openChapterIndex = self._datas.curChapterId % 1000
        -- self:setCurNode(self._datas.curChapterId) --设置当前关卡
        local locakData = {}
        locakData.chapterId=data.unLockMap
        locakData.ownStarNum = 0
        locakData.ownBoxNum  = 0

        --self._allPageData = self._datas.mapNodeList
        table.insert(self._datas.passList,locakData)
        self.m_pTableView:reloadData()

        local tempPageNum = self:getPageNumByChapter( self._datas.curChapterId )
        -- print("tempPageNum",tempPageNum,"self._curPageNum",self._curPageNum)
        if tempPageNum ~= self._curPageNum then
            self:ChangePage(tempPageNum - 1, true)
        end

        if data.unLockMap == ZXCJOPENCHP then
            self._needOpenZXCJ = true
        end

    else
        if isReload then
           self.m_pTableView:reloadData()
        end
       -- self:updateChapter(lastNode,curFightChapterId,showShowStarNum)
    end   
    
    if data.stageId > self._datas.curStageID  then
        self._datas.curStageID = data.stageId
    end
    
    --[[
    后面再改一下
    ]]
    for i = 1, 3 do
        if self._pageCellCtrlArr[i] ~= nil then
            self._pageCellCtrlArr[i]:RefreshPage()
        end
    end 
end











--[[解锁新关卡
   设置原来关卡
]]
-- function NormalFuBenUI:setLastNode(node,chapterId)
--     node:getChildByName("Finish"):setVisible(true)
--     local Text_xing = node:getChildByName("Text_xing")
--     Text_xing:setVisible(true)
--     local HeadBg = node:getChildByName("HeadBg")
--     HeadBg:setVisible(false)
--     local showShowStarNum = self:getChapterOwnStar(chapterId)
--     local maxStarNum = self:getChapterMaxStarNum(chapterId)
--     Text_xing:setString(string.format("%d/%d", showShowStarNum, maxStarNum))
--     if showShowStarNum>=maxStarNum then
--         node:getChildByName("perfect"):setVisible(true)
--     end
-- end
--[[解锁新关卡
   设置当前关卡
]]
-- function NormalFuBenUI:setCurNode(chapterId)
--     local tempPageNum = self:getPageNumByChapter(chapterId)
--     if tempPageNum~=self._curPageNum then
--        self._curPageNum=tempPageNum
--        if self._curPageNum>=self._curShow then
--             self:LoadNewPages();
--        end
--        self._pageView:scrollToPage(self._curPageNum-1,0.3)
--     end
--     local node = self:getStageNode(self._curPageNum,self:getTransInd(chapterId))
--     node:getChildByName("Label"):setVisible(true);
--     node:findChildByName("Label/Text"):setVisible(true);
--     local suo = node:getChildByName("suo")
--     suo:setVisible(false)
--     --更新星星
--     local curText_xing = node:getChildByName("Text_xing")
--     curText_xing:setVisible(true)
--     local  curMaxStarNum = self:getChapterMaxStarNum(chapterId)
--     curText_xing:setString(string.format("%d/%d", 0, curMaxStarNum))
--     --显示头像
--     local HeadBg = node:getChildByName("HeadBg")
--     HeadBg:setVisible(true)
--     local prof = LRoleDataMgr.MyHeroInfo.head
--     local strHeadImage = AppDef:GetHeroPicFileName(prof, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
--     HeadBg:getChildByName("Icon"):loadTexture(strHeadImage, ccui.TextureResType.localType)
-- end
--[[更新关卡]]
-- function NormalFuBenUI:updateChapter(node,chapterId,showShowStarNum)
--     local curText_xing = node:getChildByName("Text_xing")
--     curText_xing:setVisible(true)
--     local  curMaxStarNum = self:getChapterMaxStarNum(chapterId)
--     --print("一共多少星showShowStarNum",showShowStarNum)
--     curText_xing:setString(string.format("%d/%d", showShowStarNum, curMaxStarNum))
--     if showShowStarNum>=curMaxStarNum then
--         node:getChildByName("perfect"):setVisible(true)
--     end
-- end




--[[获取页数  关卡id]]
function NormalFuBenUI:getPageNumByChapter(chapter)
    return  math.ceil(chapter%1000/5)
    -- body
end


function NormalFuBenUI:refrashData( data )
    self._datas = data
    self._curShow=1
    self._curPageNum = 1
    self._openChapterIndex = self._datas.curChapterId % 1000
    print("self._datas.curChapterId",self._datas.curChapterId)
    self._mapIndex = self:getPageNumByChapter(self._datas.curChapterId)
    self._allPageData = self._datas.mapNodeList
    self._curChapterId = self._datas.curChapterId
    
    -- self._pageView:scrollToPage(self:getPageNumByChapter(self._curChapterId)-1,0) 
    -- self._leftBtn:setVisible(self:getPageNumByChapter(self._curChapterId)-1 > 0)
    -- self._rightBtn:setVisible(self:getPageNumByChapter(self._curChapterId)-1 < self._pageNum - 1)
end


function NormalFuBenUI:leftEvent( sender )
    -- body
    local curIndex =  self._pageView:getCurrentPageIndex()
    self:ChangePage(curIndex - 1,true)
end
function NormalFuBenUI:rightEvetn( sender )
    local curIndex =  self._pageView:getCurrentPageIndex()
    self:ChangePage(curIndex + 1,true)
end

function NormalFuBenUI:ChangePage(curIndex,isScroll)
    self._leftBtn:setVisible(curIndex > 0)
    self._rightBtn:setVisible(curIndex < self._pageNum - 1)
    local oldPage = self._curPageNum
    self._curPageNum = curIndex + 1
    local index = curIndex * 5 + 1

    if #self._allPageData >= index then
        self._curChapterId = self._allPageData[index].chapterId

        -- self._fubenName:setString(self._allPageData[index].chapterName)
    end

    self:updateRLTipsUI(curIndex, afterIndex)
    self:TurnPage(self._curPageNum, oldPage);
    if isScroll then
        self._pageView:scrollToPage(curIndex)
    end
end

function NormalFuBenUI:getStageNode( page, index )
    -- body
    -- local index = (page - 1)*5 + index
    local data = self._allPageData[index]
    local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
    for i = 1, 3 do
        if self._pageCellCtrlArr[i] ~= nil and self._pageCellCtrlArr[i]._curPage == page then
            return self._pageCellCtrlArr[i]._view["btn_" .. index];
        end
    end
    return nil
    -- local page = self._pageView:getItem(page - 1)
    -- local bg = page:getChildByName("Bg1")
    -- local btn = bg:getChildByName(configData.Chapter_btn)
    -- return btn
end







-- function NormalFuBenUI:refreshUI( ... )
--     -- body
--    ----print("refreshUI ======================>")
--     local mylevel = LRoleDataMgr.MyHeroInfo.level
--     --print("刷新UIrefreshUI")
--     ----print("NormalFuBenUI:refreshUI ===========>", self._curShow)
--     for i= self._curShow ,self._curShow + 4 do
--         local page = self._pageView:getItem(i - 1)
--         local bg = page:getChildByName("Bg1")

--         for j=1, 5 do
--             local index = (i - 1)*5 + j
--             local data
--             if self._allPageData ~= nil and #self._allPageData >= index then
--                 data = self._allPageData[index]
--             end

--             local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
--             local btn = bg:getChildByName(configData.Chapter_btn)
--             btn:setVisible(true)
--             btn:setTag(index)
--             btn:addClickEventListener(handler(self, NormalFuBenUI.enterEvent))
--             local  Label = btn:getChildByName("Label")
--             local name = Label:getChildByName("Text")
--             Label:setVisible(true)
--             name:setVisible(false)
--             local xuhao = name:getChildByName("xuhao")
--             local Finish = btn:getChildByName("Finish")
--             Finish:setVisible(false)

--             local perfect = btn:getChildByName("perfect")
--             perfect:setVisible(false)

            
--             --锁的状态显示
--             local suo = btn:getChildByName("suo")
--             local lock = suo:getChildByName('lock')
--             --print(self._mapIndex,i,self._openChapterIndex,j,"锁的状态显示=========>")
--             lock:setVisible(false)
--             suo:setVisible(true)
--             if self._mapIndex > i then 
--                --print(self._mapIndex,i,"锁的状态显示1")
--                 suo:setVisible(false)
--                 name:setVisible(true)
--             elseif self._mapIndex == i then
--                 if self._openChapterIndex >= index then
--                     --print(self._mapIndex,i,"锁的状态显示2")
--                     suo:setVisible(false)
--                     name:setVisible(true)
--                 -- elseif self._openChapterIndex == index then
--                 --     --print(self._mapIndex,i,"锁的状态显示3")
--                 --     suo:setVisible(false)
--                 --     name:setVisible(true)
--                 else
--                     suo:setVisible(true)
--                     name:setVisible(false)
--                 end
--             else
--                 suo:setVisible(true)
--                 name:setVisible(false)

--             end
--             local HeadBg = btn:getChildByName("HeadBg")
--             self:PlayBoxAndHead(HeadBg)
--             HeadBg:setTag(index)
--             HeadBg:addClickEventListener(handler(self, NormalFuBenUI.enterEvent))
--             HeadBg:setVisible(false)
--             if index == 1 then
--                 self.m_guideBtn1 = HeadBg
--             elseif index == 2 then
--                 self.m_guideBtn2 = HeadBg
--             end
--             local boxBg =  btn:getChildByName("boxBg")
--             self:PlayBoxAndHead(boxBg)
--             local red = boxBg:getChildByName("Prompt")
--             boxBg:setVisible(false)
--             red:setVisible(false)
--             local Text_xing1 = btn:getChildByName("Text_xing")
--             Text_xing1:setVisible(false)

--             if data then
--                 --print("--------------------data.chapterId",data.chapterId,data.chapterMaxStarNum)
--                 --local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
--                 if configData.OpenLv > mylevel then
--                     --等级未达到,未解锁
--                     lock:setVisible(true)
--                     lock:setString(string.format(GUITips.RSI_XUEZHAN_TIP18, configData.OpenLv))
--                 end

--                 if not lock:isVisible() and not name:isVisible() then
--                     Label:setVisible(false)
--                 end

--                 if j == 1 then
--                     local bgImg = bg:getChildByName("Image");
--                     bgImg:loadTexture("res/UI/Icon/ui_map_icon/" ..configData.World_bg .. ".png", ccui.TextureResType.localType)
--                 end
               
--                 name:setString(data.chapterName)
--                 xuhao:setString(data.chapterId % 1000)
                
--                 -- self._mapName:setString(data.chapterId)
--                 local ownBoxNum = self:getChapterOwnBoxNum(data.chapterId)
--                 --print("normalUI refreshUI ===>", data.chapterId, ownBoxNum, self:getChapterOwnStar(data.chapterId))
--                 if ownBoxNum > 0 then
--                     boxBg:setVisible(true)
--                     red:setVisible(true)
--                 end

--                 if self._curChapterId == data.chapterId then
--                     --后面一章开头
--                     --print("normalUI refreshUI ===>1")
--                     local afterIndex = (i - 1)*5 + 5
    
--                     self:updateRLTipsUI(curIndex, afterIndex)

--                     HeadBg:setVisible(true)
--                     local prof = LRoleDataMgr.MyHeroInfo.head
--                     local strHeadImage = AppDef:GetHeroPicFileName(prof, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
--                     HeadBg:getChildByName("Icon"):loadTexture(strHeadImage, ccui.TextureResType.localType)

--                     Text_xing1:setVisible(true)
--                     Text_xing1:setString(string.format("%d/%d", self:getChapterOwnStar(data.chapterId), data.chapterMaxStarNum))
--                 elseif self._curChapterId > data.chapterId then
--                     --print("normalUI refreshUI ===>2")
--                     Text_xing1:setVisible(true)
--                     Text_xing1:setString(string.format("%d/%d", self:getChapterOwnStar(data.chapterId), data.chapterMaxStarNum))
--                     --过关
--                     Finish:setVisible(true)
--                     perfect:setVisible(false)
--                 end

--                 --完美过关
--                 if self:getChapterOwnStar(data.chapterId) >= data.chapterMaxStarNum then
--                     Finish:setVisible(false)
--                     perfect:setVisible(true)
--                 end

            
--             end
--         end
--     end
-- end
function NormalFuBenUI:updateRLTipsUI( index, afterIndex)
    --print(index, afterIndex,"NormalFuBenUI:updateRLTipsUI( index, afterIndex)")
    -- body
    local isHaveBoxL, indexL = self:getBeforeHaveBox(index)
    self._Image_qipao_L:setVisible(isHaveBoxL)
    if isHaveBoxL then
        local strL = string.format(GUITips.RSI_FUBENMAP_RES17, indexL)
        self._Image_qipao_L:getChildByName("Text_1"):setString(strL)
    end
    
    local isHaveBoxR, indexR = self:getAfterHaveBox(afterIndex)
    self._Image_qipao_R:setVisible(isHaveBoxR)
    if isHaveBoxR then
        local strR = string.format(GUITips.RSI_FUBENMAP_RES17, indexR)
        self._Image_qipao_L:getChildByName("Text_1"):setString(strL)
    end
end
function NormalFuBenUI:enterEvent( sender )
    local index = sender:getTag()
    --print(index,"NormalFuBenUI:enterEvent( sender )") 
    if index > #self._datas.mapNodeList then
        local tips = string.format(GUITips.RSI_FUBENMAP_RES1, index - 1)
        Utils:ShowScrollTips(tips)
        return
    end
    local theStageData = {}
    theStageData.curChapterID = self._datas.curChapterId
    theStageData.curStageID = self._datas.curStageID
    theStageData.selectChapterId =  self._datas.mapNodeList[index].chapterId
    theStageData.chapterName = self._datas.mapNodeList[index].chapterName
    theStageData.ownChapterStarNum = self:getChapterOwnStar(self._datas.mapNodeList[index].chapterId)
    theStageData.maxStarNum = self._datas.mapNodeList[index].chapterMaxStarNum
    theStageData.ownTotalStarNum = self._datas.ownTotalStarNum
    local configData = JsonConfig.m_FuBenMapConfig.getDefByID(self._datas.mapNodeList[index].chapterId)
    theStageData.BundleId = configData.BundleId
    --print("theStageData.curChapterID =========>", theStageData.curChapterID, theStageData.selectChapterId)

    if theStageData.curChapterID < theStageData.selectChapterId then
        local tips = string.format(GUITips.RSI_FUBENMAP_RES1, index - 1)
        Utils:ShowScrollTips(tips)
        return
    end

    self._curChapterId = theStageData.selectChapterId
    -- dump(theStageData, "enterEvent ====>")

    self._theStageData = theStageData
    local isChapterOver = LUserConfigMgr:GetChpaterDialogOver()
    -- local isChapterOver = false
    if not isChapterOver and configData.DialogueId > 0 and theStageData.curChapterID == theStageData.selectChapterId  then
        Utils:InitUI("Common.NPCChatDialogUI", AppDef.UIType.Plot, {DialogueId = configData.DialogueId, isStageDialog = false})
        LUserConfigMgr:SetChpaterDialogOver(true)
        return
    end
    self:openStageScene() 
end

--打开当前关卡
function NormalFuBenUI:OpenCurChapter()
    dump(self.openChapterData,"self.openChapterData=========>")

    if self.openChapterData.chapterId==nil then
        self.openChapterData.chapterId=self._datas.curChapterId
    end

    local index = self.openChapterData.chapterId%1000
    local theStageData = {}

    theStageData.curChapterID = self._datas.curChapterId

    theStageData.curStageID = self._datas.curStageID

    theStageData.selectChapterId =  self._datas.mapNodeList[index].chapterId
    theStageData.chapterName = self._datas.mapNodeList[index].chapterName
    theStageData.ownChapterStarNum = self:getChapterOwnStar(self._datas.mapNodeList[index].chapterId)
    theStageData.maxStarNum = self._datas.mapNodeList[index].chapterMaxStarNum
    theStageData.ownTotalStarNum = self._datas.ownTotalStarNum
    local configData = JsonConfig.m_FuBenMapConfig.getDefByID(self._datas.mapNodeList[index].chapterId)
    theStageData.BundleId = configData.BundleId
    if theStageData.curChapterID < theStageData.selectChapterId then
        local tips = string.format(GUITips.RSI_FUBENMAP_RES1, index - 1)
        Utils:ShowScrollTips(tips)
        return
    end
    self._curChapterId = theStageData.selectChapterId
    self._theStageData = theStageData
    self._theStageData.openStageId=self.openChapterData.stageId

    dump(self._theStageData,"打开关卡stageIdself._theStageData=====>")
    print("打开关卡stageId",self.openChapterData.stageId)
    -- local isChapterOver = LUserConfigMgr:GetChpaterDialogOver()
    -- if not isChapterOver and configData.DialogueId > 0 and theStageData.curChapterID == theStageData.selectChapterId  then
    --     Utils:InitUI("Common.NPCChatDialogUI", AppDef.UIType.Plot, {DialogueId = configData.DialogueId, isStageDialog = false})
    --     LUserConfigMgr:SetChpaterDialogOver(true)
    --     return
    -- end
    self:openStageScene() 
end

function NormalFuBenUI:openStageScene( ... )
    -- body 
    Utils:InitUI("FuBenMap.FuBenDetailUI", AppDef.UIType.Normal, self._theStageData)
end

function NormalFuBenUI:getChapterOwnStar( chapterId )
    -- body
    for i=1, #self._datas.passList do
        if self._datas.passList[i].chapterId == chapterId then
            return self._datas.passList[i].ownStarNum
        end
    end
    return 0
end

function NormalFuBenUI:getChapterOwnBoxNum( chapterId )
    -- body
    for i=1, #self._datas.passList do
        if self._datas.passList[i].chapterId == chapterId then
            return self._datas.passList[i].ownBoxNum
        end
    end
    return 0
end

function NormalFuBenUI:updateChapterOwnBoxData( data )
    -- body
    for i=1, #self._datas.passList do
        if self._datas.passList[i].chapterId == data.chapterId then
            self._datas.passList[i].ownBoxNum = self._datas.passList[i].ownBoxNum - 1
            --更新UI
            -- --print("updateChapterOwnBoxData ==>", self._datas.passList[i].ownBoxNum)
            if self._datas.passList[i].ownBoxNum <= 0 then
                local page = math.floor((i - 1) / CONSTPAGENUM) + 1
                local lastIndex = (i - 1) % CONSTPAGENUM + 1
                -- --print("updateChapterOwnBoxData ==>", page, lastIndex)
                local lastNode = self:getStageNode(page, lastIndex)
                local boxBg =  lastNode:getChildByName("boxBg")
                local red = boxBg:getChildByName("Prompt")
                boxBg:setVisible(false)
                red:setVisible(false)
            end
        end
    end
end
function NormalFuBenUI:getBeforeHaveBox( index )
    -- body
    if index == nil then
        return false
    end
    for i=1, #self._datas.passList do
        if i < index then
            return self._datas.passList[i].ownBoxNum > 0, i
        end
    end
    return false, 0
end
function NormalFuBenUI:getAfterHaveBox( index )
    -- body
    if index == nil then
        return false
    end
    for i=1, #self._datas.passList do
        if i > index then
            return self._datas.passList[i].ownBoxNum > 0, i
        end
    end
    return false, 0
end
function NormalFuBenUI:getCurChapterIndex( chapterId )
    -- body
    for i=1, #self._allPageData do
        if self._allPageData[i].chapterId == chapterId then
            return i
        end
    end
    return 0
end
function NormalFuBenUI:getChapterMaxStarNum( chapterId )
    -- body
    for i=1, #self._allPageData do
        if self._allPageData[i].chapterId == chapterId then
            return self._allPageData[i].chapterMaxStarNum
        end
    end
    return 0
end
function NormalFuBenUI:closeDialog( sender )
-- self.m_pUILayer:setVisible(false) 
   
    Utils:DeleteUI("FuBenMap.NormalFuBenUI")
end
function NormalFuBenUI:onExit()
    local guideIds = {GuideDef.StepId.Guide_FuBen_1,GuideDef.StepId.Guide_Pet_12,GuideDef.StepId.Guide_FuBen2_12
        ,GuideDef.StepId.Guide_FuBen3_12,GuideDef.StepId.Guide_FuBen4,GuideDef.StepId.Guide_Equip_11
        ,GuideDef.StepId.Guide_Pet_1,GuideDef.StepId.Guide_FuBen2_3,GuideDef.StepId.Guide_FuBen3_3
        ,GuideDef.StepId.Guide_Equip_1,GuideDef.StepId.Guide_Pet1_1,GuideDef.StepId.Guide_Arena_1
        ,GuideDef.StepId.Guide_XunBao_1}
    for i=1,#guideIds do
        Utils:SendMsg(LUIGuideEvent.UnRegisterStep, guideIds[i])
    end
    self.m_pUILayer = nil
    self:Destory()
    
    guideIds = {GuideDef.StepId.Guide_Pet_2,GuideDef.StepId.Guide_FuBen2_4,GuideDef.StepId.Guide_FuBen3_4
        ,GuideDef.StepId.Guide_Equip_2,GuideDef.StepId.Guide_Pet1_2,GuideDef.StepId.Guide_Arena_2
        ,GuideDef.StepId.Guide_XunBao_2}
    for i=1,#guideIds do
        Utils:CheckGuide(guideIds[i],true)
    end

    --关闭的时候更新副本红点
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.FuBenMap)    
end

function NormalFuBenUI:RegisterGuide()
    if self.m_guideBtn1 ~= nil then
        local guideIds = {GuideDef.StepId.Guide_FuBen_1,GuideDef.StepId.Guide_Pet_12,GuideDef.StepId.Guide_FuBen2_12,GuideDef.StepId.Guide_FuBen3_12}
        for i=1,#guideIds do
            Utils:RegisterGuide(guideIds[i], self.m_guideBtn1, function()
                self:enterEvent(self.m_guideBtn1)
            end, nil, true)
        end
    end
    if self.m_guideBtn2 ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen4, self.m_guideBtn2, function()
            self:enterEvent(self.m_guideBtn2)
        end, nil, false)

        Utils:RegisterGuide(GuideDef.StepId.Guide_Equip_11, self.m_guideBtn2, function()
            self:enterEvent(self.m_guideBtn2)
        end, nil, true)
    end

    if self.m_guideBtn ~= nil then
        local guideIds = {GuideDef.StepId.Guide_Pet_1,GuideDef.StepId.Guide_FuBen2_3,GuideDef.StepId.Guide_FuBen3_3
            ,GuideDef.StepId.Guide_Equip_1,GuideDef.StepId.Guide_Pet1_1,GuideDef.StepId.Guide_Arena_1
            ,GuideDef.StepId.Guide_XunBao_1}
        for i=1,#guideIds do
            Utils:RegisterGuide(guideIds[i], self.m_guideBtn, handler(self, NormalFuBenUI.closeDialog), nil, false)
        end
    end
end


function NormalFuBenUI:UpdateRedDot()
	local show = Utils:GetRedDotState(RedDotDef.ID.FengShengShiLian)
	self._fssl:setVisible(show)

    local showFBAc = Utils:GetRedDotState(RedDotDef.ID.FuBenAchievement)
    print("NormalFuBenUI:UpdateRedDot ==========>", showFBAc)
    self._achiPrompt:setVisible(showFBAc)

end

return NormalFuBenUI
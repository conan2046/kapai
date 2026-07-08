--[[
lua里面的游戏逻辑控制
]]

local ServerListUI = LUIBase:New()
ServerListUI.__index = ServerListUI
--local this = LTcpSocket
function ServerListUI:New()
	local o = LUIBase:New()
	setmetatable(o,ServerListUI)	
    o:Init()
	return o
end


function ServerListUI:Init()
    --self.m_pNode = cc.Node:create()
    self:InitMemberVars()
    self.m_pUILayer = cc.CSLoader:createNode("csd/Login/SeverListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitServerData()
    self:InitUIData()
    self:ShowList()
    self:AddTouchEvt()
end

function ServerListUI:InitUIData()

    local panelHead = self.m_pUILayer:getChildByName("SeverList")
    local panel = self.m_pUILayer:getChildByName("SeverList"):getChildByName("Panel_1")

    local leftview = panel:getChildByName("ListView_1")
    local rightView = panel:getChildByName("ListView_2")
    --print("SeverList",panel:getContentSize().width,panel:getContentSize().height)
    self.m_pLeftCell = panelHead:getChildByName("Item_1")
    self.m_pRightCell = panelHead:getChildByName("Item_2")
    self.m_pExitBtn = panel:getChildByName("btn_Exit")
    self.m_pEnterBtn = panelHead:getChildByName("Btn_Play")
    self.m_pLeftCell:setVisible(false)
    self.m_pRightCell:setVisible(false)
    self:InitLeftTabView(leftview)
    self:InitRightTabView(rightView)
    self:SelServerArea(self.m_selLeftInd)
end

--[[
声明成员变量
]]
function ServerListUI:InitMemberVars()
    self.m_pUILayer = nil
    self.m_pLeftCell = nil
    self.m_pRightCell = nil


    self.m_pServerInfo = nil
    self.m_pServerList = nil
    self.m_pServerAreaList = nil
    self.m_pRecommendServerList = nil
    self.m_needSelectDefault = false
    self.m_IsSelectRecommend = false
    self.m_IsRecommendServer = false
    self.m_totalAreaNum = 0
    self.m_selRightInd = -1
    self.m_selLeftInd = -1
    self.m_curServerNum = 0--
    
end

function ServerListUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pServerInfo = nil
    self.m_pServerList = nil
    self.m_pRecommendServerList = nil
    self.m_needSelectDefault = nil
    self.m_IsSelectRecommend = nil
    self.m_IsRecommendServer = nil
    self.m_totalAreaNum = nil
    self.m_pServerAreaList = nil
    self.m_selRightInd = nil
    self.m_selLeftInd = nil
    self.m_pLeftCell = nil
    self.m_pRightCell = nil
    self.m_curServerNum = nil
    self.m_pRightTableView = nil
end

function ServerListUI:AddTouchEvt()
    local function ExitCallback(sender)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.ServerListUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        if GameSdk:IsSDKUser() then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,1)
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            print("隐藏服务器列表 返回登录界面")

            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,2)
            self:SendMsg(LGameMsg.m_initUIMsg)
        end

    end
    self.m_pExitBtn:addClickEventListener(ExitCallback)  
	self:MarkIntaractCObj(self.m_pExitBtn)
    local function EnterGameCallback(sender)

        if self.m_selRightInd >= 0 then
            --再次点击进入游戏
            self:EnterGame()
        end
    end
    self.m_pEnterBtn:addClickEventListener(EnterGameCallback) 
	self:MarkIntaractCObj(self.m_pEnterBtn)
end

function ServerListUI:ShowList()
end

function ServerListUI:GetLastServerInfo()
    --取出上次登录的信息
    local serName = LUserConfigMgr:GetLastSelServerName()
    if serName ~= nil and string.len(serName) > 0 then
        local serId = LUserConfigMgr:GetLastSelServerId()
        --再次检测是否存在
        local ind = self:GetServer(serId)
        
        if ind == 0 then --不存在
            self.m_pServerInfo = nil
            LUserConfigMgr:SetLastSelServerName("")
            LUserConfigMgr:SetLastSelServerNum(-1)
            LUserConfigMgr:SetLastSelServerIp()
            LUserConfigMgr:SetLastSelServerPort(-1)
            LUserConfigMgr:SetLastSelServerPage(-1)
            LUserConfigMgr:SetLastSelServerId(-1)
            LUserConfigMgr:SetLastOnLineState(-1)
            LUserConfigMgr:SetLastServerState(-1)
            LUserConfigMgr:SetLastServerPicId(-1)
            return false
        else
            self.m_pServerInfo = self.m_pServerList[ind]
        end
        return true
    end
    return false
end

function ServerListUI:GetServer(serId)
    for k= 1, #self.m_pServerList do
        if serId == self.m_pServerList[k].serId then
            --info = serList[i];
            return k
        end
    end
    return 0
end

function ServerListUI:InitServerData()
    self.m_pServerList = LRoleDataMgr.Account.serverList

    self.m_pRecommendServerList = {}
    --------------------------------------------------------------
    if #self.m_pServerList == 0 then
        return
    end
    --------------------------------------------------------------
    -- table.sort(self.m_pServerList,function(a,b)
    --         if a.page == b.page then
    --             return a.id < b.id
    --         else
    --             return a.page < b.page
    --         end
    --         end)
    -- table.sort(self.m_pServerList,function(a,b)
    --         return a.page < b.page
    --         end)
    local serverArr = {}
    local pageArr = {}
    for i = 1, #self.m_pServerList do
        local curPage = self.m_pServerList[i].page
        if serverArr[curPage] == nil then
            serverArr[curPage] = {}
            table.insert(pageArr,curPage)
        end
        table.insert(serverArr[curPage], self.m_pServerList[i])
    end
    table.sort(pageArr,function(a,b) return a < b end)
    LRoleDataMgr.Account.serverList = {}
    for i = 1, #pageArr do
        for j = 1, #serverArr[pageArr[i]] do
            table.insert(LRoleDataMgr.Account.serverList,serverArr[pageArr[i]][j])
        end
    end
    self.m_pServerList = LRoleDataMgr.Account.serverList
    --------------------------------------------------------------
    self.m_pServerAreaList = {}
    local temp = {}
    for k= 1, #self.m_pServerList do
        local page = self.m_pServerList[k].page
        if temp[page] == nil then
            temp[page] = {}
            table.insert(self.m_pServerAreaList, temp[page])
        end
        table.insert(self.m_pServerAreaList[#self.m_pServerAreaList], self.m_pServerList[k])

        local info = self.m_pServerList[k]
        if info and (info.serType >= 1 or LRoleDataMgr.Account:GetServerHeroInfo(info.id)) then--新服或推荐服或BUG FIXED2203
            table.insert(self.m_pRecommendServerList, self.m_pServerList[k])
        end
    end
    --------------------------------------------------------------
    local IsLastServer = self:GetLastServerInfo()--是否有上次登陆
    if #self.m_pRecommendServerList > 0 or IsLastServer == true then
        table.sort(self.m_pRecommendServerList, function(a, b)
            if LRoleDataMgr.Account:GetServerHeroInfo(a.id) == nil then
                return false
            elseif LRoleDataMgr.Account:GetServerHeroInfo(b.id) == nil then
                return true
            end
            return a.id < b.id
        end)
        if IsLastServer == true then
            for i = 1, #self.m_pRecommendServerList do
                if self.m_pRecommendServerList[i].serId == self.m_pServerInfo.serId then
                    table.remove(self.m_pRecommendServerList,i)
                    break
                end
            end
            table.insert(self.m_pRecommendServerList,1,self.m_pServerInfo)
        end

        self.m_IsRecommendServer = true
    else
        self.m_IsRecommendServer = false
    end
    --------------------------------------------------------------
    -- dump(self.m_pServerAreaList)
    self.m_totalAreaNum = #self.m_pServerAreaList
    self.m_selLeftInd        = 0 --默认选中最上面那个区
    self.m_selRightInd = 0
end

--右边服务器列表内容，创建服务器列表条
function ServerListUI:SelServerArea(selectBtn)
    if self.m_pServerAreaList == nil then
        return
    end
    local serverIdxInArea = 0--索引某区的序列（非全部区)
    self.m_needSelectDefault = false
    self.m_IsSelectRecommend = false

    --上次登录按钮初始化
    if selectBtn==0 and self.m_IsRecommendServer == true then
        self.m_IsSelectRecommend = true
        self.m_curServerNum = #self.m_pRecommendServerList
    else
        self.m_IsSelectRecommend = false
        local areaList
        if not self.m_IsRecommendServer then
            areaList = self.m_pServerAreaList[selectBtn + 1]
        else
            areaList = self.m_pServerAreaList[selectBtn]
        end
        if areaList then
            self.m_curServerNum = #areaList
        else
            self.m_curServerNum = 0
        end
    end
    self.m_selLeftInd = selectBtn
    self.m_pRightTableView:reloadData()
end

function ServerListUI:InitLeftTabView(leftview)
    local tableView = cc.TableView:create(leftview:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(leftview:getAnchorPoint())
    tableView:setPosition(leftview:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    leftview:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:LeftTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pLeftCell:getContentSize().width
        local height = self.m_pLeftCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableLeftCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local cnt = self.m_totalAreaNum
        --print("m_totalAreaNum",self.m_totalAreaNum)
        if self.m_IsRecommendServer == true then
            cnt = cnt + 1
        end
        --print("cnt",cnt)
        return cnt
        --self:NumberOfCellsInTableView()
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pLeftTableView = tableView
end

function ServerListUI:InitRightTabView(rightView)
    local tableView = cc.TableView:create(rightView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(rightView:getAnchorPoint())
    tableView:setPosition(rightView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    rightView:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched",sender,cell,cell:getIdx())
        self:RightTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pRightCell:getContentSize().width
        local height = self.m_pRightCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:RightTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        --print("self.m_curServerNum=",self.m_curServerNum)
        return self.m_curServerNum
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    --tableView:reloadData()
    self.m_pRightTableView = tableView
end

function ServerListUI:LeftTableCellTouched(cell)
    local ind = cell:getIdx()

    if self.m_selLeftInd == ind then
        return
    end
     
    local cellChild = cell:getChildByTag(123)
    local oldCell = self.m_pLeftTableView:cellAtIndex(self.m_selLeftInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nli then
            oldCellChild:setSelected(false)
        end
    end
    cellChild:setSelected(true)

    self:SelServerArea(ind)
end

function ServerListUI:RightTableCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    if self.m_selRightInd == ind then
        --再次点击进入游戏
        self:EnterGame()
    else
        local oldCell = self.m_pRightTableView:cellAtIndex(self.m_selRightInd)
        if oldCell ~= nil then
            local oldCellChild = oldCell:getChildByTag(123)
            if oldCellChild ~= nli then
                local selectImg = oldCellChild:getChildByName("Choose")
                selectImg:setVisible(false)
            end
        end
        self.m_selRightInd = ind
        --cellChild:setSelected(true)
        local selectImg = cellChild:getChildByName("Choose")
        selectImg:setVisible(true)
    end
end

function ServerListUI:RightTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pRightCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)

    else
        cellChild = cell:getChildByTag(123)
    end
    if self.m_IsSelectRecommend == true then
        self:ShowRightRecommendCellInfo(cellChild, idx)
    else
        self:ShowRightCommonCellInfo(cellChild, idx)
    end
    local selectImg = cellChild:getChildByName("Choose")
    local _ = selectImg and selectImg:setVisible(idx == self.m_selRightInd)
    return cell
end

function ServerListUI:ShowRightCellInfo(cellChild, serverInfo, serHeroInfo)
    if serverInfo == nil then
        return
    end
    local info = serverInfo
    local serHInfo = serHeroInfo

    local headPanel = cellChild:getChildByName("bg_head")
    local nameLabel = cellChild:getChildByName("Name")
    --print("headPanel=",headPanel,"nameLabel=",nameLabel)
    if serHInfo ~= nil then
        local filestr = AppDef:GetHeroPicFileName(serHInfo.head, AppDef.HeadType.HERO_IMAGE_HEAD)
        local headSp = headPanel:getChildByName("icon")
        headSp:loadTexture(filestr, ccui.TextureResType.localType)
        --headSp:setContentSize(headPanel:getContentSize())

        local lvLabel = headPanel:getChildByName("Level")
        lvLabel:setString(serHInfo.level)

        nameLabel:setString(serHInfo.name)
        headPanel:setVisible(true)
    else
        headPanel:setVisible(false)
        nameLabel:setString(GUITips.Login_Server_No_RoleData)
    end
    
    --服务器名字
    local serverLabel = cellChild:getChildByName("SeverName")
    
    local color = {UICOLOR_GREEN,UICOLOR_YELLOW,UICOLOR_ORANGE}
    local newServerSp = cellChild:getChildByName("State")

    --[[
    self.serType = -1--0正常 1推荐 2新服
    self.onlineState = -1--0绿 1黄 2红
    self.serState = -1--0正常 1维护中
    ]]
    if info.onlineState < 3 then
        serverLabel:setColor(color[info.onlineState + 1])
        --dump(info)
        --设置流畅或者拥挤    serType：0正常 1推荐 2新服   serState：0：正常1：维护
        if info.serState == 1 then
            newServerSp:loadTexture("res/UI/ui_severlist/ui_biaoshi_weihu.png", UI_TEX_TYPE_PLIST)
            serverLabel:setString(info.serName)
        elseif info.onlineState ==0 then--流畅
            newServerSp:loadTexture("res/UI/ui_severlist/ui_biaoshi_liuchang.png", UI_TEX_TYPE_PLIST)
            serverLabel:setString(info.serName)
        elseif info.onlineState ==1 then--拥挤
            newServerSp:loadTexture("res/UI/ui_severlist/ui_biaoshi_yongji.png", UI_TEX_TYPE_PLIST)
            serverLabel:setString(info.serName)    
        elseif info.onlineState ==2 then--爆满
            newServerSp:loadTexture("res/UI/ui_severlist/ui_biaoshi_baoman.png", UI_TEX_TYPE_PLIST)
            serverLabel:setString(info.serName)
        end
    else
        serverLabel:setString(info.serName)
    end
    local newflag = cellChild:getChildByName("New")
    if info.serType == 2 then
        newflag:setVisible(true)
    else
        newflag:setVisible(false)
    end
    
end

--[[
右边推荐列表
]]
function ServerListUI:ShowRightRecommendCellInfo(cellChild, idx)
    local info = self.m_pRecommendServerList[idx + 1]
    local serHInfo = LRoleDataMgr.Account:GetServerHeroInfo(info.id)
    self:ShowRightCellInfo(cellChild, info, serHInfo)
end

--[[
右边正常列表
]]
function ServerListUI:ShowRightCommonCellInfo(cellChild, idx)
    local areaList
    if not self.m_IsRecommendServer then
        areaList = self.m_pServerAreaList[self.m_selLeftInd + 1]
    else
        areaList = self.m_pServerAreaList[self.m_selLeftInd]
    end
    if areaList == nil then
        return
    end
    local info = areaList[idx + 1]
    if info == nil then
        return
    end
    local serHInfo = LRoleDataMgr.Account:GetServerHeroInfo(info.id)
    self:ShowRightCellInfo(cellChild, info, serHInfo)
end

function ServerListUI:TableLeftCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pLeftCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowLeftCellInfo(cellChild, idx)
    return cell
end

function ServerListUI:ShowLeftCellInfo(cell, idx)
    -- print("self.m_selLeftInd--->", self.m_selLeftInd, idx)
    cell:setSelected(self.m_selLeftInd == idx)
    ------------------------------------------------
    local text = cell:getChildByName("Text")
    if text == nil then
        return
    end
    ------------------------------------------------
    if self.m_IsRecommendServer and idx == 0 then
        text:setString(GUITips.Login_Server_Recommed)
        return
    else
        ------------------------------------------------
        if not self.m_IsRecommendServer then
            idx = idx + 1
        end
        local areaList = self.m_pServerAreaList[idx]
        if areaList == nil or #areaList == 0 then
            return
        end
        local curServerInfo = areaList[1]
        if curServerInfo.page == 0 then
            text:setString(GUITips.Login_Server_Test)
        else
            text:setString(string.format("%d%s", curServerInfo.page, GUITips.Login_Server_Fu))
        end
    end
end

--[[
进入游戏
]]
function ServerListUI:EnterGame()
    local server = nil
    if self.m_IsSelectRecommend == true then
        server = self.m_pRecommendServerList[self.m_selRightInd + 1]
    else
        if not self.m_IsRecommendServer then
            areaList = self.m_pServerAreaList[self.m_selLeftInd + 1]
        else
            areaList = self.m_pServerAreaList[self.m_selLeftInd]
        end
        server = areaList[self.m_selRightInd + 1]
    end
    if server == nil then
        return
    end
    --判断服务器是否有维护
    if server.serState ~= 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,server.errMsg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end
    LGameMsg.m_baseMsgWithOne:Change(LGameNetEvent.TCPSelectedGameServer, server)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    -- GetLoginMainLayer()->StartGameLogin(server)
    -- LUserConfigMgr:SetIsFirstLogin("false")
end

return ServerListUI
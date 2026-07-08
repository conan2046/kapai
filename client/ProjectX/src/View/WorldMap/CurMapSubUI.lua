--[[
lua里面的游戏逻辑控制
]]

local CurMapSubUI = LUIBase:New()
CurMapSubUI.__index = CurMapSubUI
--local this = LTcpSocket
function CurMapSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,CurMapSubUI)	
    o:Init()
	return o
end


function CurMapSubUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/CurMapLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    
    self:ShowCurMap()
    self:LoadMapData()
    self:InitTabView()
    self:AddTouchEvt()
end

function CurMapSubUI:InitTabView()
    local tableView = cc.TableView:create(self.m_pListView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pListView:getAnchorPoint())
    tableView:setPosition(self.m_pListView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pListView:getParent():addChild(tableView)
    self.m_pListView:removeFromParent()
    self.m_pListView = nil
    local function tableCellTouched(sender,cell)
        self:TableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pItemCell:getContentSize().width
        local height = self.m_pItemCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local cnt =  #self.m_pNPCList  + #self.m_pMonsterList + #self.m_pGateList
        return cnt
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pListTableView = tableView
end

function CurMapSubUI:TableCellTouched(cell)
    local idx = cell:getIdx()
     if self.m_curSelectedInd == idx then
        return
    end
    local cellChild = cell:getChildByTag(123)
    local oldCell = self.m_pListTableView:cellAtIndex(self.m_curSelectedInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nil then
            local selectImg = oldCellChild:getChildByName("Choose")
            selectImg:setVisible(false)
        end
    end
    self.m_curSelectedInd = idx
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)

    local pathType = -1
    local pos = cc.p(0,0)
    if idx < #self.m_pNPCList then
        local tmpPoint = self.m_pNPCList[idx + 1]:GetPos()
        -- pos.x = tmpPoint.x
        -- pos.y =  (self.m_pMapSize.height - tmpPoint.y)
        pos = tmpPoint
        pathType = 0
    elseif idx < #self.m_pNPCList + #self.m_pMonsterList then
        --self:ShowMonsterCellInfo(cell,idx - #self.m_pNPCList)
        idx = idx - #self.m_pNPCList
        local tmpPoint = self.m_pMonsterList[idx + 1]:GetPos()
        -- pos.x = tmpPoint.x
        -- pos.y =  (self.m_pMapSize.height - tmpPoint.y)
        pos = tmpPoint
    else
        idx = idx - #self.m_pNPCList - #self.m_pMonsterList
        pos.x = self.m_pGateList[idx + 1].x
        pos.y = self.m_pMapSize.height - self.m_pGateList[idx + 1].y
        --self:ShowGateCellInfo(cell, idx - #self.m_pNPCList - #self.m_pMonsterList)
    end
    LGameMsg.m_autoPathMsg:ChangeToStart(LRoleDataMgr.MyHeroInfo.sid,pos.x,pos.y,pathType,0,false,false,nil)
    self:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --self:SelServerArea(ind)
end

function CurMapSubUI:TableCellAtIndex(sender,idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pItemCell:clone()
        cellChild:setTouchEnabled(false)
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowCellInfo(cellChild,idx)
    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curSelectedInd then 
        --cellChild:setSelected(true)
        
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end

    return cell
end

function CurMapSubUI:ShowCellInfo(cell, idx)
    if idx < #self.m_pNPCList then
        self:ShowNPCCellInfo(cell,idx)
    elseif idx < #self.m_pNPCList + #self.m_pMonsterList then
        self:ShowMonsterCellInfo(cell,idx - #self.m_pNPCList)
    else
        self:ShowGateCellInfo(cell, idx - #self.m_pNPCList - #self.m_pMonsterList)
    end
    
end

function CurMapSubUI:GetNpcBodyTexture(npcType, npcPicId)
    if npcType == 0 then  --NPC
        return string.format("res2/Npc_Bust/%d_tou.png", npcPicId)
    elseif npcType == 2 then --怪物
        return string.format("res2/Monster_Bust/%d_tou.png", npcPicId)
    elseif npcType == 3 then --坐骑
        return string.format("res2/Horse_Bust/%d_tou.png", npcPicId)
    else
        return "res2/Monster_Bust/head_defult.png"
    end
end

function CurMapSubUI:ShowNPCCellInfo(cell, idx)
    idx = idx + 1
    local text = cell:getChildByName("Name")
    text:setString(self.m_pNPCList[idx]:GetName())
    local headImg = cell:getChildByName("bg_icon"):getChildByName("Icon")
    local imgPath = self:GetNpcBodyTexture(self.m_pNPCList[idx]:GetType(),self.m_pNPCList[idx]:GetPicId())
    headImg:loadTexture(imgPath,ccui.TextureResType.localType)

    local stateImg = cell:getChildByName("imgState")
    local npcID = self.m_pNPCList[idx]:GetId()
    local strState = ""
    if npcID ==9 or npcID == 10 then--药店杂货店
        strState = "UI/shopNPC.png"
    elseif npcID == 7 then--武器店npc
        strState = "UI/wearponNPC.png"
    elseif npcID == 8 then--防具店npc
        strState = "UI/fangjuNPC.png"
    elseif npcID == 24 then--竞技npc
        strState = "UI/jingjiNPC.png"
    elseif npcID == 6 then--钱庄老板npc
        strState = "UI/guanliNPC.png"
    elseif npcID == 25 then--帮派总管npc
        strState = "UI/zongguanNPC.png"
    end
    if string.len(strState) > 0 then
        stateImg:setVisible(true)
        stateImg:loadTexture(strState,ccui.TextureResType.localType)
    else
        stateImg:setVisible(false)
    end
end

function CurMapSubUI:ShowMonsterCellInfo(cell, idx)
    idx = idx + 1
    local text = cell:getChildByName("Name")
    text:setString(self.m_pMonsterList[idx]:GetName())

    local headImg = cell:getChildByName("bg_icon"):getChildByName("Icon")
    local imgPath = "res2/Monster_Bust/" .. self.m_pMonsterList[idx]:GetPicId().. "_tou.png"
    headImg:loadTexture(imgPath,ccui.TextureResType.localType)

    cell:getChildByName("imgState"):setVisible(false)
end

function CurMapSubUI:ShowGateCellInfo(cell, idx)
    idx = idx + 1
    local text = cell:getChildByName("Name")
    text:setString(self.m_pGateNameList[idx])

    local headImg = cell:getChildByName("bg_icon"):getChildByName("Icon")
    local imgPath = "UI/chuansongNPC.png"
    headImg:loadTexture(imgPath,ccui.TextureResType.localType)

    cell:getChildByName("imgState"):setVisible(false)
end

function CurMapSubUI:LoadMapData()
    local function GetCurMapCallback(npclist,monsterlist,gatelist,gateNameList,mapSize,heroNode)
        self.m_pNPCList = npclist
       print("NPC个数"..#self.m_pNPCList)
        self.m_pMonsterList = monsterlist
        self.m_pGateList = gatelist
        self.m_pGateNameList = gateNameList
        self.m_pMapSize = mapSize
        self.m_pHeroNode = heroNode

        self.m_pWidthScale = self.m_pMiniMapSize.width/self.m_pMapSize.width
        self.m_pHeightgScale = self.m_pMiniMapSize.height/self.m_pMapSize.height
        --print("MapSize=",mapSize.width,mapSize.height)
        self:ShowObjInMap()
    end
 
    local msg = GetMapChildMsg:new(CEnum.MapEvent.LuaGetCurMapObjData,GetCurMapCallback)
    self:SendMsg(msg)
end

-- function CurMapSubUI:DelayToShow()
--     local function LoadMapData()
        
--     end
--     local func = cc.CallFunc:create(LoadMapData)
--     local sequence = cc.Sequence:create(0.1, func)
--     self.m_pUILayer:runAction(sequence)
-- end

function CurMapSubUI:onExit()
    if self.m_posSchedulerID ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_posSchedulerID)
        self.m_posSchedulerID = nil
    end

    self.m_pMapScrollView = nil
    self.m_pItemCell = nil

    self.m_pListView = nil
    self.m_pListTableView = nil
    self.m_pMiniMapImg = nil
    self.m_pNPCList = nil
    self.m_pMonsterList = nil
    self.m_pGateList = nil
    self.m_pGateNameList = nil
    self.m_pMapSize = nil
    self.m_pHeroNode = nil
    self.m_pHeroAni = nil
    self.m_pMiniMapSize = nil
    self.m_pMiniMapScreenSize = nil
    self.m_pWidthScale = nil
    self.m_pHeithgScale = nil
    self.m_posSchedulerID = nil
    self.m_curSelectedInd = nil
    self:Destory()
end

function CurMapSubUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel_1")
    self.m_pMapScrollView = panel:getChildByName("mapScrollView")
    self.m_pMapScrollView:setScrollBarEnabled(false)--不显示滚动条
    self.m_pItemCell = self.m_pUILayer:getChildByName("Item")
    self.m_pItemCell:setVisible(false)

    self.m_pListView = panel:getChildByName("BtnList")
    self.m_pListTableView = nil
    self.m_pMiniMapImg = nil
    self.m_pNPCList = nil
    self.m_pMonsterList = nil
    self.m_pGateList = nil
    self.m_pGateNameList = nil
    self.m_pMapSize = nil
    self.m_pHeroNode = nil
    self.m_pHeroAni = nil
    self.m_pMiniMapSize = nil
    self.m_pMiniMapScreenSize = self.m_pMapScrollView:getContentSize()
    self.m_pWidthScale = 0
    self.m_pHeithgScale = 0
    self.m_posSchedulerID = nil
    self.m_curSelectedInd = -1
    
end

function CurMapSubUI:ShowObjInMap()
    self:ShowNPCInMiniMap()
    self:ShowMonsterInMiniMap()
    self:ShowGateInMiniMap()
    self:ShowMyHeroInMiniMap()
    self:MyHeroCenterInMiniMap()
end

function CurMapSubUI:ShowMyHeroInMiniMap()
    self.m_pHeroAni = ImodAnim:createWithFileSync("UI/role")
    self.m_pHeroAni:PlayActionRepeat(0)
    local x, y = self.m_pHeroNode:getPosition()
    self.m_pHeroAni:setPosition(cc.p(x*self.m_pWidthScale, y*self.m_pHeightgScale))
    self.m_pHeroAni:setAnchorPoint(cc.p(0.5,0))
    self.m_pMiniMapImg:addChild(self.m_pHeroAni)

    local function tick(dt)
        local x, y = self.m_pHeroNode:getPosition()
        self.m_pHeroAni:setPosition(cc.p(x*self.m_pWidthScale, y*self.m_pHeightgScale))
    end 

    self.m_posSchedulerID = AppDef.Director:getScheduler():scheduleScriptFunc(tick, 0.1, false)
end

function CurMapSubUI:MyHeroCenterInMiniMap()
    local heroPos = cc.p(self.m_pHeroAni:getPosition())
    -- x 方向可见
    local hMapWidth = self.m_pMiniMapSize.width/ 2
    local hMapHeight = self.m_pMiniMapSize.height / 2
    local hScreenWidth = self.m_pMiniMapScreenSize.width / 2
    local hScreenHeight = self.m_pMiniMapScreenSize.height / 2
    self.m_pWidthScale = self.m_pMiniMapSize.width/self.m_pMapSize.width
    self.m_pHeightgScale = self.m_pMiniMapSize.height/self.m_pMapSize.height
    local mapPos = cc.p(0,0)
    if heroPos.x >= hMapWidth and heroPos.x + hScreenWidth <= self.m_pMiniMapSize.width then
        mapPos.x = hMapWidth - heroPos.x
        -- mpScalemap->setPositionX(mpScalemap->getPositionX() - (heroInScalemapPos.x - clipperSize.width/2) - offsetx);
        -- -- 左右可见
        -- setFourArrowShow(2,true,true);
    elseif heroPos.x < hMapWidth then
        mapPos.x = 0
        -- 左看不见
        --setFourArrowShow(2,false,true);
    elseif heroPos.x + hMapWidth > self.m_pMiniMapSize.width then
        mapPos.x = self.m_pMiniMapScreenSize.width - self.m_pMiniMapSize.width
        -- 右看不见
        --setFourArrowShow(2,true,false);
    end

    --y 方向可见
    if heroPos.y >= hScreenHeight and heroPos.y + hScreenHeight <= self.m_pMiniMapSize.height then
        mapPos.y = hScreenHeight - heroPos.y
        --mpScalemap->setPositionY(mpScalemap->getPositionY() - (heroInScalemapPos.y - clipperSize.height/2) - offsety);
        -- 上下可见
        --setFourArrowShow(1,true,true);
    elseif heroPos.y < hScreenHeight then
        mapPos.y = 0
        -- 下看不见
        --setFourArrowShow(1,true,false);
    elseif heroPos.y + hScreenHeight > self.m_pMiniMapSize.height then
        mapPos.y = self.m_pMiniMapScreenSize.height - self.m_pMiniMapSize.height
        -- 上看不见
        --setFourArrowShow(1,false,true);
    end
    self.m_pMapScrollView:setInnerContainerPosition(mapPos)
end

function CurMapSubUI:ShowMonsterInMiniMap()
    local showMonsters = {}
    local curMonster
    local isAdded = false
    local monsterName = nil
    local miniPoint = {x = 0,y = 0}
    local tmpPoint
    local monsterSpr
    for i = 1, #self.m_pMonsterList do
        curMonster = self.m_pMonsterList[i]
        isAdded = false
        monsterName = curMonster:GetName()
        for j = 1,#showMonsters do
            if monsterName == showMonsters[j]:GetName() then
                isAdded = true
                break
            end
        end
        if isAdded == false then
            table.insert(showMonsters, curMonster)
            tmpPoint = curMonster:GetPos()
            miniPoint.x = tmpPoint.x * self.m_pWidthScale
            miniPoint.y = (self.m_pMapSize.height - tmpPoint.y) * self.m_pHeightgScale
            local nameLabel = ccui.Text:create(monsterName,AppDef.FNT_NAMEC,15)
            nameLabel:setAnchorPoint(cc.p(0.5,0.0))
            nameLabel:setPosition(cc.p(miniPoint.x,miniPoint.y+16))
            nameLabel:setColor(cc.c3b(255,24,0))
            self.m_pMiniMapImg:addChild(nameLabel)

            monsterSpr = cc.Sprite:create("UI/monsterNPC.png")
            monsterSpr:setPosition(miniPoint)
            self.m_pMiniMapImg:addChild(monsterSpr)
        end
    end
    local cnt = #self.m_pMonsterList
    for i = 1, #self.m_pMonsterList do
        self.m_pMonsterList[i] = nil
    end
    self.m_pMonsterList = nil
    self.m_pMonsterList = showMonsters
end

function CurMapSubUI:ShowGateInMiniMap()
    local chuansongSpr
    local miniPoint = {x = 0,y = 0}
    for i = 1, #self.m_pGateList do
        miniPoint.x = self.m_pGateList[i].x * self.m_pWidthScale
        miniPoint.y = self.m_pGateList[i].y * self.m_pHeightgScale
        chuansongSpr = cc.Sprite:create("UI/chuansongNPC.png")
        chuansongSpr:setPosition(miniPoint)
        self.m_pMiniMapImg:addChild(chuansongSpr)
    end
end

function CurMapSubUI:ShowNPCInMiniMap()
    local npcSpr = nil
    local tempoint = {x = 0,y = 0}
    local npcPos
    for i = 1,#self.m_pNPCList do
        npcID = self.m_pNPCList[i]:GetId()
        npcPos = self.m_pNPCList[i]:GetPos()
        tempoint.x = npcPos.x * self.m_pWidthScale
        tempoint.y =  (self.m_pMapSize.height - npcPos.y) *self.m_pHeightgScale

        if npcID ==9 or npcID == 10 then-- 药店杂货店
            npcSpr = cc.Sprite:create("UI/shopNPC.png")
            npcSpr:setPosition(tempoint)
            self.m_pMiniMapImg:addChild(npcSpr)
        elseif npcID == 7 then-- 武器店npc
            npcSpr = cc.Sprite:create("UI/wearponNPC.png")
            npcSpr:setPosition(tempoint)
            self.m_pMiniMapImg:addChild(npcSpr)
        elseif npcID == 8 then--防具店npc
            npcSpr = cc.Sprite:create("UI/fangjuNPC.png")
            npcSpr:setPosition(tempoint)
            self.m_pMiniMapImg:addChild(npcSpr)
        elseif npcID == 24 then--竞技npc
            npcSpr = cc.Sprite:create("UI/jingjiNPC.png")
            npcSpr:setPosition(tempoint)
            self.m_pMiniMapImg:addChild(npcSpr)
        elseif npcID == 6 then--钱庄老板npc
            npcSpr = cc.Sprite:create("UI/guanliNPC.png")
            npcSpr:setPosition(tempoint)
            self.m_pMiniMapImg:addChild(npcSpr)
        elseif npcID == 25 then--帮派总管npc
            npcSpr = cc.Sprite:create("UI/zongguanNPC.png")
            npcSpr:setPosition(tempoint)
            self.m_pMiniMapImg:addChild(npcSpr)
        elseif npcID ~=227 then--雪莲屏蔽
            npcState = self.m_pNPCList[i]:GetState()

            if npcState == 0 then--平常状态
                local temptest = cc.Sprite:create("UI/landian.png")
                temptest:setAnchorPoint(cc.p(0.5,0))
                temptest:setPosition(tempoint)
                self.m_pMiniMapImg:addChild(temptest)
            else
                local fileName = ""
                if npcState == 1 then 
                    fileName = "UI/renwuweijie"--可接
                elseif npcState == 2 then
                    fileName = "UI/renwuweiwancheng"--未完成
                elseif npcState == 3 then
                    fileName = "UI/renwuyiwancheng"--已完成 .png
                end
                if string.len(fileName) > 0 then
                    local imod =  ImodAnim:createWithFileSync(fileName)
                    imod:PlayActionRepeat(0)
                    imod:setPosition(tempoint)
                    imod:setAnchorPoint(cc.p(0.5,0))
                    imod:setScale(0.87)
                    self.m_pMiniMapImg:addChild(imod)
                end
            end
        end
    end
end

function CurMapSubUI:ShowCurMap()
    local currMapSid = LRoleDataMgr.MyHeroInfo.mid
       print("当前地图的38"..currMapSid)
    self.m_pMiniMapImg = ccui.ImageView:create("map/map"..currMapSid .. ".png",ccui.TextureResType.localType)
    self.m_pMapScrollView:addChild(self.m_pMiniMapImg)
    self.m_pMiniMapImg:setAnchorPoint(cc.p(0,0))
    self.m_pMiniMapImg:setPosition(cc.p(0,0))
    self.m_pMiniMapSize = self.m_pMiniMapImg:getContentSize()
    self.m_pMapScrollView:setInnerContainerSize(self.m_pMiniMapSize)

    self.m_pMiniMapImg:setTouchEnabled(true)

    
end

function CurMapSubUI:AddTouchEvt()
    local function onTouchEnded(sender, eventType)
        --print("onTouchEnded")
        if eventType ~= ccui.TouchEventType.ended then
            return
        end
        local touchPos = cc.p(self.m_pMiniMapImg:getTouchEndPosition())
        touchPos = self.m_pMiniMapImg:convertToNodeSpace(touchPos)
        touchPos.x = math.floor(touchPos.x/self.m_pWidthScale)
        touchPos.y = self.m_pMapSize.height - math.floor(touchPos.y/self.m_pHeightgScale)
        LGameMsg.m_autoPathMsg:ChangeToStart(LRoleDataMgr.MyHeroInfo.sid,touchPos.x,touchPos.y,-1,0,false,false,nil)
        self:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		self:SendMsg(LGameMsg.m_baseMsgWithOne)
        --print(touchPos.x,touchPos.y)
    end
    self.m_pMiniMapImg:addTouchEventListener(onTouchEnded)
	self:MarkIntaractCObj(self.m_pMiniMapImg)
end

return CurMapSubUI
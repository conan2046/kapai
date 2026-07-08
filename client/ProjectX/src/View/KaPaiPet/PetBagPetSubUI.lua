
local PetBagPetSubUI = LUIBase:New()
PetBagPetSubUI.__index = PetBagPetSubUI
--local this = LTcpSocket
function PetBagPetSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetBagPetSubUI)	
    o:Init()
	return o
end

local EVERYLINENUM = 5

--注册事件
-- -----------------------------------
function PetBagPetSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.ComposionPet,
        LUIPetEvent.PetDataChanged,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetBagPetSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.ComposionPet then
        self:initData()
        self.m_pPetTableView:reloadData()
    elseif msg.msgId == LUIPetEvent.PetDataChanged then
        self:initData()
        self.m_pPetTableView:reloadData()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:setTuJianPrompt()
    end
end

function PetBagPetSubUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongbeibao.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_effect={}-- 效果
    self.m_scheduleId=nil
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData()
    self:initControlUI()
    self:RegisterGuide()
    self:setTuJianPrompt()
    self:PlayLoopEffect()
end

function PetBagPetSubUI:initData( ... )
    
    -- body
    self._ownPetList = Utils:deepCopy(LRoleDataMgr.Pet.petlist)
    -- print("PetBagPetSubUI:initData ==> 111", #self._ownPetList)
    for k,v in pairs(LRoleDataMgr.Equip:GetPackageMap()) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if v.m_type == AppDef.ItemType.PetFrag then
            local pidId = PetkaPaiManager:getPetIdByItem(v)
            local isOwnPet = LRoleDataMgr.Pet:IsOwnPetById(pidId)
            print("pidId =======", pidId, isOwnPet)
            if pidId and pidId > 0 and not isOwnPet then
                local Data = LPetData:New(pidId)
                Data.isFragment = true
                table.insert(self._ownPetList, Data)
            end
        end
    end
    -- print("PetBagPetSubUI:initData ==> 2222", #self._ownPetList)
    self._lastIdx = 0
    self:SortPetList()
end

function PetBagPetSubUI:SortPetList( ... )
    -- body
    local function sortFuc(a, b)
        return PetkaPaiManager:getPetBookCanUpgrade(a) > PetkaPaiManager:getPetBookCanUpgrade(b)
    end
    table.sort(self._ownPetList, sortFuc)
end

-- yingxiongbeibaoUI
function PetBagPetSubUI:initControlUI( ... )
    -- body
    local yingxiongbeibaoUI = self.m_pUILayer:getChildByName("yingxiongbeibaoUI")
    yingxiongbeibaoUI:setTouchEnabled(false)
    self._TableViewPanel = yingxiongbeibaoUI:getChildByName("TableView")

    self._pCell = yingxiongbeibaoUI:getChildByName("ItemCell")
    self._pCell:setAnchorPoint(cc.p(0, 0))
    self._pCell:removeFromParent()
    self._pCell:retain()

    local tujianBtn = yingxiongbeibaoUI:getChildByName("cell")
    tujianBtn:addClickEventListener(handler(self,PetBagPetSubUI.TujianCallBack))
    self.m_guideBtn = tujianBtn
    self.m_pTujianPrompt=tujianBtn:getChildByName("Prompt")
    
    local recycle = yingxiongbeibaoUI:getChildByName("recycle")
    recycle:addClickEventListener(function ( sender )
        -- body
        self:closeUI()
        Utils:OpenFunction(AppDef.EModuleID.EMID_HUISHOU)
    end)
    -- recycle:setVisible(false)

    --初始化列表
    ----------------------------------------------------------------
    self:InitGiftTabView()

    self.m_pPetTableView:reloadData()
end

function PetBagPetSubUI:closeUI()
    print("执行关闭")
  
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetBagMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function PetBagPetSubUI:InitGiftTabView()
    
    local tableView = cc.TableView:create(self._TableViewPanel:getContentSize())
    
    tableView:setContentSize(self._TableViewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._TableViewPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:TableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height + 5
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:PetTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = 0
        if self._ownPetList then
            if #self._ownPetList % EVERYLINENUM == 0 then
                size = #self._ownPetList / EVERYLINENUM
            else
                size = math.floor(#self._ownPetList / EVERYLINENUM) + 1 
            end
        end
        return size
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
    self.m_pPetTableView = tableView
end


--点击选中处理
function PetBagPetSubUI:TableCellTouched(sender, cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    print("TableCellTouched ============ 111111111111111111 >")
end 


function PetBagPetSubUI:PetTableCellAtIndex(sender, idx)

    local function petGridTouched(sender)--选中
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
        print("PetTableCellAtIndex =============>", ind)
        --选中逻辑
        -- if self._lastIdx > 0 then
        --     local lastidx = math.floor((self._lastIdx - 1) / EVERYLINENUM)
        --     local lastSelcetFace = self.m_pPetTableView:cellAtIndex(lastidx)
        --     if lastSelcetFace ~= nil then
        --         local cellChild = lastSelcetFace:getChildByTag(123)
        --         if cellChild ~= nil then
        --             local i = (self._lastIdx - 1) % EVERYLINENUM + 1
        --             local lastItem = cellChild:getChildByTag(i)
        --             if lastItem ~= nil then
        --                 -- lastItem:getChildByName("Choose"):setVisible(false)
        --             end
        --         end
        --     end
        -- end
        -- sender:getChildByName("Choose"):setVisible(true)
        self._lastIdx = ind
        local petData = self._ownPetList[ind]

        if petData == nil then
            return
        end
        if not petData.isFragment then
            local iscanStarUp = PetkaPaiManager:isPetCanStarUp(petData)
            print("PetTableCellAtIndex iscanStarUp ===>", iscanStarUp, petData.id)

            if iscanStarUp then
                -- LRoleDataMgr.tempPetUpStarData = Utils:deepCopy(petData)
                -- dump(LRoleDataMgr.tempPetUpStarData, "pData 3333333333333333 =====>")
                -- LuaNetSendMsg:QueryPetStarUp(petData.id)

                Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_SJSHENGXING)
                Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, petData)
            else
                Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_SJJINENG)
                --临时这样写
                print("PetTableCellAtIndex ================>", petData.fightPos)
                Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, petData)
            end
        else
            local itemData = LRoleDataMgr:GetPItemFromBagById(petData.baseData.itemId)
            if PetkaPaiManager:isPetCanHeCheng(itemData) then
                LuaNetSendMsg:QueryGetPet(11, petData.baseData.itemId)
            else
                -- Utils:ShowItemTips(petData.baseData.itemId)
                LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {petData.id})
                self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
        end
    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        for i=1, EVERYLINENUM do
            -- local giftGrid = self._PCellItem:clone()
            local giftGrid = cellChild:getChildByName("Item"..i)
            --实现选中状态
            giftGrid:setBright(true)
            giftGrid:setSwallowTouches(false)
            local index = idx * EVERYLINENUM + i 
            giftGrid:setTag(index)
            giftGrid:addClickEventListener(petGridTouched) 
            self:MarkIntaractCObj(giftGrid)
            giftGrid:setTouchEnabled(true)
            -- giftGrid:getChildByName("Choose"):setVisible(false)
            -- cellChild:pushBackCustomItem(giftGrid)
            self:showKaPaiInfo(cellChild, giftGrid, index)
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1, EVERYLINENUM do
            local index = idx*EVERYLINENUM+i
            local giftGrid = cellChild:getChildByName("Item"..i)
            giftGrid:setTag(index)
            self:showKaPaiInfo(cellChild, giftGrid, index)
        end

    end
    
    return cell
end

function PetBagPetSubUI:showKaPaiInfo(cellChild, giftGrid, index)
    -- body
    if cellChild == nil then
        return
    end
    -- print("PetBagPetSubUI:showKaPaiInfo ===>", index, #self._ownPetList)
    if index > #self._ownPetList then
        giftGrid:setVisible(false)
        return
    end
    local petData = self._ownPetList[index]
    self:showItemInfo(giftGrid, petData)

end

function PetBagPetSubUI:showItemInfo(giftGrid, petData)
    -- body
    -- dump(petData, "showItemInfo ==============>")
    giftGrid:setVisible(true)

    local Quality = giftGrid:getChildByName("Quality")
    Quality:setTouchEnabled(false)
    -- print("petData.quality", petData.baseData.quality)
    local QualityPath = AppDef:GetQualityColorKuang(petData.baseData.quality)
    print("QualityPath ===>", QualityPath)
    Utils:SafeLoadTexture(Quality, QualityPath, ccui.TextureResType.plistType)

    local name = giftGrid:getChildByName("Name")
    -- print("showItemInfo ========", petData.name)
    name:setString(petData.name.. "   +"..petData.breakLevel)

    local Quality_Level = giftGrid:getChildByName("Quality_Level")
    local lVBgPath = AppDef.ColorDengjiArr[petData.baseData.quality]
    Utils:SafeLoadTexture(Quality_Level, lVBgPath, ccui.TextureResType.plistType)


    local level = giftGrid:getChildByName("Level")
    level:setString(petData.level)

    local shangzhen = giftGrid:getChildByName("shangzhen")
    local showPos = LRoleDataMgr.Pet:GetPetPos(petData.id)
    shangzhen:setVisible(showPos > 0)

    local icon = giftGrid:getChildByName("Panel_icon"):getChildByName("Icon")
    local imagePath = Utils:GetMonsterIconRes(petData.baseData.pic, AppDef.HeadIconResType.Body)
    -- print("imagePath =============>", imagePath)

    if cc.FileUtils:getInstance():isFileExist(imagePath) then
        Utils:SafeLoadTexture(icon, imagePath, ccui.TextureResType.localType)
    end

    local StarList = giftGrid:getChildByName("StarList")

    PetkaPaiManager:ShowStars(StarList, petData.star)

    local toGet = giftGrid:getChildByName("To_get")
    toGet:setVisible(false)
    toGet:setTag(petData.baseData.itemId)
    toGet:addClickEventListener(handler(self, PetBagPetSubUI.heChengEvent))
    local silderbg = giftGrid:getChildByName("slider_bg")
    local Value = silderbg:getChildByName("Value")
    local fragmentBar = silderbg:getChildByName("fragmentBar")
    local synthesis = giftGrid:getChildByName("kehecheng")

    -- toGet:setVisible(petData.isFragment)
    silderbg:setVisible(petData.isFragment)
    local hongdian = giftGrid:getChildByName("Prompt")
    hongdian:setVisible(false)

    local mask = giftGrid:getChildByName("mask")
    mask:setVisible(petData.isFragment)
    synthesis:setVisible(false)
    local itemData = LRoleDataMgr:GetPItemFromBagById(petData.baseData.itemId)
    local keshengxing = giftGrid:getChildByName("keshengxing")
    keshengxing:setVisible(false)

    local effect1 =giftGrid:getChildByName("effect_shenjiangyangcheng_1")
    local effect2 =giftGrid:getChildByName("effect_shenjiangyangcheng_2")
    local shenJiangEffect1 = effect1:getChildByName("effect")
    local shenJiangEffect2 = effect2:getChildByName("effect")
    if shenJiangEffect1==nil then
        shenJiangEffect1=self:CreatEffect("effect_shenjiangyangcheng_1")
        effect1:addChild(shenJiangEffect1)
        shenJiangEffect1:setPosition(cc.p(0,0))
        shenJiangEffect1:setName("effect")
    end
    shenJiangEffect1:setVisible(false)
    if shenJiangEffect2==nil then
        shenJiangEffect2=self:CreatEffect("effect_shenjiangyangcheng_2")
        effect2:addChild(shenJiangEffect2)
        shenJiangEffect2:setPosition(cc.p(0,0))
        shenJiangEffect2:setName("effect")
        table.insert(self.m_effect,shenJiangEffect2)
    end 
    shenJiangEffect2:setVisible(false)  

    if petData.isFragment then
        local hechengConfig = JsonConfig.GetHeChengCfg(AppDef.ItemType.PetFrag, petData.baseData.itemId)
        
        if hechengConfig then
            Value:setString(string.format("%d/%d", itemData.m_num, hechengConfig.item[1][3]))
            fragmentBar:setPercent(itemData.m_num/hechengConfig.item[1][3] * 100)
            local isHecheng = PetkaPaiManager:isPetCanHeCheng(itemData)
            synthesis:setVisible(isHecheng)
            shenJiangEffect1:setVisible(isHecheng)
            shenJiangEffect2:setVisible(isHecheng)
            hongdian:setVisible(isHecheng)
        end
    else
        local iscanStarUp = PetkaPaiManager:isPetCanStarUp(petData)
        --天命激活
        local isCanTMJH = PetkaPaiManager:isPetCanTianMingJH(petData)

        hongdian:setVisible(iscanStarUp or isCanTMJH)
        if iscanStarUp then
            shenJiangEffect1:setVisible(true)
            shenJiangEffect2:setVisible(true)
            keshengxing:setVisible(true)
            mask:setVisible(true)
        end

    end
end

function PetBagPetSubUI:LoopEffect()
    for i=1,#self.m_effect do
        if self.m_effect[i]~=nil and self.m_effect[i]:isVisible()==true then
            self.m_effect[i]:PlayAction(0,1)
        end
    end
end

function PetBagPetSubUI:PlayLoopEffect()
    self.m_scheduleId=Utils:schedule(pNode,handler(self,PetBagPetSubUI.LoopEffect), 3, paused)
end
function PetBagPetSubUI:StopLoopEffect()
    self.m_effect={}
    if self.m_scheduleId~=nil then
        Utils:unschedule(nil,self.m_scheduleId)
        self.m_scheduleId=nil 
    end
    -- body
end


function PetBagPetSubUI:CreatEffect(name)
    local bgAnim = "res2/animation/"..name
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    if name=="effect_shenjiangyangcheng_1" then
        m_pBgAni:PlayActionRepeat(0,1)
    else
        m_pBgAni:PlayAction(0,1)
        
    end    
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
  
end

 


function PetBagPetSubUI:setTuJianPrompt(show)
    local tujian = Utils:GetRedDotState(RedDotDef.ID.ShenJiangTuJian)
    print("tujian =>", tujian)
    self.m_pTujianPrompt:setVisible(tujian)
    -- Prompt
    -- print("PetBagPetSubUI:setTuJianPrompt(show)",show)
end

function PetBagPetSubUI:TujianCallBack(sender)
   
    local funccfg = JsonConfig.m_functionConfig.getDefByID(1090)
    if LRoleDataMgr.MyHeroInfo.level < funccfg.open_condition[1][2] then
        Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2, funccfg.open_condition[1][2]))
        return
    end
    --self:closeUI()
    Utils:OpenFunction(AppDef.EModuleID.EMID_TUJIAN)
end

function PetBagPetSubUI:heChengEvent( sender )
    -- body
    local itemId = sender:getTag()
    Utils:ShowItemTips(itemId)
end

function PetBagPetSubUI:onExit()
    self:StopLoopEffect()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Tujian_2)
    self.m_pUILayer = nil
    self._ownPetList = nil
    self:Destory()
end

function PetBagPetSubUI:RegisterGuide()
    if self.m_guideBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Tujian_2, self.m_guideBtn ,handler(self,PetBagPetSubUI.TujianCallBack), nil, true)
    end
end

return PetBagPetSubUI
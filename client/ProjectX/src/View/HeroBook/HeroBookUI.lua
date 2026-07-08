local HeroBookUI = LUIBase:New()
HeroBookUI.__index = HeroBookUI
--local this = LTcpSocket
function HeroBookUI:New()
    local o = LUIBase:New()
    setmetatable(o,HeroBookUI)    
    o:Init()
    return o
end

--注册事件
-- -----------------------------------
function HeroBookUI:RegistMsgs()
    self.msgIds = 
    {
        LUIKaPaiPetEvent.ShowHeroBookUI,
        LUIKaPaiPetEvent.UpdateHeroBookUI,
		LUIKaPaiPetEvent.BGVisible,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBookUI:ProcessEvent(msg)
    if msg.msgId == LUIKaPaiPetEvent.ShowHeroBookUI then
        self:initTableView()
        self:ShowBookData()
        self:RegisterGuide()
    elseif msg.msgId == LUIKaPaiPetEvent.UpdateHeroBookUI then
        JsonConfig.SortPetBookList()
        self:udapteTableView()
        self:ShowBookData()
	elseif msg.msgId == LUIKaPaiPetEvent.BGVisible then
		LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.BGVisible, false)
		self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function HeroBookUI:Init()
    self:InitMembers()
    self:RegistMsgs()
    self:AddTouchEvt()
    self:RegisterScriptHandler()
    self:InitTuJianTableView()
	
	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_PetArchive_1)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
	
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    LuaNetSendMsg:QueryHeroBook()

end

function HeroBookUI:InitMembers()
    self:CreateUINode("csd/shenjiangyangcheng/yingxiongtujianLayer.csb")
    self.m_bg = self.m_pUILayer
    -- self.m_bg = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtujianLayer.csb")
    -- self.m_bg:setPosition(cc.p(0, 0))
    -- self.m_pUILayer:addChild(self.m_bg)
    local headBg = self.m_bg:getChildByName("tujianUI")
    -- headBg:setSwallowTouches(false)
    local panelBg = headBg:getChildByName("Panel")
    local sliderBg = panelBg:getChildByName("Slider_Bg")
    
    -------------------------------------------------
    self.m_tableView = headBg:getChildByName("TableView")
    self.m_item = headBg:getChildByName("Item")
    self.m_leftBtn = headBg:getChildByName("Button_l")
    self.m_rightBtn = headBg:getChildByName("Button_r")
    self.m_jinduText = panelBg:getChildByName("Text_jindu"):getChildByName("Value")
    self.m_percentBar = sliderBg:getChildByName("LoadingBar")
    self.m_percentText = sliderBg:getChildByName("Value")
    self.m_curValueText = sliderBg:getChildByName("tujianzhi"):getChildByName("Value")
    self.m_allValueText = panelBg:getChildByName("Text_chaju"):getChildByName("Value")
    self.m_tujianBtn = sliderBg:getChildByName("Btn_tujian")
    self.m_searchBtn = panelBg:getChildByName("Btn_tujian")
    self.m_allAttrBtn = panelBg:getChildByName("Btn_shuxing")
    self.m_rankBtn = panelBg:getChildByName("Btn_Rank")
    self.m_nextAttr = {}
    local attrBg = self.m_tujianBtn:getChildByName("Image")
    for i=1,3 do
        self.m_nextAttr[i] = attrBg:getChildByName("Attribute_"..i)
    end
    self.m_item:setVisible(false)
    self.m_jinduText:setTouchEnabled(false)
    self.m_cellHight = (self.m_tableView:getContentSize().height - self.m_item:getContentSize().height) / 2
    self.m_curIdx = 0
    JsonConfig.SortPetBookList()
    self.m_maxHeros = #JsonConfig.m_heroCfg.getList()

end

function HeroBookUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Tujian_Finish)
    self.m_pUILayer = nil
    self.m_tableView = nil
    self.m_item = nil
    self.m_leftBtn = nil
    self.m_rightBtn = nil
    self.m_jinduText = nil
    self.m_percentBar = nil
    self.m_percentText = nil
    self.m_curValueText = nil
    self.m_allValueText = nil
    self.m_tujianBtn = nil
    self.m_nextAttr = nil
    self.m_searchBtn = nil
    self.m_allAttrBtn = nil
    self.m_rankBtn = nil
    self.m_cellHight = nil
    self.m_bookTableView = nil
    self.m_curIdx = nil
    self.m_maxHeros = nil
    self:Destory()
end

function HeroBookUI:AddTouchEvt()
    function LeftBtnCallBack()
        self.m_curIdx = self.m_curIdx - 1
        self.m_curIdx = math.max(self.m_curIdx, 0)
        Utils:MoveToTableIdx(self.m_bookTableView, self.m_item, self.m_curIdx)
        -- self:UpdateScale()
    end
    self.m_leftBtn:addClickEventListener(LeftBtnCallBack)
    self:MarkIntaractCObj(self.m_leftBtn)

    function RightBtnCallBack()
        self.m_curIdx = self.m_curIdx + 1
        self.m_curIdx = math.min(self.m_curIdx, self.m_maxHeros)
        Utils:MoveToTableIdx(self.m_bookTableView, self.m_item, self.m_curIdx)
        -- self:UpdateScale()
    end
    self.m_rightBtn:addClickEventListener(RightBtnCallBack)
    self:MarkIntaractCObj(self.m_rightBtn)

    function TuJianBtnCallBack()
        Utils:InitUI("HeroBook.HeroBookNextAttrUI", AppDef.UIType.PopWindow, self.m_curIdx)
    end
    self.m_tujianBtn:addClickEventListener(TuJianBtnCallBack)
    self:MarkIntaractCObj(self.m_tujianBtn)

    function SearchBtnCallBack()
        Utils:InitUI("HeroBook.HeroBookNextAttrUI", AppDef.UIType.PopWindow, self.m_curIdx)
    end
    -- self.m_searchBtn:addClickEventListener(SearchBtnCallBack)
    -- self:MarkIntaractCObj(self.m_searchBtn)

    function AllAttrBtnCallBack()
        Utils:InitUI("HeroBook.HeroBookAllAttrUI", AppDef.UIType.PopWindow, self.m_curIdx)
    end
    self.m_allAttrBtn:addClickEventListener(AllAttrBtnCallBack)
    self:MarkIntaractCObj(self.m_allAttrBtn)

    function RankBtnCallBack()
        Utils:OpenFunction(AppDef.EModuleID.EMID_RANK_Tujian)
        -- print("==============RankBtnCallBack")
        -- local sucInfo = {}
        -- sucInfo.heroId = 11
        -- sucInfo.star = 2
        -- sucInfo.addScore = 10
        -- sucInfo.booklevel = 2
        -- sucInfo.cardAttr = {}
        -- for i=1, 4 do
        --     local data = {}
        --     data.value = 10
        --     table.insert(sucInfo.cardAttr, data)
        -- end
        -- sucInfo.levelAttr = {}
        -- Utils:InitUI("HeroBook.HeroBookLevelEndUI", AppDef.UIType.PopWindow, sucInfo)
    end
    self.m_rankBtn:addClickEventListener(RankBtnCallBack)
    self:MarkIntaractCObj(self.m_rankBtn)
end

function HeroBookUI:InitTuJianTableView( ... )
    local tableView = cc.TableView:create(self.m_tableView:getContentSize())
    tableView:setContentSize(self.m_tableView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_BOTTOMUP)
    self.m_tableView:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:TableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_item:getContentSize().width
        local height = self.m_item:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return self.m_maxHeros
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_bookTableView = tableView
end

function HeroBookUI:TableCellTouched(sender, cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    local bg = cellChild:getChildByName("Item")
    bg:setScale(1)
    local cell = self.m_bookTableView:cellAtIndex(self.m_curIdx)
    if cell ~= nil and self.m_curIdx ~= ind then
        local perCell = cell:getChildByTag(123)
        perCell:getChildByName("Item"):setScale(0.8)
    end
    local heroId = bg:getChildByName("Btn_shengji"):getTag()
    self.m_curIdx = ind
    -- 神将信息界面
	local book = LRoleDataMgr.m_book.bookStar[heroId]
	if book ~= nil then
		Utils:InitUI("KaPaiPet.PetKaPaiMainUI", AppDef.UIType.FirstClassLayer, 1)
		local curPet = LRoleDataMgr.Pet:GetPetById(heroId)
		Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, curPet)
		return
	end

	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {heroId})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end 
function HeroBookUI:SetEffect()
    local bgAnim = "res2/animation/effect_shenjiangyangcheng_3"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end

function HeroBookUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_item:clone()

        cellChild:setTag(123)
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setPosition(cc.p(0, self.m_cellHight))
        cellChild:setVisible(true)
        cellChild:setSwallowTouches(false)
        local parent =cellChild:findChildByName("Item/Btn_shengji") 
        local effcet = self:SetEffect()
        effcet:setName("effcet") 
        parent:addChild(effcet)
        --effcet:setAnchorPoint(cc.p(0.5,0.5))
        effcet:setPosition(cc.p(parent:getContentSize().width/2,parent:getContentSize().height/2))

        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:UpdateItem(cellChild, idx + 1)
    end
    return cell
end

function HeroBookUI:CheckIsUpGrade(curStar,needStar,needItemId,needItemNum)
    if curStar<needStar then
        return false
    end
    if needItemNum>LRoleDataMgr.Equip:CountItemNumById(needItemId) then
        return false 
    end
    return true

end
function HeroBookUI:SetEffectIsVisiable(node,pid)
    local petData = LRoleDataMgr.Pet:GetPetById(pid)
    local configPet = JsonConfig.m_heroCfg.getDefByID(pid)
    local bookValue = 0
    local id = 0
    if petData~= nil then
        local book = LRoleDataMgr.m_book.bookStar[pid]
        if book == nil then
            node:setVisible(true) 
        else
            local level =book.star+1
            if level>#JsonConfig.m_star.getList() then
                return
            end
            local starCfg = JsonConfig.m_star.getDefByID(level)
            for i=1,#starCfg.handbook_cost do
                local value = starCfg.handbook_cost[i]
                if value[1] == configPet.quality then
                    id=value[2]
                    bookValue = value[3]
                    break
                end
            end
            node:setVisible(self:CheckIsUpGrade(petData.star,level,id,bookValue))
        end
        
    else
        node:setVisible(false)
    end
end


function HeroBookUI:UpdateItem(cellChild, idx)
    local cfg = JsonConfig.m_heroCfg.getDefByIndex(idx)
    local bg = cellChild:getChildByName("Item")
    local imgBg = bg:getChildByName("Panel") --:getChildByName("Icon"):setString(cfg.name)
    local icon = imgBg:getChildByName("Icon")
    -- icon:setContentSize(imgBg:getContentSize())
    icon:setTouchEnabled(true)
    icon:setSwallowTouches(false)
    local imagePath = Utils:GetMonsterIconRes(cfg.pic, AppDef.HeadIconResType.Body)
    if not cc.FileUtils:getInstance():isFileExist(imagePath) then
        imagePath = "res2/Monster_Bust/1.png"
    end
    Utils:SafeLoadTexture(icon, imagePath, ccui.TextureResType.localType)

    bg:findChildByName("Namebg/Name"):setString(cfg.name)
    local color = AppDef:GetPetQualityColor(cfg.quality);
    bg:findChildByName("Namebg/Name"):setTextColor(color);

    local btn = bg:getChildByName("Btn_shengji")
    btn:setTag(cfg.id)
    bg:setScale(0.8)
    local curStar = LRoleDataMgr.m_book.bookStar[cfg.id]
    local level = 1
    local bookValue = 0
    if curStar ~= nil then
        level = curStar.star
        bookValue = curStar.score
    else
    local starCfg = JsonConfig.m_star.getDefByID(level)
        for i=1,#starCfg.handbook_value do
            local value = starCfg.handbook_value[i]
            if value[1] == cfg.quality then
                bookValue = value[2]
                break
            end
        end
    end

    bg:getChildByName("Level"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK2, level))
    bg:getChildByName("Value"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK4, bookValue))
    btn:addClickEventListener(handler(self,HeroBookUI.JiHuoCallBack))
    self:MarkIntaractCObj(btn)

    local function setTouchEnabled(btn, isEnabled, str)
        btn:setBright(isEnabled)
        btn:setTouchEnabled(isEnabled)
        if isEnabled then
            btn:getChildByName("Text_1"):setVisible(true)
            btn:getChildByName("Text_1"):setString(str)
            btn:getChildByName("Text_2"):setVisible(false)
        else
            btn:getChildByName("Text_2"):setVisible(true)
            btn:getChildByName("Text_2"):setString(str)
            btn:getChildByName("Text_1"):setVisible(false)
        end
    end

    local petData = LRoleDataMgr.Pet:GetPetById(cfg.id)
    if petData~= nil then
        local book = LRoleDataMgr.m_book.bookStar[cfg.id]
        if book == nil then
            setTouchEnabled(btn, true, "激活")
            btn.jihuo = true
        else
            setTouchEnabled(btn, true, "升级")
            btn.jihuo = false
        end
    else
        setTouchEnabled(btn, false, "激活")
        btn:setTouchEnabled(true)
        btn.jihuo = true
    end

    local effcet = btn:getChildByName("effcet")
    self:SetEffectIsVisiable(effcet,cfg.id)
end

function HeroBookUI:UpdateScale()
    local scale = {0.8, 0.8, 0.8, 1, 1.1, 1, 0.8, 0.8, 0.8}
    local calcIdx = self.m_curIdx - 4
    for i=1, 10 do
        local cell = self.m_bookTableView:cellAtIndex(calcIdx + i)
        if cell ~= nil then
            cell:getChildByTag(123):getChildByName("Item"):setScale(scale[i])
        end
    end
end

function HeroBookUI:RegisterScriptHandler( ... )
    local function onNodeEvent(event)
        if "exit" == event then
            Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function closeCallback()
        Utils:DeleteUI("HeroBook.HeroBookUI")
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.TuJian)
end

function HeroBookUI:udapteTableView( ... )
    -- body
    local offset = self.m_bookTableView:getContentOffset()
    self.m_bookTableView:reloadData()
    self.m_bookTableView:setContentOffset(offset) 
end

function HeroBookUI:initTableView( ... )
    -- body
    self.m_bookTableView:reloadData()
end

function HeroBookUI:ShowBookData( ... )

    local queryLevel = LRoleDataMgr.m_book.curLevel
    if queryLevel < #JsonConfig.m_heroBook.getList() then
        queryLevel = queryLevel + 1
    end
    local bookCfg = JsonConfig.m_heroBook.getDefByID(queryLevel)
     --dump(LRoleDataMgr.m_book,"LRoleDataMgr.m_book===========>")
    if bookCfg ~= nil then
        local str = string.format(GUITips.RSI_ZQX_HERO_BOOK5, LRoleDataMgr.m_book.curScore, bookCfg.handbook_value)
        self.m_allValueText:setString(str)
        self.m_percentBar:setPercent(LRoleDataMgr.m_book.curScore*100/bookCfg.handbook_value)
        self.m_percentText:setString(str)
        for i=1,#bookCfg.attr do
            local attr = bookCfg.attr[i]
            if self.m_nextAttr[i] ~= nil then
                self.m_nextAttr[i]:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK6,Utils:getAttrNameAndValue(attr[1],attr[2])))
            end
        end
        for i=1,#self.m_nextAttr do
            if i>#bookCfg.attr then
                self.m_nextAttr[i]:setVisible(false)
            end
            
        end
    end
    self.m_jinduText:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5, #LRoleDataMgr.Pet.petlist, self.m_maxHeros))
    self.m_curValueText:setString(tostring(LRoleDataMgr.m_book.curScore))
end

function HeroBookUI:JiHuoCallBack(sender)
    local heroId = sender:getTag()
    if sender.jihuo then
        if LRoleDataMgr.Pet:GetPetById(heroId) == nil then
            Utils:ShowScrollTips(GUITips.RSI_ZQX_HERO_BOOK13,true)
        else
            LuaNetSendMsg:LevelUpHeroBook(heroId)
        end
    else
        
        local book = LRoleDataMgr.m_book.bookStar[heroId]
        if book and book.star >=#JsonConfig.m_star.getList() then
            Utils:ShowScrollTips(GUITips.RSI_ZQX_HERO_BOOK16,true)
            return
        end
        Utils:InitUI("HeroBook.HeroBookSingleUI", AppDef.UIType.PopWindow, heroId)
    end
end

function HeroBookUI:RegisterGuide()
    local cell = self.m_bookTableView:cellAtIndex(0)
    if cell ~= nil then
        local cellChild = cell:getChildByTag(123)
        if cellChild ~= nil then
            self.m_guideBtn = cellChild:findChildByName("Item/Btn_shengji")
        end
    end
    if self.m_guideBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Tujian_Finish, self.m_guideBtn , function()
            self:JiHuoCallBack(self.m_guideBtn)
        end, nil, true)
    end
end

return HeroBookUI
local BiaoBaiEffect = require("View.Social.xianhuapar_biaobai")
local HehuaEffect = require("View.Social.xianhuapar_hehua")
local GiveGiftIUI = LUIBase:New()
GiveGiftIUI.__index = GiveGiftIUI
--local this = LTcpSocket
function GiveGiftIUI:New()
	local o = LUIBase:New()
	setmetatable(o,GiveGiftIUI)	
    o:Init()
	return o
end


function GiveGiftIUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/GiveGiftsLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:initData();
    self:initUI();

    self:initLeftView();
    self:initRightView();

    --请求鲜花商店信息
    LuaNetSendMsg:QueryXianHuaInfo(7)
end


--[[
注册消息
]]
function GiveGiftIUI:RegistMsgs()
    self.msgIds = 
    {
         LUIGiveGiftEvent.updateXianHuaShop,
         LUIGiveGiftEvent.receiveXianHuaFullScreen,
         LUIGiveGiftEvent.buyXHSuccess,
         LUIGiveGiftEvent.updateAfterGiveUI,
         LUIGiveGiftEvent.updateUIAfterSendGift,
    }
    self:RegistSelf(self,self.msgIds)
end

function GiveGiftIUI:ProcessEvent(msg)
    if msg:GetMsgId() == LUIGiveGiftEvent.updateXianHuaShop then
        self:updateGiftTable(msg.value)
    end

    if msg:GetMsgId() == LUIGiveGiftEvent.receiveXianHuaFullScreen then
        
    end

    if  msg:GetMsgId() == LUIGiveGiftEvent.buyXHSuccess then
--        LRoleDataMgr.Equip:IsPackFull()
        local num = LRoleDataMgr.Equip:CountItemNumById(msg.value.itemId)
--        print("GiveGiftIUI num", num)
        if num > 0 then
            LuaNetSendMsg:QueryGiveXianHua(4, msg.value.itemId, msg.value.buy_num, self._selectId)
        end
    end

    if msg:GetMsgId() == LUIGiveGiftEvent.updateAfterGiveUI then
        --更新
--        self.m_pGiftTableView:reloadData()
        self:updateAfterGiveUI(msg.value)
    elseif LUIGiveGiftEvent.updateUIAfterSendGift then
        self:updateUIAfterSendGift(msg.value)
    end
end

function GiveGiftIUI:initData()    
    self._friendsData = Utils:deepCopy(LRoleDataMgr.Social:GetFriendData())
--    self._selectId = self._friendsData[1].id
    self._selectId = -1 
    self._lastIdx = -1
    self._curSelNum = 0
    self._curSelItem = nil

    if #self._friendsData <= 0 then
        return
    end

    local idx = LRoleDataMgr.Social:FindFriend(0, self._friendsData);
    table.remove(self._friendsData, idx)

    if #self._friendsData <= 0 then
        return
    end
end

function updateFriendTable()
    self:initData();
--    self.m_pFriendTableView:reloadData()
end

function GiveGiftIUI:initUI()

    -- local function closeCallback()
    --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Social.GiveGiftIUI")
    --     self:SendMsg(LGameMsg.m_initUIMsg)
    -- end
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local panel = self.m_pUILayer:getChildByName("Panel")
    local WhisperBg = panel:getChildByName("FriendsList"):getChildByName("WhisperBg")
    self._friendView = WhisperBg:getChildByName("WhisperTableView")
    self._pFriendCell = self._friendView:getChildByName("WhisperBtn_0")
    self._pFriendCell:setVisible(false)


    local btn = panel:getChildByName("FriendsList"):getChildByName("Btn1")
    btn:setBright(false)
    local btnName1 = btn:getChildByName("BtnName_1") 
    btnName1:setVisible(true)

    local btnName2 = btn:getChildByName("BtnName_2")
    btnName2:setVisible(false)

    local chatScreen = panel:getChildByName("ChatScreem")
    self._list = chatScreen:getChildByName("List")
    self._rowCell = chatScreen:getChildByName("Item")
    self._rowCell:setVisible(false)

    self.itemCell = chatScreen:getChildByName("ChatScreem")

end

function GiveGiftIUI:initLeftView()
    self:initFriendTableView()
    self.m_pFriendTableView:reloadData()
end

function GiveGiftIUI:initFriendTableView()
    local tableView = cc.TableView:create(self._friendView:getContentSize())
    
    tableView:setContentSize(self._friendView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._friendView:addChild(tableView)
    

    local function tableCellTouched(sender,cell)
        self:FriendTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pFriendCell:getContentSize().width
        local height = self._pFriendCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:FriendTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = #self._friendsData;
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

    self.m_pFriendTableView = tableView
end

function GiveGiftIUI:FriendTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local oneData = self._friendsData[ind + 1]
    self._selectId = oneData.id

    local cellChild = cell:getChildByTag(123)

    local selectRoleID = LRoleDataMgr.Social:GetFriendIdByIndex(ind)
    if  selectRoleID ~= self._ChatId then
        cellChild:setBright(false);
        if self._lastSelCell ~= nil then
            self._lastSelCell:setBright(true)
        end
     end

    self._ChatId = selectRoleID
    self._lastSelCell = cellChild;
    
end 

function GiveGiftIUI:FriendTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pFriendCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(cellChild:getContentSize().width / 2, cellChild:getContentSize().height / 2))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)         
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowFriendCellInfo(cellChild, idx)
    return cell
end

function GiveGiftIUI:ShowFriendCellInfo(cellChild, idx)

    local oneData = self._friendsData[idx + 1]
    local friendId = oneData.id

    local function OnCheckBtnButtonClick(sender)
        if self.m_isDragging then
            return
        end

        local function QueryFriendInfoCallback()
           LuaNetSendMsg:QueryOtherPlayer(friendId)
        end
    
        local function InvateTeamCallback()
            LuaNetSendMsg:QueryTeamInvite(friendId)
        end

        local function InvateBpCallback()
            LuaNetSendMsg:QueryFactionInvite(friendId)
        end

        -- local function getGiftCallback()
            
        -- end

        -- local function DelFriendCallback()
        --     LuaNetSendMsg:QuertDelFriend(friendId)
        --     LRoleDataMgr.Social:delFriend(friendId);
        --     self:delFriend(friendId)
        --     self.m_pFriendTableView:reloadData();
        -- end

        local function SendMailCallback()
           LGameMsg.m_baseMsgWithOne:Change(LUIMailEvent.TurnWriteMail, oneData.name)
           self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end

        local btndata = {}
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
        btndata.pos = worldPos;

        table.insert(btndata,{GUITips.UI_FRIEND_QUERY,QueryFriendInfoCallback})
        table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM,InvateTeamCallback})
        table.insert(btndata,{GUITips.UI_FRIEND_INVATEBP,InvateBpCallback})
--        table.insert(btndata,{GUITips.UI_FRIEND_GIFT,getGiftCallback})
--        table.insert(btndata,{GUITips.UI_TEAM_DELFRIEND,DelFriendCallback})
        table.insert(btndata,{GUITips.UI_TEAM_SENDMAIL,SendMailCallback})
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

    end
    

    if cellChild ~= nil then

        local oneData = self._friendsData[idx + 1]
        if oneData ~= nil then
            
            cellChild:setBright(true)


            local imageIcon = cellChild:getChildByName("Image")

            local strHeadImage = AppDef:GetHeroPicFileName(oneData.prof, AppDef.HeadType.HERO_IMAGE_HEAD);

            --GM头像
            if oneData.id == 0 then
                strHeadImage = "res2/Monster_Bust/302_tou.png"
            end

            imageIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)

            local Offline = cellChild:getChildByName("Offline")
            local isonline = oneData.mapId > 0 or oneData.id == 0
            Offline:setVisible(not isonline)

            local lv = cellChild:getChildByName("LevelNum")
            lv:setString(GUITips.Item_Info_Lv .. oneData.level)
            lv:setVisible(true)

            local name = cellChild:getChildByName("Name")
            name:setString(oneData.name)
            
            local btn = cellChild:getChildByName("CheckBtn")
    --        btn:setTag(idx + 1)
            btn:addClickEventListener(OnCheckBtnButtonClick)
			self:MarkIntaractCObj(btn)
            btn:ignoreContentAdaptWithSize(true)
            btn:setVisible(true)

            local pro = cellChild:getChildByName("Career")
            pro:setString(oneData.profession)
            pro:setVisible(true)

            local GoodFeel = cellChild:getChildByName("GoodFeel")

            local optValTemp = LRoleDataMgr.Social:getQingMiDu(oneData.qingMiDu)
            local str = string.format("res/UI/ui_shejiao/friend_chenghao_%d.png", optValTemp) 
            GoodFeel:loadTexture(str, ccui.TextureResType.plistType)

            if(oneData.id == 0) then
                btn:setVisible(false)
                pro:setVisible(false)
                lv:setVisible(false);
                GoodFeel:setVisible(false)
                 --GM的头像资源headimg_system.png
--                local posY = name:getPositionY()
--                name:setPositionY(posY - 30);
            end
        end

    end
end

function GiveGiftIUI:delFriend(id)
    -- body
    local idx = LRoleDataMgr.Social:FindFriend(id, self._friendsData)
    if idx < 0 then
        return
    end

    table.remove(self._friendsData, idx)
end

function GiveGiftIUI:findXHIndex(id)
    -- body
    for i = 1, #self._giftData do
        if self._giftData[i].id == id then
            return i
        end
    end
    return -1
end


function GiveGiftIUI:getQingMiDu(value)
    -- body
    if value <= 500 then
        return 3
    elseif value <= 1000 then
        return 4
    elseif value <= 5000 then
        return 5
    else
        return 6
    end
end

function GiveGiftIUI:initRightView()
    self:InitGiftTabView()
--    self.m_pGiftTableView:reloadData()
end

function GiveGiftIUI:updateGiftTable(value)
    self._giftData = value.FlowerShopData
    self._myGiftData = value.myList
    self.m_pGiftTableView:reloadData()
end

function GiveGiftIUI:flowerIsOwn(id)
    local num = LRoleDataMgr.Equip:CountItemNumById(id)
    return num > 0
end

function GiveGiftIUI:InitGiftTabView()
    
    local tableView = cc.TableView:create(self._list:getContentSize())
    
    tableView:setContentSize(self._list:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._list:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:GiftTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._rowCell:getContentSize().width
        local height = self._rowCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:GiftTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = 0
        if self._giftData then
            if #self._giftData % 3 == 0 then
                size = #self._giftData / 3
            else
                size = math.floor(#self._giftData / 3) + 1 
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
    self.m_pGiftTableView = tableView
end


--点击选中处理
function GiveGiftIUI:GiftTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
end 


function GiveGiftIUI:GiftTableCellAtIndex(sender, idx)

    local function GiftGridTouched(sender)--选中
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag() 
        if self._lastIdx > 0 then
            local lastidx = math.floor((self._lastIdx - 1) / 3)
            local lastSelcetFace = self.m_pGiftTableView:cellAtIndex(lastidx)
            if lastSelcetFace ~= nil then
                local cellChild = lastSelcetFace:getChildByTag(123)
                if cellChild ~= nil then
                    local i = (self._lastIdx - 1) % 3 + 1
                    local lastItem = cellChild:getChildByName("Item"..i)
                    if lastItem ~= nil then
                        lastItem:getChildByName("Choose"):setVisible(false)
                    end
                end
            end
        end

        local  data = self._giftData[ind]
        if data.type == 2 then
            return
        end
         
        sender:getChildByName("Choose"):setVisible(true)
        self._lastIdx = ind;
    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._rowCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i=1,3 do
            local giftGrid = cellChild:getChildByName("Item"..i)
            --实现选中状态
            giftGrid:setBright(true)
            giftGrid:setSwallowTouches(false)
            local index = idx*3+i
            giftGrid:setTag(index)
            giftGrid:addClickEventListener(GiftGridTouched) 
			self:MarkIntaractCObj(giftGrid)
            giftGrid:setTouchEnabled(true)
            giftGrid:getChildByName("Choose"):setVisible(false)
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1,3 do
            local giftGrid = cellChild:getChildByName("Item"..i)
            local index = idx*3+i
            giftGrid:setTag(index)
            giftGrid:addClickEventListener(GiftGridTouched)
			self:MarkIntaractCObj(giftGrid)
            giftGrid:getChildByName("Choose"):setVisible(false)
        end

    end
    self:ShowFaceCellInfo(cellChild, idx)
    return cell
end


function GiveGiftIUI:ShowFaceCellInfo(cellChild, idx)
    if cellChild ~= nil then
        for i=1,3 do
            local index = idx * 3 + i
            if index > #self._giftData then
                cellChild:getChildByName("Item".. i):setVisible(false)
                return
            end

            local  data = self._giftData[index]
            dump(data, "data ==>")
            local item = LItemMgr:getItem(data.id)
            if item == nil then
                return
            end
            local frienCell = cellChild:getChildByName("Item"..i)
            local name = frienCell:getChildByName("Name")
            name:setString(item:Getm_name())

            local icon = frienCell:getChildByName("bg_icon")

            local sprIcon = cc.Sprite:create(string.format("item/equip%d.png", item:Getm_pic()))
            icon:addChild(sprIcon)
            sprIcon:setAnchorPoint(cc.p(0.5, 0.5))
            sprIcon:setPosition(cc.p(icon:getContentSize().width / 2, icon:getContentSize().height / 2))

--            icon:loadTexture(string.format("item/equip%d.png", item:Getm_pic()), ccui.TextureResType.localType)

            local qinmi = frienCell:getChildByName("Text_1")
            local meili = frienCell:getChildByName("Text_2")

            local sendBtn = frienCell:getChildByName("BuyBtn")
            local  function sendBtnEvent( sender )
                -- body
                local id = sender:getTag();
                
                LGameMsg.m_baseMsgWithOne:Change(LUIGiveGiftEvent.xianHuaRecordNeedRefresh)
                self:SendMsg(LGameMsg.m_baseMsgWithOne)

                if self._selectId == nil or self._selectId <= 0 then
                    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_CHENGHAO_GET_64)
                    self:SendMsg(LGameMsg.m_scrollTipsMsg)
                    return
                end

                if self:flowerIsOwn(data.id) then
                    LuaNetSendMsg:QueryGiveXianHua(4, id, 1, self._selectId)
                else
                    LuaNetSendMsg:QuerybugXianHua(2, id, 1)
                end

            end
            sendBtn:addClickEventListener(sendBtnEvent)
			self:MarkIntaractCObj(sendBtn)
            sendBtn:setTag(data.id)

            local  BtnName = sendBtn:getChildByName("BtnName")
            local  btnIcon = sendBtn:getChildByName("Icon")
            if data.buy_type == 3 then
                btnIcon:loadTexture("res/UI/ui_common/ui_icon_jinbi.png", ccui.TextureResType.plistType)
            end

            --价钱
            local  value = btnIcon:getChildByName("Value")
            value:setString(data.price)

            local PreviewBtn = frienCell:getChildByName("PreviewBtn")
            local  function previewEvent( sender )
                if data.type ~= 1 then
                    return
                end
                if data.id == 2989 then
                    BiaoBaiEffect:Init(self.m_pUILayer)
                    BiaoBaiEffect:playAction()
                elseif data.id == 2990 then
                    HehuaEffect:Init(self.m_pUILayer)
                    HehuaEffect:playAction()
                else
                    LRoleDataMgr.Social:createEffectAnim(data.id)
                end
                
            end
            PreviewBtn:addClickEventListener(previewEvent)
			self:MarkIntaractCObj(PreviewBtn)
            if self:flowerIsOwn(data.id) then
                BtnName:setVisible(true)
                btnIcon:setVisible(false)
                value:setVisible(false)
            else
                BtnName:setVisible(false)
                btnIcon:setVisible(true)
                value:setVisible(true)
            end

            -----------------------------
            --彩带
            local itemHd = frienCell:getChildByName("Item_hd")
            local buyBtn_2 = frienCell:getChildByName("BuyBtn_2")
            local bg_num = itemHd:getChildByName("bg_Num")
            local textButton = bg_num:getChildByName("TextButton")
            
            if data.type == 1 then
                qinmi:setString( string.format(GUITips.RSI_XIANHUA_ADDQINLI, data.qinmi))
                meili:setString(string.format(GUITips.RSI_XIANHUA_ADDMEILI, data.meili))
                qinmi:setVisible(true)
                meili:setVisible(true)
                itemHd:setVisible(false)
                sendBtn:setVisible(true)
                buyBtn_2:setVisible(false)
                PreviewBtn:setVisible(true)
            else
                itemHd:setVisible(true)
                qinmi:setVisible(false)
                meili:setVisible(true)
                meili:setString(string.format(GUITips.RSI_NATIONALGIFT_TIPS2, data.sendScore))
                sendBtn:setVisible(false)
                buyBtn_2:setVisible(true)
                PreviewBtn:setVisible(false)

                print("_curSelNum ==>", self._curSelNum, data.num)
                textButton:setTitleText(string.format("%d/%d", self._curSelNum, data.num))
                textButton:addClickEventListener(function( sender )
                    -- body
                    local function NumInputCallback(num)
                        if num == 0 then
                           return
                        end
                        if num > data.num then
                            num = data.num
                        end
                        self._curSelNum = num
                        textButton:setTitleText(string.format("%d/%d", self._curSelNum, data.num))
                    end
                    print("addClickEventListener ===>")
                    if data.num > 1  then
                        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowNumInputUI, {data.num, NumInputCallback})
                        self:SendMsg(LGameMsg.m_baseMsgWithOne)
                    end
                end)
                local btn_Minus = bg_num:getChildByName("btn_Minus")
                btn_Minus:addClickEventListener(function( sender )
                    -- body 
                    if self._curSelNum < 1 then
                        return
                    end
                    self._curSelNum = self._curSelNum - 1
                    textButton:setTitleText(string.format("%d/%d", self._curSelNum, data.num))
                end)
                local btn_Plus = bg_num:getChildByName("btn_Plus")
                btn_Plus:addClickEventListener(function( sender )
                    -- body
                    print("self._curSelNum =", self._curSelNum, data.num)
                    if self._curSelNum >= data.num then
                        return
                    end
                    self._curSelNum = self._curSelNum + 1
                    textButton:setTitleText(string.format("%d/%d", self._curSelNum, data.num))
                end)
                
                buyBtn_2:addClickEventListener(function( sender )
                    -- 赠送鲜花
                    if self._selectId == nil or self._selectId <= 0 then
                        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_CHENGHAO_GET_64)
                        self:SendMsg(LGameMsg.m_scrollTipsMsg)
                        return
                    end

                    self._curSelItem = textButton
                    if self._curSelNum > 0 then
                        LuaNetSendMsg:QueryGiveXianHua(8, data.id, self._curSelNum, self._selectId)
                    end
                end)
            end
        end
        
    end
end

function GiveGiftIUI:updateAfterGiveUI(id)
    -- body
    local index = self:findXHIndex(id)
    if index <= 0 then
        return
    end

    local ind
    if index % 3 == 0 then
        ind = index / 3
    else
        ind = math.floor(index / 3) + 1 
    end

    local cell = self.m_pGiftTableView:cellAtIndex(ind - 1)
    if cell == nil then
        return
    end 

    cellChild = cell:getChildByTag(123)


    if cellChild ~= nil then

        local idx = index % 3
        if idx == 0 then
            idx = 3
        end

        local frienCell = cellChild:getChildByName("Item"..idx)
        local sendBtn = frienCell:getChildByName("BuyBtn")
        local  BtnName = sendBtn:getChildByName("BtnName")
        local  btnIcon = sendBtn:getChildByName("Icon")
        local  value = btnIcon:getChildByName("Value")

        local num = LRoleDataMgr.Equip:CountItemNumById(id)
        if num > 0 then
            BtnName:setVisible(true)
            btnIcon:setVisible(false)
            value:setVisible(false)
        else
            BtnName:setVisible(false)
            btnIcon:setVisible(true)
            value:setVisible(true)
        end
    end
end

function GiveGiftIUI:updateUIAfterSendGift( data )
    -- body
    local totalNum = self:updateData(data.id, data.num)
    if self._curSelItem == nil then
        return
    end
    self._curSelItem:setTitleText(string.format("%d/%d", self._curSelNum, totalNum))
end

function GiveGiftIUI:updateData( id, num )
    -- body
    for i=1, #self._giftData do
        if self._giftData[i].id == id then
            self._giftData[i].num = self._giftData[i].num - num
            return self._giftData[i].num
        end
    end
    return 0
end

function GiveGiftIUI:onExit()
    self.m_pUILayer = nil
    self.m_pGiftTableView = nil
    self._list = nil
    self._rowCell = nil
    self._friendView = nil
    self._pFriendCell = nil
    Utils:FreeTable(self._friendsData)
    self._selectId = nil
    self.itemCell = nil
    self._curSelItem = nil
    self:Destory()
end

return GiveGiftIUI
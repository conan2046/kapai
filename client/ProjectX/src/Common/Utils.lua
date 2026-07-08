Utils = {}

function Utils:dump(t)
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function Utils:Debug(...)
    release_print(debug.traceback())
    --dump({...})
end

function Utils:point2size(point)
    return cc.size(point.x, point.y)
end

function Utils:size2point(size)
    return cc.p(size.width, size.height)
end

function Utils:serialize(obj)
    local lua = ""
    local t = type(obj)
    if t == "number" then
        lua = lua .. obj
    elseif t == "boolean" then
        lua = lua .. tostring(obj)
    elseif t == "string" then
        lua = lua .. string.format("%q", obj)
    elseif t == "table" then
        lua = lua .. "{\n"
    for k, v in pairs(obj) do
        lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"
    end
    local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
        for k, v in pairs(metatable.__index) do
            lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"
        end
    end
        lua = lua .. "}"
    elseif t == "nil" then
        return nil
    else
        error("can not serialize a " .. t .. " type.")
    end
    return lua
end
 
function Utils:unserialize(lua)
    local t = type(lua)
    print("t",t)
    if t == "nil" or lua == "" then
        return nil
    elseif t == "number" or t == "string" or t == "boolean" then
        lua = tostring(lua)
    else
        error("can not unserialize a " .. t .. " type.")
    end
    lua = "return " .. lua
    local func = loadstring(lua)
    -- --dump(func,"func")
    if func == nil then
        return nil
    end
    return func()
end


function Utils:concatTable(t1, ...)
    local function _concatTwoTable(one, two)
        if type(one) == "table" and type(two) == "table" then
            local ret = one
            for i,v in ipairs(two) do
                table.insert(ret, v)
            end
        end
    end
    local list = {...}
    for i=1,#list do
        _concatTwoTable(t1, list[i])
    end
    return t1
end

function Utils:getSpace( num )
    local temp = {}
    for i=1,num do
        table.insert(temp, " ")
    end
    return table.concat(temp)
end

function Utils:getFormatTime(sec)
    return math.floor(sec/3600), math.floor(math.fmod(sec/60,60)), math.fmod(sec,60)
end


--获取当天还剩余秒数
function Utils:getTodayLeftSec( ... )
    -- body
    local sYear = tonumber(os.date("%Y", LDataConstMgr.m_serverTime))
    local sMonth = tonumber(os.date("%m", LDataConstMgr.m_serverTime))
    local SDay = tonumber(os.date("%d", LDataConstMgr.m_serverTime))
--    print("SYear", sYear, sMonth, SDay)
    local todayEndTime = os.time({year = sYear, month = sMonth, day = SDay, hour = 23, min = 59, sec = 59})

    local lero_time = todayEndTime - LDataConstMgr.m_serverTime
    return lero_time
end

function Utils:containValue(tb, value, isKey)
    for k,v in pairs(tb) do
        if isKey then
            if k == value then
                return true
            end
        else
            if v == value then
                return true
            end
        end
    end
    return false
end

function Utils:three(conditon, ret1, ret2)
    return (Utils:ToBool(conditon) and {ret1} or {ret2})[1]
end

function Utils:deepCopy(object)
    local SearchTable = {}

    local function Func(object)
        if type(object) ~= "table" then
            return object
        end
        local NewTable = {}
        SearchTable[object] = NewTable
        for k,v in pairs(object) do
            NewTable[Func(k)] = Func(v)
        end

        return setmetatable(NewTable, getmetatable(object))
    end

    return Func(object)
end

-- cfg:
-- {
--     tbPanel, --TableView父节点
--     cellSizeForTable,
--     tableCellAtIndex,
--     tableCellTouched,
--     scrollViewDidScroll,
--     numberOfCellsInTableView,
--     direction, --方向
--     bounceable,
--     verticalFillOrder,
-- }
function Utils:createTableView(cfg)
    local tableView = cc.TableView:create(cfg.tbPanel:getContentSize())
    tableView:setDirection(cfg.direction or cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(cfg.bounceable or true)
    tableView:setVerticalFillOrder(cfg.verticalFillOrder or cc.TABLEVIEW_FILL_TOPDOWN)
    cfg.tbPanel:addChild(tableView)

    if cfg.tableCellTouched then --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
        tableView:registerScriptHandler(cfg.tableCellTouched, cc.TABLECELL_TOUCHED)
    end
    if cfg.cellSizeForTable then --此回调需要返回TableView中Cell的尺寸大小
        tableView:registerScriptHandler(cfg.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
    end
    if cfg.tableCellAtIndex then --此回调需要为TableView创建在某个位置的Cell
        tableView:registerScriptHandler(cfg.tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
    end
    if cfg.numberOfCellsInTableView then --此回调需要返回TableView中Cell的数量
        tableView:registerScriptHandler(cfg.numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    end
    if cfg.scrollViewDidScroll then -- 滚动回调
        tableView:registerScriptHandler(cfg.scrollViewDidScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    end

    return tableView
end
function Utils:createTableView1(parent,direction,sizeFun,numFun,cellAtIndexFun,cellTouchedFun,isBounce,verticalFillOrder)
    local cfg = {}
    cfg.tbPanel=parent
    cfg.direction=direction
    cfg.bounceable=isBounce
    cfg.verticalFillOrder=verticalFillOrder
    cfg.tableCellTouched=cellTouchedFun
    cfg.tableCellAtIndex=cellAtIndexFun
    cfg.numberOfCellsInTableView=numFun
    cfg.cellSizeForTable=sizeFun
    return Utils:createTableView(cfg)
end
--创建ScrollView
--@layout 基础容器
--@parent 父节点
--@direction 滑动方向
--@containerSize 内容框尺寸
function Utils:CreateScrollView(layout,parent,direction,containerSize)
    local scrollView = ccui.ScrollView:create()
    scrollView:setContentSize(layout:getContentSize())
    scrollView:setDirection(direction)   --设置滚动方向
    scrollView:setAnchorPoint(layout:getAnchorPoint())
    scrollView:setPosition(layout:getPosition())
    scrollView:setInnerContainerSize(containerSize)
    scrollView:setBackGroundColor(layout:getBackGroundColor())
    parent:addChild(scrollView)
    
    return scrollView
end

--创建ListView
--@layout 基础容器
--@direction 滑动方向
--@margin 间距
function Utils:CreateListView(layout,direction,margin)
local listView = ccui.ListView:create()
    listView:setDirection(direction)--LISTVIEW_DIR_VERTICAL
    listView:setContentSize(layout:getContentSize())
    listView:setAnchorPoint(layout:getAnchorPoint())
    listView:setPosition(layout:getPosition())
    listView:setBounceEnabled(false)-- 关闭惯性滑动
    listView:setSwallowTouches(false)
    listView:setItemsMargin(margin)-- 设置间距
    listView:setScrollBarEnabled(false)-- 隐藏滚动条
    layout:getParent():addChild(listView)
    return listView
end

--读取指定字符前的整数，并返回指定字符的偏移
function Utils:ReadBeforeCharInt(s, tagChar, offset)
    local start, idx = string.find(s, tagChar, offset)
    if start == nil then
        return nil, 0
    end
    local str = string.sub(s, start, idx)
    return idx + 1, tonumber(str)
end

--读取指定字符前的浮点数，并返回指定字符的偏移
function Utils:ReadBeforeCharFloat(s, tagChar, offset)
    local start, idx = string.find(s, tagChar, offset)
    if start == nil then
        return nil, 0
    end
    local str = string.sub(s, start, idx)
    return idx + 1, tonumber(str)
end

--读取指定字符前的字符串，并返回指定字符的偏移
function Utils:ReadBeforeCharStr(s, tagChar, offset)
    local start, idx = string.find(s, tagChar, offset)
    if start == nil then
        return nil, 0
    end
    local str = string.sub(s, start, idx)
    return idx + 1, str
end

function Utils:LuaSplitNumnber(s, tagChar)
    local offset = 1
    local start
    local finish
    local numnbers = {}
    while true do
        start, finish = string.find(s, tagChar, offset)
        if start == nil then
            if offset ~= string.len(s) then
                -- 取分割符后面的数字
                mapStr = string.sub(s, offset, -1)
                numnbers[#numnbers + 1] = tonumber(mapStr)
            end
            break
        end
        mapStr = string.sub(s, offset, start - 1)
        numnbers[#numnbers + 1] = tonumber(mapStr)
        offset = finish + 1
    end
    return numnbers
end

function Utils:getPostName(idx)
    local postNames = {GUITips.RSI_FACTION_BOSS, GUITips.RSI_FACTION_ELDERS, GUITips.RSI_FACTION_HUFA, GUITips.RSI_FACTION_BANGZHONG}
    return postNames[idx]
end

function Utils:ToBool(v)
    if v == nil then
        return false
    end
    if type(v) == "boolean" then
        return v
    elseif type(v) == "number" then
        return (math.floor(v) ~= 0) 
    elseif type(v) == "string" then
        return (#v > 0)
    else
        return (v ~= nil)
    end
end

--上浮提示框
function Utils:ShowScrollTips(msg,isAfterBattle)
    if msg == nil or #msg == 0 then
        return
    end
    if isAfterBattle == nil then
        isAfterBattle = false
    end
    if isAfterBattle then
        local isInHighCangBaoTu = LRoleDataMgr.IsInHighTreasuer
        --藏宝图
        if isInHighCangBaoTu then
            LRoleDataMgr.IsHighTreasuerMsg = msg
            return
        else
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTipsAtferBattle, msg)
        end
    else
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    end
    
    LUIManager:SendMsg(LGameMsg.m_scrollTipsMsg)
end

--走马灯（底部）
function Utils:ShowFloatNoticeMsg(msg)
    LGameMsg.m_floatTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowFloatNotice, msg)
    LUIManager:SendMsg(LGameMsg.m_floatTipsMsg)
end

--喇叭跑马灯
function Utils:ShowLabaNoticeMsg(msg)
    LGameMsg.m_floatTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowLabaNotice, msg)
    LUIManager:SendMsg(LGameMsg.m_floatTipsMsg)
end


--MsgBox-基础款，只包含描述、确定取消按钮
function Utils:ShowDialogOKCancel(msg,okFunc,cancelFunc,okBtnName,cancelBtnName, isAfterBattleShow, autoSelect, autoTime)
    local okName = okBtnName or GUITips.UI_Btn_OK
    local cancelName = cancelBtnName or GUITips.UI_Btn_Cancel
    local isAfter = isAfterBattleShow or false
    local userData =
    {
        title = GUITips.UI_Title_Tishi,
        desc = msg,
        okCallback = okFunc,
        cancelCallback = cancelFunc,
        okBtnName = okName,
        cancelBtnName = cancelName,
        AfterBattleShow = isAfter,
        autoSelect = autoSelect,
        autoTime = autoTime,
    }
    --print("LUIMsgBoxEvent.ShowMsgBox",LUIMsgBoxEvent.ShowMsgBox)
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, userData)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.PopWindow, userData)
    -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--MsgBox-基础款，多列描述
function Utils:ShowDialog(msg,title)
    local okName = GUITips.UI_Btn_OK
    local userData =
    {
        title = title or GUITips.UI_Title_Tishi,
        descList = msg
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, userData)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.PopWindow, userData)
    -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--MsgBox-血战失败，点击重置（cnt == -1 血战100关通关)
function Utils:ShowXueZhanDialog(closeFunc,okFunc,cnt)
    local userData =
    {
        title = GUITips.UI_Title_Tishi,
        closeCallback = closeFunc,
        okCallback = okFunc,
        xueZhanCnt = cnt,--剩余复活次数
    }
    Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, userData)
end

function Utils:ShowOneKeyStrengthDialog(msg, title, okFunc,cancelFunc)
	local userData =
    {
        title = title or GUITips.UI_Title_Tishi,
        desc = msg,
        okCallback = okFunc,
        cancelCallback = cancelFunc,
		showTips = true,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, userData)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--MsgBox-购买次数
function Utils:ShowBuyTimesDialog(price, useType, buyNum, maxBuyNun, OKCallback, cancelCallback)
    --useType 1 元宝  2 金币  3 绑元
    local userData =
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        TipsInfo = {
            price = price,
            useType = useType,
            buyNum = buyNum,
            maxBuyNum = maxBuyNun,
        }
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

function Utils:ShowBuyTiliDialog(price, OKCallback, cancelCallback)
    --useType 1 元宝  2 金币  3 绑元
    local userData =
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        TiliTipsInfo = {
            price = price,
            useType = useType,
        }
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--MsgBox-找回经验
-- function Utils:ShowResRecovery(findType, findName, findTimes, cost, awardInfo, OKCallback, cancelCallback)
--     local userData =
--     {
--         okCallback = OKCallback,
--         cancelCallback = cancelCallback,
--         spendInfo = {
--             findType = findType,
--             findName = findName,
--             findTimes = findTimes,
--             oneSpend = cost,
--             awardInfo = awardInfo,
--         }
--     }
--     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
--     LUIManager:SendMsg(LGameMsg.m_initUIMsg)
-- end
function Utils:ShowResRecovery(cellData, OKCallback, cancelCallback)
    local userData =
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        data = cellData
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Welfare.FindTimes",AppDef.UIType.PopWindow, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--MsgBox一键找回所有资源
function Utils:ShowResRecoveryAll(findType, cost, OKCallback, cancelCallback)
    local userData =
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        recoveryAllInfo = {
            findType = findType,
            cost = cost,
        }
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

function Utils:ShowLackItemUI(lackItemArr, OKCallback, cancelCallback, useType)
    -- body
    local userData =
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        lackItemInfo = lackItemArr,
        useType = useType,
        tips = GUITips.RSI_UPGRADE_BUYITEM_TIPS,
        title = GUITips.RSI_UPGRADE_BUYITEM_TITLE,
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end
--增加
function Utils:ShowLackItemUINew(lackItemArr, OKCallback, cancelCallback, useType)
    -- body
    local userData =
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        lackItemInfo = lackItemArr,
        useType = useType,
        tips = GUITips.RSI_UPGRADE_BUYITEM_TIPS,
        title = GUITips.RSI_UPGRADE_BUYITEM_TITLE,
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.HeChengPopup",AppDef.UIType.ThirdClassLayer, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--打开Vip界面
function Utils:OpenVipUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.VipMainUI",AppDef.UIType.FirstClassLayer)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--打开战斗通关界面
function Utils:ShowFiristAwardUI(activityId,okCallback)
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowFiristAwardUI,{activityId,okCallback})
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--打开神将图鉴界面
--@openTab 1-图鉴 2-阵型推荐
function Utils:OpenPetArchiveUI(openTab)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Pet.PetArchiveMainUI",AppDef.UIType.FirstClassLayer,openTab)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--图鉴红点检测
function Utils:TujianRedDotCheck()
    local hcData = LDataConstMgr:GetALLPetCpdData()
    if hcData == nil then return end
    for i=1,#hcData do
        --判断是否有该宠物
        local signHave = LRoleDataMgr.Pet:GetPetById(hcData[i].targetId - 60002)
        if not signHave then
            local itemId = hcData[i].itemId
            local itemNum = hcData[i].itemNum
            local curNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
            if curNum >= itemNum then
                return true
            end
        end
    end
    return false
end

--打开充值界面
function Utils:OpenRechargeMainUI()
    if #LRoleDataMgr.MyHeroInfo.m_PayPricelist > 0 then
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_RECHARGE,nil,true)
    else -- 没有查询过 就先查询
        LuaNetSendMsg:QueryPayPriceList()
    end
end

--充值
function Utils:Payment(money)
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP1)
        return
    end
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
 --   print("target **************************", target, cc.PLATFORM_OS_ANDROID, cc.PLATFORM_OS_IPHONE, cc.PLATFORM_OS_IPAD)
    -- if GameSdk.AppID == AppDef.APPID_JIANZHENGZHUXIAN then
        if target == cc.PLATFORM_OS_ANDROID  then
            --注册回调
            if GameSdk:IsSDKUser() then
                GameSdk:U8Pay(money)
                -- GameSdk:UCPaySuc()
                -- GameSdk:toPayUC(tostring(money))
            else
                Utils:ShowScrollTips(GUITips.RSI_BP_TIP45)
            end
        elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
            if GameSdk:IsSDKUser() then
                GameSdk:U8Pay(money)
            else
                -- print("GameSdk.ChannelId pay", GameSdk.ChannelId)
                GameSdk.payMoney = money
                
                -- GameSdk:IAPPay(GameSdk.payMoney)
                -- GameSdk:regesterIosPaySucCallBack()
                
                LuaNetSendMsg:QueryIAPOderId(GameSdk.ChannelId)
            end
            -- GameSdk:fetchProductIdentifier()
        else
            Utils:ShowScrollTips(GUITips.RSI_BP_TIP45)
        end
    -- else
    --     Utils:ShowScrollTips(GUITips.RSI_BP_TIP45)
    -- end
end

--元宝不足界面
function Utils:OpenNotEnoughGold()
    local function okFunc()
        self:OpenRechargeMainUI()
    end
    local function cancelFunc()

    end
    self:ShowDialogOKCancel(GUITips.RSI_GL_CPT_TIP6, okFunc, cancelFunc)
end

--打开商城界面,shopType-商店类型，itemId-选中道具id
function Utils:OpenShop(shopType,itemId)
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SCCHANGYONG) then 
        return
    end

    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.ShopUI")
    LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)

    -- print("OpenShop ============= 111111111111111 2222>", shopType)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Shop.ShopUI", AppDef.UIType.FirstClassLayer, {shopType=shopType})
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)

    if itemId ~= nil and itemId > 0 then
        local selectItem = {}
        selectItem.sel_id = itemId
        selectItem.sel_num = 1
        -- --dump(selectItem, "OpenShop from")
        Utils:SendMsg(LUIShopEvent.SelectShopItem, selectItem)
    end
end

--抽宠界面（包含礼盒抽奖）
function Utils:OpenRandPetUI(type,picList,getSign,msg)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Instances.RandPetUI", AppDef.UIType.PopWindow, {type,picList,getSign,msg})
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--打开玩法界面,id-选中玩法id
function Utils:OpenWanfaUI(id)
--    local function callback()
--        self:unschedule(nil,self.m_scheduleId)
--        LGameMsg.m_baseMsgWithOne:Change(LUIActivityEvent.ClickActivity, id)
--        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
--    end
    if self:CheckModelNotOpened(AppDef.EModuleID.EMID_WANFA) then 
        return
    end
    local flag = self:OpenFunction(AppDef.EModuleID.EMID_WANFA)
    if id ~= nil and id > 0 then
        --self.m_scheduleId = self:schedule(nil, callback, 0.3)
        self.m_wanfaId = id
    end
end

--打开非道具类穿戴Tips
--@param wearType "Mount"-坐骑,"Wing"-翅膀,"Title"-称号,"Artifact"-神器
--@param cfgId 配置表Id
function Utils:OpenWearTips(wearType,cfgId)
    if cfgId == nil or  cfgId < 1 then return end
    local item = 
    {
        itemType = wearType,
        id = cfgId,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemWearTips, item)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end
-- Awrdid 奖励类型
-- quality 品质
-- star  星级
-- pid 道具id
--神将装备
function Utils:ShowPetEquidTips(AwrdId,quality,star,pid)
    if AwrdId ~=  AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
       return
    end
    local userdata={
      itemType="PetEuqid",
      quality=quality,
      star=star,
      itemData=AwrdId,
      pid=pid,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, userdata)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function Utils:ShowGoldTips(id, quality)
    if id < 1 then return end
    if not AppDef:IsMoneyType(id) then return end
    local userdata = {id,0,0}
    Utils:SendMsg(LUILogicEvent.ShowItemSource,userdata)
end

function Utils:ShowItemTips(id)
    if id < 1 then return end
    local userdata = {id,0,0}
    Utils:SendMsg(LUILogicEvent.ShowItemSource,userdata)
end

function Utils:ShowItemSource(data)
    if data == nil or type(data) ~= "table" or #data < 3 or data[1] == AppDef.RewardItem.RD_ITEM_PET then
        return
    end
    Utils:SendMsg(LUILogicEvent.ShowItemSource,data)
end


--字符串拼接，{pos},...对应填充
--pos从{1}开始
function Utils:JointString(str,...)
	local args = {...} 
    if #args == 0 then
       return str
    end
    for i=1,#args do
        local temp = "{"..i.."}"
        str = string.gsub(str,temp,args[i])
    end
    return str
end

--字符串处理，删除开始符号与结束符号之间的内容
--fir开始符号，fin结束符号
function Utils:DeleteString(str,fir,fin)
    if str == nil or #str == 0 or fir == nil or fin == nil then 
        return "" 
    end
    local newStr = str
    for i=1,100 do
	   local pos1 = string.find(newStr,fir)
       local pos2 = string.find(newStr,fin)
       if pos1 == nil or pos2 == nil then
           break
       end
       local sNew1 = string.sub(newStr,1,pos1-1)
       local sNew2 = string.sub(newStr,pos2+1)
       newStr = sNew1..sNew2
    end
    return newStr
end

function Utils:initLuaTable(num, v)
    local o = {}
    for i=1,num do
        table.insert(o, v)
    end
    return o
end

--[[
创建一个富文本框
parent 父节点
oldText 替换节点
newName 新节点的名字
isReomve 旧节点是否删除
]]
function Utils:CreateColorText(parent, oldText, newName, isReomve)
    local newText = CCAysLabel:create()
    newText:setName(newName)
    newText:setPosition(oldText:getPosition())
    newText:setAnchorPoint(cc.p(0,0))
    parent:addChild(newText)
    newText.pFontSize = oldText:getFontSize()
    newText.cellSize = oldText:getContentSize()
    newText.color = oldText:getTextColor()
    newText.oldX = oldText:getPositionX()
    newText.oldY = oldText:getPositionY()
    if isReomve == nil or isReomve then
        oldText:removeFromParent()
    end
    return newText
end

function Utils:CreateColorText2(parent, oldText, textSize)
    if oldText == nil then
        return nil
    end
    local pos = cc.p(oldText:getPosition())
    local anchor = oldText:getAnchorPoint()
    local textSize = textSize or oldText:getContentSize()
    local fontSize = oldText:getFontSize()
    local fontColor = oldText:getTextColor()

    local pAysLabel = CCAysLabel:createWithFixedWidth(textSize.width, fontSize, cc.c3b(fontColor.r,fontColor.g, fontColor.b), false)
    pAysLabel:setPosition(cc.p(pos.x-anchor.x*textSize.width, pos.y+(1-anchor.y)*oldText:getContentSize().height))
    pAysLabel:setName(oldText:getName())
    oldText:getParent():addChild(pAysLabel,oldText:getLocalZOrder())
    oldText:removeFromParent(true)
    return pAysLabel
end


function Utils:CreateColorText3(oldText, isRemove)
    if oldText == nil then
        return nil
    end
    local pos = cc.p(oldText:getPosition())
    local anchor = oldText:getAnchorPoint()
    local textSize = textSize or oldText:getContentSize()
    local fontSize = oldText:getFontSize()
    local fontColor = oldText:getTextColor()

    local pAysLabel = CCAysLabel:createWithFixedWidth(textSize.width, fontSize, cc.c3b(fontColor.r,fontColor.g, fontColor.b), false)
    pAysLabel:setPosition(cc.p(pos.x-anchor.x*textSize.width, pos.y+(1-anchor.y)*oldText:getContentSize().height))
    pAysLabel:setName(oldText:getName())
    if oldText:getParent()==nil then
        return pAysLabel

    end
    oldText:getParent():addChild(pAysLabel,oldText:getLocalZOrder())
    if isRemove ~= nil and isRemove == true then
        oldText:removeFromParent()
    else
        oldText:setVisible(false)
    end
    
    return pAysLabel
end

function Utils:CreateColorText4(parent,oldText)
    if oldText == nil then
        return nil
    end
    local pos = cc.p(oldText:getPosition())
    local anchor = oldText:getAnchorPoint()
    local textSize = textSize or oldText:getContentSize()
    local fontSize = oldText:getFontSize()
    local fontColor = oldText:getTextColor()

    local pAysLabel = CCAysLabel:createWithFixedWidth(textSize.width, fontSize, cc.c3b(fontColor.r,fontColor.g, fontColor.b), false)
    pAysLabel:setPosition(cc.p(pos.x-anchor.x*textSize.width, pos.y+(1-anchor.y)*oldText:getContentSize().height))
    pAysLabel:setName(oldText:getName())
    parent:addChild(pAysLabel)
   -- oldText:getParent():addChild(pAysLabel,oldText:getLocalZOrder())
    oldText:removeFromParent()
    return pAysLabel
end

--[[
移动到tableview的指定索引位置
tableView
cell 格子单元
idx 索引 从0开始
]]
function Utils:MoveToTableIdx(tableView, cell, idx)
    local dir = tableView:getDirection()
    local offset = tableView:getContentOffset()
    local min, max, pos
    if dir == cc.SCROLLVIEW_DIRECTION_VERTICAL then
        min = tableView:minContainerOffset().y
        max = tableView:maxContainerOffset().y
        pos = cell:getContentSize().height * idx
        offset.y = math.max(math.min(min+pos, max), min)
    elseif dir == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
        min = tableView:minContainerOffset().x
        max = tableView:maxContainerOffset().x
        pos = cell:getContentSize().width * idx
        offset.x = math.max(math.min(min+pos, max), min)
    end
    tableView:setContentOffset(offset)
end

--[[
移动到tableview的指定索引位置
tableView
cellHeight 格子单元高度
idx 索引 从0开始
]]
function Utils:MoveToTableIdxSec(tableView, cellHeight, idx)
    local offset = tableView:getContentOffset()
    local min = tableView:minContainerOffset().y
    local max = tableView:maxContainerOffset().y
    offset.y = math.max(math.min(min+cellHeight*idx, max), min)

    tableView:setContentOffset(offset)
end

function Utils:RemoveNode(node)
    if node then
        node:removeFromParent()
    end
end

function Utils:DelayToCallFunc(node, delayTime, func)
    if delayTime > 0 then
        local delay = cc.DelayTime:create(delayTime)
        local func = cc.CallFunc:create(func)
        local sq = cc.Sequence:create(delay, func)
        node:runAction(sq)
    else
        local func = cc.CallFunc:create(func)
        node:runAction(func)
    end
end



--创建动画模型
function Utils:CreateImod(str,pos,parent,scale)
    local p = ImodAnim:createWithFileSync(str)
    p:setPosition(pos)
    p:setScale(scale)
    parent:addChild(p)
    return p
end

--坐标自适应
function Utils:GetRelativePoint(pos)
    local scaleX = AppDef.frameSize.width/1334
    local scaleY = AppDef.frameSize.height/750
    return cc.p(pos.x*scaleX,pos.y*scaleY)
end

function Utils:Delete(...)
    local temp = {...}
    for k,v in pairs(temp) do
        if v ~= nil then
            if type(v) == "table" then
                if v.Delete and type(v.Delete) == "function" then
                    v:Delete()
                    temp[k] = nil
                else
                    for kk,vv in pairs(v) do
                        Utils:Delete(vv)
                        v[kk] = nil
                    end
                end
            else
                temp[k] = nil
            end
        end
    end
end

--[[
创建一个带物品数量的格子
grid 格子父控件
type 0 普通物品 1 神器 
itemId 物品id
showQuality 是否显示品质
showNum 是否显示数量
num 数量
isOpenTouch 是否开启点击事件
isChangeSize 是否和父节点大小匹配
isSelect 是否显示选中框
]]
function Utils:GetItemCellValue(grid, type, itemId, showQuality, showNum, num, pItem, isOpenTouch, isChangeSize, isSelect)

     -- 特殊物品
    local function MakeDefineValue(itemValue, itemId)
        local pic = GUITipsAwrdItemIdMap[itemId]
        local quality = 0
        local cfg = LItemMgr:getItem(itemId)
        if cfg ~= nil then
            pic = cfg.pic
            quality = cfg.quality
        end
        if pic == nil then
            return
        end
        if not showQuality then
            quality = 0
        end
        local userDefine =
        {
            picFilePath = string.format(AppDef.GUIRes.Res_Item_Path, pic),
            quality = quality,
            num = num,
            itemId = itemId
        }
        itemValue.userDefine = userDefine
        return userDefine
    end
    -- 特殊物品2
    local function MakeDefineValue2(itemValue, path, itemType, itemId)
        local userDefine =
        {
            picFilePath = path,
            itemId = itemId,
            itemType = itemType,
        }
        itemValue.userDefine = userDefine
        return userDefine
    end

    -- 普通物品
    local function MakNormalValue(itemValue, itemId)
        -- print("MakNormalValue",itemId)
        local item = LPItem:New(itemId)
        itemValue.itemData = item
        item.m_item = LItemMgr:getItem(itemId)
        if item.m_item == nil then
        --默认数据
            return MakeDefineValue(itemValue, AppDef.AwrdItem.AWRD_ITEM_COIN)
        end

        item.m_num = num
        item.name = item.m_item.name
        return item
    end

    -- 神器
    local function MakeShenqiValue(itemValue, itemId)
        local userDefine =
        {
            picFilePath = AppDef.GUIRes["Shenqi_Stage_Icon_"..itemId],
            quality = 0,
            itemId = itemId,
            itemType = AppDef.AwrdItem.AWRD_ITEM_ARTIFACT,
        }
        itemValue.userDefine = userDefine
        return userDefine
    end

    local itemValue = {
        isShowQualityBg = showQuality,
        isShowNum = showNum,
        isChangeSize = isChangeSize,
        isSelect = isSelect,
    }
    if type == 0 then
        -- if itemId == AppDef.AwrdItem.AWRD_ITEM_COIN     -- 金币
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_YUANBAO  -- 元宝
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_EXP      -- 经验
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_POTEN    -- 潜能
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_SHENPO   --神魄
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_BANGGONG  --帮贡
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_LTJIFEN  --积分
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_XINXIUJINHUA  --星宿精华
        --     or itemId == AppDef.AwrdItem.AWRD_ITEM_BPMONEY  --帮派资金
        if AppDef:IsSpecialItem(itemId) == true
        then
            MakeDefineValue(itemValue, itemId)
            --翅膀和坐骑不要了
        -- elseif itemId == AppDef.AwrdItem.AWRD_ITEM_WINDS then --翅膀
        --     MakeDefineValue2(itemValue, "res2/Wing_Bust/"..num.."_tou.png", itemId, num)
        -- elseif itemId == AppDef.AwrdItem.AWRD_ITEM_HORSE then --坐骑
        --     MakeDefineValue2(itemValue, "res2/Horse_Bust/"..num.."_tou.png", itemId, num)
        elseif itemId == AppDef.AwrdItem.AWRD_ITEM_EQUIP then --神将装备
            return self:GetEquipCellByEquipID(grid, pItem, num, isOpenTouch, isChangeSize,showQuality)
        elseif itemId == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then --称号
            itemValue.isShowNum = false
            MakeDefineValue2(itemValue, "item/equip4000.png", itemId, num)
        else
            MakNormalValue(itemValue, itemId)
        end
    elseif type == 1 then
        MakeShenqiValue(itemValue, itemId)
    end
    -- print("GetItemCellValue ===============>", isOpenTouch, itemId)
    if pItem ~= nil then
        pItem:UpdateItem(itemValue)
        pItem:SetCanClick(Utils:ToBool(isOpenTouch))
        return pItem
    end
    pItem = ItemCellUI:New(grid, itemValue) 
    pItem:SetCanClick(Utils:ToBool(isOpenTouch))
    return pItem
end

--[[
神将装备图标显示
grid 格子父控件
equipId 装备id
isOpenTouch 是否开启点击事件
isChangeSize 是否和父节点大小匹配
]]
function Utils:GetEquipCellValue(grid,pItem,equipId,uid,qhLv,jlLv,szLv,jxLv,isOpenTouch,isChangeSize,showQuality, isShowNum, num)
    if isOpenTouch == nil then
        isOpenTouch = false
    end
    if isChangeSize == nil then
        isChangeSize = false
    end
    if showQuality==nil then
       showQuality=true
    end
    local itemValue = {
        isChangeSize = isChangeSize,
        isShowQualityBg = showQuality,
    }
    --if uid == 0 or equipId == 0 then
    if uid == 0 and equipId == 0 then
        isOpenTouch = false
        itemValue = nil
    else
        local petEquipData =
        {
            uid = uid,
            id = equipId,
            star = jxLv or 0,
            qhLv = qhLv or 0,
            jlLv = jlLv or 0,
            szLv = szLv or 0,
            isShowNum = isShowNum or false,
            num = num or 0,
        }
        itemValue.petEquipData = petEquipData
    end
    if pItem ~= nil then
        pItem:UpdateItem(itemValue)
        pItem:SetCanClick(Utils:ToBool(isOpenTouch))
        return pItem
    end
    pItem = ItemCellUI:New(grid, itemValue) 
    pItem:SetCanClick(Utils:ToBool(isOpenTouch))
    return pItem
end

function Utils:GetEquipCellValueVec2(grid, pItem, equipData, isOpenTouch, isChangeSize, showQuality)
    local qhLv = equipData.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
    local jlLv = equipData.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
    local jxLv = equipData.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
    local szLv = equipData.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0 
    local equipId = equipData.m_id
    local uid = equipData.m_uid
    return self:GetEquipCellValue(grid,pItem,equipId,uid,qhLv,jlLv,szLv,jxLv,isOpenTouch,isChangeSize,showQuality)
end

--方便通用接口调用
function Utils:GetEquipCellByEquipID(grid, pItem, equipId, isOpenTouch, isChangeSize,showQuality, isShowNum, num)
    -- body
    --显示初始状态头像
    local qhLv = 0
    local jlLv = 0
    local jxLv = 0
    local szLv = 0
    return self:GetEquipCellValue(grid,pItem,equipId,0,qhLv,jlLv,szLv,jxLv,isOpenTouch,isChangeSize,showQuality, isShowNum, num)
end

--[[
根据配置显示道具
]]
function Utils:ShowItemByConfigData(dataArr, grid, itemCell, isTouchEnabled, isResize,isShowNum)
    isResize = isResize or false;
    isTouchEnabled = isTouchEnabled or false;
    isShowNum = isShowNum or true
    local id = dataArr[1];
    local tmp = dataArr[2];
    local num = dataArr[3];
    local itemType = 0
    if id == AppDef.RewardItem.RD_ITEM_EQUIP then
        itemType = AppDef.RewardItem.RD_ITEM_EQUIP;
        id = tmp
    elseif id== AppDef.RewardItem.RD_ITEM_PET then
        itemType = AppDef.RewardItem.RD_ITEM_PET;
        id = num
    elseif id == AppDef.RewardItem.RD_ITEM_FABAO then
        itemType = AppDef.RewardItem.RD_ITEM_FABAO;
        id = tmp
    end

    if itemType == AppDef.RewardItem.RD_ITEM_EQUIP then
        itemCell = Utils:GetEquipCellValue(grid,itemCell,id,0,nil,nil,nil,nil,false,false,true, true, num)
        -- local cfg = JsonConfig.m_equipConfig.getDefByID(data.id)
        -- if cfg ~= nil then
        --     nameLabel:setString(cfg.name)
        --     nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
        -- end
    elseif itemType == AppDef.RewardItem.RD_ITEM_PET then
        return PetCellUI:New(grid, {id})
    elseif itemType == AppDef.RewardItem.RD_ITEM_FABAO then
        --grid,pItem,faBaoId,uid, isShowNum, num, qhLv,jlLv,isOpenTouch,isChangeSize
        itemCell = Utils:GetFaBaoCellValue(grid, itemCell, id, 0, isShowNum, num, nil,nil,isTouchEnabled,isResize)
        -- local cfg = JsonConfig.m_faBaoConfig.getDefByID(data.id)
        -- if cfg ~= nil then
        --     nameLabel:setString(cfg.name)
        --     nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
        -- end
    else
        -- if AppDef:IsSpecialItem(id) == true then
        --     isTouchEnabled = false;
        -- end
        -- print("id",id)
        itemCell = Utils:GetItemCellValue(grid, 0, id, true, isShowNum, num, itemCell, isTouchEnabled, isResize)
        -- local cfg = JsonConfig.m_Item.getDefByID(data.id)
        -- if cfg ~= nil then
        --     nameLabel:setString(cfg.name)
        --     nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
        -- end
    end
    return itemCell
end

                                --grid, itemCell, id, true, num
function Utils:GetFaBaoCellValue(grid,pItem,faBaoId,uid, isShowNum, num, qhLv,jlLv,isOpenTouch,isChangeSize)
    if isOpenTouch == nil then
        isOpenTouch = false
    end
    if isChangeSize == nil then
        isChangeSize = false
    end
    local itemValue = {
        isChangeSize = isChangeSize,
    }
    if faBaoId == 0 then
        isOpenTouch = false
        itemValue = nil
    else
        local petFaBaoData =
        {
            uid = uid,
            id = faBaoId,
            qhLv = qhLv or 0,
            jlLv = jlLv or 0,
            isShowNum = isShowNum or false,
            num = num or 0,
        }
        itemValue.petFaBaoData = petFaBaoData
    end
    if pItem ~= nil then
        pItem:UpdateItem(itemValue)
        pItem:SetCanClick(Utils:ToBool(isOpenTouch))
        return pItem
    end
    pItem = ItemCellUI:New(grid, itemValue)
    pItem:SetCanClick(Utils:ToBool(isOpenTouch))
    return pItem
end

--根据神将上阵位置获取装备数据
function Utils:GetEquipsByfPos(fPos)
    if LRoleDataMgr.Pet.equipList == nil then
        LRoleDataMgr.Pet.equipList = {}
    end
    if LRoleDataMgr.Pet.equipList.m_formationEquips == nil then
        LRoleDataMgr.Pet.equipList.m_formationEquips = {}
    end
    return LRoleDataMgr.Pet.equipList.m_formationEquips[fPos]
end

--根据神将上阵位置获取法宝
function Utils:GetFaBaoByfPos(fPos)
    if LRoleDataMgr.Pet.faBaoList == nil then
        LRoleDataMgr.Pet.faBaoList = {}
    end
    if LRoleDataMgr.Pet.faBaoList.m_formationFaBaos == nil then
        LRoleDataMgr.Pet.faBaoList.m_formationFaBaos = {}
    end
    return LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[fPos]
end

--[[
通过id 获取图片资源
]]
function Utils:getPicById(curDayFisrtAward)
    -- body
    local picFilePath
    if curDayFisrtAward >= AppDef.AwrdItem.AWRD_ITEM_COIN then
        picFilePath = string.format(AppDef.GUIRes.Res_Item_Path, GUITipsAwrdItemIdMap[curDayFisrtAward])
    else
        local pathID = LRoleDataMgr.GetItemPicId(curDayFisrtAward)
        picFilePath = string.format(AppDef.GUIRes.Res_Item_Path, pathID)
    end
    return picFilePath
end

--增加特效
function Utils:createAnimEffect( parent, pos, path)
    -- body
    --按钮动画
    local pCreateImod = ImodAnim:createWithFileSync(path)
    pCreateImod:setPosition(cc.p(pos.x - 3, pos.y))
    parent:addChild(pCreateImod, 5);

    -- local pngStr = "res2/fx/gaojiwupin.png"
    -- local aniStr = "res2/fx/gaojiwupin.ani"
    --pCreateImod:initAnimWithNameSync(path)
    pCreateImod:PlayActionRepeat(0)
    return pCreateImod
end

function Utils:getQualityByItem(item)
    -- body
    if item == nil then
        return 0
    end

    if item.m_pItem == nil then
        return 0
    end
    ----dump(item, "getQualityByItem")
    if item.m_pItem:IsEquip() == true then
        return item.m_pItem.m_quality
    else
        if item.m_pItem.m_item == nil then
            return 0
        end
        return item.m_pItem.m_item.quality
    end
    return 0
end

function Utils:getItemNameByConfigArr(arr)
    if arr == nil then
        return ""
    end
    if arr[1] == AppDef.RewardItem.RD_ITEM_EQUIP then
        return Utils:getEquipNameByID(arr[2])
    elseif arr[1] == AppDef.RewardItem.RD_ITEM_PET then
        local info = LPetDataMgr:FindPetDataById(arr[2])
        if info == nil then
            return ""
        end
        return info.name
    elseif arr[1] == AppDef.RewardItem.RD_ITEM_FABAO then
        local cfg = JsonConfig.m_faBaoConfig.getDefByID(arr[2])
        if cfg == nil then
            return ""
        end
        return cfg.name
    else
        local item = JsonConfig.m_Item.getDefByID(arr[1]);
        if item then
            return item.name
        else
            return ""
        end
    end
end

function Utils:getItemNameByID(itemId,value)
    if itemId == nil then
        return ""
    end
    local cfg = nil
    if itemId == AppDef.RewardItem.RD_ITEM_FABAO then
        cfg = JsonConfig.m_faBaoConfig.getDefByID(value)
    elseif itemId == AppDef.RewardItem.RD_ITEM_EQUIP then
        cfg = JsonConfig.m_equipConfig.getDefByID(value)
    elseif itemId == AppDef.RewardItem.RD_ITEM_PET then
        cfg = JsonConfig.m_heroCfg.getDefByID(value)
    else
        cfg = LDataConstMgr:getCItemByID(itemId)
    end
    if cfg ~= nil then
        return cfg.name
    end
    return ""
end

function Utils:getEquipNameByID( equipId )
    -- body
    local configData = JsonConfig.m_equipConfig.getDefByID(equipId)
    if configData == nil then
        return ""
    end
    return configData.name
end

--加载单个神将
function Utils:ShowPetOnItem(id, item, noTouch,Petstar)
    local info = LPetDataMgr:FindPetDataById(id)
    -- --dump(info, "ShowPet ==============>")
    if info == nil then return end

    item.userObject = id
    if noTouch == nil or noTouch == false then
        item:setTouchEnabled(true)
    end
    -- parent:addChild(item)

    local icon = item:getChildByName("Icon")
    --icon
    Utils:ShowPetHeadImg(icon,info.pic,item,info.quality, PetkaPaiManager:IsShiny(info))
    --评分
    local scoreImage = item:getChildByName("Quality")
    AppDef:GetPetQualityScore(scoreImage,info.quality)
    --神将类型
    local typeImage = item:getChildByName("Career")
    if typeImage then
        AppDef:ShowPetType(typeImage,info.petType)
    end
    --数量
    local label = item:getChildByName("Text")
    if label then
        label:setString("")
    end
    --星级
    local list = item:getChildByName("StarsList")
    list:setSwallowTouches(false)
    local star = list:getChildByName("Star")

    if Petstar==nil then
      for i=2,info.initstar do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
      end
    else
       for i=2,Petstar do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
      end

    end
    local function ShowPetInfo(sender)--查看信息
        local id = sender.userObject
         if Petstar ~=nil then
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id,nil,Petstar})
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        else
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)  
        end
    end
    item:addClickEventListener(ShowPetInfo)
end


--加载单个神将
function Utils:ShowPet(id, parent, item, noTouch,Petstar)
    local info = LPetDataMgr:FindPetDataById(id)
    -- --dump(info, "ShowPet ==============>")
    if info == nil then return end
    local parentHeight = parent:getContentSize().height
    local itemHeight = item:getContentSize().height
    local temp = (parentHeight-itemHeight)/2
    item:setAnchorPoint(cc.p(0,0))
    item:setPosition(cc.p(temp,temp))
    item.userObject = id
    if noTouch == nil or noTouch == false then
        item:setTouchEnabled(true)
    end
    -- parent:addChild(item)

    local icon = item:getChildByName("Icon")
    --icon
    Utils:ShowPetHeadImg(icon,info.pic,item,info.quality,info:IsShiny())
    --评分
    local scoreImage = item:getChildByName("Quality")
    AppDef:GetPetQualityScore(scoreImage,info.quality)
    --神将类型
    local typeImage = item:getChildByName("Career")
    if typeImage then
        AppDef:ShowPetType(typeImage,info.petType)
    end
    --数量
    local label = item:getChildByName("Text")
    label:setString("")
    --星级
    local list = item:getChildByName("StarsList")
    list:setSwallowTouches(false)
    local star = list:getChildByName("Star")

    if Petstar==nil then
      for i=2,info.initstar do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
      end
    else
       for i=2,Petstar do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
      end

    end
    local function ShowPetInfo(sender)--查看信息
        local id = sender.userObject
         if Petstar ~=nil then
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id,nil,Petstar})
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        else
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)  
        end
    end
    item:addClickEventListener(ShowPetInfo)
end


--加载单个神将
function Utils:ShowPetByData(itemInfo, parent, item, noTouch,Petstar)
    local info
    if itemInfo == nil then
        info = LPetDataMgr:FindPetDataById(10)
    else
        info = itemInfo
    end
    
    -- --dump(info, "ShowPet ==============>")
    if info == nil then return end
    local parentHeight = parent:getContentSize().height
    local itemHeight = item:getContentSize().height
    local temp = (parentHeight-itemHeight)/2
    item:setAnchorPoint(cc.p(0,0))
    item:setPosition(cc.p(temp,temp))
    item.userObject = itemInfo.id
    if noTouch == nil or noTouch == false then
        item:setTouchEnabled(true)
    end
    -- parent:addChild(item)

    local icon = item:getChildByName("Icon")
    --icon
    Utils:ShowPetHeadImg(icon,info.pic,item,info.quality,info:IsShiny())
    --评分
    local scoreImage = item:getChildByName("Quality")
    AppDef:GetPetQualityScore(scoreImage,info.quality)
    --神将类型
    local typeImage = item:getChildByName("Career")
    AppDef:ShowPetType(typeImage,info.petType)
    --数量
    local label = item:getChildByName("Text")
    label:setString("")
    --星级
    local list = item:getChildByName("StarsList")
    list:setSwallowTouches(false)
    local star = list:getChildByName("Star")

    if info.star == nil or info.star < 1 then
        info.star = 1
    end
    Petstar = info.star
    if Petstar==nil then
      for i=2,info.star do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
      end
    else
       for i=2,Petstar do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
      end

    end
    local function ShowPetInfo(sender)--查看信息
        local id = sender.userObject
         if Petstar ~=nil then
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id,nil,Petstar})
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        else
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)  
        end
    end
    item:addClickEventListener(ShowPetInfo)
end

--获取滚动层当前位置的百分比(横向)
function Utils:GetScrollViewXPercent(scrollView)
    if scrollView == nil then 
        return 0
    end 
    local direction = scrollView:getDirection()
    if direction == cc.SCROLLVIEW_DIRECTION_VERTICAL then
        return 0
    end
    local size = scrollView:getInnerContainerSize()     --内容区大小
    local pos = scrollView:getInnerContainerPosition()  --内容区当前位置
    local listSize = scrollView:getContentSize()      --列表可见区域大小
    local percent = 0
    if size.width > listSize.width then 
         --左侧0，右侧100 最大偏移量 = 总宽度-列表可见区域
         percent = math.abs(pos.x)/(size.width-listSize.width)*100
    end
    return percent
end

function Utils:SecondFormat(second)
    local hour = second / 3600
    local min = second / 60
    local sec = second % 60
    return string.format("%02d:%02d:%02d", hour, min, sec)
end

function Utils:GetPetHeadCellValue(grid, pItem, petData, showQuality, isOpenTouch, isChangeSize, isSelect)
	if showQuality == nil then
		showQuality = false
	end
	if isOpenTouch == nil then
		isOpenTouch = false
	end

	if isChangeSize == nil then
		isChangeSize = false
	end

	if isSelect == nil then
		isSelect = false
	end

	if petData == nil then return end
	local itemValue = {}
	itemValue.m_isShowQuityBg = showQuality
	itemValue.isChangeSize = isChangeSize
	itemValue.isSelect = isSelect
	itemValue.heroData = petData
	if pItem ~= nil then
        pItem:UpdateItem(itemValue)
        pItem:SetCanClick(Utils:ToBool(isOpenTouch))
        return pItem
    end
    pItem = HeroCellUI:New(grid, itemValue) 
    pItem:SetCanClick(Utils:ToBool(isOpenTouch))
    return pItem
end
--[[
显示宠物icon
headImg:头像ImageView
petId:宠物id 
bgImg:背景ImageView
petQuality:宠物品质
]]
function Utils:ShowPetHeadImg(headImg, petId, bgImg, petQuality, isShiny)
    local isSafe = true
    if bgImg ~= nil then
        
        local color = AppDef:GetPetQualityColorId(petQuality)
        local str = AppDef.ColorKuangArr[color]
        if str then
            isSafe = Utils:SafeLoadTexture(bgImg,str,ccui.TextureResType.plistType)
            --bgImg:loadTexture(str,ccui.TextureResType.plistType)
        end
    end
    if isSafe == false then
        return
    end
    if headImg then
        local imgPath = "res2/Monster_Bust/" .. petId.. "_tou.png"
        isSafe = Utils:SafeLoadTexture(headImg,imgPath,ccui.TextureResType.localType)
        --headImg:loadTexture(imgPath,ccui.TextureResType.localType)
        if isSafe == false then
            return
        end
        if isShiny == true then
            local imod = ImodAnim:createWithFileSync("item/equipLight")
            imod:PlayActionRepeat(0,0.1)
            local size = headImg:getContentSize()
            imod:setPosition(cc.p(size.width/2, size.height/2))
            headImg:addChild(imod,0,666)
        else
            headImg:removeChildByTag(666)
        end
    end
end

--[[
创建一个不被压缩的img
parent 父节点
replaceImg 需要替换图片
sprite
]]
function Utils:CreateSprite(parent, replaceImg, sprite)
    if sprite == nil then
        return nil
    end
    sprite:setLocalZOrder(replaceImg:getLocalZOrder())
    sprite:setScale(replaceImg:getScale())
    sprite:setAnchorPoint(cc.p(replaceImg:getAnchorPoint().x, replaceImg:getAnchorPoint().y))
    sprite:setPosition(cc.p(replaceImg:getPositionX(), replaceImg:getPositionY()))
    parent:addChild(sprite)
    replaceImg:setVisible(false)
    return sprite
end

--[[
创建一个不被压缩的img
parent 父节点
replaceImg 需要替换图片
imgStr 图片plist 名称
]]
function Utils:CreateSpriteWithFrame(parent, replaceImg, imgStr)
    local sprite = cc.Sprite:createWithSpriteFrameName(imgStr)
    if sprite == nil then--再创建一次
        sprite = cc.Sprite:createWithSpriteFrameName(imgStr)
    end
    return Utils:CreateSprite(parent, replaceImg, sprite)
end

--[[
创建一个不被压缩的img
parent 父节点
replaceImg 需要替换图片
imgStr 图片名称
]]
function Utils:CreateSpriteWithPath(parent, replaceImg, imgStr)
    local sprite = cc.Sprite:create(imgStr)
    return Utils:CreateSprite(parent, replaceImg, sprite)
end

--[[
创建一个不被压缩的img
parent 父节点
]]
function Utils:AddSprite(parent, strPath)
    local sprite = cc.Sprite:create(strPath)
    if sprite == nil then--再创建一次
        sprite = cc.Sprite:createWithSpriteFrameName(strPath)
    end
    sprite:setPosition(cc.p(parent:getContentSize().width / 2, parent:getContentSize().height / 2))
    parent:addChild(sprite)
    return sprite
end

function Utils:CheckImprove(imType)
    LGameMsg.m_baseMsgWithOne:Change(LUIMainEvent.CheckImproveBtn, imType)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--检查背包更新提升
function Utils:CheckPackageCanUp(pos, item_id, num)
    -- 锻造升级使用的
    if ((item_id >= 506 and item_id <= 518) or (item_id >= 1 and item_id <=474)) then--铁 锦缎 金丝/装备id
        Utils:CheckImprove(ImproveDef.Type.UP_Equip)
    end

    -- 锻造强化
    if ((item_id >= 1 and item_id <=476 or item_id == 610)) then
        Utils:CheckImprove(ImproveDef.Type.STRENGTH_EQUIP)
    end

    -- 宠物技能升级或者学习
    if (item_id >= 540 and item_id <= 570) then
        if (#LRoleDataMgr.Pet.petlist > 0) then
            Utils:CheckImprove(ImproveDef.Type.UPGRADESKILL_PET)
        end
    elseif ((item_id == 631)) then-- 宠物洗资  -- 培养露
    elseif(item_id == 834) then--宠物可升级
        Utils:CheckImprove(ImproveDef.Type.UPGRADE_PET)
    elseif (item_id >= 2251 and item_id <= 2254) then-- 坐骑进阶
        Utils:CheckImprove(ImproveDef.Type.STRENGTH_HORSE)
    elseif (item_id >= 2301 and item_id <= 2303) then -- 坐骑进阶
        Utils:CheckImprove(ImproveDef.Type.TRANSFORM_HORSE)
    elseif (item_id >= 2310 and item_id <= 2313) then-- 宠物铠甲
    elseif(item_id == 2370) then--检查宠物可进化
        Utils:CheckImprove(ImproveDef.Type.EVOLUTE_PET)
    end
    
    local itemConf = JsonConfig.m_Item.getDefByID(item_id)
    if itemConf ~= nil and itemConf.type  == AppDef.ItemType.PetFrag then
        local ret = {}
        ret.script = "HappyDraw.DrawRewardMainUI"
        Utils:SendMsg(LUILogicEvent.CheckLayerExist, ret)
        if ret.isExist then
            return
        end
        LRoleDataMgr:CheckPetCompound()
    end
end

-- 物品不足提示
function Utils:ItemNotEnoughTips(itemId)
    local item = LDataConstMgr:getCItemByID(itemId)
    if item ~= nil then
        self:ShowScrollTips(string.format(GUITips.Rsi_Item_Not_Enough_Format, item.m_name))
    end
end
--[[
自动排列
parent:Node父节点
nodes:{Node}需要排列的节点
space:{Number}间隔 [1]-中间间隔 [2]-左间隔/顶间隔 [3]-右间隔/底间隔
align:Number排列方式Vec2 - 1:从左到右 2:从右到左 3:水平居中 4:从上到下 5:从下到上 6:垂直居中
isChangeParentSize:Bool 是否改变父节点尺寸
time:float 移动动画时长 0/nil表示立即更新位置
]]
function Utils:AlignNodes(parent, nodes, space, align, isChangeParentSize, time)
    if parent == nil or nodes == nil or #nodes == 0 or space == nil or align == nil then
        return
    end
    local rNodes,poses,allSize,center = Utils:GetAlignPos(parent, nodes, space, align, isChangeParentSize)
    -- print("allSize-->", allSize)
    ------------------------------------------------------------------------------
    if isChangeParentSize then
        parent:setContentSize(cc.size(center.x*2, center.y*2))
    end
    -----------------------------------------------------------------------------
    if align < 4 then
        for i=1,#rNodes do
            local x = poses[i]
            local node = rNodes[i]
            -- print('btn name-->', node:getName(), 'x:', x)
            if x then
                if time and time > 0 then
                    local y = node:getPositionY()
                    node:stopActionByTag(0xf1)
                    local pAc = node:runAction(cc.MoveTo:create(time, cc.p(x, y)))
                    local _ = pAc and pAc:setTag(0xf1)
                else
                    node:setPositionX(x)
                end
            end
        end
    else
        for i=1,#rNodes do
            local node = rNodes[i]
            local y = poses[i]
            if y then
                -- print('btn name-->', node:getName(), 'y:', y)
                if time and time > 0 then
                    local x = node:getPositionX()
                    node:stopActionByTag(0xf1)
                    local pAc =node:runAction(cc.MoveTo:create(time, cc.p(x, y)))
                    local _ = pAc and pAc:setTag(0xf1)
                else
                    node:setPositionY(y)
                end
            end
        end
    end
    return allSize
end
--[[
计算排列位置
parent:Node父节点
nodes:{Node}需要排列的节点
space:{Number}间隔 [1]-中间间隔 [2]-左间隔/顶间隔 [3]-右间隔/底间隔
align:Number排列方式Vec2 - 1:从左到右 2:从右到左 3:水平居中 4:从上到下 5:从下到上 6:垂直居中
]]
function Utils:GetAlignPos(parent, nodes, space, align, isChangeParentSize)
    if parent == nil or nodes == nil or #nodes == 0 or space == nil or align == nil then
        return
    end
    local space_mid = space[1] or 0
    local space_leftTop = space[2] or 0
    local space_rightBtm = space[3] or 0
    local center = cc.p(parent:getContentSize().width/2, parent:getContentSize().height/2)
    local count = #nodes
    -----------------------------------------------------------------------------
    local allSize = space_leftTop + space_rightBtm
    for i=1,#nodes do
        local node = nodes[i]
        if node:isVisible() and node:getOpacity() > 0 then
            if align < 4 then --水平
                allSize = allSize + node:getContentSize().width*node:getScaleX() + space_mid
            else --垂直
                allSize = allSize + node:getContentSize().height*node:getScaleY() + space_mid
            end
        end
    end
    if isChangeParentSize then
        if align < 4 then
            center.x = allSize/2
        else
            center.y = allSize/2
        end
    end
    allSize = allSize - space_mid
    -- print("allSize-->", allSize)
    -----------------------------------------------------------------------------
    local start = 0
    if align == 1 then
        start = space_leftTop
    elseif align == 2 then
        start = center.x*2 - space_rightBtm
    elseif align == 3 or align == 6 then
        start = center.x - allSize/2 + space_leftTop
    elseif align == 4 then
        start = center.y*2 - space_leftTop
    elseif align == 5 then
        start = space_rightBtm
    elseif align == 6 then
        start = center.y - allSize/2 + space_rightBtm
    end
    -----------------------------------------------------------------------------
    local sIndex = 1
    local fIndex = #nodes
    local step = 1

    local poses,rNodes = {},{}
    if align < 4 then
        for i=sIndex,fIndex,step do
            local node = nodes[i]
            local nodeSize = node:getContentSize()
            local anchor = node:getAnchorPoint()
            local scaleX = node:getScaleX()
            local x = nil
            if align == 2  then
                x = start - ((1-anchor.x) * nodeSize.width * scaleX)
            else
                x = start + (anchor.x * nodeSize.width * scaleX)                
            end
            -- print('btn name-->', node:getName(), 'x:', x)
            if x then
                table.insert(poses, x)
                table.insert(rNodes, node)
                if node:isVisible() and node:getOpacity() > 0 then
                    if align == 2  then
                        start = start - nodeSize.width * scaleX - space_mid
                    else
                        start = start + nodeSize.width * scaleX + space_mid             
                    end
                end
            end
        end
    else
        for i=sIndex,fIndex,step do
            local node = nodes[i]
            local nodeSize = node:getContentSize()
            local anchor = node:getAnchorPoint()
            local scaleY = node:getScaleY()
            local y = nil
            if align == 4 then
                y = start - (1-anchor.y) * nodeSize.height * scaleY
            else
                y = start + anchor.y * nodeSize.height * scaleY
            end
            if y then
                -- print('btn name-->', node:getName(), 'y:', y)
                table.insert(poses, y)
                table.insert(rNodes, node)
                if node:isVisible() and node:getOpacity() > 0 then
                    if align == 4 then
                        start = start - nodeSize.height * scaleY - space_mid
                    else
                        start = start + nodeSize.height * scaleY + space_mid
                    end
                end
            end
        end
    end
    return rNodes,poses,allSize,center
end

--[[
获取npcIcon资源
@param1:npcId npcid
@param2:resType 资源类型 AppDef.HeadIconResType = {
                            Body = 1,--半身像
                            Circel = 2,--圆形头像
                            Square = 3,--方形头像
                            }
]]
function Utils:GetNPCIconRes(npcId, resType)
    local strBody = "res2/Npc_Bust/%d.png"
    local strCircel = "res2/Npc_Bust/%d_touxiang.png"
    local strSquare = "res2/Npc_Bust/%d_tou.png"
    if resType == AppDef.HeadIconResType.Body then
        return string.format(strBody,npcId)
    elseif resType == AppDef.HeadIconResType.Circel then
        return string.format(strCircel,npcId)
    elseif resType == AppDef.HeadIconResType.Square then
        return string.format(strSquare,npcId)
    end
end

--[[
获取怪物Icon资源
@param1:monsterId 怪物id
@param2:resType 资源类型 AppDef.HeadIconResType = {
                            Body = 1,--半身像
                            Circel = 2,--圆形头像
                            Square = 3,--方形头像
                            }
]]
function Utils:GetMonsterIconRes(monsterId, resType)
    local strBody = "res2/Monster_Bust/%d.png"
    local strCircel = "res2/Monster_Bust/%d_touxiang.png"
    local strSquare = "res2/Monster_Bust/%d_tou.png"
    if resType == AppDef.HeadIconResType.Body then
        return string.format(strBody,monsterId)
    elseif resType == AppDef.HeadIconResType.Circel then
        return string.format(strCircel,monsterId)
    elseif resType == AppDef.HeadIconResType.Square then
        return string.format(strSquare,monsterId)
    end
end

--[[
获取怪物Icon资源
@param1:heroPro 英雄职业
@param2:resType 资源类型 AppDef.HeadIconResType = {
                            Body = 1,--半身像
                            Circel = 2,--圆形头像
                            Square = 3,--方形头像
                            }
]]
function Utils:GetHeroIconRes(heroPro, resType)
    heroPro = Utils:CheckHeadId(heroPro)
    local strBody = "res2/Role_Bust/%d.png"
    local strCircel = "res2/Role_Bust/%d_touxiang.png"
    local strSquare = "res2/Role_Bust/%d_tou.png"
    if resType == AppDef.HeadIconResType.Body then
        return string.format(strBody,heroPro)
    elseif resType == AppDef.HeadIconResType.Circel then
        return string.format(strCircel,heroPro)
    elseif resType == AppDef.HeadIconResType.Square then
        return string.format(strSquare,heroPro)
    end
end

--[[
获取坐骑Icon资源
@param1:horseId 坐骑id
@param2:resType 资源类型 AppDef.HeadIconResType = {
                            Body = 1,--半身像
                            Circel = 2,--圆形头像
                            Square = 3,--方形头像
                            }
]]
function Utils:GetHorseIconRes(horseId, resType)
    local strBody = "res2/Horse_Bust/%d.png"
    local strCircel = "res2/Horse_Bust/%d_touxiang.png"
    local strSquare = "res2/Horse_Bust/%d_tou.png"
    if resType == AppDef.HeadIconResType.Body then
        return string.format(strBody,horseId)
    elseif resType == AppDef.HeadIconResType.Circel then
        return string.format(strCircel,horseId)
    elseif resType == AppDef.HeadIconResType.Square then
        return string.format(strSquare,horseId)
    end
end

--[[
获取神器Icon资源
@param1:shenqiId 神器id
@param2:resType 资源类型 AppDef.HeadIconResType = {
                            Body = 1,--半身像
                            Circel = 2,--圆形头像
                            Square = 3,--方形头像
                            }
]]
function Utils:GetArtifactIconRes(shenqiId, resType)
    local strBody = "res2/Artifact_Bust/%d.png"
    local strCircel = "res2/Artifact_Bust/%d_touxiang.png"
    local strSquare = "res2/Artifact_Bust/%d_tou.png"
    if resType == AppDef.HeadIconResType.Body then
        return string.format(strBody,shenqiId)
    elseif resType == AppDef.HeadIconResType.Circel then
        return string.format(strCircel,shenqiId)
    elseif resType == AppDef.HeadIconResType.Square then
        return string.format(strSquare,shenqiId)
    end
end

--[[
获取翅膀Icon资源
@param1:wingId 翅膀id
@param2:resType 资源类型 AppDef.HeadIconResType = {
                            Body = 1,--半身像
                            Circel = 2,--圆形头像
                            Square = 3,--方形头像
                            }
]]
function Utils:GetWingsIconRes(wingId, resType)
    local strBody = "res2/Wing_Bust/%d.png"
    local strCircel = "res2/Wing_Bust/%d_touxiang.png"
    local strSquare = "res2/Wing_Bust/%d_tou.png"
    if resType == AppDef.HeadIconResType.Body then
        return string.format(strBody,wingId)
    elseif resType == AppDef.HeadIconResType.Circel then
        return string.format(strCircel,wingId)
    elseif resType == AppDef.HeadIconResType.Square then
        return string.format(strSquare,wingId)
    end
end


--[[
显示属性名字和值
@param1:attrTypeLabel 属性显示Label
@param2:attyType 属性类型
@param3:attrValueLabel 属性对应值Label
@param4:attyValueType 属性值
@param5:ratio 是否显示比率，默认nil为false
]]
function Utils:ShowAttrLabel(attrTypeLabel, attyType, attrValueLabel, attyValueType, ratio)
    ratio = ratio or false
    local attrData = LDataConstMgr:GetAttrConfigData(attyType)
    attrTypeLabel:setString(attrData.attrName .. "：")
    if ratio then
        Utils:SafeSetString(attrValueLabel,"" .. attyValueType .. "%")
        --attrValueLabel:setString("" .. attyValueType .. "%")
    else
        Utils:SafeSetString(attrValueLabel, attyValueType)
        --attrValueLabel:setString(attyValueType)
    end
end

--[[
显示属性名字和值
]]
function Utils:ShowAttrLabelSec( attrTypeLabel, attyType, attrValueLabel, attyValueType, ratio )
    -- body
    if attyType > AppDef.EAttrType.EAT_RESISIT_CRIT then
        Utils:ShowAttrLabel(attrTypeLabel, attyType, attrValueLabel, attyValueType / 100, true)
    else
        Utils:ShowAttrLabel(attrTypeLabel, attyType, attrValueLabel, attyValueType, false)
    end
end

function Utils:getAttrStr(attyType, attrValue)
    -- body
    if attrValue == nil then
        return GUITips.RSI_GS_TIP16
    end
    local attrData = LDataConstMgr:GetAttrConfigData(attyType)
    if attrData == nil then
        return tostring(attrValue)
    end

    local ratio = false
    if attyType > AppDef.EAttrType.EAT_RESISIT_CRIT then
        ratio = true
    end
    
    local attrValueStr
    if ratio then
        attrValueStr = tostring(attrValue / 100) .. "%"
    else
        attrValueStr = tostring(attrValue)
    end
    return attrData.attrName .. "+" .. attrValueStr
end

--[[
精确倒计时
@param1:pNode 依附的节点，如果没有就使用Director的
@param2:handler 回调（function(dt:Number)end）
@param3:interval 间隔
@param4:paused 是否允许暂停
]]
function Utils:schedule(pNode, handler, interval, paused)
    if handler == nil or interval == nil then
        return nil
    end
    -- local pScheduler = nil
    -- if pNode == nil then
    --     pScheduler = cc.Director:getInstance():getScheduler()
    -- else
    --     pScheduler = pNode:getScheduler()
    -- end
    -- return pScheduler:scheduleScriptFunc(handler, interval, paused or false)
    local TimerCenter = require("Common.TimerCenter")
    return TimerCenter:getInstance():schedule(handler, interval)
end

--[[
关闭倒计时
@param1:pNode 依附的节点，如果没有就使用Director的
@param2:scheduleScriptEntryID
]]
function Utils:unschedule(pNode, scheduleScriptEntryID)
    if scheduleScriptEntryID == nil then
        return
    end
    -- local pScheduler = nil
    -- if pNode == nil then
    --     pScheduler = cc.Director:getInstance():getScheduler()
    -- else
    --     pScheduler = pNode:getScheduler()
    -- end
    -- pScheduler:unscheduleScriptEntry(scheduleScriptEntryID)
    local TimerCenter = require("Common.TimerCenter")
    TimerCenter:getInstance():unschedule(scheduleScriptEntryID)
end
--[[
延时回调
@param1:handler 回调（function(dt:Number)end）
@param3:interval 间隔
]]
function Utils:scheduleOnce(handler, interval)
    if handler == nil or interval == nil then
        return nil
    end
    local TimerCenter = require("Common.TimerCenter")
    return TimerCenter:getInstance():scheduleOnce(handler, interval)
end

function Utils:unscheduleOnce(scheduleID)
    if scheduleID == nil then
        return
    end
    local TimerCenter = require("Common.TimerCenter")
    TimerCenter:getInstance():unschedule(scheduleID)
end

--[[
子节点的显示控制
]]
function Utils:setVisible(pNode, name, visible)
    local child = pNode:getChildByName(name)
    if child ~= nil then
        child:setVisible(false)
    end
end
--[[
根据名称深路径查找子节点
@param1:rootNode 根节点路径
@param2:path 名称路径，以/分割
]]
function Utils:FindNodeByName(rootNode, path)
    local function _FindNodeByName(pNode, nameVec, idx)
        idx = idx or 1
        if pNode == nil then
            return nil
        end
        if #nameVec < 1 then
            return nil
        end
        local pSubNode = pNode:getChildByName(nameVec[idx])
        if #nameVec == idx then
            return pSubNode
        else
            return _FindNodeByName(pSubNode, nameVec, idx + 1)
        end
    end
    if string.find(path, '/') then
        local vec = string.split(path, '/')
        return _FindNodeByName(rootNode, vec)
    else
        return rootNode:getChildByName(path)
    end
end
--[[
根据功能模块ID检查模块是否未开启
@param1:functionId 功能模块ID
]]
function Utils:CheckModelNotOpened(functionId, notShowTip)
    local PreViewCheckControl = require("View.PreView.PreViewCheckControl")
    local checkId = functionId
    if functionId == AppDef.EActivityID.EAID_QIANNENGCOPY then
        checkId = AppDef.EModuleID.EMID_FUBEN
    end
    local isOpened,limitType,limitValue = PreViewCheckControl.isMeetCompleteCondition(checkId)

    if not isOpened and (limitType == nil or limitValue == nil) and not notShowTip then
        --Utils:ShowScrollTips(string.format(GUITips.UI_function_Open_tips, functionId))
        return false
    end

    if (not isOpened) and (not Utils:ToBool(notShowTip)) and limitType and limitType > 0 and limitValue then
        if limitType == 1 and functionId ~= AppDef.EModuleID.EMID_FIGHT_DOUBLE then--等级开启
            local cfg = LDataConstMgr:GetFunctionLevelData(checkId)
            if cfg and #cfg.unopen_tips > 0 then
                Utils:ShowScrollTips(cfg.unopen_tips,false)
            else
                Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2, limitValue))
            end
            
        else
            local cfg = LDataConstMgr:GetFunctionLevelData(checkId)
            if cfg and cfg.unopen_tips and #cfg.unopen_tips > 0 then
                Utils:ShowScrollTips(cfg.unopen_tips,false)
            end
        end
    end
    return (not isOpened)
end

function Utils:getFucnOpenLevel( funcID )
    -- body
    local config = LDataConstMgr:GetFunctionLevelData(funcID)
    local limitValue = 0
    if config and config.open_condition and #config.open_condition > 0 then
        if config.open_condition[1][1] == 1 then
            limitValue = config.open_condition[1][2]
        end
    end
    return limitValue
end

function Utils:getAttrName(attrType)
    -- body
    local attrConfig = JsonConfig.m_AttrType.getDefByID(attrType)
    return attrConfig.attrName
end

--获取属性和名字


function Utils:getAttrNameAndValue(attrType,value)

    if attrType>=10 then
        value=tostring(value/100).."%"
    end

    local attrConfig = JsonConfig.m_AttrType.getDefByID(attrType)
    return attrConfig.attrName,tostring(value)
    -- body
end
--获取属性和名字


function Utils:getAttrNameAndValue1(attrType,value)

    if attrType>=10 then
        value=tostring(value).."%"
    end

    local attrConfig = JsonConfig.m_AttrType.getDefByID(attrType)
    return attrConfig.attrName,tostring(value)
    -- body
end




--[[
注册引导步骤
@param1:stepId 引导步骤Id
@param2:callback 引导点击回调
@param3:pNode   引导点击节点 
@param4:pos   引导点击位置，与 pNode互斥
@param5:isCheck   是否立即检测引导 
]]
function Utils:RegisterGuide(stepId, pNode, callback, pos, isCheck, isImmediately)
    if stepId == nil then
        return
    end
    local data = LDataConstMgr:GetGuideData(stepId)
    if data == nil then
        return
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIGuideEvent.RegisterStep, {stepId=stepId,pNode=pNode,callback=callback,pos=pos})
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    if isCheck then
        Utils:CheckGuide(stepId, true)
    end
end
--[[
检测引导步骤
@param1:stepId 引导步骤Id
]]
function Utils:CheckGuide(stepId, isImmediately)
    LGameMsg.m_baseMsgWithOne:Change(LUIGuideEvent.CheckGuideStep, {stepId,Utils:ToBool(isImmediately)})
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--关闭升级界面引导处理
function Utils:CheckLvGuide()
    local myLv = LRoleDataMgr.MyHeroInfo.level
    if myLv == 2 then
        --Utils:scheduleOnce(function()
            Utils:CheckGuide(GuideDef.StepId.Guide_FuBen1,true)
        --end, 1)
    elseif myLv == 3 then
        Utils:CheckGuide(GuideDef.StepId.Guide_Pet,true)
    elseif myLv == 4 then
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen2,true)
    elseif myLv == 5 then
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen3,true)
    elseif myLv == 6 then
        Utils:CheckGuide(GuideDef.StepId.Guide_Equip,true)
    elseif myLv == 8 or myLv == 9 then
        Utils:CheckGuide(GuideDef.StepId.Guide_Pet1,true)
    elseif myLv >= 10 and myLv < 15 then
        Utils:CheckGuide(GuideDef.StepId.Guide_Arena,true)
    elseif myLv == 15 then
        Utils:CheckGuide(GuideDef.StepId.Guide_XunBao,true)
    elseif myLv == 35 then
        Utils:CheckGuide(GuideDef.StepId.Guide_Tujian_1,true)
    end
end

--[[
播放神将音效
@param1:petId 神将Id
]]
function Utils:PlayPetAudioEffect(petId)
    local curPet = LDataConstMgr:GetPetData(petId)
    if curPet and string.len(curPet.cv) > 0 then
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, curPet.cv)
        LUIManager:SendMsg(LGameMsg.m_audioMsg)
    end
end


function Utils:CheckSkillLevelUp(pos, level, noTips)
    local skill = LDataConstMgr:GetSkillLvUpCost(pos, level)
    if skill == nil then
        if noTips then return false end
        Utils:ShowScrollTips(GUITips.RSI_Skill_Level_Err_Full)
        return false
    end

    local unLock = LRoleDataMgr.HeroSkills[pos]
    if unLock == nil then return false end -- 未解锁

    if LRoleDataMgr.MyHeroInfo.level < skill.learn_level then
        if noTips then return false end
        Utils:ShowScrollTips(GUITips.RSI_Skill_Level_Err_Level)
        return false
    end
    for k,v in pairs(skill.cost) do
        if not LRoleDataMgr.MyHeroInfo:GetDetailData():SkillCheckCost(v[1], v[2], noTips) then
            return false
        end
    end
    return true
end

function Utils:OpenInstance(ind)
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FUBEN) then 
        return
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Instances.InstancesMainUI",AppDef.UIType.FirstClassLayer, ind)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--打开排行榜界面
function Utils:OpenRankUI(funId)

    Utils:OpenFunction(funId)

    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.RankUI",AppDef.UIType.PopFirstClassLayer, ind)
    -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--血战预测排名查询
function Utils:QueryXueCurRank(skip)
    skip = skip or 0
    local data = LActivityManager:GetXueZhanData()
    local sign = false
    local time = os.time()
    if skip == 1 or  data.m_forecastTime == 0 or (time - data.m_forecastTime) > 300 then
        data.m_forecastTime = os.time()
        sign = true
    end
    if sign then
        LuaNetSendMsg:QueryXueZhanInfo(17)
    end
end

--英勇试炼(血战) 信息返回后弹框处理
function Utils:OpenXueZhanUI()
    local data = LActivityManager:GetXueZhanData()
    if data.m_enemyZhenId[1] == 0 then
        --直接打开主界面
        Utils:InitUI("XueZhan.XueZhanMainUI",AppDef.UIType.FirstClassLayer)
    else
        if data.m_state == 3 or data.m_state == 4 then
            if data.m_cnt > 0 then
                LuaNetSendMsg:QueryXueZhanInfo(6)
            else
                Utils:InitUI("XueZhan.XueZhanMainUI",AppDef.UIType.FirstClassLayer)
            end
            return
        elseif data.m_state == 2 then
            if data.m_reviveCnt > 0 then
                LuaNetSendMsg:SendXueZhanReviveReq(1)
            elseif data.m_cnt > 0 then
                LuaNetSendMsg:QueryXueZhanInfo(6)
                return
            end
        end
        --打开章节界面
        Utils:InitUI("XueZhan.XueZhanChapterUI",AppDef.UIType.FirstClassLayer)
    end
end

--英勇试炼(血战) 战斗结束后 弹窗处理
function Utils:OpenXueZhanReward()
    local function closeFun()
        Utils:OpenXueZhanReward()
    end

    local data = LActivityManager:GetXueZhanData()
    if #data.m_items1 > 0 then
        --打开首通界面
        Utils:OpenRewardBox(GUITips.RSI_XUEZHAN_TIP14,data.m_items1,true,GUITips.RSI_GS_TIP_RECOVERY_SURE,closeFun,closeFun)
        data.m_items1 = {}
        return
    end
   if data.m_bufs ~= nil and #data.m_bufs > 0 then
        --打开buff选择界面
        Utils:InitUI("XueZhan.XueZhanAttrSelectUI",AppDef.UIType.PopWindow,10)
        return
    end
    if #data.m_items2 > 0 then
        --print("222222222222222222222222")
        local function fun()
            --打开五关奖励界面
            Utils:OpenRewardBox(GUITips.RSI_XUEZHAN_TIP13,data.m_items2,true,GUITips.RSI_GS_TIP_RECOVERY_SURE,closeFun,closeFun)
            --Utils:InitUI("XueZhan.XueZhanGiftBoxUI",AppDef.UIType.PopWindow)
            data.m_items2 = {}
        end
        Utils:scheduleOnce(fun, 0.1)  
        return
    end
    if data.m_levelId > 1 and data.m_levelId %100 == 1 and data.m_levelId > data.m_sweepLevelId then
        Utils:ShowXueZhanDialog(nil,nil,-1)
    end
end

--血战 扫荡 Buff选择弹窗
function Utils:OpenXueZhanSweepBuffUI()
local data = LActivityManager:GetXueZhanData()
    if data.m_sweepInfo == nil or data.m_sweepInfo.bufs == nil or #data.m_sweepInfo.bufs < 3 then
        return
    end
    --打开buff选择界面
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "XueZhan.XueZhanAttrSelectUI",AppDef.UIType.PopWindow,14)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--英勇试炼(血战) 点击开始后 前面章弹窗处理
function Utils:OpenXueZhanAyerReward()
    local function closeFun()
        --print("2222222222222222")
        Utils:OpenXueZhanAyerReward()
    end

    local data = LActivityManager:GetXueZhanData()
    -- print("#data.m_rewards",#data.m_rewards)
    if data.m_rewards == nil or #data.m_rewards == 0 then
        return
    end
    dump(data.m_rewards)
    if data.m_rewards[1] ~= nil then
        local function fun()
            data.m_rewardNum = data.m_rewardNum+1
            local str = string.format(GUITips.RSI_FUBENMAP_RES17,data.m_rewardNum).." "..GUITips.RSI_XUEZHAN_TIP30
            Utils:OpenRewardBox(str,data.m_rewards[1],true,GUITips.RSI_GS_TIP_RECOVERY_SURE,closeFun,closeFun)
            table.remove(data.m_rewards,1)
        end
        Utils:scheduleOnce(fun, 0.2)  
    end
end

--奖励宝箱弹窗通用
--@title 标题
--@rewards 奖励列表（id,0,num)结构
--@callback 确认按钮回调
--@isShowBtn 确认按钮是否显示，false时显示文字 
--@tips okIsShow为false时,显示文字为nil则显示默认(RSI_BOX_TIP1);okIsShow为true时,为按钮文字(RSI_GS_TIP_RECOVERY_DRAW)
--@callback 领取按钮返回
--@closedCallBack --关闭按钮返回
function Utils:OpenRewardBox(title,rewards,isShowBtn,tips,callback,closedCallBack)
    rewards = rewards or {}
    local value = {}
    value.isShowBtn = true
    if isShowBtn == nil or not isShowBtn then
        value.isShowBtn = false
    end
    value.closedCallBack = closedCallBack
    value.callback = callback
    value.title = title or ""
    value.tips = tips or GUITips.RSI_BOX_TIP1
    value.rewards = rewards
    -- for i=1,#rewards do
    --     local item = {}
    --     item.num = 1
    --     if rewards[i][1] == AppDef.RewardItem.RD_ITEM_EQUIP then
    --         item.id = rewards[i][2]
    --         item.type = 1--type=1是装备表
    --     elseif rewards[i][1] == AppDef.RewardItem.RD_ITEM_PET then
    --         item.id = rewards[i][2]
    --         item.type = 2--type=1是宠物
    --     elseif rewards[i][1] == AppDef.RewardItem.RD_ITEM_FABAO then
    --         item.id = rewards[i][2]
    --         item.type = 3--type=1是法宝
    --     else
    --         item.id = rewards[i][1]
    --         item.type = 0--type=0是道具表
    --         item.num = rewards[i][3]
    --     end
    --     table.insert(value.rewards,item)
    -- end
    Utils:InitUI("Common.RewardGetUI",AppDef.UIType.PopWindow, value)
end

function Utils:OpenRewardBoxFromConfig(title,rewards,isShowBtn,tips,callback,closedCallBack)
    -- local tmpRewards = {}
    -- --转从服务器格式
    -- for i = 1, #rewards do

    --     if rewards[i][1] == AppDef.RewardItem.RD_ITEM_EQUIP 
    --         or rewards[i][1] == AppDef.RewardItem.RD_ITEM_PET
    --         or rewards[i][1] == AppDef.RewardItem.RD_ITEM_FABAO then
    --         table.insert(tmpRewards,{rewards[i][1],rewards[i][3],rewards[i][2]})
    --     else
    --         table.insert(tmpRewards,{rewards[i][1],rewards[i][2],rewards[i][3]})
    --     end
    -- end
    -- Utils:OpenRewardBox(title,tmpRewards,isShowBtn,tips,callback,closedCallBack)

    --[[
    服务器传过来的格式现在和配置表里面的格式统一了
    ]]
    Utils:OpenRewardBox(title,rewards,isShowBtn,tips,callback,closedCallBack)
end

--打开兑换界面
--@itemId 道具id
function Utils:OpenExchangeUI(itemId)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.ItemExchangeUI",AppDef.UIType.PopWindow, itemId)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--打开购买\使用(1)界面
--@itemId 道具id
--@sType 商店类型
--@vipFieldName vip表字段名
function Utils:OpenUseUI(itemId,sType)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.ItemUseUI",AppDef.UIType.PopWindow, {itemId,sType})
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--打开购买(2)界面
--@param shopId 商店id
--@param buyCnt 剩余次数,nextVip 增加次数的下个vip等级,addCnt 增加的次数 ,curCnt 已经购买的次数
--@param shopType 商店类型 
function Utils:OpenBuyUI(shopId,buyCnt,nextVip,addCnt,curCnt)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.ItemBuyUI",AppDef.UIType.PopWindow, {shopId,buyCnt,nextVip,addCnt,curCnt})
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end


--打开数字输入界面
function Utils:ShowNumInputUI(maxNum,callback)
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowNumInputUI, {maxNum,callback})
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
打开Function_Level.xlsx表中各个模块功能
@param1:functionId function_id
@param2:noCheckOpen 是否检查开启
@param3:noTips 是否显示未开启tips
]]
function Utils:OpenFunction(functionId, sub, noCheckOpen, noTips, isInBattle)
    noCheckOpen = Utils:ToBool(noCheckOpen)
    noTips = Utils:ToBool(noTips)
    -- print("noCheckOpen",noCheckOpen)
    if not noCheckOpen then
        --暂时注释
        if Utils:CheckModelNotOpened(functionId, noTips) then
            return false
        end
    end
    local cfg = AppDef.FuncUI[functionId]
    if cfg == nil or cfg.lua == nil or #(cfg.lua) == 0 then
        if functionId == AppDef.EModuleID.EMID_HUODONG then
            local datas = LRechargeDataMgr:GetWelFareActivityData()
            if datas == nil or #datas == 0 then
                Utils:ShowScrollTips(GUITips.RSI_WACT_TIP11)
                return
            end
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "WelfareActivity.WelfareActivityUI", AppDef.UIType.Chat, sub)
            LUIManager:SendMsg(LGameMsg.m_initUIMsg)
        elseif functionId == AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG then
            if LRoleDataMgr.m_firstRechargeState == 0 then
                LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Recharge.FirstRechargeUI",AppDef.UIType.SpecialLayer)
                LUIManager:SendMsg(LGameMsg.m_initUIMsg)
                LuaNetSendMsg:QueryKaifuHuodong(9,2)
            elseif LRoleDataMgr.m_secondRechargeState == 0 then
                LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Recharge.FirstRechargeUI",AppDef.UIType.SpecialLayer)
                LUIManager:SendMsg(LGameMsg.m_initUIMsg)
                LuaNetSendMsg:QueryKaifuHuodong(42,2)
            end
        elseif functionId == AppDef.EModuleID.EMID_KAPAI_WF_XZ then
            LuaNetSendMsg:QueryXueZhanInfo(1)
        else
            error(string.format("AppDef.FuncUI[%d] not exist!!!!", functionId))
        end
        return true
    end
    if functionId == AppDef.EModuleID.EMID_SHENJIANG then
        if #LRoleDataMgr.Pet.petlist == 0 then
            Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
            return false
        end
    end
    local subPage = sub or cfg.sub
    if isInBattle == true then
        if cfg.ind then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, cfg.lua, cfg.ind, subPage)
        else
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, cfg.lua, AppDef.UIType.FirstClassLayer, subPage)
        end
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    else
        if cfg.ind then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, cfg.lua, cfg.ind, subPage)
        else
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, cfg.lua, AppDef.UIType.FirstClassLayer, subPage)
        end
        
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    end
    
    return true
end
--[[
判断点是否在三角形内
@param1:pt 判断点
@param2:tr1 三角形的点1
@param3:tr2 三角形的点2
@param4:tr3 三角形的点3
]]
function Utils:IsInTriangle(pt, tr1, tr2, tr3)
    local function calcArea(p1, p2, p3)
        return math.abs(cc.pCross(cc.pSub(p2, p1), cc.pSub(p3, p1))/2)
    end
    local tArea = calcArea(tr1, tr2, tr3) - calcArea(pt, tr1, tr2)
    if tArea < 0 then
        return false
    end
    tArea = tArea - calcArea(pt, tr1, tr3)
    if tArea < 0 then
        return false
    end
    tArea = tArea - calcArea(pt, tr2, tr3)
    if tArea < 0 then
        return false
    end
    return true
end
--[[
判断点是否在多边形内
@param1:pt 判断点
@param2:points 多边形顶点列表
]]
function Utils:PointInArea(pt, points)
    if points == nil or #points <= 2 then
        return false
    end
    local count = #points
    for i=1,count-2 do
        local tr1 = points[1]
        local tr2 = points[i+1]
        local tr3 = points[i+2]
        if Utils:IsInTriangle(pt, tr1, tr2, tr3) then
            return true
        end
    end
    return false
end
--[[
获取红点显示状态
@param1:id 红点的ID
]]
function Utils:GetRedDotState(id)
    local ret = {id=id, isShow=false}
    LGameMsg.m_baseMsgWithOne:Change(LUIRedDotEvent.GetRedDotState, ret)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    return ret.isShow
end
--[[
设置红点显示状态
@param1:id 红点的ID
@param2:isShow 是否显示
]]
function Utils:SetRedDotState(id, isShow)
    Utils:SendMsg(LUIRedDotEvent.SetRedDotState, {id=id, isShow=isShow});
end

function Utils:TestMemery(testFunc1,testFunc2)
    for i = 1,10 do
        collectgarbage("collect")
    end
    local cnt = collectgarbage("count")
    -- print("初始内存：",cnt)
    for i = 1,100 do
        testFunc1()
        if testFunc2 then
            testFunc2()
        end
    end
    for i = 1,10 do
        collectgarbage("collect")
    end
    cnt = collectgarbage("count")
    -- print("现在内存：",cnt)
end
--[[
显示等待
@param1:key
@param2:waitMsg
@param3:autoClearTime
]]
function Utils:ShowWaiting(key, waitMsg, autoClearTime)
    if key == nil then
        return
    end
    local waitAniData = {key = key, waitMsg = waitMsg or "", autoClearTime = autoClearTime or 0}
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end
--[[
移除等待
]]
function Utils:RemoveWaiting(key)
    if key == nil then
        return
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ClearWait, key)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function Utils:SafeLoadTexture(img, filePath, fileType)
    local isSuccess = true
    local function TexErr()
        isSuccess = false   
    end
    local function showImg()
        img:loadTexture(filePath, fileType)
    end
    xpcall(showImg,TexErr)
    return isSuccess
end

--异步加载图片
function Utils:AsyncLoadImg(curImg,filepath,callback)
    if curImg == nil or filepath == nil then 
        return false 
    end

    local function defaultCallback(texture)
        --print("defaultCallback:filepath=",filepath)
        if texture == nil then
            return
        end

        if callback then
            callback(texture)
        else
            local function TexErr()
                
            end
            local function showImg()
                curImg:initWithTexture(texture)
            end
            xpcall(showImg,TexErr)
            
            
        end
        --curImg:release()
    end
    --curImg:retain()
    --print("AsyncLoadImg:filepath=",filepath)
    LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, filepath, defaultCallback,curImg)
    LAssetManager:SendMsg(LGameMsg.m_resMsg)
    -- local textureCache = cc.Director:getInstance():getTextureCache()
    -- textureCache:addImageAsync(filepath, callback)
    return true
end

--异步加载图片,关闭时处理unbindImageAsync
function Utils:UnbindAsyncImg(filepathKey)
    if filepathKey == nil then 
        return 
    end

    LGameMsg.m_resMsg:Change(LResEvent.UnLoadImgSync, filepathKey)
    LAssetManager:SendMsg(LGameMsg.m_resMsg)
    -- local textureCache = cc.Director:getInstance():getTextureCache()
    -- textureCache:unbindImageAsync(filepathKey)
end

--异步删除图片组,关闭时处理unbindImageAsync
function Utils:UnbindAsyncImgArr( filepathArr )
    -- body
    if filepathKey == nil then 
        return 
    end

    for i = 1, #filepathArr do
        self:UnbindAsyncImg(filepathArr[i])
    end
end


--[[
播放音效
@param1:key 主键
@param2:idKey id键
@param3:id id/索引
@param4:isIndex 是否是索引
@excemple Utils:PlayEffect("MonsterDeathBGM", "picId", 401, false)
@excemple Utils:PlayEffect("HeroBGM", nil, 1, true)
]]
function Utils:PlayEffect(key, idKey, id, isIndex, isLong)
    if key == nil or id == nil then
        return
    end
    idKey = idKey or "id"
    local cfg = AppDef[key]
    if isIndex then
        if id <= #cfg and cfg[id] then
            if isLong then
                LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, cfg[id])
            else
                LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, cfg[id])
            end
            LUIManager:SendMsg(LGameMsg.m_audioMsg)
        end
    else
        for k,v in pairs(cfg) do
            if v[idKey] and v[idKey] == id and v.bgm then
                if isLong then
                    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, v.bgm)
                else
                    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, v.bgm)
                end
                LUIManager:SendMsg(LGameMsg.m_audioMsg)
                break
            end
        end
    end
end
--[[播放音效]]
function Utils:PlayKPEffect(name)
    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, name)
    LUIManager:SendMsg(LGameMsg.m_audioMsg)
end

function Utils:SendMsg(msgId, data, isNew)
    if msgId == nil then
        return
    end
    isNew = true
    local pMsg = nil
    if data ~= nil then
        if isNew then
            pMsg = LUIMsg1:New()
        else
            pMsg = LGameMsg.m_baseMsgWithOne
        end
        pMsg:Change(msgId, data)
    else
        if isNew then
            pMsg = LMsgBase:New()
        else
            pMsg = LGameMsg.m_baseMsg
        end
        pMsg:ChangeEventId(msgId)
    end
    local _ = pMsg and LUIManager:SendMsg(pMsg)
end

function Utils:FilterLimitedMsg(msg)
    -- body
    local forbiddenWordArr = AppDef.LllegalCharacter
--    print("forbiddenWordArr", #forbiddenWordArr)
    for i = 1, #forbiddenWordArr do
--        print("show msg", msg, forbiddenWordArr[i])
        local q, w = string.find(msg, forbiddenWordArr[i], 1)
--        print("ssss", q, w)
        if q then
            msg = string.gsub(msg, forbiddenWordArr[i], "***")
        end
    end

    return msg
end

function Utils:FilterAdLimitedMsg(msg)
	--先过滤非法字符串
	msg = self:FilterLimitedMsg(msg)
	--屏蔽广告字
	local forbiddenWordArr2 = AppDef.LllegalCharacter2
	for i = 1, #forbiddenWordArr2 do
		local q, w = string.find(msg, forbiddenWordArr2[i], 1)
		if q then
            return true
        end
	end

	return false
end

function Utils:IsLimitedMsg(msg)
    -- body
    local forbiddenWordArr = AppDef.LllegalCharacter
    for i = 1, #forbiddenWordArr do
        local q, w = string.find(msg, forbiddenWordArr[i], 1)
        if q then
            return true
        end
    end
    return false
end

--在引导中
function Utils:IsInGuide()
    local ret = {}
    ret.script = "Guide.GuideLayer"
    Utils:SendMsg(LUILogicEvent.CheckLayerExist, ret)
    return ret.isExist
end


function Utils:getAngleByPos(p1, p2)
    -- body
    local p = {}
    p.x = p2.x - p1.x
    p.y = p2.y - p1.y
    local r = math.atan2(p.y, p.x)*180 / math.pi
    return r
end

function Utils:SortTaskGiftData(datas)
    if datas == nil then
        return nil
    end
    local function _Sort(list)
        local missions = list.missions
        local wcList = {}--完成
        local jxList = {}--进行
        local wjsList = {}--未解锁
        local ywcList = {}--已完成
        for i=1,#missions do
            local missData = missions[i]
            if missData.isFinish then
                table.insert(ywcList, missions[i])
            elseif missData.state == 0 then
                table.insert(wjsList, missions[i])
            elseif missData.state == 1 then
                table.insert(jxList, missions[i])
            elseif missData.state == 2 then
                table.insert(wcList, missions[i])
            end
        end
        list.missions = {}
        table.sort(wcList, function(a, b) return a.missId < b.missId end)
        table.sort(jxList, function(a, b) return a.missId < b.missId end)
        Utils:concatTable(list.missions, wcList, jxList, wjsList, ywcList)
    end
    for i=1,#datas do
        _Sort(datas[i])
    end
    return datas
end

function Utils:ResetTaskGiftState(datas)
    if datas == nil then
        return nil
    end
    for i=1,#datas do
    end
end

function Utils:CreateAnimModel(iType, iValue, pAnimNode, isBig)
    if iType == AppDef.AwrdItem.AWRD_ITEM_PET then--宠物
        local pAnim = nil
        local cfg = LPetDataMgr:FindPetDataById(iValue)
        local aniType = AppDef.CEnum.ModelAniType.Monster
        if isBig then
            aniType = AppDef.CEnum.ModelAniType.MonsterBig
        end
        if cfg then
            if pAnimNode == nil then
                pAnim = ModelAniNode:create(aniType, 0)
            else
                pAnim = pAnimNode
            end
            -- cfg.pic = 909
            pAnim:InitAni(aniType, cfg.pic)
            pAnim:PlayStand(0)
        end
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then--坐骑
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,iValue,0)
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then--翅膀
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Wing, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,iValue,0,0)
        pAnim:PlayStand(0)
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then--神器
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_MONSTER then--宠物
        local pAnim = nil
        local cfg = LDataConstMgr:GetMonsterData(iValue)
        if cfg then
            if pAnimNode == nil then
                pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
            else
                pAnim = pAnimNode
            end
            pAnim:InitAni(AppDef.CEnum.ModelAniType.Monster, cfg.pic)
            pAnim:PlayStand(0)
        end
        return pAnim
    end
    return nil
end

function Utils:CreateBigRoleModel(modelId,pAnimNode)
    if pAnimNode == nil then
        pAnim = ImodAnim:create()
    else
        pAnim = pAnimNode
    end
    local pngStr = AppDef.GUIRes.Create_Role_Path.."Create_"..modelId
    local aniStr = AppDef.GUIRes.Create_Role_Path.."Create_"..modelId..".ani"
    pAnim:initAnimWithNameSync(pngStr)
    pAnim:PlayNewAction(0, true)
    return pAnim
end

function Utils:UpdateTaskGiftState(missData)
    if missData == nil then
        return false
    end
    missData.state = 0 --0:未解锁 1:未完成 2:可领取
    -- --dump({missData.isFinish, data}, "--------------->")
    if not missData.isFinish then
        local data = LRoleDataMgr.Task:GetTaskById(missData.missId)
        -- if data then
        --     --dump(data.op, "missData.missId--->")
        -- end
        --data.op 3可领奖
        if data and data.op then
            if data.op == 3 then
                missData.state = 2
                return true
            else
                missData.state = 1
            end
            missData.taskData = data
        end
    end
    return false
end

function Utils:OpenGodTree()
    if LRoleDataMgr.Faction.Info.id <= 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP1)
        return
    end
    LuaNetSendMsg:QueryCanBattle(2)
    --设置自动寻路状态
    if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false then
        Utils:ShowScrollTips(GUITips.RSI_TTL_TIP1)
    else
        local canJumpMap = false
        if LRoleDataMgr.MyHeroInfo.level > 25 then--如果不在当前地图则传送
            canJumpMap = true
        end

        --护送任务忽略NPC
        local IsPassNPC = false
        if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 and taskid == 213 then
            IsPassNPC = true
        end
        if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
            canJumpMap = false
        end
        local function AutoPachEndCallback(npcId, npcIdx)
            local BangPaiZoneDef = require('View.BangPaiZone.BangPaiZoneDef')      
            local pMsg = FactionZoneMsg:new(LPlantEvent.PlantEvent, 1, BangPaiZoneDef.OprType.ClickGodTree)
            LUIManager:SendMsg(pMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
			LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
        local endPos = cc.p(2182,546)
        LGameMsg.m_autoPathMsg:ChangeToStart(47, endPos.x, endPos.y, 0, bit.lshift(0,16), true, canJumpMap, AutoPachEndCallback)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function Utils:ScrollToListItem(list, pItem, ind, total, countOfPage, time)
    if list == nil or pItem == nil then
        return
    end
    if ind <= total then
        if ind >= 2 and pItem ~= nil then
            local space = list:getItemsMargin()
            time = time or 0.5
            performWithDelay(list, function(sender)
                if (total-ind) <= countOfPage then
                    list:scrollToPercentHorizontal(100, time, true)
                else
                    local posX = pItem:getPositionX()-space*0.5
                    local diff = list:getInnerContainerSize().width - list:getContentSize().width
                    local persent = posX / diff * 100
                    list:scrollToPercentHorizontal(math.min(persent, 100), time, true)
                end
            end, 1/10)
        end
    end
end

function Utils:GetPetQuality( data )
    -- body
    if data == nil then
        return 0
    end

    if data.baseData == nil then
        return 0
    end

    return data.baseData.quality
end

--折合成一级道具的数量
function Utils:getSynthesisNum(id)  
   local Tempnum = 1
   local list=LDataConstMgr:GetItemCpdList()
      while(true)do
     
        local isHave = false
        for k,v in pairs(list) do
           if v.targetId==id then
             id=k
             Tempnum=v.itemNum*Tempnum
             isHave=true
             break      
           end
        end
        if not isHave then
          break
        end
      end
    return Tempnum
end
--自动合成道具 道具id ，合成道具数量
function Utils:AutoSynthesisProp(itemId,num)--4级3个
   local TotalNum=Utils:getSynthesisNum(itemId)*num --折合成一级道具需要的数量81
   local selfTypePropId = Utils:GetSameTypeProp(itemId) --3级2级1级
   if itemId==selfTypePropId[#selfTypePropId] then
    return
   end
   local MyBagPropNum = {} --背包中每一级折合道具的数量
   local upgreadData = {}  --需要升级的道具和数量
   --local upgreadDataLeastID = 0
   --local upgreadDataLeastNum = 0
   for i=1,#selfTypePropId do  
      local myselfPropNum =LRoleDataMgr.Equip:CountItemNumById(selfTypePropId[i]) --3级4个 2级7个 1级100
      MyBagPropNum[selfTypePropId[i]]=myselfPropNum*Utils:getSynthesisNum(selfTypePropId[i])--36--21--100
   end 
--    --dump(MyBagPropNum,"MyBagPropNum-------->")
   for i=1,#selfTypePropId   do  
      if TotalNum<=MyBagPropNum[selfTypePropId[i]] then--24<21
         upgreadData[selfTypePropId[i]]=TotalNum  --最终确认合成道具值 24
         --upgreadDataLeastID=selfTypePropId[i]
         --upgreadDataLeastNum=TotalNum
         break
      else             
        upgreadData[selfTypePropId[i]]=TotalNum--45
        TotalNum=TotalNum-MyBagPropNum[selfTypePropId[i]]--81-36             36-21       =45-21=24
      end
   end 

  
   --  --dump(upgreadData,"upgreadData-------->")
    for i=#selfTypePropId,1,-1 do
      local data =LDataConstMgr:GetItemCpdData(selfTypePropId[i])
      if upgreadData[selfTypePropId[i]]~= nil then           
         LuaNetSendMsg:QuerySynthesisSpecifiedNumItem(selfTypePropId[i],upgreadData[selfTypePropId[i]]/Utils:getSynthesisNum(data.targetId))
      end
    end

  
end
--获得相同的道具类型
function Utils:GetSameTypeProp(itemId)
     local list=LDataConstMgr:GetItemCpdList()
     local selfTypePropId={} 
     while(true)do
      
        local isHave = false
        for k,v in pairs(list) do
           if v.targetId== itemId then
             table.insert(selfTypePropId,k) 
             itemId=k
             isHave=true
             break      
           end
        end
        if not isHave then
          break
        end
     end
    -- --dump(selfTypePropId,"selfTypePropId-------->")
     return selfTypePropId
end

--自动折合道具判断是否满足升级需求
function Utils:AutoMaticPropSynthesis(itemId,num)   
   local leastPropNum=1 --当前道具  等于   当前道具类型最小的道具  合成需要数量
   local selfTypePropId={} 
   selfTypePropId=Utils:GetSameTypeProp(itemId)
   leastPropNum=Utils:getSynthesisNum(itemId)
--   --dump(selfTypePropId,"AutoMaticPropSynthesis---->")
   local UpgreadNum = num*leastPropNum--当前需要的一级道具的数量 
   local MyLeastPropNum = 0 --折算成最低级道具的数量
   for i=1,#selfTypePropId do  
      local myselfPropNum =LRoleDataMgr.Equip:CountItemNumById(selfTypePropId[i])  
       MyLeastPropNum=MyLeastPropNum+myselfPropNum*Utils:getSynthesisNum(selfTypePropId[i])
   end 
   -- --返回的数据
   local tempdata = {
    isTrue=false,
    num=0
   }
   if UpgreadNum<=MyLeastPropNum then
       tempdata.isTrue= true    
   else
      tempdata.num= UpgreadNum-MyLeastPropNum
   end
   return tempdata
end

--string转Table
function Utils:StrToTable(str)
    --print("StrToTable",str)
    if str == nil or type(str) ~= "string" or #str == 0 then
        return nil
    end
    return loadstring("return "..str)()
end

--Table转String
function Utils:TableToStr(t)
    if t == nil or type(t) ~= 'table'or #t == 0 then return "" end
    local retstr = "{"
    local i = 1
    for k,v in pairs(t) do
        local signal = ","
        if i == 1 then
            signal = ""
        end
        if k == i then
            retstr = retstr..signal..self:ToStringEx(v)
        else
            if type(k) == 'number' or type(k) == "string" then
                retstr = retstr..signal.."["..self:ToStringEx(k).."]="..self:ToStringEx(v)
            else
                retstr = retstr..signal..k.."="..self:ToStringEx(v)
            end
        end
        i = i+1
    end
    retstr = retstr.."}"
    return retstr
end

function Utils:ToStringEx(value)
    if type(value) == "table" then
        return TableToStr(value)
    elseif type(value) == "string" then
        return "\'"..value.."\'"
    else
        return tostring(value)
    end
end

function Utils:InitUI(script, zType, data)
    if script == nil or #script == 0 then
        return
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, script, zType, data)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

function Utils:DeleteUI(script)
    if script == nil or #script == 0 then
        return
    end
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, script)
    LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
end

function Utils:ShowUI(script)
    if script == nil or #script == 0 then
        return
    end

    LGameMsg.m_hideUIMsg:ChangeWithMsgId(LUILogicEvent.ShowUI, script)
    LUIManager:SendMsg(LGameMsg.m_hideUIMsg)
end

function Utils:HideUI(script)
    if script == nil or #script == 0 then
        return
    end

    LGameMsg.m_hideUIMsg:ChangeWithMsgId(LUILogicEvent.HideUI, script)
    LUIManager:SendMsg(LGameMsg.m_hideUIMsg)
end

function Utils:FreeTableUnit(t)
    if t ~= nil and type(t) == "table" then
        for k,v in pairs(t) do
            if k and v then
                t[k] = nil
            end
        end
    end
    t = nil
end

function Utils:FreeTable(...)
    local tbs = {...}
    for i=1,#tbs do
        Utils:FreeTableUnit(tbs[i])
        tbs[i] = nil
    end
end
function Utils:ShowBuffTips(BuffType)  
    local userdata = {}
    if BuffType==AppDef.BuffType.WorldLevel then
        local msgs = {}    
        local msg = {
        GUITips.RSI_WORLDLEVLE0,
        string.format(GUITips.RSI_WORLDLEVLE1,LRoleDataMgr.MyHeroInfo.m_BufferList[BuffType].dic1),
        string.format(GUITips.RSI_WORLDLEVLE2,LRoleDataMgr.MyHeroInfo.level),
        string.format(GUITips.RSI_WORLDLEVLE3,LRoleDataMgr.MyHeroInfo.m_BufferList[BuffType].dic2),
        }
        msgs.dis1 = msg   
        msgs.dis2=GUITips.RSI_WORLDLEVLE4
        userData={
        title = title or GUITips.RSI_WORLDLEVLETITLE,
        BuffDic=msgs
        }
        LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, userData)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- elseif BuffType==AppDef.BuffType.ExperienceMC or BuffType==AppDef.BuffType.PlatinumMC then
    --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Welfare.WelfareUI", AppDef.UIType.SpecialLayer, 4)
    --     LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif BuffType == AppDef.BuffType.Team then
        local msgs = {}    
        local msg = {
        GUITips.RSI_TEAMDESC1,
        }
        msgs.dis1 = msg   
        local tips = GUITips.RSI_TEAMDESC2
        if LRoleDataMgr.MyHeroInfo:GetTeamMemberNum() == 2 then
            tips = GUITips.RSI_TEAMDESC2_2
        elseif LRoleDataMgr.MyHeroInfo:GetTeamMemberNum() > 2 then
            tips = GUITips.RSI_TEAMDESC2_1
        end

        msgs.dis2=tips
        msgs.dis2ColorText = true
        userData={
        title = GUITips.RSI_TEAMBUFF,
        BuffDic=msgs
        }
        LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, userData)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        
    end 
   
end
function Utils:OpenFanPai(data)
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.FanPaiRewardUI", AppDef.UIType.Chat, data)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

function Utils:CheckIsMoney(id)
    if id == AppDef.EMoneyType.EMT_Gold or id == AppDef.EMoneyType.EMT_Cash 
        or id == AppDef.EMoneyType.EMT_Tili or id == AppDef.EMoneyType.EMT_ArenaSorce 
        or id == AppDef.EMoneyType.EMT_KunlunMoney then
        return true
    end
    return false
end

function Utils:SortBangPaiMemList(list)
    if list  == nil or type(list) ~= "table" then
        return
    end
    table.sort(list, function(a, b)
        if a and b and a.roleWeiJie and b.roleWeiJie and a.zhandouli and b.zhandouli then
            if a.roleWeiJie == b.roleWeiJie then
                return a.zhandouli > b.zhandouli
            else
                return a.roleWeiJie < b.roleWeiJie
            end
        end
        return false
    end)
end

function Utils:isIOSPlatform()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    return target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD
end

function Utils:getFunctionTime( actIdTemp )
    -- body
    for i=1,#LRoleDataMgr.OpenedActData do
        local actId = LRoleDataMgr.OpenedActData[i].actID
        if actIdTemp == actId then
            if LRoleDataMgr.OpenedActData[i].time then
                return LRoleDataMgr.OpenedActData[i].time
            end
        end
    end
    return 0
end

function Utils:SafeSetString(label, str)
    local function TexErr()
                
    end
    local function showImg()
        label:setString(str)
    end
    xpcall(showImg,TexErr)
end


function Utils:CalTotalPower(OtInfo, isOther)
    local horseList
    if isOther == nil or isOther == false then
        horseList = LDataConstMgr:GetHorseConfigArr()
    else
        horseList = LDataConstMgr:GetOtherHorseConfigArr()
    end
    
    local TotalCell={}
        local TotalPower = 0
          for i = 1, #horseList do
            local horsedata = horseList[i]
            --获得
            if horsedata.isGet == true then
              for i = 2, 5 do
                local attrType = horsedata.attrTypeArr[i-1]
                local attrValue = horsedata.attrValueArr[i-1]
                if attrType~=nil then      
                    if TotalCell[attrType]~=nil and TotalCell[attrType]~=0  then
                        TotalCell[attrType]=attrValue+TotalCell[attrType]
                    else
                        TotalCell[attrType]=attrValue
                    end
                end 

                end           
            end

          end
    OtInfo.TotalPower=TotalPower

    if isOther == nil or isOther == false then
        self:SendMsg(LUIHorseEvent.RecvEnforceValue)
    end

end

function Utils:getTiliStr( tili )
    -- body
    tili = tili or 0
    local strTili = string.format("%d/%d", tili, 100)
    return strTili
end

function Utils:formatNumber( num )
    if  type(num) ~= 'number' then
        return ""
    end
    local numStr = tostring(num)
    local len = string.len(numStr)
    local str = ''
    local has0 = false
    for i = 1, len do
        local n = tonumber(string.sub(numStr,i,i))
        local p = len - i + 1
        if n > 0 and has0 == true then --连续多个零只显示一个
            str = str .. GUITips.RSI_ZERO
            has0 = false
        end
        if p % 4 == 2 and n == 1 then --十位数如果是首位则不显示一十这样的
            if len > p then
                str = str .. GUINumUper[n]
            end
            str = str .. GUIUnit[p]
        elseif n > 0 then 
            str = str .. GUINumUper[n]
            str = str .. GUIUnit[p]
        elseif n == 0 then
            if p % 4 == 1 then --各位是零则补单位
                str = str .. GUIUnit[p]
            else
                has0 = true
            end
        end
    end
    return str
end

function Utils:LoadItemImg(icon, itemId)
    local path = "item/equip"..LRoleDataMgr.GetItemPicId(itemId)..".png"
    if not io.exists(path) then
        path = "item/equip_"..LRoleDataMgr.GetItemPicId(itemId)..".png"
    end
    icon:loadTexture(path)
end


function Utils:PlayAction(path, beginFrame, endFrame, num, fuc)
    -- body
    local action = cc.CSLoader:createTimeline(path)
    local timeline = ccs.Timeline:create()
    local frame = ccs.EventFrame:create()
    frame:setEvent("End")
    frame:setFrameIndex(num)
    timeline:addFrame(frame)
    action:addTimeline(timeline)
    action:pause()
    action:clearFrameEventCallFunc()
    if fuc then
        action:setFrameEventCallFunc(fuc)
    end
    AppDef.CurScene:runAction(action)
    action:gotoFrameAndPlay(beginFrame, endFrame, false)
end

--[[
 * @param baseSecond
 * @param numType true: 00:00:00 false: xx小时xx分钟xx秒
 * @param showHour
 * @returns {string}
 ]]
 --baseSecond: number, numType: boolean = true, showHour: boolean = true
function Utils:timeString( baseSecond, numType, showHour)
    if showHour == nil then
        showHour = true
    end
    if numType == nil then 
        numType = true
    end
    local timeStr = ""
    local hour = 0
    if showHour then
        hour = math.floor( baseSecond / 3600 )
    end
    local min = math.floor(( baseSecond - hour * 3600 ) / 60 )
    local sec = math.floor(( baseSecond - hour * 3600 ) % 60 )

    if numType == false then
        if showHour == true then
            if hour < 10 then
                timeStr = timeStr .. "0" .. hour .. GUITips.UI_Arena_Msg2
            else
                timeStr = timeStr .. hour .. GUITips.UI_Arena_Msg2
            end
        end
        if min ~= nil and min ~= 0 then
            timeStr = timeStr ..  min .. GUITips.UI_Arena_Msg3
        end
        if sec ~= nil and sec ~= 0 then
            timeStr = timeStr .. sec .. GUITips.UI_Arena_Msg4
        end
    else
        if showHour then
            if hour < 10 then
                timeStr = timeStr .. "0" .. hour .. ":";
            else
                timeStr = timeStr .. hour .. ":";
            end
        end
        if min < 10 then
            timeStr = timeStr .. "0" .. min .. ":";
        else
            timeStr = timeStr .. min .. ":";
        end
        if sec < 10 then
            timeStr = timeStr .. "0" .. sec;
        else
            timeStr = timeStr .. sec;
        end
    end
    return timeStr;
end

function Utils:getTimeString(time)
    if 0 == time then
        return GUITips.RSI_FACTION_MSG43
    else
        local day = math.floor(time / (24 * 3600))
        local hour = math.floor(time / 3600)
        if day > 0 then
            return string.format("%d%s", day, GUITips.RSI_FACTION_MSG44)
        elseif hour > 0 then
            return string.format("%d%s", hour, GUITips.RSI_FACTION_MSG45)
        else
            return string.format("%d%s", math.floor(time / 60), GUITips.RSI_FACTION_MSG46)
        end
    end
end
--[[
 可领奖宝箱特效
]]
function Utils:ReceivableEffect(scale)
    local bgAnim = "res2/animation/effect_tuitu_1"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end
--[[]]

function Utils:FightEffect(scale)
    local bgAnim = "res2/animation/effect_tuitu_4"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end


--[[打开副本]]
function Utils:OpenFuben(openCurChapter)
    local data = {}
    data.openCurChapter=openCurChapter
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FuBenMap.NormalFuBenUI",AppDef.UIType.Normal,data)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

--[[打开大地图挑战界面
   id 当前小关卡id
]]
function Utils:OpenChallenge(stageId)
    local chapterId = JsonConfig.getMapIdByStageID(stageId)
    local data = {}
    data.openCurChapter=true
    data.chapterId=chapterId
    data.stageId=stageId
  
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FuBenMap.NormalFuBenUI",AppDef.UIType.Normal,data)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end
--[[
获得重置次数
]]
function Utils:GetResetTimes()
    -- body
end



function Utils:getGoldStr()
    local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if money >= 1000000 then
        return "" .. math.floor(money / 10000) .. GUITips.RSI_FACTION_WAN
    else
        return "" .. money
    end
end

function Utils:getPowerStr(power)
    -- local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if power >= 1000000 then
        return "" .. math.floor(power / 10000) .. GUITips.RSI_FACTION_WAN
    else
        return "" .. power
    end
end

function Utils:getNewPowerStr(power)
    -- local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if power >= 1000000 then
        return "" .. math.floor(power / 10000), true
    else
        return "" .. power, false
    end
end

function Utils:CheckHeadId(headId)
    headId = headId or 0
    if headId ~= 4 and headId ~= 5 then
        headId = 5
    end
    return headId
end

function Utils:CheckModelId(modelId)
    modelId = modelId or 0
    if modelId ~= 4 and modelId ~= 5 then
        modelId = 5
    end
    return modelId
end

return Utils
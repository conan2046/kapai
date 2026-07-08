--  ----------------------------------------------
-- 签到UI逻辑
local DailySignUI = LUIBase:New()
DailySignUI.__index = DailySignUI


-- ----------------------------------------------
-- 常量区
local CsbFilePath = "csd/SignLayer.csb"
local rpanel_tv_tagid = 1886 

-- ---------------------------------
local _DEBUG = false
local function Debug(msg)
    if not _DEBUG then return end
end


-- ----------------------------------------------
local function _ShowImage(image , show)
    local show = show or false 
    image:setVisible(show)
end

-- ----------------------------------------------
local function _DrawTexture(image, texture, type)
    if not image then return end 
    if not texture or texture == ""  then return end
    local type = type or ccui.TextureResType.localType
    image:loadTexture(texture, type)
end

-- ----------------------------------------------
local function _DrawText(text, str)
    if text == nil then
        return 
    end
    text:setString(str)
end

-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end

-- ----------------------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	DailySignUI:MarkIntaractCObj(btn)
end

-- ----------------------------------------------
function DailySignUI:RegistMsgs()
    self.msgIds = 
    {
        LUIDailySignEvent.DailySignInfo,   -- 服务器返回签到数据
        LUIDailySignEvent.DailySignResult, -- 服务器返回签到结果

    }
    self:RegistSelf(self, self.msgIds)
end

-- ----------------------------------------------
function DailySignUI:ProcessEvent(msg)
    if msg.msgId == LUIDailySignEvent.DailySignInfo then
        self:OnDailySignInfo(msg.value)
        self:ShowCurSign()
    end

    if msg.msgId == LUIDailySignEvent.DailySignResult then
        self:OnDailySignResult(msg.value)
    end
end


-- ----------------------------------------------
function DailySignUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.list_view = nil
    self.item_list_view_template = nil
    self.item_template = nil
    self.days_text = nil
end

-- ----------------------------------------------
function DailySignUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- ----------------------------------------------
function DailySignUI:Init()
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:QueryDailySignInfo()
    self:RegisterQuik()
end

-- ----------------------------------------------
function DailySignUI:New()
    local o = LUIBase:New()
    setmetatable(o, DailySignUI)
    o:Init()
    return o
end


-- ----------------------------------------------
function DailySignUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    local RootPanel = self.m_pUILayer:getChildByName("LoginGiftUI")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- ----------------------------------------------

function DailySignUI:InitUIControl()
    local rp = self.m_pUILayer:getChildByName("LoginGiftUI")
    self.list_view = rp:getChildByName("ListView")
    self.item_list_view_template = rp:getChildByName("ItemList")
    self.item_list_view_template:setScrollBarEnabled(false)
    self.item_template = rp:getChildByName("Item")
    self.item_template:setTouchEnabled(true)
    self.days_text = rp:getChildByName("bg_Tips"):getChildByName("Count")
    self.list_view_map = {}
end

-- ----------------------------------------------
local row_len = 5
function DailySignUI:DrawListView()
    -- ========================
    -- 画签到天数
    if not self.signdata then 
        Debug("没有签到数据")
        return 
    end
    self:DrawTitle()
    local rows , left = self:SplitSignData(row_len)
    -- 1.构造组织整行
    for i = 1, rows do
        local row = self:CreateRow(i, row_len)
        if row then
            self:ListViewAddRowCell(row)    
        end
    end
    -- 2 构造剩余
    if left <= 0 then return end 
    local row = self:CreateRow(rows + 1, left)
    if row then
        self:ListViewAddRowCell(row)    
    end
end


-- ----------------------------------------------
function DailySignUI:DrawTitle()
    local days = self.signdata.sign_info.signnum
    Debug("DrawTitle days "..days)
    self.days_text:setString(days)
end

-- ----------------------------------------------
function DailySignUI:ListViewAddRowCell(row)
    if  row then
        self.list_view:pushBackCustomItem(row)
    end
end


-- ----------------------------------------------
function DailySignUI:SplitSignData(row_len)
    local datal = #self.signdata.sign_info.daily_award
    local rows = math.floor(datal / row_len)
    local left = math.fmod(datal, row_len)  
    return rows, left
end

-- ----------------------------------------------
local function _DrawVIP(vipmultiple,viplv,cell)
    -- ===============================
    -- VIP翻倍
    if vipmultiple > 1 then
        local vip_str = "V"..viplv.."翻倍"
        local text = cell:getChildByName("bg_Tag"):getChildByName("Text")
        text:setString(vip_str)
        text:setRotation(-43)
    else 
        cell:getChildByName("bg_Tag"):setVisible(false)
    end
end

-- ----------------------------------------------
local function _DrawDays(day ,cell)
    local title_str = "第"..day.."天"
    cell:getChildByName("Title"):setString(title_str)
end

-- ----------------------------------------------
local function _DrawBackground(ui, rawidx, sign, cell)
    -- ===============================
    -- 高亮已签
    if rawidx <= sign then
        cell:getChildByName("choose"):setVisible(true)
    else
        cell:getChildByName("choose"):setVisible(false)
    end
end

-- ----------------------------------------------
local function _ReDrawBackground(ui, sign)
    local cell = ui.list_view_map[rpanel_tv_tagid + sign] 
    cell:getChildByName("choose"):setVisible(true)
    if ui.signdata.ani then
        ui.signdata.ani:removeFromParent()
    end
end

-- ----------------------------------------------
local function _CatItemImagePath(atype)
    local resid = GUITipsAwrdItemIdMap[atype]
    if not resid then
        Debug("_CatItemImagePath error typeid "..atype)
        return ""
    end 
    local imagef = "item/equip"..resid..".png"
    return imagef
end

-- ----------------------------------------------
local function _GetItemName(atype)
    local name = AppDef.AwrdItemName[atype]
    if  not name then 
        Debug("_GetItemName error typeid "..atype)
        return ""
    end 
    return name  
end

-- ----------------------------------------------
local function _DrawAwardTexture(atype, num, value,cell)
    local imagef  
    local name 
    if atype < AppDef.AwrdItem.AWRD_ITEM_COIN then 
        local item  = LItemMgr:getItem(atype)
        -- imagef = "item/equip"..item.m_pic..".png"
        if item then
            name = item.m_name
        else
            name = "查找不到:"..atype
        end
    else 
        imagef = _CatItemImagePath(atype)
        name = _GetItemName(atype)
    end

    local texture = cell:getChildByName("bg_Icon")
    texture:removeAllChildren()
    if atype==AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
        --Utils:GetItemCellValue(grid, type, itemId, showQuality, showNum, num, pItem, isOpenTouch, isChangeSize, pid, pstar)
        Utils:GetItemCellValue(texture, 0, atype, true,false, num,nil,nil,nil,num,value)
    else
       Utils:GetItemCellValue(texture, 0, atype, true, true, num)
    end
    local namectl  = cell:getChildByName("Name")
    _DrawText(namectl, name)
end


-- ----------------------------------------------
local function _DrawItemNum(num ,cell)
    cell:getChildByName("Num"):setString(num)
end

-- ----------------------------------------------
-- row_index 行号

function DailySignUI:ShowCurSign()
    if LRoleDataMgr.MyHeroInfo.dailyIsDone == 1 then
        return
    end
    local cell = self.list_view_map[rpanel_tv_tagid + self.signdata.sign_info.signnum + 1] 
    self.signdata.ani = ImodAnim:createWithFileSync("res2/fx/qiandao")
    -- ani:registerScriptEndCBHandler(aniPlayEndCallback)
    self.signdata.ani:PlayActionRepeat(0)
    local btnSize = cell:getContentSize()
    self.signdata.ani:setPosition(cc.p(btnSize.width/2,btnSize.height/2))
    cell:addChild(self.signdata.ani)
end

function DailySignUI:CreateRow(row_index, len )
    local row = self.item_list_view_template:clone()
    for i = 1, len do
        local rawidx = (row_index - 1) * row_len  + i
        local sdata = self:GetDailySignDataByIdx(rawidx)
        if not sdata then 
            return row        
        end

        local row_cell = self.item_template:clone()
        self.list_view_map[rpanel_tv_tagid + rawidx] = row_cell
        row_cell:setTag(rawidx)
        _DrawDays(sdata.dayidx , row_cell)
        _DrawVIP(sdata.vipmultiple, sdata.viplv, row_cell)
        _DrawBackground(self,rawidx, self.signdata.sign_info.signnum, row_cell)
        _DrawAwardTexture(sdata.awardtype, sdata.awardnum,sdata.value,row_cell)
        _BindClickFunctionToButton(row_cell, self:SpawnRowCellClickFunc(rawidx))
        row:pushBackCustomItem(row_cell)
    end
    return row
end
-- ----------------------------------------------
function DailySignUI:SpawnRowCellClickFunc(idx)
    local func = function(btn)
        local rawidx = btn:getTag()
        local cur = (self.signdata.sign_info.isdone == 0) and (self.signdata.sign_info.signnum+1) or self.signdata.sign_info.signnum
        if rawidx < cur then
            Utils:ShowScrollTips(GUITips.RSI_DAYSIGN_TIPS_2)
        elseif rawidx > cur then
            Utils:ShowScrollTips(GUITips.RSI_DAYSIGN_TIPS_1)
        else
            if self.signdata.sign_info.isdone == 0 then
                self.sign_cell = btn -- 保存当前点击的btn
                LuaNetSendMsg:DailySign()
            else
                Utils:ShowScrollTips(GUITips.RSI_DAYSIGN_TIPS_2)
            end
        end
    end
    return func
end

-- ----------------------------------------------
function DailySignUI:GetDailySignDataByIdx(idx)
    local data = self.signdata.sign_info.daily_award[idx]
    if data then 
        return  data 
    end 
    return nil 
end

-- ----------------------------------------------
function DailySignUI:OnDailySignInfo(rsp)
    Debug("OnDailySignInfo")
    if self.signdata then self.signdata = nil end
    self.signdata = rsp
    self:DrawListView()
end

-- ----------------------------------------------
function DailySignUI:OnDailySignResult(rsp)
    Debug("OnDailySignResult")
    if rsp.errcode > 0 then 
        -- ===================
        -- 签到成功
        self.signdata.sign_info.signnum = self.signdata.sign_info.signnum + 1
        self.signdata.sign_info.isdone = 1
        LRoleDataMgr.MyHeroInfo.dailyIsDone = 1
        self:DrawTitle()
        local idx = self.sign_cell:getTag()
        _ReDrawBackground(self, self.signdata.sign_info.signnum)

        LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh,3)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
--    _ShowTipsWindow(self, rsp.errmsg)
end

-- ----------------------------------------------
function DailySignUI:QueryDailySignInfo()
    Debug("QueryDailySignInfo")
    LuaNetSendMsg:QueryDailySignInfo()
end
-- ----------------------------------------------
return DailySignUI

--[[
lua里面的游戏逻辑控制
道具来源界面
]]
--local ShopDef = require("View.Shop.ShopDef")
local ICONPATH = "res2/Icon/ui_main_icon/"
local ItemSourceUI = LUIBase:New()
ItemSourceUI.__index = ItemSourceUI
--local this = LTcpSocket
function ItemSourceUI:New(userData)
   
	local o = LUIBase:New()
	setmetatable(o,ItemSourceUI)	
    o:Init(userData)
 
	return o
end


function ItemSourceUI:Init(userData)
    self:CreateUINode("csd/common/huoqutujing.csb")

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:InitTouchEvt()
    self:RegistMsgs()
    self:ShowItem(userData)
end

function ItemSourceUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Popup")
    self.m_CloseBtn = panel:findChildByName("Title/Btn_close")
    local bgPanel = panel:getChildByName("Panel_name")
    self.m_nameLabel = bgPanel:getChildByName("txt_name")
    self.m_descLabel = bgPanel:getChildByName("txt_tips")
    self.m_numLabel = bgPanel:getChildByName("txt_num")
    self.m_iconBtn = bgPanel:getChildByName("Panel_icon")
    self.m_iconPanel = self.m_iconBtn:getChildByName("Icon")

    self.m_listView = panel:getChildByName("ListView")
    self.m_cell = panel:getChildByName("itemlayer_1")
    self.m_cell:retain()
    self.m_cell:removeFromParent()

    self.m_fuBenMap = {}
end

function ItemSourceUI:InitTouchEvt()
    self.m_CloseBtn:addClickEventListener(handler(self,ItemSourceUI.CloseUI))
    self.m_iconBtn:addClickEventListener(handler(self,ItemSourceUI.OpenInfo))
end

--[[
显示道具
userData数据结构：
{
    表格内奖励通用{id,0,1}
}
]]
function ItemSourceUI:ShowItem(userData)
    if userData == nil then
        return
    end
    self.m_itemId = userData[1] or 0
    self.m_value = userData[2] or 0
    if self.m_itemId == 0 then
        return
    end
    if self.m_itemId == AppDef.RewardItem.RD_ITEM_FABAO then
        self:ShowFaBaoInfo()
    elseif self.m_itemId == AppDef.RewardItem.RD_ITEM_EQUIP then
        self:ShowEquipInfo()
    else
        self:ShowItemInfo()
    end
end

function ItemSourceUI:UpdateBaseInfo()
    if self.m_itemCfg == nil then
        return
    end
    if self.m_itemId == AppDef.RewardItem.RD_ITEM_FABAO then
        self:ShowCFaBaoInfo()
    elseif self.m_itemId == AppDef.RewardItem.RD_ITEM_EQUIP then
        self:ShowCEquipInfo()
    else
        self:ShowCItemInfo()
    end
end

--[[
查询副本信息
]]
function ItemSourceUI:QueryFuBenInfo()
    if self.m_itemCfg == nil then
        return
    end
    for i=1,#self.m_itemCfg.item_source do
        local value = self.m_itemCfg.item_source[i]
        if value ~= nil and #value > 1 then
            local fType = 0
            if value[1] == 4 then
                fType = 1 
            elseif value[1] == 5 then
                fType = 2
            end
            if fType > 0 then
                local mapId = JsonConfig.getMapIdByStageID(value[2])
                if mapId > 0 then
                    LuaNetSendMsg:QueryFuBenInfo(fType,mapId,value[2])
                end
            end
        end
    end
end

---------------------------------------道具-----------------------------------------
function ItemSourceUI:ShowItemInfo()
    self.m_itemCfg = JsonConfig.m_Item.getDefByID(self.m_itemId)
    --print("ItemSourceUI:ShowItem",self.m_itemId)
    self:QueryFuBenInfo()
    self:ShowCItemInfo()
    self:ShowFromList()
end

--[[
显示citem信息
]]
function ItemSourceUI:ShowCItemInfo()
    if self.m_itemCfg == nil then 
        return 
    end
    self.m_nameLabel:setString(self.m_itemCfg.name)
    local color = AppDef:GetItemQualityColor(self.m_itemCfg.quality)
    self.m_nameLabel:setTextColor(color)
    self.m_descLabel:setString(self.m_itemCfg.des)
    local str = ""
    local num = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
    if self.m_itemId < AppDef.SpecialItemId.Gold then
        str = GUITips.RSI_NUM..": "..num
    end
    if self.m_itemCfg.type == AppDef.ItemType.PetEquipFrag then--装备碎片
        local item_num = self:GetHeChengNum(4)
        if item_num > 0 then
            str = str.."/"..item_num
        end
    elseif self.m_itemCfg.type == AppDef.ItemType.FaBaoFrag then--法宝碎片
        local item_num = self:GetHeChengNum(8)
        if item_num > 0 then
            str = str.."/"..item_num
        end
    elseif self.m_itemCfg.type == AppDef.ItemType.PetFrag then--神将碎片
        local target = self:GetHeChengTarget(2)
        if target ~= nil and target[1] == AppDef.RewardItem.RD_ITEM_PET then
            local petData = LRoleDataMgr.Pet:GetPetById(target[2])
            if petData ~= nil then
                local cost = PetkaPaiManager:getPetStarUpCostInfo(petData)
                if cost ~= nil then
                    local item_num = cost[2] or 0
                    str = str.."/"..item_num
                end
            end
        end
    end
    self.m_numLabel:setString(""..str)
    self.m_icon = Utils:GetItemCellValue(self.m_iconPanel, 0, self.m_itemId, true, false, 0, self.m_icon, false, true)
end

function ItemSourceUI:GetHeChengNum(hType)
    local cfg = JsonConfig.GetHeChengCfg(hType,self.m_itemId)
    if cfg == nil  then
        return 0
    end
    local item_num = 0
    for i=1,#cfg.item do
        local data = cfg.item[i]
        if data[1] == info.m_id then
            item_num = data[3] 
            break
        end
    end
    return item_num
end

function ItemSourceUI:GetHeChengTarget(hType)
    local cfg = JsonConfig.GetHeChengCfg(hType,self.m_itemId)
    if cfg == nil  then
        return 0
    end
    return cfg.target
end
-----------------------------------法宝----------------------------------------------
function ItemSourceUI:ShowFaBaoInfo()
    if self.m_value == 0 then
        return
    end
    self.m_itemCfg = JsonConfig.m_faBaoConfig.getDefByID(self.m_value)
    --print("ItemSourceUI:ShowItem",self.m_itemId)
    self:QueryFuBenInfo()
    self:ShowCFaBaoInfo()
    self:ShowFromList()
end

--[[
显示cfabao信息
]]
function ItemSourceUI:ShowCFaBaoInfo()
    if self.m_itemCfg == nil then 
        return 
    end
    self.m_nameLabel:setString(self.m_itemCfg.name)
    local color = AppDef:GetItemQualityColor(self.m_itemCfg.quality)
    self.m_nameLabel:setTextColor(color)
    self.m_descLabel:setString(self.m_itemCfg.des)
    self.m_numLabel:setString("")
    self.m_icon = Utils:GetFaBaoCellValue(self.m_iconPanel,self.m_icon,self.m_itemCfg.id,0, false, 0, 0,0,false,true)
end

-----------------------------------装备----------------------------------------------
function ItemSourceUI:ShowEquipInfo()
    if self.m_value == 0 then
        return
    end
    self.m_itemCfg = JsonConfig.m_equipConfig.getDefByID(self.m_value)
    --print("ItemSourceUI:ShowItem",self.m_itemId)
    self:QueryFuBenInfo()
    self:ShowCEquipInfo()
    self:ShowFromList()
end

--[[
显示cfabao信息
]]
function ItemSourceUI:ShowCEquipInfo()
    if self.m_itemCfg == nil then 
        return 
    end
    self.m_nameLabel:setString(self.m_itemCfg.name)
    local color = AppDef:GetItemQualityColor(self.m_itemCfg.quality)
    self.m_nameLabel:setTextColor(color)
    self.m_descLabel:setString(self.m_itemCfg.des)
    self.m_numLabel:setString("")
    self.m_icon = Utils:GetEquipCellByEquipID(self.m_iconPanel, self.m_icon, self.m_itemCfg.id, false, true,true)
end
------------------------------------------------------------------------------------------
--来源列表
function ItemSourceUI:SortSource()
    if self.m_itemCfg == nil then
        return
    end
    self.m_showIds = {}
    local ids = {}
    local max = math.max(1,#self.m_itemCfg.item_source)
    for i=1,max do
        local functionId = 0
        local tmp = 0
        local value = self.m_itemCfg.item_source[i]
        if value ~= nil then
            if #value == 2 and value[1] == 4 and  value[2] > 0 then
                local tmp = self.m_fuBenMap[value[2]]
                if tmp ~= nil and type(tmp) == "table" and tmp.star ~= 0xff then
                    table.insert(self.m_showIds,1,value)
                else
                    table.insert(self.m_showIds,value)
                end
            elseif  value[1] ~= nil then
                table.insert(ids,value)
            end
        end
    end
    for i=#ids,1,-1 do
        table.insert(self.m_showIds,1,ids[i])
    end
end

--来源列表
function ItemSourceUI:ShowFromList()
    if self.m_itemCfg == nil then
        return
    end
    self:SortSource()
    local max = math.max(1,#self.m_showIds)
    for i=1,max do
        local functionId = 0
        local tmp = 0
        local value = self.m_showIds[i]
        if value ~= nil then
            if #value > 0 then
                functionId = value[1]
            end
            if #value > 1 then
                tmp = value[2]
            end
        end
        self:ShowOneFrom(i,functionId,tmp)
    end
end

function ItemSourceUI:ShowOneFrom(ind,functionId,value)
    local sender = self.m_listView:getChildByTag(ind)
    if sender == nil then
        sender = self.m_cell:clone()
        sender:setTag(ind)
        self.m_listView:pushBackCustomItem(sender)
        sender:getChildByName("Button_1"):addClickEventListener(handler(self,ItemSourceUI.SweepCallBack))
        sender:getChildByName("Button_2"):addClickEventListener(handler(self,ItemSourceUI.JumpCallBack))
        sender:getChildByName("Button_3"):addClickEventListener(handler(self,ItemSourceUI.JumpCallBack))
    end
    local iconImg = sender:getChildByName("item_icon")
    local fromLabel1 = sender:getChildByName("Name_1")
    local fromLabel2 = sender:getChildByName("Name_2")
    local cntLabel = sender:getChildByName("times")
    local btn1 = sender:getChildByName("Button_1")
    local btn2 = sender:getChildByName("Button_2")
    local btn3 = sender:getChildByName("Button_3")
    local btn1Label = btn1:getChildByName("txt")
    btn3.userObject = {functionId,value}
    btn2.userObject = {functionId,value}
    btn1.userObject = value
    fromLabel1:setString("")
    fromLabel2:setString("")
    cntLabel:setString("")
    btn1:setVisible(false)
    btn2:setVisible(false)
    btn3:setVisible(false)
    functionId = functionId or 0
    value = value or 0
    local funCfg = JsonConfig.m_functionConfig.getDefByID(functionId)
    if functionId == 0 or funCfg == nil then
        iconImg:setVisible(false)
        fromLabel2:setString(self.m_itemCfg.item_from)
        return
    end
    local str = ICONPATH .. funCfg.icon .. ".png"
    Utils:SafeLoadTexture(iconImg,str,ccui.TextureResType.localType)
    fromLabel1:setString(GUITips.UI_Btn_Item_From.."："..funCfg.name)
    if functionId ~= 4 and functionId ~= 5 then
        btn3:setVisible(true)
        return
    end
    btn1:setVisible(true)
    btn1:setEnabled(false)
    btn2:setVisible(true)
    btn2:setEnabled(false)
    local fuBenCfg = JsonConfig.m_stageNodeConfig.getDefByID(value)
    if fuBenCfg ~= nil then
        local str = GUITips.UI_Btn_Item_From.."："..funCfg.name
        if functionId == 4 then
            str = str..string.format(GUITips.RSI_FUBENMAP_RES17,fuBenCfg.mapid%1000) 
        end
        str = str.."("..fuBenCfg.Name..")"
        fromLabel1:setString(str)
    end
    local data = self.m_fuBenMap[value]
    if data == nil then
        return
    end
    data.star = data.star or 0xff
    if data.star == 0xff then
        return
    end
    if data.star > 0 and data.fightCnt >= fuBenCfg.AttackCount and data.resetCnt == 0 then
        return    
    end
    local cnt = fuBenCfg.AttackCount - data.fightCnt
    local str = ""..cnt.."/"..fuBenCfg.AttackCount
    cntLabel:setString(string.format(GUITips.RSI_ITEM_TIPS4,str))
    if data.star > 0 then
        
        if data.fightCnt < fuBenCfg.AttackCount then
            btn1:setEnabled(true)
            if cnt > 5 then
                cnt = 5
            end
            btn1Label:setString(string.format(GUITips.RSI_FUBENMAP_RES6,cnt))
        else
            if data.resetCnt > 0 then
                btn1:setEnabled(true)
                btn1Label:setString(GUITips.RSI_FUBENMAP_RES18)
            end
        end
    end
    btn2:setEnabled(true)
end

function ItemSourceUI:JumpCallBack(sender)
    local functionId = sender.userObject[1] or 0
    if functionId == 0 then
        return
    end
    local value = sender.userObject[2] or 0
    if functionId == 4 then
        if value > 0 then
            if LUILogic:GetUIInBufferInd("FuBenMap.FuBenDetailUI") > 0 then
                Utils:DeleteUI("FuBenMap.FuBenDetailUI")
            end
            if LUILogic:GetUIInBufferInd("FuBenMap.NormalFuBenUI") == 0 then 
                Utils:DeleteUI("FuBenMap.NormalFuBenUI")
            end
            Utils:SendMsg(LUILogicEvent.CloseAllPopup)
            Utils:OpenChallenge(value)
        end
        self:CloseUI()
        return
    end
    local LayerType = AppDef.UIType.FirstClassLayer
    local cfg = AppDef.FuncUI[functionId]
    if cfg ~= nil then
        LayerType = cfg.ind or AppDef.UIType.FirstClassLayer
        if LUILogic:GetUIInBufferInd(cfg.lua) > 0 then
            Utils:DeleteUI(cfg.lua)
        end
    end
    Utils:SendMsg(LUILogicEvent.CloseHighPopup,LayerType)
    if functionId == AppDef.EModuleID.EMID_KAPAI_WF_XZ then
        Utils:DeleteUI("XueZhan.XueZhanMainUI")
        Utils:DeleteUI("XueZhan.XueZhanChapterUI")
    end
    Utils:OpenFunction(functionId)
    if functionId == AppDef.EModuleID.EMID_KAPAI_SJJINENG or functionId==AppDef.EModuleID.EMID_KAPAI_SJXIULIAN then
        --调整神将养成界面
        Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, LRoleDataMgr.Pet:GetPetByFightPos(fightPos))
    end 
    self:CloseUI()
end

--扫荡or重置
function ItemSourceUI:SweepCallBack(sender)
    local value = sender.userObject
    if value == nil or type(value) ~= "number" then
        return
    end
    local fuBenCfg = JsonConfig.m_stageNodeConfig.getDefByID(value)
    if fuBenCfg == nil then
        return
    end
    local data = self.m_fuBenMap[value]
    if data == nil then
        return
    end
    if data.star <= 0 or data.star == 0xff then
        return
    end

    if data.fightCnt < fuBenCfg.AttackCount then
        if fuBenCfg.Hope > LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Tili) then
            Utils:OpenUseUI(500,1)
            return
        end
        LuaNetSendMsg:QueryFightSatge(6, data.fType, fuBenCfg.mapid, value)
        return
    end
    if data.resetCnt > 0 then
        self:ShowBuyCntDialog(value,data.mapId,data.resetCnt)
    end
end


function ItemSourceUI:ShowBuyCntDialog(nodeId,mapId,resetCnt)
    --print("ItemSourceUI:ShowBuyCntDialog",nodeId,mapId,resetCnt)
    local mapData = JsonConfig.m_FuBenMapConfig.getDefByID(mapId)
    if mapData.MapType == AppDef.MapType.FactionCopy then
        Utils:ShowScrollTips(GUITips.RSI_MONOPOLY_USEUPROOL)
        return
    end

    local function okFunc()
        --购买
        if resetCnt < 1 then
            Utils:ShowScrollTips(GUITips.RSI_FUBENMAP_RES11)
            return
        end
        LuaNetSendMsg:QueryResetStage(nodeId)
    end
    local function cancelFunc()
    end

    local configData = JsonConfig.m_config.getDefByID(1)
    if configData == nil then
        return
    end
    local values = json.decode(configData.value)
    local ind = #values - resetCnt + 1
    local resetCost = values[ind]
    local strTips = string.format(GUITips.RSI_FUBENMAP_RES5, resetCost, resetCnt)
    Utils:ShowDialogOKCancel(strTips, okFunc, cancelFunc)
end

function ItemSourceUI:RefreshFuBenInfo(value)
    if value == nil then
        return
    end
    if self.m_fuBenMap == nil then
        self.m_fuBenMap = {}
    end
    local data = {}
    data.fType = value.fType
    data.star =  value.star--0xff未开启，0可以打，其他可以扫荡
    data.fightCnt = value.fightCnt --已挑战次数
    data.resetCnt = value.resetCnt --可以重置次数
    data.mapId = value.mapId
    self.m_fuBenMap[value.nodeId] = data
    self:ShowFromList()
end

function ItemSourceUI:ResetFightCnt(value)
    --dump(value,"ItemSourceUI:ResetFightCnt == >")
    if value == nil then
        return
    end
    if self.m_fuBenMap == nil then
        return
    end
    local data = self.m_fuBenMap[value.stageId]
    if data == nil then
        return
    end
    local fuBenCfg = JsonConfig.m_stageNodeConfig.getDefByID(value.stageId)
    if fuBenCfg == nil then
        return
    end
    data.fightCnt = 0 --已挑战次数
    data.resetCnt = data.resetCnt-1 --可以重置次数
    --dump(data)
    self:ShowFromList()
end

function ItemSourceUI:RefreshFightCnt(value)
    --dump(value,"ItemSourceUI:RefreshFightCnt == >")
    if value == nil then
        return
    end
    if self.m_fuBenMap == nil then
        return
    end
    local data = self.m_fuBenMap[value.stageId]
    if data == nil then
        return
    end
    local fuBenCfg = JsonConfig.m_stageNodeConfig.getDefByID(value.stageId)
    if fuBenCfg == nil then
        return
    end
    data.fightCnt = data.fightCnt + value.sandangNum --已挑战次数
    --dump(data)
    self:ShowFromList()
end

function ItemSourceUI:OpenInfo(sender)
    if self.m_itemId == AppDef.RewardItem.RD_ITEM_FABAO then
        local data = {}
        data.id = self.m_itemCfg.id
        Utils:InitUI("FaBao.FaBaoInfo",AppDef.UIType.PopWindow,data)
    elseif self.m_itemId == AppDef.RewardItem.RD_ITEM_EQUIP then
        local data = {}
        data.id = self.m_itemCfg.id
        Utils:InitUI("PetEquip.EquipInfoUI",AppDef.UIType.PopWindow,data)
    else
        if self.m_itemCfg.type == AppDef.ItemType.PetEquipFrag then--装备碎片
            local cfg = JsonConfig.GetHeChengCfg(4,self.m_itemId)
            if cfg ~= nil then
                local data = {}
                data.id = cfg.target[2]
                Utils:InitUI("PetEquip.EquipInfoUI",AppDef.UIType.PopWindow,data)
            end
        elseif self.m_itemCfg.type == AppDef.ItemType.FaBaoFrag then--法宝碎片
            local cfg = JsonConfig.GetHeChengCfg(8,self.m_itemId)
            if cfg ~= nil then
                local data = {}
                data.id = cfg.target[2]
                Utils:InitUI("FaBao.FaBaoInfo",AppDef.UIType.PopWindow,data)
            end
        elseif self.m_itemCfg.type == AppDef.ItemType.PetFrag then--神将碎片
            local cfg = JsonConfig.GetHeChengCfg(2,self.m_itemId)
            if cfg ~= nil then
                Utils:SendMsg(LUILogicEvent.ShowPetInfo, {cfg.target[2]})
                self:HideUI()
            end
        end
    end
end

--[[
注册UI消息
]]
function ItemSourceUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFuBenMapEvent.getSingleNodeSuc,--关卡数据请求成功
        LUIFuBenMapEvent.resetFightTimesSuc,--重置成功
        LUIFuBenMapEvent.updateSaoDangEvent,--扫荡事件
        LUILogicEvent.ClosePetInfo,--关闭神将预览界面
    }
    self:RegistSelf(self,self.msgIds)
end

function ItemSourceUI:ProcessEvent(msg)
    if msg.msgId == LUIFuBenMapEvent.getSingleNodeSuc then
        self:RefreshFuBenInfo(msg.value)
    elseif msg.msgId == LUIFuBenMapEvent.resetFightTimesSuc then
        self:ResetFightCnt(msg.value)
    elseif msg.msgId == LUIFuBenMapEvent.updateSaoDangEvent then
        self:RefreshFightCnt(msg.value)
        performWithDelay(self.m_pUILayer, handler(self,ItemSourceUI.UpdateBaseInfo),1)
    elseif msg.msgId == LUILogicEvent.ClosePetInfo then
        self:ShowUI()
    end
end

function ItemSourceUI:HideUI()
    self.m_pUILayer:setVisible(false)
end

function ItemSourceUI:ShowUI()
    self.m_pUILayer:setVisible(true)
end

function ItemSourceUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_fuBenMap = nil
end

function ItemSourceUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemSourceUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function ItemSourceUI:UpdateUserData(userData)
    self:ShowItem(userData)
    self:ShowUI()
end

return ItemSourceUI
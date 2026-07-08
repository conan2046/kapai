
local XueZhanShopUI = LUIBase:New()
XueZhanShopUI.__index = XueZhanShopUI

local WanFaShopDelegate = require("View.Shop.WanFaShopDelegate")
local ShopDef = require("View.Shop.ShopDef")

--local this = LTcpSocket
function XueZhanShopUI:New()
	local o = LUIBase:New()
	setmetatable(o,XueZhanShopUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function XueZhanShopUI:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.UpdateKaPaiShop,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function XueZhanShopUI:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.UpdateKaPaiShop then
        self:updateData(msg.value)
    end
end

function XueZhanShopUI:Init()
    self:CreateUINode("csd/shop/wanfashop.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/shop/wanfashop.csb")
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
    --请求数据
    LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.XueZhan_1)
end

function XueZhanShopUI:initControlUI( ... )
    local value = {} --表数据
    local shopConfiglist = JsonConfig.m_ShopConfig.getList()
    for i=1, #shopConfiglist do
        local type = shopConfiglist[i].type[1]
        if type == ShopDef.KP_TYPE.XUEZHANSHANGDIAN then
            table.insert(value, shopConfiglist[i])
        end
    end
    value.shopType = ShopDef.KP_TYPE.XUEZHANSHANGDIAN
    self._WanFaShopDelegate = WanFaShopDelegate:New({pUILayer=self.m_pUILayer, value = value})

end

function XueZhanShopUI:updateData( data )
    -- body
    local itemList = {}
    local list = JsonConfig.m_ShopInfo.getList()
    local myLevel = LRoleDataMgr.MyHeroInfo.level
    for i=1, #list do
        local configData = list[i]
        if data.type == configData.type then
            local dataTemp = {}
            local conditionLv = 0
            if #configData.show > 0 then
                conditionLv = configData.show[1][2]
            end

            if myLevel >= conditionLv then
                local serverData = self:getBuyTimes(configData.id, data.itemList)
                if serverData then
                    dataTemp = serverData
                else
                    dataTemp.id = configData.id
                    dataTemp.buyTimes = 0
                    dataTemp.index = configData.cell
                end
                table.insert(itemList, dataTemp)
            end
        end
    end
    data.itemList = itemList
    data.size = #data.itemList

    self._WanFaShopDelegate:updateData(data)

end

function XueZhanShopUI:getBuyTimes( id, itemlist )
    -- body
    for i=1, #itemlist do
        if itemlist[i].id == id then
            return itemlist[i]
        end
    end
    return nil
end

function XueZhanShopUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("Shop.XueZhanShopUI")
end

function XueZhanShopUI:onExit()
    self._WanFaShopDelegate:onExit()
    self.m_pUILayer = nil
    print("XueZhanShopUI ===================== 111111111111>")
    self:Destory()
end

return XueZhanShopUI
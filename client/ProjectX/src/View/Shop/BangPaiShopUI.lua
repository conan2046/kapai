
local BangPaiShopUI = LUIBase:New()
BangPaiShopUI.__index = BangPaiShopUI

local WanFaShopDelegate = require("View.Shop.WanFaShopDelegate")
local ShopDef = require("View.Shop.ShopDef")

--local this = LTcpSocket
function BangPaiShopUI:New()
	local o = LUIBase:New()
	setmetatable(o,BangPaiShopUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function BangPaiShopUI:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.UpdateKaPaiShop,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function BangPaiShopUI:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.UpdateKaPaiShop then
        self:updateData(msg.value)
    end
end

function BangPaiShopUI:Init()
    self:CreateUINode("csd/shop/wanfashop.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
    LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.BANGPAISHOP)
end

function BangPaiShopUI:initControlUI( ... )
    local value = {} --表数据
    local shopConfiglist = JsonConfig.m_ShopConfig.getList()
    for i=1, #shopConfiglist do
        local type = shopConfiglist[i].type[1]
        if type == ShopDef.KP_TYPE.BANGPAISHANGDAIN then
            table.insert(value, shopConfiglist[i])
        end
    end
    value.shopType = ShopDef.KP_TYPE.BANGPAISHANGDAIN
    value.noAwardTab = true 
    self._WanFaShopDelegate = WanFaShopDelegate:New({pUILayer=self.m_pUILayer, value = value})
    
end

function BangPaiShopUI:updateData( data )
    -- body
    -- data.size = #data.itemList
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
                -- dump(serverData, "updateData ==222222222222222 >")
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

function BangPaiShopUI:getBuyTimes( id, itemlist )
    -- body
    for i=1, #itemlist do
        if itemlist[i].id == id then
            return itemlist[i]
        end
    end
    return nil
end

function BangPaiShopUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("Shop.BangPaiShopUI")
end

function BangPaiShopUI:onExit()
    self._WanFaShopDelegate:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return BangPaiShopUI
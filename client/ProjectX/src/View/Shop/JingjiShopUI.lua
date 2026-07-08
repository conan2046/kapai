
local JingjiShopUI = LUIBase:New()
JingjiShopUI.__index = JingjiShopUI

local WanFaShopDelegate = require("View.Shop.WanFaShopDelegate")
local ShopDef = require("View.Shop.ShopDef")

--local this = LTcpSocket
function JingjiShopUI:New()
	local o = LUIBase:New()
	setmetatable(o,JingjiShopUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function JingjiShopUI:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.UpdateKaPaiShop,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function JingjiShopUI:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.UpdateKaPaiShop then
        self:updateData(msg.value)        
    end
end

function JingjiShopUI:Init()
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
    LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.WANFA)
end

function JingjiShopUI:initControlUI( ... )
    local value = {} --表数据
    local shopConfiglist = JsonConfig.m_ShopConfig.getList()
    for i=1, #shopConfiglist do
        local type = shopConfiglist[i].type[1]
        if type == ShopDef.KP_TYPE.JINGJICHANGSHANGDIAN then
            table.insert(value, shopConfiglist[i])
        end
    end
    value.shopType = ShopDef.KP_TYPE.JINGJICHANGSHANGDIAN
    self._WanFaShopDelegate = WanFaShopDelegate:New({pUILayer=self.m_pUILayer, value = value})
    
end

function JingjiShopUI:updateData( data )
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

function JingjiShopUI:getBuyTimes( id, itemlist )
    -- body
    for i=1, #itemlist do
        if itemlist[i].id == id then
            return itemlist[i]
        end
    end
    return nil
end

function JingjiShopUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("Shop.JingjiShopUI")
end

function JingjiShopUI:onExit()
    self._WanFaShopDelegate:onExit()
    self.m_pUILayer = nil
    print("JingjiShopUI ===================== 111111111111>")
    self:Destory()
end

return JingjiShopUI
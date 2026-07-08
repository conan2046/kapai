
local AlearTreasureMap = LUIBase:New()
AlearTreasureMap.__index = AlearTreasureMap
--local this = LTcpSocket
function AlearTreasureMap:New(treaseInfo)
	local o = LUIBase:New()
	setmetatable(o, AlearTreasureMap)	
    o:Init(treaseInfo)
	return o
end

function AlearTreasureMap:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.AlearTreasureMap")
    self:SendMsg(LGameMsg.m_initUIMsg)
end


function AlearTreasureMap:Init(treaseInfo)

    self._treaseInfo = treaseInfo

--记录挖矿数据
    LRoleDataMgr.isInTreasuer = true
    LRoleDataMgr.posX = self._treaseInfo.posX
    LRoleDataMgr.posY = self._treaseInfo.posY

    self.m_pUILayer = cc.CSLoader:createNode("csd/WearPopupLayer.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("WearBg")
    local mask = self.m_pUILayer:getChildByName("Panel"):getChildByName("Mask")
    self:InitTouchEvt(mask)

    local IconBg = panel:getChildByName("IconBg")
    local icon = IconBg:getChildByName("Icon")
    local id = self._treaseInfo.itemId
    local text = IconBg:getChildByName("Text_1")
    if id == 2441 then
        icon:loadTexture("item/equip10049.png", ccui.TextureResType.localType)
        text:setString(GUITips.RSI_TIPS_TREASUERMAP_LOW)
    else
        icon:loadTexture("item/equip10050.png", ccui.TextureResType.localType)
        text:setString(GUITips.RSI_TIPS_TREASUERMAP_HIGHT)
    end   
    local haveMcCard = LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasMcCard or LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasLmCard or LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasMcCardTemp
    local btn = panel:getChildByName("Button")
    local function useItem( sender )
        
        if haveMcCard then
            return
        end
        self:useItemEvent()
    end
    btn:addClickEventListener(useItem)
	self:MarkIntaractCObj(btn)

    local btnTxt = btn:getChildByName("Text")
    btnTxt:setString(GUITips.UI_Btn_Item_Use)

    if haveMcCard then
        performWithDelay(self.m_pUILayer, function(sender)
            self:useItemEvent()
        end, 0.5)
    end

end

function AlearTreasureMap:useItemEvent( ... )
    -- body
    local collectData = {}
    collectData["collectTip"] = GUITips.RSI_TIPS_TREASUERMAP
    collectData["seconds"] = 3
    collectData["pic"] = 1
    collectData["callback"] = handler(self, AlearTreasureMap.CollectFinished)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCCollectUI", AppDef.UIType.PopWindow, collectData)
    self:SendMsg(LGameMsg.m_initUIMsg)

--高级藏宝图
    if self._treaseInfo.itemId == 2442 then
        LRoleDataMgr.IsInHighTreasuer = true
    end

    self:CloseUI()
end


function AlearTreasureMap:InitTouchEvt(mask)
    local function BgTouchedCallback(sender)
        self:CloseUI()
    end
    mask:setSwallowTouches(false)
    mask:setTouchEnabled(true)
    mask:addClickEventListener(BgTouchedCallback)
	self:MarkIntaractCObj(mask)
end

function AlearTreasureMap:CollectFinished()
    LuaNetSendMsg:SendItemUseReq(self._treaseInfo.pos, 1, 0)
end

function AlearTreasureMap:onExit()
    self.m_pUILayer = nil

--重置挖矿数据
    LRoleDataMgr.isInTreasuer = false
    LRoleDataMgr.posX = 0
    LRoleDataMgr.posY = 0

    self:Destory()
end

return AlearTreasureMap
--[[
lua里面的游戏逻辑控制
]]

local MountEnforceUI = LUIBase:New()
MountEnforceUI.__index = MountEnforceUI
MountEnforceUI.HorseMaxLevel = 100
--local this = LTcpSocket
local old_num
local new_num
local num
function MountEnforceUI:New()
	local o = LUIBase:New()
	setmetatable(o,MountEnforceUI)	
    o:Init()
	return o
end
function MountEnforceUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/MountUpgradeLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:ShowSelectedHorse()
    self:AddTouchEvt()
    self:ShowEnforceRedPoint()
    self:ShowEnforceItem()
    LuaNetSendMsg:QueryHorseInfo(2, 1)   --请求强化经验

end

--[[
注册UI消息
]]
function MountEnforceUI:RegistMsgs()
    self.msgIds = 
    {
        --LUIItemListUIEvent.SelectItem,
        LUIHorseEvent.RecvEnforceValue,
    }
    self:RegistSelf(self,self.msgIds)
end


function MountEnforceUI:ProcessEvent(msg)
    if msg.msgId == LUIItemListUIEvent.SelectItem then
        if self.m_pUILayer:isVisible() then
            self:ItemSelected(msg.value)
        end
    elseif msg.msgId == LUIHorseEvent.RecvEnforceValue then
        if msg.value==nil or msg.value==0 then
             self:ShowSelectedHorse()
             return
          end  
        self.m_HorseCurLv = msg.value[1]
        self.m_StrengthExp = msg.value[2]
        self.m_StrengthExpLimit = msg.value[3]

        local hdata = LRoleDataMgr.MyHeroInfo
        local _horinfo = hdata.horseExInfo
        local useIndex = _horinfo:GetUseIndex()  
        _horinfo.qhLevel = self.m_HorseCurLv
        self.m_bHasEnforceData = true
        
        
        self:InitCurHorse()
        self:ShowSelectedHorse()
        --self:ShowItem()
        self:ShowEnforceRedPoint()
        self:ShowEnforceItem()

    end
end

function MountEnforceUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNameLabel1 = nil
    self.m_pNameLabel2 = nil
    self.m_pAniNode1 = nil
    self.m_pAniNode2 = nil
    self.m_pModelAni1 = nil
    self.m_pModelAni2 = nil
    self.m_pPowerabel1 = nil
    self.m_pPowerabel2 = nil
    for i = 1,5 do
        self.m_pAttrLabels1[i] = nil
        self.m_pAttrLabels2[i] = nil
        self.m_pAttrNameLabels1[i] = nil
        self.m_pAttrNameLabels2[i] = nil
    end
    self.m_pAttrLabels1 = nil
    self.m_pAttrLabels2 = nil
    self.m_pAttrNameLabels1 = nil
    self.m_pAttrNameLabels2 = nil
    -- for i = 1,10 do
    --     self.m_pStarImgs1[i] = nil
    --     self.m_pStarImgs2[i] = nil
    -- end
    -- self.m_pStarImgs1 = nil
    -- self.m_pStarImgs2 = nil
    -- self.m_pGlodLabel = nil
    self.m_pBtn =  nil
    self.m_pMatBtn = nil
    self.m_pMatBar = nil
    self.m_pMatLabel1 = nil
    self.m_pMatLabel2 = nil
    self.m_pMatLabel3 = nil
    self.m_pItemImg = nil
--    if self.m_pItemCell ~= nil then
--        self.m_pItemCell:Delete()
--        self.m_pItemCell = nil
--    end
    self.m_pItemCell = nil
    self.m_pAddImg = nil
    self.m_pItemNameLabel = nil
    self.m_itemId = nil
    self.m_itemNum = nil
    -- self.m_isMonyEnough = nil
    self.m_curHorseId = nil

    self.m_HorseCurLv = nil
    self.m_StrengthExp = nil
    self.m_StrengthExpLimit = nil
    self.m_bHasEnforceData = nil
    self.m_bMalLevel = nil
    self.m_isItemEnough = nil
end

function MountEnforceUI:ShowHorseStar(star)
    self.m_pQianghuaLabel1:setString(star)
    self.m_pQianghuaLabel2:setString(star + 1)
    -- local curStar = math.floor(star/10)
    -- local nextStar = math.floor((star+1)/10)
    -- for i = 1,10 do
    --     if curStar >= i then
    --         self.m_pStarImgs1[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_01.png",ccui.TextureResType.plistType)
    --     else
    --         self.m_pStarImgs1[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_02.png",ccui.TextureResType.plistType)
    --     end

    --     if nextStar >= i then
    --         self.m_pStarImgs2[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_01.png",ccui.TextureResType.plistType)
    --     else
    --         self.m_pStarImgs2[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_02.png",ccui.TextureResType.plistType)
    --     end
    -- end
end

function MountEnforceUI:ShowEnforceItem()
    self.m_itemId = 0
    self.m_itemNum = 0
    for i = #AppDef.Mount.EnforceStoneIds, 1, -1 do
        local pid = AppDef.Mount.EnforceStoneIds[i]
        local num = LRoleDataMgr.Equip:CountItemNumById(pid)
        if num > 0 then
            self.m_itemId = pid
            self.m_itemNum = num
            break
        end
    end 
    if self.m_itemId == 0 then
        self.m_itemId = AppDef.Mount.EnforceStoneIds[1]
    end
    self:ShowItem()
    -- self.m_itemId = msg.id
    -- self.m_itemNum = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
    -- if self.m_itemNum == 0 then
    --     self.m_itemId = 0
    --     LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Lua_DaoZaoTip1)
    --     self:SendMsg(LGameMsg.m_scrollTipsMsg)
    -- end
    -- self:ShowItem()
end

function MountEnforceUI:ItemSelected(msg)
    self.m_itemId = msg.id
    self.m_itemNum = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
    if self.m_itemNum == 0 then
        self.m_itemId = AppDef.Mount.EnforceStoneIds[1]
    end
    self:ShowItem()
end

function MountEnforceUI:ShowItem()
    local exp = 0
    local money = 0
    --local info = LRoleDataMgr.Equip.GetPackageMap()
    local haveNum = 0
    if LItemMgr:IsHorseStrengthStone(self.m_itemId) then   --上次选择为特定等级强化石头
        haveNum = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
--        if haveNum <= 0 then
--            self.m_itemId = -1
--            self.m_itemNum = 0
--        end
--    else
--        haveNum = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId) --目前拥有的数量
--        if haveNum <= 0 then
--            self.m_itemId = -1
--            self.m_itemNum = 0
--        elseif haveNum < self.m_itemNum then
--            self.m_itemNum = haveNum
--        end
    end
    local numLabel = self.m_pMatBtn:getChildByName("Value")
    -- numLabel:setString( "" .. self.m_itemNum .. "/" .. haveNum)
    -- if self.m_itemNum > haveNum then    --数目不够按钮不可用且灰色显示
    --     numLabel:setTextColor(AppDef.UIColor.RED)
    --     self.m_isItemEnough = false
    -- else
    --     numLabel:setTextColor(AppDef.UIColor.GREEN)
    --     self.m_isItemEnough = true
    -- end
    numLabel:setString( "" .. haveNum)
    if haveNum <= 0 then    --数目不够按钮不可用且灰色显示
        numLabel:setTextColor(AppDef.UIColor.RED)
        self.m_isItemEnough = false
    else
        numLabel:setTextColor(AppDef.UIColor.GREEN)
        self.m_isItemEnough = true
    end
    local exp = 0
    self.m_pItemImg:setVisible(true)
    self.m_pAddImg:setVisible(false)
    numLabel:setVisible(true)
    if self.m_itemNum < 1 then
        --self.m_pItemNameLabel:setString(LuaStr_Str52)
        local itemData = LItemMgr:getItem(self.m_itemId)
        if itemData ~= nil then
            self.m_pItemCell = Utils:GetItemCellValue(self.m_pItemImg, 0, self.m_itemId, true, false, 0, self.m_pItemCell, true, true)
            self.m_pItemNameLabel:setString(itemData.m_name)
        end
    elseif self.m_bMalLevel == false then
        local itemData = LItemMgr:getItem(self.m_itemId)
        self.m_pItemCell = Utils:GetItemCellValue(self.m_pItemImg, 0, self.m_itemId, true, false, 0, self.m_pItemCell, false, true)
        --self.m_pItemImg:loadTexture(string.format("item/equip%d.png",itemData.m_pic),ccui.TextureResType.localType)
        self.m_pItemNameLabel:setString(itemData.m_name)
        local citem = LDataConstMgr:getCItemByID(self.m_itemId)
        exp = citem.additionalValue * self.m_itemNum
    
        --money = LItemMgr:GetHorseStrengthStoneExp(self.m_itemId) * exp * self.m_itemNum
    end
    self:ShowMoney(money)
    if self.m_bMalLevel == false then
        self:SetProgress(self.m_StrengthExpLimit, self.m_StrengthExp, exp)
    else
        --self.m_proImgArr[1]:setVisible(true)
    end
end

-- function MountEnforceUI:FindHorseStoneDataById(id)
--     local HorseStoneAttrs = {
--         {["id"] = 2251, ["minLv"] = 0, ["maxLv"] = 9, ["exp"] = 5, ["moneyBase"] = 2 },
--         {["id"] = 2252, ["minLv"] = 10, ["maxLv"] = 19, ["exp"] = 25, ["moneyBase"] = 10 },
--         {["id"] = 2253, ["minLv"] = 20, ["maxLv"] = 39, ["exp"] = 125, ["moneyBase"] = 50 },
--         {["id"] = 2254, ["minLv"] = 40, ["maxLv"] = 79, ["exp"] = 625, ["moneyBase"] = 250 },
--         {["id"] = 2584, ["minLv"] = 0, ["maxLv"] = 79, ["exp"] = 100, ["moneyBase"] = 40 },
--         {["id"] = 2585, ["minLv"] = 0, ["maxLv"] = 79, ["exp"] = 500, ["moneyBase"] = 125 },
--         {["id"] = 2586, ["minLv"] = 0, ["maxLv"] = 79, ["exp"] = 1500, ["moneyBase"] = 600 },
--     }
--     for i=1, #HorseStoneAttrs do
--         if(HorseStoneAttrs[i].id == id)then
--             return HorseStoneAttrs[i]
--         end
--     end
--     return nil
-- end

function MountEnforceUI:InitData()
    local panel = self.m_pUILayer:getChildByName("MountUpgradeUI")
    local panel1 = panel:getChildByName("Panel")
    local panel2 = panel:getChildByName("Panel_0")
    self.m_pNameLabel1 = panel1:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pNameLabel2 = panel2:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pAniNode1 = panel1:getChildByName("aniNode")
    self.m_pAniNode2 = panel2:getChildByName("aniNode")

    self.m_pModelAni1 = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,0)
    self.m_pAniNode1:addChild(self.m_pModelAni1)

    self.m_pModelAni2 = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,0)
    self.m_pAniNode2:addChild(self.m_pModelAni2)


    self.m_pPowerabel1 = panel1:getChildByName("bg_zhanli"):getChildByName("Text")
    self.m_pPowerabel2 = panel2:getChildByName("bg_zhanli"):getChildByName("Text")

    local pHelpBtn = panel2:getChildByName("btn_Help")
    pHelpBtn:setVisible(true)
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
    self.m_pAttrLabels1 = {}
    self.m_pAttrLabels2 = {}
    self.m_pAttrNameLabels1 = {}
    self.m_pAttrNameLabels2 = {}
    local attrPanel1 = panel1:getChildByName("bg_Describe")
    local attrPanel2 = panel2:getChildByName("bg_Describe")
    for i = 1,5 do
        self.m_pAttrNameLabels1[i] = attrPanel1:getChildByName("Attribute_" .. i)
        self.m_pAttrNameLabels2[i] = attrPanel2:getChildByName("Attribute_" .. i)
        self.m_pAttrLabels1[i] = self.m_pAttrNameLabels1[i]:getChildByName("Value")
        self.m_pAttrLabels2[i] = self.m_pAttrNameLabels2[i]:getChildByName("Value")
    end
	--dump(self.m_pAttrNameLabels2)
    -- self.m_pStarImgs1 = {}
    -- self.m_pStarImgs2 = {}
    -- local starPanel1 = panel1:getChildByName("Star")
    -- local starPanel2 = panel2:getChildByName("Star")
    -- self.m_pStarImgs1[1] = starPanel1:getChildByName("Image")
    -- self.m_pStarImgs2[1] = starPanel2:getChildByName("Image")
    -- for i = 2,10 do
    --     self.m_pStarImgs1[i] = starPanel1:getChildByName("Image_" .. (i-2))
    --     self.m_pStarImgs2[i] = starPanel2:getChildByName("Image_" .. (i-2))
    -- end

    -- self.m_pGlodLabel = panel:getChildByName("Consume"):getChildByName("Value")
    self.m_pBtn =  panel:getChildByName("btn_Upgrad")
    self.m_pMatBtn = panel:getChildByName("btn_Material")
    local bgBar = panel:getChildByName("bg_Bar")
    self.m_pExpNextBar = bgBar:getChildByName("LoadingBar_1")
    self.m_pExpCurBar = bgBar:getChildByName("LoadingBar_2")
    local textLabel = bgBar:getChildByName("Value")
    local fontSize = textLabel:getFontSize()
    self.m_barSize = bgBar:getContentSize()
    self.m_pExpLabel = CCAysLabel:createWithFixedWidth(self.m_barSize.width+200,fontSize)
    --self.m_pExpLabel = textLabel
    bgBar:addChild(self.m_pExpLabel)
    textLabel:removeFromParent()

    self.m_pItemImg = self.m_pMatBtn:getChildByName("Image")
    self.m_pAddImg = self.m_pMatBtn:getChildByName("Icon")
    self.m_pItemNameLabel = panel:getChildByName("Name")
    self.m_pQianghuaLabel1 = panel1:getChildByName("Level"):getChildByName("Value")
    self.m_pQianghuaLabel2 = panel2:getChildByName("Level_0"):getChildByName("Value")
    self.m_itemId = 0
    self.m_itemNum = 0
    -- self.m_isMonyEnough = false
    self.m_curHorseId = 0

    self.m_HorseCurLv = 0
    self.m_StrengthExp = 0
    self.m_StrengthExpLimit = 0
    self.m_bHasEnforceData = false
    self.m_bMalLevel = false
    self.m_isItemEnough = false
    self:InitCurHorse()
end

function MountEnforceUI:helpButtonCallback()
    local str = GUITips.RSI_Help_Str11
    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function MountEnforceUI:ShowEnforceRedPoint()
    local redImg = self.m_pBtn:getChildByName("Prompt")
    local isVisible = LRoleDataMgr:CheckMountEnforce()
    redImg:setVisible(isVisible)
end


function MountEnforceUI:InitCurHorse()
    local hdata = LRoleDataMgr.MyHeroInfo
    local _horinfo = hdata.horseExInfo
    local useIndex = _horinfo:GetUseIndex()  
    self.m_curHorseId = 1
    if useIndex < 255 then
        local vechorsedata = LRoleDataMgr.MyHeroInfo.Horse
        local horsedata = vechorsedata[useIndex + 1]
        self.m_curHorseId = horsedata.id
    end
    local qhLevel = _horinfo.qhLevel   

    if qhLevel > MountEnforceUI.HorseMaxLevel then
        self.m_bMalLevel = true
    end

    self:ShowHorseStar(qhLevel)
end

function MountEnforceUI:ShowMoney(value)
    -- self.m_pQianghuaLabel1:setString(value)
    -- self.m_pQianghuaLabel2:setString(value + 1)
    --print("ShowMoney(value): ", value)
    -- local heroMoney = LRoleDataMgr.MyHeroInfo:GetDetailData().Money
    -- --self.m_pLabel[7]:setString(value)
    -- self.m_pGlodLabel:setString(value)

    -- if heroMoney < value then
    --     self.m_isMonyEnough = false
    --     self.m_pGlodLabel:setTextColor(UICOLOR_RED)
    -- else
    --     self.m_isMonyEnough = true
    --     self.m_pGlodLabel:setTextColor(UICOLOR_GREEN)
    -- end
end

function MountEnforceUI:AddTouchEvt()
    local function MatBtnCallback(sender)
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemListUI, {AppDef.EItemListType.EILTMountStone,self.m_HorseCurLv+1})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self.m_pMatBtn:addClickEventListener(MatBtnCallback)
	self:MarkIntaractCObj(self.m_pMatBtn)
    local function OKBtnCallback(sender)
        if self.m_bHasEnforceData == false then
            return
        end
        local hdata = LRoleDataMgr.MyHeroInfo
        local _horinfo = hdata.horseExInfo
        local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)

        local qhLevel = _horinfo:GetqhLevel()     

        if qhLevel >= MountEnforceUI.HorseMaxLevel then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_HSL_TIP3)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif self.m_isItemEnough == false then
            -- LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_HSL_TIP4)
            -- self:SendMsg(LGameMsg.m_scrollTipsMsg)
--材料不足则显示来源
            local num = LRoleDataMgr:getLowMatrialNumByType(AppDef.EItemListType.EILTMountStone)
            if num > 0 then
                Utils:ShowScrollTips(GUITips.RSI_PTL_TIP29)
            else
                local id = LRoleDataMgr:getLowMatrialIdByType(AppDef.EItemListType.EILTMountStone)
                item = 
                {
                    itemType = "CItem",
                    itemData = LItemMgr:getItem(id)
                }
                LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
                self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
        elseif(self.m_itemId < 0 or self.m_itemNum < 1)then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Lua_DaoZaoTip1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            LuaNetSendMsg:QueryHorseInfo(2, 2, self.m_itemId, self.m_itemNum)
            LuaNetSendMsg:QueryHorseInfo(1)
        end 
    end
    self.m_pBtn:addClickEventListener(OKBtnCallback)
	self:MarkIntaractCObj(self.m_pBtn)
end

function MountEnforceUI:ShowSelectedHorse()
    self:ShowCurHorse()
    self:ShowNextHorse()
end

function MountEnforceUI:ShowCurHorse()
    local hdata = LRoleDataMgr.MyHeroInfo
    local _horinfo = hdata.horseExInfo
    local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
    self.m_pModelAni1:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,horseData.id,0)
    self.m_pModelAni1:PlayStand(0)
    self.m_pPowerabel1:setString(GUITips.UI_Power_All .._horinfo.TotalPower)
	old_num = hdata:GetHorsePower(self.m_curHorseId,_horinfo.qhLevel,2)
    self.m_pNameLabel1:setString(horseData.name)

    local qhLevel = _horinfo:GetqhLevel()     

    local qianghuadata = LDataConstMgr:GetHorseStrengthData(_horinfo.qhLevel)

    for i = 1, 5 do
        if i > #qianghuadata.attrTypeArr then
            self.m_pAttrNameLabels1[i]:setVisible(false)
        else
            self.m_pAttrNameLabels1[i]:setVisible(true)
            Utils:ShowAttrLabel(self.m_pAttrNameLabels1[i], qianghuadata.attrTypeArr[i], self.m_pAttrLabels1[i], qianghuadata.attrValueArr[i])
        end
        
    end
end

function MountEnforceUI:ShowNextHorse()
    local hdata = LRoleDataMgr.MyHeroInfo
    local _horinfo = hdata.horseExInfo
    local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
    local qhLevel = _horinfo:GetqhLevel()   
    if qhLevel < MountEnforceUI.HorseMaxLevel then
        self.m_pNameLabel2:setString(horseData.name)
        self.m_pModelAni2:setVisible(true)
        self.m_pModelAni2:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,horseData.id,0)
        self.m_pModelAni2:PlayStand(0)
		new_num = hdata:GetHorsePower(self.m_curHorseId,_horinfo.qhLevel+1,2)
		num = new_num - old_num
		
        self.m_pPowerabel2:setString(_horinfo.TotalPower.." + "..num)
		
        local qianghuadata = LDataConstMgr:GetHorseStrengthData(_horinfo.qhLevel + 1)

        for i = 1, 5 do
            if i > #qianghuadata.attrTypeArr then
                self.m_pAttrNameLabels2[i]:setVisible(false)
            else
                self.m_pAttrNameLabels2[i]:setVisible(true)
                Utils:ShowAttrLabel(self.m_pAttrNameLabels2[i], qianghuadata.attrTypeArr[i], self.m_pAttrLabels2[i], qianghuadata.attrValueArr[i])
            end
            
        end
    else
        self.m_pPowerabel2:setString("0")
        self.m_pModelAni2:setVisible(false)
        self.m_pNameLabel2:setString("")
        
    end
end

function MountEnforceUI:SetProgress(totalValue, value1, value2)
    print("setProgress(), totalValue: ", totalValue, "; value1: ", value1, "; addvalue2: ", value2)
    -- local proSize = self.m_proImgArr[3]:getContentSize()   --BK
    -- local proWidth = proSize.width   --bg
    -- local proHeight = proSize.height
    
    if(value1 == nil or value1 < 0 )then
        value1 = 0
    end
    if(value2 == nil or value2 < 0)then
        value2 = 0
    end
    local percent1 = value1/totalValue
    local percent2 = (value1 + value2)/totalValue
    if(percent1 > 1)then
        percent1 = 1
    end
    if(percent2 > 1)then
        percent2 = 1
    end
    -- self.m_pMatBar:setPercent(math.floor(percent2*100))
    
    self.m_pExpNextBar:setPercent(math.floor(percent2*100))
    self.m_pExpCurBar:setPercent(math.floor(percent1*100))

    --local width = self.m_pMatBar:getContentSize().width
    if value2 > 0 then
       
        self.m_pExpLabel:setString(""..value1 .. "[c3](+"..value2..")[/c3]/" .. totalValue)
    else
        self.m_pExpLabel:setString(""..value1 .. "/" .. totalValue)
    end
    

    local msgSize = self.m_pExpLabel:getSize()
    self.m_pExpLabel:setPosition(cc.p((self.m_barSize.width - msgSize.width)/2, (self.m_barSize.height - msgSize.height)/2 + msgSize.height + 1))

    
    -- self.m_pMatLabel1:setString(""..value1)
    -- self.m_pMatLabel2:setString("(+"..value2..")")
    -- self.m_pMatLabel3:setString("/"..totalValue)
    -- local labelW1 = self.m_pMatLabel1:getContentSize().width
    -- local labelW2 = self.m_pMatLabel2:getContentSize().width
    -- local labelW3 = self.m_pMatLabel3:getContentSize().width
    -- local midPos
    -- if value2 == 0 then
    --     self.m_pMatLabel2:setVisible(false)
    --     midPos = (width - labelW1 - labelW3)/2
    --     self.m_pMatLabel3:setPositionX(midPos)
    --     self.m_pMatLabel1:setPositionX(midPos - labelW3/2 - labelW1/2)
    -- else
    --     self.m_pMatLabel2:setVisible(true)
    --     midPos = (width - labelW1 - labelW2 - labelW3)/2
    --     self.m_pMatLabel2:setPositionX(midPos)
    --     self.m_pMatLabel1:setPositionX(midPos - labelW2/2 - labelW1/2)
    --     self.m_pMatLabel3:setPositionX(midPos + labelW2/2 + labelW3/2)
    -- end
end

return MountEnforceUI
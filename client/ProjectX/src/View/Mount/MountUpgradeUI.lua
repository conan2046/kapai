--[[
lua里面的游戏逻辑控制
]]

local MountUpgradeUI = LUIBase:New()
MountUpgradeUI.__index = MountUpgradeUI
--local this = LTcpSocket
function MountUpgradeUI:New()
	local o = LUIBase:New()
	setmetatable(o,MountUpgradeUI)	
    o:Init()
	return o
end


function MountUpgradeUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/MountjinjieLayer.csb")
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
    self:AddTouchEvt()
    self:SetCurSelect(1)
    self:ShowUpgradeRedPoint()
    
    -- self:ShowAttr()
    -- self:ShowEquip()
    -- self:SetCurAttrTab(1)

end


--[[
注册UI消息
]]
function MountUpgradeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIItemListUIEvent.SelectItem,
        LUIHorseEvent.HorseListChange,
        LUILogicEvent.buyItemSucEvent,
    }
    self:RegistSelf(self,self.msgIds)
end

function MountUpgradeUI:ProcessEvent(msg)
    if msg.msgId == LUIHorseEvent.HorseListChange then
        self:DataChanged()
    elseif msg.msgId == LUIItemListUIEvent.SelectItem then
        if not self.m_pUILayer:isVisible() then
            return
        end
        local itemInfo = msg.value
        if itemInfo == nil then
            return
        end
        local itemId = itemInfo["id"]
        local itemNum = itemInfo["num"]
        self:ShowSelectStoneCnt(itemId,itemNum)
    elseif msg.msgId == LUILogicEvent.buyItemSucEvent then
        if LFastShopDataMgr.m_curUseMattrial == AppDef.upgradeMaterial_ID.FM_Mount_upgrade then
            self:DataChanged()
            LuaNetSendMsg:QueryHorseInfo(3)  --进阶操作
            LuaNetSendMsg:QueryHorseInfo(1)
        end
    end
end

function MountUpgradeUI:DataChanged()
    self:SetCurSelect(1)
    self:ShowUpgradeRedPoint()
end

function MountUpgradeUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pItemCell = nil
    self.m_pBtn = nil
    self.m_pNameLabel1 = nil
    self.m_pNameLabel2 = nil
    self.m_pAniNode1 = nil
    self.m_pAniNode2 = nil
    self.m_pModelAni1 = nil
    self.m_pModelAni2 = nil
    self.m_pPowerabel1 = nil
    self.m_pPowerabel2 = nil
    self.m_pSpdLabel1 = nil
    self.m_pSpdLabel2 = nil
    self.m_pGlodLabel = nil
    self.m_pMatBtn = nil
    self.m_pGoldBtn = nil
    self.m_curHorseId = nil
    self.m_isMonyEnough = nil
end

function MountUpgradeUI:InitData()
    local panel = self.m_pUILayer:getChildByName("MountjinjieUI")
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
    self.m_pSpdLabel1 = panel1:getChildByName("bg_Describe"):getChildByName("Text")
    self.m_pSpdLabel2 = panel2:getChildByName("bg_Describe"):getChildByName("Text")
    self.m_pGlodLabel = panel:getChildByName("Consume"):getChildByName("Value")
    self.m_pBtn =  panel:getChildByName("btn_jinjie")
    self.m_pMatBtn = panel:getChildByName("btn_Material")
    self.m_pGoldBtn = panel:getChildByName("btn_Material_0")

    local pHelpBtn = panel2:getChildByName("btn_Help")
    pHelpBtn:setVisible(true)
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
    self.m_curHorseId = 0
    self.m_isMonyEnough = false
end

--[[
初始化当前进阶的坐骑
]]

function MountUpgradeUI:helpButtonCallback()
    local str = GUITips.RSI_Help_Str10
    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end



function MountUpgradeUI:InitCurUpgradeMount()
    local mountArr = LDataConstMgr:GetHorseConfigArr()
    local curId = 1--默认等于1
    for i = #mountArr,1,-1 do
        if mountArr[i].isGet == true and mountArr[i].jinjieId > 0 then
            self.m_curHorseId = mountArr[i].jinjieId
            curId = mountArr[i].id
            break
        end
    end
    if self.m_curHorseId > 0 then
        local hdata = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
        if hdata.isGet == false then
            self.m_curHorseId = curId
        end
    else
        self.m_curHorseId = 1
    end
end

function MountUpgradeUI:SetCurSelect(curHorseId)
    self:clearLackItemData()
    self:InitCurUpgradeMount()
    self:ShowSelectedHorse()
end

function MountUpgradeUI:ShowSelectedHorse()
    self:ShowCurHorse()
    self:ShowNextHorse()
    self:ShowConsume()
end

function MountUpgradeUI:ShowCurHorse()
    local hdata = LRoleDataMgr.MyHeroInfo
    local _horinfo = hdata.horseExInfo
    local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
    self.m_pModelAni1:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,horseData.id,0)
    self.m_pModelAni1:PlayStand(0)

    --self.m_pPowerabel1:setString(GUITips.UI_Power_All .. hdata:GetHorsePower(self.m_curHorseId,_horinfo.qhLevel,0))

    self.m_pPowerabel1:setString(GUITips.UI_Power_All .. _horinfo.TotalPower)
    self.m_pSpdLabel1:setString(GUITips.UI_Move_Speed .. horseData.moveSpeed .. "%")

    self.m_pNameLabel1:setString(horseData.name)
end

function MountUpgradeUI:ShowNextHorse()
    local hdata = LRoleDataMgr.MyHeroInfo
    local _horinfo = hdata.horseExInfo
    local  horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)

    local nextData = LDataConstMgr:GetHorseConfigData(horseData.jinjieId)
     local  TotalPower = 0
    if nextData ~= nil then
        local horseList = LDataConstMgr:GetHorseConfigArr()
        for i = 1, #horseList do
            if horseList[i].id==nextData.id then
                  for i = 2, 5 do
                     attrType = horseList[i].attrTypeArr[i-1]
                     attrValue = horseList[i].attrValueArr[i-1]
                     TotalPower=LDataConstMgr:GetSingleAttrPower(attrType,attrValue)+TotalPower
                  end             
            end
         end 
        -- self.m_pNameLabel2:setString(LDataConstMgr:GetHorseName(self.m_curHorseId))
        self.m_pNameLabel2:setString(nextData.name)
        self.m_pModelAni2:setVisible(true)
        self.m_pModelAni2:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,nextData.id,0)
        self.m_pModelAni2:PlayStand(0)
        self.m_pSpdLabel2:setString(GUITips.UI_Move_Speed .. nextData.moveSpeed .. "%")
        self.m_pPowerabel2:setString( _horinfo.TotalPower.."+"..TotalPower)
        
    else
        self.m_pPowerabel2:setString(GUITips.UI_Power_All .. "0")
        self.m_pModelAni2:setVisible(false)
        self.m_pNameLabel2:setString("")
        self.m_pSpdLabel2:setString(GUITips.UI_Move_Speed .. "0")
    end
end

function MountUpgradeUI:ShowHorseStar(star)
    -- local starBrightPath = "UI/ui_common/ui_zuoqi_xing_01"
    -- local starHalfBrightPath = "UI/ui_common/ui_zuoqi_xing_03"
    -- local starGrayPath = "UI/ui_common/ui_zuoqi_xing_02"
    -- local maxStar = 10
    
    -- local star1x = 35.0
    -- local star11x = 547.0
    -- local starw = 28
    -- local starh = 28
    -- local stargw = 30
    -- local stargh = 30
    -- local originY = 384.0
    -- local showY = 386.0
    -- for i=1, 20 do
    --     self.m_pStar[i]:setVisible(true)
    --     self.m_pStar[i]:initWithSpriteFrameName("star_gray.mydp")
    --     self.m_pStar[i]:setAnchorPoint(ccp(0.5,0.5))
    --     self.m_pStar[i]:setContentSize(CCSize(starw,starh))
    --     self.m_pStar[i]:setScale(28.0/35.0)
    --     if (i <= 10)then
    --         self.m_pStar[i]:setPositionX((i-1)*stargw + star1x)
    --     else
    --         self.m_pStar[i]:setPositionX((i - 11)*stargw + star11x)
    --     end
    --     self.m_pStar[i]:setPositionY(originY)
    -- end

    -- if(star > HorseLayer_HorseMaxLevel)then
    --     return;
    -- end

    -- local starPNG = {"xing_bai.mydp","xing_lv_nor.mydp","xing_lv.mydp","xing_lan_nor.mydp","xing_lan.mydp","xing_zi_nor.mydp","xing_zi.mydp","xing_cheng_nor.mydp","xing_cheng.mydp","xing_fen_nor.mydp","xing_fen.mydp","xing_hong_nor.mydp","xing_hong.mydp"}
    -- local starIndex = math.ceil(star/10)
    -- local starIndex2 = starIndex
    -- local starLimit = star%10
    -- if(star > 0 and starLimit == 0)then
    --     starLimit = 10
    --     starIndex2 = starIndex + 1
    -- end
    -- --print("star: ", star, "starIndex: ", starIndex, "; starIndex2: ", starIndex2, "; starLimit: ", starLimit)
    -- if(star >= 100)then
    --     for i=1, 10 do
    --         self.m_pStar[i]:setPositionY(showY)
    --         self.m_pStar[i]:initWithSpriteFrameName(starPNG[11])
    --         self.m_pStar[i]:setVisible(true)
    --     end
    -- else
    --     for i=1, 10 do
    --         if(i <= starLimit)then
    --             self.m_pStar[i]:setPositionY(showY)
    --             self.m_pStar[i]:initWithSpriteFrameName(starPNG[starIndex + 1])
    --             self.m_pStar[i]:setVisible(true)
    --         else
    --             if(starIndex>0)then
    --                 self.m_pStar[i]:setPositionY(showY)
    --                 self.m_pStar[i]:initWithSpriteFrameName(starPNG[starIndex])
    --                 self.m_pStar[i]:setVisible(true)
    --             end
    --         end
    --     end
    -- end


    -- local star2 = star + 1
    -- local starLimit2 = star2%10 
    -- if(star2 > 0 and starLimit2 == 0)then
    --     starLimit2 = 10
    -- end
    -- --print("star2: ", star2, "starIndex: ", starIndex, "; starIndex2: ", starIndex2, "; starLimit2: ", starLimit2)
    -- if(star2 >= 100)then
    --     if(star2 > HorseLayer_HorseMaxLevel )then
    --         return;
    --     end
    --     for i=1, 10 do
    --         self.m_pStar[i+10]:setPositionY(showY)
    --         self.m_pStar[i+10]:initWithSpriteFrameName(starPNG[1])
    --         self.m_pStar[i+10]:setVisible(true)
    --     end
    -- else
    --     for i=1, 10 do
    --         if(i <= starLimit2)then
    --             self.m_pStar[i+10]:setPositionY(showY)
    --             self.m_pStar[i+10]:initWithSpriteFrameName(starPNG[starIndex2 + 1])
    --             self.m_pStar[i+10]:setVisible(true)
    --         else
    --             if(starIndex>0)then
    --                 self.m_pStar[i+10]:setPositionY(showY)
    --                 self.m_pStar[i+10]:initWithSpriteFrameName(starPNG[starIndex2])
    --                 self.m_pStar[i+10]:setVisible(true)
    --             end
    --         end
    --     end
    -- end
end

function MountUpgradeUI:ShowConsume()
    local hdata = LRoleDataMgr.MyHeroInfo
    local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
    -- local packageList = LRoleDataMgr.Equip.PackageList
    -- local item = {0,0,0,0}
    -- local picid = {5005,5005,1522,1522}

    -- for i = 1,#packageList do
    --     if horseData.id == 1 and packageList[i]:getID() == 2301 then
    --         item[1] = item[1] + packageList[i].m_num--葫芦进阶丹数目
    --     end
    -- end
    
    local cnt = self.m_pMatBtn:getChildByName("Value_0")

    if horseData.jinjieId > 0 then
        local advMoney = horseData:GetJinjieMoney()
        self.m_pGlodLabel:setString(advMoney)
        local heroMoney = LRoleDataMgr.MyHeroInfo:GetDetailData().Money
        if heroMoney < advMoney then
            self.m_isMonyEnough = false
            self.m_pGlodLabel:setTextColor(AppDef.UIColor.RED)
            self:addLackItemData(AppDef.AwrdItem.AWRD_ITEM_COIN, advMoney - heroMoney)
        else
            self.m_isMonyEnough = true
            self.m_pGlodLabel:setTextColor(AppDef.UIColor.GREEN)
        end
        local itemId,itemNum = horseData:GetJinjieItem()
        self:ShowSelectStoneCnt(itemId, itemNum)
    else
        self.m_pGlodLabel:setString("0")
        cnt:setVisible(false)
    end
end

function MountUpgradeUI:ShowSelectStoneCnt(itemId, needNum)
    local citem = LDataConstMgr:getCItemByID(itemId)
    local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    
    local img = self.m_pMatBtn:getChildByName("Image")
    local cnt = self.m_pMatBtn:getChildByName("Value_0")
    self.m_pItemCell = Utils:GetItemCellValue(img, 0, itemId, true, false, 0, self.m_pItemCell, true, true)
    --img:loadTexture(string.format("item/equip%d.png",citem.m_pic),ccui.TextureResType.localType)
    cnt:setVisible(true)
    cnt:setString(tostring(myItemNum).."/"..tostring(needNum))
    if needNum <= myItemNum then
        self.m_isItemEnough = true
        cnt:setTextColor(AppDef.UIColor.GREEN)
    else
        self.m_isItemEnough = false
        cnt:setTextColor(AppDef.UIColor.RED)
        self:addLackItemData(itemId, needNum - myItemNum)
    end
end

function MountUpgradeUI:ShowUpgradeRedPoint()
    local redImg = self.m_pBtn:getChildByName("Prompt")
    local isVisible = LRoleDataMgr:CheckMountUpgrade()
    redImg:setVisible(isVisible)
end

function MountUpgradeUI:AddTouchEvt()
    local function UpgradeCallback(sender)

        local horseList = LDataConstMgr:GetHorseConfigArr()
        local myHorse = LRoleDataMgr.MyHeroInfo.Horse
        if #myHorse == 0 then
            return
        end
        local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
        if horseData.jinjieId == 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_HSL_TIP5)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif self.m_isItemEnough == false then
--            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_HSL_TIP6)
--            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            LFastShopDataMgr:ShowNeedBuyMaterial(self._materialArr, AppDef.upgradeMaterial_ID.FM_Mount_upgrade)
        elseif self.m_isMonyEnough == false then
            -- LuaNetSendMsg:QueryHorseInfo(3)  --进阶操作
            -- LuaNetSendMsg:QueryHorseInfo(1)
            LFastShopDataMgr:ShowNeedBuyMaterial(self._materialArr, AppDef.upgradeMaterial_ID.FM_Mount_upgrade)
        else
            LuaNetSendMsg:QueryHorseInfo(3)  --进阶操作
            LuaNetSendMsg:QueryHorseInfo(1)
            
        end
    end
    self.m_pBtn:addClickEventListener(UpgradeCallback)
	self:MarkIntaractCObj(self.m_pBtn)
    local function MaterialCallback(sender)
        local horseData = LDataConstMgr:GetHorseConfigData(self.m_curHorseId)
        if horseData.jinjieId == 0 then
            return
        end
        local itemId,itemNum = horseData:GetJinjieItem()
        local citem = LDataConstMgr:getCItemByID(itemId)

        local item = 
        {
            itemType = "CItem",
            itemData = citem,
        }
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        -- LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemListUI, {AppDef.EItemListType.EILTMountUpgradeStone, self.m_curHorseId})
        -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self.m_pMatBtn:addClickEventListener(MaterialCallback)
	self:MarkIntaractCObj(self.m_pMatBtn)
    local function ShowGoldTips(sender)
        Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
    end
    self.m_pGoldBtn:addClickEventListener(ShowGoldTips)
	self:MarkIntaractCObj(self.m_pGoldBtn)
end

--升级消耗材料
function MountUpgradeUI:addLackItemData(id, num)
    -- body
    local material = {}
    material.id = id
    material.num = num
    table.insert(self._materialArr, material)
end

function MountUpgradeUI:clearLackItemData( ... )
    -- body
    self._materialArr = {}
end

return MountUpgradeUI
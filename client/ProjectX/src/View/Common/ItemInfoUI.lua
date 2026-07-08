--[[
lua里面的游戏逻辑控制

userData数据结构：
{
    （必选）itemType：字符串，可选值有：   "Equip"        装备
                                         "CItem"        道具
                                         "Skill"       技能
                                         "PreView"     预览
                                         "Wing"        翅膀
                                         "Mount"       坐骑
                                         ...按需添加
    （必选）itemData:  LPItem数据结构或者LPetSkill数据结构获取CItem数据结构--CItem必须对应CItem类型
    （可选）pos:       item的位置，比如在装备栏的位置,下标从1开始
    （可选）fromShop:  是否来自商城道具：true,false,nil
    （可选）quality：品质
    （可选）showFrom: 显示来源（隐藏右侧按钮，暂只支持"CItem",默认为true）
     (可选）skLevel：技能等级
    ...后续按需要添加
}
]]
local ShopDef = require("View.Shop.ShopDef")

local ItemInfoUI = LUIBase:New()
ItemInfoUI.__index = ItemInfoUI
--local this = LTcpSocket
function ItemInfoUI:New(userData)
   
	local o = LUIBase:New()
	setmetatable(o,ItemInfoUI)	
    o:Init(userData)
 
	return o
end


function ItemInfoUI:Init(userData)
    --self.m_pNode = cc.Node:create()
    --print("执行3.1")
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/SourceLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:InitTouchEvt()
    self:RegistMsgs()
    --print("执行3.3")
    self:ShowItem(userData)

    --self:ShowVersion()
end

function ItemInfoUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    self.m_bgClosePanel = panel
    local bgPanel = panel:getChildByName("Panel_1_0")
    self.m_pItemIconPanel = bgPanel:getChildByName("Image_2")
    self.m_pSkillIconPanel = bgPanel:getChildByName("Image_4")
    self.m_signImg = bgPanel:getChildByName("Image_3")
    self.m_signImg:setVisible(false)
    self.m_pNameLabel = bgPanel:getChildByName("nameLabel")
    self.m_pNameLabel:disableEffect()
    self.m_pTypeLabel = bgPanel:getChildByName("typeLabel")
    self.m_pTypeLabel:setString("")
    self.m_pPowerLabel =  bgPanel:getChildByName("powerLabel")
    self.m_pInfoListView = bgPanel:getChildByName("infoListView")
    self.m_pInfoListView:setItemsMargin(5)
    self.m_pLineImg = bgPanel:getChildByName("Line")
    self.m_pLineImg:retain()
    self.m_pLineImg:removeFromParent()
    self.m_pCloseBtn = bgPanel:getChildByName("closeBtn")
    --self.m_pBtnListPanel = bgPanel:getChildByName("Btn_ListView")
    --self.m_pBtmBtnListPanel = bgPanel:getChildByName("Btn_ListView_0")
    --self.m_pBaseBtn = self.m_pBtnListPanel:getChildByName("commonBtn1")
    --self.m_pBaseBtn:retain()
    --self.m_pBaseBtn:removeFromParent()
    self.m_pFromPanel = bgPanel:getChildByName("Btn_ListView") 
    self.m_pFromLabel = self.m_pFromPanel:getChildByName("Text")
    self.m_pFromList = self.m_pFromPanel:getChildByName("List")
    self.m_pFromBtn = bgPanel:getChildByName("SystemBtn")
    self.m_pFromBtn:getChildByName("Name"):setVisible(false)
    self.m_pFromBtn:setAnchorPoint(0,0)
    self.m_pFromBtn:retain()
    self.m_pFromBtn:removeFromParent()

    self.m_itemType = 0
    self.m_itemData = nil
    self.m_isShopItem = false
    self.m_isShowFrom = false
    self.m_pos = 0
end

function ItemInfoUI:InitTouchEvt()
    local function closeCallback(sender)
        self:CloseUI()
    end
    self.m_pCloseBtn:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
    self.m_bgClosePanel:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_bgClosePanel)
end

--[[
显示道具
userData数据结构：
{
    （必选）itemType：字符串，可选值有：   "Equip"        装备
                                         "CItem"        道具
                                         "Skill"       技能
                                         "PreView"     预览
                                         "Wing"        翅膀
                                         "Mount"       坐骑
                                         ...按需添加
    （必选）itemData:  LPItem数据结构或者LPetSkill数据结构获取CItem数据结构--CItem必须对应CItem类型
    （可选）pos:       item的位置，比如在装备栏的位置,下标从1开始
    （可选）fromShop:  是否来自商城道具：true,false,nil
    （可选）quality：品质
    （可选）showFrom: 显示来源（隐藏右侧按钮，暂只支持"CItem",默认为true）
     (可选）skLevel：技能等级
    ...后续按需要添加
}
]]
function ItemInfoUI:ShowItem(userData)
    --print("执行3.2")
    if userData == nil then
        return
    end
    self.m_itemType = userData["itemType"]
    self.m_itemData = userData["itemData"]
    -- dump(self.m_itemData, "ShowItem ======================>")
    self.m_quality = userData["quality"]
    self.m_isShopItem = userData["fromShop"]
    self.m_pos = userData["pos"]
    self.m_isShowFrom = userData["showFrom"] or true
    self.m_skillLevel = userData["skLevel"] or AppDef.Pet.MaxBornSkillLv
    if self.m_isShowFrom == nil then
        self.m_isShowFrom = true
    end
    if self.m_isShopItem == nil then
        self.m_isShopItem = false
    end

    if self.m_pos == nil then
        self.m_pos = 0
    end
    userData["itemType"] = nil
    userData["itemData"] = nil
    userData["quality"] = nil
    userData["fromShop"] = nil
    userData["pos"] = nil
    userData["showFrom"] = nil
    --self:InitItemBtns()
    if self.m_itemType == "CPetSkill" then
        self.m_pItemIconPanel:setVisible(false)
        self.m_pSkillIconPanel:setVisible(true)
        self:ShowCPetSkillInfo(self.m_itemData)
    elseif self.m_itemType == "CItem" then
        self.m_pItemIconPanel:setVisible(true)
        self.m_pSkillIconPanel:setVisible(false)
        self:ShowCItemInfo(self.m_itemData.m_item)
    elseif self.m_itemType == "Wing" then
        self.m_pItemIconPanel:setVisible(true)
        self.m_pSkillIconPanel:setVisible(false)
        self:ShowWingInfo(self.m_itemData)
    elseif self.m_itemType == "Mount" then
        self.m_pItemIconPanel:setVisible(true)
        self.m_pSkillIconPanel:setVisible(false)
        self:ShowMountInfo(self.m_itemData)
    elseif self.m_itemType == "Equip" then
        self.m_pItemIconPanel:setVisible(true)
        self.m_pSkillIconPanel:setVisible(false)
        self:ShowPetEquidInfo(self.m_itemData)
    elseif self.m_itemType == "Money" then
        self.m_pItemIconPanel:setVisible(true)
        self.m_pSkillIconPanel:setVisible(false)
        self.m_itemData = LPItem:New(self.m_itemData)
        self:ShowBaseInfo(self.m_itemData)
        self:ShowDetailInfo(self.m_itemData, false)

    else
        self.m_pItemIconPanel:setVisible(true)
        self.m_pSkillIconPanel:setVisible(false)
        self:ShowBaseInfo(self.m_itemData)
        self:ShowDetailInfo(self.m_itemData,self.m_isShopItem)
    end
    
end

--[[
显示citem信息
]]
function ItemInfoUI:ShowCItemInfo(itemData)
   
    -- dump(itemData, "ShowCItemInfo ===>")

    if itemData == nil or type(itemData) ~= "table" then return end
    self.m_pNameLabel:setString(itemData.name)
    local color = AppDef:GetItemQualityColor(itemData.quality)
    self.m_pNameLabel:setTextColor(color)

    self.m_pItemIconPanel:removeAllChildren()

    local str = AppDef.ColorKuangArr[itemData.quality]
    if itemData.quality and str ~= nil then
        local qualityImg = ccui.ImageView:create(str, UI_TEX_TYPE_PLIST)
        local size = self.m_pItemIconPanel:getContentSize()
        local itemSize = qualityImg:getContentSize()
        qualityImg:setScale(size.width/itemSize.width,size.height/itemSize.height)
        qualityImg:setPosition(size.width/2, size.height/2)
        self.m_pItemIconPanel:addChild(qualityImg)
    end
  

    local str
    if itemData ~= nil and (itemData.type == 2) then
        str = "res2/Monster_Bust/" .. itemData.pic.. "_tou.png"
    else
        str = "item/equip" .. itemData.pic .. ".png"
    end

    local itemImg = ccui.ImageView:create(str,ccui.TextureResType.localType)
    local size = self.m_pItemIconPanel:getContentSize()
    local itemSize = itemImg:getContentSize()
    itemImg:setScale(size.width/itemSize.width,size.height/itemSize.height)
    itemImg:setPosition(size.width/2, size.height/2)
    self.m_pItemIconPanel:addChild(itemImg)
    self.m_pPowerLabel:setString("")
   
    --self:AddLine()
    local label = self:AddLabel(itemData.des, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE) 
    self:TextLineFeed(label,305)

    if string.len(itemData.item_from) > 0 then
        self:AddLine()
        local label = self:AddLabel(itemData.item_from, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE) 
        self:TextLineFeed(label,305)    
    end
    self.m_isShowFrom = true
    if self.m_isShowFrom and #itemData.item_source > 0 then
        --self.m_pBtnListPanel:setVisible(false)
        --self.m_pBtmBtnListPanel:setVisible(false)
        self.m_pFromPanel:setVisible(true)
        self:ShowFromInfo()
    else
        self.m_pFromPanel:setVisible(false)
    end
end

function ItemInfoUI:ShowPetSkillInfo(skData)
    self.m_pNameLabel:setString(skData.skDetail.name)
    self.m_pNameLabel:setTextColor(UICOLOR_YELLOW) --CCWHITE
    if skData.level == 0 and self.m_pos <= AppDef.Pet.MaxBornSkillNum then
        self.m_pTypeLabel:setString(GUITips.Activity_Cnt_1)
        self.m_pTypeLabel:setTextColor(AppDef.UIColor.RED) --CCWHITE
    else
        -- self.m_pTypeLabel:setString("Lv." .. skData.level)
        -- self.m_pTypeLabel:setTextColor(UICOLOR_ORANGE) --CCWHITE
        self.m_pTypeLabel:setString("")
    end
    
    self.m_pPowerLabel:setString("")

    self.m_pSkillIconPanel:removeAllChildren()

    --parent, skData, quality,isBronSkill, showLv, scale
    SkillCellUI:New(self.m_pSkillIconPanel,skData, self.m_petQuality, self.m_pos < AppDef.Pet.MaxBornSkillNum,false,1.0)
    


    self:AddLine()

    self:AddLabel(GUITips.Skill_Info_DescTitle, AppDef.FNT_NAMEC, AppDef.FNT_SIZE_M, UICOLOR_YELLOW_PALE)

    local curDesc = LDataConstMgr:GetHeroSkillDesc(skData.skDetail.id, skData.level)
    local label = self:AddLabel(curDesc, AppDef.FNT_NAMEC, AppDef.FNT_SIZE_M, UICOLOR_YELLOW_PALE)     
    local labelHeight = self:TextLineFeed(label,305)
    local pos = cc.p(label:getPosition())
    --label:setVisible(false)
    local newLabel = CCAysLabel:createWithString(curDesc, 280, 22, UICOLOR_YELLOW_PALE)
    label:addChild(newLabel)
    label:setString("")
    newLabel:setPositionY(labelHeight)

    if skData.level == 0 then
        self:AddLine()
        self:AddLabel(GUITips.Skill_Info_UnlockTitle, AppDef.FNT_NAMEC, AppDef.FNT_SIZE_M, UICOLOR_YELLOW_PALE)

        local tips = string.format(GUITips.UI_Pet_Born_Skill_UnLock_Tip,self.m_pos)
        self:AddLabel(tips, AppDef.FNT_NAMEC, AppDef.FNT_SIZE_M, AppDef.UIColor.RED)     
    end
    
end

function ItemInfoUI:ShowCPetSkillInfo(skData)
    self.m_pNameLabel:setString(skData.name)
    self.m_pNameLabel:setTextColor(UICOLOR_YELLOW) --CCWHITE

    self.m_pTypeLabel:setString("Lv." .. (self.m_skillLevel or AppDef.Pet.MaxBornSkillLv))
    self.m_pTypeLabel:setTextColor(UICOLOR_ORANGE) --CCWHITE
    self.m_pPowerLabel:setString("")

    self.m_pSkillIconPanel:removeAllChildren()
    local size = self.m_pSkillIconPanel:getContentSize()
    local iconImg = ccui.ImageView:create()
    iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", skData.id), ccui.TextureResType.localType)
    iconImg:setScale(0.88)
    iconImg:setPosition(size.width/2, size.height/2)
    self.m_pSkillIconPanel:addChild(iconImg)


    self:AddLine()

    self:AddLabel(GUITips.Skill_Info_DescTitle, AppDef.FNT_NAMEC, AppDef.FNT_SIZE_M, UICOLOR_YELLOW_PALE)

    local curDesc = LDataConstMgr:GetHeroSkillDesc(skData.id, self.m_skillLevel or AppDef.Pet.MaxBornSkillLv)
    local label = self:AddLabel(curDesc, AppDef.FNT_NAMEC, AppDef.FNT_SIZE_M, UICOLOR_YELLOW_PALE)   
    local labelHeight = self:TextLineFeed(label,305)
    local pos = cc.p(label:getPosition())
    local newLabel = CCAysLabel:createWithString(curDesc, 280, 22, UICOLOR_YELLOW_PALE)
    label:addChild(newLabel)
    label:setString("")
    newLabel:setPositionY(labelHeight)  
    --self:TextLineFeed(label,300)
end

function ItemInfoUI:AddLabel(str,fontname,fontsize,color)
    local label = ccui.Text:create(str,fontname,fontsize)
    label:setColor(color)
    self.m_pInfoListView:pushBackCustomItem(label)
    return label
end

--文本换行
function ItemInfoUI:TextLineFeed(label,maxWidth)
   if label == nil then
       return 0
   end
   local size = label:getAutoRenderSize()
   local row = math.ceil(size.width/maxWidth)
   label:ignoreContentAdaptWithSize(false)
   local height = row*size.height+size.height/2
   label:setContentSize(cc.size(maxWidth,height))
   return height
end

function ItemInfoUI:AddLine()
    local line = self.m_pLineImg:clone()
    self.m_pInfoListView:addChild(line)
end

function ItemInfoUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemInfoUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end


--来源面板
function ItemInfoUI:ShowFromInfo(sources)
    local function showIcon(sourceBtn,sId)
        sId = sId or 0
        --显示来源Icon
        if sourceBtn == nil or sId == 0 then
            return
        end
--        local data = LDataConstMgr:GetFunctionLevelData(sourceInfo.id)
--        if data == nil then return end
        local cfg = JsonConfig.m_functionConfig.getDefByID(sId)
        if cfg == nil then return end
        local res = "res2/Icon/ui_main_icon/"..cfg.icon..".png"
        local size = self.m_pFromBtn:getContentSize()
        --sourceBtn:ignoreContentAdaptWithSize(false)   
        sourceBtn:loadTextureNormal(res) 
        local curSize  = sourceBtn:getVirtualRendererSize()  
        sourceBtn:setScale(size.width/curSize.width)

        local nameLabel = sourceBtn:getChildByName("Name")
        nameLabel:setString(cfg.name)
    end

    local function onClick(sender)
        --来源Icon点击
        local value = sender.userObject
        local id = value[1]
        local param = value[2] or 0
        if param == 0 and id > 0 then
            Utils:OpenFunction(id)
        end
        --Utils:OpenFunction(source.id)
        self:CloseUI()
    end

    local list = nil
    if sources ~= nil then
        list = sources
    elseif  self.m_itemData ~= nil and self.m_itemData.m_item~=nil  and self.m_itemData.m_id==nil    then
        if  # self.m_itemData.m_item.item_source == 0 then return end
        list =  self.m_itemData.m_item.item_source
    elseif self.m_itemData ~= nil and self.m_itemData.m_id > 0 then
        local itemData = LItemMgr:getItem(self.m_itemData.m_id)
        if itemData == nil or #itemData.item_source == 0 then return end
        list = itemData.item_source
    end
    if list == nil or #list == 0 then return end

    local max = #list
    local line = math.ceil(max/3)  
    for i=1,max do
        local row = line - math.floor((i-1)/3)-1
        local low = (i-1)%3
        local btn = self.m_pFromBtn:clone()
        btn.userObject = list[i]
        self.m_pFromList:addChild(btn)
        btn:setPosition(cc.p(low*100,row*100))
        showIcon(btn,list[i][1])
        btn:addClickEventListener(onClick)
		self:MarkIntaractCObj(btn)
    end
    local size = self.m_pFromPanel:getContentSize()
    local height = 90+line*100
    local width = size.width
    if max < 3 then width = max * math.floor(size.width/3) + 20 end
    self.m_pFromPanel:setContentSize(cc.size(width,height))
    self.m_pFromLabel:setPosition(cc.p(35,height-30))
end

function ItemInfoUI:ShowWingInfo(id)
    local icon = ccui.ImageView:create()
    icon.userObject = id
    icon:loadTexture("res2/Wing_Bust/"..id.."_tou.png",ccui.TextureResType.localType)
    local parentHeight = self.m_pItemIconPanel:getContentSize().height
    local itemHeight = icon:getContentSize().height
    local temp = (parentHeight-itemHeight)/2
    icon:setAnchorPoint(cc.p(0,0))
    icon:setPosition(cc.p(temp,temp))
    self.m_pItemIconPanel:addChild(icon)

end

function ItemInfoUI:ShowMountInfo(id)
    local icon = ccui.ImageView:create()
    icon.userObject = id
    icon:loadTexture("res2/Horse_Bust/"..id.."_tou.png",ccui.TextureResType.localType)
    local parentHeight = self.m_pItemIconPanel:getContentSize().height
    local itemHeight = icon:getContentSize().height
    local temp = (parentHeight-itemHeight)/2
    icon:setAnchorPoint(cc.p(0,0))
    icon:setPosition(cc.p(temp,temp))
    self.m_pItemIconPanel:addChild(icon)

    local data = LDataConstMgr:GetHorseConfigData(id)
    if data == nil then return end
    self.m_pNameLabel:setString(data.name)
    self.m_pTypeLabel:setString("")
    self.m_pPowerLabel:setString("")
end


-- Data.Awrdid 奖励类型
-- Data.quality 品质
-- Data.star  星级
-- Data.pid 道具id
function ItemInfoUI:ShowPetEquidInfo(Data)
    local info = LDataConstMgr:GetPetEquipCfgData(Data.pid)
    local suitCfgData = LDataConstMgr:GetPetSuitCfgData(info.suitType)
    local strPath = ""
    local strDesc = ""
    local strFrom = ""
    local sourceTable = {}
   
     for i=1 ,#info.from do
       local from = {}
       from.id=info.from[i]
       table.insert(sourceTable,from)
     end
   
    strPath=string.format("item/%s.png", info.pic) 
    strDesc=info.unKnowDesc
    local userDefine ={picFilePath = strPath,quality = self.m_quality, star = Data.star}
    local itemValue = {}
    itemValue.userDefine = userDefine
    ItemCellUI:New(self.m_pItemIconPanel, itemValue)
    self.m_pNameLabel:setString(info.name)
    local color = AppDef:GetItemQualityColor(self.m_quality)
    self.m_pNameLabel:setTextColor(color)
    self.m_pTypeLabel:setString("")
    if info.m_item ~= nil and info.m_item.m_sell > 0 then
        local str = GUITips.RSI_SELL_ITEMS_TIPS .. tostring(info.m_item.m_sell)
        self.m_pPowerLabel:setString(str)
    else
        self.m_pPowerLabel:setString("")
    end
    --未获取描述
     local label = self:AddLabel(strDesc, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE) 
     self:TextLineFeed(label,305) 
     self:AddLine()
     --套装属性
    if suitCfgData == nil then return end
    local contentStr = string.format(GUITips.RSI_PET_SUIT_TIPS4,suitCfgData.name)
    self:AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_PURPLE_TIPS)
    
    for i = 1, suitCfgData.maxAttrNum do
        local suitStr = LDataConstMgr:GetHeroSkillDesc(suitCfgData.skillId[i], suitCfgData.skillLv[i])
        local color = UICOLOR_GRAY_TIPS
       
        local numStr = string.format(GUITips.RSI_PET_SUIT_TIPS9,suitCfgData.suitNum[i])
        local label = self:AddLabel(numStr..Utils:DeleteString(suitStr,"%[","%]"), AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, color)
        self:TextLineFeed(label,305)
       local label = self:AddLabel(strFrom, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE) 
        self:TextLineFeed(label,305)   
    end 
    --来源跳转界面
    if self.m_isShowFrom then
        --self.m_pBtnListPanel:setVisible(false)
        self.m_pFromPanel:setVisible(true)
        self:ShowFromInfo(sourceTable)
    end
end

function ItemInfoUI:ShowBaseInfo(itemData)
    
    self:ShowCommonItemBaseinfo(itemData)
    self.m_pItemIconPanel:removeAllChildren()
    local itemValue = {
                itemData = itemData,
                isShowQualityBg = true,
            }
    ItemCellUI:New(self.m_pItemIconPanel, itemValue)
end

--[[
显示常用道具基础信息
]]
function ItemInfoUI:ShowCommonItemBaseinfo(pItem)
    if pItem == nil then
        return
    end
    self.m_pNameLabel:setString(pItem.m_name)
    local color = AppDef:GetItemQualityColor(pItem.m_quality)
    self.m_pNameLabel:setTextColor(color)
    self.m_pPowerLabel:setString("") 
end

--[[
显示物品详细信息
]]
function ItemInfoUI:ShowDetailInfo(pItem, shopItem)

    if pItem == nil or pItem.m_item == nil then
        return false
    end
    local pHero = LRoleDataMgr.MyHeroInfo    
    local contentStr = ""
    local lastHight = 0
    local findAttrType = false
    local XiangXing = {
                        GUITips.Item_Info_Xian2,
                        GUITips.Item_Info_Ren,
                        GUITips.Item_Info_Mo
                    }
    local newLabel
    local function AddLabel(str,fontname,fontsize,color)
        local label = ccui.Text:create(str,fontname,fontsize)
        label:setColor(color)
        self.m_pInfoListView:pushBackCustomItem(label)
        return label
    end

    local function AddSubLabel(parent, str,fontname,fontsize,color, pos)
        local label = ccui.Text:create(str,fontname,fontsize)
        label:setAnchorPoint(cc.p(0, 0.5))
        label:setColor(color)
        parent:addChild(label)
        label:setPosition(pos)
        return label
    end

    local function AddImage(str,authpos)
        local img = ccui.ImageView:create(str)
        if authpos == nil then
            authpos = cc.p(0,1)
        end
        img:setAnchorPoint(authpos)
        self.m_pInfoListView:pushBackCustomItem(img)
    end
    local contentStr
    local function AddUseLvText(color)
        contentStr = GUITips.Item_UseLv .. pItem.m_roleLevel
        if color == nil then
            if pHero.level < pItem.m_roleLevel then
                color = CCNORMAL_RED
            else
                color = UICOLOR_YELLOW_PALE
            end
        end
        AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, color)
    end

    local function AddShopPriceText()
        if shopItem and pItem.m_price > 0 then
            contentStr = GUITips.Item_Price .. pItem.m_price
            AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE)
            return true
        end
        return false
    end

    local function AddAttrText()
        local findAttrType = false
        for i = 1, pItem.addCuiLianAttrNum do
            if pItem.addCuiLianAttrType[i] > 0 then
                if findAttrType == false then
                    findAttrType = true
                    contentStr = GUITips.Item_Info_Cuilian_Attr
                    AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE)
                end
                contentStr = LDataConstMgr:GetItemAttrName(pItem.addCuiLianAttrType[i],self.m_profession) .." ".. pItem.addCuiLianAttrVal[i]
                AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, CCBLUE)
            end
        end
        if findAttrType == true then
            self:AddLine()
        end
        findAttrType = false
        for i = 1, pItem.addXiLianAttrNum do
            if pItem.addXiLianAttrType[i] > 0 then
                if findAttrType == false then
                    findAttrType = true
                    contentStr = GUITips.Item_Info_Xilian_Attr
                    AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE)
                end
                contentStr = LDataConstMgr:GetItemAttrName(pItem.addXiLianAttrType[i],self.m_profession)
                if pItem.addXiLianAttrType[i] > AppDef.EAttrType.EAT_RESISIT_CRIT then
                    contentStr = contentStr.." "..string.format("%.2f",pItem.addXiLianAttrVal[i]/100).."%"
                else
                    contentStr = contentStr.." "..pItem.addXiLianAttrVal[i]
                end
                AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, DZ_GetAttrQualityColor(pItem.addXiLianAttrStar[i]))
            end
        end

        if findAttrType == true then
            self:AddLine()
        end
    end

    local testColor
    if LItemMgr:IsEquip(pItem.m_type) then --装备

        local prof = pItem.m_type % 10
        if prof < 1 then
            prof = 1
        elseif prof > AppDef.HeroPro.Jiuli then
            prof = AppDef.HeroPro.Jiuli
        end

        contentStr = GUITips.Item_Need_Zhongzu ..GUITips["HeroPro"..prof] 
        if pHero.professional ~= prof then
            testColor = AppDef.UIColor.RED
        else
            testColor = UICOLOR_YELLOW_PALE
        end
        AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, testColor) --职业
        self:AddLine()

        if AddShopPriceText() then
           self:AddLine()
        end

        for i=1,#pItem.m_item.m_baseAttrTypes do
            local attrType = pItem.m_item.m_baseAttrTypes[i]
            local attrValue = pItem.m_item.m_baseAttrValues[i]
            if attrType > 0 and attrValue > 0 then
               contentStr = LDataConstMgr:GetItemAttrName(attrType,self.m_profession).."：" .. attrValue  --基础属性
               newLabel = AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE)
               
               --强化属性
               local attrValue = LItemMgr:GetQiangHuaVal(pItem.m_qhLevel,pItem.m_type,attrType)
               if attrValue > 0 then
                   contentStr = "+" .. attrValue
                   AddSubLabel(newLabel, contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, CCGREEN1, cc.p(newLabel:getContentSize().width + 4, newLabel:getContentSize().height / 2))
               end
            end
        end
        self:AddLine()
        AddAttrText() 
    else
        if AddShopPriceText() then
           self:AddLine()
        end
    end

    -- dump(pItem.m_item, "RegistMsgs ==================>")

    if #pItem.m_item.item_source > 0 then
        self:ShowFromInfo(pItem.m_item.item_source)
    end

    if string.len(pItem.m_item.des) > 0 then
        --self:AddLine()
        local label = AddLabel(pItem.m_item.des, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE)     
        self:TextLineFeed(label,305)
    end

    if string.len(pItem.m_item.item_from) > 0 then
        self:AddLine()
        local label = AddLabel(pItem.m_item.item_from, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE) 
        self:TextLineFeed(label ,305)    
    end
end

--[[
注册UI消息
]]
function ItemInfoUI:RegistMsgs()
   
end

function ItemInfoUI:ProcessEvent(msg)
    
end

function ItemInfoUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemType = nil
    self.m_itemData = nil
    self.m_isShopItem = nil
    self.m_isShowFrom = nil
    self.m_pos = nil
end

return ItemInfoUI
ItemCellUI = {}
ItemCellUI.__index = ItemCellUI

--local this = LTcpSocket
--[[
itemValues数据结构：
{
	（二选一）itemData:PItem
	（二选一）userDefine:{picFilePath, quality, num, level(Pet), star(Pet,PetEquip),career(Pet),strengthenLv(PetEquip),suitId(PetEquip)}
	（可选）isShowQualityBg:true,false,默认false
	（可选）isShowNum:是否显示道具数量：true,false,默认false
	（可选）isChangeSize:是否缩放已匹配父节点大小
}
]]
function ItemCellUI:New(parent, itemValues)
	local o = {}
	setmetatable(o,ItemCellUI)	
    o:Init(parent, itemValues)
	return o
end

function ItemCellUI:onNodeEvent(event)       
    if "exit" == event then
        self:onExit(false)
    end
end


function ItemCellUI:Init(parent, itemValues)
    --self.m_pNode = cc.Node:create()

    self.m_pNode = parent
    self.userObject = 0
    self.m_bCanClick = false
    self.m_isShowFrom = true
    self.m_pUILayer = self.m_pNode:getChildByName("ItemIconLayer.csb")
    if self.m_pUILayer == nil then
    	self.m_pUILayer = cc.CSLoader:createNode("csd/ItemIconLayer.csb")
    	self.m_pUILayer:setName("ItemIconLayer.csb")
    	self.m_pNode:addChild(self.m_pUILayer)
        self.itemValues= itemValues
    	if itemValues and itemValues.isChangeSize then
    		local pSize = self.m_pNode:getContentSize()
    		local cSize = self.m_pUILayer:getContentSize()
    		local xScale = pSize.width/cSize.width
    		local yScale = pSize.height/cSize.height
    		self.m_pUILayer:setScale(math.min(xScale, yScale))
    	end

        
        self.m_pUILayer:registerScriptHandler(handler(self,ItemCellUI.onNodeEvent))
    end
   	local iconImg = self.m_pUILayer:getChildByName("Touch")
    iconImg:setSwallowTouches(false)
    iconImg:addClickEventListener(handler(self, ItemCellUI.ClickCallback))
    local qlLvLabel = self.m_pUILayer:getChildByName("qianghuadengji")
    qlLvLabel:setVisible(false)
    self:UpdateItem(itemValues)
	
end

function ItemCellUI:setTag(tag)
    -- body
    self.m_pUILayer:setTag(tag)
end

function ItemCellUI:getTag()
    -- body
    self.m_pUILayer:getTag()
end

function ItemCellUI:setSwallowTouches(isSwallow)
    -- body
    local iconImg = self.m_pUILayer:getChildByName("Touch")
    iconImg:setSwallowTouches(isSwallow)
end

function ItemCellUI:setNumTextColor( color )
    -- body
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    numLabel:setTextColor(color)
end

function ItemCellUI:setNumTextScale( scale )
    -- body
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    numLabel:setScale(scale)
end

function ItemCellUI:setPosition( pos )
    -- body
    self.m_pUILayer:setPosition(pos)
end

function ItemCellUI:adjustPostion( ... )
    -- body
    local size = self.m_pUILayer:getContentSize()
    local x, y = self.m_pUILayer:getPosition()
    self.m_pUILayer:setPosition(cc.p(x - size.height / 2 , y - size.width / 2))
end

function ItemCellUI:onExit(isNonAuto)
    self:UnbindAsyncImg()
    self:UnbindAsyncImg2()
    if isNonAuto or self.m_isNonAutoFree == nil then
        self:Destory()
        self.m_suitImg = nil
        self.m_pUILayer = nil
        self.m_pNode = nil
        self.m_bCanClick = nil
        self.m_pItem = nil
        self.m_pUserDefine = nil
        self.m_isShowQuityBg = nil
        self.m_isShowNum = nil
        self.m_pUserDefine = nil
    end
    self.userObject = nil
end

--设置是否主动释放
function ItemCellUI:SetIsNonAutoFree(IsNonAutoFree)
	self.m_isNonAutoFree = IsNonAutoFree
end

--[[
itemValues数据结构：
{
	（二选一）itemData:PItem
	（二选一）userDefine:{picFilePath, num}
	（可选）isShowQualityBg:true,false,默认false
	（可选）isShowNum:是否显示道具数量：true,false,默认false
}
]]
function ItemCellUI:UpdateItem(itemValues)
	-- --print("UpdateItem")
	if itemValues == nil then
		self.m_pUILayer:setVisible(false)
		return
	end
	self.m_pUILayer:setVisible(true)
	if self.m_pItem ~= nil then
		self.m_pItem = nil
	end
    if itemValues.isChangeSize then
        local pSize = self.m_pNode:getContentSize()
        local cSize = self.m_pUILayer:getContentSize()
        local xScale = pSize.width/cSize.width
        local yScale = pSize.height/cSize.height
        self.m_pUILayer:setScale(math.min(xScale, yScale))
    end
	self.m_pItem = itemValues["itemData"]
	self.m_pUserDefine = itemValues["userDefine"]
	self.m_pPetEquip = itemValues["petEquipData"]
    self.m_pPetFaBao =  itemValues["petFaBaoData"]

	self.m_isShowQuityBg = itemValues["isShowQualityBg"]
	if self.m_isShowQuityBg == nil then
		self.m_isShowQuityBg = false
	end
	self.m_isShowNum = itemValues["isShowNum"]
	if self.m_isShowNum == nil then
		self.m_isShowNum = false
	end
    self.m_isSelect = itemValues["isSelect"]
    if self.m_isSelect == nil then
        self.m_isSelect = false
    end
    --print("self.m_pItem",self.m_pItem,"self.m_pPetEquip",self.m_pPetEquip,"self.m_pPetFaBao",self.m_pPetFaBao)
	if self.m_pItem ~= nil then
		self:ShowItem()
	elseif self.m_pUserDefine ~= nil then
		self:ShowUserDefineData()
    elseif self.m_pPetEquip ~= nil then
        self:ShowPetEquipData()
    elseif self.m_pPetFaBao ~= nil then
        self:ShowPetFabaoData()
	end
	itemValues["itemData"] = nil
	itemValues["isShowQualityBg"] = nil
	itemValues["userDefine"] = nil
	itemValues["petEquipData"] = nil
end

function ItemCellUI:ShowPetEquipData()
    self.m_pPetEquip.uid = self.m_pPetEquip.uid or 0
    self.m_pPetEquip.id = self.m_pPetEquip.id or 0
    self.m_pPetEquip.star = self.m_pPetEquip.star or 0 --觉醒星级
    self.m_pPetEquip.qhLv = self.m_pPetEquip.qhLv or 0 --强化等级
    self.m_pPetEquip.jlLv = self.m_pPetEquip.jlLv or 0 --精炼等级
    self.m_pPetEquip.szLv = self.m_pPetEquip.szLv or 0 --神铸等级
    --self.m_pPetEquip.showQ=self.m_pPetEquip.showQ
    
    local qualityImg = self.m_pUILayer:getChildByName("ItemQuality")
    local iconImg = self.m_pUILayer:getChildByName("Icon")
    local qlLvLabel = self.m_pUILayer:getChildByName("qianghuadengji")
    local jlLvLabel = self.m_pUILayer:getChildByName("jingliandengji")
    local szLvLabel = self.m_pUILayer:getChildByName("shenzhudengji")
    local petStarList = self.m_pUILayer:getChildByName("StarsList")
    local petStar = petStarList:getChildByName("Star")
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    local stateImg = self.m_pUILayer:getChildByName("ItemState")
    local itemIcon = self.m_pUILayer:getChildByName("ItemIcon")
    local touchPanel = self.m_pUILayer:getChildByName("Touch")
    local selectNode = self.m_pUILayer:getChildByName("Select")

    qualityImg:setVisible(false)
    iconImg:setVisible(true)
    qlLvLabel:setVisible(false)
    jlLvLabel:setVisible(false)
    szLvLabel:setVisible(false)
    petStarList:setVisible(false)
    numLabel:setVisible(false)
    stateImg:setVisible(false)
    itemIcon:setVisible(false)
    touchPanel:setVisible(self:GetCanClick())

    if self.m_pPetEquip.id == 0 then
        return
    end
    local cfg = JsonConfig.m_equipConfig.getDefByID(self.m_pPetEquip.id)
    if cfg == nil then
        return
    end
    if cfg.quality > 0 then  --品质框
        local colorId = cfg.quality
        local str = AppDef.ColorKuangArr[colorId]
        Utils:SafeLoadTexture(qualityImg, str,ccui.TextureResType.plistType)
        qualityImg:setVisible(self.m_isShowQuityBg)
    end
	local star = math.floor(self.m_pPetEquip.star/10)
    if star > 0 then
        petStarList:setVisible(true)
        --petStarList:setPosition(cc.p(2,0))
        for i=2,star do
            local starP = petStarList:getChildByTag(i)
            if starP == nil then
                starP = petStar:clone()
                starP:setTag(i)
                petStarList:pushBackCustomItem(starP)
            end 
        end
        for i=star+1,6 do
            local starP = petStarList:getChildByTag(i)
            if starP ~= nil then
                starP:removeFromParent()
            end
        end
    end
    if self.m_isSelect == true  then
        selectNode:setVisible(true)
    else
        selectNode:setVisible(false)
    end

    if self.m_pPetEquip.isShowNum then
        numLabel:setVisible(true)
        numLabel:setString(tostring(self.m_pPetEquip.num))
    end

    if self.m_pPetEquip.qhLv > 0 then
        qlLvLabel:setVisible(true)
        qlLvLabel:setString(self.m_pPetEquip.qhLv)
    end
    if self.m_pPetEquip.jlLv > 0 then
        jlLvLabel:setVisible(true)
        jlLvLabel:setString(Utils:formatNumber(self.m_pPetEquip.jlLv))
    end
	local showlv = math.floor(self.m_pPetEquip.szLv / 50)
    if showlv > 0 then
        szLvLabel:setVisible(true)
        szLvLabel:setString(showlv)
    end

    local size = itemIcon:getContentSize()
    self.m_value = math.max(size.width,size.height)
    local str = "item/"..cfg.pic..".png"   

    self.m_iconImg = iconImg

    if self.m_filepathKey ~= str then
        self:UnbindAsyncImg()
        self.m_filepathKey = str
        Utils:AsyncLoadImg(self.m_iconImg, str, function(pTexture)
            self.m_iconImg:initWithTexture(pTexture)
            local size = self.m_iconImg:getContentSize()
            local value = math.max(size.width,size.height)
            if value < 1 then value = 1 end
            local scale = self.m_value/value
            self.m_iconImg:setScale(scale)
        end)
    end
end


function ItemCellUI:ShowPetFabaoData( ... )
    -- body
    self.m_pPetFaBao.uid = self.m_pPetFaBao.uid or 0
    self.m_pPetFaBao.id = self.m_pPetFaBao.id or 0

    self.m_pPetFaBao.qhLv = self.m_pPetFaBao.qhLv or 0 --强化等级
    self.m_pPetFaBao.jlLv = self.m_pPetFaBao.jlLv or 0 --精炼等级
    
    local qualityImg = self.m_pUILayer:getChildByName("ItemQuality")
    local iconImg = self.m_pUILayer:getChildByName("Icon")
    local qlLvLabel = self.m_pUILayer:getChildByName("qianghuadengji")
    local jlLvLabel = self.m_pUILayer:getChildByName("jingliandengji")
    local szLvLabel = self.m_pUILayer:getChildByName("shenzhudengji")
    local petStarList = self.m_pUILayer:getChildByName("StarsList")
    local petStar = petStarList:getChildByName("Star")
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    local stateImg = self.m_pUILayer:getChildByName("ItemState")
    local itemIcon = self.m_pUILayer:getChildByName("ItemIcon")
    local touchPanel = self.m_pUILayer:getChildByName("Touch")
    local selectNode = self.m_pUILayer:getChildByName("Select")

    qualityImg:setVisible(false)
    iconImg:setVisible(true)
    qlLvLabel:setVisible(false)
    jlLvLabel:setVisible(false)
    szLvLabel:setVisible(false)
    petStarList:setVisible(false)
    numLabel:setVisible(false)
    stateImg:setVisible(false)
    itemIcon:setVisible(false)
    touchPanel:setVisible(self:GetCanClick())

    if self.m_pPetFaBao.id == 0 then
        return
    end
    local cfg = JsonConfig.m_faBaoConfig.getDefByID(self.m_pPetFaBao.id)
    if cfg == nil then
        return
    end
    if cfg.quality > 0 then  --品质框
        local colorId = cfg.quality
        local str = AppDef.ColorKuangArr[colorId]
        Utils:SafeLoadTexture(qualityImg, str,ccui.TextureResType.plistType)
        qualityImg:setVisible(true)
    end

    if self.m_isSelect == true  then
        selectNode:setVisible(true)
    else
        selectNode:setVisible(false)
    end

    if self.m_pPetFaBao.isShowNum then
        numLabel:setVisible(true)
        numLabel:setString(tostring(self.m_pPetFaBao.num))
    end
    
    if self.m_pPetFaBao.qhLv > 0 then
        qlLvLabel:setVisible(true)
        qlLvLabel:setString(self.m_pPetFaBao.qhLv)
    end
    if self.m_pPetFaBao.jlLv > 0 then
        jlLvLabel:setVisible(true)
        jlLvLabel:setString(Utils:formatNumber(self.m_pPetFaBao.jlLv))
    end

    local size = itemIcon:getContentSize()
    self.m_value = math.max(size.width,size.height)
    local str = "item/"..cfg.pic..".png"   
    self.m_iconImg = iconImg

    if self.m_filepathKey ~= str then
        self:UnbindAsyncImg()
        self.m_filepathKey = str
        Utils:AsyncLoadImg(self.m_iconImg, str, function(pTexture)
            self.m_iconImg:initWithTexture(pTexture)
            local size = self.m_iconImg:getContentSize()
            local value = math.max(size.width,size.height)
            if value < 1 then value = 1 end
            local scale = self.m_value/value
            self.m_iconImg:setScale(scale)
        end)
    end
end

function ItemCellUI:ShowUserDefineData()
	self.m_pUserDefine.num = self.m_pUserDefine.num or 0
	self.m_pUserDefine.quality = self.m_pUserDefine.quality or 0
    self.m_pUserDefine.level = self.m_pUserDefine.level or 0
    self.m_pUserDefine.star = self.m_pUserDefine.star or 0
    self.m_pUserDefine.career = self.m_pUserDefine.career or 0
    self.m_pUserDefine.strengthenLv = self.m_pUserDefine.strengthenLv or 0
    self.m_pUserDefine.itemId = self.m_pUserDefine.itemId or 0
    self.m_pUserDefine.itemType = self.m_pUserDefine.itemType or 0
    self.m_pUserDefine.suitId = self.m_pUserDefine.suitId or 0
	self.m_pUserDefine.locked = self.m_pUserDefine.locked or 0
    local cfg = JsonConfig.m_Item.getDefByID(self.m_pUserDefine.itemId)
    -- if cfg ~= nil and (cfg.type == 2 or (cfg.type >= 7 and cfg.type <= 10))then
    if cfg ~= nil and (cfg.type == 2)then
        self.m_pUserDefine.isSuiPian = true
    else
        self.m_pUserDefine.isSuiPian = false
    end

    if cfg ~= nil and (cfg.type == 7)then
        self.m_pUserDefine.isEquipSuiPian = true
    else
        self.m_pUserDefine.isEquipSuiPian = false
    end

	local qualityImg = self.m_pUILayer:getChildByName("ItemQuality")
	local numLabel = self.m_pUILayer:getChildByName("ItemNum")
	local stateImg = self.m_pUILayer:getChildByName("ItemState")
    local iconImg = self.m_pUILayer:getChildByName("Icon")
    local itemIcon = self.m_pUILayer:getChildByName("ItemIcon")
    local levelLabel = self.m_pUILayer:getChildByName("Level")
    local petQualityImg = self.m_pUILayer:getChildByName("Quality")
    local petCareerImg = self.m_pUILayer:getChildByName("Career")
    local petStarList = self.m_pUILayer:getChildByName("StarsList")
    local petStar = petStarList:getChildByName("Star")
    local petEquipLevelLable = self.m_pUILayer:getChildByName("Strengthen")--宠物装备强化等级
    local touchPanel = self.m_pUILayer:getChildByName("Touch")
    local suitImg = self.m_pUILayer:getChildByName("PetEquip")--套装
	local clock = self.m_pUILayer:getChildByName("Clock")
    local selectNode = self.m_pUILayer:getChildByName("Select")
    local suiPianImg = self.m_pUILayer:getChildByName("ShardIcon")

    itemIcon:setVisible(false)
	stateImg:setVisible(false)
    iconImg:setVisible(true)
    levelLabel:setVisible(false)
	petQualityImg:setVisible(false)
    petCareerImg:setVisible(false)
    petStarList:setVisible(false)
    petStarList:setTouchEnabled(false)
    petEquipLevelLable:setVisible(false)
    touchPanel:setVisible(self:GetCanClick())
    suitImg:setVisible(false)
	if clock ~= nil then
		clock:setVisible(false)
	end

	if self.m_isShowNum == true and self.m_pUserDefine.num >= 0 then
		numLabel:setVisible(true)
        numLabel:setString(tostring(self.m_pUserDefine.num))
	else
		numLabel:setVisible(false)
	end
    if self.m_isSelect == true  then
        selectNode:setVisible(true)
    else
        selectNode:setVisible(false)
    end

    suiPianImg:setVisible(self.m_pUserDefine.isSuiPian or self.m_pUserDefine.isEquipSuiPian)

	if self.m_pUserDefine.quality > 0 then	--品质框
        local colorId = self.m_pUserDefine.quality
        if self.m_pUserDefine.level > 0 then--神将特殊处理
            colorId = AppDef:GetPetQualityColorId(self.m_pUserDefine.quality)
            petQualityImg:setVisible(true)
            AppDef:GetPetQualityScore(petQualityImg,self.m_pUserDefine.quality)
            petQualityImg:setScale(0.4)
        end
		local str = AppDef.ColorKuangArr[colorId]
        Utils:SafeLoadTexture(qualityImg, str,ccui.TextureResType.plistType)
		--qualityImg:loadTexture(str,ccui.TextureResType.plistType)
		qualityImg:setVisible(true)
	else
		qualityImg:setVisible(false)
	end
    --神将特殊处理
    if self.m_pUserDefine.level > 0 then
        levelLabel:setVisible(true)
        levelLabel:setString("Lv."..self.m_pUserDefine.level)
    end
	if self.m_pUserDefine.locked > 0 then
		clock:setVisible(true)
	end
    if self.m_pUserDefine.career > 0 then
        petCareerImg:setVisible(true)
        AppDef:ShowPetType(petCareerImg,self.m_pUserDefine.career)
    end
    if self.m_pUserDefine.star > 0 then
        petStarList:setVisible(true)
        petStarList:setPosition(cc.p(2,0))
        for i=2,self.m_pUserDefine.star do
            local starP = petStarList:getChildByTag(i)
            if starP == nil then
                starP = petStar:clone()
                starP:setTag(i)
                petStarList:pushBackCustomItem(starP)
            end 
        end
        for i=self.m_pUserDefine.star+1,6 do
            local starP = petStarList:getChildByTag(i)
            if starP ~= nil then
                starP:removeFromParent()
            end
        end
    end
    --end
   
    if self.m_pUserDefine.itemId >= AppDef.AwrdItem.AWRD_ITEM_COIN then
        if self.m_isShowQuityBg == true then
            self.m_pUserDefine.quality = 3
			local str = AppDef.ColorKuangArr[self.m_pUserDefine.quality]
            if str ~= nil then
                Utils:SafeLoadTexture(qualityImg, str, ccui.TextureResType.plistType)
			    --qualityImg:loadTexture(str,ccui.TextureResType.plistType)
			    qualityImg:setVisible(true)
            end
        end
    end

    if self.m_pUserDefine.strengthenLv > 0 then
        petEquipLevelLable:setVisible(true)
        petEquipLevelLable:setString("+"..self.m_pUserDefine.strengthenLv)
    end

    local size = itemIcon:getContentSize()
    self.m_value = math.max(size.width,size.height)
    local str = self.m_pUserDefine.picFilePath   
    --print("ShowUserDefineData ===============> str", str)
    self.m_iconImg = iconImg

    if self.m_filepathKey ~= str then
        self:UnbindAsyncImg()
        self.m_filepathKey = str
        Utils:AsyncLoadImg(self.m_iconImg, str, function(pTexture)
            self.m_iconImg:initWithTexture(pTexture)
            --self.m_iconImg:setTextureRect(cc.rect(0,0,self.m_iconSize.width,self.m_iconSize.height))
            local size = self.m_iconImg:getContentSize()
            local value = math.max(size.width,size.height)
            if value < 1 then value = 1 end
            local scale = self.m_value/value
            self.m_iconImg:setScale(scale)
            if self.m_pUserDefine.isSuiPian then
                self.m_iconImg:setScale(0.92 * scale)
            else
                self.m_iconImg:setScale(scale)
            end
        end)
    end

    --Utils:AsyncLoadImg(self.m_iconImg,str)
    
    
    self.m_suitImg = suitImg
    if self.m_pUserDefine.suitId > 0 then
        
        local resFile = string.format("res2/Icon/ui_pet_icon/ui_tuteng_dongwu_%d.png", self.m_pUserDefine.suitId)
        if self.m_filepathKey2 ~= resFile then
            self:UnbindAsyncImg2()
            self.m_filepathKey2 = resFile
            Utils:AsyncLoadImg(suitImg, resFile, function(pTexture)
                self.m_suitImg:setVisible(true)
                Utils:SafeLoadTexture(self.m_suitImg, resFile, UI_TEX_TYPE_LOCAL)
                --self.m_suitImg:loadTexture(resFile, UI_TEX_TYPE_LOCAL)
              end)
        else
            self.m_suitImg:setVisible(true)
        end
    end
end

function ItemCellUI:ShowItem()
	local item = self.m_pItem
    if item == nil then return end
    if item.m_item == nil and item.m_id <= 0 then 
        item.m_item = LItemMgr:getItem(item.m_id)
    end
    if item.m_item == nil then return end
	local qualityImg = self.m_pUILayer:getChildByName("ItemQuality")
	--local itemImg = self.m_pUILayer:getChildByName("ItemIcon")
	local numLabel = self.m_pUILayer:getChildByName("ItemNum")
	local stateImg = self.m_pUILayer:getChildByName("ItemState")
    local iconImg = self.m_pUILayer:getChildByName("Icon")
    local levelLabel = self.m_pUILayer:getChildByName("Level")
    local petQualityImg = self.m_pUILayer:getChildByName("Quality")
    local petCareerImg = self.m_pUILayer:getChildByName("Career")
    local petStarList = self.m_pUILayer:getChildByName("StarsList")
    local touchPanel = self.m_pUILayer:getChildByName("Touch")
    local suitImg = self.m_pUILayer:getChildByName("PetEquip")--套装
    local selectNode = self.m_pUILayer:getChildByName("Select")
	--itemImg:setVisible(false)
    levelLabel:setVisible(false)
	petQualityImg:setVisible(false)
    petCareerImg:setVisible(false)
    petStarList:setVisible(false)
    petStarList:setTouchEnabled(false)
	stateImg:setVisible(false)
    iconImg:setVisible(true)
    touchPanel:setVisible(self:GetCanClick())
    suitImg:setVisible(false)

    local cfg = JsonConfig.m_Item.getDefByID(item.m_id)

    if cfg ~= nil and (cfg.type == 2)then
        item.isSuiPian = true
    else
        item.isSuiPian = false
    end

    if cfg ~= nil and (cfg.type == 7)then
        item.isEquipSuiPian = true
    else
        item.isEquipSuiPian = false
    end

    local suiPianImg = self.m_pUILayer:getChildByName("ShardIcon")
    suiPianImg:setVisible(item.isSuiPian or item.isEquipSuiPian)

    local size = qualityImg:getContentSize()
    --iconImg:setTextureRect(cc.rect(0,0,size.width,size.height))
	if self.m_isShowNum == true and item.m_num >= 0 then
		numLabel:setVisible(true)
        numLabel:setString(tostring(item.m_num))
	else
		numLabel:setVisible(false)
	end
    if self.m_isSelect == true  then
        selectNode:setVisible(true)
    else
        selectNode:setVisible(false)
    end

	if self.m_isShowQuityBg then
		local colorIdx = item.m_item.quality
        local str = AppDef.ColorKuangArr[colorIdx]
		if colorIdx and str ~= nil then			
            Utils:SafeLoadTexture(qualityImg, str, ccui.TextureResType.plistType)
			--qualityImg:loadTexture(str, ccui.TextureResType.plistType)
			qualityImg:setVisible(true)
        else
            qualityImg:setVisible(false)
		end
	else
		qualityImg:setVisible(false)
	end

    self.m_value = math.max(size.width,size.height)
	self.m_iconImg = iconImg

    local str
    if item.isSuiPian then
        str = "res2/Monster_Bust/" .. item.m_item.pic.. "_tou.png"
    else
        str = "item/equip" .. item.m_item.pic .. ".png"
    end

    -- --print("str 11111111111111111 ===>", str)
    if self.m_filepathKey ~= str then
        self:UnbindAsyncImg()
        self.m_filepathKey = str
        Utils:AsyncLoadImg(self.m_iconImg, str, function(pTexture)
            self.m_iconImg:initWithTexture(pTexture)
            local size = self.m_iconImg:getContentSize()
            local value = math.max(size.width,size.height)
            if value < 1 then value = 1 end
            local scale = self.m_value/value
            if item.isSuiPian then
                self.m_iconImg:setScale(0.92 * scale)
            else
                self.m_iconImg:setScale(scale)
            end
        end)
    end
end

function ItemCellUI:UnbindAsyncImg()
    if self.m_filepathKey then
        Utils:UnbindAsyncImg(self.m_filepathKey)
        self.m_filepathKey = nil
    end
end

function ItemCellUI:UnbindAsyncImg2()
    if self.m_filepathKey2 then
        Utils:UnbindAsyncImg(self.m_filepathKey2)
        self.m_filepathKey2 = nil
    end
end

function ItemCellUI:ClickCallback(sender)
	if not self.m_bCanClick then
		return
	end
	if self.m_pItem ~= nil then
		Utils:ShowItemTips(self.m_pItem.m_id)
    elseif self.m_pUserDefine ~= nil and self.m_pUserDefine.itemId ~= nil then
       
        if self.m_pUserDefine.itemType ~= nil and self.m_pUserDefine.itemType > 0 then
            if self.m_pUserDefine.itemType == AppDef.AwrdItem.AWRD_ITEM_WINDS then
                Utils:OpenWearTips("Wing", self.m_pUserDefine.itemId)
            elseif self.m_pUserDefine.itemType == AppDef.AwrdItem.AWRD_ITEM_HORSE then
                Utils:OpenWearTips("Mount", self.m_pUserDefine.itemId)
            elseif self.m_pUserDefine.itemType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then
                Utils:OpenWearTips("Artifact", self.m_pUserDefine.itemId)
            elseif self.m_pUserDefine.itemType == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then            
                Utils:ShowPetEquidTips(self.m_pUserDefine.itemType,self.m_pUserDefine.quality,self.m_pUserDefine.star,self.m_pUserDefine.itemId)
            elseif self.m_pUserDefine.itemType == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then
                --称号特殊处理           
                Utils:OpenWearTips("Title", self.m_pUserDefine.itemId)
            end
        elseif self.m_pUserDefine.itemId >= AppDef.AwrdItem.AWRD_ITEM_COIN then
            Utils:ShowGoldTips(self.m_pUserDefine.itemId, self.m_pUserDefine.quality)
        end
    elseif self.m_pPetEquip ~= nil and self.m_pPetEquip.id ~= nil then 
        local data = 
        {
            uid = self.m_pPetEquip.uid,
            id = self.m_pPetEquip.id
        }
        Utils:InitUI("PetEquip.EquipInfoUI",AppDef.UIType.PopWindow,data)
    elseif self.m_pPetFaBao ~= nil and self.m_pPetFaBao.id ~= nil then
        local data = 
        {
            uid = self.m_pPetFaBao.uid,
            id = self.m_pPetFaBao.id
        }
        Utils:InitUI("FaBao.FaBaoInfo",AppDef.UIType.PopWindow,data)
	end
end

function ItemCellUI:Destory()
	self.m_pUILayer = nil
	self.m_pNode = nil
	self.m_pItem = nil
	self.m_pUserDefine = nil
	self.m_isShowQuityBg = nil
	self.m_isShowNum = nil
	self.m_isNonAutoFree = nil
	self.m_bCanClick = nil
end

--[[
设置是否能点击显示详情
]]
function ItemCellUI:SetCanClick(canClick)
	self.m_bCanClick = canClick
    local touchPanel = self.m_pUILayer:getChildByName("Touch")
    touchPanel:setVisible(canClick)
end

--[[
设置点击是否显示来源
]]
function ItemCellUI:SetShowFrom(sign)
    self.m_isShowFrom = sign
end

function ItemCellUI:GetCanClick()
    return self.m_bCanClick
end
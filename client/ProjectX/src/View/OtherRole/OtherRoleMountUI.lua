--[[
lua里面的游戏逻辑控制
]]

local OtherRoleMountUI = LUIBase:New()
OtherRoleMountUI.__index = OtherRoleMountUI
--local this = LTcpSocket
function OtherRoleMountUI:New()
	local o = LUIBase:New()
	setmetatable(o,OtherRoleMountUI)	
    o:Init()
	return o
end


function OtherRoleMountUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/MountInfoLayer.csb")
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
    self:ShowMountInfo()
end

--[[
注册UI消息
]]
function OtherRoleMountUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

function OtherRoleMountUI:ProcessEvent(msg)
end

function OtherRoleMountUI:onExit()
    self:Destory()
    self.m_pTableView = nil
    self.m_pListView = nil
    self.m_pBaseCell = nil
    self.m_pMountAniPanel = nil
    self.m_pNameLabel = nil
    self.m_pPowerLabel = nil
    self.m_pPowerLabelbg = nil
    self.m_pTipImg = nil
    self.m_bgAttribute=nil
    self.m_bgAttributeText=nil
    self.m_pAniNode = nil
    self.m_pModelAni = nil
    self.m_pMountAttrPanel = nil
    self.m_TotalZhanLi= nil
    self.m_TotalAtt=nil
    self.m_pAttrCell = nil
    self.m_pRideBtn = nil
    self.m_pBaseAttrLabel = nil
    self.m_pBaseAttrNameLabel = nil
end

function OtherRoleMountUI:InitData()
  
    -------------------------------------
     local panel = self.m_pUILayer:getChildByName("MountInfoUI")
    self.m_pListView = panel:getChildByName("List")
    self.m_pBaseCell = panel:getChildByName("Item")
    self.m_pMountAniPanel = panel:getChildByName("Panel")
    self.m_pNameLabel = self.m_pMountAniPanel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pPowerLabel = self.m_pMountAniPanel:getChildByName("bg_zhanli"):getChildByName("Text")
    self.m_pPowerLabelbg = self.m_pMountAniPanel:getChildByName("bg_zhanli")
    self.m_pPowerLabelbg:setVisible(false)
    self.m_pTipImg = self.m_pMountAniPanel:getChildByName("bg_Describe")
    self.m_bgAttribute=self.m_pTipImg:getChildByName("bg_Attribute")
    self.m_bgAttributeText=self.m_bgAttribute:getChildByName("Text")
    self.m_pAniNode = self.m_pMountAniPanel:getChildByName("mountNode")
    self.m_pModelAni = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,0)
    self.m_pAniNode:addChild(self.m_pModelAni)
    self.m_pMountAttrPanel = panel:getChildByName("Panel_0")
    local OtInfo = LRoleDataMgr.MyHeroInfo:GetHorseExInfo() 
    self.m_TotalZhanLi= self.m_pMountAttrPanel:getChildByName("Power"):getChildByName("Value")
    self.m_TotalAtt=self.m_pMountAttrPanel:getChildByName("ListView")
    self.m_pAttrCell = self.m_pMountAttrPanel:getChildByName("Attribute")
    self.m_pRideBtn = self.m_pMountAttrPanel:getChildByName("Btn_Register")
    self.m_pRideBtn:setVisible(false)
    local baseAttrPanel = self.m_pMountAttrPanel:getChildByName("Panel_jichu")
    self.m_pBaseAttrLabel = {}
    self.m_pBaseAttrNameLabel = {}
    for i = 1, 5 do
        self.m_pBaseAttrNameLabel[i] = self.m_pTipImg:getChildByName("Attribute"..i)
        self.m_pBaseAttrLabel[i] = self.m_pBaseAttrNameLabel[i]:getChildByName("Value")
    end

    local addAttrPanel = self.m_pMountAttrPanel:getChildByName("Panel_qianghua")
    -- self.m_pAddAttrLabel = {}
    -- self.m_pAddAttrNameLabel = {}
    -- for i = 1, 6 do
    --     self.m_pAddAttrNameLabel[i] = addAttrPanel:getChildByName("Attribute_"..i)
    --     self.m_pAddAttrLabel[i] = self.m_pAddAttrNameLabel[i]:getChildByName("Value")
    -- end
    
    -- self.m_pBaseAttrListView = self.m_pMountAttrPanel:getChildByName("ListView_jichu")
    -- self.m_pEnforceAttrListView = self.m_pMountAttrPanel:getChildByName("ListView_qianghua")
    self.m_pTableView = nil
    self.m_curSelectInd = 0
    self.m_curSelectId = 0 --选中的坐骑ID

    local hdata = LRoleDataMgr.MyHeroInfo
    local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    local horseList = LDataConstMgr:GetHorseConfigArr()
    for i = 1, #horseList do
        local horsedata = horseList[i]
        if hdata:IsRide() and showIdx == i then
            self.m_curSelectInd = i - 1
            self.m_curSelectId = horsedata.id
            break
        end
    end

    self:InitTabView()
end

function OtherRoleMountUI:InitTabView()
    local tableView = cc.TableView:create(self.m_pListView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pListView:getAnchorPoint())
    tableView:setPosition(self.m_pListView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pListView:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:TableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pBaseCell:getContentSize().width
        local height = self.m_pBaseCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return #LRoleDataMgr.OtherHeroInfo.Horse
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTableView = tableView
end

function OtherRoleMountUI:TableCellTouched(cell)
    local ind = cell:getIdx()
    self:SetSelect(ind)
end

function OtherRoleMountUI:SetSelect(ind)
    if self.m_curSelectInd == ind then
        return
    end
    if self.m_curSelectInd >= 0 then
        local oldCell = self.m_pTableView:cellAtIndex(self.m_curSelectInd)
        if oldCell ~= nil then
            local oldCellChild = oldCell:getChildByTag(123)
            if oldCellChild ~= nil then
                local selectImg = oldCellChild:getChildByName("Choose")
                selectImg:setVisible(false)
            end
        end
    end
    self.m_curSelectInd = ind
    local cell = self.m_pTableView:cellAtIndex(self.m_curSelectInd)
    local cellChild = cell:getChildByTag(123)
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)

    self:ShowMountInfo()
end

function OtherRoleMountUI:ShowMountInfo()
    self:ShowMountAni()
    self:ShowMountAttr()
    self:ChangeBtnName()
end

function OtherRoleMountUI:ChangeBtnName()
    local hdata = LRoleDataMgr.OtherHeroInfo
    local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    local horsedata = LRoleDataMgr.OtherHeroInfo.Horse[showIdx]
    if hdata:IsRide() and showIdx == self.m_curSelectInd  + 1 then
        btnStr = GUITips.RSI_HSL_TIP12
    elseif horsedata.IsGet == false then
        btnStr = GUITips.RSI_HSL_TIP13
    else
        btnStr = GUITips.RSI_HSL_TIP11
    end

    self.m_pRideBtn:getChildByName("Text"):setString(btnStr)
end

function OtherRoleMountUI:GetCurHorseId()
    local hdata = LRoleDataMgr.OtherHeroInfo
    return  hdata.Horse[self.m_curSelectInd +1].id
end

function OtherRoleMountUI:ShowMountAni()
    local hdata = LRoleDataMgr.OtherHeroInfo
    local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    local horseData = hdata.Horse[self.m_curSelectInd +1]
    local IsShowHero = false
    if hdata:IsRide() and showIdx == self.m_curSelectInd +1 then
        IsShowHero = true
    end
    --int type, int bodyId, char sex, int weaponId, int weaponEffect, int wings, int horseId, int shenqiId
    if IsShowHero == true then
        self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.Hero,hdata.professional,0,0,0,horseData.id,0)
    else
        self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,horseData.id,0)
    end
    self.m_pModelAni:PlayStand(0)
end

function OtherRoleMountUI:GetCurHorse()
    local curHorseID = self:GetCurHorseId()
    return LDataConstMgr:GetOtherHorseConfigData(curHorseID)
end

function OtherRoleMountUI:ShowTotalAttr()
    local herodata = LRoleDataMgr.OtherHeroInfo
    local _horinfo = herodata.horseExInfo
    self.m_TotalAtt:removeAllItems()
    for i,v in pairs(_horinfo.AttrList) do
        local cell = self.m_pAttrCell:clone()
        local value = cell:getChildByName("Value")  
        Utils:ShowAttrLabelSec(cell, i, value, v)
        value:setVisible(true)
        cell:setVisible(true)
        self.m_TotalAtt:pushBackCustomItem(cell)
    end
    self.m_TotalZhanLi:setString(Utils:getPowerStr(_horinfo.TotalPower))
end

function OtherRoleMountUI:ShowMountAttr()
   
    -------------------------
     local herodata = LRoleDataMgr.OtherHeroInfo
     if   #herodata.Horse == 0 then
        return
     end
    local _horinfo = herodata.horseExInfo
    local CurHorse = self:GetCurHorse()

-------------------------------------------------
    
    self.m_pNameLabel:setString(CurHorse.name)
    self.m_pPowerLabel:setString(GUITips.UI_Power_All .. herodata:GetHorsePower(CurHorse.id,_horinfo.qhLevel,0))

    self.TotalCell={}

    local attrType
    local attrValue
    local ind
    local qianghuadata = LDataConstMgr:GetHorseStrengthData(_horinfo.qhLevel)
     if _horinfo.qhLevel>=1 then
        for j = 1, 4 do                      
            if self.TotalCell[qianghuadata.attrTypeArr[j]]==nil or self.TotalCell[qianghuadata.attrTypeArr[j]]==0 then
                self.TotalCell[qianghuadata.attrTypeArr[j]]=0
            end                            
        end
      end
  
    for i = 2, 5 do
        ind = i - 1
        if ind > #CurHorse.attrTypeArr then
            self.m_pBaseAttrNameLabel[i]:setVisible(false)
        else
            self.m_pBaseAttrNameLabel[i]:setVisible(true)
            attrType = CurHorse.attrTypeArr[i-1]
            attrValue = CurHorse.attrValueArr[i-1]
            if AppDef:IsRatioAttr(attrType) then
                Utils:ShowAttrLabel(self.m_pBaseAttrNameLabel[i], attrType, self.m_pBaseAttrLabel[i], attrValue / 100, true)
            else
                Utils:ShowAttrLabel(self.m_pBaseAttrNameLabel[i], attrType, self.m_pBaseAttrLabel[i], attrValue, false)
            end
            self.m_pBaseAttrLabel[i]:setPositionX(self.m_pBaseAttrNameLabel[i]:getContentSize().width)
        end
    end
    self.m_pBaseAttrNameLabel[1]:setString("移动速度 ：")
    self.m_pBaseAttrLabel[1]:setString(CurHorse.moveSpeed .. "%")
    self.m_pBaseAttrLabel[1]:setPositionX(self.m_pBaseAttrNameLabel[1]:getContentSize().width)

    -- local qianghuadata = LDataConstMgr:GetHorseStrengthData(_horinfo.qhLevel)
    -- local horseList = LDataConstMgr:GetHorseConfigArr()
    -- local hdata = LRoleDataMgr.OtherHeroInfo
    --  for i = 1, #horseList do
    --     for j=1,#herodata.Horse do
    --           if herodata.Horse[j].id==horseList[i].id then
    --               local horsedata = horseList[i]    
    --                 for i = 2, 5 do
    --                   attrType = horsedata.attrTypeArr[i-1]
    --                   attrValue = horsedata.attrValueArr[i-1]
    --                   if attrType~=nil then      
                      
    --                         if self.TotalCell[attrType]~=nil and self.TotalCell[attrType]~=0  then
    --                           self.TotalCell[attrType]=attrValue+self.TotalCell[attrType]
    --                         else
    --                         self.TotalCell[attrType]=attrValue
    --                          end
                 
    --                     end
    --                 end           
    --             end
    --       end

    --   end
    --   local TotallPower = 0
    --  self.m_TotalAtt:removeAllItems()
      
    --   for i,v in pairs(self.TotalCell) do

    --         local cell = self.m_pAttrCell:clone()  
    --         local value = cell:getChildByName("Value")            
    --         Utils:ShowAttrLabelSec(cell, i, value, v)
    --         TotallPower=LDataConstMgr:GetSingleAttrPower(i,v)+TotallPower
    --         value:setVisible(true)
    --         cell:setVisible(true)
    --         self.m_TotalAtt:pushBackCustomItem(cell)
           
    --   end
    --     self.m_TotalZhanLi:setString("总战力 :"..TotallPower)

    self:ShowTotalAttr()
end

function OtherRoleMountUI:GetShowIdx(useIdx)
    --print("GetShowIdx",useIdx)
    local mHorse = LRoleDataMgr.OtherHeroInfo.Horse
    if useIdx > #mHorse then
        return 1
    end
    if mHorse[useIdx+1] == nil then
        return 1
    end
    local horseId = mHorse[useIdx+1].id
    local hlist = LRoleDataMgr.OtherHeroInfo.Horse
    for i = 1, #hlist do
        if hlist[i].id == horseId then
            return i
        end
    end
    return 1
end

function OtherRoleMountUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pBaseCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)

    else
        cellChild = cell:getChildByTag(123)
    end
    -- if self.m_IsSelectRecommend == true then
    --     self:ShowRightRecommendCellInfo(cellChild, idx)
    -- else
    --     self:ShowRightCommonCellInfo(cellChild, idx)
    -- end
    cellChild:getChildByName("DressState"):setVisible(false)
    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curSelectInd then 
        --cellChild:setSelected(true)
        
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end

    self:ShowCellInfo(cellChild, idx)
    return cell
end

function OtherRoleMountUI:ShowCellInfo(cellChild, idx)
    local mountArr = LDataConstMgr:GetHorseConfigArr()
    local horse = LRoleDataMgr.OtherHeroInfo.Horse[idx + 1]
    local redDotImg = cellChild:getChildByName("Prompt")
    if redDotImg ~=nil then
        redDotImg:setVisible(false)
    end
    if horse == nil then return end
    local horsedata
    for k,v in pairs(mountArr) do
        if v.id == horse.id then
            horsedata = v
        end
    end
    local headImg = cellChild:getChildByName("bg_icon"):getChildByName("Icon")
    headImg:loadTexture(string.format("res2/Horse_Bust/%d_tou.png", horsedata.id),ccui.TextureResType.localType)

    --坐骑名字
    local nameLabel = cellChild:getChildByName("Name")
    nameLabel:setString(horsedata.name)

    --获得
    local gotLabel = cellChild:getChildByName("State")
    gotLabel:setString(GUITips.RSI_PAGE_MSG37)
    gotLabel:setTextColor(UICOLOR_GREEN)
    
    -- local str = string.sub(horsedata.describ, 5, string.len(horsedata.describ) - 4)
    -- local descLabel = cellChild:getChildByName("Source")
    -- descLabel:setString(str)
end

function OtherRoleMountUI:AddTouchEvt()
end

return OtherRoleMountUI
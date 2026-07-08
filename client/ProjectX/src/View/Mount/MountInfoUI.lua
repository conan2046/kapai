--[[
lua里面的游戏逻辑控制
]]

local MountInfoUI = LUIBase:New()
MountInfoUI.__index = MountInfoUI
--local this = LTcpSocket
function MountInfoUI:New()
	local o = LUIBase:New()
	setmetatable(o,MountInfoUI)	
    o:Init()
	return o
end


function MountInfoUI:Init()
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
    -- self:ShowAttr()
    -- self:ShowEquip()
    -- self:SetCurAttrTab(1)

end

--[[
注册UI消息
]]
function MountInfoUI:RegistMsgs()
    self.msgIds = 
    {
        LUIHorseEvent.RideStateChanged,
        LUIHorseEvent.HorseListChange,
        LUIHorseEvent.UpdateHorseTotalAttr,
    }
    self:RegistSelf(self,self.msgIds)
end

function MountInfoUI:ProcessEvent(msg)
    if msg.msgId == LUIHorseEvent.RideStateChanged then
        self:RecvRideStateChanged()
        self:HorseListChanged()
    elseif msg.msgId == LUIHorseEvent.HorseListChange then
        self:CheckSelect()
        self:HorseListChanged()
        self:ChangeBtnName()
        --self:ShowTotalAttr()
     elseif msg.msgId==LUIHorseEvent.UpdateHorseTotalAttr then
         self:ShowTotalAttr()
     end
end

function MountInfoUI:HorseListChanged()
    local horseList = LDataConstMgr:GetHorseConfigArr()
    local hdata = LRoleDataMgr.MyHeroInfo
    for i = 1, #horseList do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)

            local horsedata = horseList[i]
            --获得
            local gotLabel = cellChild:getChildByName("State")
            if horsedata.isGet == true then
                gotLabel:setString(GUITips.RSI_PAGE_MSG37)
                gotLabel:setTextColor(UICOLOR_GREEN)
            else
                gotLabel:setString(GUITips.RSI_PAGE_MSG36)
                gotLabel:setTextColor(UICOLOR_RED)
            end

            local nameLabel = cellChild:getChildByName("Name")
            nameLabel:setString(horsedata.name)

            local headImg = cellChild:getChildByName("bg_icon"):getChildByName("Icon")

            headImg:loadTexture(string.format("res2/Horse_Bust/%d_tou.png", horsedata.id),ccui.TextureResType.localType)

            local chuandaiLabel = cellChild:getChildByName("DressState")
            
            local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
            if showIdx ==  i then
                chuandaiLabel:setVisible(true)
            else
                chuandaiLabel:setVisible(false)
            end

            local redDotImg = cellChild:getChildByName("Prompt")
            if redDotImg ~= nil then
                local value = self:CheckItemExchangeRedDot(horsedata.getWayType,horsedata.isGet,horsedata.getWayItem,horsedata.getWayNum)
                redDotImg:setVisible(value)
            end
        end
    end

end

--[[

]]
function MountInfoUI:RecvRideStateChanged()
    --local hdata = LRoleDataMgr.MyHeroInfo
    --local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    -- if showIdx ~= self.m_curSelectInd +1 then
    --     return
    -- end

    self:ShowMountAni()
    self:ChangeBtnName()
end

function MountInfoUI:onExit()
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
    local baseAttrPanel = nil
    local pHelpBtn = nil
    self.m_pBaseAttrLabel = nil
    self.m_pBaseAttrNameLabel = nil
end

function MountInfoUI:InitData()
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
   -- self.m_TotalZhanLi:setString(GUITips.Item_Power.." : "..OtInfo.fightPower)
    self.m_TotalAtt=self.m_pMountAttrPanel:getChildByName("ListView")
    self.m_pAttrCell = self.m_pMountAttrPanel:getChildByName("Attribute")
    self.m_pRideBtn = self.m_pMountAttrPanel:getChildByName("Btn_Register")
    local baseAttrPanel = self.m_pMountAttrPanel:getChildByName("Panel_jichu")
    local pHelpBtn = self.m_pMountAttrPanel:getChildByName("btn_Help")
    pHelpBtn:setVisible(true)
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
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
    self:ShowTotalAttr()
end

function MountInfoUI:helpButtonCallback()
    local str = GUITips.RSI_Help_Str9
    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function MountInfoUI:InitTabView()
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
        local arr = LDataConstMgr:GetHorseConfigArr()
        return #arr
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTableView = tableView
end

function MountInfoUI:TableCellTouched(cell)
    local ind = cell:getIdx()
    self:SetSelect(ind)
end

function MountInfoUI:CheckSelect()
    local horseList = LDataConstMgr:GetHorseConfigArr()
    for i = 1, #horseList do
        local horsedata = horseList[i]
        if self.m_curSelectId > 0 and horsedata.id == self.m_curSelectId then
            self:SetSelect(i - 1)
            break
        end
    end
end

function MountInfoUI:SetSelect(ind)
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
    local horseList = LDataConstMgr:GetHorseConfigArr()
    if horseList ~= nil then
        local horsedata = horseList[ind+1]
        if horsedata ~= nil then
            self.m_curSelectId = horsedata.id
        end
    end
    local cell = self.m_pTableView:cellAtIndex(self.m_curSelectInd)
    if cell ~= nil then
        local cellChild = cell:getChildByTag(123)
        local selectImg = cellChild:getChildByName("Choose")
        selectImg:setVisible(true)
    else
        Utils:MoveToTableIdx(self.m_pTableView, self.m_pBaseCell, self.m_curSelectInd)
    end

    self:ShowMountInfo()
end

function MountInfoUI:ShowMountInfo()
    self:ShowMountAni()
    self:ShowMountAttr()
    self:ChangeBtnName()
end

function MountInfoUI:ChangeBtnName()
    local hdata = LRoleDataMgr.MyHeroInfo
    local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    local horseList = LDataConstMgr:GetHorseConfigArr()
    local horsedata = horseList[self.m_curSelectInd+1]

    local redDot = self.m_pRideBtn:getChildByName("Prompt")
    if redDot ~= nil then 
        local value = self:CheckItemExchangeRedDot(horsedata.getWayType,horsedata.isGet,horsedata.getWayItem,horsedata.getWayNum)
        redDot:setVisible(value)
    end
    if hdata:IsRide() and showIdx == self.m_curSelectInd  + 1 then
        btnStr = GUITips.RSI_HSL_TIP12
    elseif horsedata.isGet == false then
        btnStr = GUITips.RSI_HSL_TIP13
    else
        btnStr = GUITips.RSI_HSL_TIP11
    end

    self.m_pRideBtn:getChildByName("Text"):setString(btnStr)
end

function MountInfoUI:GetCurHorseId()
    local hdata = LRoleDataMgr.MyHeroInfo
    local arr = LDataConstMgr:GetHorseConfigArr()
    return  arr[self.m_curSelectInd +1].id
end

function MountInfoUI:GetCurHorse()
    local arr = LDataConstMgr:GetHorseConfigArr()
    return  arr[self.m_curSelectInd +1]
end

function MountInfoUI:ShowMountAni()
    local hdata = LRoleDataMgr.MyHeroInfo
    local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    local horseData = self:GetCurHorse()
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
function MountInfoUI:ShowTotalAttr()
    local herodata = LRoleDataMgr.MyHeroInfo
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
function MountInfoUI:ShowMountAttr()
    local herodata = LRoleDataMgr.MyHeroInfo
    local _horinfo = herodata.horseExInfo
    local CurHorse = self:GetCurHorse()

    self.m_pNameLabel:setString(CurHorse.name)

    self.m_pPowerLabel:setString(GUITips.UI_Power_All .. herodata:GetHorsePower(CurHorse.id,_horinfo.qhLevel,0))

    -- self.TotalCell={}

    -- local attrType
    -- local attrValue
    local ind
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
    --self:ShowTotalAttr()
    -- local qianghuadata = LDataConstMgr:GetHorseStrengthData(_horinfo.qhLevel)

    -- local horseList = LDataConstMgr:GetHorseConfigArr()
    -- local hdata = LRoleDataMgr.MyHeroInfo
    -- local ToatlPower = 0
    --  for i = 1, #horseList do
    --      local horsedata = horseList[i]
    --         --获得
    --         if horsedata.isGet == true then
    --           for i = 2, 5 do
    --              attrType = horsedata.attrTypeArr[i-1]
    --              attrValue = horsedata.attrValueArr[i-1]
               
    --              if attrType~=nil then      
                      
    --                   if self.TotalCell[attrType]~=nil and self.TotalCell[attrType]~=0  then
    --                      self.TotalCell[attrType]=attrValue+self.TotalCell[attrType]
    --                   else
    --                     self.TotalCell[attrType]=attrValue
    --                   end
                 
    --               end 
    --             end           
    --         end

    --   end
    -- self.m_TotalAtt:removeAllItems()
    -- local qianghuadata = LDataConstMgr:GetHorseStrengthData(_horinfo.qhLevel)
    -- if _horinfo.qhLevel>=1 then
    --     for j = 1, 4 do                      
    --         if self.TotalCell[qianghuadata.attrTypeArr[j]]==nil or self.TotalCell[qianghuadata.attrTypeArr[j]]==0 then
    --             self.TotalCell[qianghuadata.attrTypeArr[j]]=0
    --         end                            
    --    end
    -- end
    --   for i,v in pairs(self.TotalCell) do

    --         local cell = self.m_pAttrCell:clone()  
    --         local value = cell:getChildByName("Value")  

    --         if i<=4 then
    --              for j = 1, 4 do
                      
    --                     if i==qianghuadata.attrTypeArr[j] then
    --                         v=qianghuadata.attrValueArr[j]+v
    --                     end
    --              end
    --           Utils:ShowAttrLabel(cell, i, value, v, false)
    --         else
    --           Utils:ShowAttrLabel(cell, i, value, v / 100, true)
    --         end
    --          ToatlPower=LDataConstMgr:GetSingleAttrPower(i,v)+ToatlPower
    --         cell:getChildByName("Value"):setVisible(true)
    --         cell:setVisible(true)
    --         self.m_TotalAtt:pushBackCustomItem(cell)
           
    --   end
    --     herodata.HorseTotalPower=ToatlPower
    --     self.m_TotalZhanLi:setString(ToatlPower)
end

function MountInfoUI:GetShowIdx(useIdx)
    --print("GetShowIdx",useIdx)
    local mHorse = LRoleDataMgr.MyHeroInfo.Horse
    if useIdx > #mHorse then
        return 0
    end
    local horseId = mHorse[useIdx+1].id
    local hlist = LDataConstMgr:GetHorseConfigArr()
    for i = 1, #hlist do
        if hlist[i].id == horseId then
            return i
        end
    end
    return 0
end

function MountInfoUI:TableCellAtIndex(sender, idx)
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

function MountInfoUI:CheckItemExchangeRedDot(getType,isGet,itemId,itemNum)
    if getType == 2 and not isGet and itemId > 0 then
        local curNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
        if curNum >=  itemNum then
            return true
        end
    end
    return false
end

function MountInfoUI:ShowCellInfo(cellChild, idx)
    local mountArr = LDataConstMgr:GetHorseConfigArr()
    local horsedata = mountArr[idx+1]
    local headImg = cellChild:getChildByName("bg_icon"):getChildByName("Icon")
    headImg:loadTexture(string.format("res2/Horse_Bust/%d_tou.png", horsedata.id),ccui.TextureResType.localType)
    --红点
    local redDotImg = cellChild:getChildByName("Prompt")
    if redDotImg ~= nil then
        local value = self:CheckItemExchangeRedDot(horsedata.getWayType,horsedata.isGet,horsedata.getWayItem,horsedata.getWayNum)
        redDotImg:setVisible(value)
    end

    --坐骑名字
    local nameLabel = cellChild:getChildByName("Name")
    nameLabel:setString(horsedata.name)

    --获得
    local gotLabel = cellChild:getChildByName("State")
    if horsedata.isGet == true then
        gotLabel:setString(GUITips.RSI_PAGE_MSG37)
        gotLabel:setTextColor(UICOLOR_GREEN)
    else
        gotLabel:setString(GUITips.RSI_PAGE_MSG36)
        gotLabel:setTextColor(UICOLOR_RED)
    end

    local chuandaiLabel = cellChild:getChildByName("DressState")
    local hdata = LRoleDataMgr.MyHeroInfo
    local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
    if showIdx ==  idx+1 then
        chuandaiLabel:setVisible(true)
    else
        chuandaiLabel:setVisible(false)
    end
    
    local str = string.sub(horsedata.desc, 5, string.len(horsedata.desc) - 4)
    local descLabel = cellChild:getChildByName("Source")
    descLabel:setString(str)
end

function MountInfoUI:AddTouchEvt()
    local function btnCallback(sender)
        local hdata = LRoleDataMgr.MyHeroInfo
        local hsid = hdata.sid
        if hSid == 54 or hSid == 55 then
            if hdata.huoDongState == 1 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_HSL_TIP2)
                self:SendMsg(LGameMsg.m_scrollTipsMsg)
                return
            end
        end

        local showIdx = self:GetShowIdx(hdata.horseExInfo.useIndex)
        local horsedata = self:GetCurHorse()
        if showIdx ==  self.m_curSelectInd+1 then
            --休息
            LuaNetSendMsg:QueryHorseRideInfo(4, 0xff)--发送休息消息
        elseif horsedata.isGet == false then
            --获得
            if horsedata.getway == 0 then
                local tip
                if horsedata.id == 1 then
                    tip = GUITips.RSI_HSL_TIP10
                else
                    tip = GUITips.RSI_HSL_TIP9
                end
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,tip)
                self:SendMsg(LGameMsg.m_scrollTipsMsg)
            elseif horsedata.getway == 1 then
                --这个说是不要了
            else
                LuaNetSendMsg:QueryHorseRideInfo(6, horsedata.id)--发送获得消息
            end
        else
            --乘骑
            LuaNetSendMsg:QueryHorseRideInfo(4, horsedata.id)--发送骑乘消息
        end
    end
    self.m_pRideBtn:addClickEventListener(btnCallback)
	self:MarkIntaractCObj(self.m_pRideBtn)
end

return MountInfoUI
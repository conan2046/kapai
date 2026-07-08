--[[
lua里面的游戏逻辑控制
神器信息界面
]]

local OtherRoleArtifactUI = LUIBase:New()
OtherRoleArtifactUI.__index = OtherRoleArtifactUI
--local this = LTcpSocket
function OtherRoleArtifactUI:New()
	local o = LUIBase:New()
	setmetatable(o,OtherRoleArtifactUI)	
    o:Init()
	return o
end


function OtherRoleArtifactUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/ShenqiLayer.csb")--神器信息
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
    self:ShowShenQiAllAttr()
    self:ShowShenQiInfo()
    self:ShowRoleModel()
end

function OtherRoleArtifactUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_selectIdx = nil
    self.m_selectCell = nil
    self.m_pLeftTableView = nil
    self.m_pCell = nil
    
    self.m_selectIdx = nil
    
    self.m_nameLabel = nil
    self.m_attr1Label = nil
    self.m_attr2Label = nil
    self.m_attr3Label = nil
    self.m_attr4Label = nil
    self.m_attr5Label = nil
    self.m_attr6Label = nil
    self.m_conLabel = nil
    --角色模型
    self.m_pRoleNode = nil
    self.m_pRoleModel = nil

    --神器总属性
    self.m_allZhanliLabel = nil
    self.m_listView = nil
    
    self.m_button = nil
    if self.m_allAttrLabel then
        self.m_allAttrLabel:release()
        self.m_allAttrLabel = nil
    end
    self.m_btnLabel = nil
    self.m_allAttrLabels = nil
    self:UnRegistMsgs()
end

--[[
注册UI消息
]]
function OtherRoleArtifactUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

--[[
释放注册UI消息
]]
function OtherRoleArtifactUI:UnRegistMsgs()
    self.msgIds = 
    {
    }
    self:UnRegistSelf(self,self.msgIds)
end

function OtherRoleArtifactUI:ProcessEvent(msg)
end

function OtherRoleArtifactUI:InitData()
    local panel = self.m_pUILayer:getChildByName("ShenqiUI")
    --tableview部分
    local leftView = panel:getChildByName("List")
    self.m_pCell = panel:getChildByName("Item")
    self.m_pCell:setVisible(false)
    
    self.m_selectIdx = 0
    self:InitLeftTabView(leftView)
    self:RefreshCell()

    --信息部分
    local shenQiPanel = panel:getChildByName("Panel");
    self.m_nameLabel = shenQiPanel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_attr1Label = shenQiPanel:getChildByName("Attribute1")
    self.m_attr2Label = shenQiPanel:getChildByName("Attribute2")
    self.m_attr3Label = shenQiPanel:getChildByName("Attribute3")
    self.m_attr4Label = shenQiPanel:getChildByName("Attribute4")
    self.m_attr5Label = shenQiPanel:getChildByName("Attribute5")
    self.m_attr6Label = shenQiPanel:getChildByName("Attribute6")
    self.m_attr1Label:getChildByName("Value"):setVisible(false)
    self.m_attr2Label:getChildByName("Value"):setVisible(false)
    self.m_attr3Label:getChildByName("Value"):setVisible(false)
    self.m_attr4Label:getChildByName("Value"):setVisible(false)
    self.m_attr5Label:getChildByName("Value"):setVisible(false)
    self.m_attr6Label:getChildByName("Value"):setVisible(false)
    self.m_conLabel = shenQiPanel:getChildByName("Condition")
    --角色模型
    self.m_pRoleNode = shenQiPanel:getChildByName("Node")
    self.m_pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,0)
    self.m_pRoleNode:addChild(self.m_pRoleModel)

    --神器总属性
    local attrPanel = panel:getChildByName("Panel_0")
    self.m_allZhanliLabel = attrPanel:getChildByName("Power"):getChildByName("Value")
    self.m_allZhanliLabel:setString("0")
    self.m_listView = attrPanel:getChildByName("ListView")
    self.m_allAttrLabel = self.m_listView:getChildByName("Attribute")
    self.m_button = attrPanel:getChildByName("Button")
    self.m_button:setVisible(false)
    self.m_allAttrLabel:retain()
    self.m_allAttrLabel:removeFromParent()
    self.m_btnLabel = self.m_button:getChildByName("Text")

    --self.m_button = attrPanel:getChildByName("Button")
    self.m_listView:setScrollBarEnabled(false)
    self.m_allAttrLabels = {}
end

function OtherRoleArtifactUI:AddTouchEvt()
end

function OtherRoleArtifactUI:RefreshCell()
    local info = LRoleDataMgr.m_otherShenqi
    self.m_curGridNum = #info;
    self.m_pLeftTableView:reloadData()
end

function OtherRoleArtifactUI:InitLeftTabView(leftView)
    local tableView = cc.TableView:create(leftView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(leftView:getAnchorPoint())
    tableView:setPosition(leftView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    leftView:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
       -- print("tableCellTouched",sender,cell,cell:getIdx())
        self:LeftTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:LeftTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView() 
        return self.m_curGridNum
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pLeftTableView = tableView
end


--点击选中处理
function OtherRoleArtifactUI:LeftTableCellTouched(cell)
    local ind = cell:getIdx()
    if ind == self.m_selectIdx then
        return
    end
    local oldCell = self.m_pLeftTableView:cellAtIndex(self.m_selectIdx)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nli then
            oldCellChild:getChildByName("Choose"):setVisible(false)
        end
    end

    self.m_selectIdx = ind
    local cellChild = cell:getChildByTag(123)
    self.m_selectCell = cellChild:getChildByName("Choose")
    self.m_selectCell:setVisible(true)
    self:ShowShenQiInfo()
    self:ShowRoleModel()
end 


function OtherRoleArtifactUI:LeftTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()

        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)      
        cellChild:getChildByName("Prompt"):setVisible(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowLeftCellInfo(cellChild, idx)
    
    return cell
end



function OtherRoleArtifactUI:ShowLeftCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    local index = idx+1;
    local iconImage = cellChild:getChildByName("bg_icon"):getChildByName("Icon")    
    local selectImg = cellChild:getChildByName("Choose")
    local nameLabel = cellChild:getChildByName("Name")
    local stateLabel = cellChild:getChildByName("State")
    local srcLabel = cellChild:getChildByName("Source")
    local signImage = cellChild:getChildByName("DressState")--跟随标识
    srcLabel:setVisible(false)
    if self.m_selectIdx == idx then
       selectImg:setVisible(true)
    else
       selectImg:setVisible(false)
    end

    local info = LRoleDataMgr.m_otherShenqi
    if info == nil and index > #info then
        return
    end

    if info[index].state == 2 then
        signImage:setVisible(true)
    else
        signImage:setVisible(false)
    end

    iconImage:loadTexture("res2/Artifact_Bust/"..info[index].id.."_tou.png")
    nameLabel:setString(info[index].name)
    self:ShowShenQiState(stateLabel,info[index].state)

    local shenqiInfo = LDataConstMgr:GetShenQiById(info[index].id)
    if shenqiInfo ~= nil then
         nameLabel:setString(shenqiInfo.m_name)
    end
end

function OtherRoleArtifactUI:ShowShenQiState(label,state)
    if label == nil then
        return
    end
    if state == 1 then
        label:setString("("..GUITips.UI_Shenqi_Rest..")")
        label:setTextColor(CCGREEN)
    elseif state == 2 then
        label:setString("("..GUITips.UI_Shenqi_Follow..")")
        label:setTextColor(CCGREEN)
    else
        label:setString("("..GUITips.UI_Shenqi_NotGet..")")
        label:setTextColor(CCNORMAL_RED)
    end
end

function OtherRoleArtifactUI:ShowShenQiAttr(idx,attr,val,isPer)
    local str = ""
    if attr ~= nil then
        str = attr..": "
        if isPer ~= nil and isPer then
            str = str..string.format("%.2f",val/100).."%"
        else
            str = str..val
        end
    end
    local label = self["m_attr"..idx.."Label"];
    if label ~= nil then
        label:setString(str)
    end
end

function OtherRoleArtifactUI:GetAttrValue(attrType)
    local info = LArtifactUIDataMgr.m_UIOtherData
    if info == nil then return 0 end

    local level = info["cur_level"]
    local star = info ["cur_star"]
    if level == nil or star == nil then
        return 0
    end
    local value = 0
    local data = LDataConstMgr:GetShenQiCultureData(level,star)
    if data == nil then return 0 end
    for i=1,#data.m_attrList do
        if attrType == data.m_attrList[i].attrType then
            value = data.m_attrList[i].attrValue
            break
        end
    end
    return value
end

function OtherRoleArtifactUI:AddAttrValue(allAttr)
    if allAttr == nil then allAttr = {} end
    local info = LArtifactUIDataMgr.m_UIOtherData
    if info == nil then return 0 end

    local level = info["cur_level"]
    local star = info ["cur_star"]
    if level == nil or star == nil then
        return 0
    end
    local value = 0
    local data = LDataConstMgr:GetShenQiCultureData(level,star)
    
    if data == nil then return 0 end
    for i=1,#data.m_attrList do
        local attrType = data.m_attrList[i].attrType
        local attrValue = data.m_attrList[i].attrValue
        if attrValue > 0 then
            if allAttr[attrType] == nil then
                allAttr[attrType] = attrValue
            else
                allAttr[attrType] = allAttr[attrType] + attrValue
            end
        end
    end
end

function OtherRoleArtifactUI:ShowShenQiInfo()
    local info = LRoleDataMgr.m_otherShenqi
    if info == nil or #info == 0 or self.m_selectIdx < 0 or self.m_selectIdx + 1> #info then
        return
    end
    local data = info[self.m_selectIdx + 1];
    local shenqiInfo = LDataConstMgr:GetShenQiById(data.id)
    if shenqiInfo == nil then return end
    self.m_nameLabel:setString(shenqiInfo.m_name)
    self.m_conLabel:setString(shenqiInfo.m_desc)
    local count = 1
    local attrList = shenqiInfo.m_attrList
    for i = 1,#attrList do
        if attrList[i].attrType > 0  then
            local attrValue = attrList[i].attrValue--[[+self:GetAttrValue(attrList[i].attrType)]]
            local isPercent = false
            if attrList[i].attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
                isPercent = true
            end
            self:ShowShenQiAttr(count,LDataConstMgr:GetAttrConfigData(attrList[i].attrType).attrName,attrValue,isPercent)
            count = count +1
        end
        if count > 6 then
            break
        end
    end

    --TODO 单个神器战力不显示
--    if count < 5 then
--        count = 5
--        self.m_attr6Label:setString("")
--    end
--    self:ShowShenQiAttr(count,GUITips.UI_Shenqi_Zhanli,data.zhandouli)

    --按钮文字  data.state--0佩戴，1卸下， 2激活
    self:ShowButtonText(data.state)
end

--按钮文字  data.state--0佩戴，1卸下， 2激活
function OtherRoleArtifactUI:ShowButtonText(state)
    if state == 1 then 
        self.m_btnLabel:setString(GUITips.UI_Btn_Equip_PutOn)
    elseif state == 2 then
        self.m_btnLabel:setString(GUITips.UI_Btn_Equip_PutOff)
    else 
        self.m_btnLabel:setString(GUITips.UI_Shenqi_Active)
    end
end

function OtherRoleArtifactUI:ShowShenQiAllAttr()
    local info = LRoleDataMgr.m_otherShenqi
    if info == nil or #info == 0 then      
       return
    end
    --
    local allAttrs = {}
    for i = 1,#info do
        local shenqiInfo = LDataConstMgr:GetShenQiById(info[i].id)
        if shenqiInfo ~= nil and info[i].state ~= 0 then
            for k = 1,#shenqiInfo.m_attrList do
                local attrType = shenqiInfo.m_attrList[k].attrType
                local attrValue = shenqiInfo.m_attrList[k].attrValue
                --power = power +  LDataConstMgr:GetSingleAttrPower(attrType,attrValue)
                if allAttrs[attrType] == nil then
                    allAttrs[attrType] = attrValue
                else
                    allAttrs[attrType] = allAttrs[attrType] + attrValue
                end
            end
        end
    end

    self:AddAttrValue(allAttrs)
 
    --self.m_allAttrLabels = {}
    --table.insert(self.m_allAttrLabels,self.m_allAttrLabel)
    local idx = 1
    local power = 0
    for k,v in pairs(allAttrs) do
       if self.m_allAttrLabels[idx] == nil then
           self.m_allAttrLabels[idx] = self.m_allAttrLabel:clone()
           self.m_listView:addChild(self.m_allAttrLabels[idx])
       end
       local attrConfigData = LDataConstMgr:GetAttrConfigData(k)
       if attrConfigData ~= nil then
           local attrValue = v
           local valueStr = self.m_allAttrLabels[idx]:getChildByName("Value")
           Utils:ShowAttrLabelSec(self.m_allAttrLabels[idx], k, valueStr, attrValue)
           power = power +  LDataConstMgr:GetSingleAttrPower(k,attrValue)
       end
       idx = idx + 1
    end
    self.m_allZhanliLabel:setString(Utils:getPowerStr(power))
end

--模型显示
function OtherRoleArtifactUI:ShowRoleModel()
    local shenqiId = 0;
    local index = self.m_selectIdx+1;
    local info = LRoleDataMgr.m_otherShenqi
    if info ~= nil and index <= #info then
       shenqiId = info[index].id
    end
    local data = LRoleDataMgr.OtherHeroInfo

    self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            data.professional, 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            data.WingsId,
                                            0,
                                            shenqiId)
    self.m_pRoleModel:PlayStand(0)
end
return OtherRoleArtifactUI
--[[
lua里面的游戏逻辑控制
神器进阶界面
]]

local ArtifactDevelopUI = LUIBase:New()
ArtifactDevelopUI.__index = ArtifactDevelopUI
--local this = LTcpSocket
function ArtifactDevelopUI:New()
	local o = LUIBase:New()
	setmetatable(o,ArtifactDevelopUI)	
    o:Init()
	return o
end


function ArtifactDevelopUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/ShenqiDevelopLayer.csb")--神器信息
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
    self:ShowShenQiInfo()
    self:ShowRoleModel()
    self:AutoPutIn()
end

function ArtifactDevelopUI:onExit()
    self.m_pUILayer = nil
    self.m_starImages = nil
    self:Destory()
end

--[[
注册UI消息
]]
function ArtifactDevelopUI:RegistMsgs()
    self.msgIds = 
    {
        LUIShenQiEvent.ShenQiDevelopInfoChanged,
        --LUIItemListUIEvent.SelectItem,
    }
    self:RegistSelf(self,self.msgIds)
end

function ArtifactDevelopUI:ProcessEvent(msg)
    if msg.msgId == LUIShenQiEvent.ShenQiDevelopInfoChanged then
        self:UpdateDevelopUI()
    elseif msg.msgId == LUIItemListUIEvent.SelectItem then
        self:UpdateItemInfo(msg.value)
    end

end

--刷新页面
function ArtifactDevelopUI:UpdateDevelopUI()
    self:ShowShenQiInfo()
    self:ShowRoleModel()

    self:AutoPutIn()
end

--刷新Icon
function ArtifactDevelopUI:UpdateItemInfo(itemInfo)
    if itemInfo == nil then
        return
    end
    self.m_itemId = itemInfo["id"]
    self.m_itemNum = itemInfo["num"]
    self:ShowStoneInfo()
end

function ArtifactDevelopUI:InitData()
    local panel = self.m_pUILayer:getChildByName("ShenqiDevelopUI")
    --panel:setTouchEnabled(false)
    
    --信息部分
    self.m_attr1Label = panel:getChildByName("Attribute_1") --攻击
    self.m_attr2Label = panel:getChildByName("Attribute_2") --防御
    self.m_attr3Label = panel:getChildByName("Attribute_3") --气血
    self.m_attr4Label = panel:getChildByName("Attribute_4") --速度
    self.m_attr5Label = panel:getChildByName("Attribute_5") --速度
    self.m_attrVal1Label = self.m_attr1Label:getChildByName("Value") --属性值
    self.m_attrVal2Label = self.m_attr2Label:getChildByName("Value") --属性值
    self.m_attrVal3Label = self.m_attr3Label:getChildByName("Value") --属性值
    self.m_attrVal4Label = self.m_attr4Label:getChildByName("Value") --属性值
    self.m_attrVal5Label = self.m_attr5Label:getChildByName("Value") --属性值
    self.m_num1Label = self.m_attr1Label:getChildByName("Value_0") --下一级属性差值
    self.m_num2Label = self.m_attr2Label:getChildByName("Value_0") --下一级属性差值
    self.m_num3Label = self.m_attr3Label:getChildByName("Value_0") --下一级属性差值
    self.m_num4Label = self.m_attr4Label:getChildByName("Value_0") --下一级属性差值
    self.m_num5Label = self.m_attr5Label:getChildByName("Value_0") --下一级属性差值
  
    local leftPanel = panel:getChildByName("Panel")
    local rightPanel = panel:getChildByName("Panel_0")
	local pHelpBtn = rightPanel:getChildByName("btn_help")
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
    --角色模型
    self.m_pLRoleNode = leftPanel:getChildByName("RolePoint")
    self.m_pRRoleNode = rightPanel:getChildByName("RolePoint")
    local data = LRoleDataMgr.MyHeroInfo
    self.m_pLRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, data.professional)
    self.m_pLRoleNode:addChild(self.m_pLRoleModel)
    self.m_pRRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, data.professional)
    self.m_pRRoleNode:addChild(self.m_pRRoleModel)

    --神器名称、阶段
    self.m_LNameLabel = leftPanel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_LStageLabel = leftPanel:getChildByName("bg_Class"):getChildByName("Text")

    self.m_RNameLabel = rightPanel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_RStageLabel = rightPanel:getChildByName("bg_Class"):getChildByName("Text")

    --按钮
    self.m_DevelopButton = panel:getChildByName("btn_Upgrad") --培养
    self.m_redImg = self.m_DevelopButton:getChildByName("Prompt")
    self.m_redImg:setVisible(false)
    self.m_AddButton = panel:getChildByName("btn_Material")   --添加道具（“+”号）

    --进度条
    local barPanel = panel:getChildByName("bg_xianling")
    self.m_LoadingBar = barPanel:getChildByName("LoadingBar_2")
    self.m_LoadingBarNext = barPanel:getChildByName("LoadingBar_1")
    self.m_barLabel = barPanel:getChildByName("Value")

    --星星
    local starPanel = panel:getChildByName("Star")
    self.m_starImages = {}
    table.insert(self.m_starImages,starPanel:getChildByName("Image"))
    table.insert(self.m_starImages,starPanel:getChildByName("Image_0"))
    table.insert(self.m_starImages,starPanel:getChildByName("Image_1"))
    table.insert(self.m_starImages,starPanel:getChildByName("Image_2"))
    table.insert(self.m_starImages,starPanel:getChildByName("Image_3"))

    --道具Icon
    local icon  = self.m_AddButton:getChildByName("Icon")
    icon:setVisible(false)
    self.m_addImage = self.m_AddButton:getChildByName("Image")
    self.m_nameLabel = panel:getChildByName("Name")
    --数量
    self.m_itemNumLabel = self.m_AddButton:getChildByName("Value")
    self.m_itemNumLabel:setVisible(false)
   
    self.m_attrMaxNum = 5
end

function ArtifactDevelopUI:helpButtonCallback()
    local str = GUITips.RSI_Help_Str8
    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function ArtifactDevelopUI:AddTouchEvt()
    local function developBtnTouched(sender)
        if self.m_itemId == nil then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.UI_Shenqi_Error_Non_Stone)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        if self.m_itemNum == nil then
            self.m_itemNum = 1
        end

        --若没有材料,则显示来源
        if LRoleDataMgr:getLowMatrialNumByType(AppDef.EItemListType.EILTWuSeStone) < 1 then
            local id = LRoleDataMgr:getLowMatrialIdByType(AppDef.EItemListType.EILTWuSeStone)
            item = 
            {
                itemType = "CItem",
                itemData = LItemMgr:getItem(id)
            }
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            return
        end
        
        LuaNetSendMsg:SendShenQiReq(4,self.m_itemId,self.m_itemNum)--道具ID，道具数量
    end
    self.m_DevelopButton:addClickEventListener(developBtnTouched)  --神器培养
	self:MarkIntaractCObj(self.m_DevelopButton)
--    local function addBtnTouched(sender)
--        --弹出道具列表
--        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemListUI, {AppDef.EItemListType.EILTWuSeStone})
--            self:SendMsg(LGameMsg.m_baseMsgWithOne)
--    end
    --self.m_AddButton:addClickEventListener(addBtnTouched)  --神器培养
end

--通过当前等级、星级获取下一级属性文字
function ArtifactDevelopUI:GetNextAttrStr(level,star,index)
    local curData = LDataConstMgr:GetShenQiCultureData(level,star)
    if curData == nil then return ""  end
    local nextData = LDataConstMgr:GetShenQiCultureData(level+1,0)
    if nextData == nil then return ""  end
    --local attrData = LDataConstMgr:GetAttrConfigData(curData.m_attrList[index].attrType)
    local attrValue = nextData.m_attrList[index].attrValue - curData.m_attrList[index].attrValue
    return "+"..attrValue
end

function ArtifactDevelopUI:GetAttrValue(attrType,attrValue,id)
    local value = attrValue
    local info = LRoleDataMgr:GetShenQiDataById(id)
    if info == nil or info.state == 0 then
       return value
    end

    local shenqiInfo = LDataConstMgr:GetShenQiById(id)
    for i=1,#shenqiInfo.m_attrList do
        if attrType == shenqiInfo.m_attrList[i].attrType then
            value = value + shenqiInfo.m_attrList[i].attrValue
        end
    end
    return value
end

function  ArtifactDevelopUI:ShowShenQiInfo()
    local info = LArtifactUIDataMgr.m_UIData
    if info == nil then
       return
    end
    local level = info["cur_level"]
    local star = info["cur_star"]
    local data = LDataConstMgr:GetShenQiCultureData(level,star)
    if data == nil then
        return
    end
    local curId = data.m_cur_shenqi
    local nextId = data.m_next_shenqi
    info["cur_id"] = curId
    info["next_id"] = nextId
    for i=1,self.m_attrMaxNum do
        if data.m_attrList[i] == nil then break end
        local attrValue = data.m_attrList[i].attrValue
        Utils:ShowAttrLabel(self["m_attr"..i.."Label"],data.m_attrList[i].attrType,self["m_attrVal"..i.."Label"],attrValue)

        if nextId > 0 then
            self["m_num"..i.."Label"]:setString(self:GetNextAttrStr(level,star,i)) --下一级属性差值
        end
    end

    local curData = LDataConstMgr:GetShenQiById(curId)
    local nextData = nil
    if nextId == 0 then
        nextData = LDataConstMgr:GetShenQiById(curId)
    else
        nextData = LDataConstMgr:GetShenQiById(nextId)
    end

    local levelStrs = {}--{"一阶", "二阶", "三阶", "四阶", "五阶", "六阶"}
    for i= 1,10 do
        table.insert(levelStrs,GUITips["UI_Shenqi_Level"..i])
    end
    --名称、阶段
    if curData ~= nil then
        self.m_LNameLabel:getParent():setVisible(true)
        self.m_LNameLabel:setString(curData.m_name)
        self.m_LStageLabel:setString(GUITips.UI_Shenqi_Cur..": "..levelStrs[level])
    else 
        self.m_LNameLabel:getParent():setVisible(false)
        self.m_LNameLabel:setString("")
        self.m_LStageLabel:setString(GUITips.UI_Shenqi_Cur..": "..levelStrs[1])
    end

    if nextData ~= nil then
        self.m_RNameLabel:setString(nextData.m_name)
        self.m_RStageLabel:setString(GUITips.UI_Shenqi_Next..": "..levelStrs[info["next_level"]])
    elseif curData ~= nil then
        self.m_RNameLabel:setString(curData.m_name)
        self.m_RStageLabel:setString(GUITips.UI_Shenqi_Cur..": "..levelStrs[level])
    end

    --进度条
    local curExp = info["cur_exp"]
    local maxExp = data.m_needExp
    info["max_exp"] = maxExp
    local percent = 0
    if maxExp == 0 then
        percent = 100
        self.m_barLabel:setString(GUITips.UI_Shenqi_MaxLevel)
    else
        percent = curExp*100/maxExp
        self.m_barLabel:setString(curExp.."/"..maxExp)
    end
    self.m_LoadingBar:setPercent(percent)
    self.m_LoadingBarNext:setPercent(0)

    local starNum = info["cur_star"]
    --星星
    for i=1,starNum do
        self.m_starImages[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_01.png",ccui.TextureResType.plistType)
    end
    for i=starNum+1,5 do
        self.m_starImages[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_02.png",ccui.TextureResType.plistType)
    end
end

--
function ArtifactDevelopUI:ShowRoleModel()
    local info = LArtifactUIDataMgr.m_UIData
    if info == nil then
       return
    end
    local curId = info["cur_id"] or 0
    local nextId = info["next_id"] or 0
    if nextId == 0 then
        nextId = curId
    end
    self:ShowModel(self.m_pLRoleNode,self.m_pLRoleModel,curId)
    self:ShowModel(self.m_pRRoleNode,self.m_pRRoleModel,nextId)
end

--模型显示
function ArtifactDevelopUI:ShowModel(modelNode,model,shenqiId)
    local data = LRoleDataMgr.MyHeroInfo
    if shenqiId == nil then
        shenqiId = 0
    end
    if data.professional == nil or data:GetWeaponId() == nil or data.LightEffect == nil or shenqiId == nil then
        return
    end
    model:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            data.professional, 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            data.WingsId,
                                            0,
                                            shenqiId)
    model:PlayStand(0)

    -- local off = 0
    -- if data:GetHorseId() > 0 then
    --     off = -80
    -- end
    -- model:setPositionY(off)
end

--刷新Icon
function ArtifactDevelopUI:ShowStoneInfo()
    if self.m_itemId == nil or self.m_itemNum == nil then
        self.m_nameLabel:setString(GUITips.UI_Shenqi_Msg1) 
        if self.m_icon ~= nil then
            self.m_icon:UpdateItem(nil)
        end
        return
    end
    if self.m_itemId > 0 and self.m_itemNum > 0 then
        local dItem = LItemMgr:getItem(self.m_itemId)
        if dItem ~= nil then
            self.m_nameLabel:setString(dItem.m_name) 
        end
        self.m_icon = Utils:GetItemCellValue(self.m_AddButton,0,self.m_itemId,true,true,self.m_itemNum,self.m_icon,false)     

        local info = LArtifactUIDataMgr.m_UIData
        if info ~= nil then
            local curExp = info["cur_exp"] or 1
            local maxExp = info["max_exp"] or 1
            local add = dItem.additionalValue*self.m_itemNum
            local percent = (curExp+add)*100/maxExp
            if percent > 100 then percent = 100 end
            self.m_LoadingBarNext:setPercent(percent)
            self.m_barLabel:setString(""..curExp.."(+"..add..")/"..maxExp)
        end
    else
        
        local dItem = LItemMgr:getItem(AppDef.WuSeStoneIds[#AppDef.WuSeStoneIds])
        if dItem ~= nil then
            self.m_nameLabel:setString(dItem.m_name) 
        end
        self.m_icon = Utils:GetItemCellValue(self.m_AddButton,0,dItem.m_id,true,true,0,self.m_icon,true)  
    end
end

function ArtifactDevelopUI:AutoPutIn()
    self.m_itemId = 0
    self.m_itemNum = 0
    for i=1,#AppDef.WuSeStoneIds do
        local itemId = AppDef.WuSeStoneIds[i]
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
        if itemNum > 0 then
            self.m_itemId = itemId
            self.m_itemNum = itemNum
            break
        end
    end
    self:ShowStoneInfo()
end 

return ArtifactDevelopUI
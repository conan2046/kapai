local EquipInfoUI = LUIBase:New()
EquipInfoUI.__index = EquipInfoUI
local HeroBuildRecommendation = require("Data.HeroBuildRecommendation")

local function GetAffixBuildRecommendation(key)
    local prefix = string.match(key or "", "^([A-Z]+)") or ""
    local builds = {
        SHIELD = "护盾守护流｜适合护盾、援护与减伤神将",
        HEAL = "治疗复苏流｜适合治疗、净化与复活神将",
        GUARD = "嘲讽承伤流｜适合前排坦克与援护神将",
        COUNTER = "反击荆棘流｜适合受击反打与分伤神将",
        CRIT = "暴击斩杀流｜适合单体爆发与收割神将",
        COMBO = "连击追击流｜适合普攻连段与追加行动神将",
        BREAK = "破盾破法流｜适合穿透、驱盾与法术爆发神将",
        CONTROL = "控制先手流｜适合眩晕、沉默与速度压制神将",
        DOT = "持续伤害流｜适合毒、灼烧与异常扩散神将",
        DEBUFF = "弱化禁疗流｜适合减益、禁疗与易伤神将",
        DEATH = "献祭召唤流｜适合死亡触发与召唤神将",
        TACTIC = "战意战法流｜适合战法循环与团队辅助神将",
    }
    return builds[prefix] or "通用构筑｜根据神将技能标签搭配"
end

function EquipInfoUI:New(userdata)
    local o = LUIBase:New()
    setmetatable(o,EquipInfoUI) 
    o:Init(userdata)
    return o
end

function EquipInfoUI:Init(userdata)
    self.Script = "PetEquip.EquipInfoUI"
    self:CreateUINode("csd/zhuangbeiyangcheng/zhuangbeiInfo.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeiInfo.csb")
    if userdata ~= nil then
        self.m_id = userdata["id"]
        self.m_uid = userdata["uid"]
        self.m_IsShowBtn = userdata["isShowBtn"]
        self.m_heroPos = userdata["heroPos"]--查看其他玩家神将装备使用
    end
    self.m_id = self.m_id or 0
    self.m_uid = self.m_uid or 0
    self.m_heroPos = self.m_heroPos or 0
    if self.m_IsShowBtn == nil then
        self.m_IsShowBtn = false
    end
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
	self:RegistMsgs()
    self:ShowLeftInfo()
    self:ShowRightInfo()
    self:RegisterGuide()
	self:UpdateRedDotUI()
end

function EquipInfoUI:RegistMsgs()
    self.msgIds = { LUIPetEvent.GotPetEquip }
    self:RegistSelf(self, self.msgIds)
end

function EquipInfoUI:ProcessEvent(msg)
    if msg.msgId ~= LUIPetEvent.GotPetEquip or self.m_heroPos > 0 then return end
    local equips = LRoleDataMgr.Pet.equipList and LRoleDataMgr.Pet.equipList.m_petEquips
    self.m_info = equips and equips[self.m_uid] or self.m_info
    self.m_fpos = self.m_info and self.m_info.m_fpos or 0
    self:RefreshAffixDescription()
    self:RefreshAffixActions()
    self:RefreshBuildRecommendation()
end

function EquipInfoUI:InitData()
    local panel = self.m_pUILayer:getChildByName("zhuangbeiInfoUI")
    local maskImg = panel:getChildByName("Mask")
    maskImg:setTouchEnabled(true)
    local closeBtn = panel:getChildByName("Popup"):getChildByName("Btn_close")
    closeBtn:addClickEventListener(function(sender)
        self:CloseUI()
    end)

    --左边
    local left = panel:getChildByName("zhuangbei")
    self.m_iconNode = left:getChildByName("Node")
    self.m_nameLabel = left:getChildByName("Namebg"):getChildByName("Name")
    self.m_xieBtn = left:getChildByName("Btn_xiexia")
    self.m_huanBtn = left:getChildByName("Btn_genghuan")
    self.m_xieBtn:addClickEventListener(function (sender)--脱装备
        -- body
        if self.m_uid > 0 and self.m_fpos > 0 then
            LuaNetSendMsg:SendPetEquipWearReq(3,self.m_uid,self.m_fpos)
            self:CloseUI()
        end
    end)
    self.m_huanBtn:addClickEventListener(function (sender)--更换装备
        if self.m_uid > 0 and self.m_fpos > 0 and self.m_info ~= nil then
            local part = self.m_info.m_wpos or 0
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "PetEquip.PetEquipChangeUI",AppDef.UIType.PopWindow,{part,self.m_fpos})
            self:SendMsg(LGameMsg.m_initUIMsg)
            self:CloseUI()
        end
    end)

    --右边
    local right = panel:getChildByName("Info")
    self.m_scrollView = right:getChildByName("ScrollView")
    self.m_listView = right:getChildByName("ListView")
    self.m_baseAttr = right:getChildByName("jichushuxing")
    self.m_baseAttrType = self.m_baseAttr:getChildByName("Atrribute_1")

    self.m_qhAttr = right:getChildByName("qianghuashuxing")
    --self.m_qhLvLabel = self.m_qhAttr:getChildByName("Level"):getChildByName("Value")
    self.m_qhAttrType = self.m_qhAttr:getChildByName("Atrribute_1")
    self.m_qhBtn = self.m_qhAttr:getChildByName("Btn_qianghua")
    self.m_qhBtn:addClickEventListener(handler(self,EquipInfoUI.QiangHuaCallBack))

    self.m_jlAttr = right:getChildByName("jinglianshuxing")
    --self.m_jlLvLabel = self.m_jlAttr:getChildByName("Level"):getChildByName("Value")
    self.m_jlAttrType = self.m_jlAttr:getChildByName("Atrribute_1")
    local jlBtn = self.m_jlAttr:getChildByName("Btn_jinglian")
    jlBtn:addClickEventListener(function (sender)
        if self.m_uid > 0 then
            local data = self:CheckFunction(2)
			if data[1] == false then
				Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2,data[2]))
			else
				self:CloseUI()
				Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH, {2,self.m_uid})
			end
        end
    end)

    self.m_jxAttr = right:getChildByName("juexingshuxing")
    --self.m_jxLvLabel = self.m_jxAttr:getChildByName("Level"):getChildByName("Value")
    self.m_jxAttrType = self.m_jxAttr:getChildByName("Atrribute_1")
    local jxBtn = self.m_jxAttr:getChildByName("Btn_juexing")
    jxBtn:addClickEventListener(function (sender)
        if self.m_uid > 0 then
            local data = self:CheckFunction(3)
			if data[1] == false then
				Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2,data[2]))
			else
				self:CloseUI()
				Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH, {3,self.m_uid})
			end
        end
    end)

    self.m_szAttr = right:getChildByName("shenzhushuxing")
    --self.m_szLvLabel = self.m_szAttr:getChildByName("Level"):getChildByName("Value")
    self.m_szAttrType = self.m_szAttr:getChildByName("Atrribute_1")
    local szBtn = self.m_szAttr:getChildByName("Btn_shenzhu")
    szBtn:addClickEventListener(function (sender)
        if self.m_uid > 0 then
			local data = self:CheckFunction(4)
			if data[1] == false then
				Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2,data[2]))
			else
				self:CloseUI()
				Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH, {4,self.m_uid})
			end
        end    
    end)

    self.m_suitInfo = right:getChildByName("zhuangbeitaozhuang")
    self.m_suitList = self.m_suitInfo:getChildByName("List")
    self.m_suitItem = self.m_suitInfo:getChildByName("Item")
    self.m_suitAttrType = self.m_suitInfo:getChildByName("Atrribute_1")

    self.m_descNode = right:getChildByName("zhuangbeimiaoshu")
    self.m_descLabel = self.m_descNode:getChildByName("Content")

    self.m_buildRecommendationNode = ccui.Layout:create()
    self.m_buildRecommendationLabel = ccui.Text:create("", self.m_descLabel:getFontName(), 20)
    self.m_buildRecommendationLabel:setColor(cc.c3b(120, 84, 60))
    self.m_buildRecommendationLabel:setAnchorPoint(cc.p(0, 1))
    self.m_buildRecommendationLabel:ignoreContentAdaptWithSize(true)
    self.m_buildRecommendationLabel:setTextAreaSize(cc.size(410, 0))
    self.m_buildRecommendationNode:addChild(self.m_buildRecommendationLabel)

    self.m_affixActionNode = ccui.Layout:create()
    self.m_affixActionNode:setContentSize(cc.size(440, 72))
    self.m_affixLockBtn = ccui.Button:create("res/UI/ui_common_new2/btn_4.png", "res/UI/ui_common_new2/btn_5.png")
    self.m_affixLockBtn:setTitleFontSize(22)
    self.m_affixLockBtn:setPosition(cc.p(110, 36))
    self.m_affixLockBtn:addClickEventListener(function()
        LuaNetSendMsg:SendPetEquipAffixOperateReq(41, self.m_uid)
    end)
    self.m_affixActionNode:addChild(self.m_affixLockBtn)
    self.m_affixRerollBtn = ccui.Button:create("res/UI/ui_common_new2/btn_4.png", "res/UI/ui_common_new2/btn_5.png")
    self.m_affixRerollBtn:setTitleFontSize(22)
    self.m_affixRerollBtn:setPosition(cc.p(330, 36))
    self.m_affixRerollBtn:addClickEventListener(function()
        local locked = self.m_info ~= nil and bit.band(self.m_info.affixLockMask or 0, 1) ~= 0
        local baseCost = self.m_cfgData ~= nil and self.m_cfgData.quality >= 7 and 50000 or 30000
        local cost = locked and baseCost * 2 or baseCost
        local text = locked
            and string.format("锁定重铸将保留词条类型，只重置阶位，消耗%d金币。是否继续？", cost)
            or string.format("重铸将重新随机词条类型与阶位，消耗%d金币。是否继续？", cost)
        Utils:ShowDialogOKCancel(text, function()
            LuaNetSendMsg:SendPetEquipAffixOperateReq(42, self.m_uid)
        end)
    end)
    self.m_affixActionNode:addChild(self.m_affixRerollBtn)

    --数据
    if self.m_id > 0 then
        self.m_cfgData = JsonConfig.m_equipConfig.getDefByID(self.m_id)
        self.m_suitId = self.m_cfgData.suit or 0
    end
    
    if self.m_uid > 0 then
        if self.m_heroPos > 0 then
            self.m_info = LRoleDataMgr.OtherHeroInfo.MapEquip[self.m_heroPos][self.m_cfgData.part]
        else
            local petEquips = LRoleDataMgr.Pet.equipList.m_petEquips
            if petEquips ~= nil then
                self.m_info = petEquips[self.m_uid]
            end
        end
    end
    self.m_fpos = 0
    if self.m_info ~= nil then
        self.m_fpos = self.m_info.m_fpos or 0
        if self.m_id == 0 and self.m_heroPos == 0 then
            self.m_id = self.m_info.m_id
            self.m_cfgData = JsonConfig.m_equipConfig.getDefByID(self.m_id)
            self.m_suitId = self.m_cfgData.suit or 0
        end
    end
    

    self.m_qhLv = 0
    self.m_xLv = 0
    self.m_jlLv = 0
    self.m_szLv = 0
    if self.m_info ~= nil then
        self.m_jxLv = self.m_info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
        self.m_qhLv = self.m_info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
        self.m_jlLv = self.m_info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
        self.m_szLv = self.m_info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
    end

    if not self.m_IsShowBtn then
        self.m_xieBtn:setVisible(false)
        self.m_huanBtn:setVisible(false)
    end
    if self.m_heroPos > 0 then
        self.m_qhBtn:setVisible(false)
        jlBtn:setVisible(false)
        szBtn:setVisible(false)
        jxBtn:setVisible(false)
    end
end

function EquipInfoUI:QiangHuaCallBack()
    if self.m_uid > 0 then
        local data = self:CheckFunction(1)
        if data[1] == false then
            Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2,data[2]))
        else
            self:CloseUI()
            Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH, {1,self.m_uid})
        end
    end
end

function EquipInfoUI:CheckFunction(ind)
	local level = LRoleDataMgr.MyHeroInfo.level
	local func = nil
	if ind == 1 then
		func = JsonConfig.m_functionConfig.getDefByID(1120)
	elseif ind == 2 then
		func = JsonConfig.m_functionConfig.getDefByID(1130)
	elseif ind == 3 then
		func = JsonConfig.m_functionConfig.getDefByID(1140)
	elseif ind == 4 then
		func = JsonConfig.m_functionConfig.getDefByID(1150)
	end
	if func~= nil and level < func.open_condition[1][2] then
		return {false, func.open_condition[1][2]}
	end
	return {true}
end

function EquipInfoUI:ShowLeftInfo()
    if self.m_id == 0 or self.m_cfgData == nil then
        return
    end
    self.m_nameLabel:setString(self.m_cfgData.name)
    self.m_nameLabel:setColor(AppDef:GetQualityColor(self.m_cfgData.quality))

    if self.m_icon == nil then
        self.m_iconNode:setScale(1.5)
        self.m_icon = ItemCellUI:New(self.m_iconNode)
        self.m_icon.m_pUILayer:setAnchorPoint(cc.p(0.5, 0.5))
    end
    
    local itemValue = {isShowQualityBg = false}
    local petEquipData = {
        id = self.m_id
    }
    itemValue.petEquipData = petEquipData
    self.m_icon:UpdateItem(itemValue)
end

function EquipInfoUI:ShowRightInfo()
    --self.m_scrollView:removeAllChildren()
    self.m_listView:removeAllItems()
    self:ShowBaseAttr()
    self:ShowAttrs()
    self:ShowSuit()
    self:ShowDesc()
end
function EquipInfoUI:ShowBaseAttr()
    if self.m_id == 0 or self.m_cfgData == nil then
        return
    end
    self.m_baseAttr:retain()
    self.m_baseAttr:removeFromParent()
    local typeLable = self.m_baseAttrType
    local valLable = typeLable:getChildByName("Value")
    Utils:ShowAttrLabelSec(typeLable, self.m_cfgData.attr[1], valLable, "+"..self.m_cfgData.attr[2])
    self.m_listView:pushBackCustomItem(self.m_baseAttr)
end

function EquipInfoUI:ShowAttrs()
    self.m_qhAttr:setVisible(false)
    self.m_jlAttr:setVisible(false)
    self.m_jxAttr:setVisible(false)
    self.m_szAttr:setVisible(false)
    if self.m_uid == 0 or self.m_info == nil then
        return
    end
    local qhAttrs = {}
    if self.m_cfgData ~= nil and (self.m_info.qhAttrs == nil or next(self.m_info.qhAttrs) == nil) then
        for i = 1,#self.m_cfgData.atrr_qianghua do
            local attr = self.m_cfgData.atrr_qianghua[i]
            qhAttrs[attr[1]] = 0
        end
    else
        qhAttrs = self.m_info.qhAttrs
    end
    local jlAttrs = {}
    if self.m_cfgData ~= nil and (self.m_info.jlAttrs == nil or next(self.m_info.jlAttrs) == nil) then
        for i = 1,#self.m_cfgData.attr_jinglian do
            local attr = self.m_cfgData.attr_jinglian[i]
            jlAttrs[attr[1]] = 0
        end
    else
        jlAttrs = self.m_info.jlAttrs
    end
    local jxAttrs = {}
    if self.m_cfgData ~= nil and (self.m_info.jxAttrs == nil or next(self.m_info.jxAttrs) == nil) then
        for i = 1,#self.m_cfgData.attr_juexing do
            local attr = self.m_cfgData.attr_juexing[i]
            jxAttrs[attr[1]] = 0
        end
    else
        jxAttrs = self.m_info.jxAttrs
    end
    local szAttrs = {}
    if self.m_cfgData ~= nil and (self.m_info.szAttrs == nil or next(self.m_info.szAttrs) == nil) then
        for i = 1,#self.m_cfgData.attr_shenzhu do
            local attr = self.m_cfgData.attr_shenzhu[i]
            szAttrs[attr[1]] = 0
        end
    else
        szAttrs = self.m_info.szAttrs
    end
    --强化
    self:ShowAttr(self.m_qhAttr,self.m_qhAttrType,self.m_qhLv,#JsonConfig.m_equip_qianghua.getList(),qhAttrs)
    --精炼
    self:ShowAttr(self.m_jlAttr,self.m_jlAttrType,self.m_jlLv,#JsonConfig.m_equipJingLian.getList()-1,jlAttrs)
    --觉醒
    self:ShowAttr(self.m_jxAttr,self.m_jxAttrType,self.m_jxLv,-1,jxAttrs)
    --神铸
    self:ShowAttr(self.m_szAttr,self.m_szAttrType,self.m_szLv,-2,szAttrs)
    --dump(self.m_info,"jlattr=>")
end

function EquipInfoUI:ShowAttr(attrNode,attrType,level,maxLevel,attrs)
    --dump(attrs,"EquipInfoUI:ShowAttr=>")
    if level == nil or attrs == nil or  attrNode == nil or attrType == nil  then
        return
    end
    attrNode:setVisible(true)
    attrType:setString("")
    attrType:getChildByName("Value"):setString("")
    local cnt = 0
    for k,v in pairs(attrs) do
        local typeLable = nil
        if cnt == 0 then
            typeLable = attrType
            cnt = 1 
        else
            typeLable = attrType:clone()
            local pos = cc.p(attrType:getPosition())
            typeLable:setPosition(cc.p(pos.x,pos.y-typeLable:getContentSize().height*cnt-2))
            attrNode:addChild(typeLable)
            cnt = cnt +1
        end
        local valLable = typeLable:getChildByName("Value")
        --Utils:ShowAttrLabelSec(typeLable, k, valLable, v)
        if k > AppDef.EAttrType.EAT_RESISIT_CRIT then
            local value = v / 100
            Utils:ShowAttrLabel(typeLable, k, valLable, "+"..value, true)
        else
            Utils:ShowAttrLabel(typeLable, k, valLable, "+"..v, false)
        end
        valLable:setPositionX(100)
    end
    local lvLabel = attrNode:getChildByName("Level"):getChildByName("Value")
    local str = ""
    if maxLevel == -1 then
        local cfg = JsonConfig.m_equipJueXing.getDefByID(level)
        if cfg ~= nil then
            str = cfg.name
        else
            str = GUITips.RSI_ZQX_QEUIP_CULTIVATE9
        end
    elseif maxLevel == -2 then
        local cfg = JsonConfig.m_equipShenZhu.getDefByID(level)
        if cfg ~= nil then
            str = cfg.name
        else
            str = GUITips.RSI_ZQX_QEUIP_CULTIVATE10
        end
    else
        str = ""..level.."/"..maxLevel
    end
    lvLabel:setString(str)
    --self.m_scrollView:addChild(attrNode)
    attrNode:retain()
    attrNode:removeFromParent()
    self.m_listView:pushBackCustomItem(attrNode)
end

function EquipInfoUI:ShowSuit()
    self.m_suitInfo:setVisible(false)
    if self.m_cfgData == nil or self.m_cfgData.suit == 0 then
        return
    end
    local suitCfg = JsonConfig.m_suitConfig.getDefByID(self.m_suitId)
    if suitCfg == nil then
        return
    end
    local suitList = JsonConfig.m_suitList[self.m_cfgData.suit]
    if suitList == nil then
        return
    end
    local equipSign = self:GetSuitEquipInfo()
    self.m_suitInfo:setVisible(true)
    self.m_suitList:removeAllChildren()
    for i=1,#suitList do
        local equipId = suitList[i]
        local equipCfg = JsonConfig.m_equipConfig.getDefByID(equipId)
        if equipCfg ~= nil then
            local suit = self.m_suitItem:clone()
            local nameLabel = suit:getChildByName("Name")
            nameLabel:setString(equipCfg.name)
            nameLabel:setColor(AppDef:GetQualityColor(equipCfg.quality))
            local item = ItemCellUI:New(suit)
            local itemValue = { isChangeSize =  true,isShowQualityBg = true}
            local petEquipData = {id = equipId}
            itemValue.petEquipData = petEquipData
            item:UpdateItem(itemValue)
            self.m_suitList:addChild(suit)
            if equipSign ~= nil and equipSign[equipId] then
                local size = self.m_suitItem:getContentSize()
                Utils:createAnimEffect( item.m_pUILayer,cc.p(size.width/2,size.height/2),"res2/animation/effect_tuitu_3")
            end
        end
    end
    local suitNum = self:GetSuitNum()
    --print("suitNum",suitNum)
    --属性
    local cnt = 0
    for i=1,#suitCfg.suit do
        local val = suitCfg.suit[i]
        if #val > 0 then
            local typeLable = nil
            if cnt == 0 then
                typeLable = self.m_suitAttrType
                cnt  = 1
            else
                typeLable = self.m_suitAttrType:clone()
                local pos = cc.p(self.m_suitAttrType:getPosition())
                typeLable:setPosition(cc.p(pos.x,pos.y-typeLable:getContentSize().height*(i-1)-2))
                self.m_suitInfo:addChild(typeLable)
            end
            typeLable:setString(string.format(GUITips.RSI_PET_SUIT_TIPS14,i+1))
            local valLable = {}
            local max = math.min(2,#val)
            local sign = false
            if i+1 <= suitNum then
                sign = true
            end
            for k= 1,max do
                valLable[k] = typeLable:getChildByName("Value_"..k)
                local value = val[k] 
                if value ~= nil and #value == 3 then
                    local str = ""
                    if value[1] == 1 then
                        str = Utils:getAttrStr(value[2],value[3])
                    elseif value[1] == 2 then
                        local skillCfg = LDataConstMgr:GetSkillDetailList(value[2]) 
                        if skillCfg ~= nil then
                            str = GUITips.RSI_SKILL.."["..skillCfg.name.."Lv."..value[3].."]"
                        end
                    end
                    valLable[k]:setString(str)  
                    if sign then
                        valLable[k]:setColor(UICOLOR_GREEN)
                    else
                        valLable[k]:setColor(UICOLOR_BROWN)
                    end
                end    
            end
            for k=max+1,2 do
                local label = typeLable:getChildByName("Value_"..k)
                label:setString("")
            end
        end
    end
    --self.m_scrollView:addChild(self.m_suitInfo)
    self.m_suitInfo:retain()
    self.m_suitInfo:removeFromParent()
    self.m_listView:pushBackCustomItem(self.m_suitInfo)

end

--获取套装内的装备穿戴情况
function EquipInfoUI:GetSuitEquipInfo()
    if self.m_suitId == 0 or self.m_uid == 0 or self.m_fpos == 0 then
        return nil
    end
    local value = {}
    if self.m_heroPos == 0 then
        local infos = LRoleDataMgr.Pet.equipList.m_formationEquips[self.m_fpos]
        if info == nil then
            return nil
        end
        
        for k,v in pairs(infos) do
            if v > 0 then
                local info = LRoleDataMgr.Pet.equipList.m_petEquips[v]
                if info ~= nil and info.m_suitType == self.m_suitId then
                    value[info.m_id] = true
                end
            end
        end
    else
        local infos = LRoleDataMgr.OtherHeroInfo.MapEquip[self.m_fpos]
        if info == nil then
            return nil
        end
        for k,v in pairs(infos) do
            local info = v
            if info ~= nil and info.m_suitType == self.m_suitId then
                value[info.m_id] = true
            end
        end
    end
    return value
end

function EquipInfoUI:GetSuitNum()
    if self.m_suitId == 0 then
        return 0
    end
    if self.m_fpos == 0 then
        return 0
    end
    local num = 0
    if self.m_heroPos == 0 then
        local infos = LRoleDataMgr.Pet.equipList.m_formationEquips[self.m_fpos]
        if info == nil then
            return 0
        end
        for k,v in pairs(infos) do
            if v > 0 then
                local info = LRoleDataMgr.Pet.equipList.m_petEquips[v]
                if info ~= nil and info.m_suitType == self.m_suitId then
                    num = num+1
                end
            end
        end
    else
        local infos = LRoleDataMgr.OtherHeroInfo.MapEquip[self.m_fpos]
        if info == nil then
            return 0
        end
        for k,v in pairs(infos) do
            local info = v
            if info ~= nil and info.m_suitType == self.m_suitId then
                num = num+1
            end
        end
    end
    return num
end

function EquipInfoUI:RefreshAffixDescription()
    if self.m_cfgData == nil then
        return
    end
    local desc = self.m_cfgData.des or ""
    if self.m_info ~= nil and (self.m_info.specialAffixId or 0) > 0 then
        local tierName = ({"T1", "T2", "T3"})[self.m_info.specialAffixTier] or "T?"
        local lockText = bit.band(self.m_info.affixLockMask or 0, 1) ~= 0 and "已锁定" or "未锁定"
        local affixText = string.format("[特殊词条·%s·%s] %s\n%s\n推荐：%s", tierName, lockText,
            self.m_info.specialAffixName or "", self.m_info.specialAffixDesc or "",
            GetAffixBuildRecommendation(self.m_info.specialAffixKey))
        desc = (#desc > 0) and (desc .. "\n" .. affixText) or affixText
    end
    self.m_descLabel:setString(desc)
end

function EquipInfoUI:RefreshAffixActions()
    if self.m_affixActionNode == nil or self.m_info == nil then return end
    local visible = self.m_heroPos == 0 and (self.m_info.specialAffixId or 0) > 0
    self.m_affixActionNode:setVisible(visible)
    if not visible then return end
    local locked = bit.band(self.m_info.affixLockMask or 0, 1) ~= 0
    self.m_affixLockBtn:setTitleText(locked and "解锁词条" or "锁定词条")
    local baseCost = self.m_cfgData ~= nil and self.m_cfgData.quality >= 7 and 50000 or 30000
    self.m_affixRerollBtn:setTitleText(string.format("%s %d万", locked and "锁定重铸" or "重铸词条",
        (locked and baseCost * 2 or baseCost) / 10000))
end

function EquipInfoUI:RefreshBuildRecommendation()
    local visible = self.m_info ~= nil and (self.m_info.specialAffixId or 0) > 0
    self.m_buildRecommendationNode:setVisible(visible)
    if not visible then
        self.m_buildRecommendationNode:setContentSize(cc.size(440, 0))
        self.m_listView:forceDoLayout()
        return
    end
    -- Equipment uses display formation slots. Do not use GetPetByFightPos: it
    -- silently returns the first hero for an empty position or stale formation.
    local heroId = 0
    if self.m_heroPos == 0 and self.m_fpos > 0 then
        heroId = (LRoleDataMgr.Pet.ShowPosList or {})[self.m_fpos] or 0
    end
    self.m_buildRecommendationLabel:setString(
        HeroBuildRecommendation.Describe(heroId, self.m_info.specialAffixKey))
    local height = math.max(60, self.m_buildRecommendationLabel:getVirtualRendererSize().height + 20)
    self.m_buildRecommendationNode:setContentSize(cc.size(440, height))
    self.m_buildRecommendationLabel:setPosition(cc.p(15, height - 10))
    self.m_listView:forceDoLayout()
end

function EquipInfoUI:ShowDesc()
    self:RefreshAffixDescription()
    self.m_descNode:retain()
    self.m_descNode:removeFromParent()
    self.m_listView:pushBackCustomItem(self.m_descNode)
    self.m_buildRecommendationNode:retain()
    self.m_buildRecommendationNode:removeFromParent()
    self.m_listView:pushBackCustomItem(self.m_buildRecommendationNode)
    self.m_buildRecommendationNode:release()
    self:RefreshBuildRecommendation()
    self:RefreshAffixActions()
    self.m_affixActionNode:retain()
    self.m_affixActionNode:removeFromParent()
    self.m_listView:pushBackCustomItem(self.m_affixActionNode)
end

function EquipInfoUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "PetEquip.EquipInfoUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function EquipInfoUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Equip_6)
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_id = nil
    self.Script  = nil
end

function EquipInfoUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_Equip_6, self.m_qhBtn ,handler(self,EquipInfoUI.QiangHuaCallBack), nil, true)
end 

function EquipInfoUI:UpdateRedDotUI()
    if self.m_uid == 0 or self.m_id == 0 or self.m_heroPos ~= 0 then
        return
    end

	local isqianghua, isjinglian, isjuexing, isshenzhu = LRedDotCheckMgr:EquipCultivateRedDotCheck(self.m_uid)
	self.m_qhAttr:getChildByName("Btn_qianghua"):getChildByName("Prompt"):setVisible(isqianghua)
	self.m_jlAttr:getChildByName("Btn_jinglian"):getChildByName("Prompt"):setVisible(isjinglian)
	self.m_jxAttr:getChildByName("Btn_juexing"):getChildByName("Prompt"):setVisible(isjuexing)
	self.m_szAttr:getChildByName("Btn_shenzhu"):getChildByName("Prompt"):setVisible(isshenzhu)
	local isShow = LRedDotCheckMgr:EquipChangeRedDotCheck(self.m_info.m_wpos,self.m_uid)
	self.m_huanBtn:getChildByName("Prompt"):setVisible(isShow)
end

return EquipInfoUI

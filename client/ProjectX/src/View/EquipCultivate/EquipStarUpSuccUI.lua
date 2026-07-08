
local EquipStarUpSuccUI = LUIBase:New()
EquipStarUpSuccUI.__index = EquipStarUpSuccUI
--local this = LTcpSocket
function EquipStarUpSuccUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,EquipStarUpSuccUI)	
    o:Init(data)
	return o
end

--注册事件
-- -----------------------------------
function EquipStarUpSuccUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function EquipStarUpSuccUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function EquipStarUpSuccUI:Init(data)
    self:InitMembers()
    self:ShowData(data)
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function EquipStarUpSuccUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/shengxingchenggong.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
	
	self.title = self.m_pUILayer:getChildByName("shengxingchenggong"):getChildByName("Bg"):getChildByName("Title")

    local attrBg = self.m_pUILayer:getChildByName("shengxingchenggong"):getChildByName("jichushuxing")
    local starAttrBg = self.m_pUILayer:getChildByName("shengxingchenggong"):getChildByName("Title")
	self.title_text = starAttrBg:getChildByName("Text")
    self.m_blackBg = self.m_pUILayer:getChildByName("shengxingchenggong")
    self.m_preLevel = attrBg:getChildByName("Level_1")
    self.m_curLevel = attrBg:getChildByName("Level_2")
    self.m_attrInfo = {}
    for i=1,2 do
        local abg = {}
        abg.name = attrBg:getChildByName("Atrribute_"..i)
        abg.preValue = abg.name:getChildByName("Value_1")
        abg.curValue = abg.name:getChildByName("Value_2")
        abg.addValue = abg.name:getChildByName("Value_3")
        abg.name:setVisible(false)
        self.m_attrInfo[i] = abg
    end
    self.m_starAttr1 = self.m_blackBg:getChildByName("shuxing_1")
    self.m_starAttr1=Utils:CreateColorText3(self.m_starAttr1, true)   

    self.m_starAttr2 = self.m_blackBg:getChildByName("shuxing_2")
    self.m_starAttr2=Utils:CreateColorText3(self.m_starAttr2, true)   

    self.m_starAttr2:setVisible(false)
    self.m_btn = starAttrBg:getChildByName("Btn_Close")
end

function EquipStarUpSuccUI:onExit()
    self.m_pUILayer = nil
    self.m_preLevel = nil
    self.m_curLevel = nil
    self.m_attrInfo = nil
    self.m_btn = nil
    self.m_blackBg = nil
    self:Destory()
end

function EquipStarUpSuccUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "EquipCultivate.EquipStarUpSuccUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
end

function EquipStarUpSuccUI:ShowData(data)
	local type = data.type
	if type == 1 then
		--self.title:setString(GUITips.UI_Equip_ChengGong_Title_1.."成功")
		self.title_text:setString(GUITips.UI_Equip_ChengGong_Title_1.."特效")
	elseif type == 2 then
		--self.title:setString(GUITips.UI_Equip_ChengGong_Title_2.."成功")
		self.title_text:setString(GUITips.UI_Equip_ChengGong_Title_2.."特效")
	elseif type == 3 then
		--self.title:setString(GUITips.UI_Equip_ChengGong_Title_3.."成功")
		self.title_text:setString(GUITips.UI_Equip_ChengGong_Title_3.."特效")
	end
	local equipId = data.equipId
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[equipId]
	local ecfg = JsonConfig.m_equipConfig.getDefByID(equip.m_id)
	local curLevel = 0
	local preLevel = 0
	local cjcfg = nil
	local pjcfg = nil
	local attrs_add = {}
	if type == 1 then --觉醒
		curLevel = equip.cultivateLevel[3] or 0
		preLevel = curLevel - 1
		cjcfg = JsonConfig.m_equipJueXing.getDefByID(curLevel)
		pjcfg = JsonConfig.m_equipJueXing.getDefByID(preLevel)
		attrs_add = cjcfg.attr_add
	elseif type == 2 or type == 3 then --神铸
		curLevel = equip.cultivateLevel[4] or 0
		preLevel = curLevel - 1
		cjcfg = JsonConfig.m_equipShenZhu.getDefByID(curLevel)
		pjcfg = JsonConfig.m_equipShenZhu.getDefByID(preLevel)
		local list = JsonConfig.m_equipShenZhu.getList()
		for i = curLevel,#list do
			local cfg = list[i]
			if #cfg.skill_add > 0 then
				attrs_add = cfg.skill_add
				break
			end
		end
	end
    if cjcfg == nil then
        return
    end
    self.m_preLevel:setString(pjcfg.name)
    self.m_curLevel:setString(cjcfg.name)
	local attrs = {}
	if type == 1 then
		attrs = ecfg.attr_juexing
	elseif type == 2 or type == 3 then
		attrs = ecfg.attr_shenzhu
	end 
    for i=1,#attrs do
        local abg = self.m_attrInfo[i]
        if abg ~= nil then
            local attr = attrs[i]
            abg.name:setString(AppDef.EAttrTypeName[attr[1]] .. ": ")
            abg.preValue:setString(tostring(attr[2] * preLevel))
            abg.curValue:setString(tostring(attr[2] * curLevel))
            abg.addValue:setString(tostring(attr[2]))
            abg.name:setVisible(true)
        end
    end
    if #attrs_add ~= 0 then
        local attr = attrs_add[equip.m_wpos]
		if type == 1 then
			self.m_starAttr1:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE12,
				AppDef.EAttrTypeName[attr[2]], attr[3] / 100))
			self.m_starAttr1:setVisible(true)
		elseif type == 2 or type == 3 then
			--local data = LDataConstMgr:GetSkillDetailList(attr[2])
            local temp_Desc =LDataConstMgr:GetHeroSkillDesc(attr[2],curLevel)

			self.m_starAttr1:setString(temp_Desc)
			self.m_starAttr1:setVisible(true)
		end
    else
        self.m_starAttr1:setVisible(false)
    end
end

return EquipStarUpSuccUI
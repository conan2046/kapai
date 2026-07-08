
local ShenZhuTeXiaoUI = LUIBase:New()
ShenZhuTeXiaoUI.__index = ShenZhuTeXiaoUI
--local this = LTcpSocket
function ShenZhuTeXiaoUI:New(equipId)
	local o = LUIBase:New()
	setmetatable(o,ShenZhuTeXiaoUI)	
    o:Init(equipId)
	return o
end

--注册事件
-- -----------------------------------
function ShenZhuTeXiaoUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function ShenZhuTeXiaoUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function ShenZhuTeXiaoUI:Init(equipId)
    self:InitMembers()
    self:ShowData(equipId)
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function ShenZhuTeXiaoUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/shenzhutexiao.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("Popup")
    self.m_item = bg:getChildByName("Item")
    self.m_list = bg:getChildByName("ListView")
    self.m_btn = bg:getChildByName("Btn_close")
end

function ShenZhuTeXiaoUI:onExit()
    self.m_pUILayer = nil
    self.m_item = nil
    self.m_list = nil
    self.m_btn = nil
    self:Destory()
end

function ShenZhuTeXiaoUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "EquipCultivate.ShenZhuTeXiaoUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_btn:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_btn)
end

function ShenZhuTeXiaoUI:ShowData(equipId)
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[equipId]
    local curLevel = equip.cultivateLevel[4] or 0
    local szcfg = JsonConfig.m_equipShenZhu.getList()

    for i=1,#szcfg do
        local skills = szcfg[i].skill_add
        if #skills > 0 then
        	skill = skills[equip.m_wpos]
        	local item = self.m_item:clone()
        	local skCfg = LDataConstMgr:GetSkillDetailList(skill[2])
        	local curDesc = LDataConstMgr:GetHeroSkillDesc(skill[2], skill[3])
        	item:getChildByName("Content"):setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE14,
        		skCfg.name, skill[3], curDesc, szcfg[i].name))
        	if curLevel >= i then
        		item:getChildByName("Content"):setTextColor(AppDef.UIColor.GREEN)
        	end
        	self.m_list:addChild(item)


        end
    end
end

return ShenZhuTeXiaoUI
local ImproveDef = require("View.ImproveUI.ImproveDef")

ImproveUI = LUIBase:New()
ImproveUI.__index = ImproveUI
----------------------------------------------------------------------
function ImproveUI:New()
	local o = LUIBase:New()
	setmetatable(o, self)
	self.__index = self
	o:Init()
	return o
end

function ImproveUI:getInstance()
	if self.instance == nil then
		self.instance = self:New()
	end
	return self.instance
end

----------------------------------------------------------------------
function ImproveUI:Init()
	self:RegistMsgs()
end
----------------------------------------------------------------------
function ImproveUI:onExit()
    self:UnRegistSelf(self, self.msgIds)
    self.m_pUILayer = nil
    self.msgIds = {}
end
----------------------------------------------------------------------
function ImproveUI:RegistMsgs()
	self.msgIds = {
        LUIMainEvent.ShowImproveView,
    }
    self:RegistSelf(self, self.msgIds)
end
----------------------------------------------------------------------
function ImproveUI:ProcessEvent(msg)
	if msg.msgId == LUIMainEvent.ShowImproveView then
        self:LoadImproveDialog(msg.value)
    end
end

function ImproveUI:LoadImproveDialog(pos)
    local levelNum = LRoleDataMgr.MyHeroInfo.level
    local _improveOkInfo = LCheckImproveMgr:getInstance()._ImproveOK
    
    local _isImproveID = {}
    -- _isImproveID[ImproveDef.Type.UP_SKILL]             = _improveOkInfo._UpgradeSkillId >=0
    -- _isImproveID[ImproveDef.Type.UP_Equip]             = _improveOkInfo._UpgradeEquip >= 0
    -- _isImproveID[ImproveDef.Type.UPGRADESKILL_PET]     = _improveOkInfo._UpgradeSkillPet >= 0
    -- _isImproveID[ImproveDef.Type.TRANSFORM_HORSE]      = _improveOkInfo._HorseTransform >= 0
    -- _isImproveID[ImproveDef.Type.STRENGTH_HORSE]       = _improveOkInfo._HorseStrength >= 0
    -- _isImproveID[ImproveDef.Type.UPGRADE_PET]          = _improveOkInfo._UpgradePet >= 0
    _isImproveID[ImproveDef.Type.UPDATE_MEDAL]         = _improveOkInfo._UpdateMedal >= 0
    -- _isImproveID[ImproveDef.Type.FIGHT_PET]            = _improveOkInfo._FightPet >= 0
    -- _isImproveID[ImproveDef.Type.EVOLUTE_PET]          = _improveOkInfo._EvoPet >= 0

    local optionName = {}
    local num = 0
    for i=0,ImproveDef.Type.IMPROVEMAX-1 do
        if (_isImproveID[i]) then
            local cfg = self:getConfigById(i)
            if cfg then
                table.insert(optionName, cfg)
                num = num + 1
            end
        end
    end

    if num > 5 then
        num = 5.1
    end
--调整bntlist位置
    optionName.pos = cc.p(pos.x, pos.y + 72 * num)
    --dump(optionName)
    if (#optionName > 0) then
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, optionName)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function ImproveUI:getConfigById(id)
    if id == ImproveDef.Type.UP_SKILL then
        return {GUITips.RSI_IMPROVE_MSG1, handler(self, ImproveUI.CB_UP_SKILL)}
    elseif id == ImproveDef.Type.UP_Equip then
        return {GUITips.RSI_IMPROVE_MSG3, handler(self, ImproveUI.CB_UP_Equip)}
    elseif id == ImproveDef.Type.STRENGTH_EQUIP then
        return {GUITips.RSI_IMPROVE_MSG5, handler(self, ImproveUI.CB_STRENGTH_EQUIP)}
    elseif id == ImproveDef.Type.COMPON_JINGPO then
        return {GUITips.RSI_IMPROVE_MSG6, handler(self, ImproveUI.CB_COMPON_JINGPO)}
    elseif id == ImproveDef.Type.UPGRADESKILL_PET then
        return {GUITips.RSI_IMPROVE_MSG9, handler(self, ImproveUI.CB_UPGRADESKILL_PET)}
    elseif id == ImproveDef.Type.TRANSFORM_HORSE then
        return {GUITips.RSI_IMPROVE_MSG11, handler(self, ImproveUI.CB_TRANSFORM_HORSE)}
    elseif id == ImproveDef.Type.STRENGTH_HORSE then
        return {GUITips.RSI_IMPROVE_MSG12, handler(self, ImproveUI.CB_STRENGTH_HORSE)}
    elseif id == ImproveDef.Type.UPGRADE_PET then
        return {GUITips.RSI_IMPROVE_MSG13, handler(self, ImproveUI.CB_UPGRADE_PET)}
    elseif id == ImproveDef.Type.UPDATE_MEDAL then
        return {GUITips.RSI_IMPROVE_MSG14, handler(self, ImproveUI.CB_UPDATE_MEDAL)}
    elseif id == ImproveDef.Type.FIGHT_PET then
        return {GUITips.RSI_IMPROVE_MSG15, handler(self, ImproveUI.CB_FIGHT_PET)}
    elseif id == ImproveDef.Type.EVOLUTE_PET then
        return {GUITips.RSI_IMPROVE_MSG16, handler(self, ImproveUI.CB_EVOLUTE_PET)}
    end
    return nil
end
--技能可升级
function ImproveUI:CB_UP_SKILL()
    Utils:OpenFunction(AppDef.EModuleID.EMID_JINENG)
end
--装备可升级
function ImproveUI:CB_UP_Equip()
    Utils:OpenFunction(AppDef.EModuleID.EMID_DZSHENGJIE)
end
--强化
function ImproveUI:CB_STRENGTH_EQUIP()
    Utils:OpenFunction(AppDef.EModuleID.EMID_DZQIANGHUA)
end
--合成
function ImproveUI:CB_COMPON_JINGPO()
    Utils:OpenFunction(AppDef.EModuleID.EMID_HECHENG)
end
--宠物技能升级
function ImproveUI:CB_UPGRADESKILL_PET()
    Utils:OpenFunction(AppDef.EModuleID.EMID_SJJINENG)
end
--坐骑可进阶
function ImproveUI:CB_TRANSFORM_HORSE()
    Utils:OpenFunction(AppDef.EModuleID.EMID_ZJJINJIE)
end
--坐骑可强化
function ImproveUI:CB_STRENGTH_HORSE()
    Utils:OpenFunction(AppDef.EModuleID.EMID_ZJQIANGHUA)
end
--宠物可升级
function ImproveUI:CB_UPGRADE_PET()
    Utils:OpenFunction(AppDef.EModuleID.EMID_SHENJIANG)
end
--称号系统
function ImproveUI:CB_UPDATE_MEDAL()
    Utils:OpenFunction(AppDef.EModuleID.EMID_HERO)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Role.RoleTitleUI", AppDef.UIType.FirstClassLayer)
    self:SendMsg(LGameMsg.m_initUIMsg)
end
--宠物出战
function ImproveUI:CB_FIGHT_PET()
    Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
end
--宠物进化
function ImproveUI:CB_EVOLUTE_PET()
    Utils:OpenFunction(AppDef.EModuleID.EMID_SJXIULIAN)
end

return ImproveUI

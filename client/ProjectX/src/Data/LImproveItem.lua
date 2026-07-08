LImproveItem = {}
LImproveItem.__index = LImproveItem
function LImproveItem:New()
	local o = {}
	setmetatable(o,LImproveItem)	
	o:Init()
	return o
end

function LImproveItem:Init()
	self._UpgradeSkillId = -1
	self._UpgradeEquip = -1
	self._XiangqianEquip = -1
	self._StrengthEquip = -1
	self._WashPet = -1
	self._LearnSkillPet = -1
	self._UpgradeSkillPet = -1
	self._UpgradeKaijiaPet = -1
	self._HorseTransform = -1
	self._HorseStrength = -1
	self._HorseExchange = -1
	self._ComponEquip = -1
	self._UpgradePet = -1
	self._UpdateMedal = -1
	self._FightPet = -1
	self._EvoPet = -1
end

function LImproveItem:Delete()
	self._UpgradeSkillId = nil
	self._UpgradeEquip = nil
	self._XiangqianEquip = nil
	self._StrengthEquip = nil
	self._WashPet = nil
	self._LearnSkillPet = nil
	self._UpgradeSkillPet = nil
	self._UpgradeKaijiaPet = nil
	self._HorseTransform = nil
	self._HorseStrength = nil
	self._HorseExchange = nil
	self._ComponEquip = nil
	self._UpgradePet = nil
	self._UpdateMedal = nil
	self._FightPet = nil
	self._EvoPet = nil
end

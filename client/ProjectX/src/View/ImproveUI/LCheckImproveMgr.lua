local ImproveDef = require("View.ImproveUI.ImproveDef")

LCheckImproveMgr = LUIBase:New()
LCheckImproveMgr.__index = LCheckImproveMgr
----------------------------------------------------------------------
function LCheckImproveMgr:New()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o:Init()
	return o
end

function LCheckImproveMgr:getInstance()
	if self.instance == nil then
		self.instance = self:New()
	end
	return self.instance
end

----------------------------------------------------------------------
function LCheckImproveMgr:Init()
    self._ImproveOK = LImproveItem:New()
    self._isChecking = true
	-- self:RegistMsgs()
end
----------------------------------------------------------------------
function LCheckImproveMgr:onExit()
    self.m_pUILayer = nil
    self._ImproveOK = LImproveItem:New()
    self:Destory()
end
----------------------------------------------------------------------
function LCheckImproveMgr:RegistMsgs()
	self.msgIds = {
        LUILogicEvent.DeleteUI,
        LUIMainEvent.CheckImproveBtn,
        LUIMainEvent.CheckImproveMedal,
        LUIMapEvent.ChangeMapSuccess,
        -- LUIRoleDataChangeEvent.LvUp,
        LUIRoleDataChangeEvent.MoneyChanged,
    }
    self:RegistSelf(self, self.msgIds)
end
----------------------------------------------------------------------
function LCheckImproveMgr:ProcessEvent(msg)
    if msg.msgId == LUILogicEvent.DeleteUI then
        self:checkUpdate(msg.m_pScript)
    elseif msg.msgId == LUIMainEvent.CheckImproveBtn then
        self:CheckImproveItemByIdx(msg.value)
    elseif msg.msgId == LUIMainEvent.CheckImproveMedal then
        if msg.value[1] then
            self:UpdateMedal()
        else
            self:RemoveMedal(msg.value[2])
        end
    elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
        -- performWithDelay(cc.Director:getInstance():getRunningScene(), function(sender)
        --     self:CheckAllImproveItem()
        -- end, 1)
    -- elseif msg.msgId == LUIRoleDataChangeEvent.LvUp then
    --     self:CheckImproveItemByIdx(ImproveDef.Type.UP_SKILL)
    --     self:CheckImproveItemByIdx(ImproveDef.Type.UPGRADE_PET)
    --     self:CheckImproveItemByIdx(ImproveDef.Type.FIGHT_PET)
    --     self:CheckImproveItemByIdx(ImproveDef.Type.EVOLUTE_PET)
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        self:CheckImproveItemByIdx(ImproveDef.Type.UP_SKILL)
        self:CheckImproveItemByIdx(ImproveDef.Type.TRANSFORM_HORSE)
    elseif msg.msgId == LUIRoleDataChangeEvent.PotentialChanged then
        self:CheckImproveItemByIdx(ImproveDef.Type.UP_SKILL)
    end
end
------------------------------------------------
function LCheckImproveMgr:check(...)
    local function isnot_1(values)
        for k,v in pairs(values) do
            if v ~= -1 then
                return true
            end
        end
        return false
    end
    local tb = {
        -- self._ImproveOK._UpgradeSkillId,
        -- self._ImproveOK._UpgradeEquip,
        -- self._ImproveOK._XiangqianEquip,
        -- self._ImproveOK._LearnSkillPet,
        -- self._ImproveOK._UpgradeSkillPet,
        -- self._ImproveOK._UpgradeKaijiaPet,
        -- self._ImproveOK._HorseTransform,
        -- self._ImproveOK._HorseStrength,
        -- self._ImproveOK._UpgradePet,
        -- self._ImproveOK._FightPet,
        -- self._ImproveOK._EvoPet,
    }
    local temp = {...}
    for i,v in ipairs(temp) do
        table.insert(tb, temp[i])
    end
    return isnot_1(tb)
end
------------------------------------------------
function LCheckImproveMgr:CheckAllImproveItem()
    if (not self._isChecking) then
        return
    end
    self._isChecking = false

    self:UpgradeHeroSkill()
    self:StrengthEquip()
    self:UpgradePetSkill()
    self:TransformHorse()
    self:StrengthHorse()
    self:UpgradePet()
    self:EnfightPet()
    self:EvolutePet()

    if(self:check()) then
        self:ShowImproveMenu()
    else
        self:HideImproveMenu()
    end
end
------------------------------------------------
function LCheckImproveMgr:CheckImproveItemByIdx(idx)
    if idx == ImproveDef.Type.UP_SKILL then
        self:UpgradeHeroSkill()
    elseif idx == ImproveDef.Type.UP_Equip then
        self:UpgradeEquip()
    elseif idx == ImproveDef.Type.STRENGTH_EQUIP then
        self:StrengthEquip()
    elseif idx == ImproveDef.Type.UPGRADESKILL_PET then
        self:UpgradePetSkill()
    elseif idx == ImproveDef.Type.TRANSFORM_HORSE then
        self:TransformHorse()
    elseif idx == ImproveDef.Type.STRENGTH_HORSE then
        self:StrengthHorse()
    elseif idx == ImproveDef.Type.UPGRADE_PET then
        self:UpgradePet()
    elseif idx == ImproveDef.Type.FIGHT_PET then
        self:EnfightPet()
    elseif idx == ImproveDef.Type.EVOLUTE_PET then
        self:EvolutePet()
    end

    if(self:check(self._ImproveOK._UpdateMedal)) then
        self:ShowImproveMenu()
    else
        self:HideImproveMenu()
    end
end

------------------------------------------------
function LCheckImproveMgr:ShowImproveMenu()
    self._isChecking = true
    LGameMsg.m_baseMsgWithOne:Change(LUIMainEvent.ShowImproveBtn, true)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function LCheckImproveMgr:HideImproveMenu()
    self._isChecking = true
    LGameMsg.m_baseMsgWithOne:Change(LUIMainEvent.ShowImproveBtn, false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
------------------------------------------------
function LCheckImproveMgr:ShowImproveItemList()
    LGameMsg.m_baseMsgWithOne:Change(LUIMainEvent.ShowImproveView)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

----------------------角色技能相关--------------------------
function LCheckImproveMgr:UpgradeHeroSkill()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_JINENG, true) then
        return
    end
    self._ImproveOK._UpgradeSkillId  = -1

    local pSkill,skillNum = LSkillMgr:GetSkillInfo(LRoleDataMgr.MyHeroInfo.professional)
    skillNum = skillNum or 0
    for i=1,skillNum do--已学习，看是否能升级
        local id = pSkill[i][1]
        local skillCell = LRoleDataMgr:GetSkillDetailById(id)
        if skillCell then
            if Utils:CheckSkillLevelUp(i, skillCell.level, true) then
                self._ImproveOK._UpgradeSkillId = self._ImproveOK._UpgradeSkillId + 1
            end
        end
    end
end
------------------------角色称号相关------------------------
function LCheckImproveMgr:UpdateMedal()--对新加的称号进行判断
    self._ImproveOK._UpdateMedal = -1

    local medal_info = LRoleDataMgr.MedalList
    if(#medal_info <= 0) then
        return
    end

    --判断条件修改为 获得的称号数量大于已佩戴的数量,且佩戴的数量小于5
    local wearNum = 0
    for i=1,#medal_info do
        if (medal_info[i].ware == 1) then
            wearNum = wearNum + 1
        end
    end
    if( #medal_info > wearNum and wearNum <= 4) then
        self._ImproveOK._UpdateMedal = 1
    else--已显示
        self._ImproveOK._UpdateMedal = -1
    end
    self:CheckImproveItemByIdx(ImproveDef.Type.UPDATE_MEDAL)
end

function LCheckImproveMgr:RemoveMedal(idx)
    local medal_info = LRoleDataMgr.MedalList
    if(idx > #medal_info)then
        return
    end

    if(medal_info[idx].id == self._ImproveOK._UpdateMedal) then--移除称号操作
        self._ImproveOK._UpdateMedal = -1
    end

    self:CheckImproveItemByIdx(ImproveDef.Type.UPDATE_MEDAL)
end
-----------------------角色装备相关-------------------------
function LCheckImproveMgr:UpgradeEquip()
     print("LCheckImproveMgr:UpgradeEquip是否执行")
    -- if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DZSHENGJIE, true) then
    --     return
    -- end
    -- self._ImproveOK._UpgradeEquip = -1

    -- local hdata = LRoleDataMgr.MyHeroInfo

    -- local function getItemforUpgrade(idx, pItem)
    --     if pItem == nil or pItem.m_quality >= 8 then
    --         return -1
    --     end
    --     local m_Material = {}
    --     m_Material.tarItemId = 0
    --     m_Material = LDataConstMgr:GetEquipUpgradeData(pItem.m_item.m_pos,pItem.m_item.m_level)
    --     if m_Material == nil then
    --         Utils:Debug(pItem, pItem.m_item)
    --         return -1
    --     end
    --     local material_num = LRoleDataMgr.Equip:CountItemNumById(m_Material.m_itemId)
    --     if LRoleDataMgr.MyHeroInfo.DetailData:getMoney() < m_Material.m_moneyValue then
    --          return -1
    --     end
    --     if material_num >= m_Material.m_itemNum then
    --         return idx
    --     end
    --     local data= Utils:AutoMaticPropSynthesis(m_Material.m_itemId,m_Material.m_itemNum-material_num)
    --     if  data.isTrue then
    --       return idx
    --     end
    --     return -1
    -- end

    -- local pItem = nil
    -- --检查装备
    -- for k=1,LRoleData.MAX_EQUIP_NUM do
    --     local itemId = hdata.EquipList[k].m_id
    --     if itemId ~= 0 and (not hdata.EquipList[k].m_locked) then
    --         local p = LItemMgr:getItem(itemId+1) --下一阶物品
    --         if (p and p.m_level <= hdata.level) then
    --            pItem = hdata.EquipList[k]
    --             if(pItem and pItem.m_id ~= 0) then
    --                 self._ImproveOK._UpgradeEquip = getItemforUpgrade(k, pItem)
    --                 if(self._ImproveOK._UpgradeEquip ~= -1) then
    --                     return 
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- --检查背包
    -- for k,v in pairs(LRoleDataMgr.Equip.PackageMap) do
    --     if(v.m_id ~= 0 and v.m_item ~= nil and v:IsEquip() and (not v.m_locked)) then
    --         local p = LItemMgr:getItem(v.m_item.m_id + 1)
    --         if(p and p.m_level > hdata.level) then
    --             if v and v.m_id ~= 0 then
    --                 self._ImproveOK._UpgradeEquip = getItemforUpgrade(k, v)
    --                 if(self._ImproveOK._UpgradeEquip ~= -1) then
    --                     break
    --                 end
    --             end
    --         end
    --     end
    -- end
end
function LCheckImproveMgr:StrengthEquip()
    print("LCheckImproveMgr:StrengthEquip是否执行")
    -- if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DZQIANGHUA, true) then
    --     return
    -- end
    -- self._ImproveOK._StrengthEquip = -1
    -- local herodata = LRoleDataMgr.MyHeroInfo

    -- local function checkQianghua(idx, stoneId, packageMap)
    --     local num = 0
    --     for k,v in pairs(packageMap) do
    --         if v and v:getID() == stoneId then
    --             num = num + v.m_num--坐骑强化时自己材料数目
    --         end
    --     end

    --     if (num > 0) then
    --         return idx
    --     else
    --         return -1
    --     end
    -- end

    -- local packageMap = LRoleDataMgr.Equip.PackageMap
    -- for k=1,LRoleData.MAX_EQUIP_NUM do
    --     local pItem = herodata.EquipList[k]
    --     if(pItem.m_id ~= 0 and (not pItem.m_locked) and pItem.m_qhLevel < 15) then
    --         if pItem and pItem.m_id > 0 and pItem.m_qhLevel < 15 then
    --             self._ImproveOK._StrengthEquip = checkQianghua(k, 610, packageMap)
    --             if(self._ImproveOK._StrengthEquip ~= -1) then
    --                 return
    --             end
    --         end
    --     end
    -- end
end
-----------------------宠物相关-------------------------
function LCheckImproveMgr:canUpgreadOfPet( ... )
    local petlist = LRoleDataMgr.Pet.petlist
    for k=1,#petlist do     
        local level = petlist[k].level
        if level<LRoleDataMgr.MyHeroInfo.level then
          for i = 1, AppDef.Pet.MaxUpgradeItems do
            local itemNum = LRoleDataMgr.Equip:CountItemNumById(AppDef.Pet.UpgradsMats[i])
            if itemNum>0 then
                 print("可升级")
            end
          end
        end      
    end
end


function LCheckImproveMgr:canPetBookSkillUpLevel(itemId, itemNum)
    local allSkillList = LDataConstMgr:GetPetBookSkillList()--所有可以学习的技能id数组

    if itemId == nil and itemNum == nil then
        for i = 1, #allSkillList do
            local consumeItemData = allSkillList[i]
            local _itemId = consumeItemData.itemId
            local _itemNum = LRoleDataMgr.Equip:CountItemNumById(_itemId)
            if _itemNum > 0 then
                return true
            end
        end
    else
        local _itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
        return _itemNum >= itemNum
    end
    return false
end

--宠物天赋技能可升级
function LCheckImproveMgr:UpgradePetTFSkill()
    local petlist = LRoleDataMgr.Pet.petlist
    local potential = LRoleDataMgr.MyHeroInfo:GetDetailData().potential
    local money = LRoleDataMgr.MyHeroInfo.DetailData.Money

    for k=1,#petlist do
        if petlist[k]:IsFight() then
            local pSkillList = petlist[k].skills
            local level = petlist[k].level
            -- dump(pSkillList)
            for i=1,AppDef.Pet.MaxBornSkillNum do
                local skill = pSkillList[i]
                if skill and skill.skDetail and skill.level > 0 then
                    -- print('skill.level', skill.level)
                    -- print('level', level)
                    local cfg = LDataConstMgr:GetPetBornSKLvUpData(i, skill.level)
                    if cfg then --未到最大等级
                        if level >= cfg.needLv and money >= cfg.costItemNum[1] then
                            self._ImproveOK._UpgradeSkillPet = 1
                            return
                        end
                    end
                end
            end
        end
    end
end

--宠物天书技能可升级
function LCheckImproveMgr:UpgradePetSkill()
    ---------------------------------------
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJJINENG, true) then
        return
    end
    self._ImproveOK._UpgradeSkillPet = -1
    ---------------------------------------
    self:UpgradePetTFSkill()
    ---------------------------------------
    if self._ImproveOK._UpgradeSkillPet >= 0 then
        return
    end
    ---------------------------------------
    local function canPetSkillOpened(ind, petStar)
        ind = ind - AppDef.Pet.MaxBornSkillNum
        return petStar >= AppDef.Pet.LearnOpenStar[ind]
    end

    local petlist = LRoleDataMgr.Pet.petlist

    for k=1,#petlist do
        if petlist[k]:IsFight() then
            local pSkillList = petlist[k].skills
            -- dump(pSkillList)
            local star = petlist[k].star
            for m=AppDef.Pet.MaxBornSkillNum+1,AppDef.Pet.MaxSkillNum do
                if pSkillList[m].skDetail == nil and canPetSkillOpened(m, star) then
                    if self:canPetBookSkillUpLevel() then -- 有宠物天书
                        self._ImproveOK._UpgradeSkillPet = m
                        return
                    end
                end

                if(pSkillList[m].skDetail) then
                    local skillLevel = pSkillList[m].level
                    local cfg = LDataConstMgr:GetPetLearnSkillLvUpData(pSkillList[m].skDetail.id, skillLevel)
                    if cfg then -- 可升级
                        -- dump(cfg)
                        if self:canPetBookSkillUpLevel(cfg.itemId, cfg.itemNum) then -- 有宠物天书
                            self._ImproveOK._UpgradeSkillPet = m
                            return
                        end
                    end
                end
            end
        end
    end
    self._ImproveOK._UpgradeSkillPet = -1
end
--------------------------境界相关-------------------------

function LCheckImproveMgr:JingJieBreak()

  self._ImproveOK.JingJie = -1
  local  info=LRoleDataMgr.MyHeroInfo.jingJieOtherInfo
  local JingJieData=LDataConstMgr:GetJingjieInfoById(info.curId)
  if JingJieData==nil then
    return 
  end
  local itemId =JingJieData.upgrade[1].uptype
  local itemNum =JingJieData.upgrade[1].upnum
  local num = #LDataConstMgr:GetJingjieConfifArr() 
  if LRoleDataMgr.Equip:CountItemNumById(itemId) >= itemNum and info.curId <num then
    
        self._ImproveOK.JingJie = 1
          return
  end
  
end
function LCheckImproveMgr:JingJieSalary()
    self._ImproveOK.JingJie = -1
    if  LRoleDataMgr.MyHeroInfo.jingJieOtherInfo.salary==0 then
      self._ImproveOK.JingJie = 1
      return
    end
end

-----------------------------------------------------------
-------------------------角色坐骑相关-----------------------
--坐骑进阶
function LCheckImproveMgr:TransformHorse()
  
    ---------------------------------------
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZJJINJIE, true) then
        return
    end
    self._ImproveOK._HorseTransform = -1

    local myHorse = LRoleDataMgr.MyHeroInfo.Horse
    -- dump(myHorse)
    if #myHorse == 0 then
        return
    end
     
    for i=#myHorse,1,-1 do
        local pHorseData = myHorse[i]
        if pHorseData and pHorseData.id > 0 then
            local horseData = LDataConstMgr:GetHorseConfigData(pHorseData.id)
            if horseData and horseData.isGet == true and horseData.jinjieId > 0 then
                local pJinJieData = LDataConstMgr:GetHorseConfigData(horseData.jinjieId)
                if pJinJieData.isGet == false then
                    local advMoney = horseData:GetJinjieMoney()
                    -- print('advMoney-->', advMoney)
                    if advMoney and LRoleDataMgr.MyHeroInfo.DetailData:getMoney() < advMoney then
                        return
                    end
           
                    local itemId,itemNum = horseData:GetJinjieItem()
                    -- print('itemId,itemNum-->', itemId, itemNum)

                    if LRoleDataMgr.Equip:CountItemNumById(itemId) < itemNum then
                        return
                    end

                    -- dump("---------------------------------------------")
                    self._ImproveOK._HorseTransform = 1
                    return
                end
            end
        end
    end
end
--坐骑强化
function LCheckImproveMgr:StrengthHorse()
    ---------------------------------------
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZJQIANGHUA, true) then
        return
    end
    self._ImproveOK._HorseStrength = -1

    local myHorse = LRoleDataMgr.MyHeroInfo.horseExInfo

    if(myHorse.qhLevel <0 or myHorse.qhLevel >= AppDef.Mount.MaxEnforceLv) then  --强化最高级
        return
    end

    local pack = LRoleDataMgr.Equip.PackageMap
    local num = 0

    for k,v in pairs(pack) do
        local pid = v:getID()
        if LItemMgr:IsHorseStrengthStone(pid) then
            num = num + v.m_num--坐骑强化时自己材料数目
            break
        end
    end

    if num > 0 then--可以强化
        self._ImproveOK._HorseStrength = 1
    end
end

--坐骑可激活
function LCheckImproveMgr:ExchangeHorse()
    ---------------------------------------
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZUOJI, true) then
        return
    end
    self._ImproveOK._HorseExchange = -1

    local myHorse = LRoleDataMgr.MyHeroInfo.horseExInfo

    local horseList = LDataConstMgr:GetHorseConfigArr()
    for i=1,#horseList do
        local horsedata = horseList[i]
        if horsedata.getWayType == 2 and not horsedata.isGet and horsedata.getWayItem > 0 then
            local curNum = LRoleDataMgr.Equip:CountItemNumById(horsedata.getWayItem)
            if curNum >=  horsedata.getWayNum then
                self._ImproveOK._HorseExchange  = 1
                return 
            end
        end
    end
end
-------------------------神将可升级相关-----------------------
function LCheckImproveMgr:UpgradePet()
    self._ImproveOK._UpgradePet = -1
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHENJIANG, true) then
        return
    end

    local haveGradeDan = 0
    for k,v in pairs(LRoleDataMgr.Equip.PackageMap) do
        if v and v.m_id >= 834 and v.m_id <= 837 then
            haveGradeDan = haveGradeDan + v.m_num
        end
    end

    local PetList = LRoleDataMgr.Pet.petlist
    for i=1,#PetList do --宠物出战且等级<人物等级
        local tmpPetData = PetList[i]
        if (tmpPetData:IsFight() and (tmpPetData.level < LRoleDataMgr.MyHeroInfo.level)) then
            --丹的数量>提升需要的数量
            if(haveGradeDan >= LDataConstMgr:GetPetLevelUpPill(tmpPetData.level)) then
                self._ImproveOK._UpgradePet = i
                break
            end
        end
    end
end
--------------------------角色宠物出战相关----------------------
function LCheckImproveMgr:EnfightPet()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHENJIANG, true) then
        return
    end
    self._ImproveOK._FightPet = -1
    local heroData = LRoleDataMgr.MyHeroInfo
    local MaxFightNum = LPetDataMgr:GetMaxFightPetNum(heroData.level)--可出战数量
    -- print('MaxFightNum', MaxFightNum)
    local petList = LRoleDataMgr.Pet.petlist
    
    local DidFightNum,TotalNum = 0,#petList--当前已出战宠物数量/所有可出战宠数量
    for i=1,#petList do
        if(petList[i]:IsFight()) then
            DidFightNum = DidFightNum + 1
        end
    end
    -- print('DidFightNum', DidFightNum, TotalNum)
    if(DidFightNum < MaxFightNum and DidFightNum < TotalNum) then
        self._ImproveOK._FightPet = 1
    end
end
--------------------------角色宠物进化相关(暂无)----------------------
function LCheckImproveMgr:EvolutePet()
    self._ImproveOK._EvoPet = -1
    if true then
        return
    end
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJXIULIAN, true) then
        return
    end

    local PetList = LRoleDataMgr.Pet.petlist
    for i=1,#PetList do --宠物出战且等级<人物等级
        local petData = PetList[i]
        local basePetData = petData.baseData
        -- dump(tmpPetData)
        for j=1,#petData.xiulianLv do
            local xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, petData.xiulianLv[j])
            -- dump(xiulianData)
            if xiulianData and xiulianData.needItemIdList and xiulianData.needItemNumList and #xiulianData.needItemIdList == #xiulianData.needItemNumList then
                for i=1,#xiulianData.needItemIdList do
                    local needItemId = xiulianData.needItemIdList[i]
                    local needItemNum = xiulianData.needItemNumList[i]
                    if LRoleDataMgr.Equip:CountItemNumById(needItemId) < needItemNum then
                        return
                    end
                end
            end
        end
    end
    self._ImproveOK._EvoPet = 1
end
------------------------------------------------
function LCheckImproveMgr:checkUpdate(script)
    local index = string.find(script, "%.")
    if index == nil then
        return
    end
    local uiName = string.sub(script, index + 1)
    if uiName == 'ForgeMainUI' then
        self:CheckImproveItemByIdx(ImproveDef.Type.UP_Equip)
        self:CheckImproveItemByIdx(ImproveDef.Type.STRENGTH_EQUIP)
    elseif uiName == 'MountMainUI' then
        self:CheckImproveItemByIdx(ImproveDef.Type.TRANSFORM_HORSE)
        self:CheckImproveItemByIdx(ImproveDef.Type.STRENGTH_HORSE)
    elseif uiName == 'PetMainUI' then
        self:CheckImproveItemByIdx(ImproveDef.Type.UPGRADESKILL_PET)
        self:CheckImproveItemByIdx(ImproveDef.Type.UPGRADE_PET)
        self:CheckImproveItemByIdx(ImproveDef.Type.FIGHT_PET)
        self:CheckImproveItemByIdx(ImproveDef.Type.EVOLUTE_PET)
    elseif uiName == 'RoleBagUI' then
        self:UpdateMedal()
        self:CheckImproveItemByIdx(ImproveDef.Type.UP_SKILL)
    elseif uiName == 'RoleMainUI' then
        self:UpdateMedal()
        self:CheckImproveItemByIdx(ImproveDef.Type.UP_SKILL)
    elseif uiName == 'SkillUI' then
        self:CheckImproveItemByIdx(ImproveDef.Type.UP_SKILL)
    end
end

return LCheckImproveMgr

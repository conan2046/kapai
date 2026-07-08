--[[
属性对应的名字和战斗力换算表
]]
LAttrConfig = {}
LAttrConfig.__index = LAttrConfig
function LAttrConfig:New()
    local o = {}
    setmetatable(o,LAttrConfig)    
    o:ctor()
    return o
end

function LAttrConfig:ctor()
    self.attrType = 0--属性值
    self.attrName = 0--属性名称
    self.powerRatio = 0--属性战斗力换算比率
end

--[[
玩家部分信息保存在lua
]]
LAdditionInfo = {}
LAdditionInfo.__index = LAdditionInfo
function LAdditionInfo:New()
    local o = {}
    setmetatable(o,LAdditionInfo)    
    o:ctor()
    return o
end

function LAdditionInfo:ctor()
    self.id = 0

    self.addHp = 0
    self.addHurt = 0
    self.addRecovery = 0
    self.zhandouli = 0
    self.addSpeed = 0  --速度
    self.name = "" 
    --神器新加一些 ：速，全系精通，全系抗性，暴击强化，韧性强化
    self.addQxjt = 0 --全系精通
    self.addQxkx = 0 --全系抗性
    self.addBjqh = 0 --暴击强化
    self.addRxqh = 0 --韧性强化

    --宠物相关 
    self.addPetHp = 0
    self.addPetHurt = 0
    self.addPetRecovery = 0
    self.addPetSpeed = 0
end

function LAdditionInfo:Reset()
    self.id = 0

    self.addHp = 0
    self.addHurt = 0
    self.addRecovery = 0
    self.zhandouli = 0
    self.addSpeed = 0  --速度
    self.name = "" 
    --神器新加一些 ：速，全系精通，全系抗性，暴击强化，韧性强化
    self.addQxjt = 0 --全系精通
    self.addQxkx = 0 --全系抗性
    self.addBjqh = 0 --暴击强化
    self.addRxqh = 0 --韧性强化

    --宠物相关 
    self.addPetHp = 0
    self.addPetHurt = 0
    self.addPetRecovery = 0
    self.addPetSpeed = 0
end

function LAdditionInfo:Delete()
    self.id = nil

    self.addHp = nil
    self.addHurt = nil
    self.addRecovery = nil
    self.zhandouli = nil
    self.addSpeed = nil  --速度
    self.name = nil 
    --神器新加一些 ：速，全系精通，全系抗性，暴击强化，韧性强化
    self.addQxjt = nil --全系精通
    self.addQxkx = nil --全系抗性
    self.addBjqh = nil --暴击强化
    self.addRxqh = nil --韧性强化

    --宠物相关 
    self.addPetHp = nil
    self.addPetHurt = nil
    self.addPetRecovery = nil
    self.addPetSpeed = nil
end

function LAdditionInfo:Getid() return self.id end
function LAdditionInfo:GetaddHp() return self.addHp end
function LAdditionInfo:GetaddHurt() return self.addHurt end
function LAdditionInfo:GetaddRecovery() return self.addRecovery end
function LAdditionInfo:Getzhandouli() return self.zhandouli end
function LAdditionInfo:Getname() return self.name end
function LAdditionInfo:GetaddSpeed() return self.addSpeed end
function LAdditionInfo:GetaddPetHp() return self.addPetHp end
function LAdditionInfo:GetaddPetHurt() return self.addPetHurt end
function LAdditionInfo:GetaddPetRecovery() return self.addPetRecovery end
function LAdditionInfo:GetaddPetSpeed() return self.addPetSpeed end

function LAdditionInfo:Setid(value) self.id = value end
function LAdditionInfo:SetaddHp(value) self.addHp = value end
function LAdditionInfo:SetaddHurt(value) self.addHurt = value end
function LAdditionInfo:SetaddRecovery(value) self.addRecovery = value end
function LAdditionInfo:Setzhandouli(value) self.zhandouli = value end
function LAdditionInfo:Setname(value) self.name = value end
function LAdditionInfo:SetaddSpeed(value) self.addSpeed = value end
function LAdditionInfo:SetaddPetHp(value) self.addPetHp = value end
function LAdditionInfo:SetaddPetHurt(value) self.addPetHurt = value end
function LAdditionInfo:SetaddPetRecovery(value) self.addPetRecovery = value end
function LAdditionInfo:SetaddPetSpeed(value) self.addPetSpeed = value end

--[[
玩家身上的buff结构
]]
-- LRoleBufInfo = {}
-- LRoleBufInfo.__index = LRoleBufInfo
-- function LRoleBufInfo:New()
-- 	local o = {}
-- 	setmetatable(o,LRoleBufInfo)	
-- 	o:ctor()
-- 	return o
-- end

-- function LRoleBufInfo:ctor()
-- 	self.m_byType = 0--buff类型
--     self.m_iStartTime = 0--开始时间
--     self.m_iLastTime = 0--持续持剑
-- end

-- function LRoleBufInfo:Delete()
-- 	self.m_byType = nil
--     self.m_iStartTime = nil
--     self.m_iLastTime = nil
-- end



LRoleData = LUIBase:New()
LRoleData.__index = LRoleData
LRoleData.MAX_EQUIP_NUM = 8

function LRoleData:New()
	local o = LUIBase:New()
	setmetatable(o,LRoleData)	
	o:Awake()
	return o
end

function LRoleData:Awake()
	-- self.msgIds = 
	-- {
	-- 	--LDataRoleEvent.InitRoleData,
 --        LDataRoleEvent.InitRoleNode,
	-- }
	-- self:RegistSelf(self,self.msgIds)

	self:InitRoleData()
end

function LRoleData:Reset()
    self.node = nil--显示节点
    self.id = 0--人物id
    self.roleType = 0-- 0:玩家  1：机器人
    self.name = ""
    --self.attackType = 0--攻击类型
    
    self.head = 0 --头像
    self.model = 0 --模型
    self.vipLevel = 0
    self.face = 0--朝向
    self.sex = 0--性别
    self.professional = 0--职业
    self.mid = 0--场景资源ID
    self.sid = 0--场景ID
    self.level = 0--等级
    --self.yaoLingLv = 0--妖灵等级
    self.posx = 0--坐标
    self.posy = 0
    self.FactionId = 0--帮派
    self.FactionName = ""--帮派名字
    self.FactionRankType = 0--帮派职务
    self.showFactionName = 0--是否显示帮派名字
    self.showMasterName = 0--显示师父名字
    self.masterName = ""--师父名字
    self.coupleShow = ""--是否显示夫妻名字
    self.coupleName = ""--夫妻名字
    self.jingjieName = ""--境界名字
    self.jingjieQuality = 0--境界品质
    self.jingjieIsshow = 0--境界显示
    self.zhanDouLi = 0--人物战斗力
    self.zhanDouLiInAll = 0--总战斗力
    --self.HolyBeastZdl = 0--灵兽战斗力
    self.state = 0--状态(0x01-战斗 0x04-红名强杀 0x08-帮派偷窃 0x10-帮派魔火0x20飞仙状态)
    self.huoDongState = 0--在活动中正在做活动中:1钓鱼
    self.LightEffect = 0--光效
    -- self.IsFirstCharge = {}--每个档位是否首充双倍(1可首充，0首充过了)
    self.m_PayPricelist = {} -- 所有充值档位 IsFirstCharge 移到这里面来
    
    --护送任务相关
    self.ConvoyType = 0--0无 1护送 2押镖
    self.IsAutoYunShou = false--是否为自动护送神兽
    self.IsAutoConvoy = false--是否为自动运镖
    self.IsIntendCancel = false--主动取消运镖
    self.IsTakingTask = false--是否正在接任务
    self.AutoConvoyQuality = 0--自动换车上限品质（该品质以下自动换）1白2绿3蓝4紫5橙
    self.ConvoyInfo = ""--运镖是弹出信息
    self.ConvoySid = 0--运镖目的地sid
    self.ConvoyPos = cc.p(0,0)--运镖目的地pos
    self.ConvoyNPC = 0--运镖目的NPC
    self.m_Convoy:Reset()--护送详细信息

    --self.LockPassword = ""--安全锁
    --self.m_FengHuangChangeState = 0--未知
    self.isCompleteNewRoleTask = 0--是否完成新手任务
    self.packageOpenNum = 0
    self.nextOpenPackageTime = 0
    self.isInitHorseList = true--是否初始化坐骑列表
    self.Horse = {}--坐骑信息(LHorseData)
    self.JingJie={}--境界信息(LJingjieData)
    self.isKuFuTaskAutoPath=false--
    --self.m_ServerHorseList = {}      --服务器下发的所有坐骑信息(LServerHorseList)
    self.HorseTotalPower=0
    self.horseExInfo:Reset()--坐骑其他信息
    self.DetailData:Reset()                     --详细属性

    for i = 1,LRoleData.MAX_EQUIP_NUM do
        self.EquipList[i].m_id = 0
    end
    self.VecFightPet = {}--出战宠物LPetData
    self.m_PetIdx = 0
    self.VecZhuZhanPet = {}                  --助战宠物pos
    self.MedalAddition:Reset() --称号附加信息
    self.ShenQiAddition:Reset()--神器附加信息
    self.MedalId = 0                        --当前佩戴的称号
    self.ShenQiId = 0                       --当前佩戴的神器
    --ark_hero*           HeroNode
    --附近玩家相关
    self.FollowPet = 0
    self.RideId = 0
    self.FollowPetQty = 0
    self.FollowPetName = ""
    self.TeamId = 0                        --ID
    self.TeamType = 0                      --队伍类型：0任意目标1野外挂机2捉鬼任务3其他0xff没有发布
    self.isAFK = false                          --

    self.WingsId = 0                        --翅膀id
    self.MyChiBangVec = {}--角色拥有的翅膀信息LChiBangData
    self.ChiBangExInfo:Reset()
    self.RingInfo = {0}--婚戒信息 第一个数据为是否有婚戒                
    self.serzoneid = 0                      --跨服战游戏服大区id
    self.serenterid = 0                     --跨服战服务器列表入口id
    self.ShapeId = 0                        --变形宠物Id

    --婚礼信息
    self.marrriageType = 0

    self.marriageLeaderId = 0

    self.marriageFlowId = 0

    self.create_time = 0
    self.serverId = 0
    self.meili = 0
    --self.footId = 0
    
    self.shapeIdState = 0--0显示 1隐藏

    self.MyPowerUpdate = 0

	self.equip_fenjie_tips = true
    self.SceneType = 0              --场景类型
    self.IsSpaicialScene = false        --是否为特殊场景

    self.m_pTeam:Reset()
    self.MyVIPInfo:Reset()
    self.m_pLoginGift:Reset()
    self.m_pLevelWard = {}
    self.ShenQi:Reset()
    self.m_pLingqi:Reset()
    self.m_pQuestion = {} -- 答题信息
    self.m_pRechargetGift:Reset()
    --self.YouLi:Reset()
end

function LRoleData:InitRoleData()
    self.node = nil--显示节点
    self.id = 0--人物id
    self.roleType = 0-- 0:玩家  1：机器人
    self.name = ""
    self.attackType = 0--攻击类型
    
    self.head = 0 --头像
    self.vipLevel = 0
    self.face = 0--朝向
    self.sex = 0--性别
    self.professional = 0--职业
    self.mid = 0--场景资源ID
    self.sid = 0--场景ID
    self.level = 0--等级
    --self.yaoLingLv = 0--妖灵等级
    self.posx = 0--坐标
    self.posy = 0
    self.FactionId = 0--帮派
    self.FactionName = ""--帮派名字
    self.FactionRankType = 0--帮派职务
    self.showFactionName = 0--是否显示帮派名字
    self.showMasterName = 0--显示师父名字
    self.masterName = ""--师父名字
    self.coupleShow = ""--是否显示夫妻名字
    self.coupleName = ""--夫妻名字
    self.jingjieName = ""--境界名字
    self.jingjieQuality = 0--境界品质
    self.jingjieIsshow = 0--境界显示
    self.zhanDouLi = 0--人物战斗力
    self.zhanDouLiInAll = 0--总战斗力
    --self.HolyBeastZdl = 0--灵兽战斗力
    self.state = 0--状态(0x01-战斗 0x04-红名强杀 0x08-帮派偷窃 0x10-帮派魔火0x20飞仙状态)
    self.huoDongState = 0--在活动中正在做活动中:1钓鱼
    self.LightEffect = 0--光效
    -- self.IsFirstCharge = {}--每个档位是否首充双倍(1可首充，0首充过了)
    self.m_PayPricelist = {} -- 所有充值档位 IsFirstCharge 移到这里面来

    --护送任务相关
    self.ConvoyType = 0--0无 1护送 2押镖
    self.IsAutoYunShou = false--是否为自动护送神兽
    self.IsAutoConvoy = false--是否为自动运镖
    self.IsIntendCancel = false--主动取消运镖
    self.IsTakingTask = false--是否正在接任务
    self.AutoConvoyQuality = 0--自动换车上限品质（该品质以下自动换）1白2绿3蓝4紫5橙
    self.ConvoyInfo = ""--运镖是弹出信息
    self.ConvoySid = 0--运镖目的地sid
    self.ConvoyPos = cc.p(0,0)--运镖目的地pos
    self.ConvoyNPC = 0--运镖目的NPC
    self.m_Convoy = LConvoyData:New()--护送详细信息
  
    --self.LockPassword = ""--安全锁
    --self.m_FengHuangChangeState = 0--未知
    self.isCompleteNewRoleTask = 0--是否完成新手任务
    self.packageOpenNum = 0
    self.nextOpenPackageTime = 0
    self.isInitHorseList = true--是否初始化坐骑列表
    self.Horse = {}--坐骑信息(LHorseData)
    self.JingJie={}--境界信息(LJingjieData)
    self.jingJieOtherInfo = LJingJieOtherInfo:New()
  
    --self.m_ServerHorseList = {}      --服务器下发的所有坐骑信息(LServerHorseList)
     self.isKuFuTaskAutoPath=false
    self.horseExInfo = LHorseOthInf:New()--坐骑其他信息
    self.DetailData = LHeroDetailData:New()                     --详细属性
    self.EquipList = {}--装备列表
    for i = 1,LRoleData.MAX_EQUIP_NUM do
        table.insert(self.EquipList,LPItem:New())
    end
    self.VecFightPet = {}--出战宠物LPetData
    self.m_PetIdx = 0 --出战宠物选择（临时数据）
    self.VecZhuZhanPet = {}                  --助战宠物pos
    self.MedalAddition = LAdditionInfo:New() --称号附加信息
    self.ShenQiAddition = LAdditionInfo:New()--神器附加信息
    self.MedalId = 0                        --当前佩戴的称号
    self.ShenQiId = 0                       --当前佩戴的神器
    --ark_hero*           HeroNode
    --附近玩家相关
    self.FollowPet = 0
    self.RideId = 0
    self.FollowPetQty = 0
    self.FollowPetName = ""
    self.TeamId = 0                        --ID
    self.TeamType = 0                      --队伍类型：0任意目标1野外挂机2捉鬼任务3其他0xff没有发布
    self.isAFK = false                          --

    self.WingsId = 0                        --翅膀id
    self.MyChiBangVec = {}--角色拥有的翅膀信息LChiBangData
    self.ChiBangExInfo = LChiBangOtherInfo:New()
    self.RingInfo = {0}--婚戒信息 第一个数据为是否有婚戒                
    self.serzoneid = 0                      --跨服战游戏服大区id
    self.serenterid = 0                     --跨服战服务器列表入口id
    self.ShapeId = 0                        --变形宠物Id

    --婚礼信息
    self.marrriageType = 0

    self.marriageLeaderId = 0

    self.marriageFlowId = 0

    self.create_time = 0
    self.serverId = 0
    self.meili = 0
    --self.footId = 0
    
    self.shapeIdState = 0--0显示 1隐藏

    self.MyPowerUpdate = 0


    self.SceneType = 0              --场景类型
    self.IsSpaicialScene = false        --是否为特殊场景

    self.m_pTeam = LTeamData:New()
    self.MyVIPInfo = LVIPDataInfo:New()       --我的vip信息
    self.m_pLoginGift = LLoginGitt:New()     --登录奖励
	self.m_pLevelWard = {}
    self.ShenQi = LShenqiStage:New() -- 神器阶段
    --self.YouLi=LYouLiData:New()-- 游历
    self.OnLine=LOnLineData:New()-- 在线
    self.m_pLingqi = LLingqiInfo:New() -- 灵气
    self.m_pQuestion = {} -- 答题信息
    self.m_pRechargetGift = LActiveAward:New() -- 充值送礼
    self.m_BufferList={}--buff加成世界经验月卡等
    self.m_CardBuffer=0
	self.equip_fenjie_tips = true

end

--[[
检查是否可以挂机
]]
function LRoleData:CheckCanHangUp()
    --主城和师门不能挂机
    if (self.sid > 10 and self.sid < 15) or sid == 70 then
        return false
    end
    return true
end

--[[
设置地图
mid场景资源id
sid场景id
]]
function LRoleData:SetMap(sid,picid)
    self.sid = sid
    self.mid = picid--场景资源ID
    if (sid >= 1 and sid <= 14) then
        self.SceneType = AppDef.SceneType.MSI_NORMAL
    elseif sid == 45 then
        self.SceneType = AppDef.SceneType.MSI_FACTION_WAR_PRE
    elseif sid == 46 or sid == 56  then
        self.SceneType = AppDef.SceneType.MSI_FACTION_WAR
    elseif sid == 47 then
        self.SceneType = AppDef.SceneType.MSI_FACTION_ZONE
    elseif sid == 51 then
        self.SceneType = AppDef.SceneType.MSI_LEITAISAI
    elseif sid == 53 or sid == 170 then
        self.SceneType = AppDef.SceneType.MSI_FIARYLAND
    elseif sid > 53 and sid < 56 then
        self.SceneType = AppDef.SceneType.MSI_FISHROOM
    elseif sid == 70 then
        self.SceneType = AppDef.SceneType.MSI_CROSSSERVER
    elseif sid == 71 or sid == 72 then
        self.SceneType = AppDef.SceneType.MSI_LUNDAO
    elseif sid == 73 then
        self.SceneType = AppDef.SceneType.MSI_WEIWODUXIAN
    elseif sid == 74 or sid == 75 then
        self.SceneType = AppDef.SceneType.MSI_SHENJIEMIJING
    elseif sid == 76 then
        self.SceneType = AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY
    elseif sid == 77 then
        self.SceneType = AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE
    elseif sid > 60 and sid < 121 then
        self.SceneType = AppDef.SceneType.MSI_TOWER
    elseif sid > 120 and sid < 151 then
        self.SceneType = AppDef.SceneType.MSI_KUNLUN
    elseif sid >= 162 and sid <= 165 then
        self.SceneType = AppDef.SceneType.MSI_PETCOPY
    elseif sid == 161 or sid >=166 and sid < 174  then
        self.SceneType = AppDef.SceneType.MSI_COPY
    elseif sid == 174 then
        self.SceneType = AppDef.SceneType.MSI_SHILIAN
    elseif sid >= 175 and sid<=179 then
        self.SceneType = AppDef.SceneType.MSI_FLYFARY
    elseif sid == 201 then
        self.SceneType = AppDef.SceneType.MSI_COUPLE_COPY
    end
    --跨服场景是正常场景
    if self.SceneType ~= AppDef.SceneType.MSI_NORMAL == true then
        self.IsSpaicialScene = true
    else
        self.IsSpaicialScene = false
    end
end

function LRoleData:GetTeamMemberNum()
    local cnt = 0
    local members = self.m_pTeam.m_pMembers
    for i = 1, #members do
        if members[i].m_type == 1 then
            cnt = cnt + 1
        end
    end
    return cnt
end

function LRoleData:SendTeamMsg(teamType, minLv, maxLv)
    --[[
    改服务器推送
    ]]
    LuaNetSendMsg:ReqTeamChat()
    -- local name = ""
    -- local publishData = self.m_pTeam.m_pPublishList
    -- if teamType == nil then
    --     if publishData.m_byType == 0 then
    --         return false
    --     end
    --     teamType = publishData.m_byType
    --     local settingData = LDataConstMgr:GetTeamData()
    --     for i = 1, #settingData do
    --         if settingData[i].m_type == publishData.m_byType then
    --             minLv = publishData.m_minLv
    --             maxLv = publishData.m_maxLv
    --             name = settingData[i].m_name
    --             break
    --         end
    --     end
    -- else
    --     local settingData = LDataConstMgr:GetTeamData()
    --     for i = 1, #settingData do
    --         if teamType == settingData[i].m_type then
    --             name = settingData[i].m_name
    --             break
    --         end
    --     end
    -- end
    -- local str = name
    --             .. "(" .. self:GetTeamMemberNum() .. "/5\n" 
    --             .. minLv .. "-" .. maxLv .. GUITips.Common_Ji
    --             .. "[d|2," .. self.id .. ",".. GUITips.UI_Team_Join .."]"
    -- LuaNetSendMsg:QuerySendChatMsg(AppDef.ChatChanelType.CCT_SPEC, str)
    -- return true
end

function LRoleData:GetTeamId()
    local members = self.m_pTeam.m_pMembers
    
    for i = 1, #members do
        
        if members[i].m_cap == 1 then
            return members[i].m_id
        end
    end
    return 0
end

function LRoleData:IsTeam()
    return self.m_pTeam.m_bIsTeam
end

function LRoleData:IsTeamPause()
    local members = self.m_pTeam.m_pMembers
    for i = 1, #members do
        if members[i].m_id == self.id then
            if members[i].m_state == 0 then
                return true
            else
                return false
            end
        end
    end
    return false
end

function LRoleData:CleatTeamApplyList()
    local cnt = #self.m_pTeam.m_pApplyList
    for i = 1, cnt do
        LuaNetSendMsg:AccpetPlayerTeam(self.m_pTeam.m_pApplyList[i].id, 0)
        self.m_pTeam.m_pApplyList[i]:Delete()
        self.m_pTeam.m_pApplyList[i] = nil
    end
    self.m_pTeam.m_pApplyList = {}
    LGameMsg.m_baseMsgWithOne:Change(LUIRoleTeamEvent.ApplyListChanged, false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function LRoleData:GetApplyMember(id)
    for i = 1, #self.m_pTeam.m_pApplyList do
        if self.m_pTeam.m_pApplyList[i].id == id then
            return self.m_pTeam.m_pApplyList[i]
        end
    end
    return nil
end

function LRoleData:ClearApplyMember()
    local num = #self.m_pTeam.m_pApplyList
    for i = 1, num do
        self.m_pTeam.m_pApplyList[i]:Delete()
        self.m_pTeam.m_pApplyList[i] = nil
    end
    self.m_pTeam.m_pApplyList = {}
end

function LRoleData:AddApplyMember(info)
    table.insert(self.m_pTeam.m_pApplyList,info)
end

function LRoleData:GetTeamApplyList()
    local members = self.m_pTeam.m_pMembers
    for i = 1, #members do
        for j = 1,#self.m_pTeam.m_pApplyList do
            if members[i].m_id == self.m_pTeam.m_pApplyList[j].id then
                self.m_pTeam.m_pApplyList[j]:Delete()
                self.m_pTeam.m_pApplyList[j] = nil
                table.remove(self.m_pTeam.m_pApplyList,j)
                break
            end
        end
    end
    return self.m_pTeam.m_pApplyList
end

function LRoleData:CreateTeam()
    self.m_pTeam.m_bIsTeam = true
    self.m_pTeam.m_bIsCap = true
    self.m_pTeam.m_bIsAutoApply = false
    self.m_pTeam:ResetTeamTarget()
    self.m_pTeam:ResetMembers()
    self:ClearApplyMember()
end

function LRoleData:SetCap(cap)
    self.m_pTeam.m_bIsCap = cap
end

function LRoleData:SetTeamInvated(heroId)
    self.m_pTeam:SetTeamInvated(heroId)
end

function LRoleData:IsTeamInvated(heroId)
    return self.m_pTeam:IsTeamInvated(heroId)
end

function LRoleData:IsPause()
    local myInfo = self.m_pTeam:GetHeroMemberById(self.id)
    if myInfo == nil then
        return false
    end
    if myInfo.m_state == 0 then
        return true
    end
    return false
end

function LRoleData:LeaveTeam()
    self.m_pTeam.m_bIsTeam = false
    self.m_pTeam.m_bIsCap = false
    self.m_pTeam.m_bIsAutoApply = false
    self.m_pTeam:ResetMembers()
end

function LRoleData:JoinTeam()
    self.m_pTeam.m_bIsTeam = true
    self.m_pTeam.m_bIsCap = false
    self.m_pTeam.m_bIsAutoApply = false
    self.m_pTeam:ResetTeamTarget()
    self.m_pTeam:ResetMembers()
end

function LRoleData:IsLeader()
    return self.m_pTeam.m_bIsCap
end

function LRoleData:IsFightingState() return bit:_and(self.state , 0x01) == 0x01 end
function LRoleData:IsEnemyState() return bit:_and(self.state , 0x04) == 0x04 end
function LRoleData:IsStealState() return bit:_and(self.state , 0x08) == 0x08 end
function LRoleData:IsMagicFireState() return bit:_and(self.state , 0x10) == 0x10 end
function LRoleData:IsFlyFaryState() return bit:_and(self.state , 0x20) == 0x20 end
function LRoleData:IsRide()  return self.horseExInfo.useIndex ~= 0xff end
function LRoleData:IsWeapon() return self.EquipList[5].m_id > 0 end
function LRoleData:IsShaped() return self.ShapeId > 0 end
function LRoleData:GetShapeId() return self.ShapeId end
function LRoleData:IsMe(id) return id == self.id end

--Get
function LRoleData:GetWeaponId() return self.EquipList[5].m_id end
function LRoleData:GetEquipPItem(idx)  return self.EquipList[idx] end
function LRoleData:SetWeaponId(id) self.EquipList[5].m_id = id end  --设置武器ID

function LRoleData:SendHeroModelChangedMsg()
    if AppDef.CurScene then
        local function DelayToChangeModel()
            local modelmsg = HeroModelChangedMsg:new(CEnum.RoleEvent.ModelChanged,
                        self:GetWeaponId(),
                        self:GetLightEffect(),
                        self:GetHorseId(),
                        self:GetWingId(),
                        self:GetShenQiId(),
                        self:GetHorseSpd(),
                        self:GetShapeId())
            self:SendMsg(modelmsg)
        end
        Utils:DelayToCallFunc(AppDef.CurScene,0.2,DelayToChangeModel)
    end
    
end

function LRoleData:SendHeroConvoyChangedMsg()
    local modelmsg = HeroConvoyChangedMsg:new(CEnum.RoleEvent.ConvoyDataChanged,
                self.ConvoyType, self.m_Convoy.Quality)
    self:SendMsg(modelmsg)
end

function LRoleData:SendHeroFollowPetChangedMsg(petId, petName, petQuality)
    local modelmsg = HeroConvoyChangedMsg:new(CEnum.RoleEvent.ConvoyDataChanged,
                petId, petName, petQuality)
    self:SendMsg(modelmsg)
end

function LRoleData:GetHorseId()
    if self:IsRide() == true then
        return self.Horse[self.horseExInfo.useIndex + 1].id
    else
        return 0
    end 
end

function LRoleData:GetHorseSpd()
    if self:IsRide() == true then
        return self.Horse[self.horseExInfo.useIndex + 1].basicSpeed
    else
        return 0
    end 
end

function LRoleData:GetHorseExInfo_UseIndex() 
    if self:IsRide() == true then
        return self.horseExInfo.useIndex
    else
        return -1
    end 
end

function LRoleData:GetHorseExInfo()  return self.horseExInfo end
function LRoleData:GetzhanDouLi() return self.zhanDouLi end
function LRoleData:GetDetailData() return self.DetailData end
function LRoleData:GetHorse() return self.Horse end
function LRoleData:GetMyChiBangVec() return self.MyChiBangVec end
function LRoleData:GetChiBangOtherInfo() return self.ChiBangExInfo end

--ark_hero* GetHeroNode() {return self.HeroNode end--获取玩家节点
function LRoleData:IsEquipChiBang() return self.ChiBangExInfo.useIndex ~= 0xff end   --是否有翅膀装配
function LRoleData:GetWingId()   

    if self.ChiBangExInfo.useIndex ~= 0xff then
        return self.ChiBangExInfo.useIndex
    else 
        return 0 
    end                 --翅膀id
end

function LRoleData:Getid() return self.id end           
function LRoleData:GetroleType() return self.roleType end            
function LRoleData:Getname() return self.name end        
function LRoleData:GetvipLevel() return self.vipLevel end
function LRoleData:Getface() return self.face end
function LRoleData:Getsex() return self.sex end
function LRoleData:Getprofessional() return self.professional end
function LRoleData:Getmid() return self.mid end
function LRoleData:Getsid() return self.sid end
function LRoleData:Getlevel() return self.level end
function LRoleData:Getposx() return self.posx end
function LRoleData:Getposy() return self.posy end
function LRoleData:GetFactionId() return self.FactionId end
function LRoleData:GetFactionName() return self.FactionName end
function LRoleData:GetFactionRankType() return self.FactionRankType end
function LRoleData:GetshowFactionName() return self.showFactionName end
function LRoleData:GetshowMasterName() return self.showMasterName end
function LRoleData:Getstate() return self.state end
function LRoleData:GethuoDongState() return self.huoDongState end
function LRoleData:GetLightEffect() return self.LightEffect end
function LRoleData:GetMedalId() return self.MedalId end
function LRoleData:GetShenQiId()   return self.ShenQiId end
function LRoleData:GetWingsId()   return self.WingsId end
function LRoleData:GetMedalAdditionInfo()   return self.MedalAddition end                 --称号附加信息
function LRoleData:GetPackageOpenNum()   return self.packageOpenNum end
function LRoleData:GetIsFirstCharge()   return self.IsFirstCharge end                 --每个档位是否首充双倍(1可首充，0首充过了)
function LRoleData:GetVecZhuZhanPet()   return self.VecZhuZhanPet end                 --助战宠物pos
--Set
function LRoleData:SetzhanDouLi(value_) zhanDouLi = value_ end
function LRoleData:SetDetailData(value_)
    if self.DetailData ~= nil then
        self.DetailData:Delete()
        self.DetailData = nil
    end
    self.DetailData = value_ 
end

function LRoleData:GetHorseListAndReset()
    local cnt = #self.Horse
    for i = 1, cnt do
        self.Horse[i]:Delete()
        self.Horse[i] = nil
    end
    self.Horse = {}
    return self.Horse
end
function LRoleData:GetJingJieListAndReset()
    local cnt = #self.JingJie
    for i = 1, cnt do
        self.JingJie[i]:Delete()
        self.JingJie[i] = nil
    end
    self.JingJie = {}
    return self.JingJie
end

function LRoleData:GetSerZoneId()
    return self.serzoneid
end

function LRoleData:SetHorse(value_)
    if self.Horse ~= nil then
        for i = 1, #self.Horse do
            self.Horse[i]:Delete()
            self.Horse[i] = nil
        end
        self.Horse = nil
    end
    self.Horse = value_ 
end
function LRoleData:Setid(value_) self.id = value_ end           
function LRoleData:SetroleType(value_) self.roleType = value_ end            
function LRoleData:Setname(value_) self.name = value_ end         
function LRoleData:SetvipLevel(value_) self.vipLevel = value_ end
function LRoleData:Setface(value_) self.face = value_ end
function LRoleData:Setsex(value_) self.sex = value_ end
function LRoleData:Setprofessional(value_) self.professional = value_ end
function LRoleData:Setmid(value_) self.mid = value_ end
function LRoleData:Setsid(value_) self.sid = value_ end
function LRoleData:Setlevel(value_) self.level = value_ end
function LRoleData:Setposx(value_) self.posx = value_ end
function LRoleData:Setposy(value_) self.posy = value_ end
function LRoleData:SetFactionId(value_) self.FactionId = value_ end
function LRoleData:SetFactionName(value_) self.FactionName = value_ end
function LRoleData:SetFactionRankType(value_) self.FactionRankType = value_ end
function LRoleData:SetshowFactionName(value_) self.showFactionName = value_ end
function LRoleData:Setstate(value_) self.state = value_ end
function LRoleData:SethuoDongState(value_) self.huoDongState = value_ end
function LRoleData:SetLightEffect(value_) self.LightEffect = value_ end
function LRoleData:SetMedalId(value_) self.MedalId = value_ end
function LRoleData:SetShenQiId(value_) self.ShenQiId = value_ end
function LRoleData:SetshowMasterName(val)  self.showMasterName = val end  
function LRoleData:SetWingsId(val) self.WingsId = val end
function LRoleData:SetMedalAdditionInfo(info) 
    if self.MedalAddition ~= nil then
        self.MedalAddition:Delete()
        self.MedalAddition = nil
    end 
    self.MedalAddition = info 
end                --称号附加信息o
function LRoleData:ResetIFC(init)--充值首充标记（全部置0）
    self.IsFirstCharge = {}
    if init == false then
        return
    end
    for i = 1, 8 do
        table.insert(self.IsFirstCharge,0)
    end
end

function LRoleData:AddMyWing(wing)
    self.MyChiBangVec[#self.MyChiBangVec + 1] = wing
end

function LRoleData:GetMyWing(wid)
    if wid == nil then
        return nil
    end
    for k,v in pairs(self.MyChiBangVec) do
        if k and v and v[1] == wid then
            return v[2]
        end
    end
    return nil
end
--[[
不需要了，里面的信息全部通过前端读表获取
]]
-- function LRoleData:GetServerHorseListAndReset()
--     local cnt = #self.m_ServerHorseList
--      for i = 1,cnt do
--          self.m_ServerHorseList[i]:Delete()
--          self.m_ServerHorseList[i] = nil
--      end
--      self.m_ServerHorseList = {}
--      return self.m_ServerHorseList
--  end


-- function LRoleData:FindHorse(id)
--      for i = 1,#self.m_ServerHorseList do
--          if id == self.m_ServerHorseList[i].id then
--              return i
--          end
--      end
--      return 0
--  end

--  function LRoleData:FindServerHorseData(id)
--      for i = 1,#self.m_ServerHorseList do
--          if id == self.m_ServerHorseList[i].id then
--              return self.m_ServerHorseList[i]
--          end
--      end
--      return nil
--  end

function LRoleData:GetHorsePower(id,sLevel)
    local baseHorse = LDataConstMgr:GetHorseConfigData(id)
    if baseHorse == nil then
        return 0
    end
    local basePower = LDataConstMgr:GetAttrPower(baseHorse.attrTypeArr, baseHorse.attrValueArr)


    local qianghuadata = LDataConstMgr:GetHorseStrengthData(sLevel)

    local addPower = LDataConstMgr:GetAttrPower(qianghuadata.attrTypeArr, qianghuadata.attrValueArr)
    return basePower + addPower
     -- local idx = self:FindHorse(id)
     -- if idx == 0 then
     --     return 0
     -- else
     --     local horse = self.m_ServerHorseList[idx]
     --     local basePower = math.floor(horse:GetBasicHP()/3) + horse:GetBasicRecovery()*2 + horse:GetBasicDamage()
     --     local addPower = math.floor(LDataConstMgr:GetHorseHpAdd(sLevel)/3 + LDataConstMgr:GetHorseDefenseAdd(sLevel)*2 + LDataConstMgr:GetHorseHurtAdd(sLevel))

     --     if t == 0 then
     --         return math.floor((basePower+addPower)*1.5)
     --     elseif t == 1 then
     --         return math.floor((basePower*1.5))
     --     else
     --         return math.floor((addPower*1.5))
     --     end
     -- end
end

function LRoleData:GetSceneType()
    return self.SceneType
end

function LRoleData:SortPayPriceData()
    -- body
    function sortFunc(a, b) 
        return a.index < b.index
    end
    table.sort(self.m_PayPricelist, sortFunc)
end

function LRoleData:ISLunDaoScene()
    return self.SceneType and (self.SceneType == AppDef.SceneType.MSI_LUNDAO)
end

function LRoleData:IsLoginGiftHaveGet(day)
    if day == nil or self.m_pLoginGift == nil then
        return false
    end
    if self.m_pLoginGift.dayInfo == nil or self.m_pLoginGift.getNum < day then
        return false
    end

    local info = self.m_pLoginGift.dayInfo[day]
    if info == nil then
        return false
    end
    return (info.haveGet or false)
end

function LRoleData:updateMyVipInfo(type)
    -- body
    if type == 1 then
        self.MyVIPInfo.mcGiftMonState = false
    elseif type == 2 then
        self.MyVIPInfo.mcLifeGiftMonState = false
    end
end

--获取头像
function LRoleData:GetHead()
    self.head = Utils:CheckHeadId(self.head)
    return self.head
end

--获取模型
function LRoleData:GetModel()
    self.model = Utils:CheckModelId(self.model)
    return self.model
end

function LRoleData:SetHead(head)
    self.head = head
end

return LRoleData:Awake()
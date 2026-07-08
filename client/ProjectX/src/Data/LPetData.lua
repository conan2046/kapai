--宠物成长信息
LPetGrowUp = {}
LPetGrowUp.__index = LPetGrowUp
function LPetGrowUp:New()
    local o = {}
    setmetatable(o,LPetGrowUp)    
    o:ctor()
    return o
end

function LPetGrowUp:ctor()
    self.HpGrow = 0
    self.DefGrow = 0
    self.SpeedGrow = 0
    self.ADGrow = 0
    self.APGrow = 0
    self.AftHpGrow = 0
    self.AftDefGrow = 0
    self.AftSpeedGrow = 0
    self.AftADGrow = 0
    self.AftAPGrow = 0--培养后数值
end
function LPetGrowUp:Delete()
    self.HpGrow = nil
    self.DefGrow = nil
    self.SpeedGrow = nil
    self.ADGrow = nil
    self.APGrow = nil
    self.AftHpGrow = nil
    self.AftDefGrow = nil
    self.AftSpeedGrow = nil
    self.AftADGrow = nil
    self.AftAPGrow = nil--培养后数值
end

--技能信息
LPetSkill = {}
LPetSkill.__index = LPetSkill
function LPetSkill:New()
    local o = {}
    setmetatable(o,LPetSkill)    
    o:ctor()
    return o
end

function LPetSkill:ctor()
    --LSkillDetail
    self.skDetail = nil
    self.level = 0
end
function LPetSkill:Delete()
    self.skDetail = nil
    self.level = nil
end

--能力值
LPetAbility = {}
LPetAbility.__index = LPetAbility
function LPetAbility:New()
    local o = {}
    setmetatable(o,LPetAbility)    
    o:ctor()
    return o
end

function LPetAbility:ctor()
    self.AD = 0 --物理攻击
    self.AP = 0 --法术攻击
    self.Def = 0 --防御
    self.Fix = 0 --修为
    self.Speed = 0 --速度
    self.CloseTo = 0 --亲密度
    self.Martial = 0 --武学
    self.Equipment = 0 --宠物装备
    self.StatusPoint = 0 --属性点
    self.Strength = 0 --体质
    self.Power = 0 --力量
    self.Agile = 0 --敏捷
    self.Psychic = 0 --灵力
    self.Endurance = 0 --耐力
    self.SpeedAddval = 0 --附加移动速度
end
function LPetAbility:Delete()
    self.AD = nil --物理攻击
    self.AP = nil --法术攻击
    self.Def = nil --防御
    self.Fix = nil --修为
    self.Speed = nil --速度
    self.CloseTo = nil --亲密度
    self.Martial = nil --武学
    self.Equipment = nil --宠物装备
    self.StatusPoint = nil --属性点
    self.Strength = nil --体质
    self.Power = nil --力量
    self.Agile = nil --敏捷
    self.Psychic = nil --灵力
    self.Endurance = nil --耐力
    self.SpeedAddval = nil --附加移动速度
end

LPetXueMai = {}
LPetXueMai.__index = LPetXueMai
function LPetXueMai:New()
    local o = {}
    setmetatable(o,LPetXueMai)    
    o:ctor()
    return o
end

function LPetXueMai:ctor()    
    self.Level = 0
    self.CurExp = 0
end

function LPetXueMai:Delete()
    self.Level = nil
    self.CurExp = nil
end

--宠物装备信息
LPetEquipInfo = {}
LPetEquipInfo.__index = LPetEquipInfo
function LPetEquipInfo:New()
    local o = {}
    setmetatable(o,LPetEquipInfo)    
    o:ctor()
    return o
end

function LPetEquipInfo:ctor()
    self.m_uid = 0          --唯一ID
    self.m_id = 0           --表格ID
    self.m_suitType = 0     --套装类型
    self.m_wpos = 0         --装备部位
    self.m_fpos = 0         --阵型位置
    self.m_star = 0         --星级
    self.m_name = ""         --名字
    self.m_stoneLevel = 0   --强化等级
    self.m_locked = 0       --是否锁定
    self.m_pic = ""         --icon
    self.m_des = ""         --描述
    self.m_from = ""         --描述
    self.m_quality = 0
    self.m_szCostItemId = 0
    self.m_jlExp = 0
    self.cultivateLevel = {}
    self.baseAttrs = {}
    self.qhAttrs = {}
    self.jlAttrs = {}
    self.jxAttrs = {}
    self.szAttrs = {}
end

function LPetEquipInfo:Delete()
    self.m_uid = nil
    self.m_id = nil
    self.m_suitType = nil
    self.m_wpos = nil
    self.m_star = nil
    self.m_stoneLevel = nil
    self.m_locked = nil
    self.m_pic = nil
    self.m_quality = nil
    self.m_suitId = nil
    self.m_baseTypes = nil
    self.m_baseValues = nil
    self.m_addTypes = nil
    self.m_addValues = nil
end

--宠物装备背包信息
LPetEquipBag = {}
LPetEquipBag.__index = LPetEquipBag
function LPetEquipBag:New()
    local o = {}
    setmetatable(o,LPetEquipBag)    
    o:ctor()
    return o
end

function LPetEquipBag:ctor()
    self.m_maxGridNum = 0
    self.m_curGridNum = 0 
    self.m_petEquips = {}
    self.m_petSuitNums = {}
    self.m_partNums = {}
    self.m_formationEquips = {}
end

function LPetEquipBag:Delete()
    self.m_maxGridNum = nil
    self.m_curGridNum = nil 
    self.m_petEquips = nil
    self.m_petSuitNums = nil
    self.m_formationEquips = nil
end

--宠物法宝信息
LPetFaBaoInfo = {}
LPetFaBaoInfo.__index = LPetFaBaoInfo
function LPetFaBaoInfo:New()
    local o = {}
    setmetatable(o,LPetFaBaoInfo)    
    o:ctor()
    return o
end

--法宝
function LPetFaBaoInfo:ctor()
    self.m_uid = 0          --唯一ID
    self.m_id = 0           --表格ID
    self.m_fpos = 0         --位置
    self.m_wpos = 0          --穿戴位置(5 6)
    self.qhLv = 0   --强化等级
    self.jlLv = 0 --精炼等级
    self.m_locked = 0       --是否锁定

    self.cultivateLevel = {}
    self.baseData = {}

end

function LPetFaBaoInfo:Delete()
    self.m_uid = nil          --唯一ID
    self.m_id = nil           --表格ID
    self.m_fpos = nil         --位置
    self.m_wpos = nil          --穿戴位置
    self.qhLv = nil   --强化等级
    self.jlLv = nil --精炼等级
    self.m_locked = nil       --是否锁定

    self.cultivateLevel = {}
    self.baseAttrs = {}
end

--法宝装备背包信息
LPetFaBaoBag = {}
LPetFaBaoBag.__index = LPetFaBaoBag
function LPetFaBaoBag:New()
    local o = {}
    setmetatable(o,LPetFaBaoBag)    
    o:ctor()
    return o
end

function LPetFaBaoBag:ctor()
    self.m_maxGridNum = 0
    self.m_curGridNum = 0 
    self.m_petFaBaos = {}
    self.m_formationFaBaos = {}
end

function LPetFaBaoBag:Delete()
    self.m_maxGridNum = nil
    self.m_curGridNum = nil 
    self.m_petFaBaos = nil
    self.m_formationFaBaos = nil
end

--神将装备表格信息
LPetEquipCfgInfo = {}
LPetEquipCfgInfo.__index = LPetEquipCfgInfo
function LPetEquipCfgInfo:New()
    local o = {}
    setmetatable(o,LPetEquipCfgInfo)    
    o:Init()
    return o
end

function LPetEquipCfgInfo:Init()
    self.id = 0                                  --索引
    self.pic = ""                                --资源（图标）
    self.name = 0                                --阵形容量
    self.suitType = 0                            --套装类型
    self.pos = 0                                 --部位
    self.quality = 0                             --品质
    self.sortId = 0                              --初始排序ID
    self.desc = ""                               --描述
    self.unKnowDesc = ""                         --未获取时描述
    self.from = ""                               --来源
end


--宠物封装类信息
LPetData = {}
LPetData.__index = LPetData
function LPetData:New(pid)
    pid = pid or 0
    local o = {}
    setmetatable(o,LPetData)    
    o:ctor(pid)
    return o
end

function LPetData:SetPetId(pid)
    self.id = pid
    self.baseData = JsonConfig.m_heroCfg.getDefByID(self.id)
    for i = 1, #self.baseData.skills do
        self.skills[i].skDetail = LSkillMgr:getSkillById(self.baseData.skills[i])
        self.skills[i].level = 0
    end
end

function LPetData:ctor(pid)
    self.id = pid--宠物id
    self.baseData = nil--宠物基础数据
    if self.id > 0 then
        -- self.baseData = LDataConstMgr:GetPetData(self.id)
        self.baseData = JsonConfig.m_heroCfg.getDefByID(self.id)
    end
    self.name = ""
    --self.pos = 0 --位置
    --self.type = 0           --宠物类型1宝宝0野怪
    self.fightPos = 0       --出战位置
    --self.curForm = 0        --阵形索引  -1：无，0，1：a,b阵
    --self.state = 0          --宠物状态
    --self.picid = 0          --图片id
    self.star = 0--星级
    self.starStep = 0--子星级
    self.breakLevel = 0--突破等级
    self.XLLv = 0 --修炼等级
    self.XLInfo = {0, 0 , 0, 0}
    self.level = 0--等级
    self.exp = 0--当前经验
    self.expMax = 0--最大经验
    self.zhandouli = 0--战斗力

    self.attrs = {}

    self.skillNum = 0--技能数量
    self.skills = {}
    -- --前四个固定是天赋技能，后面是天书技能
    -- for i = 1, AppDef.Pet.MaxSkillNum do
    --     table.insert(self.skills,LPetSkill:New())
    -- end
    if self.baseData ~= nil then
        for i = 1, #self.baseData.skills do
            if self.skills[i] == nil then
                self.skills[i] = LPetSkill:New()
            end
            self.skills[i].skDetail = LSkillMgr:getSkillById(self.baseData.skills[i])
            self.skills[i].level = 0
        end
        self.name = self.baseData.name
    end

    self.isFight = false        --是否出战状态
    self.isRiding = false       --是否被骑乘
    self.isLook = false         --是否是观看状态
    self.isInTuJian = false     --是否图鉴显示
    self.isJueXing = false      --是否可觉醒
    self.isJueXinged = false    --是否觉醒过
    self.jueXingTargetId = 0    --觉醒宠物id
    self.isZhuZhan = false        --是否助战
    --群仙争霸
    self.isFightInQXZB = false  --是否出战状态,群仙内
    self.isFromInQXZB = false  --是否来自群仙内
    self.isDieInQXZB = false        --是否已经死亡,群仙内
    self.GrowUp = LPetGrowUp:New()

    --宠物装备
    --self.petEquips = {}
    --套装属性
    --self.petSuits = {}--id ,num(套装ID，件数)
    --宠物装备总属性
    --self.equipAttrs = {}
end

--[[
设置属性值
]]
function LPetData:SetAttrValue(attrType,attrValue)
    self.attrs[attrType] = attrValue
end

function LPetData:Delete()
    self.baseData = nil
    self.name = nil--名字
    self.pos = nil --位置
    self.type = nil           --宠物类型1宝宝0野怪
    self.fightPos = nil       --出战位置
    self.curForm = nil        --阵形索引  -1：无，nil，1：a,b阵
    self.id = nil             --宠物id
    self.state = nil          --宠物状态
    self.picid = nil          --图片id

    self.isFight = nil        --是否出战状态
    self.isRiding = nil       --是否被骑乘
    self.isLocked = nil       --是否被锁住
    self.isLook = nil         --是否是观看状态
    self.isInTuJian = nil     --是否图鉴显示
    self.isJueXing = nil      --是否可觉醒
    self.isJueXinged = nil    --是否觉醒过
    self.jueXingTargetId = 0--觉醒宠物id
    self.isZhuZhan = nil        --是否助战
    --群仙争霸
    self.isFightInQXZB = nil  --是否出战状态,群仙内
    self.isFromInQXZB = nil  --是否来自群仙内
    self.isDieInQXZB = nil        --是否已经死亡,群仙内
    self.GrowUp:Delete()
    self.GrowUp = nil
    for i = 1, AppDef.Pet.MaxSkillNum do
        if self.skills[i] then
            self.skills[i]:Delete()
            self.skills[i] = nil
        end
    end
    self.skills = nil
    self.skillNum = nil
    self.xiulianLv = nil
    --宠物装备
    self.petEquips = nil
    --套装属性
    self.petSuits = nil
    self.equipAttrs = nil
end


function LPetData:Getname()
    return self.name
end

function LPetData:Getid() 
    return self.id
end

function LPetData:IsShiny()
    return self.baseData:IsShiny()
end

function LPetData:Getstate()
    return self.state
end

function LPetData:Getpos()
    return self.pos
end

function LPetData:GetfightPos() 
    return self.fightPos
end
function LPetData:GetcurForm() 
    return self.curForm
end

function LPetData:GetisZhuZhan()
    return self.isZhuZhan
end

function LPetData:GetAttackSkills(skillList)
    local num = math.floor(#self.Skills/#self.Skills[1])
    for i = 1, num do
        if self.Skills[i].id ~= 0 and self.Skills[i].id <= 150 then
            table.insert(skillList,self.Skills[i])
        end
    end
end

function LPetData:GetNaturalSkills(skillList)
    local num = math.floor(#self.Skills/#self.Skills[1])
    for i = 1, num do
        if self.Skills[i].id ~= 0 and (self.Skills[i].id <= 2 or (self.Skills[i].id >= 10 and self.Skills[i].id <= 16)) then
            table.insert(skillList,self.Skills[i])
        end
    end
end

function LPetData:IsFight() 
    return self.fightPos > 0
    --return bit._and(self.state , 0x02) == 0x02
end

function LPetData:IsAtLook()
    return  bit._and(self.state , 0x01) == 0x01
end

--
 


--pet 阵容出战宠物pos
LFormationInfo = {}
LFormationInfo.__index = LFormationInfo
function LFormationInfo:New()
    local o = {}
    setmetatable(o,LFormationInfo)    
    o:ctor()
    return o
end

function LFormationInfo:ctor()
    self.CurIndex = 0                               --当前阵形索引
    self.TotalCount = 0                             --阵形总数
    self.PosCount = 0                               --阵形容量
    self.lingshouId = 0                             --灵兽Id
    self.VecPetPosList = {}      --每个阵行中包含的宠物的位置索引
end

function LFormationInfo:Delete()
    self.CurIndex = nil                               --当前阵形索引
    self.TotalCount = nil                             --阵形总数
    self.PosCount = nil                               --阵形容量
    self.lingshouId = nil                             --灵兽Id
    local num = #self.VecPetPosList
    for i = 1, num do
        self.VecPetPosList[i] = {}
    end
    self.VecPetPosList = {}
    self.VecPetPosList = nil
end

--[[
宠物神将升星数据
]]
LPetShengxing = {}
LPetShengxing.__index = LPetShengxing
function LPetShengxing:New()
    local o = {}
    setmetatable(o,LPetShengxing)    
    o:ctor()
    return o
end

function LPetShengxing:ctor()
    --quality    star    node    attr    cost_num
    self.quality = 0--资质
    self.star = 0--星级
    self.subStar = 0--每个星级对应的子星级
    self.attrType = {}--对应的属性键值
    self.attrValue = {}--对应的属性值
    self.constNum = 0--对应的消耗碎片数量
    self.attrs = ""
end
function LPetShengxing:Delete()
    self.quality = nil--资质
    self.star = nil--星级
    self.subStar = nil--每个星级对应的子星级
    self.attrType = nil--对应的属性键值
    self.attrValue = nil--对应的属性值
    self.constNum = nil--对应的消耗碎片数量
end

--[[
宠物神将修炼
]]
LPetXiulianData = {}
LPetXiulianData = {}
LPetXiulianData.__index = LPetXiulianData
function LPetXiulianData:New()
    local o = {}
    setmetatable(o,LPetXiulianData)    
    o:ctor()
    return o
end

function LPetXiulianData:ctor()
    --[[
    quality    level    index1_attr    index1_level    index2_attr    index2_level    index3_attr    index3_level    index4_attr    index4_level    index5_attr    index5_level    cost_item
资质1234    修炼等级    属性-属性值;属性-属性值    可修炼等级    属性-属性值;属性-属性值    可修炼等级    属性-属性值;属性-属性值    可修炼等级    属性-属性值;属性-属性值    可修炼等级    属性-属性值;属性-属性值    可修炼等级    道具id-数量;道具id-数量

    ]]
    self.quality = 0--资质
    self.level = 0--修炼等级
    self.attrType1List = {0,0,0,0,0}--对应属性1
    self.attrValue1List = {0,0,0,0,0}--对应属性值1
    self.attrType2List = {0,0,0,0,0}--对应属性2
    self.attrValue2List = {0,0,0,0,0}--对应属性值2
    self.heroLvList = {0,0,0,0,0}--对应英雄等级要求
    self.needItemIdList = {0,0}--需求道具1
    self.needItemNumList = {0,0}--需求道具1

end
function LPetXiulianData:Delete()
    self.quality = nil--资质
    self.level = nil--修炼等级
    self.attrType1List = nil--对应属性1
    self.attrValue1List = nil--对应属性值1
    self.attrType2List = nil--对应属性2
    self.attrValue2List = nil--对应属性值2
    self.heroLvList = nil--对应英雄等级要求
    self.needItemIdList = nil--需求道具1
    self.needItemNumList = nil--需求道具1
end

--[[
宠物神将升星职业对应的属性加成
]]
LPetSXAddValue = {}
LPetSXAddValue = {}
LPetSXAddValue.__index = LPetSXAddValue
function LPetSXAddValue:New()
    local o = {}
    setmetatable(o,LPetSXAddValue)    
    o:ctor()
    return o
end

function LPetSXAddValue:ctor()
    --[[
    type    attackRatio    wufangRatio    fashangRatio    suduRatio    qixueRatio    mingzhongRatio    shanbiRatio    baojiRatio    kangbaoRatio
神将类型    攻击倾向比例    物防倾向比例    法防倾向比例    速度倾向比例    气血倾向比例    命中倾向比例    闪避倾向比例    暴击倾向比例    抗暴倾向比例

    ]]
    self.zhiye = 0--职业
    self.attackRatio = 0--攻击比例
    self.wufangRatio = 0--物防倾向比例
    self.fashangRatio = 0--法防倾向比例
    self.suduRatio = 0--速度倾向比例
    self.qixueRatio = 0--气血倾向比例
    self.shanbiRatio = 0--闪避倾向比例
    self.mingzhongRatio = 0--命中倾向比例
    self.baojiRatio = 0--暴击倾向比例
    self.kangbaoRatio = 0--抗暴倾向比例

end
function LPetSXAddValue:Delete()
    self.zhiye = nil--职业
    self.attackRatio = nil--攻击比例
    self.wufangRatio = nil--物防倾向比例
    self.fashangRatio = nil--法防倾向比例
    self.suduRatio = nil--速度倾向比例
    self.qixueRatio = nil--气血倾向比例
    self.shanbiRatio = nil--闪避倾向比例
    self.mingzhongRatio = nil--气血倾向比例
    self.baojiRatio = nil--暴击倾向比例
    self.kangbaoRatio = nil--抗暴倾向比例
end

--神将表格信息
LPetConfigInfo = {}
LPetConfigInfo.__index = LPetConfigInfo
function LPetConfigInfo:New()
    local o = {}
    setmetatable(o,LPetConfigInfo)    
    o:Init()
    return o
end

function LPetConfigInfo:Init()
    self.id = 0                                  --索引
    self.pic = 0                                 --资源ID（头像）
    self.name = 0                                --阵形容量
    self.petType = 0                             --1物2法3肉4辅5控6灵
    self.joinLv = 0                              --出战等级
    self.quality = 0                             --1蓝2紫3橙4红(A、S、SS、SSS)
    self.initStar = 0                            --初始星级
    self.skills = {}                             --技能ID（天赋技能4个）
    self.skillBgms = {}                             --技能bgm,可能一对多
    self.recommend_skill = {}                     --推荐技能ID数组
    self.defaultFace = 0--UI展示默认的朝向
    self.desc = ""                               --描述
    self.attackType = 0                          --攻击类型（1物攻2法攻）
    self.baseAttrs = {}                          --基础属性
    self.growAttrs = {}                          --成长属性
    self.itemId = 0--对应的碎片id
    self.fenjieNum = 0--分解后得到的碎片数量
    self.cv = 0--声音
    self.tag = 0--页签
end

function LPetConfigInfo:GetCV()
    if self.cv == nil or string.len(self.cv) == 0 then
        return ""
    end
    local soundStr = self.cv
    local arr = string.split(soundStr,"|")
    local num = #arr
    local playFile = arr[math.random(1,num)]
    return playFile
end

function LPetConfigInfo:GetSkillBgm(skillId)
    local ind = 0
    for i = 1, #self.skills do
        if skillId == self.skills[i] then
            ind = i
            break
        end
    end
    if ind == 0 then
        return nil
    end
    if ind > #self.skillBgms then
        return nil
    end
    local soundArr = self.skillBgms[ind]
    local num = #soundArr
    local soundId = soundArr[math.random(1,num)]
    return soundId
end

function LPetConfigInfo:IsShiny()
    return self.initStar > 7
end

function LPetConfigInfo:Delete()
    self.id = nil                                  --索引
    self.pic = nil                                 --资源ID（头像）
    self.name = nil                                --阵形容量
    self.petType = nil                             --1物2法3肉4辅5控6灵
    self.joinLv = nil                              --出战等级
    self.quality = nil                             --1蓝2紫3橙4红(A、S、SS、SSS)
    self.initStar = nil                            --初始星级
    self.skills = nil                              --技能ID（天赋技能4个）
    self.recommend_skill = nil
    self.desc = nil
    self.fenjieNum = nil
    self.recommend_skill = nil
    self.defaultFace = nil
    self.attackType= nil
    self.baseAttrs = nil                           --基础属性
    self.growAttrs = nil                           --基础属性
    self.cv = nil--声音
    self.tag = nil
end

--神将推荐信息
LPetRecommendInfo = {}
LPetRecommendInfo.__index = LPetRecommendInfo
function LPetRecommendInfo:New()
    local o = {}
    setmetatable(o,LPetRecommendInfo)    
    o:Init()
    return o
end

function LPetRecommendInfo:Init()
    self.profession = 0                          --职业
    self.levels = {} 
    self.vecFormation = {}
--    level         --等级
--    name         --阵法类型
--    formation  --推荐阵法Id    
--    pets         --伙伴阵容
--    desc       --描述
end

function LPetRecommendInfo:Delete()
    self.profession = nil  
    local num = #self.VecPetPosList
    for k,v in pairs(self.vecFormation) do
        v = {}
    end
    self.vecFormation = nil
end

--神将显示信息
LPetShowInfo = {}
LPetShowInfo.__index = LPetShowInfo
function LPetShowInfo:New()
    local o = {}
    setmetatable(o,LPetShowInfo)    
    o:Init()
    return o
end

function LPetShowInfo:Init()
    self.id = 0
    self.name = 0 
    self.quality = 0
    self.starLv = 0
    self.attack_type = 0
    self.power = 0
    self.skills = {}
    self.attrs = {}
end



LPetDataMgr= {}
LPetDataMgr.__index = LPetDataMgr

function LPetDataMgr:FindPetDataById(id)
    -- local petList = LDataConstMgr:GetPetDataList()
    -- return petList[id]
    return JsonConfig.m_heroCfg.getDefByID(id)
end

-- function LPetDataMgr:ReadPetPicId(data)
--     local tmpData = self:FindPetDataById(data.id)
--     if tmpData ~= nil then
--         data.picid = tmpData.pic
--     end
-- end

function LPetDataMgr:CreatePetHead(id, isHolyBeast)
    isHolyBeast = isHolyBeast or false
    local data = LPetDataMgr:FindPetDataById(id)
    if (not isHolyBeast) and data == nil then
        return
    end

    return Utils:three(isHolyBeast, string.format('HolyBeastHead/HbHead%d.png', data.pic or id), string.format('MonsterHead/MonsterHead%d.png', data.pic or id))
end

function LPetDataMgr:GetPetTypeById(id)
    -- local petList = LDataConstMgr:GetPetDataList()
    local petList = JsonConfig.m_heroCfg.getList()
    if petList == nil or id > #petList then 
        return nil 
    end
    return petList[id].petType
end

--根据类型、图鉴分类，获取神将列表（0-所有）
function LPetDataMgr:GetPetListByType(petType)
   if LDataConstMgr.m_VecLvPets == nil then return end
   if petType == 0 then
       if self.m_petIdlist == nil then
           self.m_petIdlist = {}
           for k,v in pairs(LDataConstMgr.m_VecLvPets) do
               for key,val in pairs(v) do
                    if self.m_petIdlist[key] == nil then
                        self.m_petIdlist[key] = {}
                    end
                    if self.m_petIdlist[key].value == nil then
                        self.m_petIdlist[key].value = {}
                        self.m_petIdlist[key].tag = key
                    end
                    for i=1,#val.value do
                        table.insert(self.m_petIdlist[key].value,val.value[i])    
                    end                        
               end
           end
       end
       return self.m_petIdlist
   end
   return LDataConstMgr.m_VecLvPets[petType]
end

function LPetDataMgr:GetMaxFightPetNum(lv)
    if LRoleDataMgr.myFormation == nil then
        return 0 
    end
    local myUseId = LRoleDataMgr.myFormation.useId
    local cfg = LDataConstMgr:GetFormationDataById(myUseId)
    if cfg == nil then
        return 0 
    end
    local ret = 0
    for i=1,#cfg.posOpenLvList do
        if lv >= cfg.posOpenLvList[i] then
            ret = ret + 1
        end
    end
    return math.max(ret-1, 0)
end

--设置神将装备小红点
function LPetDataMgr:SavePetEquipRedDot(suitId,uid)
    local roleId = LRoleDataMgr.MyHeroInfo.id
    if roleId < 1 then return end
    local pUserDefault = CCUserDefault:getInstance()
    local sign = pUserDefault:getStringForKey(""..roleId.."_"..suitId)
    local uids = {}
    local isAdd = true
    if sign ~= nil and #sign > 0 then
        uids = Utils:StrToTable(sign)
        if type(uids) == "table" then
            for i = 1,#uids do
                if uids[i] == uid then
                    isAdd = false
                    break
                end
            end
        else
            uids = {}
        end
    end
    if isAdd then
        table.insert(uids,uid)
        local str = Utils:TableToStr(uids)
        pUserDefault:setStringForKey(""..roleId.."_"..suitId,str)
        pUserDefault:flush()
    end
    --print("LPetDataMgr:SavePetEquipRedDot",suitId)
end

--获取神将装备小红点
function LPetDataMgr:GetPetEquipRedDot()
    local suits = {}
    local roleId = LRoleDataMgr.MyHeroInfo.id
    local pUserDefault = CCUserDefault:getInstance()
    for i=1,AppDef.Pet.MaxSuitTypeNum do
        local sign = pUserDefault:getStringForKey(""..roleId.."_"..i)
        if sign ~= nil and #sign>0 then 
           suits[i] = 1
           --print("LPetDataMgr:GetPetEquipRedDot",i)
        end
    end
    return suits
end

--清除神将装备小红点
function LPetDataMgr:DelPetEquipRedDot()
    local roleId = LRoleDataMgr.MyHeroInfo.id
    local pUserDefault = CCUserDefault:getInstance()
    for i=1,AppDef.Pet.MaxSuitTypeNum do
        pUserDefault:setStringForKey(""..roleId.."_"..i,"")
    end
    pUserDefault:flush()
end

--清除神将单个套装小红点
function LPetDataMgr:DelPetSuitRedDot(suitId,uid)
    local roleId = LRoleDataMgr.MyHeroInfo.id
    if roleId < 1 or suitId == nil  then return false end
    local pUserDefault = CCUserDefault:getInstance()
    local sign = pUserDefault:getStringForKey(""..roleId.."_"..suitId)
    if sign == nil or #sign == 0 then
        return false
    end
    if uid == nil or uid == 0 then
        pUserDefault:setStringForKey(""..roleId.."_"..suitId,"")
        pUserDefault:flush()
    else
        local uids = Utils:StrToTable(sign)
        local isRemove = false
        if type(uids) == "table" then
            for i = 1,#uids do
                if uids[i] == uid then
                    isRemove = true
                    table.remove(uids,i)
                    break
                end
            end 
        end
        if isRemove then
            local str = Utils:TableToStr(uids)
            pUserDefault:setStringForKey(""..roleId.."_"..suitId,str)
            pUserDefault:flush()
            if #uids == 0 then
                return true
            end
        end
    end
    return false
end

--设置神将装备非新获得的标识（脱下）
--@param euid 装备唯一ID
--@param sign 1-标识 0-无标识
function LPetDataMgr:SetPetEquipOffSign(euid,sign)
    if self.m_equipSigns == nil then    
        self.m_equipSigns = {}
    end
    self.m_equipSigns[euid] = sign
end

--获得神将装备非新获得的标识（脱下）
function LPetDataMgr:GetPetEquipOffSign(euid)
    if self.m_equipSigns == nil then    
        self.m_equipSigns = {}
    end
    return self.m_equipSigns[euid] or 0
end

function LPetDataMgr:SavePetEquipRedDotById(uid)
    local roleId = LRoleDataMgr.MyHeroInfo.id
    if roleId < 1 then return end
    local pUserDefault = CCUserDefault:getInstance()
    local sign = pUserDefault:getStringForKey(""..roleId.."_new_equipids")
    local uids = {}
    local isAdd = true
    if sign ~= nil and #sign > 0 then
        uids = Utils:StrToTable(sign)
        if type(uids) == "table" then
            for i = 1,#uids do
                if uids[i] == uid then
                    isAdd = false
                    break
                end
            end
        else
            uids = {}
        end
    end
    if isAdd then
        table.insert(uids,uid)
        local str = Utils:TableToStr(uids)
        pUserDefault:setStringForKey(""..roleId.."_new_equipids",str)
        pUserDefault:flush()
    end
end

function LPetDataMgr:GetAllPetEquipRedDot()
    local roleId = LRoleDataMgr.MyHeroInfo.id
    local pUserDefault = CCUserDefault:getInstance()
    local sign = pUserDefault:getStringForKey(""..roleId.."_new_equipids")
    if sign ~= nil and #sign > 0 then
        return true
    end
    return false
end

function LPetDataMgr:IsPetEquipRedDotById(uid)
    local roleId = LRoleDataMgr.MyHeroInfo.id
    local pUserDefault = CCUserDefault:getInstance()
    local sign = pUserDefault:getStringForKey(""..roleId.."_new_equipids")
    if sign ~= nil and #sign > 0 then
        uids = Utils:StrToTable(sign)
        for i = 1,#uids do
            if uids[i] == uid then
                return true
            end
        end
    end
    return false
end

function LPetDataMgr:DelAllPetEquipRedDot()
    local roleId = LRoleDataMgr.MyHeroInfo.id
    local pUserDefault = CCUserDefault:getInstance()
    pUserDefault:setStringForKey(""..roleId.."_new_equipids","")
    pUserDefault:flush()
end

function LPetDataMgr:DelPetEquipRedDotById(uid)
    local roleId = LRoleDataMgr.MyHeroInfo.id
    if roleId < 1 then return false end
    local pUserDefault = CCUserDefault:getInstance()
    local sign = pUserDefault:getStringForKey(""..roleId.."_new_equipids")
    if sign == nil or #sign == 0 then
        return false
    end
    if uid == nil or uid == 0 then
        pUserDefault:setStringForKey(""..roleId.."_new_equipids","")
        pUserDefault:flush()
    else
        local uids = Utils:StrToTable(sign)
        local isRemove = false
        if type(uids) == "table" then
            for i = 1,#uids do
                if uids[i] == uid then
                    isRemove = true
                    table.remove(uids,i)
                    break
                end
            end 
        end
        if isRemove then
            local str = Utils:TableToStr(uids)
            pUserDefault:setStringForKey(""..roleId.."_new_equipids",str)
            pUserDefault:flush()
            if #uids == 0 then
                return true
            end
        end
    end
    return false
end
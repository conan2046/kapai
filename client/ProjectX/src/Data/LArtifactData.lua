LCShenQi = {}
LCShenQi.__index = LCShenQi
function LCShenQi:New()
    local o = {}
    setmetatable(o,LCShenQi )    
    o:Init()
    return o
end

function LCShenQi:Init( )
    self.m_id = 0
    self.m_name = ""             --名字
    self.m_desc = ""             --描述(来源)
    self.m_attrList = {}
    -- attrType
    -- attrValue
end

LCShenQiCultureData = {}
LCShenQiCultureData.__index = LCShenQi
function LCShenQiCultureData:New()
    local o = {}
    setmetatable(o,LCShenQiCultureData )    
    o:Init()
    return o
end

function LCShenQiCultureData:Init( )
    self.m_level = 0
    self.m_star = 0             
    self.m_needExp = 0 
    self.m_cur_shenqi = 0    
    self.m_next_shenqi = 0        
    self.m_add_shenqi = 0
    self.m_attrList = {}
    -- type
    -- value
end

LServerShenQiList = {}
LServerShenQiList.__index = LServerShenQiList
function LServerShenQiList:New()
    local o = {}
    setmetatable(o,LServerShenQiList )    
    o:Init()
    return o
end

function LServerShenQiList:Init( )
    self.id = 0
--    self.name = ""             --名字
--    self.get_rule = "" 
    self.getWay = 0            --神器获得方式1:碎片合成0：其他
    self.itemId = -1           --合成道具id
    self.needNum = 0           --合成所需数量
--    self.base_attr1 = 0        --攻击
--    self.base_attr2 = 0        --防御
--    self.base_attr3 = 0        --血量
--    self.base_attr4 = 0        --速度
--    self.base_attr5 = 0        --全系精通
--    self.base_attr6 = 0        --全系抗性
--    self.base_attr7 = 0        --暴击强化
--    self.base_attr8 = 0        --韧性强化
--    self.zhandouli = 0         --战斗力
    self.state = 0             --0未获得，1休息，2使用
end

function LServerShenQiList:Delete(id )
    self.id = nil
--    self.name  = nil
--    self.get_rule  = nil
    self.getWay = nil
    self.itemId  = nil
    self.needNum  = nil
--    self.base_attr1  = nil 
--    self.base_attr2  = nil 
--    self.base_attr3  = nil 
--    self.base_attr4  = nil 
--    self.base_attr5  = nil 
--    self.base_attr6  = nil 
--    self.base_attr7  = nil 
--    self.base_attr8  = nil 
--    self.zhandouli  = nil
    self.state  = nil 
end

function LServerShenQiList:GetUnitId( ) return self.m_unitid  end
function LServerShenQiList:GetId()  return id end
function LServerShenQiList:GetName()  return name end
function LServerShenQiList:GetGetWay()  return get_rule end
function LServerShenQiList:GetPath()  return getWay end
function LServerShenQiList:GetItemId()  return itemId end
function LServerShenQiList:GetNeedNum()  return needNum end
function LServerShenQiList:GetBaseAttr1() return base_attr1 end
function LServerShenQiList:GetBaseAttr2() return base_attr2 end
function LServerShenQiList:GetBaseAttr3() return base_attr3 end
function LServerShenQiList:GetBaseAttr4() return base_attr4 end
function LServerShenQiList:GetBaseAttr5() return base_attr5 end
function LServerShenQiList:GetBaseAttr6() return base_attr6 end
function LServerShenQiList:GetBaseAttr7() return base_attr7 end
function LServerShenQiList:GetBaseAttr8() return base_attr8 end
function LServerShenQiList:GetZhanDouLi() return zhandouli end
function LServerShenQiList:GetState() return state end

LShenqiStage = {}
LShenqiStage.__index = LShenqiStage
function LShenqiStage:New()
    local o = {}
    setmetatable(o,LShenqiStage )    
    o:Init()
    return o
end

function LShenqiStage:Init( )
    self.allTarget = {}
    self.allUnit = {}
    self.stepTargetWard = false
    self.zhangjie = 0
end

function LShenqiStage:Reset( )
    self.allTarget = {}
    self.allUnit = {}
    self.stepTargetWard = false
    self.zhangjie = 0
end

function LShenqiStage:Delete()
    self.allTarget = nil
    self.allUnit = nil
    self.stepTargetWard = nil
    self.zhangjie = 0
end

LSingleStageTarget = {}
LSingleStageTarget.__index = LSingleStageTarget
function LSingleStageTarget:New()
    local o = {}
    setmetatable(o,LSingleStageTarget )    
    o:Init()
    return o
end

function LSingleStageTarget:Init( )
    self.unitid = -1
    self.targetIDForUnit = -1
    self.senderServerID = -1
    self.TargetName = ""              --目标名称
    self.jiangli = 5                  --哪个奖励？0：金币；1：绑元 2：物品
    self.jinbi = -1
    self.bangyuan = -1
    self.itemID = -1
    self.itemNum = -1
    self.isWancheng = false           --完成
    self.isLingqu = false             --领取
end

function LSingleStageTarget:Delete()
    self.unitid = nil
    self.targetIDForUnit = nil
    self.senderServerID = nil
    self.TargetName = nil
    self.jiangli = nil
    self.jinbi = nil
    self.bangyuan = nil
    self.itemID = nil
    self.itemNum = nil
    self.isWancheng = nil
    self.isLingqu = nil
end

LUnitTarget = {}
LUnitTarget.__index = LUnitTarget
function LUnitTarget:New()
    local o = {}
    setmetatable(o,LUnitTarget )    
    o:Init()
    return o
end

function LUnitTarget:Init( )
    self.unit_id = 0
	self.UnitNumBig = ""
	self.unitName = ""
	self.unit_jiangli = 0  -- 哪个奖励？0：伤害；1：防御 2：气血
	self.shanghai = 0
	self.fangyu = 0
	self.qixue = 0
	self.unit_wancheng = false
	self.unit_lingqu = false
	self.isGensui = false
end

function LUnitTarget:Delete()
    self.unit_id = nil
	self.UnitNumBig = nil
	self.unitName = nil
	self.unit_jiangli = nil
	self.shanghai = nil
	self.fangyu = nil
	self.qixue = nil
	self.unit_wancheng = nil
	self.unit_lingqu = nil
	self.isGensui = nil
end

--[[
    神器培养界面数据（临时存放，关闭面板后释放）
]]
LArtifactUIDataMgr = LDataBase:New()
LArtifactUIDataMgr.__index = LArtifactUIDataMgr
function LArtifactUIDataMgr:Init()
    self.m_UIData = {}
    self.m_UIOtherData = {}
end

function LArtifactUIDataMgr:Free()
    self.m_UIData = {}
    self.m_UIOtherData = {}
end

LArtifactUIDataMgr:Init()



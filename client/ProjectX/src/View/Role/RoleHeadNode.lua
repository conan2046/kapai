--[[
lua里面的游戏逻辑控制
]]
local RoleHeadNode = {}
RoleHeadNode.__index = RoleHeadNode
function RoleHeadNode:New(userData)
	local o = {}
	setmetatable(o,RoleHeadNode)	
    o:Init(userData)
	return o
end


function RoleHeadNode:Init(userData)
    self.m_pNode = cc.CSLoader:createNode("csd/common/toudingxinxi.csb")
    self.m_pNode:setLocalZOrder(100)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pNode:registerScriptHandler(onNodeEvent)
    self:InitData()
    self.m_userData = userData
    self:ShowInfo()
end

function RoleHeadNode:onExit()
    self.m_pNode = nil
end

function RoleHeadNode:SetVisible(isVisible)
    self.m_pNode:setVisible(isVisible)
end

function RoleHeadNode:Reset()
    self.m_nameLabel:setString("")
    self.m_nameLabel:setColor(AppDef.UIColor.WHITE)
    self.m_mySignImg:setVisible(false)
    self.m_jingjieLaebl:setString("")
end

function RoleHeadNode:SetPosition(pos)
    self.m_pNode:setPosition(pos)
end

function RoleHeadNode:InitData()
    self.m_nameLabel = self.m_pNode:getChildByName("Name")
    self.m_jingjieLaebl = self.m_pNode:getChildByName("jingjie")
    self.m_mySignImg = self.m_nameLabel:getChildByName("Own")
end

function RoleHeadNode:ShowInfo()
    self.m_nameLabel:setString(self.m_userData.name)
    if self.m_userData.Id == LRoleDataMgr.MyHeroInfo.id then
        self.m_nameLabel:setColor(cc.c3b(0xff,0xf1,0xaf))
        self.m_mySignImg:setVisible(true)
    else
        self.m_nameLabel:setColor(AppDef.UIColor.WHITE)
        self.m_mySignImg:setVisible(false)
    end
    self.m_jingjieLaebl:setString("")
    local cfg = JsonConfig.m_jingjieConfig.getDefByID(self.m_userData.jingjie)
    if cfg ~= nil then
        self.m_jingjieLaebl:setString(cfg.name)
    end
end

return RoleHeadNode
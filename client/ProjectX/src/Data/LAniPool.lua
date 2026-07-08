--[[
动画文件缓存
]]
LAniPool = {}
LAniPool.__index = LAniPool
LAniPool.MaxAniNum = 20
function LAniPool:New()
	local o = {}
	setmetatable(o,LAniPool)
	o:Init()
	return o
end

function LAniPool:Init()
	self.m_pAniPool = {}
end
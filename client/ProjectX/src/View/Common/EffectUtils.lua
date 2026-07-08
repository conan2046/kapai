LGoldEffect = {}
LGoldEffect.__index = LGoldEffect
function LGoldEffect:new()
    local o = {}
    setmetatable(o,LGoldEffect)
    o:ctor()
    return o
end

function LGoldEffect:ctor()
    self.m_scheduler  = nil
    self.m_effectNode = nil
end

function LGoldEffect:UnSchedule()
	if self.m_scheduler then
		AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
		self.m_scheduler  = nil
	end
end

function LGoldEffect:Ready(node)
	self:UnSchedule()
    if self.m_effectNode == nil then
        self.m_effectNode = cc.Node:create()
        node:addChild(self.m_effectNode)
    end
    self.m_effectNode:removeAllChildren()
end


function LGoldEffect:End()
	self:UnSchedule()
    self.m_playing = false
    if self.m_effectNode ~= nil then
        self.m_effectNode:removeAllChildren()
    end
    self.m_effectNode = nil
end

function LGoldEffect:CoinFlow(node)
    local function ShowEnd(sender)
        sender:removeFromParentAndCleanup(true)
    end

    local function UnLock(dt)
        self:End()
    end
    if node == nil then
        return
    end
    self:Ready(node)
    self.m_playing = true
	--随机建立80个金币
	local GoldImod = nil
	local topDelay = 0
	for i=1,80 do
		topDelay = topDelay + 0.02

		local bottomX = math.random(AppDef.frameSize.width)
		local bottomY = math.random(AppDef.frameSize.height)
        local initHeight = AppDef.frameSize.height+60
        local endPos = Utils:GetRelativePoint(cc.p(1287,156))

		GoldImod = Utils:CreateImod("CopyRes/CopyGold",cc.p(bottomX,initHeight),self.m_effectNode,0.5)
		GoldImod:PlayActionRepeat(0)

		local durTime = (initHeight - bottomY) / 400
		local M1 = cc.MoveTo:create(durTime,cc.p(bottomX,bottomY))
		local M2 = cc.MoveTo:create(0.2,ccp(bottomX,bottomY + 30))
		local M3 = cc.MoveTo:create(0.2,ccp(bottomX,bottomY))
		local M4 = cc.MoveTo:create((endPos.x - bottomX) / 700,cc.p(endPos.x,endPos.y))
        local callfun = cc.CallFunc:create(ShowEnd)

		GoldImod:runAction(CCSequence:create(cc.DelayTime:create(topDelay),M1,M2,M3,cc.DelayTime:create(1),M4,callfun,NULL))
	end

    --self.m_locking = true
    local scheduler =  AppDef.Director:getScheduler()
    --6秒后执行Unlock函数
    self.m_schedulerID = scheduler:scheduleScriptFunc(UnLock,6,false)

	--m_sprTree->setPosition(treePoint);
	--m_sprTree->runAction(CEffectShake::create(1.0f,10));
end

LFlowerEffect = {}
LFlowerEffect.__index = LFlowerEffect
function LFlowerEffect:new()
    local o = {}
    setmetatable(o,LFlowerEffect)
    o:ctor()
    return o
end

function LFlowerEffect:ctor()
    self.m_schedulerID  = nil
    self.m_effectNode = nil
end

function LFlowerEffect:UnSchedule()
	if self.m_schedulerID ~= nil then
		AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
		self.m_schedulerID  = nil
	end
end

function LFlowerEffect:Ready(node)
	self:UnSchedule()
    if self.m_effectNode == nil then
        self.m_effectNode = cc.Node:create()
        node:addChild(self.m_effectNode)
    end
    self.m_effectNode:removeAllChildren()
end


function LFlowerEffect:End()
	self:UnSchedule()
    self.m_playing = false
    if self.m_effectNode ~= nil then
        self.m_effectNode:removeAllChildren()
    end
    self.m_effectNode = nil
end

--[[
花瓣落下
@node      花瓣动画父节点
@vecImages 花瓣资源Table
]]
function LFlowerEffect:Start(node,centerPoint,contentSize,vecImages)
    local function OnTimer(dt)
        for i=1,self.m_count do
            self:FlowerFall()
        end
    end
    if node == nil or #vecImages == 0 then
        return
    end
    self:Ready(node)
    self.m_playing = true
    self.m_effectNode = node
    self.m_vecImages = vecImages
    self.m_centerPoint = centerPoint
    self.m_contentSize = contentSize 
     
    local scheduler =  AppDef.Director:getScheduler()
    --self.m_createSpeed秒后执行OnTimer函数
    self.m_schedulerID = scheduler:scheduleScriptFunc(OnTimer,self.m_createSpeed,false)
end

function LFlowerEffect:FlowerFall()
    local function MoveEnd(sender)
        sender:removeFromParentAndCleanup(true)
    end
    --随机一个图片
    local sprId = math.random(#self.m_vecImages)
	local sprName = self.m_vecImages[sprId]

    --创建新的
    local SakuraSpr = cc.Sprite:create(sprName)	
	if SakuraSpr ~= nil then
        SakuraSpr:setScale(self.m_spriteScale)
		local randomIndex = math.random(math.floor((self.m_contentSize.height - self.m_centerPoint.x) / 20))
        self.m_startPos.x = randomIndex
		local centerPosX = self.m_centerPoint.x + self.m_startPos.x * 20;
		local centerPosY = self.m_centerPoint.y
		self.m_startPos.x = self.m_startPos.x + 1
		if self.m_centerPoint.x + self.m_startPos.x * 20 > self.m_contentSize.height then
			self.m_startPos.x = 1
        end
		SakuraSpr:setPosition(cc.p(centerPosX,centerPosY))
		
        local tempX = self.m_endPos.x - 100
        local bezier = {
            cc.p(tempX,self.m_endPos.y + self.m_contentSize.height / 2),
            cc.p(tempX,self.m_endPos.y + 50),
            cc.p(tempX,0),
        }
		self.m_endPos.x = self.m_endPos.x + self.m_contentSize.width / sprId
		self.m_endPos.y = self.m_endPos.y + self.m_contentSize.height / sprId
		if self.m_endPos.x > self.m_contentSize.width then
			self.m_endPos.x = 0
        end
		if self.m_endPos.y > self.m_contentSize.height / 2 then
			self.m_endPos.y = 0
        end
        local bezierTo = cc.BezierTo:create(self.m_moveTime,bezier)

        local callfun = cc.CallFunc:create(MoveEnd)
		SakuraSpr:runAction(CCSequence:create(bezierTo, callfun, NULL))
		SakuraSpr:runAction(cc.FadeTo:create(self.m_fadeTime,0))
		self.m_effectNode:addChild(SakuraSpr,2)
	end
end


--[[
花瓣下落参数
@createSpeed 创建花瓣的间隔
@scale       花瓣缩放
@fadeTime    透明度变化时间
@moveTime    移动时间
@count       一次创建的花瓣数量
]]
function LFlowerEffect:SetOptions(createSpeed,scale,fadeTime,moveTime,count)
    self.m_createSpeed = createSpeed
    self.m_spriteScale = scale
    self.m_fadeTime = fadeTime
    self.m_moveTime = moveTime
    self.m_count = count --一次出现的花瓣数量
    if self.m_count == nil or self.m_count < 1 then
        self.m_count = 1
    end
    self.m_endPos = cc.p(0,0)
	self.m_startPos = cc.p(1,1)
end


EffectUtils = LDataBase:New()
EffectUtils.__index = EffectUtils

--金币特效初始化
function EffectUtils:GoldEffectInit()
    if self.m_GoldEffect == nil then 
	    self.m_GoldEffect = LGoldEffect:new()
    end
end

--满屏金币动画播放
function EffectUtils:CoinFlow(node)
    self:GoldEffectFree()
    self:GoldEffectInit()
    self.m_GoldEffect:CoinFlow(node)
end

--关闭界面需要调用
function EffectUtils:GoldEffectFree()
    if self.m_GoldEffect ~= nil then 
        self.m_GoldEffect:End()
    end
    self.m_GoldEffect = nil
end

--花瓣动画初始化
function EffectUtils:FlowerEffectInit()
    if self.m_FlowerEffect == nil then 
	    self.m_FlowerEffect = LFlowerEffect:new()
    end
    self.m_FlowerEffect:SetOptions(0.25,0.5,20,10,1)
end

--[[
花瓣动画播放
@node 动画父节点
@centerPoint 花瓣出现位置
@contentSize 花瓣移动范围，满屏为AppDef.frameSize
@vecImages 花瓣资源数组
示例: 
local flowerNames = EffectUtils:GetFlowerFallImage()
EffectUtils:FlowerEffectStart(self.m_pUILayer,Utils:GetRelativePoint(cc.p(0,750)),AppDef.frameSize,flowerNames)
注意点，关闭动画父节点或者需要停止动画的时候，调用FlowerEffectStop
]]
function EffectUtils:FlowerEffectStart(node,centerPoint,contentSize,vecImages)
    self:FlowerEffectInit()
    self.m_FlowerEffect:Start(node,centerPoint,contentSize,vecImages)
end

--花瓣动画停止
function EffectUtils:FlowerEffectStop()
    if self.m_FlowerEffect ~= nil then 
        self.m_FlowerEffect:End()
    end
    self.m_FlowerEffect = nil
end

function EffectUtils:GetFlowerFallImage()
    local vecFlowers = {}
	for i=1,9 do
        table.insert(vecFlowers,"LogUI/huanpai_0"..i..".png")
    end
	return vecFlowers
end


return EffectUtils
-----------------------------------------------------
--              鲜花系统荷花特效
-----------------------------------------------------

local durTime = 6

local HeHuaEffect = {}

function HeHuaEffect:setPriority(Priority)
end

function HeHuaEffect:Init(node)

	self._layer = node

	local lastAct = self._layer:getChildByTag(AppDef.XIANHUA_TAG)
	if lastAct then
		local BiaoBaiEffect = require("View.Social.xianhuapar_biaobai")
		BiaoBaiEffect:ExitAnim()

		lastAct:removeFromParent()
		self:ExitAnim()
	end

	local winSize = AppDef.frameSize
	local widthMax = 960
	local heightMax = 640

	self.mHeYe = cc.Sprite:create("effect/hehua/heye_bg.png")
	self.mHeYe:setPosition(cc.p(winSize.width/2,winSize.height/2))
	self.mHeYe:setCascadeOpacityEnabled(true)
	self._layer:addChild(self.mHeYe, 100, AppDef.XIANHUA_TAG)
	local size = self.mHeYe:getContentSize()
	self.mHeYe:setScaleX(winSize.width/size.width)
	self.mHeYe:setScaleY(winSize.height/size.height)

	self.mFish = {}
	local ltabFishPos = {[1] = {["pos"] = cc.p(widthMax/2-180,heightMax/2-150), ["scale"] = 0.4},[2] = {["pos"] = cc.p(widthMax/2-230,heightMax/2-100),["scale"] = 0.3},[3] = {["pos"] = cc.p(widthMax/2-220,heightMax/2-180), ["scale"] = 0.5}}
	for i = 1, 3 do
		local bat = ImodAnim:create()
		bat:initAnimWithName("effect/hehua/hehua_yu.png","effect/hehua/hehua_yu.ani")
		bat:setPosition(ltabFishPos[i].pos)
		bat:setScale(ltabFishPos[i].scale)
		bat:PlayActionRepeat(0)
		self.mHeYe:addChild(bat,10)
		self.mFish[i] = bat
	end

	self.mHeHua = {}
	local ltabPos = {[1] = {["pos"] = cc.p(200,170), ["scale"] = 0.6},[2] = {["pos"] = cc.p(310,30),["scale"] = 0.5},[3] = {["pos"] = cc.p(590,25), ["scale"] = 0.7},[4] = {["pos"] = cc.p(745,300),["scale"] = 1}}
	for i = 1, #ltabPos do 
		local hehua = cc.Sprite:create("effect/hehua/hehua.png")
		hehua:setPosition(ltabPos[i].pos)
		hehua:setScale(ltabPos[i].scale)
		hehua:setOpacity(0)
		self.mHeYe:addChild(hehua)
		self.mHeHua[i] = hehua
	end

end

function HeHuaEffect:playAction()

	local winSize = AppDef.frameSize
	local widthMax = winSize.width
	local heightMax = winSize.height

	local particleFlower = cc.ParticleSnow:create()
	local pTexture = AppDef.textureCache:addImage("effect/hehua/huaban.png")
	particleFlower:setTexture(pTexture)
	particleFlower:setPosition(cc.p(widthMax/2,heightMax))
	local color = cc.c4f(1.0, 1.0, 10.0, 1.0)
	-- color.r = 1.0
	-- color.g = 1.0
	-- color.b = 10.0
	-- color.a = 1.0
	particleFlower:setStartColor(color)
	particleFlower:setEndColor(color)
	particleFlower:setTotalParticles(200)
	particleFlower:setStartSize(50)
	particleFlower:setStartSizeVar(10)
	particleFlower:setLife(4) 
	particleFlower:setSpeed(120)
	particleFlower:setSpeedVar(20)
	particleFlower:setLifeVar(1)
	particleFlower:setAutoRemoveOnFinish(true)
	self.mHeYe:addChild(particleFlower)

	for i = 1, #self.mFish do
		self.mFish[i]:runAction(cc.MoveBy:create(durTime, cc.p(math.random(300,600),0)))
	end

	local function  hehuacall(node)
		if node then
			local heHuaAction = {}
			table.insert(heHuaAction, CCFadeTo:create(0.5,255))
			table.insert(heHuaAction, cc.DelayTime:create(0.2))
			table.insert(heHuaAction, CCFadeTo:create(0.5,70))

			node:runAction(CCRepeatForever:create(cc.Sequence:create(heHuaAction)))
		end
	end
	for i = 1, #self.mHeHua do
		local actions = {}
		table.insert(actions, cc.DelayTime:create(math.random(0,5)/10))
		table.insert(actions, cc.CallFunc:create(hehuacall))

		-- actions:addObject(cc.DelayTime:create(math.random(0,5)/10))
		-- actions:addObject(cc.CallFunc:create(hehuacall))

		local sprSeq = cc.Sequence:create(actions)
		self.mHeHua[i]:runAction(sprSeq)
	end

	-- local function callback()
	-- 	-- if self.mHeYe then
	-- 	-- 	self.mHeYe:removeFromParent()
	-- 	-- end

	-- 	local lastAct = self._layer:getChildByTag(AppDef.XIANHUA_TAG)
	-- 	if lastAct then
	-- 		lastAct:removeFromParent()
	-- 	end

	-- end
	-- local layerAction = {}
	-- table.insert(layerAction, cc.DelayTime:create(durTime))
	-- table.insert(layerAction, cc.CallFunc:create(callback))
	-- local selfSeq = cc.Sequence:create(layerAction)
	-- self._layer:runAction(selfSeq)

--	self:fadeout(8)

	self:fadeout(4)

end

-- function HeHuaEffect:fadeout(outTime)
-- 	for i = 1, #self.mHeHua do 
-- 		self.mHeHua[i]:stopAllActions()
-- 	end

-- 	self.mHeYe:runAction(CCFadeOut:create(outTime))
-- end

function HeHuaEffect:fadeout(outTime)
	local bg = self._layer:getChildByTag(AppDef.XIANHUA_TAG)
	if bg == nil then
		return
	end

	local function callback()
		bg:removeFromParent()
		self:ExitAnim()
	end

	local function FishCallback()
		local actNode = bg:getChildByTag(1019)
		if actNode then
			for i = 1, #self.mFish do
				if self.mFish[i] then
					self.mFish[i]:removeFromParent()
				end
			end
		end
	end

	local fishLayerAction = {}
	table.insert(fishLayerAction, cc.DelayTime:create(outTime + outTime / 2))
	table.insert(fishLayerAction, cc.CallFunc:create(FishCallback))
	local fishSeq = cc.Sequence:create(fishLayerAction)
	local node = cc.Node:create()
	bg:addChild(node)
	node:runAction(fishSeq)
	node:setTag(1019)

	local layerAction = {}
	table.insert(layerAction, cc.DelayTime:create(outTime))
	table.insert(layerAction, cc.FadeOut:create(outTime))
	table.insert(layerAction, cc.CallFunc:create(callback))
	local selfSeq = cc.Sequence:create(layerAction)
	bg:runAction(selfSeq)
end

function HeHuaEffect:ExitAnim()
	if self.mFish == nil then
		return
	end

	for i = 1, #self.mFish do
		if self.mFish[i] then
			self.mFish[i] = nil
		end
	end
end

return HeHuaEffect
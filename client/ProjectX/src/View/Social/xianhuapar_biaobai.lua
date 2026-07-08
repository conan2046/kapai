-----------------------------------------------------
--              鲜花系统表白特效
-----------------------------------------------------

 local durTime = 6

local BiaoBaiEffect = {}

function BiaoBaiEffect:setPriority(Priority)
end

function BiaoBaiEffect:Init(node)

	self._layer = node

	local lastAct = self._layer:getChildByTag(AppDef.XIANHUA_TAG)
	if lastAct then
		local HehuaEffect = require("View.Social.xianhuapar_hehua")
		HehuaEffect:ExitAnim()

		lastAct:removeFromParent()
		self:ExitAnim()
	end

	local winSize = AppDef.frameSize
	local widthMax = 960
	local heightMax = 640

	local bg = cc.Sprite:create("effect/biaobai/bg.png")
	bg:setPosition(cc.p(winSize.width/2,winSize.height/2))
	bg:setCascadeOpacityEnabled(true)
	self._layer:addChild(bg, 100, 888)

	bg:setTag(AppDef.XIANHUA_TAG)
	local size = bg:getContentSize()
	bg:setScaleX(winSize.width/size.width)
	bg:setScaleY(winSize.height/size.height)

	self.mAiXin =  cc.Sprite:create("effect/biaobai/aixin.png")
	self.mAiXin:setPosition(cc.p(widthMax/2,heightMax/2))
	self.mAiXin:setOpacity(0)
	bg:addChild(self.mAiXin)

	self.mRole = cc.Sprite:create("effect/biaobai/role.png")
	self.mRole:setPosition(cc.p(widthMax/2,heightMax/2))
	self.mRole:setOpacity(0)
	bg:addChild(self.mRole)

	self.mRole:setScaleX(widthMax/size.width)
	self.mRole:setScaleY(heightMax/size.height)

	self.mHuDie = {}
	local ltaPos = {[1] = cc.p(150,400),[2] = cc.p(300,600),[3] = cc.p(600,300)}
	for i = 1, 3 do
		self.mHuDie[i] = cc.Sprite:create(string.format("effect/biaobai/hudie_%d.png",i))
		self.mHuDie[i]:setOpacity(0)
		self.mHuDie[i]:setPosition(ltaPos[i])
		bg:addChild(self.mHuDie[i])
	end

	local ltabEffPos = {[1] = cc.p(360,200),[2] = cc.p(420,300),[3] = cc.p(520,320),[4] = cc.p(600,500),[5] = cc.p(700,460)}
	self.mAniHuDie = {}
	for i = 1, 5 do 
	    local bat = ImodAnim:create()
		bat:initAnimWithName("effect/biaobai/butflay.png","effect/biaobai/butflay.ani")
		bat:setPosition(ltabEffPos[i])
		bat:setScale(2)
		bat:PlayActionRepeat(0)
		bg:addChild(bat,10)
		self.mAniHuDie[i] = bat
	end

	for i = 1, 9 do
		local liuxing =  cc.Sprite:create("effect/biaobai/liuxing.png")
		if i <= 5 then
			liuxing:setPosition(cc.p(widthMax/2+120*(i-1) + 80,heightMax + 80))
		else
			liuxing:setPosition(cc.p(widthMax + 80,heightMax-80*(i-5) +80))
		end
		liuxing:setRotation(-45)
		bg:addChild(liuxing,10)
		liuxing:setTag(50+i)
	end

end

function BiaoBaiEffect:playAction()
	local aiXinAction = {}
	table.insert(aiXinAction, cc.FadeTo:create(0.7,255))
	table.insert(aiXinAction, cc.DelayTime:create(0.3))
	table.insert(aiXinAction, cc.FadeTo:create(0.7,70))

	local aiXinRepeat =  cc.RepeatForever:create(cc.Sequence:create(aiXinAction))
	self.mAiXin:runAction(aiXinRepeat)

	local roleShowAction = {}
	table.insert(roleShowAction, cc.DelayTime:create(0.3))
	table.insert(roleShowAction, cc.FadeTo:create(0.5, 255))
--	local roleSeq = cc.Sequence:createWithTwoActions(cc.DelayTime:create(0.3),cc.FadeTo:create(0.5, 255))
	local roleShowSeq =  cc.Sequence:create(roleShowAction)
	self.mRole:runAction(roleShowSeq)

	for i = 1, 3 do
		local time = math.random(30,100)/100
		local actions = {}
		table.insert(actions, cc.DelayTime:create(time))
		table.insert(actions, cc.FadeTo:create(1, 255))
		table.insert(actions, cc.MoveBy:create(durTime-time-1,cc.p(math.random(-150,150),math.random(-150,150))))

		local sprSeq = cc.Sequence:create(actions)
		self.mHuDie[i]:runAction(sprSeq)
	end

	for i = 1, 5 do
		local aiXinAction = {}
		table.insert(aiXinAction, cc.DelayTime:create(0.3))
		table.insert(aiXinAction, cc.MoveBy:create(durTime,cc.p(math.random(-200,200),math.random(-150,150))))
		local aniHuDieSeq =  cc.Sequence:create(aiXinAction)
--		local aniHuDieSeq = cc.Sequence:createWithTwoActions(cc.DelayTime:create(0.3),cc.MoveBy:create(durTime,cc.p(math.random(-200,200),math.random(-150,150))))
		self.mAniHuDie[i]:runAction(aniHuDieSeq)
	end

	local function liuxingcall(node)
		if node then
			node:removeFromParent()
		end
	end
	local offx = -600
	local offy = -600
	for i = 1, 9 do
		local random = math.random(30,100)/100
		local spr = self._layer:getChildByTag(AppDef.XIANHUA_TAG):getChildByTag(50+i)
		local time = math.random(1,20)/5
		local actions = {}
		table.insert(actions, cc.DelayTime:create(time))
		table.insert(actions, cc.MoveBy:create(1,cc.p(offx*random,offy*random)))
		table.insert(actions, cc.CallFunc:create(liuxingcall))

		local sprSeq = cc.Sequence:create(actions)
		spr:runAction(sprSeq)
	end
	
--渐隐消失
	self:fadeout(4)
end

function BiaoBaiEffect:fadeout(outTime)
	local bg = self._layer:getChildByTag(AppDef.XIANHUA_TAG)
	if bg == nil then
		return
	end

	local function HuDieCallback()
		local actNode = bg:getChildByTag(1018)
		if actNode then
			for i = 1, #self.mAniHuDie do
				if self.mAniHuDie[i] then
					self.mAniHuDie[i]:removeFromParent()
				end
			end
		end
		
	end

	local huDieLayerAction = {}

	table.insert(huDieLayerAction, cc.DelayTime:create(outTime + 1))
	table.insert(huDieLayerAction, cc.CallFunc:create(HuDieCallback))
	local fishSeq = cc.Sequence:create(huDieLayerAction)
	local node = cc.Node:create()
	bg:addChild(node)
	node:runAction(fishSeq)
	node:setTag(1018)

	local function callback()
		bg:removeFromParent()
		self:ExitAnim()
	end	
	local layerAction = {}
	table.insert(layerAction, cc.DelayTime:create(outTime))
	table.insert(layerAction, cc.FadeTo:create(outTime, 0))
	table.insert(layerAction, cc.CallFunc:create(callback))
	local selfSeq = cc.Sequence:create(layerAction)
	bg:runAction(selfSeq)
end

function BiaoBaiEffect:ExitAnim()

	if self.mAniHuDie == nil then
		return
	end

	for i = 1, #self.mAniHuDie do
		if self.mAniHuDie[i] then
			self.mAniHuDie[i] = nil
		end
	end

end

return BiaoBaiEffect
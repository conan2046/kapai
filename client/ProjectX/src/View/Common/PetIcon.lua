PetIcon = class("PetIcon", cc.Sprite)
PetIcon.__index = PetIcon

function PetIcon:ctor(...)
	local function onNodeEvent(eventName)  
        if "enter" == eventName then 
            self:onEnter() 
        elseif "exit" == eventName then  
            self:onExit()
        elseif "cleanup" == eventName then
            self:onCleanup()
        end  
    end
    self:registerScriptHandler(onNodeEvent) 
    
    self:init(...)
end

function PetIcon:setTouchCallback(cb)
	self.m_touchCallback = cb
end

function PetIcon:init(...)
	self.m_id,self.m_canTouch,self.m_touchCallback = ...
	self.canClick = true
	self.m_touchBeginPos = nil

	if self.m_id then
		self:updateTexture()
	end
	if self.m_canTouch then
		self:initTouch()
	end
end

function PetIcon:initTouch()
	local listenner = cc.EventListenerTouchOneByOne:create()
	listenner:setSwallowTouches(false)
	listenner:registerScriptHandler(function(pTouch, pEvent)
		self.canClick = true
		self.m_touchBeginPos = pTouch:getLocation()

		local pos = self:convertToNodeSpace(self.m_touchBeginPos)
		local rect = cc.rect(0, 0, self:getContentSize().width, self:getContentSize().height)
		return cc.rectContainsPoint(rect, pos)
	end, cc.Handler.EVENT_TOUCH_BEGAN)

	listenner:registerScriptHandler(function(pTouch, pEvent)
		if self.canClick then
			local pos = pTouch:getLocation()
			if cc.pGetDistance(self.m_touchBeginPos, pos) > 10 then
				self.canClick = false
			end
		end
	end, cc.Handler.EVENT_TOUCH_MOVED)

	listenner:registerScriptHandler(function(pTouch, pEvent)
		if self.canClick then
			if self.m_touchCallback then
				self.m_touchCallback(self.m_id)
			else
				self:touchIcon()
			end
		end
	end, cc.Handler.EVENT_TOUCH_ENDED)

	listenner:registerScriptHandler(function(pTouch, pEvent)end, cc.Handler.EVENT_TOUCH_CANCELLED)

	local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listenner, self)
end

function PetIcon:onEnter()
end

function PetIcon:onExit()
end

function PetIcon:onCleanup()
end

function PetIcon:updateData(id)
	self.m_id = id
	self:updateTexture()
end

function PetIcon:updateTexture()
	local size = self:getContentSize()
	local pic = LPetDataMgr:FindPetDataById(self.m_id).pic
	local file = Utils:GetMonsterIconRes(pic, AppDef.HeadIconResType.Square)
	local succ = self:initWithFile(file)
	self:setVisible(succ)
	self:setContentSize(size)
end

function PetIcon:touchIcon()
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {self.m_id})
	LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

return PetIcon
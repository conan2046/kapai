local FubenDetailMap = {}
FubenDetailMap.__index = FubenDetailMap

--local this = LTcpSocket
function FubenDetailMap:New(stageData, mapNode)
	local o = LUIBase:New()
	setmetatable(o,FubenDetailMap)	
    o:Init(stageData, mapNode)
	return o
end


--注册事件
-- -----------------------------------
function FubenDetailMap:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     LUIFuBenMapEvent.refrashStageMapUI,
    --     LUILogicEvent.EnterBattle,
    --     LUILogicEvent.ExitBattle,
    --     LUIFuBenMapEvent.refrashUIAfterFight,
    --     LUIFuBenMapEvent.getBoxAwardSuc,
    --     LUIFuBenMapEvent.resetFightTimesSuc,
    --     LUIRoleDataChangeEvent.MoneyChanged,
    --     LUIRoleDataChangeEvent.TongBaoChanged,
    --     LUIRoleDataChangeEvent.TiliChanged,
    --     LUILogicEvent.PlotChatOver,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FubenDetailMap:ProcessEvent(msg)
    
end

function FubenDetailMap:Init(stageData, mapNode)

    self.m_pUILayer = mapNode;
    self._stageData = stageData;
    self._mapResArr = {}
	local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:LoadMap()
end

function FubenDetailMap:onExit()
	self.m_pUILayer:removeAllChildren()
	for i = 1, #self._mapResArr do
		display.removeImage(self._mapResArr[i])
	end
	self._mapResArr = nil
	self._stageData = nil
	
end

function FubenDetailMap:LoadMap()
	local nodePosConfig = JsonConfig.m_mapRes.getDefByID(self._stageData.BundleId)

	local size = nodePosConfig.map_size[1];
	-- dump(size,"size")
	self.m_pUILayer:setContentSize(cc.size(size[1],size[2]));

	local xNum = math.ceil(size[1] / 1024);
	local yNum = math.ceil(size[2] / 1024);

	local startPosx = 0;
	local startPosy = size[2];

	local mapPath = string.format("fuben/%s/map_", nodePosConfig.name)
	local cnt = 1
	for j = 1,yNum do
		for i = 1,xNum do
			local resName = mapPath .. cnt .. ".jpg";
			-- print("resName",resName)
			table.insert(self._mapResArr,resName);
			local sp = cc.Sprite:create();
			sp:initWithFile(resName)
			sp:setAnchorPoint(cc.p(0, 1));
			sp:setPosition(cc.p(startPosx,startPosy));
			cnt = cnt + 1;
			startPosx = startPosx + 1024;
			self.m_pUILayer:addChild(sp)
		end
		startPosx = 0
		startPosy = startPosy - 1024
	end
end

return FubenDetailMap
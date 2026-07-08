--[[
英勇试炼自动寻找NCP战斗
]]
local AutoPlayShiLian = LUIBase:New()
AutoPlayShiLian.__index = AutoPlayShiLian

function AutoPlayShiLian:New()
	local o = LUIBase:New()
	setmetatable(o, AutoPlayShiLian)	
    o:Init()
	return o
end

--[[
注册消息
]]
function AutoPlayShiLian:RegistMsgs()
    self.msgIds = 
    {
        LUIMapEvent.ChangeMapSuccess,
        LUIActivityEvent.closeFanPai,
    }
    self:RegistSelf(self,self.msgIds)
end

function AutoPlayShiLian:ProcessEvent(msg)
    if msg.msgId == LUIMapEvent.ChangeMapSuccess then
        -- print("ChangeMapSuccess =========>", msg.value)
        --不用点击自动寻路
        -- if msg.value == GUITips.RSI_YINGYONGSHILIAN_TIPS_5 then
        --     performWithDelay(AppDef.CurScene, function(sender)
        --         self:handleAutoPlay(msg.value)
        --     end, 1)
        -- end
    elseif msg.msgId == LUIActivityEvent.closeFanPai then
        self:handleAutoPlay(msg.value)
    end
end

function AutoPlayShiLian:Init()
    self:RegistMsgs()
    self:loadData()
end


function AutoPlayShiLian:loadData()
    self._npcId = 0    
end

function AutoPlayShiLian:handleAutoPlay( mapName )
    -- body
    local function GetCurMapCallback(npclist,monsterlist,gatelist,gateNameList,mapSize,heroNode)
        self.m_pNPCList = npclist
        local npcLength = #self.m_pNPCList
--        print("NPC个数", npcLength)
        if npcLength > 0 then
            self._npcId = self.m_pNPCList[1]:GetId()
--            print("handleAutoPlay 22222222222222", self._npcId)
            self:execAutoPlayEvent()
        end
    end
    local msg = GetMapChildMsg:new(CEnum.MapEvent.LuaGetCurMapObjData,GetCurMapCallback)
    self:SendMsg(msg)
end

function AutoPlayShiLian:execAutoPlayEvent( ... )
    -- body
    self:autoPathToShiLian()
end

function AutoPlayShiLian:autoPathToShiLian( ... )
    -- body
    LRoleDataMgr:autoPathToShiLian(174, self._npcId)
end

return AutoPlayShiLian


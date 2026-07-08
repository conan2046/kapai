--[[
负责每个消息模块的转发
消息路由
]]

LMsgCenter = {}
LMsgCenter.__index = LMsgCenter
function LMsgCenter.New()
	local o = {}
	setmetatable(o,LMsgCenter)
	
	return o
end

function LMsgCenter:Awake()
	--print("LMsgCenter:Awake")
	self.msgCenter = MsgCenter:GetInstance()
	local function handleMsg(fromNet, arg0, arg1, arg2)
		self:RecvMsg(fromNet, arg0, arg1, arg2)
	end
	LuaAndCMsgCenters:GetInstance():SettingLuaCallBack(handleMsg)
end




--[[
]]
function LMsgCenter:RecvMsg(fromNet, arg0, arg1, arg2)
	if fromNet == true then--网络消息
		--[[
		arg0 == msgid
		arg1 == state
		arg2 == LuaByteBuffer
		]]
		local tmpMsg = LMsgBase:New(arg0)
		tmpMsg.state = arg1
		tmpMsg.date = arg2
		self:AnasysisMsg(tmpMsg)
	else
		--[[
		arg0 == C#里面的msg类
		后面没有数据了
		]]
		self:AnasysisMsg(arg0)
	end
end

function LMsgCenter:SendToMsg(tmpMsg)
	--print("LMsgCenter:SendToMsg")
	--print(tmpMsg)
    self:AnasysisMsg(tmpMsg)
end


function LMsgCenter:AnasysisMsg(tmpMsg)
	--print("LMsgCenter:AnasysisMsg")
    local tmpId = tmpMsg:GetManager()
    --print(tmpId,LManagerID.LGameManager)
    if tmpId == LManagerID.LAssetManager then
    	--print("LAssetManager:ProcessEvent")
    	LAssetManager:ProcessEvent(tmpMsg)
	elseif tmpId == LManagerID.LAudioManager then
		LAudioManager:ProcessEvent(tmpMsg)
	elseif tmpId == LManagerID.LCharactorManager then
	elseif tmpId == LManagerID.LGameManager then
		LGameManager:ProcessEvent(tmpMsg)
	elseif tmpId == LManagerID.LDataManager then
		LDataManager:ProcessEvent(tmpMsg)
	elseif tmpId == LManagerID.LNetManager then
		--print("LNetManager:ProcessEvent")

    	LNetManager:ProcessEvent(tmpMsg)
	elseif tmpId == LManagerID.LNPCManager then
	elseif tmpId == LManagerID.LUIManager then
		LUIManager:ProcessEvent(tmpMsg)
	--elseif tmpId == LManagerID.LUIManagerTwo then
	else
		--这部分要转发给C#
		self.msgCenter:SendToMsg(tmpMsg)
	end
end
LMsgCenter:Awake()
--[[
所有的网络消息号全部在这里
]]
local lNetMsg = LManagerID.LNetManager
LTCPEvent = 
{
    LoginConnect = lNetMsg + 1,
    LoginDisConnect = lNetMsg + 2,
    LoginSendMsg = lNetMsg + 3,
    GameConnect = lNetMsg + 4,
    GameDisConnect = lNetMsg + 5,
    GameSendMsg = lNetMsg + 6,
    RecvMsg = lNetMsg + 7,
    RecvSession = lNetMsg + 8,
    MaxValue = lNetMsg + 9
}
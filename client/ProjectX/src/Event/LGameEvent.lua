local lGameMsg = LManagerID.LGameManager
local function MsgIdAdd()
    lGameMsg = lGameMsg + 1
    return lGameMsg
end
LGameNetEvent = 
{
    TcpLoginBack = MsgIdAdd(),
    TcpGameBack = MsgIdAdd(),
    TcpLineUpBack = MsgIdAdd(),
    ConfigDataLoadFinish = MsgIdAdd(),
    TCPSelectedGameServer = MsgIdAdd(),
    MaxValue = MsgIdAdd(),
}

LGameEvent = 
{
    LogoutFromSDK = MsgIdAdd(),
    EnterGame = MsgIdAdd(),
    ChangeMap = MsgIdAdd(),
    ChangeMapSuccess = MsgIdAdd(),
    ChangeUser = MsgIdAdd(),--游戏内切换用户
    EnterBattle = MsgIdAdd(),
    ExitBattle = MsgIdAdd(),
    EnterBattleWatch = MsgIdAdd(),
    MaxValue = MsgIdAdd(),
    EnterBackGround = MsgIdAdd(),
    EnterForeground = MsgIdAdd(),
    RegisterExitBattleCb = MsgIdAdd(),--注册结束战斗回调
    CrossServer = MsgIdAdd(),--跨服
    ChangeServer = MsgIdAdd(),--切换服务器
}

LBattleEvent = 
{
    InitBattle = MsgIdAdd(),
    RecvEnterBattle = MsgIdAdd(),
    RecvEnterBattleReplay = MsgIdAdd(),
    RecvBattleWatch = MsgIdAdd(),
    RecvDoBattle = MsgIdAdd(),
    RecvJumpBattle = MsgIdAdd(),
    RecvBattleOver = MsgIdAdd(),
    BreakBattle = MsgIdAdd(),--中断战斗
    SocketClosed = MsgIdAdd(),--中断战斗
    UseSkill = MsgIdAdd(),--使用技能
    JumpBattle = MsgIdAdd(),--跳过战斗
    AutoBattle = MsgIdAdd(),--自动战斗
    RunAway = MsgIdAdd(),--逃跑
    UpdateSpeed = MsgIdAdd(),--更新战斗速度
    UpdateFightHP = MsgIdAdd(),--更新血条
}

LPlantEvent = 
{
    PlantEvent = MsgIdAdd(),
}

--[[
lua代码的消息定义
消息号和C#版本一模一样
]]
MsgSpan = 3000;
LManagerID = 
{
	--Lua命令号
    LuaManager = 0,
    LUIManager = MsgSpan * 1,
    LNetManager = MsgSpan * 2,
    LNPCManager = MsgSpan * 3,
    LCharactorManager = MsgSpan * 4,
    LAssetManager = MsgSpan * 5,
    LGameManager = MsgSpan * 6,
    LDataManager = MsgSpan * 7,
    LAudioManager = MsgSpan * 8,
    LUIManagerTwo = MsgSpan * 9,

    --C#的命令号
    UIManager = MsgSpan * 12,
    NetManager = MsgSpan * 13,
    NPCManager = MsgSpan * 14,
    CharactorManager = MsgSpan * 15,
    AssetManager = MsgSpan * 16,
    GameManager = MsgSpan * 17,
    DataManager = MsgSpan * 18,
    AudioManager = MsgSpan * 19,
    UIManagerTwo = MsgSpan * 20,
}

CEnum = {}
local lNetMsg = LManagerID.NetManager
CEnum.TCPEvent =
{
    TcpLoginConnect = lNetMsg + 1,
    TcpLoginSendMsg = lNetMsg + 2,
    TcpLoginDisConnect = lNetMsg + 3,
    TcpGameConnect = lNetMsg + 4,
    TcpGameSendMsg = lNetMsg + 5,
    TcpGameDisConnect = lNetMsg + 6,
    TcpGamePauseHandleMsg = lNetMsg + 7,
    TcpGameStartHandleMsg = lNetMsg + 8,
    MaxValue = lNetMsg + 9
}
lNetMsg = CEnum.TCPEvent.MaxValue
CEnum.TCPRecvdEvent = 
{
    HandleMsg = lNetMsg + 1,--处理接受的消息
    RegisterMsg = lNetMsg + 2,--注册接受的消息
    MaxValue = lNetMsg + 3
}


--游戏的网络信息
local lGameMsg = LManagerID.GameManager
local ind = 0
local function MsgIdAdd()
    ind = ind + 1
    return ind
end
CEnum.GameNetEvent = 
{
    TcpLoginConnectSuccess = lGameMsg + MsgIdAdd(),
    TcpLoginConnectError = lGameMsg + MsgIdAdd(),
    TcpLoginConnectLost = lGameMsg + MsgIdAdd(),
    TcpGameConnectSuccess = lGameMsg + MsgIdAdd(),
    TcpGameConnectError = lGameMsg + MsgIdAdd(),
    TcpGameConnectLost = lGameMsg + MsgIdAdd(),
    MaxValue = lGameMsg + MsgIdAdd(),
}

--游戏摄像头消息
--lGameMsg = CEnum.GameNetEvent.MaxValue
CEnum.GameCarmeraEvent = 
{
    SetLookTarget = lGameMsg + MsgIdAdd(),
    StartLookTarget = lGameMsg + MsgIdAdd(),
    StopLookTarget = lGameMsg + MsgIdAdd(),

    EnterBattle = lGameMsg + MsgIdAdd(),
    ExitBattle = lGameMsg + MsgIdAdd(),
    CarmeraEffect = lGameMsg + MsgIdAdd(),
    CarmeraStartEffect = lGameMsg + MsgIdAdd(),
    CarmeraShake = lGameMsg + MsgIdAdd(),
    MaxValue = lGameMsg + MsgIdAdd(),
}

--游戏逻辑消息
--lGameMsg = CEnum.GameCarmeraEvent.MaxValue
CEnum.GameLogicEvent = 
{
    EnterScene = lGameMsg + MsgIdAdd(),--第一次进入场景
    ChangeScene = lGameMsg + MsgIdAdd(),
    ChangeSceneSuccess = lGameMsg + MsgIdAdd(),
    ChangeUser = lGameMsg + MsgIdAdd(),--游戏内切换用户
    SetLuaEvts = lGameMsg + MsgIdAdd(),
    EnterBattle = lGameMsg + MsgIdAdd(),
    ExitBattle = lGameMsg + MsgIdAdd(),
    EnterCrossServer = lGameMsg + MsgIdAdd(),
    QuitCrossServer = lGameMsg + MsgIdAdd(),
    MaxValue = lGameMsg + MsgIdAdd(),
}


-- <summary>
-- 寻路事件
-- </summary>
lGameMsg = LManagerID.NPCManager
local function MsgIdAdd()
    lGameMsg = lGameMsg + 1
    return lGameMsg
end
CEnum.AutoPathEvent = 
{
    Init = MsgIdAdd(),
    StartAutoPath = MsgIdAdd(),
    StopAutoPath = MsgIdAdd(),
    PauseAutoPath = MsgIdAdd(),
    ReStartAutoPath = MsgIdAdd(),
    MaxValue = MsgIdAdd(),
}

--[[
挂机事件
]]
CEnum.HangUpEvent = 
{
    StartHangUp = MsgIdAdd(),--开始挂机
    StopHangUp = MsgIdAdd(),--结束挂机
    StopHangUpByTaskId = MsgIdAdd(),--根据任务id来判断是不是结束挂机
    MaxValue = MsgIdAdd(),
}

-- <summary>
-- 玩家事件
-- </summary>
CEnum.RoleEvent = 
{
    Init = MsgIdAdd(),--检查初始化是否完成
    SetJingJie = MsgIdAdd(),
    CameraUpdate = MsgIdAdd(),
    StopMove = MsgIdAdd(),--停止移动 = MsgIdAdd(),停止移动的回调继续处理
    BreakMove = MsgIdAdd(),--打断移动，停止移动的回调不继续处理
    MoveEnd = MsgIdAdd(),--正常寻路结束
    AutoPath = MsgIdAdd(),--自动寻路
    ModelChanged = MsgIdAdd(),--模型数据改变
    ConvoyDataChanged = MsgIdAdd(),--护送押镖数据变化
    ShowAutoPathAni = MsgIdAdd(),--显示自动寻路动画
    HideAutoPathAni = MsgIdAdd(),--隐藏自动寻路动画
    ShowGuajiAni = MsgIdAdd(),--显示挂机动画
    HideGuajiAni = MsgIdAdd(),--隐藏挂机动画
    LuaUIInitUtil = MsgIdAdd(),--lua传过来显示地图名字和人物位置的GameObj
    LuaEvts = MsgIdAdd(),
    LuaSetFactionInfo = MsgIdAdd(),
    LuaSetVip = MsgIdAdd(),
    LuaSetSkills = MsgIdAdd(),
    LuaSetTitle = MsgIdAdd(),--设置称号
    LvUp = MsgIdAdd(),--升级
    JumpPos = MsgIdAdd(),--通场景跳转
    MaxValue = MsgIdAdd(),
}

CEnum.MapEvent = 
{
    Init = MsgIdAdd(),--
    EnterBattle = MsgIdAdd(),
    ExitBattle = MsgIdAdd(),
    ChangeUser = MsgIdAdd(),
    ChangeMap = MsgIdAdd(),
    LoadDataSucess = MsgIdAdd(),
    LuaGetCurMapObjData = MsgIdAdd(),
    LuaGetMapHeros = MsgIdAdd(),
    LuaGetFactionPlantData = MsgIdAdd(),
    LuaSceneSetting = MsgIdAdd(),--场景优化设置，比如屏蔽玩家之类
    GetGatePosition = MsgIdAdd(),--获取传送点左边列表
    GetNpcDataByPos = MsgIdAdd(),--根据位置获取npc数据
    MaxValue = MsgIdAdd()
}

local lDataMsg = LManagerID.LDataManager
LDataServerEvent = 
{
    InitServerList = lDataMsg + 1,
    GetData = lDataMsg + 2,--获取数据
    InitRoleServerList = lDataMsg + 3,--获取数据
    MaxValue = lDataMsg + 4,
}

lDataMsg = LDataServerEvent.MaxValue
LDataRoleEvent = 
{
    InitRoleData = lDataMsg + 1,
    InitRoleNode = lDataMsg + 2,
    MaxValue = lDataMsg + 5,
}

lDataMsg = LDataRoleEvent.MaxValue
--伙伴类数据与服务器通信
LDataPartnerEvent = 
{
	GetPartnerMsgData = lDataMsg + 1,--伙伴相关信息的消息数据
	GetUpdatePartnerMsgData = lDataMsg + 2,--服务器更新伙伴消息数据
	RecvPartnerListData = lDataMsg + 3,
	MaxValue = lDataMsg + 5,
}

lDataMsg = LDataPartnerEvent.MaxValue
--宠物信息数据与服务器通信
LDataPetEvent = 
{
    GetPetMsgData = lDataMsg + 1,--宠物相关信息的消息数据
    UpdatePetMsgData = lDataMsg + 2,--更新宠物数据
    MaxValue = lDataMsg + 5,
}

lDataMsg = LDataPetEvent.MaxValue
--任务数据与服务器通信
LDataTaskEvent = 
{
    RecvTaskList = lDataMsg + 1,--任务列表数据
    RecvOneTask = lDataMsg + 2,--一个任务详细描述
    RecvUpdateTask = lDataMsg + 3,--添加删除更新一个任务
    RecvTaskJinDu = lDataMsg + 4,--任务的进度
    MaxValue = lDataMsg + 5,
}

lDataMsg = LDataTaskEvent.MaxValue
--帮派数据与服务器通信
LDataBangPaiEvent = 
{
    GetBangPaiMsgData = lDataMsg + 1,--帮派消息数据
    MaxValue = lDataMsg + 5,
}

lDataMsg = LDataBangPaiEvent.MaxValue
--结拜数据与服务器通信
LDataJieBaiEvent = 
{
    GetJieBaiMsgData = lDataMsg + 1,--结拜消息数据
    ShowInputJieBaiMsg = lDataMsg + 2,
    MaxValue = lDataMsg + 5,
}


-- --[[
-- 游戏里面常用到的消息集合
-- ]]
LGameMsg = {}
LGameMsg.m_baseMsg = LMsgBase:New()
LGameMsg.m_tcpMsg = LTcpConnectMsg:New()
-- --LGameMsg.m_pUIPrefabMsg = LAssetMsg:New(LAssetEvent.GetRes)--默认的资源加载消息
LGameMsg.m_initUIMsg = LUIInitMsg:New(LUILogicEvent.InitUI, 0)--一个UI初始化的消息
LGameMsg.m_deleteUIMsg = LUIInitMsg:New(LUILogicEvent.InitUI, 0)--一个UI初始化的消息
LGameMsg.m_hideUIMsg = LUIInitMsg:New(LUILogicEvent.InitUI, 0)--一个UI初始化的消息

LGameMsg.m_scrollTipsMsg = LUIScrollTipsMsg:New(LUIScrollTipsEvent.ShowTips)--上浮滚动提示消息
LGameMsg.m_floatTipsMsg = LUIFloatNoticeMsg:New(LUIFloatNoticeEvent.ShowTips)--走马灯(底部)
LGameMsg.m_loadingProgressMsg = LUILoadingProgressMsg:New(LUILoadingEvt.ShowLoadingProcess, 0)--loading界面进度条

--通用带一个参数的消息
LGameMsg.m_baseMsgWithOne = LUIMsg1.New(LUILogicEvent.InitUI)
--通用带二个参数的消息
LGameMsg.m_baseMsgTwo = LUIMsgTwo.New(LUILogicEvent.InitUI)

--通用音效消息
LGameMsg.m_audioMsg = LUIMsg1.New(LUILogicEvent.InitUI)

--通用Net通知UI消息
LGameMsg.m_netDealMsg = LUIMsg1.New(LUILogicEvent.InitUI)
LGameMsg.m_netDealBaseMsg = LMsgBase.New(LUILogicEvent.InitUI)
--通知C++寻路
LGameMsg.m_autoPathMsg = AutoPathMsg:new()
LGameMsg.m_autoPathMsg:retain()
--C++的基础消息
LGameMsg.m_cBaseMsg = MsgBase:new()
LGameMsg.m_cBaseMsg:retain()

--通知C++挂机消息
LGameMsg.m_hangUpMsg = HangUpMsg:new()
LGameMsg.m_hangUpMsg:retain()

--资源加载消息
LGameMsg.m_resMsg = LResMsg:New()


-- LGameMsg.m_PersonJingjiMsg = LUIPersonalJingjiMsg:New(LUIPerSonalJingjiEvent.ShowList)--个人竞技场

-- LGameMsg.m_baseMsg = LMsgBase:New()--
-- LGameMsg.m_netStreamMsg = LAnalysisNetStreamMsg:New(LDataServerEvent.InitServerList)--服务器列表初始化的消息结构
-- LGameMsg.m_serverDataGetMsg = LServerGetDataMsg:New(LDataServerEvent.GetData)
-- LGameMsg.m_sdateGetBackMsg = LServerGetDataBackMsg:New()

-- LGameMsg.m_sessionMsg = LTcpSessionMsg:New()--用户的openid和opensession数据

-- LGameMsg.m_deleteHeadUIMsg = LUIHeadUIDeleteMsg:New(LUIHeadEvent.Delete)--通用头像删除的消息
-- LGameMsg.m_deleteCommonUIMsg = LUICommonUIDeleteMsg:New(LUICommonUIEvent.Delete)--通用技能icon删除的消息
-- LGameMsg.m_deleteSkillUIMsg = LUISkillUIDeleteMsg:New(LUISkillEvent.Delete)--通用技能icon删除的消息
-- LGameMsg.m_deleteMessageBoxUIMsg = LUIMessageBoxUIDeleteMsg:New(LUIMessageBoxEvent.Delete)--通用头像删除的消息

-- LGameMsg.m_recvChatDataMsg = LUIRecvChatMsg:New(LUIChatEvent.RecvUIChatMessage)--接收到聊天信息

-- --伙伴
-- LGameMsg.m_partnerStreamMsg = LAnalysisNetStreamMsg:New(LDataPartnerEvent.GetPartnerMsgData)
-- LGameMsg.m_partnerdateGetBackMsg = LPartnerGetDataBackMsg:New()

-- --宠物
-- LGameMsg.m_petStreamMsg = LAnalysisNetStreamMsg:New(LDataPetEvent.GetPetMsgData)

-- --结拜
-- LGameMsg.m_jieBaiStreamMsg = LAnalysisNetStreamMsg:New(LDataJieBaiEvent.GetJieBaiMsgData)

-- --帮派
-- LGameMsg.m_bangpaiStreamMsg = LAnalysisNetStreamMsg:New(LDataBangPaiEvent.GetBangPaiMsgData)
-- LGameMsg.m_bangpaiUIMsg = LUIBangPaiUIMsg:New(LUIBangPaiEvent.ShowBangPaiList)

-- --任务
-- LGameMsg.m_taskStreamMsg = LTaskGetDataMsg:New(LDataTaskEvent.RecvTaskList)

-- --角色界面
-- LGameMsg.m_roleInfoUpdateAllMsg = LUIRoleVUpdateAllMsg:New(LUIRoleInfoEvent.UpdateAllRoleInfo)
-- LGameMsg.m_roleInfoUpdateAddAttrMsg = LUIRoleVUpdateAddAttrMsg:New(LUIRoleInfoEvent.UpdateAddAttribute)
-- LGameMsg.m_roleInfoUpdateSkill = LUIRoleVUpdateSkillMsg:New(LUIRoleInfoEvent.UpdateSkill)
-- LGameMsg.m_roleInfoUpdateLifeSkill = LUIRoleVUpdateLifeSkillMsg:New(LUIRoleInfoEvent.UpdataLifeSkillPanel)

-- --主界面
-- LGameMsg.m_mainViewUIMsg = LUIMainViewUIMsg:New(LUIMainViewUIEvent.ShowOneTask)

-- --通知C#寻路
-- LGameMsg.m_autoPathMsg = AutoPathMsg.New()

-- --ItemUI消息
-- LGameMsg.m_itemUIMsg = LUIItemUIMsg:New(LUIItemUIEvent.Init)

-- --HelpUI消息
-- LGameMsg.m_HelpUIMsg = LUIHelpTipsUIMsg:New(LUIHelpTipsUIEvent.Update)

-- --ItemTipsUI消息,更新消息
-- LGameMsg.m_ItemTipsUIMsg = LUIItemTipsUIMsg:New(LUIItemTipsUIEvent.Update)

-- --背包消息
-- LGameMsg.m_PackViewUIMsg = LUIPackViewUIMsg:New(LUIPackViewUIEvent.Init)
-- LGameMsg.m_PackFashionViewUIMsg = LUIPackFashionViewUIMsg:New(LUIPackViewUIEvent.UpdateFashionModel)

-- --活动消息
-- LGameMsg.m_ActivityUIMsg = LUIActivityUIMsg:New(LUIActivityUIEvent.UpdateDoubleExcStyle)
-- LGameMsg.m_ActivityUpdateUIMsg = LUIActivityUpdateUIMsg:New(LUIActivityUIEvent.UpdateAllNMActBtn)

-- --战斗消息
-- LGameMsg.m_BattleSetMsg = BTSetActionMsg.New()
-- LGameMsg.m_BattleLuaMsg = LUIBattleUIMsg.New(LUIBattleUIEvent.OutAutoBattle)
-- LGameMsg.m_AutoBattleSetMsg = BTAutoActionMsg.New()

-- --好友界面消息
-- LGameMsg.m_FriendsMsg = LUIFriendsUIMsg.New(LUIFriendsUIEvent.Init)

-- --角色操作消息
-- LGameMsg.m_PlayerOperationMsg = LUIPlayerOperationMsg.New(LUIPlayerOperationEvent.Update)

-- --通用面板消息
-- LGameMsg.m_CommonMenuMsg = LUICommonMenuUIMsg.New(LUICommonMenuUIEvent.SetMenus)
-- --宠物面板
-- LGameMsg.m_PetMainPanelMsg = LUIPetMainUIMsg.New(LUIPetOperationEvent.ChangeName)
-- --对话消息
-- LGameMsg.m_DialogMsg = LUIDialogUIMsg.New(LUIDialogUIEvent.Update)

-- --通用带一个参数的消息
-- LGameMsg.m_baseMsgWithOne = LUIMsg1.New(LUIDialogUIEvent.Update)
-- --通用带二个参数的消息
-- LGameMsg.m_baseMsgTwo = LUIMsgTwo.New(LUIDialogUIEvent.Update)

-- --通用带一个参数的消息
-- LGameMsg.m_OptionUI = OptionUIMsg:New(OptionUIEvent.UpdateList)

-- --通用选择使用道具接口
-- LGameMsg.m_ItemChoiceUI = LUIItemChoiceUIMsg:New()

-- --宠物面板
-- LGameMsg.m_ShenQiPanelMsg = LUIMsgTwo.New(LUIShenQiEvent.OpenTab)

-- --装备面板
-- LGameMsg.m_EquipUIMsg = LUIEquipUI:New(LUIEquipUIEvent.UpdateChongZhu)

-- --聊天相关
-- LGameMsg.m_chatInputMsg = LUIChatInputMsg:New(LUIEquipUIEvent.UpdateChongZhu)

-- --商城相关 
-- LGameMsg.m_mallMsg = LUIMallMsg:New(LUIMallEvent.SaveQZYBData)

-- -----------------C#wrap过来的消息
-- LGameMsg.m_pCWrapBaseMsg = MsgBase.New(0)
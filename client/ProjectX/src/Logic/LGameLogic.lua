--[[
lua里面的游戏逻辑控制
]]

LGameLogic = LGameBase:New()
LGameLogic.__index = LGameLogic
--local this = LTcpSocket
function LGameLogic:New()
	local o = LUIBase:New()
	setmetatable(o,LGameLogic)
	o:Init()
	return o
end

function LGameLogic:Init()
	
	self.msgIds = 
	{
		LGameNetEvent.TcpLoginBack,
	    LGameNetEvent.TcpGameBack,
	    LGameNetEvent.TcpLineUpBack,
	    LGameNetEvent.ConfigDataLoadFinish,
	    LGameNetEvent.TCPSelectedGameServer,
        LGameEvent.LogoutFromSDK,
	    LGameEvent.EnterGame,
	    LGameEvent.ChangeMap,
	    LGameEvent.ChangeMapSuccess,
	    LGameEvent.ChangeUser,
	    LGameEvent.EnterBattle,
	    LGameEvent.EnterBattleWatch,
    	LGameEvent.ExitBattle,
    	LGameEvent.EnterBackGround,
        LGameEvent.EnterForeground,
        LGameEvent.RegisterExitBattleCb,
        LGameEvent.CrossServer,
        LGameEvent.ChangeServer,
	}
	self:RegistSelf(self,self.msgIds)
	self:InitMsgs()
	self.m_bIsInBattle = false
	self.m_strCurIp = nil
	self.m_iCurPort = nil
    self.m_iCurServerId = nil
    self.m_strCurCrossIp = nil
    self.m_strCurCrossPort = nil
	self.m_strCurCrossServerId = nil
	self.m_isFirst = true
	self.m_maxReConnectTimes = 20
	self.m_exitBattleCallback = {}
	self._enterBackTime = nil

	local scene = AppDef.Director:getRunningScene()
    if scene then
    	local function PlayBgMusic()
	        LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, AppDef.LogBgBGM)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
	    end
    	Utils:DelayToCallFunc(scene,0.5,PlayBgMusic)
    end
end

function LGameLogic:IsInBattle()
	return self.m_bIsInBattle
end

--[[
初始化一些常用的消息
]]
function LGameLogic:InitMsgs()
	self.m_initUIMsg = LUIInitMsg:New(LUILogicEvent.InitUI)--一个UI初始化的消息

	self.m_initUIMsg:Change("Login.LoginBgUI",AppDef.UIType.Normal)
	self:SendMsg(self.m_initUIMsg)

    Utils:ShowWaiting(-1, GUITips.Login_ReadData, 0)
	local function LuaLoadData()
        LDataConstMgr:LoadData()
    end

    local scene = AppDef.Director:getRunningScene()
    if scene then
    	Utils:DelayToCallFunc(scene,0.2,LuaLoadData)
    else
    	LDataConstMgr:LoadData()
    end
    
    --print("InitMsgs ----- init this event")
 --    self._toBackgroundListener = cc.EventListenerCustom:create("event_come_to_background", function (eventCustom)
 --        -- body
 --        --print("this is a enter background test")
 --        self._enterBackTime = os.time()
 --        --print("this is a enter background time", self._enterBackTime)
 --    end)
	-- AppDef.Director:getEventDispatcher():addEventListenerWithFixedPriority(self._toBackgroundListener, -1)
	-- --self.m_comMsg = LMsgBase:New()--一个通用的消息


	-- self._backToForegroundListener = cc.EventListenerCustom:create("event_come_to_foreground", function (eventCustom)
 --        -- body
 --        --print("this is a enter foreground test")
 --        self:handleBackGroundEvent()
 --    end)
	-- AppDef.Director:getEventDispatcher():addEventListenerWithFixedPriority(self._backToForegroundListener, -1)

end

--[[
链接登录游戏服务器
]]
function LGameLogic:ConnectLoginSocket()
    print("GameSdk.AppId --------->", GameSdk.AppId, AppDef.APPID_JIANZHENGZHUXIAN)
    if GameSdk.AppId == AppDef.APPID_JIANZHENGZHUXIAN then
        self.m_strCurIp = AppDef.ipAdrr_jzzs
        self.m_iCurPort = AppDef.ipPort_jzzs
    else
        self.m_strCurIp = AppDef.ipAdrr
        self.m_iCurPort = AppDef.ipPort
    end
	
	LGameMsg.m_tcpMsg:Change(LTCPEvent.LoginConnect, LGameNetEvent.TcpLoginBack, self.m_strCurIp, self.m_iCurPort)
	self:SendMsg(LGameMsg.m_tcpMsg)
end

--[[
退出跨服，返回正常服务器
]]
function LGameLogic:QuiteCrossServer()
    LGameMsg.m_baseMsg:ChangeEventId(LTCPEvent.GameDisConnect)
    self:SendMsg(LGameMsg.m_baseMsg)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
    -- LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
    -- self:SendMsg(LGameMsg.m_baseMsg)
    local waitAniData = {
                        key = LuaNetCmd.MSG_ACC_LOGIN,
                        waitMsg = GUITips.Login_Connect_LoginServer,
                        autoClearTime = 0
                    }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    local function ConnectServer()
        --server.needLineUp = false
        self.m_byLoginSocketConnectCnt = 0

        LUserConfigMgr:SetIsFirstLogin("false")
        --local lineUp = server.needLineUp
        local connectEvtId
        local connectEvtBackId
        self.m_iCurServerId = LUserConfigMgr:GetLastSelServerId()
        self.m_strCurIp = LUserConfigMgr:GetLastSelServerIp()
        self.m_iCurPort = LUserConfigMgr:GetLastSelServerPort()
        --print("QuiteCrossServer",self.m_iCurServerId,self.m_strCurIp)
        local connectEvtId = LTCPEvent.GameConnect
        local connectEvtBackId = LGameNetEvent.TcpGameBack

        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.QuitCrossServer)
        self:SendMsg(LGameMsg.m_cBaseMsg)
        LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.ChangeUser)
        self:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_baseMsg:ChangeEventId(LUIRoleTeamEvent.TeamMemberChanged)
        self:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_baseMsg:ChangeEventId(LUITaskDataEvent.DeleteAllTask)
        self:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_baseMsgWithOne:Change(LUIRoleTeamEvent.ApplyListChanged, false)
        self:SendMsg(LGameMsg.m_baseMsg)

        Utils:SendMsg(LResEvent.ChangeMap)

        LRoleDataMgr.m_bLastCrossServerState = true
        LRoleDataMgr.m_bIsCrossServer = false

        LGameMsg.m_tcpMsg:Change(connectEvtId, connectEvtBackId, self.m_strCurIp,self.m_iCurPort)
        self:SendMsg(LGameMsg.m_tcpMsg)
    end
    local scene = AppDef.Director:getRunningScene()
    Utils:DelayToCallFunc(scene,0.2,ConnectServer)
end

--[[
连接跨服
]]
function LGameLogic:ConnectCrossServer(server)

    LGameMsg.m_baseMsg:ChangeEventId(LTCPEvent.GameDisConnect)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.ChangeUser)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUIRoleTeamEvent.TeamMemberChanged)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUITaskDataEvent.DeleteAllTask)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsgWithOne:Change(LUIRoleTeamEvent.ApplyListChanged, false)
    self:SendMsg(LGameMsg.m_baseMsg)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    Utils:SendMsg(LResEvent.ChangeMap)
    -- LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.ChangeUser)
    -- self:SendMsg(LGameMsg.m_cBaseMsg)

    -- LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.Clear)
    -- self:SendMsg(LGameMsg.m_baseMsg)
    -- LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
    -- self:SendMsg(LGameMsg.m_baseMsg)

    local waitAniData = {
                        key = LuaNetCmd.MSG_ACC_LOGIN, 
                        waitMsg = GUITips.Login_Connect_LoginServer, 
                        autoClearTime = 0
                    }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    -- LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.ChangeUser)
    -- self:SendMsg(LGameMsg.m_baseMsg)

    local function ConnectServer()
        server.needLineUp = false
        self.m_byLoginSocketConnectCnt = 0

        LUserConfigMgr:SetIsFirstLogin("false")
        local lineUp = server.needLineUp
        local connectEvtId
        local connectEvtBackId
        self.m_iCurCrossServerServerId = server.serId
        if lineUp == true then
            self.m_strCurCrossServerIp = server.lineUpIp
            self.m_iCurCrossServerPort = server.lineUpPort
            connectEvtId = LTCPEvent.LoginConnect
            connectEvtBackId = LGameNetEvent.TcpLineUpBack
        else
            self.m_strCurCrossServerIp = server.serIp
            self.m_iCurCrossServerPort = server.serPort
            connectEvtId = LTCPEvent.GameConnect
            connectEvtBackId = LGameNetEvent.TcpGameBack
        end
        LRoleDataMgr.m_bLastCrossServerState = true
        LRoleDataMgr.m_bIsCrossServer = true


        LGameMsg.m_baseMsg:ChangeEventId(LUIMainEvent.CheckFirstRechargeBtn)
        self:SendMsg(LGameMsg.m_baseMsg)
        
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.EnterCrossServer)
        self:SendMsg(LGameMsg.m_cBaseMsg)

        LGameMsg.m_tcpMsg:Change(connectEvtId, connectEvtBackId, self.m_strCurCrossServerIp,self.m_iCurCrossServerPort)
        self:SendMsg(LGameMsg.m_tcpMsg)
    end

    local scene = AppDef.Director:getRunningScene()
    Utils:DelayToCallFunc(scene,0.2,ConnectServer)
end

function LGameLogic:ConnectGameSocket(server)
	LUserConfigMgr:SetIsFirstLogin("false")
	local lineUp = server.needLineUp
	local connectEvtId
	local connectEvtBackId
	self.m_iCurServerId = server.serId
	if lineUp == true then
		self.m_strCurIp = server.lineUpIp
		self.m_iCurPort = server.lineUpPort
		connectEvtId = LTCPEvent.LoginConnect
		connectEvtBackId = LGameNetEvent.TcpLineUpBack
	else
		self.m_strCurIp = server.serIp
		self.m_iCurPort = server.serPort
		connectEvtId = LTCPEvent.GameConnect
		connectEvtBackId = LGameNetEvent.TcpGameBack
	end

	LUserConfigMgr:SetLastSelServerNum(server.id)
	LUserConfigMgr:SetLastSelServerName(server.serName)
	LUserConfigMgr:SetLastSelServerIp(server.serIp)
	LUserConfigMgr:SetLastSelServerPort(server.serPort)
	LUserConfigMgr:SetLastSelServerId(server.serId)
	LUserConfigMgr:SetLastSelServerPage(server.page)
	LUserConfigMgr:SetLastOnLineState(server.onlineState)
	LUserConfigMgr:SetLastServerState(server.serType)
	LUserConfigMgr:SetLastServerPicId(server.serPic)
	LUserConfigMgr:SetIsNeedLineUp(server.needLineUp)
	LUserConfigMgr:SetLineUpServerIp(server.lineUpIp)
	LUserConfigMgr:SetLineUpServerPort(server.lineUpPort,true)
    LRoleDataMgr.Account.selServer = self.m_iCurServerId

	LGameMsg.m_tcpMsg:Change(connectEvtId, connectEvtBackId, self.m_strCurIp,self.m_iCurPort)
	self:SendMsg(LGameMsg.m_tcpMsg)

end

function LGameLogic:ShowLoginUI()
	self.m_initUIMsg:Change("Login.LoginUI",AppDef.UIType.Normal)
	self:SendMsg(self.m_initUIMsg)
end

function LGameLogic:ChangeServer()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.LoginUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LTCPEvent.GameDisConnect)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.Clear)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.ChangeUser)
    self:SendMsg(LGameMsg.m_cBaseMsg)

    self.m_initUIMsg:Change("Login.LoginBgUI",AppDef.UIType.Normal)
    self:SendMsg(self.m_initUIMsg)
    
    LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, AppDef.LogBgBGM)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    Utils:SendMsg(LResEvent.ChangeMap)

    local function ConnectLoginSocket()
        self.m_showServerList = true
        self:LoadDataFinish()
    end
    local scene = AppDef.Director:getRunningScene()
    if scene then
        Utils:DelayToCallFunc(scene,0.2,ConnectLoginSocket)
    else
        ConnectLoginSocket()
    end
end

--[[
排队服务器连接成功
]]
function LGameLogic:LineUpSocketConnectedSuccess()
	--请求排队状况
	LuaNetSendMsg:QueryLineUpServer(self.m_iCurServerId)

	local waitAniData = {
                            key = LuaNetCmd.MSG_ACC_LINEUP, 
                            waitMsg = GUITips.Login_Connect_Server, 
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
排队服务器连接失败
]]
function LGameLogic:LineUpSocketConnectedFailed()
	--重新请求连接服务器
	if self.m_byLoginSocketConnectCnt < self.m_maxReConnectTimes then
		self.m_byLoginSocketConnectCnt = self.m_byLoginSocketConnectCnt + 1
		LGameMsg.m_tcpMsg:Change(LTCPEvent.LoginConnect, LGameNetEvent.TcpLineUpBack, self.m_strCurIp,self.m_iCurPort)
		self:SendMsg(LGameMsg.m_tcpMsg)
	else

	end
end

function LGameLogic:LoadDataFinish()
	self.m_byLoginSocketConnectCnt = 0--登录服务器连接次数
    if AppDef.LOCAL_TEST == true then
        local server = LServerInfo:New()
        server.id = AppDef.LOCAL_TEST_SERVER_ID
        server.page = 1
        server.serId = AppDef.LOCAL_TEST_SERVER_ID
        server.serName = AppDef.LOCAL_TEST_SERVER_NAME
        server.serIp = AppDef.LOCAL_TEST_GAME_IP
        server.serPort = AppDef.LOCAL_TEST_GAME_PORT
        server.serType = 2
        server.onlineState = 0
        server.serState = 0
        server.serPic = 0
        server.needLineUp = false
        server.lineUpIp = ""
        server.lineUpPort = 0

        LRoleDataMgr.Account.uid = AppDef.LOCAL_TEST_UID
        LRoleDataMgr.Account.sid = AppDef.LOCAL_TEST_SIGNATURE
        LRoleDataMgr.Account.serverList = { server }

        LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_ACC_LOGIN)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self.m_initUIMsg:Change("Login.LoginUI", AppDef.UIType.Normal, 1)
        self:SendMsg(self.m_initUIMsg)
        return
    end
	local waitAniData = {
                        key = LuaNetCmd.MSG_ACC_LOGIN, 
                        waitMsg = GUITips.Login_Connect_LoginServer, 
                        autoClearTime = 0
                    }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
	self:ConnectLoginSocket()
end


function LGameLogic:ProcessEvent(msg)
	------print("LGameLogic:ProcessEvent msgID=" .. msg:GetMsgId())
	if msg:GetMsgId() == LGameNetEvent.ConfigDataLoadFinish then
		self:LoadDataFinish()
	elseif msg:GetMsgId() == LGameNetEvent.TCPSelectedGameServer then
		self.m_byLoginSocketConnectCnt = 0--登录服务器连接次数
		self:ConnectGameSocket(msg.value)
	elseif msg:GetMsgId() == LGameNetEvent.TcpLineUpBack then
		if msg:IsSuccess() == true then
			--服务器连接成功
			self:LineUpSocketConnectedSuccess()
		else
			self:LineUpSocketConnectedFailed()
		end
	elseif msg:GetMsgId() == LGameNetEvent.TcpLoginBack then
		print("LGameLogic:TcpLoginBack" .. msg:GetMsgId(), msg:IsSuccess())
		if msg:IsSuccess() == true then
			--服务器连接成功
			self:LoginSocketConnectedSuccess()
		else
			self:LoginSocketConnectedFailed()
		end
	elseif msg:GetMsgId() == LGameNetEvent.TcpGameBack then
		------print("LGameLogic:TcpGameBack" .. msg:GetMsgId(), msg:IsSuccess())
		if msg:IsSuccess() == true then
			--服务器连接成功
			self:GameSocketConnectedSuccess()
		else
			self:GameSocketConnectedFailed()
		end
	elseif msg:GetMsgId() == LGameEvent.EnterGame then
		self:EnterGameScene()
	elseif msg:GetMsgId() == LGameEvent.ChangeMap then
		self:ChangeMapScene()
	elseif msg:GetMsgId() == LGameEvent.ChangeMapSuccess then
		--self:ChangeMapSuccess(msg:GetMapId(),msg:GetMapPicId(),msg:GetPosx(),msg:GetPosy(),msg:GetAngle(),msg:GetMapName())
        self:ChangeMapSuccess()
	elseif msg:GetMsgId() == LGameEvent.EnterBattle then
		self.m_bIsInBattle = true
		self:LuaEnterBattleScene(msg)
		
		--
	elseif msg:GetMsgId() == LGameEvent.EnterBattleWatch then
		self.m_bIsInBattle = true
	elseif msg:GetMsgId() == LGameEvent.ExitBattle then
        if self.m_bIsInBattle == false then
            --登录服务器连接失败也会有这个处理消息，这个时候不在战斗中，所以不处理下面的东西
            return
        end
		self.m_bIsInBattle = false
		self:LuaExitBattleScene()
		if LDataConstMgr.m_BaoZangInfo.isWa then -- 在挖宝中
			LuaNetSendMsg:QueryCangBaotuWa()
		end
	elseif msg:GetMsgId() == LGameEvent.ChangeUser then
		self:ChangeUser()
	elseif msg:GetMsgId() == LGameEvent.EnterBackGround then
        -- --print("LGameEvent.enterBackGround -----------")
    elseif msg:GetMsgId() == LGameEvent.EnterForeground then
        -- --print("LGameEvent.enterBackGround ++++++++++++++++++")
    elseif msg:GetMsgId() == LGameEvent.RegisterExitBattleCb then
        if msg.value then
        	table.insert(self.m_exitBattleCallback, msg.value)
        end
    elseif msg:GetMsgId() == LGameEvent.CrossServer then
        self:RecvCrossServer(msg.value)
    elseif msg:GetMsgId() == LGameEvent.LogoutFromSDK then
        self:LogoutFromSDK()
    elseif msg:GetMsgId() == LGameEvent.ChangeServer then
        --print("LGameEvent.ChangeServer")
        self:ChangeServer()
	end
end

--[[
处理跨服
]]
function LGameLogic:RecvCrossServer(stream)
    local op = stream:ReadByte()
    --print("RecvCrossServer op=",op)
    if op == 1 then--连接到跨服
        local ip = stream:ReadString()
        local port = stream:ReadUInt()
        local uid = stream:ReadUInt()
        local sid = stream:ReadString()
        local serId = stream:ReadUInt()
        --print("ip=",ip,"port=",port,"serId=",serId,"uid=",uid,"sid=",sid)
        LRoleDataMgr.Account.uid = uid
        LRoleDataMgr.Account.sid = sid
        LRoleDataMgr.Account.serverList = {}

        LUserConfigMgr:SetCrossServerIp(ip, false)
        LUserConfigMgr:SetCrossServerPort(port, false)
        LUserConfigMgr:SetCrossServerId(serId, true)



        local data = LServerInfo:New()
        data.id = stream:ReadWord()
        data.page = 1
        data.serName = "CrossServer"

        data.serIp = ip
        data.serPort = port
        data.serId = serId
        self:ConnectCrossServer(data)
    elseif op == 2 then--从跨服切回
        -- int uid = s.ReadUInt();
        -- string sid = s.ReadString();
        -- int serId = s.ReadUInt();

        -- DATA_MGR->Task.m_taskTrackData[0].clear();--已接任务
        -- GAME_SCENE->ReStartGameLogin();
        self:QuiteCrossServer()
    end
end

--[[
进入战斗场景
]]
function LGameLogic:LuaEnterBattleScene(msg)
	
	LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, AppDef.BattleBgBGM)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)

	-- LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.MapEvent.EnterBattle)
 --    self:SendMsg(LGameMsg.m_cBaseMsg)

    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.EnterBattle)
    self:SendMsg(LGameMsg.m_cBaseMsg)
end

--[[
退出战斗场景
]]
function LGameLogic:LuaExitBattleScene()
	-- LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.ExitBattle)
 --    self:SendMsg(LGameMsg.m_baseMsg)

    Utils:SendMsg(LUILogicEvent.ExitBattle, nil , true)

    LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.ExitBattle)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
 --    LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayMapMusic, LRoleDataMgr.MyHeroInfo.mid)
	-- self:SendMsg(LGameMsg.m_baseMsgWithOne)

	-- LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.MapEvent.ExitBattle)
 --    self:SendMsg(LGameMsg.m_cBaseMsg)
 	LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.ExitBattle)
    self:SendMsg(LGameMsg.m_cBaseMsg)

    LuaNetSendMsg:QueryCanBattle(1)
    while #self.m_exitBattleCallback > 0 do
        self.m_exitBattleCallback[1]()
        table.remove(self.m_exitBattleCallback,1)
    end
end

--[[
进入战斗场景
]]
-- function LGameLogic:EnterBattleScene(msg)
-- 	LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.EnterBattle)
--     self:SendMsg(LGameMsg.m_baseMsg)
	
-- 	LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, Gaeme_BattleSign)
-- 	self:SendMsg(LGameMsg.m_baseMsgWithOne)
-- end

--[[
退出战斗场景
]]
-- function LGameLogic:ExitBattleScene()
-- 	LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.ExitBattle)
--     self:SendMsg(LGameMsg.m_baseMsg)
--     LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayMapMusic, LRoleDataMgr.MyHeroInfo.mid)
-- 	self:SendMsg(LGameMsg.m_baseMsgWithOne)
-- end

--[[
显示一些战斗后出现的UI，比如收益框
]]
function LGameLogic:ShowUIBuffer()
    for i = 1,#(AppDef.ScrollTipsAtferBattle) do
    	LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,AppDef.ScrollTipsAtferBattle[i])
		self:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
    AppDef.ScrollTipsAtferBattle = {}

    for i = 1,#(AppDef.CallbackAfterBatttle) do
        AppDef.CallbackAfterBatttle[i]()
    end
    AppDef.CallbackAfterBatttle = {}
end

-- function LGameLogic:ChangeMapSuccess(mid, mpicid, posx, posy, angle,mapName)
-- 	--local mid
--     LGameMsg.m_baseMsg:ChangeEventId(LAudioEvent.ChangeMap)
--     self:SendMsg(LGameMsg.m_baseMsg)

    
    
-- 	LRoleDataMgr.MyHeroInfo:SetMap(mid,mpicid)
-- 	LRoleDataMgr.MyHeroInfo.posx = posx--坐标
--     LRoleDataMgr.MyHeroInfo.posy = posy
--     LRoleDataMgr.MyHeroInfo.face = angle--朝向
--     self:PreloadCommonRes(mapName)
-- end

function LGameLogic:ChangeMapSuccess()
    --local mid
    LGameMsg.m_baseMsg:ChangeEventId(LAudioEvent.ChangeMap)
    self:SendMsg(LGameMsg.m_baseMsg)
    self:PreloadCommonRes()
end

--[[
预加载一些常用资源
]]
function LGameLogic:PreloadCommonRes(mapName)
    collectgarbage("count")
    collectgarbage("count")
    collectgarbage("count")
	local imgs = 
	{
		"csd/Plist/ui_mainPlist",
		"csd/Plist/cm_biaoqing",
		"csd/Plist/ui_juesePlist",
		"csd/Plist/ui_commonPlist",
		"csd/Plist/ui_main_iconPlist",
        "csd/Plist/cm_chenghao",
        "csd/Plist/ui_zhandouPlist",
        "csd/Plist/ui_xingongnengPlist",
        "csd/Plist/ui_huodong",
        "csd/Plist/ui_huobi",
        "csd/Plist/ui_common_new2Plist",
		"csd/Plist/ui_wanfaPlist",
	}
	local ind = 1
	
	local curLoadImg
	local mapnme = mapName
 --    local function LoadImg()

 --    	local function callback(texture)
 --            if texture then
 --                AppDef.spriteFrameCache:addSpriteFrames(curLoadImg .. ".plist", curLoadImg .. ".png")
	-- 		end
 --            if #imgs > 0 then
	-- 			LoadImg()
	-- 		else
	-- 			self:LoadCommonResComplete(mapnme)
	-- 		end
	--     end
	-- 	curLoadImg = table.remove(imgs,1)
	-- 	AppDef.textureCache:addImageAsync(curLoadImg .. ".png", callback) 
	-- end

 --    LoadImg()

    local function LoadImageFunc()
        for i = 1, #imgs do
            AppDef.spriteFrameCache:addSpriteFrames(imgs[i] .. ".plist", imgs[i] .. ".png")
        end
        self:LoadCommonResComplete(mapnme)

    end
    performWithDelay(AppDef.CurScene, LoadImageFunc, 0.1)
end

function LGameLogic:LoadCommonResComplete(mapName)

    local curMapName = mapName
    --[[第一次进入游戏场景]]
    local function DoFirstEnterScene()
        self.m_isFirst = false
        self:EnterGameReqMyHeroData()

        -- LGameMsg.m_initUIMsg:ChangeEventId(LUILogicEvent.InitUI)
        -- LGameMsg.m_initUIMsg:Change("MainUI",AppDef.UIType.Normal)
        -- self:SendMsg(LGameMsg.m_initUIMsg)

        -- LGameMsg.m_initUIMsg:Change("ImproveUI.LItemOrSkillRecvUI",AppDef.UIType.PopWindow)
        -- self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.HideLoading)
        self:SendMsg(LGameMsg.m_baseMsg)
        if LRoleDataMgr.m_bIsInBattle  == false then
            LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, AppDef.MainBGM)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end

        -- LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayMapMusic, LRoleDataMgr.MyHeroInfo.mid)
        -- self:SendMsg(LGameMsg.m_baseMsgWithOne)

        

        LGameMsg.m_baseMsgWithOne:Change(LUIMapEvent.ChangeMapSuccess, curMapName)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        LGameMsg.m_baseMsg:ChangeEventId(LResEvent.ChangeMapSuccess)
        self:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.TCPEvent.TcpGameStartHandleMsg)
        self:SendMsg(LGameMsg.m_cBaseMsg)
    end

    --[[
    切换地图
    ]]
    local function DoChangeScene()
        if (LRoleDataMgr.MyHeroInfo.sid == 11) then --主城
            LuaNetSendMsg:QueryMobaiInfo(1)     --请求膜拜雕像信息
        end

        local st = LRoleDataMgr.MyHeroInfo:GetSceneType()
        if(st == AppDef.SceneType.MSI_FACTION_ZONE) then--帮派领地 
            LuaNetSendMsg:QueryFactionList()        --请求帮派列表信息
            LuaNetSendMsg:QueryFactionPlantInfo()--请求帮派种植信息
        end

        LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.HideLoading)
        self:SendMsg(LGameMsg.m_baseMsg)
        if LRoleDataMgr.m_bIsInBattle  == false then
            LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, AppDef.MainBGM)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end

        -- LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayMapMusic, LRoleDataMgr.MyHeroInfo.mid)
        -- self:SendMsg(LGameMsg.m_baseMsgWithOne)

        

        LGameMsg.m_baseMsgWithOne:Change(LUIMapEvent.ChangeMapSuccess, curMapName)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        LGameMsg.m_baseMsg:ChangeEventId(LResEvent.ChangeMapSuccess)
        self:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.TCPEvent.TcpGameStartHandleMsg)
        self:SendMsg(LGameMsg.m_cBaseMsg)
    end

    if self.m_isFirst == true then
        local function DelayToShowMainUI()
            LGameMsg.m_initUIMsg:ChangeEventId(LUILogicEvent.InitUI)
            LGameMsg.m_initUIMsg:Change("MainUI",AppDef.UIType.Normal)
            self:SendMsg(LGameMsg.m_initUIMsg)
			
			LGameMsg.m_initUIMsg:ChangeEventId(LUILogicEvent.InitUI)
            LGameMsg.m_initUIMsg:Change("TouchUI",AppDef.UIType.Guide)
            self:SendMsg(LGameMsg.m_initUIMsg)

            LGameMsg.m_initUIMsg:Change("ImproveUI.LItemOrSkillRecvUI",AppDef.UIType.PopWindow)
            self:SendMsg(LGameMsg.m_initUIMsg)

            performWithDelay(AppDef.CurScene, DoFirstEnterScene, 0.1)
        end
        performWithDelay(AppDef.CurScene, DelayToShowMainUI, 0.1)
        
    else
        DoChangeScene()
    end
end

function LGameLogic:EnterGameReqMyHeroData()
	LuaNetSendMsg:QuerySYSTime()--请求系统时间
	LuaNetSendMsg:QuerySettingInfo()        --请求设置信息
	LuaNetSendMsg:QueryGetSettingInfo()--请求设置字符串信息
	LuaNetSendMsg:QueryPackageList()        --请求背包数据
	--LuaNetSendMsg:QueryEquipList()          --请求装备数据
	-- LuaNetSendMsg:QueryHeroSkill()          --请求技能列表信息
	--LuaNetSendMsg:QueryGotTaskList(4)        --请求已接任务列表
	LuaNetSendMsg:QueryUnGetTaskList(4)     --可接任务追踪列表
    LuaNetSendMsg:QueryShenQiInfoNew(5)	  --神器信息
    LuaNetSendMsg:QueryShenQiInfoNew(1)      --请求神器信息
	LuaNetSendMsg:QueryPetListInfo()        --请求宠物列表信息
	--LuaNetSendMsg:QueryHorseInfo(5)         --请求服务器坐骑列表
	LuaNetSendMsg:QueryHorseInfo(1)         --请求坐骑信息
	--LuaNetSendMsg:QueryMails(2) 		   --邮件列表
	LuaNetSendMsg:QueryFactionInfo()        --请求我的帮派信息
    LuaNetSendMsg:QueryBpSkilllevelUpData(44) --请求帮派科技信息
	-- LuaNetSendMsg:QueryHuoDongInfo()	       --活动
	-- LuaNetSendMsg:QueryPetArmorInfo()	   --请求宠物铠甲
	LuaNetSendMsg:QueryVipInfo(1)           --vip信息
	LuaNetSendMsg:QueryMedalList()          --请求称号
	-- LuaNetSendMsg:QueryShenQiInfoNew(5)			 --神器信息
	-- LuaNetSendMsg:QueryKaifuHuodong(7,3)    --请求等级礼包的奖励
	-- LuaNetSendMsg:QueryKaifuHuodong(10,2)   --付费套餐奖励
    --if LRoleDataMgr.IsOpenCharge then
    if not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG, true) then 
        LuaNetSendMsg:QueryKaifuHuodong(9,1)   --请求首充信息
    end

    --end
	-- LuaNetSendMsg:QueryKaifuHuodong(12,1)   --充值奖励
	-- LuaNetSendMsg:QueryDailyBossInfo(3)     --请求跑环任务次数
	-- LuaNetSendMsg:QueryPayServerId()        --請求服務器ID
	LuaNetSendMsg:QueryCangBaotuInfo(1) 	   --请求藏宝图宝藏信息
	LuaNetSendMsg:QueryConvoyInitState()
	-- LuaNetSendMsg:QueryKaifuHuodong(74,5)   -- 请求红包信息
	-- LuaNetSendMsg:QueryShituList()		--请求师徒
	LuaNetSendMsg:QueryChiBangData()    --翅膀羽翼信息
	-- if not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FUBEN, true) then 
 --        LuaNetSendMsg:QueryCopy(11)       --副本次数
 --        LuaNetSendMsg:QueryPetCopyList()       --副本次数
 --    end
	-- LuaNetSendMsg:QueryMarketShiMing(255)   -- 请求文网文信息
	LuaNetSendMsg:QueryVipInfo(9)       --请求特权卡信息

	-- LuaNetSendMsg:QueryLingShouInfo(1)  --请求灵兽信息
	LuaNetSendMsg:QueryFriendList()     --请求好友列表
    LuaNetSendMsg:QueryBlackListInfo()     --请求黑名单列表

	local st = LRoleDataMgr.MyHeroInfo:GetSceneType()
	if(st == AppDef.SceneType.MSI_FACTION_ZONE) then--帮派领地 
		LuaNetSendMsg:QueryFactionList()		--请求帮派列表信息
		LuaNetSendMsg:QueryFactionPlantInfo()--请求帮派种植信息
	elseif st == AppDef.SceneType.MSI_NORMAL then--主城
		LuaNetSendMsg:QueryMobaiInfo(1)--请求膜拜雕像信息
		LuaNetSendMsg:QueryMobaiInfo(2)--请求膜拜雕像信息
	end
    LuaNetSendMsg:QueryOnlineAward()

    LuaNetSendMsg:QueryFormationInfo()--请求阵容信息
    LuaNetSendMsg:QueryCompleteTaskList()--请求已完成任务列表
    --成长基金
    LuaNetSendMsg:QueryFundRebate(1)
    LuaNetSendMsg:QueryWorldLevel()--世界等级

    LuaNetSendMsg:QueryPetEquip(1)--装备背包
	for i = 1, #AppDef.PetFightPos do
		LuaNetSendMsg:SendMasterList(i)
	end
end

function LGameLogic:ChangeMapScene()
	-- dump('LGameLogic:ChangeMapScene')
    LGameMsg.m_baseMsg:ChangeEventId(LResEvent.ChangeMap)
    self:SendMsg(LGameMsg.m_baseMsg)
    
	LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.ChangeScene)
    self:SendMsg(LGameMsg.m_baseMsg)
    
	LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
    self:SendMsg(LGameMsg.m_baseMsg)
end

--[[
第一次进入游戏场景
]]
function LGameLogic:EnterGameScene()
	self.m_isFirst = true
	LGameMsg.m_initUIMsg:ChangeEventId(LUILogicEvent.DeleteUI)
	--删除登录界面
    LGameMsg.m_initUIMsg:Change("Login.LoginUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
    --删除角色创建界面
    LGameMsg.m_initUIMsg:Change("Login.RoleCreateUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:Change("Login.RegisterUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:Change("Login.ServerListUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:Change("Login.LoginBgUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

   	LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
    self:SendMsg(LGameMsg.m_baseMsg)
	--打开游戏主界面

	-- LGameMsg.m_baseMsgWithOne:Change(LUIMainEvent.StartAutoUseItemCheck)
 --    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
登录服务器连接成功
]]
function LGameLogic:GameSocketConnectedSuccess()
	--LuaNetSendMsg:ReqGameConfirm()
    local waitAniData = {
                        key = LuaNetCmd.MSG_LOGIN, 
                        waitMsg = GUITips.Login_Connect_GameServer_Success, 
                        autoClearTime = 0
                    }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function ReqLogin()
        LRoleDataMgr.Account.selServer = self.m_iCurServerId
        GameSdk:U8SendInfo(1, self.m_iCurServerId, 0, "")
    	LuaNetSendMsg:QueryGameLogin(LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, GameSdk.GameVersion,self.m_iCurServerId)
    end
    local scene = AppDef.Director:getRunningScene()
	Utils:DelayToCallFunc(scene,0.2,ReqLogin)
	
end

--[[
切换用户
]]
function LGameLogic:ChangeUser()
	LGameMsg.m_baseMsg:ChangeEventId(LTCPEvent.GameDisConnect)
	self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.LoginUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.ServerListUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

	LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.GameLogicEvent.ChangeUser)
	self:SendMsg(LGameMsg.m_cBaseMsg)

	LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.Clear)
	self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.ChangeUser)
    self:SendMsg(LGameMsg.m_baseMsg)

	self.m_initUIMsg:Change("Login.LoginBgUI",AppDef.UIType.Normal)
	self:SendMsg(self.m_initUIMsg)
    
	LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBgMusic, AppDef.LogBgBGM)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)

    Utils:SendMsg(LResEvent.ChangeMap)

	local function ConnectLoginSocket()
		self:LoadDataFinish()
	end
	local scene = AppDef.Director:getRunningScene()
    if scene then
    	Utils:DelayToCallFunc(scene,0.2,ConnectLoginSocket)
    else
    	ConnectLoginSocket()
    end
end

--[[
游戏服务器连接失败
]]
function LGameLogic:GameSocketConnectedFailed()
	--重新请求连接服务器
	local function ReConnect()
		local waitAniData = {
                        key = LuaNetCmd.MSG_ACC_LOGIN, 
                        waitMsg = GUITips.Login_ReConnect_Server, 
                        autoClearTime = 0
                    }
	    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
	    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    	self.m_byLoginSocketConnectCnt = self.m_byLoginSocketConnectCnt + 1
		LGameMsg.m_tcpMsg:Change(LTCPEvent.GameConnect, LGameNetEvent.TcpGameBack, self.m_strCurIp,self.m_iCurPort)
		self:SendMsg(LGameMsg.m_tcpMsg)
    end

	-- if self.m_byLoginSocketConnectCnt < self.m_maxReConnectTimes then
		
	    
	--     local scene = AppDef.Director:getRunningScene()
	-- 	Utils:DelayToCallFunc(scene,0.4,ReConnect)
	-- else
	-- 	self:ShowSocketConnectFiiledTips(ReConnect)
	-- end
    --顶号
    if GameSdk:IsQuickSDK() then
        -- GameSdk:QuerySDKSwitchAccount()
        GameSdk:GameLogoutCallBack()
    else
        self:ShowSocketConnectFiiledTips(ReConnect)
    end
	
end

--[[
登录服务器连接成功
]]
function LGameLogic:LoginSocketConnectedSuccess()

	----print("LoginSocketConnectedSuccess", GameSdk:IsSDKUser())
	if GameSdk:IsSDKUser() then
		--初始化UCSDK
		GameSdk:InitSDKData()
	else
		local account = LUserConfigMgr:GetUserAccount()
		if account == nil or string.len(account) == 0 then--显示注册
			self.m_initUIMsg:Change("Login.RegisterUI",AppDef.UIType.Normal)
		else--显示登录
            if self.m_showServerList then
                self.m_initUIMsg:Change("Login.ServerListUI",AppDef.UIType.Normal)
                self.m_showServerList = false
            else
                self.m_initUIMsg:Change("Login.LoginUI",AppDef.UIType.Normal,0)
            end
		end
        self:SendMsg(self.m_initUIMsg)
	end

    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_ACC_LOGIN)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
登录服务器连接失败
]]
function LGameLogic:LoginSocketConnectedFailed()
	local function ReConnect()
		local waitAniData = {
                        key = LuaNetCmd.MSG_ACC_LOGIN, 
                        waitMsg = GUITips.Login_ReConnect_Server, 
                        autoClearTime = 0
                    }
	    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
	    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    	self.m_byLoginSocketConnectCnt = self.m_byLoginSocketConnectCnt + 1
		LGameMsg.m_tcpMsg:Change(LTCPEvent.GameConnect, LGameNetEvent.TcpGameBack, self.m_strCurIp,self.m_iCurPort)
		self:ConnectLoginSocket()
    end
	if self.m_byLoginSocketConnectCnt < self.m_maxReConnectTimes then
		
	    
	    local scene = AppDef.Director:getRunningScene()
		Utils:DelayToCallFunc(scene,2.0,ReConnect)

	else
		self:ShowSocketConnectFiiledTips(ReConnect)
	end
end

function LGameLogic:ShowSocketConnectFiiledTips(okFunc)
    LRoleDataMgr.m_bIsCrossServer = false
    LRoleDataMgr.m_bIsCrossServer = false
	self.m_byLoginSocketConnectCnt = 0
	LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_ACC_LOGIN)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatTaskUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCCollectUI")
    self:SendMsg(LGameMsg.m_initUIMsg)


    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetArchiveMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyBaseUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.FanPaiRewardUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LBattleEvent.SocketClosed)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.PlotChatModel, false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.PlotChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "JingJie.jingjieMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.ChangeUser)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LUIRoleTeamEvent.TeamMemberChanged)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsgWithOne:Change(LUIRoleTeamEvent.ApplyListChanged, false)
    self:SendMsg(LGameMsg.m_baseMsg)

    Utils:SendMsg(LResEvent.ChangeMap)

	local function cancelFunc()
		AppDef.Director:endToLua()
	end	
	Utils:ShowDialogOKCancel(GUITips.Login_Connect_Socket_Error,okFunc,cancelFunc)
end

function LGameLogic:handleBackGroundEvent( ... )
	-- body
	if self._enterBackTime == nil then
		return
	end
	local curTime = os.time()
	local stayInBackTime = curTime - self._enterBackTime
--	--print("curTime handleBackGroundEvent", stayInBackTime)
    self._enterBackTime = nil
	if stayInBackTime < 60*30 then
		return
	end

	if LRoleDataMgr.m_bIsmainInited == nil then
		return
	end

	if not LRoleDataMgr.m_bIsmainInited then
		return
	end

--在后台时间超过30分钟, 则重新登录
	if LRoleDataMgr.m_bIsInBattle then
		LGameMsg.m_baseMsg:ChangeEventId(LBattleEvent.SocketClosed)
    	self:SendMsg(LGameMsg.m_baseMsg)

    	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.PlotChatUI")
    	self:SendMsg(LGameMsg.m_initUIMsg)
	end
	
	self:ChangeUser()
	LRoleDataMgr.m_bIsmainInited = false
end

function LGameLogic:LogoutFromSDK()
    Utils:ShowWaiting(-1, "", 0)
    local function DelayToBack()
        if LRoleDataMgr.m_bIsInBattle then
            LGameMsg.m_baseMsg:ChangeEventId(LBattleEvent.SocketClosed)
            self:SendMsg(LGameMsg.m_baseMsg)

            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.PlotChatUI")
            self:SendMsg(LGameMsg.m_initUIMsg)


        end
        Utils:RemoveWaiting(-1)
        self:ChangeUser()
        LRoleDataMgr.m_bIsmainInited = false
    end
    performWithDelay(AppDef.CurScene, DelayToBack, 0.2)
    

end

LGameLogic:Init()

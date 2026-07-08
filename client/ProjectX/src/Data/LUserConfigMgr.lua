LUserConfigMgr = LDataBase:New()
LUserConfigMgr.__index = LUserConfigMgr
-- function LUserConfigMgr:New()
-- 	local o = LUIBase:New()
-- 	setmetatable(o,LUserConfigMgr)	
-- 	o:Init()
-- 	return o
-- end
LUserConfigMgr.CFG_IS_MUSIC_VOLUME_SET = "IsMusicClosed"
LUserConfigMgr.CFG_IS_EFFECT_VOLUME_SET = "IsEffectClosed"
LUserConfigMgr.CFG_MUSIC_VOLUME = "MusicVolume"
LUserConfigMgr.CFG_EFFECT_VOLUME = "EffectVolume"
LUserConfigMgr.CFG_COPY_RESOURE_FLAG = "CopyResoureFlag"
LUserConfigMgr.CFG_ACTIVE_APP = "ActiveApp"
LUserConfigMgr.CFG_LAST_SERVER_NAME = "LastServerName"
LUserConfigMgr.CFG_LAST_SERVER_NUM = "LastServerNum"
LUserConfigMgr.CFG_LAST_SERVER_PAGE = "LastServerPage"
LUserConfigMgr.CFG_LAST_SERVER_IP = "LastServerIp"
LUserConfigMgr.CFG_LAST_SERVER_PORT = "LastServerPort"
LUserConfigMgr.CFG_LAST_SERVER_ID = "LastServerId"
LUserConfigMgr.CFG_CROSS_SERVER_IP = "CrossServerIp"
LUserConfigMgr.CFG_CROSS_SERVER_PORT = "CrossServerPort"
LUserConfigMgr.CFG_CROSS_SERVER_ID = "CrossServerId"
LUserConfigMgr.CFG_FINDPASSWORD_TIME = "LastFindPWYZM"
LUserConfigMgr.CFG_LAST_ONLINE_STATE = "LastOnLineState"
LUserConfigMgr.CFG_LAST_SERVER_STATE = "LastServerState"
LUserConfigMgr.CFG_LAST_SERVER_PICID = "LastServerPicId"
LUserConfigMgr.CFG_IS_NEED_LINEUP = "IsNeedLineUp"
LUserConfigMgr.CFG_LAST_LINEUP_SERVER_PORT = "LastLineUpServerPort"
LUserConfigMgr.CFG_LAST_LINEUP_SERVER_IP = "LastLineUpServerId"
LUserConfigMgr.CFG_LAST_HERO_PROFESSION = "LastHeroProfession"
LUserConfigMgr.CFG_LAST_HERO_SEX = "LastHeroSex"
LUserConfigMgr.CFG_LAST_HERO_NAME = "LastHeroName"
LUserConfigMgr.CFG_LAST_HERO_LEVEL = "LastHeroLevel"
LUserConfigMgr.CFG_USER_ACCOUNT = "UserAccount"
LUserConfigMgr.CFG_USER_PASSWORD = "UserPassword"
LUserConfigMgr.CFG_IS_FIRST_LOGIN = "IsFirstLogin"
LUserConfigMgr.CFG_IS_FIRST_FAST_LOGIN = "IsFirstFastLogin"
LUserConfigMgr.CFG_ND_FIRST_UIN    = "NdIosFirstUin"
LUserConfigMgr.CFG_ND_LOGIN_SUCCES = "NdIosLoginSucces"
LUserConfigMgr.CFG_PRESENT_PAY_TYPE = "PresentPayType"
LUserConfigMgr.CFG_IOS_PAY_CHECKINFO = "IosPayCheckInfo"
LUserConfigMgr.CFG_IOS_PAY_PRODUCTID = "IosPayProductId"
LUserConfigMgr.CFG_IOS_PAY_MONEY = "IosPayMoney"
LUserConfigMgr.CFG_IS_THIRDAUTH_WAY = "IsThirdAuth"
LUserConfigMgr.USERCONFIG_SHIELD_CHENGHAO = "USERCONFIG_SHIELD_CHENGHAO"
LUserConfigMgr.USERCONFIG_SHIELD_NEARHERO = "USERCONFIG_SHIELD_NEARHERO"
LUserConfigMgr.USERCONFIG_SHIELD_QIECHUO = "USERCONFIG_SHIELD_QIECHUO"
LUserConfigMgr.USERCONFIG_SHIELD_XIANHUA_PAR = "USERCONFIG_SHIELD_XIANHUA_PAR"
LUserConfigMgr.USERCONFIG_SHIELD_VIP = "USERCONFIG_SHIELD_VIP"
LUserConfigMgr.USERCONFIG_LASTBATTLE_STATE = "LastBattleState"
LUserConfigMgr.CFG_USER_GUIDE = "UserGuideList"--大步骤完成列表
LUserConfigMgr.CFG_USER_CUR_GUIDE = "UserCurGuide"--当前guideID
LUserConfigMgr.CFG_FIRST_COPY = "UserFinishCopyList"
LUserConfigMgr.CFG_SDK_YYB_LOGIN = "UserSDKYYBLogin"
LUserConfigMgr.CFG_USER_PREVIEW = "UserPreview"
LUserConfigMgr.MONOPOLYAUTOPLAY = "MonopolyAutoPlay"

LUserConfigMgr.ISCHPATERDIALOGOVER = "ChpaterDialogOver"
LUserConfigMgr.ISSTAGEDIALOGOVER = "StageDialogOver"
LUserConfigMgr.XUEZHAN_STYPE = "XuzhanSetType"
LUserConfigMgr.YOULI_INFO = "YouLiInfo"

LUserConfigMgr.FIGHT_SPEED = "FightSpeed"
LUserConfigMgr.ARENA_ZB_RED = "ArenaZbRedPoint" --竞技场战报红点


function LUserConfigMgr:Init()
	self.m_pUserDefault = CCUserDefault:getInstance()
	self.m_IsMusicClosed = nil
    self.m_IsEffectClosed = nil
    self.m_finishCopyList = nil
    self.m_strYYBLogin = nil--如果是应用宝的话,记录有没有登陆过
    self:LoadFromFile()
end

function LUserConfigMgr:Instance()
	return self
end

function LUserConfigMgr:GetYouLiInfo()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getStringForKey(LUserConfigMgr.YOULI_INFO..uid,"")
    end
    return ""
end

function LUserConfigMgr:SetYouLiInfo(infos)
    local str = "["
    for i=1,#infos do
        local value = infos[i]
        str = str.."["..value.id..","..value.heroId..","..value.mType..","..value.tType.."]"..","
    end
    str = string.sub(str,1,-2)
    str = str.."]"
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        --print("LUserConfigMgr:SetXueZhanSType",sType)
        self.m_pUserDefault:setStringForKey(LUserConfigMgr.YOULI_INFO..uid, str)
        self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:GetArenaZbRed()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.ARENA_ZB_RED..uid,false)
    end
    return false
end

function LUserConfigMgr:SetArenaZbRed(isShow)
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        self.m_pUserDefault:setBoolForKey(LUserConfigMgr.ARENA_ZB_RED..uid, isShow)
        self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:GetXueZhanSType()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getDoubleForKey(LUserConfigMgr.XUEZHAN_STYPE..uid,0)
    end
    return 0
end

function LUserConfigMgr:SetXueZhanSType(sType)
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        --print("LUserConfigMgr:SetXueZhanSType",sType)
        self.m_pUserDefault:setDoubleForKey(LUserConfigMgr.XUEZHAN_STYPE..uid, sType)
        self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:GetBattleSpeed()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.FIGHT_SPEED..uid, 0)
    end
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.FIGHT_SPEED,0)
end

function LUserConfigMgr:SetBattleSpeed(sType)
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.FIGHT_SPEED..uid, sType)
        self.m_pUserDefault:flush()
    end
    -- self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.FIGHT_SPEED, sType)
    -- self.m_pUserDefault:flush()
end
-- 
function LUserConfigMgr:GetUserAccount()
    --return "chenwei001"
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_USER_ACCOUNT)
end

function LUserConfigMgr:GetIsMusicClosed()
    if self.m_IsMusicClosed == nil then
        self.m_IsMusicClosed = self.m_pUserDefault:getBoolForKey(LUserConfigMgr.CFG_IS_MUSIC_VOLUME_SET, false)
	end
    return self.m_IsMusicClosed
end

function LUserConfigMgr:SetIsMusicClosed(b)
    self.m_IsMusicClosed = b
    self.m_pUserDefault:setBoolForKey(LUserConfigMgr.CFG_IS_MUSIC_VOLUME_SET, b)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetIsEffectClosed()
    if self.m_IsEffectClosed == nil then
        self.m_IsEffectClosed = self.m_pUserDefault:getBoolForKey(LUserConfigMgr.CFG_IS_EFFECT_VOLUME_SET, false)
    end
    return self.m_IsEffectClosed
end

function LUserConfigMgr:SetIsEffectClosed(b)
    self.m_IsEffectClosed = b
    self.m_pUserDefault:setBoolForKey(LUserConfigMgr.CFG_IS_EFFECT_VOLUME_SET, b)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetMusicVolume()
    local v = self.m_pUserDefault:getFloatForKey(LUserConfigMgr.CFG_MUSIC_VOLUME, 1)
    if v < 0 or v > 1 then
    	return 1
    else
    	return v
    end
end

function LUserConfigMgr:SetMusicVolume(b)
    self.m_pUserDefault:setFloatForKey(LUserConfigMgr.CFG_MUSIC_VOLUME, b)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetEffectVolume()
    local v = self.m_pUserDefault:getFloatForKey(LUserConfigMgr.CFG_EFFECT_VOLUME, 1)
    if v < 0 or v > 1 then
    	return 1
    else
    	return v
    end
end

function LUserConfigMgr:SetEffectsVolume(b)
    self.m_pUserDefault:setFloatForKey(LUserConfigMgr.CFG_EFFECT_VOLUME, b)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetYYBLoginFlag()
    if self.m_strYYBLogin == nil then
        self.m_strYYBLogin = self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_SDK_YYB_LOGIN)
    end
    return self.m_strYYBLogin
end

function LUserConfigMgr:SetYYBLoginFlag(s)
    self.m_strYYBLogin = s
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_SDK_YYB_LOGIN, self.m_strYYBLogin)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetCopyResoureFlag()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_COPY_RESOURE_FLAG)
end

function LUserConfigMgr:SetCopyResoureFlag(s)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_COPY_RESOURE_FLAG, s)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetActiveApp()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_ACTIVE_APP)
end

function LUserConfigMgr:setActiveApp(s)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_ACTIVE_APP, s)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetSocialMail(s)
    return self.m_pUserDefault:getStringForKey(s)
end

function LUserConfigMgr:SetSocialMail(f, s, bflush)
    self.m_pUserDefault:setStringForKey(f, s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetWarReport(s)
    return self.m_pUserDefault:getStringForKey(s)
end

function LUserConfigMgr:SetWarReport(f, s, bflush)
    self.m_pUserDefault:setStringForKey(f, s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastSelServerName()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_LAST_SERVER_NAME)
end

function LUserConfigMgr:SetLastSelServerName(s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_LAST_SERVER_NAME, s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastSelServerNum()
   return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_NUM)
end

function LUserConfigMgr:SetLastSelServerNum(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_NUM, i)
     if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLastSelServerPage()
   return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_PAGE)
end

function LUserConfigMgr:SetLastSelServerPage(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_PAGE, i)
     if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLastSelServerIp()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_LAST_SERVER_IP)
end

function LUserConfigMgr:SetLastSelServerIp(s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_LAST_SERVER_IP, s)
     if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLastSelServerPort()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_PORT)
end

function LUserConfigMgr:SetLastSelServerPort(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_PORT, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:IsNeedLineUp()
	return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.CFG_IS_NEED_LINEUP)
end

function LUserConfigMgr:SetIsNeedLineUp(needline,bflush)
	self.m_pUserDefault:setBoolForKey(LUserConfigMgr.CFG_IS_NEED_LINEUP, needline)
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

--是否屏蔽称号
function LUserConfigMgr:getShieldChengHao()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_CHENGHAO)
end

function LUserConfigMgr:setShieldChengHao(i)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_CHENGHAO, i)
    self.m_pUserDefault:flush()
end

--是否屏蔽附近玩家
function LUserConfigMgr:getShieldNearoHero()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_NEARHERO)
end

function LUserConfigMgr:setShieldNearoHero(i)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_NEARHERO, i)
    self.m_pUserDefault:flush()
end

--是否屏蔽切磋
function LUserConfigMgr:getShieldQieChuo()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_QIECHUO)
end

function LUserConfigMgr:setShieldQieChuo(i)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_QIECHUO, i)
    self.m_pUserDefault:flush()
end

--是否屏蔽鲜花特效
function LUserConfigMgr:getShieldXianHuaPar()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_XIANHUA_PAR)
end
function LUserConfigMgr:setShieldXianHuaPar(i)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_XIANHUA_PAR, i)
    self.m_pUserDefault:flush()
end

--是否屏蔽至尊标识
function LUserConfigMgr:getShieldVIP()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_VIP)
end
function LUserConfigMgr:setShieldVIP(i)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.USERCONFIG_SHIELD_VIP, i)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetLineUpServerIp()
	return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_LAST_LINEUP_SERVER_IP)
end

function LUserConfigMgr:SetLineUpServerIp(s, bflush)
	self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_LAST_LINEUP_SERVER_IP, s)
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLineUpServerPort()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_LINEUP_SERVER_PORT)
end

function LUserConfigMgr:SetLineUpServerPort(i, bflush)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_LINEUP_SERVER_PORT, i)
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLastSelServerId()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_ID)
end

function LUserConfigMgr:SetLastSelServerId(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_ID, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastOnLineState()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_ONLINE_STATE)
end

function LUserConfigMgr:SetLastOnLineState(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_ONLINE_STATE, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastServerState()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_STATE)
end

function LUserConfigMgr:SetLastServerState(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_STATE, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastServerPicId()
   return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_PICID)
end

function LUserConfigMgr:SetLastServerPicId(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_SERVER_PICID, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastHeroProfession()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_HERO_PROFESSION)
end

function LUserConfigMgr:SetLastHeroProfession(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_HERO_PROFESSION, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end  
end

function LUserConfigMgr:GetLastHeroSex()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_HERO_SEX)
end

function LUserConfigMgr:SetLastHeroSex(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_HERO_SEX, i)
     if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLastHeroName()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_LAST_HERO_NAME)
end

function LUserConfigMgr:SetLastHeroName( s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_LAST_HERO_NAME, s)
     if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetLastHeroLevel()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_LAST_HERO_LEVEL)
end

function LUserConfigMgr:SetLastHeroLevel(i, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_LAST_HERO_LEVEL, i)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:SetUserAccountAndPsd(account, psd)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_USER_ACCOUNT,account)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_USER_PASSWORD,psd)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:SetUserAccount(s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_USER_ACCOUNT,s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetUserPassword()
    --return "111111"
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_USER_PASSWORD)
end

function LUserConfigMgr:SetUserPassword(s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_USER_PASSWORD,s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetIsFirstLogin()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_IS_FIRST_LOGIN)
end

function LUserConfigMgr:SetIsFirstLogin(s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_IS_FIRST_LOGIN,s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetIsFirstFastLogin()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_IS_FIRST_FAST_LOGIN)
end

function LUserConfigMgr:SetIsFirstFastLogin(s, bflush)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_IS_FIRST_FAST_LOGIN,s)
    if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetIsThirdLogin()
	return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.CFG_IS_THIRDAUTH_WAY)
end

function LUserConfigMgr:SetIsThirdLogin(val)
	self.m_pUserDefault:setBoolForKey(LUserConfigMgr.CFG_IS_THIRDAUTH_WAY,val)
	self.m_pUserDefault:flush()
end

function LUserConfigMgr:GetNdIosFirstUin()
    return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_ND_FIRST_UIN)
end

function LUserConfigMgr:SetNdIosFirstUin(s)
    self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_ND_FIRST_UIN,s)
    self.m_pUserDefault:flush()
end


function LUserConfigMgr:IsNdIosLoginedSucces()
    return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.CFG_ND_LOGIN_SUCCES)
end

function LUserConfigMgr:SetNdIosLogined(isSuccesful)
    self.m_pUserDefault:setBoolForKey(LUserConfigMgr.CFG_ND_LOGIN_SUCCES,isSuccesful)
    self.m_pUserDefault:flush()
end

function LUserConfigMgr:SetPresentPayType(n, bflush)
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_PRESENT_PAY_TYPE,-1)--防错处理，先給它置空
    self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_PRESENT_PAY_TYPE,n)
    
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetPresentPayType()
    return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_PRESENT_PAY_TYPE)
end

function LUserConfigMgr:SetIosPayCheckInfo(s, f)
	self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_IOS_PAY_CHECKINFO,s)
	if f == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetIosPayCheckInfo()
	return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_IOS_PAY_CHECKINFO)
end

function LUserConfigMgr:SetIosPayMoney(n,f)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_IOS_PAY_MONEY,-1)--防错处理，先給它置空
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_IOS_PAY_MONEY,n)
	if f == true then
    	self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:GetIosPayMoney()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_IOS_PAY_MONEY)
end

function LUserConfigMgr:SetIosPayProductId(s,f)
	self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_IOS_PAY_PRODUCTID,s)
	if f == true then
    	self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:GetIosPayProductId()
	return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_IOS_PAY_PRODUCTID)
end

function LUserConfigMgr:LoadFromFile()
    self.m_IsEffectClosed = self:GetIsEffectClosed()
    self._IsMusicClosed = self:GetIsMusicClosed()
end

function LUserConfigMgr:GetCrossServerIp()
	return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_CROSS_SERVER_IP)
end

function LUserConfigMgr:SetCrossServerIp(s, bflush)
	self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_CROSS_SERVER_IP, s)
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetCrossServerPort()
	 return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_CROSS_SERVER_PORT)
end

function LUserConfigMgr:SetCrossServerPort(i, bflush)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_CROSS_SERVER_PORT, i)
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:GetCrossServerId()
	 return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_CROSS_SERVER_ID)
end

function LUserConfigMgr:SetCrossServerId(i, bflush)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_CROSS_SERVER_ID, i)
	if bflush == true then
    	self.m_pUserDefault:flush()
    end 
end

function LUserConfigMgr:setFindPWTime(time)
	self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_FINDPASSWORD_TIME, time)
	self.m_pUserDefault:flush()
end

function LUserConfigMgr:getFindPWTime()
	return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_FINDPASSWORD_TIME)
end

function LUserConfigMgr:setCreateTime(createTime)
	self.m_pUserDefault:setIntegerForKey("creat_role_time", createTime)
	self.m_pUserDefault:flush()
end

function LUserConfigMgr:getCreateTime()
	local createTime = self.m_pUserDefault:getIntegerForKey("creat_role_time",0)
	if createTime == 0 then
		self.m_pUserDefault:setIntegerForKey("creat_role_time", createTime)
		self.m_pUserDefault:flush()
	end
	return createTime
end

function LUserConfigMgr:LoadCacheDataByUser()
    --self:LoadUserGuide()
end

function LUserConfigMgr:LoadUserGuide()
    self:SetUserGuideCache()
    local curGuideId = 0
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        local curId = self:GetUserCurGuide()
        curGuideId = curId
        --local stepId = math.floor(curId/100)
        local str = LRoleDataMgr:GetSettingStringConfig(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE)
        if str and #str > 0 then
            local curServerStep = tonumber(str)
            if curServerStep > curId then
                LUserConfigMgr:SetUserCurGuide(curServerStep)
                curGuideId = curServerStep
            elseif curServerStep < curId then
                LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE, ""..curId)
            end
        end   
    end
    return curGuideId
end

function LUserConfigMgr:GetUserGuideCache()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_USER_GUIDE .. uid,"")
    end
    return ""
end

function LUserConfigMgr:SetUserGuideCache()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        local str = LRoleDataMgr:GetSettingStringConfig(AppDef.ServerSetIndex.SSI_FINISH_GUIDE)
        if str and #str > 0 then
            self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_USER_GUIDE .. uid, str)
            self.m_pUserDefault:flush()
        end
    end
end

function LUserConfigMgr:GetUserCurGuide()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getIntegerForKey(LUserConfigMgr.CFG_USER_CUR_GUIDE .. uid,0)
    end
    return 0
end

function LUserConfigMgr:SetUserCurGuide(guideId)
    if guideId == nil or type(guideId) ~= "number" then
        return
    end
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        self.m_pUserDefault:setIntegerForKey(LUserConfigMgr.CFG_USER_CUR_GUIDE .. uid, guideId)
        self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:IsCopyFinish(cid)
    if self.m_finishCopyList == nil then
        self.m_finishCopyList = self:GetFinishCopyList()
    end
    if self.m_finishCopyList == nil then
        return false
    end
    return Utils:ToBool(self.m_finishCopyList[cid])
end

function LUserConfigMgr:SetCopyFinish(cid)
    if self.m_finishCopyList == nil then
        self.m_finishCopyList = self:GetFinishCopyList()
    end
    self.m_finishCopyList = self.m_finishCopyList or {}
    if self.m_finishCopyList[cid] then
        return
    end
    self.m_finishCopyList[cid] = true
    self:SetFinishCopyList()
end

function LUserConfigMgr:GetFinishCopyList()
    local ret = {}
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        local str = self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_FIRST_COPY..uid)
        if str and #str > 0 then
            local arr = string.split(str, ',')
            for i=1,#arr do
                if arr[i] and #arr[i] > 0 then
                    ret[tonumber(arr[i])] = true
                end
            end
        end
    end
    return ret
end

function LUserConfigMgr:SetFinishCopyList()
    if self.m_finishCopyList == nil then
        return
    end
    local str = ''
    for k,v in pairs(self.m_finishCopyList) do
        if k and v then
            str = str..','..k
        end
    end
    if #str > 0 then
        local uid = LRoleDataMgr.MyHeroInfo.id
        if uid and uid > 0 then
            self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_FIRST_COPY..uid, str)
        self.m_pUserDefault:flush()
        end
    end
end

function LUserConfigMgr:GetUserPreView()
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        return self.m_pUserDefault:getStringForKey(LUserConfigMgr.CFG_USER_PREVIEW .. uid)
    end
    return nil
end

function LUserConfigMgr:SetUserPreView(id)
    local uid = LRoleDataMgr.MyHeroInfo.id
    if uid and uid > 0 then
        self.m_pUserDefault:setStringForKey(LUserConfigMgr.CFG_USER_PREVIEW .. uid, id or "0")
        self.m_pUserDefault:flush()
    end
end

function LUserConfigMgr:GetMonoPolyAutoPlay()
    return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.MONOPOLYAUTOPLAY, false)
end

function LUserConfigMgr:SetMonoPolyAutoPlay(autoPlay)
    self.m_pUserDefault:setBoolForKey(LUserConfigMgr.MONOPOLYAUTOPLAY, autoPlay)
    self.m_pUserDefault:flush()
end


function LUserConfigMgr:GetChpaterDialogOver()
    return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.ISCHPATERDIALOGOVER, false)
end

function LUserConfigMgr:SetChpaterDialogOver(isOver)
    self.m_pUserDefault:setBoolForKey(LUserConfigMgr.ISCHPATERDIALOGOVER, isOver)
    self.m_pUserDefault:flush()
end


function LUserConfigMgr:GetStageDialogOver()
    return self.m_pUserDefault:getBoolForKey(LUserConfigMgr.ISSTAGEDIALOGOVER, false)
end

function LUserConfigMgr:SetStageDialogOver(isStageOver)
    self.m_pUserDefault:setBoolForKey(LUserConfigMgr.ISSTAGEDIALOGOVER, isStageOver)
    self.m_pUserDefault:flush()
end

LUserConfigMgr:Init()
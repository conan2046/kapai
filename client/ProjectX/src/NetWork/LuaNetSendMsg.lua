--[[
@通信发送处理命令，一部分在c#
@作者：陈伟
@创建日期：2016-04-22
]]
LuaNetSendMsg = LNetBase:New()
LuaNetSendMsg.__index = LuaNetSendMsg
function LuaNetSendMsg:New()
    local o = {}
    setmetatable(o,LuaNetSendMsg)
    o:Awake()
    return o
end

function LuaNetSendMsg:Awake()
    -- self.m_pLoginSendMsg = LTCPMsg:New()
    -- self.m_pGameMsg = LTCPMsg:New()
    self.m_pStream = LTCPMsg:New()
end

-- self.m_pStream = NetSendMsg.GetInstance().StreamBody
function LuaNetSendMsg:ResetStream()
   self.m_pStream:Reset()
end

LuaNetSendMsg:Awake()

function LuaNetSendMsg:QueryLineUpServer(serverId)
    self:ResetStream()
    self.m_pStream:WriteWord(LuaNetCmd.MSG_ACC_LINEUP)
    self.m_pStream:WriteUInt(serverId)
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryACCheckNickName(name)
    self:ResetStream()
    self.m_pStream:WriteWord(LuaNetCmd.MSG_ACC_REG)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteString(name)
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryACReg(name, pwd, ver, adCode, mobileInfo, panelRatio, mac, newUser, regType,imie,phoneRegType,realName,idCardCode)
    --print("LuaNetSendMsg:QueryACReg",name, pwd, ver, adCode, mobileInfo, panelRatio, mac, newUser, regType,imie,phoneRegType,realName,idCardCode)
    self:ResetStream()
    self.m_pStream:WriteWord(LuaNetCmd.MSG_ACC_REG)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(pwd)
    self.m_pStream:WriteString(ver)
    self.m_pStream:WriteWord(adCode)
    self.m_pStream:WriteString(mobileInfo)
    self.m_pStream:WriteString(panelRatio)
    self.m_pStream:WriteByte(newUser)
    self.m_pStream:WriteString(mac)
    self.m_pStream:WriteString(imie)
    self.m_pStream:WriteByte(phoneRegType)
    self.m_pStream:WriteString(realName)
    self.m_pStream:WriteString(idCardCode)
    local netInfo = ""
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     netInfo = SysUtilsWrapper::GetNetworkInfo()
-- #else
--     netInfo = CallJava_GetNetworkInfo()
-- #endif
    self.m_pStream:WriteString(netInfo)
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryACLogin(name, password, version, adCode,imie)
    --print("LuaNetSendMsg:QueryACLogin",name, password, version, adCode,imie)
    --CCLog("================name=============password==================%s,%s",name.c_str(),password.c_str())
    LRoleDataMgr.Account:DeleteServerHeroInfo()
    self:ResetStream()
    self.m_pStream:WriteWord(LuaNetCmd.MSG_ACC_LOGIN)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(password)
    self.m_pStream:WriteString(version)
    self.m_pStream:WriteWord(adCode)
    local first = LUserConfigMgr:GetIsFirstLogin()
    if first == nil or string.len(first) == 0 then
        self.m_pStream:WriteByte(1)
    else
        self.m_pStream:WriteByte(0)
    end
    
    
    --加区分，加上IOS的获取，仅限越狱版
    local mobile = GamePlatform:GetDeviceName()
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     mobile = SysUtilsWrapper::GetPhoneType()
-- #else
--     mobile = CallJava_GetAndroidVersion()
-- #endif
    self.m_pStream:WriteString(mobile)
    local panelRatio = ""
    --string panelRatio =  CallJava_GetAndroidPanelRatio()
    self.m_pStream:WriteString(panelRatio)

    local mac =  GamePlatform:GetDeviceMacAddress()
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     mac = SysUtilsWrapper::GetPhoneMac()
-- #else
--     if(ark_Download::IsTencentSDK())
--         mac = CallJava_getTencentMid()
--     else
--         mac = CallJava_GetAndroidMacAddress()
-- #endif
    self.m_pStream:WriteString(mac)

    local idfa = ""
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
-- #if defined _IOS_OFFICIAL_YSHQG || _IOS_OFFICIAL_YSHQG || _IOS_OFFICIAL_MHXX || _IOS_OFFICIAL_SSJ || _IOS_SDK_AS || _IOS_SDK_XY
--     --idfa = MtSdkFunctionWraper::GetADFA()
-- #endif
-- #endif
    self.m_pStream:WriteString(idfa)

    self.m_pStream:WriteString(GamePlatform:GetDeviceIMEI())
    local netInfo = ""
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     netInfo = SysUtilsWrapper::GetNetworkInfo()
-- #else
--     netInfo = CallJava_GetNetworkInfo()
-- #endif
    self.m_pStream:WriteString(netInfo)
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)
    -- self:SendMsg(self.m_pStream)
    -- --返回当前发送包二进制数据
    -- return SystemHelper::GetHexString((const char*)self.m_pStream:GetBuffer(), self.m_pStream:GetSeekPos())
end

------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------游戏服协议---------------------------------------------------------------------
function LuaNetSendMsg:QueryGameLogin(id, name, checkStr,serverId)
    --print("id",id,"name",name,"checkStr",checkStr,"serverId",serverId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_LOGIN)
    self.m_pStream:WriteUInt(id)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(checkStr)
    self.m_pStream:WriteUInt(serverId)
    local netInfo = GamePlatform:GetNerworkInfo()
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     netInfo = SysUtilsWrapper::GetNetworkInfo()
-- #else
--     netInfo = CallJava_GetNetworkInfo()
-- #endif
    self.m_pStream:WriteString(netInfo)

    local mac =  GamePlatform:GetDeviceMacAddress()
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     mac = SysUtilsWrapper::GetPhoneMac()
-- #else
--     if(ark_Download::IsTencentSDK())
--         mac = CallJava_getTencentMid()
--     else
--         mac = CallJava_GetAndroidMacAddress()
-- #endif
    self.m_pStream:WriteString(mac)

    local imie = GamePlatform:GetDeviceIMEI()
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     imie = ""
-- #else
--     imie = CallJava_PhoneIMIE()
-- #endif
    self.m_pStream:WriteString(imie)

    local idfa = ""
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
-- #if defined _IOS_OFFICIAL_YSHQG || _IOS_OFFICIAL_YSHQG || _IOS_OFFICIAL_MHXX || _IOS_OFFICIAL_SSJ || _IOS_SDK_AS || _IOS_SDK_XY
--     --idfa = MtSdkFunctionWraper::GetADFA()
-- #endif
-- #endif
    self.m_pStream:WriteString(idfa)
    self.m_pStream:ChangeEventId(LTCPEvent.GameSendMsg)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryCheckHeroName(op, sex, name)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CHECKNAME)
	self.m_pStream:WriteByte(op)
   if op == 2 then
       self.m_pStream:WriteByte(sex)
    elseif op == 1 then
       self.m_pStream:WriteString(name)
   end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryCreateHero(name, sex, model,head,ad)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CREATE_HERO)
    self.m_pStream:WriteString(name)
	self.m_pStream:WriteByte(sex)
	self.m_pStream:WriteByte(model)
	self.m_pStream:WriteByte(head)
    self.m_pStream:WriteWord(ad)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryStartGame(roleId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CHOOSE_HERO)
    self.m_pStream:WriteUInt(roleId)
    self.m_pStream:ChangeEventId(LTCPEvent.GameSendMsg)
    self:SendMsg(self.m_pStream)
end

-- 请求副本信息
function LuaNetSendMsg:QueryCopy(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUIRY_COPYINFO)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--[[
副本相关(op
4-退出副本
11-副本列表
12-进入副本
19-扫荡副本
20-round次扫荡
24-助阵)
]]
function LuaNetSendMsg:QueryCopyExit()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUIRY_COPYINFO)
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryCopyMsg(op, id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUIRY_COPYINFO)
    self.m_pStream:WriteByte(op)
    if op == 12 or op == 19 then
        self.m_pStream:WriteWord(id)
    elseif op == 20 then
        self.m_pStream:WriteByte(id or 0)
    end

    self:SendMsg(self.m_pStream)
end

-- 副本相关op:20副本扫荡
function LuaNetSendMsg:QueryCopySweep(op, id, round)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUIRY_COPYINFO)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteWord(id)
    self.m_pStream:WriteByte(round)
    self:SendMsg(self.m_pStream)
end

-- 宠物副本列表
function LuaNetSendMsg:QueryPetCopyList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_COPY)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

-- 进入宠物副本
function LuaNetSendMsg:QueryEnterPetCopy(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_COPY)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

-- 宠物副本扫荡
function LuaNetSendMsg:QueryPetCopySweep(op, id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_COPY)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryUnGetTaskInfo(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MISSION_NOGET_LIST)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryUnGetTaskList(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MISSION_NOGET_LIST)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryPackageList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_PACK)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:QueryPackageList")
end

function LuaNetSendMsg:QuerySendChatMsg(type, msg)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CHAT)
    if(string.len(msg) <= 0)
    then
        return
    end

    if type == nil or type == 0 then
        type = 1
    end

    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteString(msg, string.len(msg))
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QuerySendPriateMsg(type, id, msg)
    if string.len(msg) <= 0 then
        return
    end
    print("QuerySendPriateMsg",id,msg)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CHAT)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteString(msg, string.len(msg))
    self.m_pStream:WriteByte(1)         --id发1 名字发2
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)

end

--[[
点击任务追踪领取奖励
]]
function LuaNetSendMsg:QueryTaskAward(taskId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_GET_MISSION_AWARD)
    self.m_pStream:WriteWord(taskId)
    self:SendMsg(self.m_pStream)
    
end
-- function LuaNetSendMsg:QueryHeroSkill()
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_GET_ALL_SKILL)
--     self:SendMsg(self.m_pStream)
-- end

--[[
不要了
]]
-- function LuaNetSendMsg:QuerySkillDesc(id)
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_SKILL_DESC)
--     self.m_pStream:WriteWord(id)
--     self:SendMsg(self.m_pStream)
-- end

function LuaNetSendMsg:QueryEquipList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_EQUIP)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryGotoNextScene(npcId, nextId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_GOTO_NEXTLOCAL)
    self.m_pStream:WriteUInt(npcId)
    self.m_pStream:WriteWord(nextId)
    self:SendMsg(self.m_pStream)
end

--[[
翅膀羽翼相关
op
1 获取已获得的翅膀信息
2 强化翅膀
3 设置翅膀状态
4 获取所有翅膀列表--这个没用了，原来是从服务器获取的，现在改为前端读表
5 购买（兑换）翅膀
6 请求翅膀强化信息
7 请求其他用户翅膀信息
]]
function LuaNetSendMsg:QueryChiBangData()
    --self:QueryChiBangInfo(4)
    self:QueryChiBangInfo(1)
end

function LuaNetSendMsg:QueryChiBangInfo(op, par1, par2)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CHIBANG_DO)
    self.m_pStream:WriteByte(op)

    if op == 2 then
        if par1 ~= 0 or par2 ~= 0 then
            self.m_pStream:WriteByte(1)
        else
            self.m_pStream:WriteByte(2)
        end
        self.m_pStream:WriteWord(par1)
        self.m_pStream:WriteWord(par2)
    elseif op == 3 or op == 5 then
        self.m_pStream:WriteByte(par1)
    elseif op == 7 then
        self.m_pStream:WriteUInt(par1)
    end
    self:SendMsg(self.m_pStream)
end

--[[
请求已接任务列表
]]
-- op 1列表 2 更新状态 3 领取
-- type 1 竞技场日常 2 每日任务 3 寻宝任务 4 成就
function LuaNetSendMsg:QueryGotTaskList(type)
    --print("QueryGotTaskList",type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MISSION_LIST)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--领取奖励
function LuaNetSendMsg:QueryGotTaskAward(type, id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MISSION_LIST)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end

--七日奖励
function LuaNetSendMsg:QueryGotQiRiTask()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MISSION_LIST)
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
    --print("QueryGotQiRiTask ===> 1111111111111111111")
end

--领取七日奖励
function LuaNetSendMsg:QueryGotQiRiAward(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MISSION_LIST)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end


--[[
请求已接任务详细信息
]]
function LuaNetSendMsg:QueryGotTaskInfo(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TASK_INFO)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end

--[[
请求坐骑信息
op 1 请求坐骑信息
op 2 升级
op 3 进阶坐骑
op 5 获取坐骑列表
op 8 获取其他玩家坐骑列表
]]
function LuaNetSendMsg:QueryHorseInfo(op, t, id, num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HORSE_DO)
    self.m_pStream:WriteByte(op)
    if op == 2 then
        self.m_pStream:WriteByte(t)
        if t == 2 then
            self.m_pStream:WriteUInt(id)
            self.m_pStream:WriteUInt(num)
        end
    elseif op == 8 then
        self.m_pStream:WriteUInt(t)
    end
    self:SendMsg(self.m_pStream)
end

--[[
上下坐骑
op 4
idx 0xff 休息
]]
function LuaNetSendMsg:QueryHorseRideInfo(op, idx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HORSE_DO)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(idx)
    self:SendMsg(self.m_pStream)
end



--[[
使用背包中物品
]]
function LuaNetSendMsg:SendItemUseReq(itemPos,itemNum,target)
    target = target or 0--N选1礼包下标
    --print("LuaNetSendMsg:SendItemUseReq",itemPos,itemNum,target)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_UPDATE_PACKAGE)
	self.m_pStream:WriteByte(1)
	self.m_pStream:WriteWord(itemPos)
	self.m_pStream:WriteByte(itemNum)
	self.m_pStream:WriteByte(target)
    self:SendMsg(self.m_pStream)
end

--[[
丢弃背包中物品
]]
function LuaNetSendMsg:SendDiscardItemReq(pos,num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_UPDATE_PACKAGE)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteWord(pos)
    self.m_pStream:WriteWord(num)
    self:SendMsg(self.m_pStream)
end

--[[
丢弃背包中物品
]]
function LuaNetSendMsg:SendSellItemReq(pos,num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_UPDATE_PACKAGE)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteWord(pos)
    self.m_pStream:WriteWord(num)
    self:SendMsg(self.m_pStream)
end

--[[
请求卸下穿戴的装备
]]
function LuaNetSendMsg:QueryPutOffEquip(pos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_EQUIP_ITEM)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteByte(pos)
    self:SendMsg(self.m_pStream)
end

--[[
请求穿装备
]]
function LuaNetSendMsg:QueryPutOnEquip(pos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_EQUIP_ITEM)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(pos)
    self:SendMsg(self.m_pStream)
end

--开启背包格
function LuaNetSendMsg:SendOpenPackageReq(num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_OPEN_PACKAGE_OPTION)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(num)
    self:SendMsg(self.m_pStream)
end

--背包物品排序
function LuaNetSendMsg:QuerySortPackage()
    local waitAniData = {
                            key = LuaNetCmd.MSG_UPDATE_PACKAGE, 
                            waitMsg = "",
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_UPDATE_PACKAGE)
    self.m_pStream:WriteByte(6)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryItemDetail(op, pos)
    --请求道具详细信息 op=0是装备 op=1是背包
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_REQ_ITEM)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteWord(pos)
    self:SendMsg(self.m_pStream)
end

--[[
请求合成道具
]]
function LuaNetSendMsg:QuerySynthesisItem(pos,synType)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HE_CHENG_OPTION)
    self.m_pStream:WriteByte(synType)
    self.m_pStream:WriteByte(pos)
    self:SendMsg(self.m_pStream)
end
--[[
请求合成指定数量道具
op=3
itemId 合成道具的id
num  合成下一级道具的数量
]]
function LuaNetSendMsg:QuerySynthesisSpecifiedNumItem(itemId,num)
    --print("合成下一级道具的数量",itemId,num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HE_CHENG_OPTION)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteWord(itemId)
    self.m_pStream:WriteWord(num)
    self:SendMsg(self.m_pStream)
end

--[[
请求分解道具（暂只支持神将碎片）
@param pos:需要分解的位置列表
]]
function LuaNetSendMsg:QueryResolveItem(pos)
    if #pos == 0 then return end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HE_CHENG_OPTION)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(#pos)
    for i=1,#pos do
        self.m_pStream:WriteByte(pos[i]-1)
    end
    self:SendMsg(self.m_pStream)
end

--[[
@param op 12请求分解神将,13请求神将分解返回信息
@param petIds:需要分解的神将Id列表
]]
function LuaNetSendMsg:QueryResolvePet(op,petIds,aType)
    if petIds == nil or #petIds == 0 then return end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(op)
    if op == 13 then
        self.m_pStream:WriteByte(aType)
    end
    self.m_pStream:WriteByte(#petIds)
    for i=1,#petIds do
        self.m_pStream:WriteUShort(petIds[i])
    end
    self:SendMsg(self.m_pStream)
end

--Npc剧情
function LuaNetSendMsg:QueryNpcChatOption(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_NPC_CHAT)
    self.m_pStream:WriteByte(2)--多个选项
    self.m_pStream:WriteByte(1)--后边参数数量
    self.m_pStream:WriteByte(0) --后边参数类型(0-表示4字节数字 1-字符串)
    self.m_pStream:WriteUInt(index) --参数数值
    self:SendMsg(self.m_pStream)
end

--跳过剧情
function LuaNetSendMsg:SendSkipPlot()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SKIP_PLOT)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryNpcChatOpen(npcId, npcIdx, missionId)

    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayNPCEffect, npcId)
    self:SendMsg(LGameMsg.m_audioMsg)

    missionId = missionId or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_OPEN_INTERACT)
    self.m_pStream:WriteWord(npcId)
    self.m_pStream:WriteWord(npcIdx)
    self.m_pStream:WriteWord(missionId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryNpcChatTask(missionId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_NPC_CHAT)
    self.m_pStream:WriteByte(38)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteUInt(missionId)
    self:SendMsg(self.m_pStream)
end


--[[
请求遇怪设置
@param1:succ 
                1请求遇怪，战斗结束后发 2请求不遇怪 3 请求遇怪，寻路结束后发
]]
function LuaNetSendMsg:QueryCanBattle(succ)    --请求遇敌
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CAN_BATTLE)
    self.m_pStream:WriteByte(succ)
    self:SendMsg(self.m_pStream)
end

--[[请求竞技场列表
    op:0排名战(竞技场模型显示),2英雄榜自己（排行榜显示）,16英雄榜全服，3记录（含回放），11奖励说明
    13请求竞技场可进入次数,14加速，15买次数，
]]
function LuaNetSendMsg:QueryArenaList(op)
    --local waitAniData = {
    --                        key = LuaNetCmd.MSG_ARENA, 
    --                        waitMsg = "",
    --                       autoClearTime = 0
    --                    }
    --LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ARENA)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--竞技场信息请求(竞技场模型显示)
--@value 1-排名模型信息
function LuaNetSendMsg:QueryArenaInfo(value)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ARENA)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteByte(value)
    self:SendMsg(self.m_pStream)
    ----print("LuaNetSendMsg:QueryArenaInfo",value)
end

--请求竞技场挑战信息-5挑战
function LuaNetSendMsg:QueryArenaChallenge(op,heroId,IdType,typeId,rank)



    local waitAniData = {
                            key = LuaNetCmd.MSG_ARENA, 
                            waitMsg = "",
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ARENA)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteUInt(rank)
    self.m_pStream:WriteUInt(heroId)
    self.m_pStream:WriteByte(IdType)
    self.m_pStream:WriteByte(typeId)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:QueryArenaChallenge",op,heroId,rank)
end

--竞技场扫荡
function LuaNetSendMsg:SendArenaSweepReq(heroId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ARENA)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteUInt(heroId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryArenaRobotInfo(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ARENA)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--玩法信息请求
function LuaNetSendMsg:QueryDailyActivityList(op,activityVal)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_DAILY_ACTIVITY)
    self.m_pStream:WriteByte(op)
    if activityVal ~= nil then
        self.m_pStream:WriteUInt(activityVal)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryRushGateInfo(op, t)
    local waitAniData = {
                            key = LuaNetCmd.MSG_ADVANCEPATH_INFO, 
                            waitMsg = "",
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    t = t or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
    self.m_pStream:WriteByte(op)
    if op == 6 or op == 11 or op == 12 then
        self.m_pStream:WriteByte(t)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryMonopolyInfo(op, t)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
    self.m_pStream:WriteByte(op)
    if op == 6 or op == 11 or op == 12 then
        self.m_pStream:WriteByte(t)
    end
    self:SendMsg(self.m_pStream)
end

--[[
开服活动
]]
function LuaNetSendMsg:QueryKaifuHuodong(op, op1, op2)
    op1 = op1 or 0
    op2 = op2 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)

    if op2 ~= 0  or (op == 5 and op1 == 2)  then
        self.m_pStream:WriteByte(op2)
    end

    self:SendMsg(self.m_pStream)
end


--[[
等级
]]
function LuaNetSendMsg:QuerySevenChargeStarAward( op, op1, op2, starNum)
    -- body
    op1 = op1 or 0
    op2 = op2 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(op2)
    self.m_pStream:WriteByte(starNum)
    self:SendMsg(self.m_pStream)
end

--[[
充值送礼
]]
function LuaNetSendMsg:QueryReChargeInfo(op, op1, op2)
    op1 = op1 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(op2)
    self:SendMsg(self.m_pStream)
end

--[[
7日活动
]]
function LuaNetSendMsg:QuerySevenChargeInfo(op, op1)
    op1 = op1 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryLoginGift(op, op1, op2)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    if op2 then
        self.m_pStream:WriteByte(op2)
    end
    self:SendMsg(self.m_pStream)
end

--[[
领取七充奖励
]]
function LuaNetSendMsg:QuerySevenChargeAward( op, op1, op2, day )
    -- body
    op1 = op1 or 0
    op2 = op2 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(op2)
    self.m_pStream:WriteByte(day)
    self:SendMsg(self.m_pStream)
end

--[[
7日活动
]]
function LuaNetSendMsg:QueryNationalDayCoWord(op, op1)
    op1 = op1 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self:SendMsg(self.m_pStream)
end

--[[
7日活动兑换
]]
function LuaNetSendMsg:exchangeNationalDayCoWord(op, op1, tag, selWordIdx)
    op1 = op1 or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteUInt(tag)
    self.m_pStream:WriteByte(selWordIdx)
    self:SendMsg(self.m_pStream)
end


function LuaNetSendMsg:QueryShakeMoneyTree(op, op1)
    LuaNetSendMsg:QueryKaifuHuodong(op,op1)
end

function LuaNetSendMsg:QueryChangeCity(nextCitySid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WORLDMAP_SID)
    self.m_pStream:WriteWord(nextCitySid)
    self:SendMsg(self.m_pStream)
end


--[[
请求神器数据 op:1神器基础信息，3培养信息，5当前跟随
]]
function LuaNetSendMsg:QueryShenQiInfoNew(op, param)
    self:ResetStream()
	self.m_pStream:WriteUShort(LuaNetCmd.MSG_SHENQI)
    self.m_pStream:WriteByte(op)
    if op == 7 then
        self.m_pStream:WriteUInt(param)
    end
    self:SendMsg(self.m_pStream)
end

--[[
请求神器数据 op:2请求穿脱(id,state)，4进阶(item_id,item_num)，6激活(id)
]]
function LuaNetSendMsg:SendShenQiReq(op,param1,param2)
    self:ResetStream()
	self.m_pStream:WriteUShort(LuaNetCmd.MSG_SHENQI)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteUInt(param1)
    if param2 ~= nil then
        self.m_pStream:WriteUInt(param2)
    end
    self:SendMsg(self.m_pStream)
end

--[[
请求商城数据
]]
function LuaNetSendMsg:QueryMarketInfo(opNum, pagetype, goodsID, goodsNum, noWaiting, pid, pstar)
    self:ResetStream()
	self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_MARKET)
    self.m_pStream:WriteByte(opNum)
    if opNum == 1 then
        self.m_pStream:WriteByte(pagetype)
    elseif opNum == 2 then
        self.m_pStream:WriteByte(pagetype)
		self.m_pStream:WriteUInt(goodsID)
        self.m_pStream:WriteWord(pid or 0)
        self.m_pStream:WriteWord(pstar or 0)
		self.m_pStream:WriteByte(goodsNum)
    elseif opNum == 7 or opNum == 24 then
        self.m_pStream:WriteWord(goodsID)
		self.m_pStream:WriteByte(pagetype)
    elseif opNum == 5 then
        self.m_pStream:WriteWord(pagetype)
	end
    self:SendMsg(self.m_pStream)
    if not Utils:ToBool(noWaiting) then
        Utils:ShowWaiting(LuaNetCmd.MSG_CLIENT_MARKET)
    end
end

--[[
    新的商城数据
]]
--商城购买商品
-- op 1 请求商店数据
-- type 2 商店类型
function LuaNetSendMsg:QueryKaPaiShopUI( op, type)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_MARKET)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--商城购买商品
-- op 1 请求商店数据
-- shopType 2 商店类型
-- id 物品Id(shop表ID)
-- num 商品数量
function LuaNetSendMsg:QueryBuyProd( op, shopType, shopId, num,isUsed)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_MARKET)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(shopType)
    self.m_pStream:WriteWord(shopId)
    self.m_pStream:WriteUShort(num)
    self.m_pStream:WriteByte(isUsed or 0)
    self:SendMsg(self.m_pStream)
end

--请求商城物品购买次数
--@param sType 商店类型
--@param itemId 道具ID
function LuaNetSendMsg:QueryKaPaiShopCnt(sType,itemId)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_MARKET)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(sType)
    self.m_pStream:WriteWord(itemId)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:QueryKaPaiShopCnt",sType,itemId)
end

--[[
请求系统时间
]]
function LuaNetSendMsg:QuerySellOrBuyInfo(op, idx, num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_NPC_CHAT)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteUInt(op)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteUInt(idx)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteUInt(num)
    self:SendMsg(self.m_pStream)
end

--[[
请求系统时间
]]
function LuaNetSendMsg:QuerySYSTime()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SYS_TIME)
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end




























--------------------------------------------------------------------------------------
--[[
请求确认登录
]]
function LuaNetSendMsg:ReqGameConfirm()
    ----print("ReqGameConfirm")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.GAMEENTER)
    self.m_pStream:WriteInt(AppDef.OpenId)
    self.m_pStream:WriteBytes(AppDef.OpenSession)
    self.m_pStream:WriteUShort(AppDef.SelectedServerId)
    self.m_pStream:ChangeEventId(LTCPEvent.GameSendMsg)
    self:SendMsg(self.m_pStream)
end

--[[
向服务器申请查询是否该服务器拥有角色
]]
function LuaNetSendMsg:ReqServerRoleInfo(fuid)
    ------print("申请的服id = "..fuid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.SERVERROLEINFO)
    self.m_pStream:WriteInt(fuid)
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)end


 -- @功能：属性点功能增加

function LuaNetSendMsg:ReqAddShuxing(tizhi, liliang, lingli, minjie)
   --[[
         客户端发送:	PRO_ID=10
	+----+-------+---------+--------+--------+
	| OP | TIZHI | LILIANG | LINGLI | MINJIE |
	+----+-------+---------+--------+--------+
	| 1  |   4   |    4    |    4   |   ４   |
	+----+-------+---------+--------+--------+
	OP:	     	1分配属性点
	TIZHI:		分配体质点数
	LILIANG:	分配力量点数
	LINGLI:		分配灵力点数
	MINJIE:		分配敏捷点数
         ]]--
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.SHUXING_POINT)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteUInt(tizhi)
    self.m_pStream:WriteUInt(liliang)
    self.m_pStream:WriteUInt(lingli)
    self.m_pStream:WriteUInt(minjie)
    self:SendMsg(self.m_pStream)
end

--@功能：属性点功能重置

function LuaNetSendMsg:ReqResetShuxing()
   --[[
        客户端发送:PRO_ID=10
                +----+
                | OP |
                +----+
                | 1  |
                +----+
        OP:	2重置属性点
     ]]--
    ------print("我重置了点数")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.SHUXING_POINT)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end


--[[    /*
@功能：相性点功能增加
*/]]--
function LuaNetSendMsg:ReqAddXiangxing(jinxiang,muxiang,tuxiang,shuixiang,huoxiang)
--[[        /*
       客户端发送:	PRO_ID=11
	+----+------+----+----+------+-----+
	| OP | JING | MU | TU | SHUI | HUO |
	+----+------+----+----+------+-----+
	| 1  |  4   | 4  | 4  |  ４  | ４  |
	+----+------+----+----+------+-----+
	OP:			1分配相性点
	JING:		分配金点数
	MU:			分配木点数
	TU:			分配土点数
	SHUI:		分配水点数
	HUO:		分配火点数
         */]]--
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.XIANGXING_POINT)
        self.m_pStream:WriteByte(1)
        self.m_pStream:WriteUInt(jinxiang)
        self.m_pStream:WriteUInt(muxiang)
        self.m_pStream:WriteUInt(tuxiang)
        self.m_pStream:WriteUInt(shuixiang)
        self.m_pStream:WriteUInt(huoxiang)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：相性点功能重置
*/]]
function LuaNetSendMsg:ReqResetXiangxing()
--[[        /*
        客户端发送:	PRO_ID=11
	                +----+
	                | OP |
	                +----+
	                | 1  |
	                +----+
	        OP:	2重置属性点
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.XIANGXING_POINT)
        self.m_pStream:WriteByte(2)
        self:SendMsg(self.m_pStream)
end

--[[
替换伙伴出战位置
@param1:pos(0左边伙伴1右边伙伴)
@param2:pid伙伴id
]]
function LuaNetSendMsg:ReqPartnerFight(pos, pid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(18)
    self.m_pStream:WriteByte(pos)
    self.m_pStream:WriteInt(pid)
    self:SendMsg(self.m_pStream)
end
--[[
请求其他玩家的队伍信息
@param:pid玩家id
]]
function LuaNetSendMsg:ReqPlayerTeamInfo(pid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(32)
    self.m_pStream:WriteInt(pid)
    self:SendMsg(self.m_pStream)
end

--[[
创建队伍
@param1:ttype(队伍类型)
]]
function LuaNetSendMsg:ReqCreateTeam(ttype)
------print("ReqCreateTeam:type=" .. ttype)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(ttype)
    self:SendMsg(self.m_pStream)
end

--[[
召回队员
]]
function LuaNetSendMsg:ReqCallbackTeamMember(pid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(14)
    self.m_pStream:WriteInt(pid)
    self:SendMsg(self.m_pStream)
end

--[[
离开队伍
]]
function LuaNetSendMsg:ReqLeaveTeam()
    ------print("ReqLeaveTeam")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end

--[[
请求加入队伍
]]
function LuaNetSendMsg:ReqTeamAccept(tid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteInt(tid)
    self:SendMsg(self.m_pStream)
end

--[[
队长请求移交队长
]]
function LuaNetSendMsg:ReqChangeCap(tid)
    ------print("ReqChangeCap")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteInt(tid)
    self:SendMsg(self.m_pStream)
end

--[[
队长请求移交队长
]]
function LuaNetSendMsg:ReqChangeCapReply(tid,v)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteInt(tid)
    self.m_pStream:WriteByte(v)
    self:SendMsg(self.m_pStream)
end

--[[
队长请求移交队长
]]
function LuaNetSendMsg:ReqKickoutTeam(tid)
------print("ReqKickoutTeam")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(13)
    self.m_pStream:WriteInt(tid)
    self:SendMsg(self.m_pStream)
end


--[[
暂离队伍
]]
function LuaNetSendMsg:ReqPauseTeam()
------print("ReqPauseTeam")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(8)
    self:SendMsg(self.m_pStream)
end

-- --[[
-- 请求回归队伍
-- ]]
-- function LuaNetSendMsg:ReqReturnTeam()
--     ------print("ReqReturnTeam")
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
--     self.m_pStream:WriteByte(15)
--     self:SendMsg(self.m_pStream)
-- end

--[[
请求加入队伍
]]
function LuaNetSendMsg:ReqJoinTeam(tid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(tid)
    self:SendMsg(self.m_pStream)
end

--[[
请求自动匹配
@param1:teamType 队伍目标类型
]]
function LuaNetSendMsg:ReqAutoMatchTeam(teamType)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(16)
    self.m_pStream:WriteByte(teamType)
    self:SendMsg(self.m_pStream)
end

--[[
请求取消自动匹配
@param1:teamType 队伍目标类型
]]
function LuaNetSendMsg:ReqCancelAutoMatchTeam()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(17)
    self:SendMsg(self.m_pStream)
end

--[[
邀请进入队伍
]]
function LuaNetSendMsg:ReqInvitePlayerTeam(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(19)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
组队请求附近玩家
]]
function LuaNetSendMsg:ReqTeamNearHeros()

    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(28)
    self:SendMsg(self.m_pStream)
end

--[[
组队请求好友列表
]]
function LuaNetSendMsg:ReqTeamMyFriends()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(29)
    self:SendMsg(self.m_pStream)
end

--[[
组队请求帮派成员
]]
function LuaNetSendMsg:ReqTeamMyFaction()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(25)
    self:SendMsg(self.m_pStream)
end

--[[
组队请求帮派成员
]]
function LuaNetSendMsg:ReqTeamChat()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(30)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：打开背包
*/]]
function LuaNetSendMsg:ReqOpenPack()
--[[        /*
        客户端发送: PRO_ID=13
            +----+
            | OP |
            +----+
            | 1  |
            +----+
            OP: 2请求背包信息
         */]]
        ------print("我请求了背包的信息~！-----------------------------")
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
        self.m_pStream:WriteByte(2)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：存到仓库
*/]]
function LuaNetSendMsg:ReqAllTempPackItem()
    ------print("获取所有临时背包信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
    self.m_pStream:WriteByte(13)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：领取临时背包里面的物品
*/]]
function LuaNetSendMsg:ReqGetTempPackItem(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：领取临时背包里面的物品
*/]]
function LuaNetSendMsg:ReqOpenPackCount()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
    self.m_pStream:WriteByte(10)
    self:SendMsg(self.m_pStream)
end

--[[
获取仓库数据
]]
function LuaNetSendMsg:ReqWarehouse()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_WAREHOUSE_INFO)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：整理仓库
*/]]
function LuaNetSendMsg:ReqFinishingWarehouse()
    ------print("整理仓库")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_WAREHOUSE_INFO)
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：存到仓库
*/]]
function LuaNetSendMsg:ReqSaveToWarehouse(pos)
    ------print("存入仓库")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteByte(pos)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：从仓库取出
*/]]
function LuaNetSendMsg:ReqGetToPack(pos)
    ------print("取出仓库")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_WAREHOUSE_INFO)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(pos)
    self:SendMsg(self.m_pStream)
end



--[[
发送聊天信息
]]
function LuaNetSendMsg:ReqChat(chn,msg)
    --[[
    +-----+-----+
    | CHN | MSG |
    +-----+-----+
    |  1  | Str |
    +-----+-----+
    CHN=1 世界
    ]]
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.CHAT)
    self.m_pStream:WriteByte(chn)
    self.m_pStream:WriteString(msg)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：丢弃背包道具
*/]]
function LuaNetSendMsg:ReqDeleteItem(pos , num)
--[[        /*
客户端发送:  PRO_ID=13
    +----+----------+----------+
    | OP | PROP_POS | PROP_NUM |
    +----+----------+----------+
    | 1  |     1    |     2    |
    +----+----------+----------+
    OP:         4背包道具删除
    PROP_POS:   道具在背包位置下标
    PROP_NUM:   道具数量
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
        self.m_pStream:WriteByte(4)
        self.m_pStream:WriteByte(pos)
        self.m_pStream:WriteUShort(num)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：背包道具详情
*/]]
function LuaNetSendMsg:ReqItemInfo(pos)
--[[        /*
        客户端发送: PRO_ID=13
            +----+
            | OP |
            +----+
            | 1  |
            +----+
            OP: 3请求背包信息
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
        self.m_pStream:WriteByte(6)
        self.m_pStream:WriteByte(pos)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：使用道具
*/]]
function LuaNetSendMsg:ReqOpenUseItem(pos,num)
--[[        /*
        客户端发送: PRO_ID=13
            +----+
            | OP |
            +----+
            | 1  |
            +----+
            OP: 2请求背包信息
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
        self.m_pStream:WriteByte(7)
        self.m_pStream:WriteByte(pos)
        self.m_pStream:WriteUShort(num)
        self:SendMsg(self.m_pStream)
end

--[[
删除buff 根据buff的type
]]
function LuaNetSendMsg:ReqDeleteBuf(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：整理背包
*/]]
function LuaNetSendMsg:ReqZhengLiPack()
--[[        /*
        客户端发送: PRO_ID=13
            +----+
            | OP |
            +----+
            | 1  |
            +----+
            OP: 3请求背包信息
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_PACK_INFO)
        self.m_pStream:WriteByte(3)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：更新左边装备栏Icon
*/]]
function LuaNetSendMsg:ReqEquipment()
--[[        /*
     客户端发送: PRO_ID=15
        +----+
        | OP |
        +----+
        | 1  |
        +----+
    OP:     2装备栏信息
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_EQUIPMENT_INFO)
        self.m_pStream:WriteByte(2)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：装备  pos--装备在背包位置下标
*/]]
function LuaNetSendMsg:ReqOnEquipment(pos)
--[[        /*
      客户端发送:    PRO_ID=15
            +----+
            | OP |
            +----+
            | 1  |
            +----+
    OP:     2装备栏信息
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_EQUIPMENT_INFO)
        self.m_pStream:WriteByte(3)
        self.m_pStream:WriteByte(pos)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：卸下装备
*/]]
function LuaNetSendMsg:ReqOffEquipment(pos)
--[[        /*
    客户端发送:  PRO_ID=15
    +----+------------+
    | OP | EQUIPS_POS |
    +----+------------+
    | 1  |      1     |
    +----+------------+
    OP:             4脱装备
    EQUIPS_POS:     装备在装备栏位置下标(0武器1帽子2衣服3鞋子4项链5护符6腰带7戒指)
    */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_EQUIPMENT_INFO)
        self.m_pStream:WriteByte(4)
        self.m_pStream:WriteByte(pos)
        self:SendMsg(self.m_pStream)
end

--[[    /*
@功能：点开装备弹窗 获取详情
*/]]
function LuaNetSendMsg:ReqEquipmentInfo(pos)
--[[        /*
      客户端发送:    PRO_ID=15
            +----+
            | OP |
            +----+
            | 1  |
            +----+
    OP:     2装备栏信息
         */]]
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_EQUIPMENT_INFO)
        self.m_pStream:WriteByte(5)
        self.m_pStream:WriteByte(pos)
        self:SendMsg(self.m_pStream)
end

--[[
    @功能：发送登录请求
    @param1:cid(ushort)渠道号
    @param2:name(string)用户名
    @param3:psd(string)密码
    @return:无返回
]]
function LuaNetSendMsg:ReqLogin(cid,name,psd)
    --[[
    +----+------+-----+
    | AD | NAME | PWD |
    +----+------+-----+
    |  2 | Str  | Str |
    +----+------+-----+
    AD:				渠道号----渠道号为2的时候默认是电脑本地登录，主要是为了兼容测试
    NAME:			用户名
    PWD:			密码	
    ]]
    ----print("LuaNetSendMsg:ReqLogin:cid=" .. cid .. "name=" .. name .. " psd=" .. psd)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.LOGIN)
    self.m_pStream:WriteUShort(cid)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(psd)
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)
    --UIManager:ShowWaitServerIcon()
end


--[[
@功能：发送注册请求
@param1:cid(ushort)渠道号
@param2:name(string)用户名
@param3:psd(string)密码
@return:无返回
]]
function LuaNetSendMsg:ReqRegister(cid, name, psd)
    --[[
    +----+------+-----+-------------+-------------+
    | AD | NAME | PWD | MOBILE_INFO | MOBILE_IMEI |
    +----+------+-----+-------------+-------------+
    |  2 | Str  | Str |     Str     |     Str     |
    +----+------+-----+-------------+-------------+
    AD:				渠道号
    NAME:			用户名
    PWD:			密码	
    MOBILE_INFO:	手机信息
    MOBILE_IMEI:	手机序列号
    ]]
    ----print("LuaNetSendMsg:ReqRegister:cid=" .. cid .. "name=" .. name .. " psd=" .. psd)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.REGUSER)
    self.m_pStream:WriteUShort(cid)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(psd)
    self.m_pStream:WriteString(GamePlatform:GetDeviceName())
    self.m_pStream:WriteString(GamePlatform:GetDeviceIMEI())
    self.m_pStream:ChangeEventId(LTCPEvent.LoginSendMsg)
    self:SendMsg(self.m_pStream)
	--UIManager:ShowWaitServerIcon()
end

    --创建角色
function LuaNetSendMsg:ReqRoleCreate(name, zhiye, sex, head)
--[[
	客户端发送:	PRO_ID=3
		+---------+------+---------+-----+------+
		| SESSION | NAME | ZHONGZU | SEX | HEAD |
		+---------+------+---------+-----+------+
		|   Str   |  Str |    1    |  1  |   1  |
		+---------+------+---------+-----+------+
		SESSION:	游戏的会话
		NAME:		名称
		ZHONGZU:	种族1(金) 2(木) 3(土) 4(水) 5(火)
		SEX:		性别1男 2女
		HEAD:		头像
]]
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.ROLECREATE)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteByte(zhiye)
    self.m_pStream:WriteByte(sex)
    self.m_pStream:WriteByte(head)
    self:SendMsg(self.m_pStream)
	--UIManager:ShowWaitServerIcon()
end


--[[-------------------------------------------------------------背包添加物品(测试用后期删除)
客户端发送:  PRO_ID=13
    +----+---------+----------+
    | OP | ITEM_ID | ITEM_NUM |
    +----+---------+----------+
    | 1  |    4    |     2    |
    +----+---------+----------+
    OP:         50背包添加物品(测试用后期删除)
    ITEM_ID:    物品ID
    ITEM_NUM:   物品数量
    ]]
function LuaNetSendMsg:ADDItem(ID , num)
    self:ResetStream()
     self.m_pStream:WriteUShort(13)
    self.m_pStream:WriteByte(50)
     self.m_pStream:WriteUInt(ID)
    self.m_pStream:WriteUShort(num)
    self:SendMsg(self.m_pStream)
 
end

--[[
点击npc发送的消息
]]
function LuaNetSendMsg:ReqOpenNpcInteract(npcid)
    ----print("<color=red>注意：</color> npc交互之前有一个延迟点击的还没有挪移过来。" .. npcid)
    -- if (RoleView.GetInstance().m_iOpenNpcId != 0) return
    -- RoleView.GetInstance().m_iOpenNpcId = nid
    -- RoleView.GetInstance().ResetOpenNpcIdCoro()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.NPC_OPEN)
    self.m_pStream:WriteInt(npcid)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:OpenNpc( id )
     self:ResetStream()
      self.m_pStream:WriteUShort(LuaNetCmd.NPC_OPEN)
      self.m_pStream:WriteUShort(2)
      self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:TalkClick(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.NPC_DIA_CLICK)
    self.m_pStream:WriteInt(id)
     self:SendMsg(self.m_pStream)
end

--[[
请求添加任务列表
]]
function LuaNetSendMsg:Reqtasklist( )
    ----print("请求添加任务列表")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.TASK_LIST)
    self:SendMsg(self.m_pStream)
end

--[[
请求一个任务的详情
]]
function LuaNetSendMsg:RequestATaskInfo(taskid)
    ----print("请求一个任务详情")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.TASK_REQ_INFO)
    self.m_pStream:WriteInt(taskid)
    self:SendMsg(self.m_pStream)
end

--[[
    -------------------------------------------------------------时装全部信息
    客户端发送:  PRO_ID=16
        +----+
        | OP |
        +----+
        | 1  |
        +----+
        OP: 4时装全部信息
]]
function LuaNetSendMsg:GetAllFashionInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_FASHION_INFO)
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
end


--[[
    客户端发送:  PRO_ID=16
    +----+---------+
    | OP | YIFU_ID |
    +----+---------+
    | 1  |    4    |
    +----+---------+
    OP:         7换衣服
    YIFU_ID:    衣服ID
]]

function LuaNetSendMsg:ChangeClothes(ID)
    self:ResetStream()
     self.m_pStream:WriteUShort(LuaNetCmd.UPDATE_FASHION_INFO)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteUInt(ID)
    self:SendMsg(self.m_pStream)
end

--[[
    客户端发送:  PRO_ID=16
        +----+-----------+
        | OP | PIFENG_ID |
        +----+-----------+
        | 1  |     4     |
        +----+-----------+
        OP:         5换发型
        PIFENG_ID:  披风ID
]]

function LuaNetSendMsg:ChangeHair(ID,Color)
    ------print("发型的ID为："..ID .. "   发型的颜色为："..Color)
    LuaNetSendMsg.ResetStream()
    LuaNetSendMsg.m_pStream:WriteUShort(LuaNetCmd.UPDATE_FASHION_INFO)
    LuaNetSendMsg.m_pStream:WriteByte(5)
    LuaNetSendMsg.m_pStream:WriteUInt(ID)
    LuaNetSendMsg.m_pStream:WriteByte(Color)
    LuaNetSendMsg:SendMsg()
end


----------------------------宠物---------------------------
--[[
宠物修炼
]]
function LuaNetSendMsg:PetXiLian(index, attribute)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteByte(index)
    ------print("宠物兑换抗性")
    for i=1,16 do
        ------print(attribute[i])
        self.m_pStream:WriteByte(attribute[i])
    end
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 请求宠物列表
-- </summary>
function LuaNetSendMsg:ReqPetList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物回复天生技能
-- </summary>
function LuaNetSendMsg:ReqPetRecoBornSkill(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 增加宠物上限
-- </summary>
function LuaNetSendMsg:ReqPetAddUpper()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物洗练
-- </summary>
function LuaNetSendMsg:ReqPetXiLian(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物洗练替换
-- </summary>
function LuaNetSendMsg:ReqPetXiLianReplace(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物加点
-- </summary>
function LuaNetSendMsg:ReqPetAddPoints(index,tizhi, liliang, lingxing, minjie)
    --Debug.Log("加点：" + index + "体质：" + tizhi + "力量" + liliang + "灵性" + lingxing + "敏捷" + minjie)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteShort(tizhi)
    self.m_pStream:WriteShort(liliang)
    self.m_pStream:WriteShort(lingxing)
    self.m_pStream:WriteShort(minjie)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物重置属性点
-- </summary>
function LuaNetSendMsg:ReqPetResetPoints(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物出战
-- </summary>
function LuaNetSendMsg:ReqPetFight(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end
-- <summary>
-- 宠物改名
-- </summary>
function LuaNetSendMsg:ReqPetChangeName(index, name)
    ----print("宠物新的名字："..name)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteString(name)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物放生
-- </summary>
function LuaNetSendMsg:ReqPetFree(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 重置修炼点
-- </summary>
function LuaNetSendMsg:ReqResetXiuLianPoint(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 增加修炼经验
-- </summary>
-- <param name="type">0使用道具，1使用宠物经验</param>
-- <param name="itemid">道具id</param>
function LuaNetSendMsg:ReqAddPetXiuLianExp(index, type,  itemid)
    --Debug.Log("增加修炼经验道具："+index+"  " +type+"  "+itemid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(13)
    self.m_pStream:WriteByte(index)
    --self.m_pStream:WriteByte(type)
    if (type == 0) then
        self.m_pStream:WriteInt(itemid)
    else
        self.m_pStream:WriteInt(0)
    end
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 使用物品
-- </summary>
function LuaNetSendMsg:ReqUseItem(index, itemid)
    --Debug.Log("使用道具：" + index + "  " + itemid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteInt(itemid)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 解锁技能栏位
-- </summary>
-- <param name="index">宠物索引</param>
-- <param name="skillLocation">技能栏位置</param>
function LuaNetSendMsg:ReqOpenLock(index, skillLocation)
    --Debug.Log("解锁技能蓝 宠物索引--技能栏位置:" + index + "  " + skillLocation)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(14)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteByte(skillLocation)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 神兽领悟技能
-- </summary>
function LuaNetSendMsg:ReqShenShouReplaceSkill(index)
    --Debug.Log("解锁技能蓝 宠物索引--技能栏位置:" + index + "  " + skillLocation)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(21)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 学习技能
-- </summary>
-- <param name="index">宠物索引</param>
-- <param name="skillLocation">技能位置</param>
-- <param name="itemid">道具id</param>
function LuaNetSendMsg:ReqLearnSkill(index, skillLocation,itemid)
    ----print("学习技能书 宠物索引--技能栏位置--道具ID:"..index .."  " ..skillLocation .."  " ..itemid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(15)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteByte(skillLocation)
    self.m_pStream:WriteInt(itemid)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物技能遗忘
-- </summary>
-- <param name="index"></param>
function LuaNetSendMsg:ReqPetSkillLeft(index, skillindx)
    --Debug.Log("宠物技能遗忘 宠物索引:" + index + skillindx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(16)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteByte(skillindx)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物转生
-- </summary>
-- <param name="index"></param>
function LuaNetSendMsg:ReqPetZhuanSheng(index)
    --Debug.Log("宠物转生 宠物索引:" + index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(17)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

-- <summary>
-- 宠物合成
-- </summary>
-- <param name="index"></param>
function LuaNetSendMsg:ReqPetHecheng(petid)
    --Debug.Log("宠物合成 宠物id:" + petid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(19)
    self.m_pStream:WriteInt(petid)
    self:SendMsg(self.m_pStream)
end
---------------------------end宠物-------------------------

--[[
点击强化按钮
@type:1-装备栏，2-背包
@pos:装备位置ID
@lhItemId:幸运符道具ID
@lhNum:幸运符数量
@autoBuy:是否自动购买强化石（元宝）
]]
-- function LuaNetSendMsg:SendStrengthenReq(type,pos,lhItemId,lhNum,autoBuy)
--     local itemId = lhItemId or 0
--     local num =  lhNum or 0
--     self:ResetStream()
-- 	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_FORGE)
--     self.m_pStream:WriteByte(1)
-- 	self.m_pStream:WriteByte(type)
-- 	self.m_pStream:WriteWord(pos)
-- 	self.m_pStream:WriteWord(itemId)
-- 	self.m_pStream:WriteWord(num)
--     self.m_pStream:WriteByte(autoBuy)
-- 	self:SendMsg(self.m_pStream)
-- end

--升阶
-- function LuaNetSendMsg:SendUpgradeReq(type,pos,autoBuy)
--     self:ResetStream()
-- 	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_FORGE)
--     self.m_pStream:WriteByte(2)
--     self.m_pStream:WriteByte(type)
--     self.m_pStream:WriteWord(pos)
-- 	self.m_pStream:WriteByte(autoBuy)
--     self:SendMsg(self.m_pStream)
-- end

--[[淬炼
@type:1-装备栏，2-背包
@pos:装备位置ID
@selectIdx:选中符文索引
@itemArrPos:炼化石ID
@itemArrNum:炼化石数量
]]
-- function LuaNetSendMsg:SendCuiLianMsg(type,pos,selectIdx,itemId,itemNum)  
--     self:ResetStream()
-- 	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_FORGE)
-- 	self.m_pStream:WriteByte(3)
-- 	self.m_pStream:WriteByte(type)
-- 	self.m_pStream:WriteWord(pos)
-- 	self.m_pStream:WriteByte(selectIdx)
-- 	self.m_pStream:WriteWord(itemId)
-- 	self.m_pStream:WriteWord(itemNum)
-- 	self:SendMsg(self.m_pStream)
-- end

--[[请求炼化石增加属性
@type:1-装备栏，2-背包
@pos:装备位置ID
@selectIdx:选中符文索引(从1开始)
@itemId:炼化石道具ID
@num:炼化石数量
]]
-- function LuaNetSendMsg:QueryLianHuaStoneAttr(type,pos,selectIdx,itemId,num)  
--     local id = itemId
--     local itemNum = num
--     if id == nil then id = 0xffff itemNum = 0 end
--     self:ResetStream()
-- 	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_FORGE)
-- 	self.m_pStream:WriteByte(4)
-- 	self.m_pStream:WriteByte(type)
-- 	self.m_pStream:WriteWord(pos)
-- 	self.m_pStream:WriteByte(selectIdx)
-- 	self.m_pStream:WriteWord(id)
-- 	self.m_pStream:WriteWord(itemNum)
-- 	self:SendMsg(self.m_pStream)
-- end

----查询洗炼次数
--function LuaNetSendMsg:QueryXiLianCnt()  
--    self:ResetStream()
--	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_SHENGHUA)
--	self.m_pStream:WriteByte(1)
--	self:SendMsg(self.m_pStream)
--end

--[[
请求洗炼
@param bagType 装备在背包or装备栏
@param bagPos 装备位置
@param lock 装备属性锁定(二级制)
@param useItemId 材料id
]]
-- function LuaNetSendMsg:SendXiLianReq(bagType,bagPos,lock,useItemId)  
--     self:ResetStream()
-- 	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_FORGE)
-- 	self.m_pStream:WriteByte(5)
-- 	self.m_pStream:WriteByte(bagType)
-- 	self.m_pStream:WriteWord(bagPos)
-- 	self.m_pStream:WriteByte(lock)
-- 	self.m_pStream:WriteWord(useItemId)
-- 	self:SendMsg(self.m_pStream)
-- end

-- --保存洗炼结果
-- function LuaNetSendMsg:SendSaveXiLianInfoReq(bagType,bagPos)
-- 	self:ResetStream()
-- 	self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_EQUIP_FORGE)
-- 	self.m_pStream:WriteByte(6)
-- 	self.m_pStream:WriteByte(bagType)
-- 	self.m_pStream:WriteWord(bagPos)
-- 	self:SendMsg(self.m_pStream)
-- end

--[[
请求坐骑信息
]]
function LuaNetSendMsg:ReqHorseInfo()
    ------print("申请坐骑信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseOperate)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
坐骑守护技能洗练
]]
function LuaNetSendMsg:ReqHorseSkillXiLian(type)
    ------print("坐骑技能洗练")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseOperate)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--[[
坐骑守护技能洗练替换
]]
function LuaNetSendMsg:ReqHorseSkillXiLianReplace(type)
    ------print("坐骑技能洗练替换")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseOperate)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--[[
坐骑守护技能修炼
]]
function LuaNetSendMsg:ReqHorseSkillXiuLianReplace(type)
    ------print("坐骑守护技能修炼")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseOperate)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--[[
请求骑乘
]]
function LuaNetSendMsg:ReqHorseInfoRide()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseSet) 
    self.m_pStream:WriteByte(0) --opt 一位操作符,0，当最后幻化坐骑id=0的时候表示上下坐骑，不等于0的时候表示幻化，1表示设置守护
    self.m_pStream:WriteByte(0) --pos  宠物的位置ID
    self.m_pStream:WriteByte(0) --shouhutype, 守护的类型，只有1234
    self.m_pStream:WriteUInt(0) --幻化的坐骑id
    self:SendMsg(self.m_pStream)
end

--[[
坐骑幻化
]]
function LuaNetSendMsg:ReqHorseHuanHua(horseid)
    ------print("坐骑幻化id = "..horseid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseSet) 
    self.m_pStream:WriteByte(0) --opt 一位操作符,0，当最后幻化坐骑id=0的时候表示上下坐骑，不等于0的时候表示幻化，1表示设置守护
    self.m_pStream:WriteByte(0) --pos  宠物的位置ID
    self.m_pStream:WriteByte(0) --shouhutype, 守护的类型，只有1234
    self.m_pStream:WriteUInt(horseid) --幻化的坐骑id
    self:SendMsg(self.m_pStream)
end

--[[
坐骑守护宠物 type等于0时表示取消守护
]]
function LuaNetSendMsg:ReqHorseShouHuPet(type, petIndex)
    ------print("坐骑守护宠物 守护类型   宠物索引= "..type.."   "..petIndex)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_MDGAME_HorseSet) 
    self.m_pStream:WriteByte(1) --opt 一位操作符,0，当最后幻化坐骑id=0的时候表示上下坐骑，不等于0的时候表示幻化，1表示设置守护
    self.m_pStream:WriteByte(petIndex) --pos  宠物的位置ID
    self.m_pStream:WriteByte(type) --shouhutype, 守护的类型，只有1234
    self.m_pStream:WriteUInt(0) --幻化的坐骑id
    self:SendMsg(self.m_pStream)
end

--[[
商店购买商品
]]
function LuaNetSendMsg:ReqBuyItemNPCShop(type, pos, num)
    --[[
    +-----+-----+--------+----------+
    |  OP |Type |  Pos   |buyAmount |
    +-----+-----+--------+----------+
    |  1  |  1  |   2    |    4     |
    +-----+-----+--------+----------+
    Op:2发送购买的物品位置以及价格信息
    Type:type为1是装备，2为杂货店，3为药品店
    Pos:物品在商店中的位置
    buyAmount：购买数量
    ]]
    ------print("商店购买类型  物品位置  购买数量="..type.."  "..pos.." "..num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.NPC_SHOP) 
    self.m_pStream:WriteByte(2) --opt 
    self.m_pStream:WriteByte(type) 
    self.m_pStream:WriteUShort(pos) 
    self.m_pStream:WriteUInt(num)
    self:SendMsg(self.m_pStream)
end

----[[
--活动界面，获取活动数据
--]]
--function LuaNetSendMsg:ReqAllActivity()
--    self:ResetStream()
--    self.m_pStream:WriteUShort(LuaNetCmd.ACTIVITY) 
--    self.m_pStream:WriteByte(1)
--    self:SendMsg(self.m_pStream)
--end

----[[
--活动详细信息获取命令
--]]
--function LuaNetSendMsg:ReqActivityInfo(id)
--    self:ResetStream()
--    self.m_pStream:WriteUShort(LuaNetCmd.ACTIVITY) 
--    self.m_pStream:WriteByte(2) 
--    self.m_pStream:WriteByte(id) --ID
--    self:SendMsg(self.m_pStream)
--end

--[[
    领取活跃度奖励
]]
--function LuaNetSendMsg:ReqGetActReward(index)
--    self:ResetStream()
--    self.m_pStream:WriteUShort(LuaNetCmd.ACTIVITY) 
--    self.m_pStream:WriteByte(5) 
--    self.m_pStream:WriteByte(index) 
--    self:SendMsg(self.m_pStream)
--end

----[[
--    离开活动
--]]
--function LuaNetSendMsg:ReqLeaveActivity(id)
--    self:ResetStream()
--    self.m_pStream:WriteUShort(LuaNetCmd.ACTIVITY) 
--    self.m_pStream:WriteByte(4) 
--    self.m_pStream:WriteByte(id) 
--    self:SendMsg(self.m_pStream)
--end

----[[
--   抓鬼双倍开关
--]]
--function LuaNetSendMsg:ReqDoubleExc()
--    ------print("申请的服id = "..fuid)
--    self:ResetStream()
--    self.m_pStream:WriteUShort(LuaNetCmd.ACTIVITY)
--    self.m_pStream:WriteByte(6)
--    self:SendMsg(self.m_pStream)
--end

--[[
    点击NPC，弹出功能选择框，发送点击弹框里面按钮是第几个按钮
]]
function LuaNetSendMsg:ReqNpcDiaClick(num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.NPC_DIA_CLICK) 
    self.m_pStream:WriteInt(num) 
    self:SendMsg(self.m_pStream)
end

--[[
发送一条聊天信息
]]
function LuaNetSendMsg:ReqSendChatMessage(chatChannel,messageType,message)
    ----print("发送一条聊天信息的内容:"..chatChannel.."  "..messageType.."  "..message)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_CHAT_MESSAGE) 
    self.m_pStream:WriteByte(chatChannel) 
    self.m_pStream:WriteByte(messageType) 
    self.m_pStream:WriteString(message) 
    self.m_pStream:ChangeEventId(LTCPEvent.GameSendMsg)
    self:SendMsg(self.m_pStream)
end

--[[
发送一条好友聊天信息
]]
function LuaNetSendMsg:ReqSendFriendMessage(messageType,id,message)
    ------print("一条聊天信息的内容:"..id.."  "..messageType.."  "..message)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_CHAT_MESSAGE) 
    self.m_pStream:WriteByte(5) 
    self.m_pStream:WriteByte(messageType)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteString(message) 
    self:SendMsg(self.m_pStream)
end

--[[
获取全部技能信息
]]
function LuaNetSendMsg:ReqSendSkills()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.Init_Role_Skill) 
    self:SendMsg(self.m_pStream)
end

--[[
升级其中一个技能的信息
]]
function LuaNetSendMsg:ReqSendLevelUpSkill(id, pos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_LEARN_SKILL) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteWord(id)
    self.m_pStream:WriteWord(pos)
    ----print("LuaNetSendMsg:ReqSendLevelUpSkill " .. id)
    self:SendMsg(self.m_pStream)
end

--[[
  一键升级
]]
function LuaNetSendMsg:ReqSendYiJianLevelUpSkill(id, pos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_LEARN_SKILL) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteWord(id)
    self.m_pStream:WriteWord(pos)
    self:SendMsg(self.m_pStream)
end

--[[
  一键升级
]]
function LuaNetSendMsg:QueryNextSkillDep(skillid ,level)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_SKILLPART_INFO) 
    self.m_pStream:WriteUShort(skillid)
    self.m_pStream:WriteByte(level)
    ----print("NetSendMsg QueryNextSkillDep " .. skillid)
    self:SendMsg(self.m_pStream)
end


--[[
    请求伙伴试炼信息
]]
function LuaNetSendMsg:ReqSendHuobanShilian()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.HUOBANSHILIAN_ACTIVITY) 
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
    离开伙伴试炼信息
]]
function LuaNetSendMsg:ReqSendLeaveHuobanShilian()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.ACTIVITY) 
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(8)    
    self:SendMsg(self.m_pStream)
end

--[[
召唤伙伴
]]
function LuaNetSendMsg:ReqSendZhaoHuanhuoban(partnerID)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.Partner_Info)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(partnerID)
    self:SendMsg(self.m_pStream)
end

--[[
伙伴战斗
]]
function LuaNetSendMsg:ReqPartnerFighting(partnerID)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.Partner_Info)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(partnerID)
    self:SendMsg(self.m_pStream)
end

--[[
伙伴培养
]]
function LuaNetSendMsg:ReqPartnerPeiYang(partnerID,itemid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.Partner_Info)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteInt(partnerID)
    self.m_pStream:WriteInt(itemid)
    self:SendMsg(self.m_pStream)
end

--[[
伙伴转生
]]
function LuaNetSendMsg:ReqPartnerZhuanSheng(partnerID)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.Partner_Info)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteInt(partnerID)
    self:SendMsg(self.m_pStream)
end

--[[
    查询好友信息
]]
function LuaNetSendMsg:ReqSendGetAllFriends()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
    查询推荐
]]
function LuaNetSendMsg:ReqSendTuijianFriends()
    ------print("我发送了查询好友推荐")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
    查询好友
]]
function LuaNetSendMsg:ReqSendSearchFriends(str)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(3)
     self.m_pStream:WriteString(str)
    self:SendMsg(self.m_pStream)
end

--[[
    请求添加好友，申请
]]
function LuaNetSendMsg:ReqSendAddFriends(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    --通过或者拒绝好友申请
]]
function LuaNetSendMsg:ReqSendAcceptFriend(id,bAccept)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteByte(bAccept)
    self:SendMsg(self.m_pStream)
end

--[[
    --删除好友
]]
function LuaNetSendMsg:ReqSendDeleteFriends(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    --添加黑名单
]]
function LuaNetSendMsg:ReqSendGoToFrBlack(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    --取消黑名单
]]
function LuaNetSendMsg:ReqSendGoOutFrBlack(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    --设置好友备注
]]
function LuaNetSendMsg:ReqSendSetFrNickName(id,str)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteString(str)
    self:SendMsg(self.m_pStream)
end

--[[
    --定时刷新好友状态
]]
function LuaNetSendMsg:ReqSendUpdataFrState()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.FRIENDS) 
    self.m_pStream:WriteByte(11)
    self:SendMsg(self.m_pStream)
end

--[[
    --触发接收邮箱信息
]]
function LuaNetSendMsg:ReqSendEmailState()
    ------print("我要获取所有邮件信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EMAIL) 
    self.m_pStream:WriteByte(0)
    self:SendMsg(self.m_pStream)
end

--[[
    --打开邮件信息
]]
function LuaNetSendMsg:ReqSendOpenEmail(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EMAIL) 
    self.m_pStream:WriteByte(1)
    ------print("我打开的邮件ID为" .. id)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    --领取奖励
]]
function LuaNetSendMsg:ReqSendGetRewardEmail(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EMAIL) 
    self.m_pStream:WriteByte(2)
    ------print("我发送的邮件ID为" .. id)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    --删除邮件
]]
function LuaNetSendMsg:ReqSendDeleteEmail(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EMAIL) 
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

-- function LuaNetSendMsg:QueryIsExitApply()
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
--     self.m_pStream:WriteByte(30)
--     self:SendMsg(self.m_pStream)
-- end

function LuaNetSendMsg:QueryFactionList()
--print("QueryFactionList")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
    Utils:ShowWaiting(LuaNetCmd.MSG_BANGPAI)
end

function LuaNetSendMsg:QueryBangPaiJoin(id)
    --print("QueryBangPaiJoin",id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionMemberList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(10)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MY_BANG)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionExit()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(12)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionDrawWages()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(24)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiCreateCost()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(0)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiCreateByMoney(name, content, pic, level)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)

    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(content)
    self.m_pStream:WriteUInt(pic or 0)
    self.m_pStream:WriteWord(level or 0)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionInvite(roleid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteUInt(roleid)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionInviteAll(dataList)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(#dataList)
    for i=1,#dataList do
        self.m_pStream:WriteUInt(dataList[i].roleId)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionApplyList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(8)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionDealApply(type, roleid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteUInt(roleid)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionDealAllApply(type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(23)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionDealInvite(type, id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUInt(id)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryIsShowBPName(val)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(32)
    self.m_pStream:WriteByte(val)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBpSkilllevelUpData(op)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--upgradeType(1-个人， 2-帮派) isAllUp 1 是 0 否
function LuaNetSendMsg:QueryBpSkilllevelUp(op, upgradeType, killId, isAllUp)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(upgradeType)
    self.m_pStream:WriteWord(killId)
    self.m_pStream:WriteByte(isAllUp)
    self:SendMsg(self.m_pStream)
end


function LuaNetSendMsg:QuerylevelUpKeji(op, type)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--帮战：op-1帮战列表2倒计时3行动力4排行榜6参战8塔的数据9占塔后更新塔的数据10中断占塔19伤害榜
function LuaNetSendMsg:QueryBangPaiWarInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAIWAR)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--帮战：攻击
function LuaNetSendMsg:SendBangPaiWarAttack(id)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAIWAR)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end
--境界 消息
function LuaNetSendMsg:JingjieMsg(op)

     


    -- if isShow == 0 then
    --     return
    -- end
    -- if _type == 0 then
    --     if LRoleDataMgr.Social.CoupleInfo.IsShowName then
    --         LuaNetSendMsg:QueryMarriageInfo(4, 0)
    --     end
    --     if LRoleDataMgr.MyHeroInfo.showMasterName ~= 0 then
    --         LuaNetSendMsg:QueryHideMasterName(0)
    --     end
    --     if LRoleDataMgr.MyHeroInfo.jingjieIsshow ~= 0 then
    --         LuaNetSendMsg:QueryJingJieInfo(2, 0)
    --     end
    -- elseif _type == 1 then
    --     if LRoleDataMgr.Faction.Info.isShowBPName ~= 0 then
    --         LuaNetSendMsg:QueryIsShowBPName(0)
    --     end
    --     if LRoleDataMgr.Social.CoupleInfo.IsShowName then
    --         LuaNetSendMsg:QueryMarriageInfo(4, 0)
    --     end
    --     if LRoleDataMgr.MyHeroInfo.jingjieIsshow ~= 0 then
    --         LuaNetSendMsg:QueryJingJieInfo(2,0)
    --     end
    -- elseif _type == 2 then
    --     if LRoleDataMgr.MyHeroInfo.showMasterName ~= 0 then
    --         LuaNetSendMsg:QueryHideMasterName(0)
    --     end
    --     if LRoleDataMgr.Faction.Info.isShowBPName ~= 0 then
    --         LuaNetSendMsg:QueryIsShowBPName(0)
    --     end
    --     if LRoleDataMgr.MyHeroInfo.jingjieIsshow ~= 0 then--隐藏境界
    --         LuaNetSendMsg:QueryJingJieInfo(2,0)
    --     end
    -- elseif _type == 3 then --境界名称
    --     if LRoleDataMgr.Social.CoupleInfo.IsShowName then
    --         LuaNetSendMsg:QueryMarriageInfo(4, 0)
    --     end
    --     if LRoleDataMgr.MyHeroInfo.showMasterName ~= 0 then
    --         LuaNetSendMsg:QueryHideMasterName(0)
    --     end
    --     if LRoleDataMgr.Faction.Info.isShowBPName ~= 0 then
    --         LuaNetSendMsg:QueryIsShowBPName(0)
    --     end
    -- end
end

function LuaNetSendMsg:DealHeroTitleShow(_type, isShow)
    if isShow == 0 then
        return
    end
    if _type == 0 then
        if LRoleDataMgr.Social.CoupleInfo.IsShowName then
            LuaNetSendMsg:QueryMarriageInfo(4, 0)
        end
        if LRoleDataMgr.MyHeroInfo.showMasterName ~= 0 then
            LuaNetSendMsg:QueryHideMasterName(0)
        end
        if LRoleDataMgr.MyHeroInfo.jingjieIsshow ~= 0 then
            LuaNetSendMsg:QueryJingJieInfo(2, 0)
        end
    elseif _type == 1 then
        if LRoleDataMgr.Faction.Info.isShowBPName ~= 0 then
            LuaNetSendMsg:QueryIsShowBPName(0)
        end
        if LRoleDataMgr.Social.CoupleInfo.IsShowName then
            LuaNetSendMsg:QueryMarriageInfo(4, 0)
        end
        if LRoleDataMgr.MyHeroInfo.jingjieIsshow ~= 0 then
            LuaNetSendMsg:QueryJingJieInfo(2,0)
        end
    elseif _type == 2 then
        if LRoleDataMgr.MyHeroInfo.showMasterName ~= 0 then
            LuaNetSendMsg:QueryHideMasterName(0)
        end
        if LRoleDataMgr.Faction.Info.isShowBPName ~= 0 then
            LuaNetSendMsg:QueryIsShowBPName(0)
        end
        if LRoleDataMgr.MyHeroInfo.jingjieIsshow ~= 0 then--隐藏境界
            LuaNetSendMsg:QueryJingJieInfo(2,0)
        end
    elseif _type == 3 then --境界名称
        if LRoleDataMgr.Social.CoupleInfo.IsShowName then
            LuaNetSendMsg:QueryMarriageInfo(4, 0)
        end
        if LRoleDataMgr.MyHeroInfo.showMasterName ~= 0 then
            LuaNetSendMsg:QueryHideMasterName(0)
        end
        if LRoleDataMgr.Faction.Info.isShowBPName ~= 0 then
            LuaNetSendMsg:QueryIsShowBPName(0)
        end
    end
end

function LuaNetSendMsg:QueryMarriageInfo(op, _type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_COUPLE)
    self.m_pStream:WriteByte(op)
    if(op ~= 5 and op ~= 11 and op ~= 13 and op ~= 25 and (not(op >= 18 and op <= 23)) and op ~= 27 and op ~= 29  and (not(op >= 31 and op <= 34))) then
        self.m_pStream:WriteByte(_type)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryHideMasterName(show)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_COUPLE)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteByte(show)
    self:SendMsg(self.m_pStream)
end
--境界
--[[
境界操作
op 3 领取俸禄
op 2 显示或隐藏
op 1 获取境界信息
op 4 突破信息
]]
function LuaNetSendMsg:QueryJingJieInfo(op, param1)
   if op == 4 then
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.MSG_JINGJIE)
        self.m_pStream:WriteByte(op)
        self:SendMsg(self.m_pStream)
   end
end

function LuaNetSendMsg:QueryFactionChangeAnnoucement(str)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(16)
    self.m_pStream:WriteString(str)
    self:SendMsg(self.m_pStream)
end

--[[
帮派事件
]]
function LuaNetSendMsg:QueryFactionZoneInfo()
    --print("----------------QueryFactionZoneInfo---------------")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(28)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiEnterZone(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(27)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGodTreeDetail(factionId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(18)
    self.m_pStream:WriteUInt(factionId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGodTreePray(factionId, type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(19)
    self.m_pStream:WriteUInt(factionId)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteUInt(factionId)
    self.m_pStream:WriteByte(areaIdx)
    self.m_pStream:WriteByte(cellIdx)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionPlantCellDetail( factionId, areaIdx, cellIdx)
    LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, 2)
end

function LuaNetSendMsg:QueryFactionPlantInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteUInt(factionId)
    self.m_pStream:WriteByte(areaIdx)
    self.m_pStream:WriteByte(cellIdx)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionPlantSeed(factionId, areaIdx, cellIdx, itemId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUInt(factionId);
    self.m_pStream:WriteWord(itemId);
    self.m_pStream:WriteByte(areaIdx);
    self.m_pStream:WriteByte(cellIdx);
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionPlantWater(factionId, areaIdx, cellIdx)
    LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, 4)
end

function LuaNetSendMsg:QueryFactionPlantBug(factionId, areaIdx, cellIdx)
    LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, 5)
end

function LuaNetSendMsg:QueryFactionPlantDig(factionId, areaIdx, cellIdx)
    LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, 6)
end

function LuaNetSendMsg:QueryFactionPlantSteal(factionId, areaIdx, cellIdx)
    LuaNetSendMsg:QueryFactionPlantAction(factionId, areaIdx, cellIdx, 8)
end

function LuaNetSendMsg:QueryFactionGodGreeCanRob(factionId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteUInt(factionId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGodGreeRob(factionId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(21)
    self.m_pStream:WriteUInt(factionId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionMagicFireOpr(factionId, isFire)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(isFire and 15 or 16)
    self.m_pStream:WriteUInt(factionId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGuardInfo(factionId, guardIdx, isDetail)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(13)
    self.m_pStream:WriteUInt(factionId)
    self.m_pStream:WriteByte(guardIdx)
    self.m_pStream:WriteByte(Utils:ToBool(isDetail) and 2 or 1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGuardSet(factionId, guardIdx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteUInt(factionId)
    self.m_pStream:WriteByte(guardIdx)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGuardRemove(factionId, guardIdx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteUInt(factionId)
    self.m_pStream:WriteByte(guardIdx)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionJuanXianRecord()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(39)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionJuanXianMsg()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(37)
    self:SendMsg(self.m_pStream)
end

--请求捐献金币
function LuaNetSendMsg:QueryFactionJuanXian(pTy)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(38)
    self.m_pStream:WriteByte(pTy)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryPublishFactionTask(pMiId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(36)
    self.m_pStream:WriteUInt(pMiId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryWorshipInfo(op, index, roleId, roleType)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WORSHIP_INFO)
    self.m_pStream:WriteByte(op)
    if op ~= 2 then
        self.m_pStream:WriteUInt(index)
        self.m_pStream:WriteUInt(roleId)
        self.m_pStream:WriteByte(roleType)
    end
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryFactionXianZunGe()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(26)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionUpXianZunGe()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(27)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionGetTaskReward(missionId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(36)
    self.m_pStream:WriteUInt(missionId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryMobaiInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WORSHIP_INFO)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryTakeFactionAward()
    local waitAniData = {
                            key = LuaNetCmd.MSG_BANGPAI, 
                            waitMsg = "",
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteWord(29)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionFireMember(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryNominateFactionBoss(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(19)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionChangePostIndex(id, idx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteUInt(id)
    self.m_pStream:WriteByte(idx)
    self:SendMsg(self.m_pStream)
end

-- function LuaNetSendMsg:QueryHideMasterName(show)
-- end

--[[
请求帮派列表 page表示第几页内容
]]
function LuaNetSendMsg:ReqSendBangPaiList(page)
    ------print("请求帮派列表=="..page)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteByte(page)
    self:SendMsg(self.m_pStream)
end

--[[
帮派邀请 ,id = 被邀请人ID
]]
function LuaNetSendMsg:ReqSendBangPaiYaoQing(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(15)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
接受帮派邀请 ,id = 帮派ID
]]
function LuaNetSendMsg:ReqAcceBangPaiYaoQing(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(16)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end


--[[
请求帮派列表 page表示第几页内容
]]
function LuaNetSendMsg:ReqSearchBangPaiList(data)
    ------print("请求帮派列表=="..page)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(14)
    self.m_pStream:WriteString(data)
    self:SendMsg(self.m_pStream)
end

--[[
创建帮派
]]
function LuaNetSendMsg:ReqSendBangPaiCreate(name,notice)
    ------print("创建的帮派名字---帮派宗旨="..name.."   "..notice)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteString(name)
    self.m_pStream:WriteString(notice)
    self:SendMsg(self.m_pStream)
end

--[[
请求帮派信息
]]
function LuaNetSendMsg:ReqBangPaiInfo()
    ------print("请求帮派信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(8)
    self:SendMsg(self.m_pStream)
end

--[[
设置是否自动加入帮派 
]]
function LuaNetSendMsg:ReqSetAutoJoinBangPai(auto, id)
    ------print("设置是否自动加入帮派="..auto)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(auto)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
申请加入一个帮派
]]
function LuaNetSendMsg:ReqJoinBangPai(id)
    ------print("申请加入一个帮派="..id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
一键申请帮派
]]
function LuaNetSendMsg:ReqOneKeyJoinBangPai()
    ------print("一键申请帮派")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
获取帮派申请列表
]]
function LuaNetSendMsg:ReqBangPaiRequestList(bangpaiid)
    ----print("<color=red>获取帮派申请列表:此处应该根据职位判断是否需要申请,还没做判断</color>")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteInt(0)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
同意玩家入盟
]]
function LuaNetSendMsg:ReqBangPaiJoin(bangpaiid,playerid)
    ------print("同意玩家入盟="..bangpaiid.."  "..playerid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteInt(playerid)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
离开帮派
]]
function LuaNetSendMsg:ReqLevelBangPai(bangpaiid)
    ------print("离开帮派="..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteInt(bangpaiid)
    self:SendMsg(self.m_pStream)
end

--[[
移除成员
]]
function LuaNetSendMsg:ReqForceLevelBangPai(bangpaiid,playerid)
    ------print("离开帮派="..bangpaiid.."  "..playerid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteInt(playerid)
    self:SendMsg(self.m_pStream)
end

--[[
设置职位  
EBRBangZhu = 1,   --1-帮主
EBRFuBangZhu,     --2-副帮主
EBRYouHuFa,         --3- 右护法
EBRZuoHuFa,          --4-左护法
EBRZhangLao,      --5-长老
EBRTangZhu,         --6-堂主
EBRBangZhong,     --7-帮众
]]
function LuaNetSendMsg:ReqSetBangPaiZhiWei(bangpaiid,playerid,zhiwei)
    ------print("设置职位"..bangpaiid.."  "..playerid.."   "..zhiwei)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteInt(playerid)
    self.m_pStream:WriteByte(zhiwei)
    self:SendMsg(self.m_pStream)
end

--[[
移除职位
]]
function LuaNetSendMsg:ReqLevelBangPaiOffice(bangpaiid,playerid)
    ------print("设置职位"..bangpaiid.."  "..playerid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteInt(playerid)
    self:SendMsg(self.m_pStream)
end

--[[
增加帮贡
]]
function LuaNetSendMsg:ReqBangPaiBangGong(bangpaiid,value)
    ------print("增加帮贡的数量"..value)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteInt(value)
    self:SendMsg(self.m_pStream)
end

--[[
增加修炼经验
]]
function LuaNetSendMsg:ReqBangPaiXiuLianExp(bangpaiid,value)
    ------print("增加修炼经验的数量"..value)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteInt(value)
    self:SendMsg(self.m_pStream)
end


--[[
修炼哪种技能
]]
function LuaNetSendMsg:ReqBangPaiXiuLianType(bangpaiid,type)
    ------print("修炼哪种技能"..type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(type)
    self:SendMsg(self.m_pStream)
end

--[[
重置修炼
]]
function LuaNetSendMsg:ReqBangPaiXiuLianReset(bangpaiid)
    ------print("重置修炼")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end

--[[
帮派捐献
]]
function LuaNetSendMsg:ReqBangPaiDonate(bangpaiid,value)
    ------print("捐献的数量"..bangpaiid.."--"..value)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteInt(value)
    self:SendMsg(self.m_pStream)
end

--[[
帮派捐献详情
]]
function LuaNetSendMsg:ReqBangPaiDonateInfo(bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(5)
    self:SendMsg(self.m_pStream)
end

--[[
修改帮派宗旨
]]
function LuaNetSendMsg:ReqBangPaiEditerAim(bangpaiid,message)
    ------print("修改帮派宗旨--"..message)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(0)
    self.m_pStream:WriteString(message)
    self:SendMsg(self.m_pStream)
end

--[[
修改帮派公告
]]
function LuaNetSendMsg:ReqBangPaiEditerChat(bangpaiid,message)
    ------print("修改帮派公告--"..message)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteString(message)
    self:SendMsg(self.m_pStream)
end

--[[
帮派升级
]]
function LuaNetSendMsg:ReqBangPaiLevelUp(bangpaiid)
    ------print("帮派升级--"..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
帮派合并申请
]]
function LuaNetSendMsg:ReqBangPaiMerge(bangpaiid)
    ------print("帮派合并申请--"..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
取消帮派合并申请
]]
function LuaNetSendMsg:ReqBangPaiCancelMerge(bangpaiid)
    ------print("帮派合并申请--"..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(0)
    self:SendMsg(self.m_pStream)
end

--[[
请求领取奖励状态
]]
function LuaNetSendMsg:ReqBangPaiRewardState(bangpaiid)
    ------print("请求领取奖励状态--"..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(0)--请求领取俸禄 
    self:SendMsg(self.m_pStream)
end

--[[
领取俸禄
]]
function LuaNetSendMsg:ReqBangPaiFengLu(bangpaiid)
    ------print("领取俸禄--"..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
宠物参战
]]
function LuaNetSendMsg:ReqPetFight(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PET_INFO)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
领取功臣奖励（活跃度奖励）
]]
function LuaNetSendMsg:ReqBangPaiGongChenReward(bangpaiid)
    ------print("领取功臣奖励（活跃度奖励）--"..bangpaiid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteInt(bangpaiid)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
获取已经申请的帮派信息
]]
function LuaNetSendMsg:ReqShenQingBangPai()
    ------print("申请已经申请的帮派信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(11)
    self:SendMsg(self.m_pStream)
end

--[[
回到帮派信息
]]
function LuaNetSendMsg:ReqReturnBangPai()
    ------print("申请已经申请的帮派信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI) 
    self.m_pStream:WriteByte(13)
    self:SendMsg(self.m_pStream)
end

--[[
驯养坐骑
]]
function LuaNetSendMsg:ReqXunYangHorse(num)
    ------print("驯养坐骑"..num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.OPEN_NPC) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(num)
    self:SendMsg(self.m_pStream)
end

--[[
驯养宠物
]]
function LuaNetSendMsg:ReqXunYangPet(index,num)
    ------print("驯养宠物"..index.."   "..num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.OPEN_NPC) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(index)
    self.m_pStream:WriteByte(num)
    self:SendMsg(self.m_pStream)
end

--[[
人物转生
]]
function LuaNetSendMsg:ReqRoleInfoZhuanSheng(index)
    ------print("人物转生"..index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.ZHUANGSHENG) 
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
领取福神降临
]]
function LuaNetSendMsg:ReqLingquFushen(id)
    ------print("领取福神降临"..id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.BAOTULINGQU) 
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
神器合成 
]]
function LuaNetSendMsg:ReqShenQiHeCheng()
    ------print("神器合成")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EQUIP_SHENQI) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
神器进阶 
]]
function LuaNetSendMsg:ReqShenQiJinJie(op,index1,index2,index3)
    ----print("神器进阶..op="..op.."=="..index1.."=="..index2.."=="..index3)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EQUIP_SHENQI) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(op)
    if op == 1 then
        self.m_pStream:WriteByte(index1)
        self.m_pStream:WriteByte(index2)
        self.m_pStream:WriteByte(index3)
    elseif op ==  2 then
        self.m_pStream:WriteByte(index1)
        self.m_pStream:WriteByte(index2)
    end
    
    self:SendMsg(self.m_pStream)
end

--[[
神器重铸 
]]
function LuaNetSendMsg:ReqShenQiChongZhu(index)
    ------print("神器重铸.."..index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EQUIP_SHENQI) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
  请求商城数据,根据类型请求
    1奇异珍宝
    2强化材料
    3每周限购
    4时装
]]
function LuaNetSendMsg:ReqMallInfo(index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MALL) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
  购买商城道具
]]
function LuaNetSendMsg:ReqBuyMall(id,count)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MALL) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteInt(count)
    self:SendMsg(self.m_pStream)
end

--[[
帮战发送pk请求
]]
function LuaNetSendMsg:ReqSendPK(id)
    ------print("帮战发送pk请求=" .. id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.BANGZHAN) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
直接复活
]]
function LuaNetSendMsg:ReqSendFuHuo()
    ------print("直接复活")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.BANGZHAN) 
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end

--[[
复活缩短cd
]]
function LuaNetSendMsg:ReqSendReduceCD()
    ------print("复活cd")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.BANGZHAN) 
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
女神像选择选项
]]
function LuaNetSendMsg:ReqSendNvShenOption(option)
    ------print("option"..option)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.BANGZHAN) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(option)
    self:SendMsg(self.m_pStream)
end

--[[
答题 回答问题
]]
function LuaNetSendMsg:ReqSendQuestion(question, index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.TongTianTa) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteInt(question)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
获取通天塔积分商城
]]
function LuaNetSendMsg:ReqSendTongTianTaShop(id,number)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.TongTianTa) 
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteInt(number)
    self:SendMsg(self.m_pStream)
end

--[[
退出通天塔 帮战等的场景
]]
function LuaNetSendMsg:ReqSendExitScene()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.EXITSCENE) 
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end

--[[
竞技场信息 获取个人竞技场挑战成员信息
]]
function LuaNetSendMsg:ReqPersonalJingJiChangInfo()
    ------print("竞技场信息 请求服务器获取个人竞技场挑战成员信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
竞技场信息 刷新个人竞技场挑战成员信息
]]
function LuaNetSendMsg:ReqRefreshPersonalJingJiChangInfo()
    ------print("竞技场信息 刷新个人竞技场挑战成员信息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:ReqChangeScene(id,x,z,angel )
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JUMPSCENE)
    self.m_pStream:WriteUShort(id)
    self.m_pStream:WriteUShort(x)
    self.m_pStream:WriteUShort(z)
    self.m_pStream:WriteUShort(angel)
    self:SendMsg(self.m_pStream)
end


--[[
竞技场信息 挑战玩家信息
]]
function LuaNetSendMsg:ReqPersonalJingJiChallenge(id)
    -- ----print("竞技场信息 挑战玩家信息 "..id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
申请战报
]]
function LuaNetSendMsg:ReqPersonalJingJiReport()
    ------print("申请战报 ")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(5)
    self:SendMsg(self.m_pStream)
end

--[[
竞技场商店
]]
function LuaNetSendMsg:ReqPersonalJingJiShopBuy(id,num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteInt(num)
    self:SendMsg(self.m_pStream)
end

--[[
3V3竞技场报名确认
]]
function LuaNetSendMsg:Req3v3JingJiAffirm(tuantiid,flag)
    ------print("3V3竞技场报名确认 "..flag)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(tuantiid)
    self.m_pStream:WriteByte(flag)
    self:SendMsg(self.m_pStream)
end

--[[
3V3竞技场请求查看轮数信息
]]
function LuaNetSendMsg:Req3v3JingJiLunShuInfo()
    ------print("3V3竞技场请求查看轮数信息 ")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
end

--[[
3V3竞技场请求查看场数信息
]]
function LuaNetSendMsg:Req3v3JingJiChangShuInfo()
    ------print("3V3竞技场请求查看场数信息 ")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(7)
    self:SendMsg(self.m_pStream)
end

--[[
3V3竞技场退出比赛
]]
function LuaNetSendMsg:Req3v3JingJiExitInfo()
    ------print("3V3竞技场退出比赛 ")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end


--[[集市功能协议 1请求摆摊信息]]
function LuaNetSendMsg:ReqFairInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 2查询系统价格]]
function LuaNetSendMsg:ReqLoadPrice(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 3上架]]
function LuaNetSendMsg:ReqSellItem(Sind,Type,Pind,num,price)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(Sind)
    self.m_pStream:WriteByte(Type)
    self.m_pStream:WriteByte(Pind)
    self.m_pStream:WriteShort(num)
    self.m_pStream:WriteInt(price)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 4下架]]
function LuaNetSendMsg:ReqTakeDownItem(Sind)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(Sind)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 5重新上架]]
function LuaNetSendMsg:ReqSellItemOneMore(Sind,price)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteByte(Sind)
    self.m_pStream:WriteInt(price)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 6提现]]
function LuaNetSendMsg:ReqFairGetMoney(Sind)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(Sind)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 7购买区查询]]
function LuaNetSendMsg:ReqGetBuyData()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(7)
    self:SendMsg(self.m_pStream)
end


--[[集市功能协议 8购买]]
function LuaNetSendMsg:ReqBuyItem(SID,NUM)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteString(SID)
    self.m_pStream:WriteInt(NUM)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 9公示区查询]]
function LuaNetSendMsg:ReqGetPubliceData()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 10添加关注]]
function LuaNetSendMsg:ReqAddGuanzhu(str)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteString(str)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 11查询关注]]
function LuaNetSendMsg:ReqGetGuanzhuData()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(11)
    self:SendMsg(self.m_pStream)
end

--[[集市功能协议 12查询交易记录]]
function LuaNetSendMsg:ReqGetRecordData()
    ------print("我查询了交易记录")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_BAZAAR) 
    self.m_pStream:WriteByte(12)
    self:SendMsg(self.m_pStream)
end

--[[
测试切磋的
]]
function LuaNetSendMsg:ReqTextPK(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PK) 
    self.m_pStream:WriteInt(id) 
    self:SendMsg(self.m_pStream)
end

--[[
发布结拜信息
]]
function LuaNetSendMsg:ReqSendJieBaiInfo(info)
    ------print("发布结拜信息 "..info)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteString(info) 
    self:SendMsg(self.m_pStream)
end

--[[
换一批结拜信息
]]
function LuaNetSendMsg:ReqChangeJieBaiList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
end

--[[
邀请结拜
]]
function LuaNetSendMsg:ReqYaoQingJieBai(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
邀请结拜确认
]]
function LuaNetSendMsg:ReqYaoQingJieBaiQueRen(roleid,flag)
    ------print("邀请结拜确认 "..roleid.."   "..flag)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteInt(roleid)
    self.m_pStream:WriteByte(flag)
    self:SendMsg(self.m_pStream)
end

--[[
结拜者退出
]]
function LuaNetSendMsg:ReqSendJieBaiRun()
    ------print("结拜者退出")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(10)
    self:SendMsg(self.m_pStream)
end

--[[
发起者结拜取消
]]
function LuaNetSendMsg:ReqSendJieBaiFaQiZheRun()
    ------print("发起者结拜取消")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(11)
    self:SendMsg(self.m_pStream)
end

--[[
发起结拜
]]
function LuaNetSendMsg:ReqSendJieBaiRequest(name)
    ------print("发送结拜请求 "..name)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteString(name)
    self:SendMsg(self.m_pStream)
end

--[[
是否确认结拜
]]
function LuaNetSendMsg:ReqJieBaiQueRen(flag)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(14)
    self.m_pStream:WriteByte(flag)
    self:SendMsg(self.m_pStream)
end

--[[
添加结拜
]]
function LuaNetSendMsg:ReqAddJieBaiMember()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(17)
    self:SendMsg(self.m_pStream)
end

--[[
退出结拜
]]
function LuaNetSendMsg:ReqExitJieBaiMember()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(18)
    self:SendMsg(self.m_pStream)
end

--[[
修改结拜称谓
]]
function LuaNetSendMsg:ReqChangeJieBaiName(name)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteString(name)
    self:SendMsg(self.m_pStream)
end

--[[
打开确认修改结拜名字
]]
function LuaNetSendMsg:ReqQueRenChangeJieBaiName()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(21)
    self:SendMsg(self.m_pStream)
end

--[[
同意结拜称谓
]]
function LuaNetSendMsg:ReqQueRenJieBaiName(flag)
    ------print("同意结拜称谓 "..flag)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JIEBAI) 
    self.m_pStream:WriteByte(22)
    self.m_pStream:WriteByte(flag)
    self:SendMsg(self.m_pStream)
end

--[[
离开观战
]]
function LuaNetSendMsg:ReqLeaveLookBattle()
    ------print("同意结拜称谓 "..flag)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.LEAVE_LOOKBATTLE) 
    self:SendMsg(self.m_pStream)
end

--[[
喊话宣传
]]
function LuaNetSendMsg:ReqHanHuaSend()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.XUANCHUAN) 
    self:SendMsg(self.m_pStream)
end

--[[
    类似引导任务，需要客户端主动告诉服务器任务完成
]]
function LuaNetSendMsg:ReqGuideSucSend(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.GUIDE) 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    查询打开对其他玩家数据，可能打开操作界面
]]
function LuaNetSendMsg:ReqPlayerOperation(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PlayerOperation)
    --self.m_pStream:WriteByte(1)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
    查询最近联系人数据
]]
function LuaNetSendMsg:ReqTempFriends(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PlayerOperation)
    --self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:ReqOKToInviteTeam(id,rec)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteInt(id)
    self.m_pStream:WriteByte(rec)
    self:SendMsg(self.m_pStream)
end

--[[
开始巡逻
]]
function LuaNetSendMsg:ReqShuaDaoXunLuo()
    ----print("开始巡逻")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.SHUADAO)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
申请离线消息数据
]]
function LuaNetSendMsg:ReqLiXianXiaoXi()
    ----print("我申请了离线消息记录")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.LIXIANXIAOXI)
    self:SendMsg(self.m_pStream)
end

--[[
查询生活技能
]]
function LuaNetSendMsg:ReqLookLifeSkill()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.LifeSKILL)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
生活技能升级
]]
function LuaNetSendMsg:ReqLifeSkillLevelUp(skilltype)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.LifeSKILL)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(skilltype)
    self:SendMsg(self.m_pStream)
end

--[[
生活技能升级
]]
function LuaNetSendMsg:ReqLifeSkillMake(skilltype,itemid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.LifeSKILL)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(skilltype)
    self.m_pStream:WriteInt(itemid)
    self:SendMsg(self.m_pStream)
end

--[[
发送申请伙伴列表的消息
]]
function LuaNetSendMsg:ReqPartnerList()
    ----print("向服务器发送申请伙伴列表的消息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_PARTNER_INFO)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
招募伙伴的消息
]]
function LuaNetSendMsg:ReqPartnerCall(partnerid)
    ----print("发送招募伙伴的消息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_PARTNER_INFO)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteInt(partnerid)
    self:SendMsg(self.m_pStream)
end

--[[
伙伴出战的消息
]]
function LuaNetSendMsg:ReqPartnerFighting(partnerid)
    ----print("发送伙伴出战的消息")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.PRO_PARTNER_INFO)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(partnerid)
    self:SendMsg(self.m_pStream)
end

--[[
  申请挑战消息1V1
]]

function LuaNetSendMsg:ReqTiaozhan(id)
    ----print("tiaozhan 1v1=============="..id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:RefreshDuishou()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
申请战报
]]
function LuaNetSendMsg:ReqPersonalJingJiReport()
    ------print("申请战报 ")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.JINGJICHANG)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(5)
    self:SendMsg(self.m_pStream)
end

--[[
查询排行榜 ，1-等级，2-神将，3-总战力，21-血战榜即时，22-血战榜昨天，23-推图,25--图鉴
]]
function LuaNetSendMsg:QueryRankList(rank_type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_RANKLIST)
    self.m_pStream:WriteWord(rank_type)
    self:SendMsg(self.m_pStream)
end
 
--[[
查询鲜花排行榜 
]]
function LuaNetSendMsg:QueryXianHuaInfo(rank_type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XIANHUA)
    self.m_pStream:WriteByte(rank_type)
    self:SendMsg(self.m_pStream)
end

--[[
查询鲜花排行榜2019/4/3
]]
function LuaNetSendMsg:QueryXianHuaInfoNew(rank_type, round)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XIANHUA)
    self.m_pStream:WriteByte(rank_type)
    self.m_pStream:WriteByte(round)
    self:SendMsg(self.m_pStream)
end

--[[
购买鲜花
]]
function LuaNetSendMsg:QuerybugXianHua(type, id, num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XIANHUA)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteUInt(id)
    self.m_pStream:WriteUInt(num)
    self:SendMsg(self.m_pStream)
end

--[[
赠送鲜花
]]
function LuaNetSendMsg:QueryGiveXianHua(type, id, num, sendToId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XIANHUA)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteWord(id)
    self.m_pStream:WriteWord(num)
    self.m_pStream:WriteUInt(sendToId)
    self:SendMsg(self.m_pStream)
    
end

--[[
受赠记录 type 1 赠送记录 2 受赠记录
]]
function LuaNetSendMsg:QueryGetXianHuaRecord(type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XIANHUA)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--[[
查询邮件 
]]
function LuaNetSendMsg:QueryMails(op)
--print("QueryMailsQueryMails");
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XINSHI)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(0)
    self:SendMsg(self.m_pStream)
end

--[[
领取邮件 
]]
function LuaNetSendMsg:SaveMails(mail_id, delAll)
--print("SaveMails",mail_id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XINSHI)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUInt(mail_id)
    self.m_pStream:WriteByte(delAll)
    self:SendMsg(self.m_pStream)
end

--[[
发送邮件 
]]
local MailDefaultItemNum = 3 -- 默认邮件的附件最多有3个
function LuaNetSendMsg:SendMails(m)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XINSHI)
    self.m_pStream:WriteByte(1) -- op 
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteString(m.from_name) -- 收信人名字

    for i = 1, MailDefaultItemNum do 
        local it  = m.item[i]
        if not it then 
            self.m_pStream:WriteByte(-1)
            self.m_pStream:WriteByte(-1)
        else
            self.m_pStream:WriteByte(it.m_pos)
            self.m_pStream:WriteByte(it.m_num)
        end
    end
    self.m_pStream:WriteUInt(m.money)

    -- ======================
    -- 邮件正文
    if m.from_name == "GM" then 
    else
        self.m_pStream:WriteString(m.message)
    end
    self:SendMsg(self.m_pStream)
end

--[[
删除邮件 
]]
function LuaNetSendMsg:DelMails(mail_id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_XINSHI)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUInt(mail_id)
    self.m_pStream:WriteByte(0)
    self:SendMsg(self.m_pStream)
end

--[[
VIP信息 
op:1查询信息2购买月卡3领取奖励
4我的vip信息5vip相关副本次数更新
6清除副本冷却时间7领取元宝
]]
function LuaNetSendMsg:QueryVipInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_VIP_INFO)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end


--[[
VIP信息 
type:
1、 月卡
2、 终身月卡
]]
function LuaNetSendMsg:QueryMcCardAward(op, type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_VIP_INFO)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--[[
脱离卡死
]]
-- function LuaNetSendMsg:QueryDieReset()
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_PRO_SCENE_POS)
--     self:SendMsg(self.m_pStream)
-- end

function LuaNetSendMsg:QueryCreateTeam()
    ------print("LuaNetSendMsg:QueryCreateTeam")
    -- if (DATA_MGR->Hero.GetSceneType() == DataMgr::CHero::MSI_LEITAISAI)// 擂台赛不能组队
    -- {
    --     TipsMgr::GetInstance()->SetCenterTip(RES_STRC(DataConsts::RSI_TL_TIP_MIN))
    --     return
    -- }
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
申请入队
]]
function LuaNetSendMsg:QueryApplyTeam(leaderId)
    -- if (DATA_MGR->Hero.GetSceneType() == DataMgr::CHero::MSI_LEITAISAI)// 擂台赛不能组队
    -- {
    --     TipsMgr::GetInstance()->SetCenterTip(RES_STRC(DataConsts::RSI_TL_TIP_MIN))
    --     return
    -- }
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteUInt(leaderId)
    self:SendMsg(self.m_pStream)
end

--[[
队长同意接受申请
]]
function LuaNetSendMsg:AccpetPlayerTeam(id,res)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(res)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
邀请组队
]]
function LuaNetSendMsg:QueryTeamInvite(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
队员同意加入队伍
]]
function LuaNetSendMsg:AccpetJoinTeam(id,res)
    -- if (DATA_MGR->Hero.GetSceneType() == DataMgr::CHero::MSI_LEITAISAI)// 擂台赛不能组队
    -- {
    --     TipsMgr::GetInstance()->SetCenterTip(RES_STRC(DataConsts::RSI_TL_TIP_MIN))
    --     return
    -- }
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteByte(res)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
请求退出队伍
]]
function LuaNetSendMsg:QueryLeaveTeam()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryExpelTeam(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryTeamLeader(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
请求暂离队伍
]]
function LuaNetSendMsg:QueryPauseTeam()
    
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(12)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBackTeam()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(13)
    self:SendMsg(self.m_pStream)
end

--[[
队长请求暂离队员归队
]]
function LuaNetSendMsg:QueryTeamReCall()
----print("LuaNetSendMsg:QueryTeamReCall()")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(15)
    self:SendMsg(self.m_pStream)
end

--[[
队长发布组队信息
]]
function LuaNetSendMsg:QueryPublishTeam(aotuApply, teamType, minLv, maxLv)
    ------print("QueryPublishTeam",aotuApply, teamType, minLv,maxLv)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteByte(aotuApply)
    self.m_pStream:WriteByte(teamType)
    self.m_pStream:WriteUShort(minLv)
    self.m_pStream:WriteUShort(maxLv)
    self:SendMsg(self.m_pStream)
end

--[[
获取发布组队信息
]]
function LuaNetSendMsg:QueryGetPublishTeam(teamType)
    
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(22)
    self.m_pStream:WriteByte(teamType)
    self:SendMsg(self.m_pStream)
end

--[[
个人开启自动组队
]]
function LuaNetSendMsg:QueryOpenAutoTeam(teamType)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(24)
    self.m_pStream:WriteByte(teamType)
    self:SendMsg(self.m_pStream)
end

--[[
个人开启自动组队
]]
function LuaNetSendMsg:QueryCloseAutoTeam()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TEAM_OPERATION)
    self.m_pStream:WriteByte(26)
    self:SendMsg(self.m_pStream)
end




--[[
猜拳
atype: 1 要经验, 2 要潜能, 3 要金钱
ftype: 1 布, 2 剪刀, 3 拳头
]]
function LuaNetSendMsg:QueryGuessFist(op, atype, ftype)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_GUESSFIST)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(atype)
    self.m_pStream:WriteByte(ftype)
    self:SendMsg(self.m_pStream)
end

--[[
    获取签到数据
]]
function LuaNetSendMsg:QueryDailySignInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(8)
    self.m_pStream:WriteByte(0)
    self:SendMsg(self.m_pStream)
end

--[[
    签到
]]
function LuaNetSendMsg:DailySign()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(8)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

-----------------------------昆仑山从这里开始------------------------------------------------
--[[
昆仑山
]]
function LuaNetSendMsg:QueryEnterKunlun()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(3)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
昆仑山房间
]]
function LuaNetSendMsg:QueryEnterKunlunRoom(idx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(3)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteWord(idx)
    self:SendMsg(self.m_pStream)
end

--[[
昆仑山排行
]]
function LuaNetSendMsg:QueryKunLunShanPaiHang()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(3)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
昆仑山房间
]]
function LuaNetSendMsg:QueryKunLunShanRoomInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(3)
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
end

--[[
昆仑山信息
]]
function LuaNetSendMsg:QueryKunLunShanInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(3)
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end

--[[
]]
function LuaNetSendMsg:QueryChangeKunLunRoom(order)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(3)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteWord(order)
    self:SendMsg(self.m_pStream)
end

--[[
获取开服第几天
]]
function LuaNetSendMsg:QuerySeverOpenTime()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(20)
    self:SendMsg(self.m_pStream)
end



-----------------------------昆仑山到这里结束------------------------------------------------

--[[
灵气查询,开服icon替换
]]
function LuaNetSendMsg:QueryLingQiButton(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(op)
    self:SendMsg(self.m_pStream)
end

--[[
灵气捐赠
]]
function LuaNetSendMsg:QueryAnimaInfo(op, step)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(op)
    if op == 7 then
        self.m_pStream:WriteByte(step)
    end
    self:SendMsg(self.m_pStream)
end

--[[
激活码
]]
function LuaNetSendMsg:QueryActiveCode(op, code)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION) 
    self.m_pStream:WriteWord(op)
    self.m_pStream:WriteString(code)
    self:SendMsg(self.m_pStream)
end

--[[
查询好友
]]
function LuaNetSendMsg:QueryFriendList()
    -- --print("QueryFriendListQueryFriendListQueryFriendListQueryFriendListQueryFriendList")
    -- Utils:ShowWaiting(LuaNetCmd.MSG_FRIENDS)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(1);
    self:SendMsg(self.m_pStream)
end

--[[
添加好友
]]
function LuaNetSendMsg:QueryFriendApplyList()
    -- Utils:ShowWaiting(LuaNetCmd.MSG_FRIENDS)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end

--[[
添加好友
]]
function LuaNetSendMsg:QueryAddFriend(id)
    --print("QueryAddFriend",id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
接受或拒绝添加好友请求
]]
function LuaNetSendMsg:QueryAddFriendAct(id, accept)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUInt(id)
    self.m_pStream:WriteByte(accept)
    self:SendMsg(self.m_pStream)
end

--[[
赠送礼物/体力
]]
function LuaNetSendMsg:QuerySendGiftToFriend(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
赠送礼物/体力
]]
function LuaNetSendMsg:QueryQuickSendGift()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(6)
    self:SendMsg(self.m_pStream)
end

--[[
领取礼物
]]
function LuaNetSendMsg:QueryFriendGetGift(roleId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUInt(roleId)
    self:SendMsg(self.m_pStream)
end

--[[
一键领取礼物
]]
function LuaNetSendMsg:QueryFriendQuickGetGift()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(8)
    self:SendMsg(self.m_pStream)
end

--[[
获取礼物列表
]]
function LuaNetSendMsg:QueryFriendGiftList()
    --print("--------------------------QueryFriendGiftList--------------------------")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end

--[[
删除好友
]]
function LuaNetSendMsg:QuertDelFriend(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
一键接受/拒绝好友申请
]]
function LuaNetSendMsg:QueryQuickAddFriendAct(accept)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteByte(accept)
    self:SendMsg(self.m_pStream)
end

--请求黑名单
function LuaNetSendMsg:QueryBlackListInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(12)
    self:SendMsg(self.m_pStream)
end
    
--请求添加黑名单
function LuaNetSendMsg:QueryAddBlack(id)

    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(13)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)

end
    
--删除黑名单
function LuaNetSendMsg:QueryDelBlack(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(14)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)

end

--推荐好友
function LuaNetSendMsg:QueryRecommendPlayer()
    --print("QueryRecommendPlayer")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(15)
    self:SendMsg(self.m_pStream)
end

--查找好友
function LuaNetSendMsg:QuerySerchPlayer(name)
    print("QuerySerchPlayer",name)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(16)
    self.m_pStream:WriteString(name)
    self:SendMsg(self.m_pStream)
end

--查找好友
function LuaNetSendMsg:QuerySimpleSerchPlayer(name)
    --print("QuerySerchPlayer",name)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FRIENDS)
    self.m_pStream:WriteByte(17)
    self.m_pStream:WriteString(name)
    self:SendMsg(self.m_pStream)
end


-----------------------------开服活动从这里开始------------------------------------------------
--[[
MSG_KAIFUHUODONG
]]
function LuaNetSendMsg:QueryTakeReward(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

----[[
--开服活动
--]]
--function LuaNetSendMsg:QueryKaifuHuodong(op, op1, op2)
--    self:ResetStream()
--    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
--    self.m_pStream:WriteByte(op)
--    self.m_pStream:WriteByte(op1)
--    if op2 ~= nil and op2 ~= 0 then
--        self.m_pStream:WriteByte(op2)
--    end
--    self:SendMsg(self.m_pStream)
--end

--[[
激活码
]]
function LuaNetSendMsg:QuerySendPassWord(op, password)

    if string.len(password) == 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(id, GUITips.RSI_MDSI_MSGI42)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    elseif string.find(password, " ") ~= nil then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(id, GUITips.RSI_MDSI_MSGI43)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end

    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteString(password)
    self:SendMsg(self.m_pStream)
end

--[[
开服活动
]]
function LuaNetSendMsg:TakeKaifuAwad(op, op1, index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
开服活动
]]
function LuaNetSendMsg:QueryWelFareInfo(op, op1)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    if op == 15 or op == 16 or op == 18 then
        self.m_pStream:WriteByte(op1)
    end
    self:SendMsg(self.m_pStream)
end

--[[
开服活动
]]
function LuaNetSendMsg:QueryGetRecharAward(op, op1, index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
开服活动
]]
function LuaNetSendMsg:QueryTotalCost(op, op1)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self:SendMsg(self.m_pStream)
end

--[[
开服活动
]]
function LuaNetSendMsg:QueryGetCostAward(op, op1, index)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end


--[[
国庆送礼数据 op1 1、查询排行榜数据 op2 1、赠送 2、受赠
]]
function LuaNetSendMsg:QueryNationalGiftData(op, op1, op2)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self.m_pStream:WriteByte(op2)
    self:SendMsg(self.m_pStream)
end

-----------------------------开服活动到这里结束------------------------------------------------

--[[
查询他人的人物信息
]]
function LuaNetSendMsg:QueryOtherPlayer(id, ind)
    LRoleDataMgr.OtherHeroInfo.id = id
    LRoleDataMgr.OtherHeroInfo.ind = ind or 1
    self:QueryOtherPlayerInfo(id)
    -- self:QueryChiBangInfo(7, id)
    -- self:QueryHorseInfo(8, id)
    -- self:QueryShenQiInfoNew(7, id)
end

--[[
查询机器人信息
]]
function LuaNetSendMsg:QueryRobotInfo(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
    self.m_pStream:WriteByte(32)
    self.m_pStream:WriteUInt(id)
    self:SendMsg(self.m_pStream)
end

--[[
请求他人的人物信息
]]
function LuaNetSendMsg:QueryOtherPlayerInfo(id, idtype)
    if idtype == nil then idtype = 0 end
    id = id or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PLAYER_DETAIL)
    self.m_pStream:WriteUInt(id)
    self.m_pStream:WriteByte(idtype)
    self:SendMsg(self.m_pStream)
end


--[[
通天塔
]]
function LuaNetSendMsg:QueryTowerInfo(op, argv)
    if not op then return end 
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SERVER_TOWER_SHOWBAZHU) 
    self.m_pStream:WriteByte(op)
    if argv and op == 5 then 
        self.m_pStream:WriteByte(argv)
    end
    self:SendMsg(self.m_pStream)

end 

-----------------------------开服活动到这里结束------------------------------------------------
--[[
称号
]]

function LuaNetSendMsg:QueryMedalList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_LIST_TITLE)
    self:SendMsg(self.m_pStream)
end

--[[
称号
]]
function LuaNetSendMsg:QueryShowMedal(op, id, use)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_USE_TITLE)
    self.m_pStream:WriteByte(op) --1, 删除, 2显示, 3修改
    self.m_pStream:WriteWord(id)
	self.m_pStream:WriteByte(use)
    self:SendMsg(self.m_pStream)
end

-----------------------------护送任务从这里开始------------------------------------------------
function LuaNetSendMsg:QueryConvoyFinish()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(13)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyNote()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(4)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyTaskRecv()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyQuality(quality)
 
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(quality)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyFightConfirm(rolid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteUInt(rolid)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyFight(roleId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUInt(roleId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyGoToNpc()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(6)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyGoldFight(roleId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteUInt(rolid)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyGoldInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(14)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryConvoyInitState()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CONVOY)
    self.m_pStream:WriteByte(18)
    self:SendMsg(self.m_pStream)
end
-----------------------------护送任务到这里结束------------------------------------------------

------------------------战斗相关--------------
function LuaNetSendMsg:QueryBattleAct(act, actionv)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BATTLE)
    self.m_pStream:WriteByte(act)
    self.m_pStream:WriteUInt(actionv)
    self:SendMsg(self.m_pStream)
end
--------------------------------------------------

--[[
摇钱树
@op1 1-获取数据,2-摇钱
]]
function LuaNetSendMsg:SendMoneyTreeReq(op1,treeType)
    op1 = op1 or 1
    treeType = treeType or 1
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(17)
    self.m_pStream:WriteByte(op1)
    if op1 == 2 then
        self.m_pStream:WriteByte(treeType)
    end
    self:SendMsg(self.m_pStream)
end

--[[
每日Boss
@op 3-请求信息,7-挑战Boss,8-请求奖励信息,9-领取星级奖励,10-购买次数按钮
]]
function LuaNetSendMsg:QueryDailyBoss(op,val)
     self:ResetStream()
     self.m_pStream:WriteUShort(LuaNetCmd.MSG_DAILYBOSSTASK)
     self.m_pStream:WriteByte(op)
     if op == 7 or op == 9 then
         self.m_pStream:WriteByte(val)
     end
     self:SendMsg(self.m_pStream)
     ------print("QueryDailyBoss",op,val)
end

-----------------------------抽卡到这里开始------------------------------------------------
--kind 1 基础 2 高级 3友情
--type 1 单抽 type 2 十连
function LuaNetSendMsg:SendExtractPetMsg(op, kind, type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_GET_PET)
    self.m_pStream:WriteByte(op)
    if op == 2 then
        self.m_pStream:WriteByte(kind)
        self.m_pStream:WriteByte(type)
    end
    self:SendMsg(self.m_pStream)
end
-----------------------------抽卡到这里结束------------------------------------------------

-----------------------------近期目标从这里开始------------------------------------------------
function LuaNetSendMsg:QueryStageGoalInfo_L(id, unit, chapter)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_STAGE_GOAL)
    self.m_pStream:WriteByte(id)
    if id == 2 then
        self.m_pStream:WriteByte(unit)
        self.m_pStream:WriteByte(chapter)
    elseif id == 3 then
        self.m_pStream:WriteByte(unit)
    end
    self:SendMsg(self.m_pStream)
end
-----------------------------近期目标到这里结束------------------------------------------------

function LuaNetSendMsg:QueryOnlineAward()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:AwardOnlineAward()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteByte(2)
    --print("执行AwardOnlineAward")
  --  self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryOfflineExpInfo()
    -- self:ResetStream()
    -- self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_OUTLINEEXP)
    -- self.m_pStream:WriteByte(1)
    -- self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:GeOfflineExp(id)
    -- self:ResetStream()
    -- self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_OUTLINEEXP)
    -- self.m_pStream:WriteByte(2)
    -- self.m_pStream:WriteByte(id)
    -- self:SendMsg(self.m_pStream)
end

--[[
充值档位请求
]]
function LuaNetSendMsg:QueryPayPriceList()
    if #LRoleDataMgr.MyHeroInfo.m_PayPricelist > 0 then
         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.RechargeMainUI",AppDef.UIType.FirstClassLayer, 1)
         self:SendMsg(LGameMsg.m_initUIMsg)
    else -- 没有查询过 就先查询
        self:ResetStream()
        self.m_pStream:WriteUShort(LuaNetCmd.MSG_PAY_PRICE_LIST)
        self.m_pStream:WriteByte(1)
        self:SendMsg(self.m_pStream)
    end 
end

--[[
神将列表
]]
function LuaNetSendMsg:QueryPetListInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
神将改名
]]
function LuaNetSendMsg:QueryPetChangeName(petId, petName)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteString(petName)
    self:SendMsg(self.m_pStream)
end

--[[
神将升级
@param1:petId 神将id
@param2:costItemId 消耗的道具id
@param3:costItemNum 消耗的道具数量
]]
function LuaNetSendMsg:QueryPetLvUp(petId, costItemId, costItemNum)
    if petId == nil then
        return
    end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteUShort(costItemId)
    self.m_pStream:WriteByte(costItemNum)
    self:SendMsg(self.m_pStream)
end

--[[
神将一键升级
@param1:petId 神将id
@param2:toLevel 升到的等级
@param3:costData 消耗的道具 table
]]
function LuaNetSendMsg:QueryOneKeyPetLvUp(petId, toLevel, costData)
    if petId == nil then
        return
    end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteWord(petId)
    self.m_pStream:WriteWord(toLevel)
    -- local costNum = #costData
    -- self.m_pStream:WriteByte(costNum)
    -- for i=1, costNum do
    --     self.m_pStream:WriteWord(costData[i].itemId)
    --     self.m_pStream:WriteWord(costData[i].itemNum)
    -- end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryPetFollowHero(petId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteUShort(petId)
    self:SendMsg(self.m_pStream)
end

--[[
宠物升星
]]
function LuaNetSendMsg:QueryPetStarUp(petId)

    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJSHENGXING) then
        return
    end

    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUShort(petId)
    self:SendMsg(self.m_pStream)
end

--[[
宠物修炼
@param1:petId 神将id
@param2:xlianInd 修炼下标
]]
function LuaNetSendMsg:QueryPetXiulian(petId, xlianInd)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(9)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteByte(xlianInd)
    self:SendMsg(self.m_pStream)
end

--[[
天书技能遗忘
]]
function LuaNetSendMsg:QueryPetBookSkillForget(petId, skPos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteByte(skPos)
    self:SendMsg(self.m_pStream)
end

--[[
天书技能学习或替换
@param1:petId 神将id
@param2:skid 技能id
]]
function LuaNetSendMsg:QueryPetBookSkillStudy(petId, skPos, itemId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteUShort(itemId)
    self.m_pStream:WriteByte(skPos)
    self:SendMsg(self.m_pStream)
end

--[[
天书技能升级
@param1:petId 神将id
@param2:skid 技能id
]]
function LuaNetSendMsg:QueryPetBookSkillLvUp(petId, skId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteUShort(skId)
    self:SendMsg(self.m_pStream)
end

--[[
天生技能升级
@param1:petId 神将id
@param2:skPos 技能位置
]]
function LuaNetSendMsg:QueryPetBornSkillLvUp(petId, skPos)
    ----print("QueryPetBornSkillLvUp",petId, skPos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteByte(skPos)
    self:SendMsg(self.m_pStream)
end

--[[
天生技能一键升级
@param1:petId 神将id
@param2:skPos 技能位置
]]
function LuaNetSendMsg:QueryQuickPetBornSkillLvUp(petId, skPos)
    ----print("QueryPetBornSkillLvUp",petId, skPos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(14)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteByte(skPos)
    self:SendMsg(self.m_pStream)
end

--[[
神将兑换
@param1:type op
@param2:materialId 合成需要材料ID
]]
function LuaNetSendMsg:QueryGetPet(type, materialId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteUShort(materialId)
    self:SendMsg(self.m_pStream)
end

--[[
神将突破
@param1:type op
]]
function LuaNetSendMsg:PetBreakUp(petId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteUShort(petId)
    self:SendMsg(self.m_pStream)
end
--[[
神将重生
]]
function LuaNetSendMsg:SendPetChongSheng(op, uid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(op)
	self.m_pStream:WriteUInt(uid)
    self:SendMsg(self.m_pStream)
end


--[[
神将修炼
]]
function LuaNetSendMsg:SendPetXiuLian(petId, xlNum)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(6)
    self.m_pStream:WriteWord(petId)
    self.m_pStream:WriteWord(xlNum)
    self:SendMsg(self.m_pStream)
end


--[[
神将激活
]]
function LuaNetSendMsg:SendPetJiHuo(petId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PET_INFO)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteWord(petId)
    self:SendMsg(self.m_pStream)
end


--[[
神将装备背包
@param1:op 1-背包数据，4-强化，5-分解
@param2:uid 神将装备唯一ID
@param3:petId 神将ID
]]
function LuaNetSendMsg:QueryPetEquip(op,uid,petId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
     if op == 2 or op == 3 or op == 4 or op == 9 or op == 10 then
        self.m_pStream:WriteWord(petId)
    end
    if op == 2 or op == 3 or op == 4 or op == 5 or op == 9 or op == 10 then
        if uid == nil then
            return
        end
        self.m_pStream:WriteUInt(uid)
    end
    self:SendMsg(self.m_pStream)
end

--[[
神将装备穿脱
@param1:op 2-穿，3-脱
@param2:uid 神将装备唯一ID
@param3:fpos 上阵位置
]]
function LuaNetSendMsg:SendPetEquipWearReq(op,uid,fPos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(fPos)
    self.m_pStream:WriteUInt(uid)
    self:SendMsg(self.m_pStream)
end

--[[
神将装备合成
@param1:id 装备碎片ID
]]
function LuaNetSendMsg:SendPetEquipHeChengReq(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end

--[[
神将装备批量分解
]]
function LuaNetSendMsg:SendPetEquipFenjieReq(uids)
    if uids == nil or #uids == 0 then return end
    local num = #uids
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteByte(num)
    for i=1,num do
        self.m_pStream:WriteUInt(uids[i])
    end
    self:SendMsg(self.m_pStream)
end

--[[
合成装备（弃用）
]]
function LuaNetSendMsg:SendEquipHecheng(equipId)
    if equipId == nil or equipId == 0 then return end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(equipId)
    self:SendMsg(self.m_pStream)
end

--[[
装备强化
]]
function LuaNetSendMsg:SendEquipQiangHua(equipId, type)
    if equipId == nil or equipId == 0 then return end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUInt(equipId)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--[[
装备一件强化
]]
function LuaNetSendMsg:SendEquipAutoQiangHua(fpos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteByte(fpos)
    self:SendMsg(self.m_pStream)
end

--[[
装备一件精炼
]]
function LuaNetSendMsg:SendEquipAutoJingLian(equipId, items)
    if equipId == nil or #items == 0 then return end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(13)
    self.m_pStream:WriteUInt(equipId)
    self.m_pStream:WriteByte(#items)
    for i=1,#items do
        self.m_pStream:WriteUShort(items[i].id)
        self.m_pStream:WriteUShort(items[i].num)
    end
    self:SendMsg(self.m_pStream)
end

--[[
装备一件精炼
]]
function LuaNetSendMsg:SendEquipCultivate(equipId, op, level)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteUInt(equipId)
    self.m_pStream:WriteUShort(level)
    self:SendMsg(self.m_pStream)
end


--[[
请求法宝数据
]]
function LuaNetSendMsg:SendFaBaoList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(17)
    self:SendMsg(self.m_pStream)
end

--[[
请求法宝强化
]]
function LuaNetSendMsg:SendFaBaoQianHua(uid, useItem)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(20)
    self.m_pStream:WriteUInt(uid)
    local num = #useItem
    --print("SendFaBaoQianHua ==>", num)
    self.m_pStream:WriteByte(num)
    for i=1, num do
        self.m_pStream:WriteUInt(useItem[i].m_uid)
    end
    self:SendMsg(self.m_pStream)
end

--[[
请求精炼
]]
function LuaNetSendMsg:SendFaBaoTakeOn(uid, fpos, wpos)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(18)
    self.m_pStream:WriteUInt(uid)
    self.m_pStream:WriteByte(fpos)
    self.m_pStream:WriteByte(wpos)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:SendFaBaoTakeOff(uid)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(19)
    self.m_pStream:WriteUInt(uid)
    self:SendMsg(self.m_pStream)
end
    

--[[
请求精炼
]]
function LuaNetSendMsg:SendFaBaoJingLian(uid, toLevel)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(21)
    self.m_pStream:WriteUInt(uid)
    self.m_pStream:WriteByte(toLevel)
    self:SendMsg(self.m_pStream)
end

--[[
请求强化大师
]]
function LuaNetSendMsg:SendMasterList(pos)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(25)
	self.m_pStream:WriteByte(pos)
    self:SendMsg(self.m_pStream)
end


--[[
法宝搜索
@param faBaoId 法宝ID
@param suiId 碎片ID
]]
function LuaNetSendMsg:SendXunBaoReq(faBaoId,suiId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(28)
    self.m_pStream:WriteWord(faBaoId)
    self.m_pStream:WriteWord(suiId)
    self:SendMsg(self.m_pStream)
end

--[[
法宝一键搜索
@param faBaoId 法宝ID
@param autoSign 是否自动使用寻宝道具
]]
function LuaNetSendMsg:SendXunBaoOneKeyReq(faBaoId,autoSign)
    local autoSign = autoSign or 0
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(29)
    self.m_pStream:WriteByte(autoSign)
    self.m_pStream:WriteWord(faBaoId)
    self:SendMsg(self.m_pStream)
end

--[[
法宝合成
]]
function LuaNetSendMsg:SendFaBaoHeChengReq(faBaoId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(30)
    self.m_pStream:WriteWord(faBaoId)
    self:SendMsg(self.m_pStream)
end

--[[
法宝一键合成
]]
function LuaNetSendMsg:SendFaBaoHeChengOneKeyReq()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(36)
    self:SendMsg(self.m_pStream)
end

--[[
法宝搜索信息请求(次数)
]]
function LuaNetSendMsg:SendXunBaoInfoReq()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(31)
    self:SendMsg(self.m_pStream)
end

--[[
装备重生
]]
function LuaNetSendMsg:SendPetEquipChongSheng(op, uid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
	self.m_pStream:WriteByte(1)
	self.m_pStream:WriteByte(1)
	for i = 1,1 do
		self.m_pStream:WriteUInt(uid)
	end
    self:SendMsg(self.m_pStream)
end

--[[
装备分解
]]
function LuaNetSendMsg:SendPetEquipFenJie(op, uids)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
	self.m_pStream:WriteByte(2)
	self.m_pStream:WriteByte(#uids)
	for i = 1,#uids do
		self.m_pStream:WriteUInt(uids[i])
	end
    self:SendMsg(self.m_pStream)
end

--[[
法宝重生
]]
function LuaNetSendMsg:SendPetFaBaoChongSheng(op, uid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
	self.m_pStream:WriteByte(1)
	self.m_pStream:WriteByte(1)
	for i = 1,1 do
		self.m_pStream:WriteUInt(uid)
	end
    self:SendMsg(self.m_pStream)
end

--[[
法宝分解
]]
function LuaNetSendMsg:SendPetFaBaoFenJie(op, uids)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MGS_PETEQUIP_BAG)
    self.m_pStream:WriteByte(op)
	self.m_pStream:WriteByte(2)
	self.m_pStream:WriteByte(#uids)
	for i = 1,#uids do
		self.m_pStream:WriteUInt(uids[i])
	end
    self:SendMsg(self.m_pStream)
end

--[[
修仙历练
]]
function LuaNetSendMsg:QueryLiLianInfo(op,val)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XIUXIANLILIAN)
    self.m_pStream:WriteByte(op)
    if op == 2 then
        self.m_pStream:WriteWord(val)--进入战斗
    end
    self:SendMsg(self.m_pStream)
end

--[[
英勇试炼
]]
function LuaNetSendMsg:QueryShiLianInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SHILIAN)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--[[
英勇试炼 抽奖
]]
function LuaNetSendMsg:QueryShiLianLottery(op, index)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SHILIAN)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(index)
    self:SendMsg(self.m_pStream)
end

--[[
百花仙子
]]
function LuaNetSendMsg:QueryEnterBaihua()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION)
    self.m_pStream:WriteWord(2)
    self:SendMsg(self.m_pStream)
end
--[[
年兽
]]
function LuaNetSendMsg:QueryEnterNianShou()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION)
    self.m_pStream:WriteWord(19)
    self:SendMsg(self.m_pStream)
end
--[[
六界巡查
]]
function LuaNetSendMsg:QueryXunChaShiInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION)
    self.m_pStream:WriteWord(14)
    self:SendMsg(self.m_pStream)
end

--[[
挑战灵魔
]]
function LuaNetSendMsg:QueryLingMoInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION)
    self.m_pStream:WriteWord(12)
    self:SendMsg(self.m_pStream)
end

--[[
擂台
]]
function LuaNetSendMsg:QueryLeiTaiInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_LEITAISAI)
    self.m_pStream:WriteWord(op)
    self:SendMsg(self.m_pStream)
end

--[[
钓鱼
]]
function LuaNetSendMsg:QueryFishingInfo(op,roomId,idx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FISHING_INFO)
    self.m_pStream:WriteByte(op)
	if op ==2 or op == 4 then--房间id
		self.m_pStream:WriteUInt(roomId)
    elseif op == 5 then
        self.m_pStream:WriteByte(roomId)
	elseif op == 7 then
		self.m_pStream:WriteUInt(roomId)
		self.m_pStream:WriteByte(idx)
	end
    self:SendMsg(self.m_pStream)
end

--[[
飞仙战场
]]
function LuaNetSendMsg:QueryFlyFaryField(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FLYFARY)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--[[
藏宝图
op 1 查询 2 地图 3 挖宝
]]
function LuaNetSendMsg:QueryCangBaotuInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CANGBAOTU)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--[[
藏宝图 挖宝
]]
function LuaNetSendMsg:QueryCangBaotuWa()
    local function CollectCallBack()
        self:QueryCangBaotuInfo(3)
    end

    local function AutoPathCallBack( ... )
        local collectData = {
                collectTip = GUITips.RSI_FACTION_MSG62,
                npcId = 0,
                serialNum = 0,
                seconds = 3,
                callback = CollectCallBack,
                type = 2,
            }
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCCollectUI",AppDef.UIType.PopWindow,collectData)
        self:SendMsg(LGameMsg.m_initUIMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
		self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    local data = LDataConstMgr.m_BaoZangInfo
    data.isWa = true
    data.isQuery = true
    LGameMsg.m_autoPathMsg:ChangeToStart(data.sid,data.posX,data.posY,0,0,false,true, AutoPathCallBack)
    self:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
查询答题信息
]]
function LuaNetSendMsg:QueryQuestion(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_EVERY_QUETION)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--[[
回答问题
]]
function LuaNetSendMsg:AnswerQuestion(op, idx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_EVERY_QUETION)
    self.m_pStream:WriteByte(op)
    if op == 2 then
        self.m_pStream:WriteByte(idx)
    end
    self:SendMsg(self.m_pStream)
end


--[[
请求阵容信息
]]
function LuaNetSendMsg:QueryFormationInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
阵法升级或者学习
@param1:zid阵法id
]]
function LuaNetSendMsg:QueryFormationLvUp(zid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteUShort(zid)
    self:SendMsg(self.m_pStream)
end

--[[
使用阵法
@param1:zid阵法id
]]
function LuaNetSendMsg:QueryFormationUse(zid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUShort(zid)
    self:SendMsg(self.m_pStream)
end

--[[
组队使用阵法
@param1:zid阵法id
]]
function LuaNetSendMsg:QueryTeamFormationUse(zid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteUShort(zid)
    self:SendMsg(self.m_pStream)
end

--[[
宠物上下阵
@param1:petId:宠物id
@param2:fightPos: 替换的位置
]]
function LuaNetSendMsg:QueryFormationPetPos(petId, fightPos)
    
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteByte(fightPos)
    self:SendMsg(self.m_pStream)
end

--[[
更换出站位置
@param1:oldPos旧的出站位置
@param2:newPos新的出站位置
]]
function LuaNetSendMsg:QueryFormationChangePos(oldPos, newPos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteByte(oldPos)
    self.m_pStream:WriteByte(newPos)
    self:SendMsg(self.m_pStream)
end

--[[
组队宠物上下阵
@param1:petId:宠物id
@param2:state: 1上阵0下阵
]]
function LuaNetSendMsg:QueryTeamFormationPetPos(petId, state)
    
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteUShort(petId)
    self.m_pStream:WriteByte(state)
    self:SendMsg(self.m_pStream)
end

--[[
更换出站位置
@param1:oldPos旧的出站位置
@param2:newPos新的出站位置
]]
function LuaNetSendMsg:QueryTeamFormationChangePos(oldPos, newPos)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FORMATION)
    self.m_pStream:WriteByte(13)
    self.m_pStream:WriteByte(oldPos)
    self.m_pStream:WriteByte(newPos)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryItemServerDetail(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ITEM_DEF)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryTotalRechar(op, op1)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(op1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:DealMsgSaveSettingInfo(idx, val)
    LRoleDataMgr:SetSettingConfig(idx, val)
    
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SAVE_VAL)
    self.m_pStream:WriteByte(idx)
    self.m_pStream:WriteUInt(val)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QuerySettingInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_GET_SAVE_VAL)
    self.m_pStream:WriteByte(AppDef.ServerSetIndex.SSI_SAVED_VAL_MAX)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QuerySetSettingInfo(id, str)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SAVE_STR_VAL)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(id)
    self.m_pStream:WriteString(str)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryGetSettingInfo(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_SAVE_STR_VAL)
    self.m_pStream:WriteByte(2)
    if id then
        self.m_pStream:WriteByte(1)--1:单条 0:全部
        self.m_pStream:WriteByte(id)
    else
        self.m_pStream:WriteByte(0)--1:单条 0:全部
    end
    self:SendMsg(self.m_pStream)
end

--请求任务列表
function LuaNetSendMsg:QueryFactionTaskList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(33)
    self:SendMsg(self.m_pStream)
end

--[[
请求和玩家PK
]]
-- function LuaNetSendMsg:QueryPKWithPlayer(op, mod, roleId)
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_PK)
--     self.m_pStream:WriteByte(2)
--     self.m_pStream:WriteUInt(roleId)
--     self:SendMsg(self.m_pStream)

--     MSG_INIT_WITH_CMD(128, ll_stream, MSG_CLIENT_PK);
--     self.m_pStream:WriteByte((char)op);
--     if(mod >= 0){ self.m_pStream:WriteByte((char)mod); }
--     self.m_pStream:WriteUInt(roleId);
--     self:SendMsg(self.m_pStream)
-- end

--[[
帮派PK
]]
function LuaNetSendMsg:QueryFactionZonePK(roleId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_PK)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteUInt(roleId)
    self:SendMsg(self.m_pStream)
end

--[[
请求和玩家切磋
@param1:op 0请求切磋 1 回复切磋
@param2:mod op=0对应mod=1 op=1对应mod=0拒绝切磋mod=1同意切磋
@param3:roleId 想要切磋的玩家id
]]
function LuaNetSendMsg:QueryMatchWithPlayer(op, mod, roleId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MATCH)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(mod)
    self.m_pStream:WriteUInt(roleId)
    self:SendMsg(self.m_pStream)
end

--请求已完成任务列表
function LuaNetSendMsg:QueryCompleteTaskList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TASK_LIST)
    self:SendMsg(self.m_pStream)
end

--请求激活码
function LuaNetSendMsg:AccActivate(accode)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_NPC_CHAT)
    self.m_pStream:WriteByte(1) --op
    self.m_pStream:WriteByte(1) --参数数量
    self.m_pStream:WriteByte(1) --0整形1字符串
    self.m_pStream:WriteString(accode)
    ----print("accode", accode)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryMsgHeader()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_ACCOUNT)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryPetInfo(roleID, petID)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_TASK_QUERY_PET)
    self.m_pStream:WriteUInt(roleID)
    self.m_pStream:WriteWord(petID)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFightSpeed(speed)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FIGHT_SPEED)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteByte(speed)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryResRecovery(op, findID, findNum)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_RESRECOVERY)
    self.m_pStream:WriteByte(op) --op 1 资源找回列表 2 找回指定的活动资源 3 一键找回所有
    if op == 2 then
        self.m_pStream:WriteUInt(findID)
        self.m_pStream:WriteUShort(findNum)
    -- elseif op == 3 then
    --     self.m_pStream:WriteByte(findType)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFundRebate(arg0, arg1, arg2)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(83)
    if arg0 then
        self.m_pStream:WriteByte(arg0)
    end
    if arg1 then
        self.m_pStream:WriteByte(arg1)
    end
    if arg2 then
        self.m_pStream:WriteByte(arg2)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryHuoYueFundRebate(arg0, arg1, arg2)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(94)
    if arg0 then
        self.m_pStream:WriteByte(arg0)
    end
    if arg1 then
        self.m_pStream:WriteByte(arg1)
    end
    if arg2 then
        self.m_pStream:WriteByte(arg2)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFengShen(op, arg1)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ACT_FENGSHEN)
    self.m_pStream:WriteByte(op)
    if arg1 then
        self.m_pStream:WriteWord(arg1)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryPetDiscount(arg0, arg1)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(84)
    local _ = arg0 and self.m_pStream:WriteByte(arg0)
    local _ = arg1 and self.m_pStream:WriteByte(arg1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryTaskGiftList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_STAGE_GOAL)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryGetTaskGiftReward(id)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_STAGE_GOAL)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryLunDaoInfo(op, _type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_LUNDAO)
    self.m_pStream:WriteByte(op)
    if op == 5 then
        self.m_pStream:WriteWord(_type)
    end
    self:SendMsg(self.m_pStream)
end

----------------------------------唯我独仙----------------------------------
function LuaNetSendMsg:QueryWeiWoDuXian(op)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end

--排行榜或者预赛挑战
function LuaNetSendMsg:QuerySingleImmortalInfo(op, type)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteUInt(type)
    self:SendMsg(self.m_pStream)
end

--type 0上半场 1下半场2 决赛
function LuaNetSendMsg:QueryWWDXFinalInfo(type, isNoLast)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    if isNoLast then
        self.m_pStream:WriteByte(21)
    else
        self.m_pStream:WriteByte(28)
    end
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--查看惟我独仙节点信息
function LuaNetSendMsg:QueryWWDXNodeInfo(type, nodeidx, isNoLast )
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    if isNoLast then
        self.m_pStream:WriteByte(22)
    else
        self.m_pStream:WriteByte(29)
    end
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteByte(nodeidx)
    self:SendMsg(self.m_pStream)
end

--惟我独仙下注
function LuaNetSendMsg:QueryWWDXBet(type, nodeidx, voteId)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    self.m_pStream:WriteByte(23)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteByte(nodeidx)
    self.m_pStream:WriteUInt(voteId)
    self:SendMsg(self.m_pStream)
end

--前往战场
function LuaNetSendMsg:QueryWWDXBattle()
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    self.m_pStream:WriteByte(24)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryWWDXTimer()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    self.m_pStream:WriteByte(25)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryWWDXScore()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WEIWODUXIAN)
    self.m_pStream:WriteByte(26)
    self:SendMsg(self.m_pStream)
end

----------------------------------神界秘境----------------------------------
function LuaNetSendMsg:QueryJoinMsBoss()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryMsBossRankList()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(2)
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryMsBossRoomInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(3)
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryMsBossChangeRoom(roomid)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUInt(roomid)
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryMsBossInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(5)
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryMsBossReBorn(type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteUInt(type)
    self:SendMsg(self.m_pStream)
end
function LuaNetSendMsg:QueryMsBossUpdateHpBar()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_MULTISERVER_BOSS)
    self.m_pStream:WriteByte(11)
    self:SendMsg(self.m_pStream)
end

--改名,op==1玩家,op==2帮派
function LuaNetSendMsg:QueryAcrossSerChatMsg(op, msg)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.NPC_DIA_CLICK)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteString(msg)
    self:SendMsg(self.m_pStream)
end

--[[
折扣礼包
]]
function LuaNetSendMsg:QueryDiscountBag(op, param1, param2)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op)
    if param1 then
        self.m_pStream:WriteByte(param1)
    end
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryLaBaIsOpen( op )
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KUAFU_LABA)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
end



function LuaNetSendMsg:QueryHeart()
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HEART)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryTest()
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(4000)
    self:SendMsg(self.m_pStream)
end


--------------------------------------------------------------------
--请求世界等级
function  LuaNetSendMsg:QueryWorldLevel()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_WORLDLEVEL or 249)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFactionSeedData()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_FACTION_ZONE)
    self.m_pStream:WriteByte(47)
    self:SendMsg(self.m_pStream)
end
--[[
砸蛋信息
]]
function LuaNetSendMsg:QueryZaDanInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op or 33)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end
--[[
砸蛋
]]
function LuaNetSendMsg:QueryZaDan(tag, op)
    LRoleDataMgr:SetDelayShowAward(true)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_KAIFUHUODONG)
    self.m_pStream:WriteByte(op or 33)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(tag or 0)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBuyZaDan(id, num)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_CLIENT_MARKET)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteUInt(id or 0)
    self.m_pStream:WriteUInt(num or 0)
    self:SendMsg(self.m_pStream) 
end

--ios支付 获取 oerder_id
function LuaNetSendMsg:QueryIAPOderId(type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_IOS_GET_ORDERID)
    self.m_pStream:WriteWord(type)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryIAPInfoToServer(type, orderId, receipt_data, money, netInfo, mac, IMEI, IDFA)
    -- body
    --print("QueryIAPInfoToServer", string.len(receipt_data))
    local netNsg = LTCPMsg:New(LTCPEvent.GameSendMsg, string.len(receipt_data) + 200)
    netNsg:Reset()
    netNsg:WriteUShort(LuaNetCmd.MSG_PRO_CHARGE)
    netNsg:WriteWord(type)
    netNsg:WriteString(orderId)
    netNsg:WriteString(receipt_data, string.len(receipt_data))
    netNsg:WriteWord(money)
    netNsg:WriteString(netInfo)
    netNsg:WriteString(mac)
    netNsg:WriteString(IMEI)
    netNsg:WriteString(IDFA)
    self:SendMsg(netNsg)
    netNsg:Delete()
end

function LuaNetSendMsg:QuerySetBPApply(val)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(40)
    self.m_pStream:WriteWord(val or 0)
    self:SendMsg(self.m_pStream)
end

--请求活跃度奖励列表
function LuaNetSendMsg:QueryFactionActivityList(type)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(41)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryGetFactionActivity(type, act)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BANGPAI)
    self.m_pStream:WriteByte(42)
    self.m_pStream:WriteByte(type or 1)
    self.m_pStream:WriteUInt(act)
    self:SendMsg(self.m_pStream)
end

--------------------------------------------------------------------------
--卡牌版本
function LuaNetSendMsg:QueryDituInfo( op, type )
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self:SendMsg(self.m_pStream)
end

--进入章节
function LuaNetSendMsg:QueryStageInfo( op, type, stageID)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteUInt(stageID)
    self:SendMsg(self.m_pStream)
end

--领取宝箱奖励
function LuaNetSendMsg:QueryGetBoxReward(op, type, mapId, boxID)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteUInt(mapId)
    self.m_pStream:WriteUInt(boxID)
    self:SendMsg(self.m_pStream)
end


--挑战 op = 5 挑战  op == 6 扫荡
function LuaNetSendMsg:QueryFightSatge(op, type, mapId, stageId)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(type)
    self.m_pStream:WriteUInt(mapId)
    self.m_pStream:WriteUInt(stageId)
    self:SendMsg(self.m_pStream)
end

--挑战 op = 7 重置关卡
function LuaNetSendMsg:QueryResetStage(stageId)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUInt(stageId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryFuBenAchievement( ... )
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(11)
    self:SendMsg(self.m_pStream)
end


function LuaNetSendMsg:QueryFuBenAchievementAward( id )
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(12)
    self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

--获取试炼所有类型 op = 21 
function LuaNetSendMsg:QueryFengshenShiLian()
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(21)
    self:SendMsg(self.m_pStream)
end

--试炼挑战 op = 22
function LuaNetSendMsg:QueryFengshenTiaozhan(shilianId)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(22)
	self.m_pStream:WriteUInt(shilianId)
    self:SendMsg(self.m_pStream)
end

--试炼扫荡 op = 23
function LuaNetSendMsg:QueryFengshenSaoDang(shilianId)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(23)
	self.m_pStream:WriteUInt(shilianId)
    self:SendMsg(self.m_pStream)
end

--获取关卡信息 fType 1-主线，2-支线
function LuaNetSendMsg:QueryFuBenInfo(fType,mapId,nodeId)
    -- body
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(27)
    self.m_pStream:WriteByte(fType)
    self.m_pStream:WriteUInt(mapId)
    self.m_pStream:WriteUInt(nodeId)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:QueryFuBenInfo",fType,mapId,nodeId)
end

--昆仑决战 op = 25
function LuaNetSendMsg:QuertKunLunData()
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
    self.m_pStream:WriteByte(25)
    self:SendMsg(self.m_pStream)
end

--请求昆仑决战位置
function LuaNetSendMsg:QuertKunLunById(id)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
    self.m_pStream:WriteByte(26)
	self.m_pStream:WriteByte(id)
    self:SendMsg(self.m_pStream)
end

--昆仑决战连闯功能
function LuaNetSendMsg:QuertKunLunLianChuang(id, fightstop, numstop)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
    self.m_pStream:WriteByte(29)
	self.m_pStream:WriteByte(id)
	self.m_pStream:WriteByte(fightstop)
	self.m_pStream:WriteByte(numstop)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:BuyKunLunFightNum(num)
	self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_ADVANCEPATH_INFO)
	self.m_pStream:WriteByte(28)
	self.m_pStream:WriteByte(num)
	self:SendMsg(self.m_pStream)
end


--op 1 请求体力信息
--op 2 每日免费体力信息
--op 3 领取每日免费体力
function LuaNetSendMsg:QueryTiLiInfo(op, ind, type)
    --print("QueryTiLiInfo",op)
    -- body
    if op == 2 or op == 3 then
        Utils:ShowWaiting(LuaNetCmd.MSG_QUERY_TILI)
    end
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_TILI)
    self.m_pStream:WriteByte(op)
    if op == 3 then
        self.m_pStream:WriteByte(ind)
        self.m_pStream:WriteByte(type)
    end
    self:SendMsg(self.m_pStream)

end

function LuaNetSendMsg:QueryHeroBook()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HERO_BOOK)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:LevelUpHeroBook(heroId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_HERO_BOOK)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteUShort(heroId)
    self:SendMsg(self.m_pStream)
end

--[[
英勇试炼(血战到底)
op-1 信息请求,2 主界面开始,4-关底宝箱数据请求,6-重置,9-扫荡,15-活动数据请求(商城用),16-领取昨日奖励,17-请求主角当日排行
]]
function LuaNetSendMsg:QueryXueZhanInfo(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XUEZHAN)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:QueryXueZhanInfo",op)
end

--[[
英勇试炼(血战到底)
4-关底宝箱数据请求
levelId-关底宝箱关卡ID
]]
function LuaNetSendMsg:QueryXueZhanBox(levelId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XUEZHAN)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteWord(levelId)
    self:SendMsg(self.m_pStream)
    print("LuaNetSendMsg:QueryXueZhanBox",levelId)
end

--[[
英勇试炼(血战到底)复活
rType - 1-正常复活，2-不复活
]]
function LuaNetSendMsg:SendXueZhanReviveReq(rType)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XUEZHAN)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteByte(rType)
    self:SendMsg(self.m_pStream)
end

--[[
英勇试炼(血战到底)挑战
mode-挑战模式，1简单，2-普通，3-困难
]]
function LuaNetSendMsg:SendXueZhanFightReq(mode)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XUEZHAN)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(mode)
    self:SendMsg(self.m_pStream)
    ----print("LuaNetSendMsg:SendXueZhanFightReq",mode)
end

--[[
英勇试炼(血战到底)buff选择
op-10(普通)，14(扫荡)
idx-下标，1-3
]]
function LuaNetSendMsg:SendXueZhanBuffReq(op,idx)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XUEZHAN)
    self.m_pStream:WriteByte(op)
    self.m_pStream:WriteByte(idx)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:SendXueZhanBuffReq",op,idx)
end

--[[
英勇试炼(血战到底)扫荡设置(32位，每位对应属性类型)
stype:0 选星最多的,0xffffffff 全不选（手动选择）,其他 属性类型
]]
function LuaNetSendMsg:SendXueZhanSweepSetting(stype)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_XUEZHAN)
    self.m_pStream:WriteByte(11)
    self.m_pStream:WriteUInt(stype)
    self:SendMsg(self.m_pStream)
    --print("LuaNetSendMsg:SendXueZhanSweepSetting",stype)
end

function LuaNetSendMsg:SendJumpBattle()
    ----print("LuaNetSendMsg:SendJumpBattle")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_JUMP_BATTLE)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:SendReplayBattle(fightId)
    ----print("LuaNetSendMsg:SendReplayBattle",fightId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_JUMP_BATTLE)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteUInt(fightId)
    self:SendMsg(self.m_pStream)
end

--[[
封神列传
op-24 列传信息,25 挑战
]]
function LuaNetSendMsg:QueryFengShenStory(op)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(op)
    self:SendMsg(self.m_pStream)
    ----print("LuaNetSendMsg:QueryFengShenStory",op)
end

--[[
封神列传 领取章节奖励（宝箱）
@chapterId 章节ID
@levelId 关卡ID
]]
function LuaNetSendMsg:SendFengShenStoryBoxReq(chapterId,levelId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_QUERY_FUBENMAP)
    self.m_pStream:WriteByte(26)
    self.m_pStream:WriteWord(chapterId)
    self.m_pStream:WriteUInt(levelId)
    self:SendMsg(self.m_pStream)
    ----print("LuaNetSendMsg:SendFengShenStoryBoxReq",chapterId,levelId)
end

function LuaNetSendMsg:QueryBangPaiFubenList()
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

-- function LuaNetSendMsg:QueryBangPaiFubenInfo(chapterId, copyId)
--     Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
--     --print("QueryBangPaiFubenInfo",chapterId, copyId)
--     self:ResetStream()
--     self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
--     self.m_pStream:WriteByte(2)
--     self.m_pStream:WriteUInt(chapterId)
--     self.m_pStream:WriteUInt(copyId)
--     self:SendMsg(self.m_pStream)
-- end

function LuaNetSendMsg:QueryBangPaiFubenFight(chapterId, copyId)
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    --print("QueryBangPaiFubenFight",chapterId, copyId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteUInt(chapterId)
    self.m_pStream:WriteUInt(copyId)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiFubenQuickFight(chapterId, copyId)
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    --print("QueryBangPaiFubenQuickFight",chapterId, copyId)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(4)
    self.m_pStream:WriteUInt(chapterId)
    self.m_pStream:WriteUInt(copyId)
    self:SendMsg(self.m_pStream)
end


function LuaNetSendMsg:QueryBangPaiBuff()
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    --print("QueryBangPaiBuff")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(6)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiBuffLvUp(id)
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(5)
    self.m_pStream:WriteWord(id)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiFubenRank(chid)
--print("QueryBangPaiFubenRank",chid)
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(7)
    self.m_pStream:WriteUInt(chid)
    self:SendMsg(self.m_pStream)
end

function LuaNetSendMsg:QueryBangPaiFubenReward(chid, cpid)
    --print("QueryBangPaiFubenReward",chid, cpid)
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(8)
    self.m_pStream:WriteUInt(chid)
    self.m_pStream:WriteUInt(cpid)
    self:SendMsg(self.m_pStream)
end

--[[
请求帮派活跃度
]]
function LuaNetSendMsg:QueryBangPaiHuoyue()
    --print("QueryBangPaiHuoyue")
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(9)
    self:SendMsg(self.m_pStream)
end

--[[
请求帮派活跃度
]]
function LuaNetSendMsg:QueryGetBangPaiHuoyueReward(huoyueId)
    --print("QueryGetBangPaiHuoyueReward",huoyueId)
    Utils:ShowWaiting(LuaNetCmd.MSG_BP_Fuben)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_BP_Fuben)
    self.m_pStream:WriteByte(10)
    self.m_pStream:WriteWord(huoyueId)
    self:SendMsg(self.m_pStream)
end

--[[
请求小红点
]]
function LuaNetSendMsg:QueryRedDot(redType)
--print("------------------QueryRedDot-----------------------------",redType)
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_RED_POINT)
    self.m_pStream:WriteByte(1)
    self.m_pStream:WriteWord(redType)
    self:SendMsg(self.m_pStream)
    
end

--[[
请求游历三界数据
]]
function LuaNetSendMsg:QueryYouLiInfo()
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_YOULI)
    self.m_pStream:WriteByte(1)
    self:SendMsg(self.m_pStream)
end

--[[
游历开始
]]
function LuaNetSendMsg:SendYouLiStartReq(infos)
    if infos == nil or #infos == 0 then
        return
    end
    dump(infos,"SendYouLiStartReq SendYouLiStartReq")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_YOULI)
    self.m_pStream:WriteByte(2)
    self.m_pStream:WriteByte(#infos)
    for i=1,#infos do
        self.m_pStream:WriteWord(infos[i].heroId)
        self.m_pStream:WriteByte(infos[i].id)
        self.m_pStream:WriteByte(infos[i].mType)
        self.m_pStream:WriteByte(infos[i].tType)
    end
    self:SendMsg(self.m_pStream)
end

--[[
游历奖励领取
]]
function LuaNetSendMsg:SendYouLiPrizeReq(ids)
    if ids == nil or #ids == 0 then
        return
    end
    dump(ids,"SendYouLiPrizeReq SendYouLiPrizeReq")
    self:ResetStream()
    self.m_pStream:WriteUShort(LuaNetCmd.MSG_YOULI)
    self.m_pStream:WriteByte(3)
    self.m_pStream:WriteByte(#ids)
    for i=1,#ids do
        self.m_pStream:WriteByte(ids[i])
    end
    self:SendMsg(self.m_pStream)
end

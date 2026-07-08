local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")
LFirstRechargeData = {}
LFirstRechargeData.__index = LFirstRechargeData
function LFirstRechargeData:new()
    local o = {}
    setmetatable(o,LFirstRechargeData)
    o:ctor()
    return o
end

function LFirstRechargeData:ctor()
    self.cash = 0 --总价值
    self.isPaid = false      --是否已付款
    self.nowYB = 0
    self.needYB = 0

    self.itemList = {}
    --id
    --num

    self.petList = {}
    --LPetData

    self.wingList = {}--idList
    self.mountList = {}--idList 
end

LDailyRechargeData = {}
LDailyRechargeData.__index = LDailyRechargeData
function LDailyRechargeData:new()
    local o = {}
    setmetatable(o,LDailyRechargeData)
    o:ctor()
    return o
end

function LDailyRechargeData:ctor()
    self.wxSign = 0               --微信充值奖励是否开启
    self.chongzhi = 0         --是否已充值
    self.lingqu = 0           --是否已领取奖励
    self.wxchongzhi = 0       --微信是否已充值
    self.wxlingqu = 0         --微信每日首充是否已领取奖励
    self.itemList = {}
    --id
    --num

    self.petList = {}
    --LPetData(待删除)

end

LAwardData = {}
LAwardData.__index = LAwardData
function LAwardData:new()
    local o = {}
    setmetatable(o,LAwardData)
    o:ctor()
    return o
end

function LAwardData:ctor()
    self.awardType = 0 
    self.id = 0
    self.value = 0 --坐骑speed,道具num
    self.petData = nil
end


LSevenChargeData = {}
LSevenChargeData.__index = LSevenChargeData
function LSevenChargeData:new()
    local o = {}
    setmetatable(o,LSevenChargeData)
    o:ctor()
    return o
end

function LSevenChargeData:ctor()
    self.m_ChargeType = 0 
    self.m_curDay = 0
    self.m_leftTime = 0  
    self.m_curValue = 0
    self.m_dayItemDataArr = {}
    self.m_rewardDataArr = {}   --额外奖励数据集
    self.m_curLimit = 0
end

function LSevenChargeData:reset()
    self.m_ChargeType = 0 
    self.m_curDay = 0
    self.m_leftTime = 0  
    self.m_curValue = 0
    self.m_dayItemDataArr = {}
    self.m_rewardDataArr = {}   --额外奖励数据集
    self.m_curLimit = 0
end

LRechargeDataMgr = LDataBase:New()
LRechargeDataMgr.__index = LRechargeDataMgr
function LRechargeDataMgr:Awake()
	self.m_firstRechargeData = nil  --首充
    self.m_secondRechargeData = nil --次充
    self.m_dailyRechargeData = nil  --每日首充
    self.m_isBuyPlatinumUI = false
    self.m_BuyPlatinumType = 1  --1、月卡 2、终身月卡
    self.m_welFareActivityData = nil
    self.m_isInitWelfareACData = false
    --付费预告
--2星
    self.m_isTwoSPetIconShow = true
--3星
    self.m_isThreePetIconShow = true
--任务一条龙
    self.needAutoTask = false
    self.autoTaskId = 0
--昆仑寻宝
    self.isShowBattleChatNow = false
    self.isMonopolyBattleWin = false
end

function LRechargeDataMgr:Free()
	self.m_firstRechargeData = nil
    self.m_secondRechargeData = nil
    self.m_dailyRechargeData = nil
end

function LRechargeDataMgr:GetFirstRechargeData()
	if self.m_firstRechargeData == nil then
       self.m_firstRechargeData = LFirstRechargeData:new()
    end
    return self.m_firstRechargeData
end

function LRechargeDataMgr:getWelfareIndexByTag( tag )
    -- body
    local datas = LRechargeDataMgr:GetWelFareActivityData()
    local index = 1
    if tag > 0 then
        for i=1,#datas do
            if datas[i].tag == tag then
                index = i
                break
            end
        end
    end
    return index
end

function LRechargeDataMgr:updateWelfareActivityData (datas)
    -- body
    -- local data = {}
    -- data.tag = WelfareActivityDef.Type.GetTiLi
    -- data.uname = "领取体力"
    -- data.state = 1
    -- data.newMask = 0
    -- data.endTime = LDataConstMgr.m_serverTime + 100000
    -- table.insert(datas, data)

    if #datas < 1 then
        return
    end
    self.m_isInitWelfareACData = false
    self.m_welFareActivityData = datas

end

function LRechargeDataMgr:GetWelFareActivityData ( ... )
    -- body
    if self.m_welFareActivityData == nil then
       self.m_welFareActivityData = {}
    end
    return self.m_welFareActivityData
end

function LRechargeDataMgr:isPaiHangShow( ... )
    -- body
    local tag , endTime = self:getTotayPaiHangID()
    --print("isPaiHangShow tag", tag)
    return tag > 0
end

function LRechargeDataMgr:getTotayPaiHangID ()
    -- body
    local datas = self:GetWelFareActivityData()
    for i=1, #datas do
        if (datas[i].tag >= 13 and datas[i].tag <= 17) or datas[i].tag == 33 then
            --print("datas[i].endTime", datas[i].endTime)
            if datas[i].endTime < 24 * 3600 and datas[i].endTime > 0 then
                return datas[i].tag, datas[i].endTime
            end
        end
    end
    return 0, 0
end

function LRechargeDataMgr:getTagDataById( tag )
    -- body
    local datas = self:GetWelFareActivityData()
    for i=1, #datas do
        if datas[i].tag == tag then
            return datas[i]
        end
    end
    return nil
end

function LRechargeDataMgr:GetSecondRechargeData()
	if self.m_secondRechargeData == nil then
       self.m_secondRechargeData = LFirstRechargeData:new()
    end
    return self.m_secondRechargeData
end

function LRechargeDataMgr:GetDailyRechargeData()
	if self.m_dailyRechargeData == nil then
       self.m_dailyRechargeData = LDailyRechargeData:new()
    end
    return self.m_dailyRechargeData
end

function LRechargeDataMgr:GetSevenRechargeData( ... )
    -- body
    if self._SevenRechargeData == nil then
        self._SevenRechargeData = LSevenChargeData:new()
    end
    return self._SevenRechargeData
end

function LRechargeDataMgr:isWelfareActivityOpen(tag)
    for i=1, #self.m_welFareActivityData do
        if self.m_welFareActivityData[i].tag == tag then
            return true
        end
    end
    return false
end

function LRechargeDataMgr:getWelfareActivityData(tag)
    for i=1, #self.m_welFareActivityData do
        if self.m_welFareActivityData[i].tag == tag then
            return self.m_welFareActivityData[i]
        end
    end
    return nil
end

function LRechargeDataMgr:updateSevenChargeData( stream )
    -- body
    local sevenRechargeData = self:GetSevenRechargeData()
    sevenRechargeData:reset()
    sevenRechargeData.m_ChargeType = opType
    sevenRechargeData.m_curDay = stream:ReadByte()
    sevenRechargeData.m_leftTime = stream:ReadUInt()
--    sevenRechargeData.m_leftTime = 50000;
    sevenRechargeData.m_curValue = stream:ReadUInt()

    local dayRewardCount  = stream:ReadByte()  --每日充值奖励（礼包
    -- print("dayRewardCount ==", dayRewardCount)
    local offsetNum = 0
    for k = 1, dayRewardCount do
        local dayInfo = {}
        dayInfo.dayIdx = stream:ReadByte()   --天数
        dayInfo.dayLimit = stream:ReadUInt()  --当天充值额限制
        dayInfo.state = stream:ReadByte()   --1未完成，2可以领取， 3已经领取
        if dayInfo.state == 3 then
            offsetNum = offsetNum + 1  --当前展示的额外奖励索引,C++从0开始，lua中从1开始
        end
        if sevenRechargeData.m_curDay == dayInfo.dayIdx then
            sevenRechargeData.m_curLimit = dayInfo.dayLimit
        end
--        print("每日奖励, day: ", dayInfo.dayIdx, "; limit: ", dayInfo.dayLimit, "; state: ", dayInfo.state)
        local num = stream:ReadByte()   --礼包内容
        dayInfo.itemArr = {}
        for i=1, num do
            dayInfo.itemArr[i] = self:readItemData(stream)
        end
        -- dump(dayInfo, "updateSevenChargeData ++++++++++++++++++++")
        table.insert(sevenRechargeData.m_dayItemDataArr, dayInfo)
    end

    local RewardCount  = stream:ReadByte()  --额外奖励（礼包
    -- print("RewardCount ==", RewardCount)
    local offsetPage = 0
    for i=1, RewardCount do
        local dayInfo = {}
        dayInfo.dayIdx = stream:ReadByte()
        if sevenRechargeData.m_curValue < sevenRechargeData.m_curLimit then
            dayInfo.dayOffset = dayInfo.dayIdx - sevenRechargeData.m_curDay + 1  --今天还没有达到要求
        else
            dayInfo.dayOffset = dayInfo.dayIdx - sevenRechargeData.m_curDay  --距离领取还剩多少天,负值表示已经达到天数
        end
        dayInfo.state = stream:ReadByte()   --1未完成，2可以领取， 3已经领取
        if dayInfo.state == 3 then
            offsetPage = offsetPage + 1
        end
--        print("额外奖励, day: ", dayInfo.dayIdx,  " offset: ", dayInfo.dayOffset, "; state: ", dayInfo.state, sevenRechargeData.m_curDay, sevenRechargeData.m_curValue)
        local num = stream:ReadByte()   --礼包内容
        dayInfo.itemArr = {}
        for i=1, num do
            dayInfo.itemArr[i] = self:readItemData(stream)
        end
        -- dump(dayInfo, "updateSevenChargeData ++++++++++++++++++++")
        table.insert(sevenRechargeData.m_rewardDataArr, dayInfo) 
    end
--    print("sevenRechargeData.m_curValue", sevenRechargeData.m_curValue, sevenRechargeData.m_curDay, sevenRechargeData.m_curLimit)
--    dump(sevenRechargeData, "mySevenData")
end

function LRechargeDataMgr:isSevenChargeActivityOpen( ... )
    -- body
    local sevenRechargeData = self:GetSevenRechargeData()
    if  sevenRechargeData == nil then
        return false
    end
    return sevenRechargeData.m_curDay < 8 and sevenRechargeData.m_curDay > 0
end

function LRechargeDataMgr:isTotayAlreadBuy( ... )
    -- body
    local sevenRechargeData = self:GetSevenRechargeData()
    if sevenRechargeData == nil or sevenRechargeData.m_curDay == nil then
        return false
    end
    local dayData = LRechargeDataMgr:getItemDayData(sevenRechargeData.m_curDay)
    if dayData == nil or dayData.state == nil then
        return false
    end

    return dayData.state > 1

end

function LRechargeDataMgr:getCurDayFirstData( ... )
    -- body
    local sevenRechargeData = self:GetSevenRechargeData()
    if sevenRechargeData == nil then
        return 0, 0
    end
--    dump(sevenRechargeData.m_dayItemDataArr, "getCurDay info")
    if #sevenRechargeData.m_dayItemDataArr < 1 then
        return 0, 0
    end
--    print("sevenRechargeData.m_curDay ===", sevenRechargeData.m_curDay)
    if #sevenRechargeData.m_dayItemDataArr < sevenRechargeData.m_curDay then
        return 0, 0
    end
    if #sevenRechargeData.m_dayItemDataArr[sevenRechargeData.m_curDay].itemArr < 0 then
        return 0, 0
    end
--    dump(sevenRechargeData.m_dayItemDataArr[sevenRechargeData.m_curDay].itemArr, "see the data")
    local Id = sevenRechargeData.m_dayItemDataArr[sevenRechargeData.m_curDay].itemArr[1].awardType
    local num = sevenRechargeData.m_dayItemDataArr[sevenRechargeData.m_curDay].itemArr[1].awardValue
    return Id, num
end

function LRechargeDataMgr:isNeedQueryData( ... )
    -- body
    if self._SevenRechargeData == nil or self._SevenRechargeData.m_rewardDataArr == nil then
        return true
    end
    return #self._SevenRechargeData.m_rewardDataArr < 1
end

--state 1 不能领取 2 可以领取 3 已经领取
function LRechargeDataMgr:updateRewardDataByIndex(day, state)
    -- body
--    print("update data day", day, state)
    if self._SevenRechargeData.m_rewardDataArr[day] == nil then
        return
    end
    self._SevenRechargeData.m_rewardDataArr[day].state = state
end

function LRechargeDataMgr:getCurShowData()
    -- body
    local index = self:getCurShowIndex()
    print("show index = ", index)
    -- dump(self._SevenRechargeData.m_rewardDataArr, "getCurShowData ===>")
    return self._SevenRechargeData.m_rewardDataArr[index]
end

function LRechargeDataMgr:getCurShowIndex( ... )
    -- body
--    dump(self._SevenRechargeData.m_rewardDataArr, "getCurShowData")
    for i = 1, #self._SevenRechargeData.m_rewardDataArr do
        local data = self._SevenRechargeData.m_rewardDataArr[i]
        if data.state == 1 then
            return i
        end

        if data.state == 2 then
            return i
        end

    end
    return 3
end

function LRechargeDataMgr:getCurAwardLightNum( ... )
    -- body
    local index = self:getCurShowIndex()
    local lightNum = 3
    if index == 1 then
        lightNum = 3
    elseif index == 2 then
        lightNum = 5
    elseif index == 3 then
        lightNum = 7
    end
    return lightNum
end

function LRechargeDataMgr:getAwardStarNum( ... )
    -- body
    local num = self:getCurShowIndex()
    local starNum = 3
    if num == 1 then
        starNum = 3
    elseif num == 2 then
        starNum = 5
    elseif num == 3 then
        starNum = 7
    end
    return starNum
end

function LRechargeDataMgr:getItemDayData( day )
    -- body
    if self._SevenRechargeData == nil then
        return nil
    end

    if self._SevenRechargeData.m_dayItemDataArr == nil then
        return nil
    end

    return self._SevenRechargeData.m_dayItemDataArr[day]

end

function LRechargeDataMgr:updateDayChargeData(day)
    -- body
    local data = LRechargeDataMgr:getItemDayData(day)
    if data == nil then
        return
    end
    data.state = 3
--    dump(self._SevenRechargeData.m_dayItemDataArr, "updateData")
end

function LRechargeDataMgr:getSevenRechargeRedDot( ... )
    -- body
    if self._SevenRechargeData == nil then
        return false
    end

    for i = 1, #self._SevenRechargeData.m_dayItemDataArr do
        if self._SevenRechargeData.m_dayItemDataArr[i].state == 2 then
            return true
        end
    end

    for i=1, #self._SevenRechargeData.m_rewardDataArr do
        if self._SevenRechargeData.m_rewardDataArr[i].state == 2 then
            return true
        end
    end

    return false
end

function LRechargeDataMgr:getLightStarNum()
    -- body
    local num = 0
    for i=1,#self._SevenRechargeData.m_dayItemDataArr do
        local data = self._SevenRechargeData.m_dayItemDataArr[i]
        if data.state == 2 or data.state == 3 then
            num = num + 1
        end
    end
    return num
end

function LRechargeDataMgr:getFirstAwardIndex()
    -- body
    for i=1,#self._SevenRechargeData.m_dayItemDataArr do
        local data = self._SevenRechargeData.m_dayItemDataArr[i]
        if data.state == 1 or data.state == 2 then
            return i
        end
    end
    return 7
end


function LRechargeDataMgr:readItemData( l_stream )
    -- body
    local itemId = l_stream:ReadWord()    --物品ID
    local itemNum = 1  --物品数量
    local descInfo = ""   --礼包描述（包含物品描述）
    local petData = nil
    if itemId == AppDef.AwrdItem.AWRD_ITEM_PET then
        local pid = l_stream:ReadUInt()
        local star = l_stream:ReadByte()
        local level = l_stream:ReadByte()
--        pid = 10
        -- print("pid= ", pid, itemId)
--        local petData = LPetData:New(pid)
--        LuaNetRecvdMsg.ReadPetInfo(petData, l_stream)
        local petDataTmp = LDataConstMgr:GetPetData(pid)
        if petDataTmp then
            descInfo = petDataTmp.name
            petData = petDataTmp
            petData.star = star
            petData.level = level
        end
       -- dump(petData, "readItemData **************")
    elseif itemId == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then  --称号
        itemNum = l_stream:ReadUInt()   --称号在称号序列中的位置索引
--        descInfo = 
--        local medalID = stream:ReadUInt()
        medalID = 10
        petData = {}
        LuaNetRecvdMsg.ReadMedalAddition(medalID, l_stream, petData)
    else
        petData = 0
        itemNum = l_stream:ReadUInt()   --物品数量
        local name = Utils:getItemNameByID(itemId)
        descInfo = string.format("%s X %d",name, itemNum)
    end
--    print("itemId: ", itemId, "; itemNum: ", itemNum, "; descInfo: ", descInfo, "; petData: ", petData)
    local tempData = {}
    tempData.awardType = itemId
    tempData.awardValue = itemNum
    tempData.descStr = descInfo
    tempData.petData = petData
    return tempData
end

--写死 排行榜每天显示顺序 根据 tag设置好
function LRechargeDataMgr:getPaihangIndex( tag )
    -- body
    local index = 1
    if tag == 15 then
        index = 1
    elseif tag == 14 then
        index = 2
    elseif tag == 13 then
        index = 3
    elseif tag == 33 then
        index = 4
    elseif tag == 16 then
        index = 5
    elseif tag == 17 then
        index = 6
    end
    return index
end

return LRechargeDataMgr:Awake()



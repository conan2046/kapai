--å‰¯æœ¬ä¿¡æ¯
LCopyData = {}
LCopyData.__index = LCopyData
function LCopyData:New()
    local o = {}
    setmetatable(o,LCopyData)    
    o:ctor()
    return o
end

function LCopyData:ctor()
    self.SweepData = 0          --å‰¯æœ¬æ‰«è¡ä¿¡æ¯
    self.MyCopyInfo = 0         --ä½“åŠ› åŠ é€Ÿæ¬¡?å†·å´æ—¶é—´
    self.IsOpenZhuZhan = 0      --åç§°
    self.SaoDangLevel = 0       --æ‰«è¡å¼€å¯ç­‰?
    self._MineList = {}         --å‰¯æœ¬åˆ—è¡¨
    self._PetCopyList = {}      --å® ç‰©å‰¯æœ¬åˆ—è¡¨
    self._CopyList = {}         --å‰¯æœ¬ä¿¡æ¯
    self._CopyDropList = {}     --å‰¯æœ¬æŽ‰è½ç‰©å“åˆ—è¡¨
end

function LCopyData:Delete()
    self.SweepData = nil
    self.MyCopyInfo = nil
    self.IsOpenZhuZhan = nil
    self.SaoDangLevel = nil 
    self._MineList = nil
    self._PetCopyList = nil
    self._CopyList = nil
    self._CopyDropList = nil
end

function LCopyData:ADDDropData(touchId, data)
    for key, value in pairs(self._CopyDropList) do
        if value.Id == touchId then
            value = data
            return
        end
    end
    self._CopyDropList[#self._CopyDropList + 1] = data
end

function LCopyData:DelDropData(touchId)
    for key, value in pairs(self._CopyDropList) do
        if value.Id == touchId then
            value = nil
            return
        end
    end
end

function LCopyData:GetDropDataList() return self._CopyDropList end

function LCopyData:UpdateCopyData(touchId, data)
    for key, value in pairs(self._CopyList) do
        if value.Id == touchId then
            value = data
            return
        end
    end
    self._CopyList[#self._CopyList + 1] = data
end

function LCopyData:GetCopyList() return self._CopyList end

function LCopyData:UpdateMineData(touchId, data) self._MineList[touchId] = data end
function LCopyData:GetMineList() return self._MineList end

function LCopyData:UpdatePetCopyData(touchId, data)
    for key, value in pairs(self._PetCopyList) do
        if value.Id == touchId then
            value = data
            return
        end
    end
    self._PetCopyList[#self._PetCopyList + 1] = data
end

function LCopyData:GetPetCopyList() return self._PetCopyList end

LSweepCopyData = {}
LSweepCopyData.__index = LSweepCopyData
function LSweepCopyData:New()
    local o = {}
    setmetatable(o,LSweepCopyData)    
    o:ctor()
    return o
end

function LSweepCopyData:ctor()
    self.curTime = 0
    self.sweepAward = {}
end

function LSweepCopyData:Delete()
    self.curTime = nil
    self.sweepAward = nil
end


LHeroCopyInfo = {}
LHeroCopyInfo.__index = LHeroCopyInfo
function LHeroCopyInfo:New()
    local o = {}
    setmetatable(o,LHeroCopyInfo)    
    o:ctor()
    return o
end

function LHeroCopyInfo:ctor()
    self.coldtime = 0
    self.herotili = 0
    self.addSpTime = 0
end

function LHeroCopyInfo:Delete()
    self.coldtime = nil
    self.herotili = nil
    self.addSpTime = nil
end

LMineInfo = {}
LMineInfo.__index = LMineInfo
function LMineInfo:New()
    local o = {}
    setmetatable(o,LMineInfo)    
    o:ctor()
    return o
end

function LMineInfo:ctor()
    self.Id = 0                 --ID
    self.Name = 0               --名称
    self.MineLv = 0             --矿等级
    self.LeftTime = 0           --剩余时间
    self.IsLock = 0             --是否锁定
    self.OpenLv = 0             --开启等级
    self.UseMoney = 0           --消耗金钱
    self.ClearTimeCost = 0      --清除时间消耗
    self.Notice = 0             --开启条件
    self.Description = 0        --描述文字
    self.costtype = 0           --消耗类型 1元宝 0金币
    self.ItemId = {}            --奖励信息
    self.ItemNum = {}           --奖励数量
    self.canEnterTimes = 0      --可进入的次数
    self.jilvSrc = 0            --几率描述
    self.jiLv = 0               --几率
    self.maxSweepTimes = 0      --最大扫荡次数 0表示未开通特权, 大于0表示可扫荡次数
    self.ardSweepTimes = 0      --已扫荡次数
    self.isCleared = 0          --是否通关
end

function LMineInfo:Delete()
    self.Id = nil
    self.Name = nil
    self.MineLv = nil
    self.LeftTime = nil   
    self.IsLock = nil
    self.OpenLv = nil
    self.UseMoney = nil
    self.ClearTimeCost = nil
    self.Notice = nil
    self.Description = nil
    self.costtype = nil
    self.ItemId = nil
    self.ItemNum = nil
    self.canEnterTimes = nil
    self.jilvSrc = nil
    self.jiLv = nil
    self.maxSweepTimes = nil
    self.ardSweepTimes = nil
    self.isCleared = nil
end

LCopyInfo = {}
LCopyInfo.__index = LCopyInfo
function LCopyInfo:New()
    local o = {}
    setmetatable(o,LCopyInfo)    
    o:ctor()
    return o
end

function LCopyInfo:ctor()
    self.Id = 0             -- ID
    self.CopyName = 0       -- 名称
    self.MaxTimes = 0       -- 最大进入次数
    self.CurTimes = 0       -- 已进次数
    self.EnterLevel = 0     -- 进入等级
    self.CostTili = 0       -- 体力消耗
    self.CanSweep = 0       -- 是否可以扫荡
    self.CopyType = 0       -- 0普通1精英
    self.IsLocked = 0       -- 是否是处于锁定状态
    self.CopyLevel = 0      -- 副本级别
    self.Description = 0
    self.CostMoney = 0      -- 消耗金币
    self.JiLvSrc = 0        -- 掉落几率描述
    self.JiLv = 0           -- 掉落几率
    self.ItemId = {}        -- 奖励信息
end

function LCopyInfo:Delete()
    self.Id = nil
    self.CopyName = nil
    self.MaxTimes = nil
    self.CurTimes = nil
    self.EnterLevel = nil
    self.CostTili = nil
    self.CanSweep = nil
    self.CopyType = nil
    self.IsLocked = nil
    self.CopyLevel = nil
    self.Description = nil
    self.CostMoney = nil
    self.JiLvSrc = nil
    self.JiLv = nil
    self.ItemId = nil
end

LCopyDropAward = {}
LCopyDropAward.__index = LCopyDropAward
function LHeroCopyInfo:New()
    local o = {}
    setmetatable(o,LCopyDropAward)    
    o:ctor()
    return o
end

function LCopyDropAward:ctor()
    self.TouchItemId = 0    -- å¯ç‚¹å‡»id
    self.TouchItemType = 0    -- ç‚¹å‡»ç‰©ç±»?å® ç‰©2ç‰©å“
    self.PetId = 0
    self.Quality = 0
    self.ItemId = 0
    self.ItemNum = 0
    self.IsLocked = 0
    self.UnLockType = 0        -- 1ï¼Œé‡‘?å…ƒå®3ç‰©å“  
    self.UnLockValue = 0    -- éžç»‘å®šç‰©æ•°é‡
    self.UnLockItemId = 0    -- è§£é”éœ€è¦çš„ç‰©å“Id
end

function LCopyDropAward:Delete()
    self.TouchItemId = nil
    self.TouchItemType = nil
    self.PetId = nil
    self.Quality = nil
    self.ItemId = nil
    self.ItemNum = nil
    self.IsLocked = nil
    self.UnLockType = nil
    self.UnLockValue = nil
    self.UnLockItemId = nil
end

LCopyAwardData = {}
LCopyAwardData.__index = LCopyAwardData
function LCopyAwardData:New()
    local o = {}
    setmetatable(o,LCopyAwardData)    
    o:ctor()
    return o
end

function LCopyAwardData:ctor()
    self.op = 0
    self.AwardType = 0
    self.extraExp = 0
    self.Money = 0
    self.qianneng = 0
    self.myItemIndex = 0
    self.attachData = 0
    self.itemId = {}
    self.itemPid = {}
    self.itemName = {}
    self.itemVal1 = {}
    self.itemVal2 = {}
    self.star = 0
end

function LCopyAwardData:Delete()
    self.op = nil
    self.AwardType = nil
    self.extraExp = nil
    self.Money = nil
    self.qianneng = nil
    self.myItemIndex = nil
    self.attachData = nil
    self.itemId = nil
    self.itemPid = nil
    self.itemName = nil
    self.itemVal1 = nil
    self.itemVal2 = nil
    self.star = nil
end

function LCopyAwardData:ToStr()
	local strRet
    local num = 0
    --print(self.op, self.AwardType, self.Money, self.qianneng, self.extraExp, self.myItemIndex)
    strRet = string.format("%d,%d,%d,%d,%d,%d", 
    	self.op, self.AwardType, self.Money, self.qianneng, self.extraExp, self.myItemIndex)

    num = #self.itemId
    strRet = strRet..num
    for i=1, num do
    	strRet = strRet..self.itemId[i]..","
    end

    num = #self.itemPid
    strRet = strRet..num
    for i=1, num do
    	strRet = strRet..self.itemPid[i]..","
    end

    num = #self.itemVal1
    strRet = strRet..num
    for i=1, num do
    	strRet = strRet..self.itemVal1[i]..","
    end

    num = #self.itemVal2
    strRet = strRet..num
    for i=1, num do
    	strRet = strRet..self.itemVal2[i]..","
    end

    num = #self.itemName
    strRet = strRet..num
    for i=1, num do
    	strRet = strRet..self.itemName[i]..","
    end

    return strRet
end

function LCopyAwardData:FromStr(str)
    local tagChar = ","
    local offset = 1
    local size
    self.op, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    self.AwardType, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    self.Money, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    self.qianneng, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    self.extraExp, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    self.myItemIndex, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)

    size, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    for i=1,size do
    	self.itemId[i], offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    end

    size, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    for i=1,size do
    	self.itemPid[i], offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    end

    size, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    for i=1,size do
    	self.itemVal1[i], offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    end

    size, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    for i=1,size do
    	self.itemVal2[i], offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    end

    size, offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    for i=1,size do
    	self.itemName[i], offset = Utils:ReadBeforeCharInt(str, tagChar, offset)
    end
end

LLoginGitt = {}
LLoginGitt.__index = LLoginGitt
function LLoginGitt:New()
    local o = {}
    setmetatable(o,LLoginGitt)    
    o:ctor()
    return o
end

function LLoginGitt:ctor()
    self.dayNum = 0 -- æ€»å¤©
    self.getNum = 0	-- å·²ç»é¢†å–å¤©æ•°
    self.canGet = 0 -- æ˜¯å¦å¯ä»¥é¢†å–
    self.num = 0
    self.dayInfo = {}
end

function LLoginGitt:Reset()
    self.dayNum = 0 -- æ€»å¤©
    self.getNum = 0 -- å·²ç»é¢†å–å¤©æ•°
    self.canGet = 0 -- æ˜¯å¦å¯ä»¥é¢†å–
    self.num = 0
    self.dayInfo = {}
end

function LLoginGitt:Delete()
    self.dayNum = nil
    self.getNum = nil
    self.canGet = nil
    self.num = nil
    self.dayInfo = nil
end

LTaocanInfo = {}
LTaocanInfo.__index = LTaocanInfo
function LTaocanInfo:New()
    local o = {}
    setmetatable(o,LTaocanInfo)    
    o:ctor()
    return o
end

function LTaocanInfo:ctor()
    self.pian_index = 0
    self.pian_price = 0
    self.levelId = 0  
    self.canBuy = 0
    self.level = 0
    self.ItemId = {}
    self.ItemNum = {}
    self.petdata = {}
    self.ItemData = {}
    self.windsAddtionData = {}
    self.haveGet = false
    self.value={}
	self.reward = {}

end

function LTaocanInfo:Delete()
    self.pian_index = nil
    self.pian_price = nil
    self.levelId = nil
    self.canBuy = nil
    self.level = nil
    self.ItemId = nil
    self.ItemNum = nil
    self.petdata = nil
    self.ItemData = nil
    self.windsAddtionData = nil
    self.haveGet = nil
    self.value=nil
	self.reward = nil
end

LWindsAdditionData = {}
LWindsAdditionData.__index = LWindsAdditionData
function LWindsAdditionData:New()
    local o = {}
    setmetatable(o,LWindsAdditionData)    
    o:ctor()
    return o
end

function LWindsAdditionData:ctor()
    self.windId = 0     --id
    self.zhandouli = 0  --æˆ˜æ–—?
    self.attack = 0     --æ”»å‡»
    self.recovery = 0   --é˜²å¾¡
    self.hp = 0         --è¡€?
    self.speed = 0      --é€Ÿåº¦
    self.shanbi = 0     --é—ªé¿
    self.mingzhong = 0  --å‘½ä¸­
    self.baoji = 0      --æš´å‡»
    self.renxing = 0    --éŸ?
    self.fanshang = 0   --åä¼¤
    self.jianshang = 0  --å‡ä¼¤
end

function LWindsAdditionData:Delete()
    self.windId = nil
    self.zhandouli = nil
    self.attack = nil
    self.recovery = nil
    self.hp = nil
    self.speed = nil
    self.shanbi = nil
    self.mingzhong = nil
    self.baoji = nil
    self.renxing = nil
    self.fanshang = nil
    self.jianshang = nil
end

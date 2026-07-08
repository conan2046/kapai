LDailySignData = {}
LDailySignData.__index = LDailySignData


LDailySignAward = {}
LDailySignAward.__index = LDailySignAward


-- ----------------------------------------------
function LDailySignData:New()
	local o = {}
	setmetatable(o, LDailySignData )	
	o:ctor()
	return o
end

-- ----------------------------------------------
function LDailySignData:ctor()
    self.isdone = 0
    self.signnum = 0
    self.daynum = 0
    self.daily_award = {}
end

-- ----------------------------------------------
function LDailySignData:Delete(id )
    self.isdone = nil
    self.signnum = nil
    self.daynum = nil
    self.daily_award = nil
end

-- ----------------------------------------------
function LDailySignData:PushDailyAward(award)
    if not self.daily_award then
        self.daily_award = {}
    end
    table.insert(self.daily_award, award)
end


-- ----------------------------------------------
function LDailySignAward:New()
	local o = {}
	setmetatable(o, LDailySignAward )	
	o:ctor()
	return o
end

-- ----------------------------------------------
function LDailySignAward:ctor()
    self.dayidx = 0
    self.awardtype = 0
    self.value=0
    self.awardnum = 0
    self.viplv = 0
    self.vipmultiple = 0
end

-- ----------------------------------------------
function LDailySignAward:Delete(id)
    self.dayidx = nil
    self.value=nil
    self.awardnum = nil
    self.viplv = nil
    self.awardstar=nil
    self.vipmultiple = nil
end






--[[
lua里面的游戏逻辑控制
]]
LTipsManager = LDataBase:New()
LTipsManager.__index = LTipsManager
function LTipsManager:New()
	local o = LUIBase:New()
	setmetatable(o,LTipsManager)	
	o:Awake()
	return o
end

function LTipsManager:Awake()
	self.m_bIsLoaded = false
	self.m_pTipsDict = {}
    self.m_pItemColor = nil
    self.m_pColorPetChat = nil
end

function LTipsManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadTips()
		self.m_bIsLoaded = true
	end
	return self
end

function LTipsManager:ReadTips()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/tips.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		self.m_pTipsDict[tonumber(v["@id"])] = v["@content"]
	end
end

--[[
@功能：获取提示文字
param1:id(int)提示文字的id
return:string提示文字字符串
]]
function LTipsManager:GetTips(tid)
    if self.m_pTipsDict[tid] ~= nil then
        return self:GetXMLTips(self.m_pTipsDict[tid])
    else
        return ""
    end
    -- if (m_pTipsDict.ContainsKey(tid))
    -- {
    --     local tips = self:GetXMLTips(self.m_pTipsDict[tid])
    --     return DisposeTips(tips);
    -- }
    -- return string.Empty;
end

function LTipsManager:GetHelpTips(tid)
    local TempTable = {}
    local str = self:GetTips(tid)
    local sx = string.FindStr(str,"#N")
    while sx ~= nil do
        table.insert(TempTable,string.SubStringUTF8(str, 3, sx-1))
        str = string.SubStringUTF8(str, sx + 3, string.SubStringGetTotalIndex(str))
        sx = string.FindStr(str,"#N")
    end
    return TempTable
end

function LTipsManager:GetTipsGsub(tid,names)
    local str = self:GetTips(tid)
    str = string.gsub(str,'{%%}',"%%s")
    str = string.format(str,unpack(names))
    return str
end

function LTipsManager:GetSkillTips(tid,names)
    local str = self:GetTips(tid)
    for i=1,#names do
       local strs1 = string.split(names[i], "+");
       str = (string.gsub(str,strs1[1],strs1[2],1))
    end
    return str
end

function LTipsManager:GetXMLTips(tips)
    --tips = "确定要{*0xff0000}逃跑{*0xffffff}吗？";
    local colorFlag = "{*0x"
    local sx = string.find(tips,colorFlag)
    local ex = 0
    local endColor = "</color>"
    local colorLen = 11
    tips = string.gsub(tips,"{%*0xnn}",endColor)
    while sx ~= nil do
        local subStr = string.sub(tips,sx-2,sx-3 + colorLen)
        subStr = string.sub(subStr,1,1) .. "%" .. string.sub(subStr,2,colorLen)
        local color = "<color=#" .. string.sub(tips,sx + 2,sx + 1 + 6) .. "ff>"
        tips = string.gsub(tips,subStr,color,1)
        sx = string.find(tips,colorFlag)
    end
    return tips
end



function LTipsManager:GetItemColorStr(item)
    if item == nil then
        return nil
    end
    local name = self:GetTips(item.m_pBItem.m_iNameId)
    local color
    if item.m_pBItem.m_eType == 7 then
        color = 4
    else 
        color = item.m_pBItem.m_byColor
    end
    if self.m_pItemColor == nil then
        self.m_pItemColor = {}
        local s = LGlobalparameterManager:Instance():GetGlobalParameterString("item_color2")
        local ss = string.split(s, "|")
        for i=1,#ss do
            local sss = string.split(ss[i],"-")
            self.m_pItemColor[tonumber(sss[1])] = sss[2]
        end
    end

    local nameColor = self.m_pItemColor[color]
    return "<color=" .. nameColor .. ">[" .. name .. "]</color>"
end

function LTipsManager:GetPetColorStr(petinfo)
    if petinfo == nil then
        return nil
    end
    local name = self:GetTips(petinfo.m_petDatatable.m_iNameId)
    local color
    --根据宠物的信息获取不同品质的颜色
    if self.m_pColorPetChat == nil then
        self.m_pColorPetChat = {}
        local s = LGlobalparameterManager:Instance():GetGlobalParameterString("pet_color2")
        local ss = string.split(s, "|")
        local nameColor = "";
        for i=1,#ss do
            local sss = string.split(ss[i],"-")
            self.m_pColorPetChat[tonumber(sss[1])] = sss[2]
        end
    end
    return "<color=" .. self.m_pColorPetChat[petinfo.m_petDatatable.m_byType] .. ">[" .. name .. "]</color>"
end

function LTipsManager:GetItemTips(item)

end



return LTipsManager:Awake()
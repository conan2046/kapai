--[[
lua里面的XML加载控制中心
]]

LXMLCenter = LDataBase:New()
LXMLCenter.__index = LXMLCenter
function LXMLCenter:New()
	local o = LDataBase:New()
	setmetatable(o,LXMLCenter)	
	o:Awake()
	return o
end

function LXMLCenter:Awake()
	print("LXMLCenter:Awake")
	-- self.msgIds = 
	-- {
	-- 	0,
	-- }
	self:RegistSelf(self,self.msgIds)
	self:InitXMLData()
	self:PreloadXMLData()
end

function LXMLCenter:InitXMLData()
	self.m_xmlLoader = require("Data.XML.LXMLReader").newParser()
	self.m_pXMLResMsg = LAssetMsg:New(LAssetEvent.GetRes)--默认的资源加载消息
	self.m_pXMLReses = {}--Dictionary<string, List<string>>
	self.m_pXMLBundleReses = {}--List<string>
	self.m_pXMLDocs = {}--Dictionary<string, XmlDocument>
	self.m_iLoadCnt = 1


	table.insert(self.m_pXMLBundleReses,"gameres_xml")

    local xmlpaths = {}
    self.m_pXMLReses[self.m_pXMLBundleReses[1]] = xmlpaths
    table.insert(xmlpaths,"Assets/GameRes/xml/tips.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/activity.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/activyreward.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/bangpaixiulian.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/bangzhan.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/npc.xml")
    --伙伴相关数据
    table.insert(xmlpaths,"Assets/GameRes/xml/brother.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/brother_exp.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/brotherfriend.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/brothervalue.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/dati.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/drillCost.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/equipment.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/fashion.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/function_open.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/gangDonate.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/ganglevel.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/globalparameter.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/guide.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/huobanyuanfen.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/item.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/jewel.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/name.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/skill.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/pet_skill.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/skill_consume.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/shuxing.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/shuxingjiadian.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/stunt.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/Vocationgrowth.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/role_exp.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/resource.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/use_item.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/makeitem.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/live_skill.xml")
    --宠物相关数据
    table.insert(xmlpaths,"Assets/GameRes/xml/pet.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/petskill.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/pet_exp.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/pet_practice.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/skill_open.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/practice_change.xml")
    
    table.insert(xmlpaths,"Assets/GameRes/xml/jishi_goods.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/jishi_firstpage.xml")
    table.insert(xmlpaths,"Assets/GameRes/xml/jishi_secondpage.xml")
end

function  LXMLCenter:GetXML(resName)
	return self.m_pXMLDocs[resName]
end

--[[
预加载XML信息
]]
function LXMLCenter:PreloadXMLData()
	function AddCallback(bundleName, resName, obj)
		local strXML = obj:ToString()
		local parsedXml = self.m_xmlLoader:ParseXmlText(strXML)
        local ind = self.m_iLoadCnt - 1
        local bundleName = self.m_pXMLBundleReses[1]
        local resName = self.m_pXMLReses[bundleName][ind]
        self.m_pXMLDocs[resName] = parsedXml
        --
        self:PreloadXMLData()
    end

    if self.m_iLoadCnt <= #self.m_pXMLReses[self.m_pXMLBundleReses[1]] then
        local bundleName = self.m_pXMLBundleReses[1];
        local resName = self.m_pXMLReses[bundleName][self.m_iLoadCnt]
        self.m_iLoadCnt = self.m_iLoadCnt + 1
        self.m_pXMLResMsg:Change(bundleName, resName, true, AddCallback)
        self:SendMsg(self.m_pXMLResMsg)
        
	else
		table.remove(self.m_pXMLBundleReses,1)
        if #self.m_pXMLBundleReses > 0 then
            self.m_iLoadCnt = 1
            self:PreloadDataFile()
        else
        	LGameMsg.m_baseMsg:ChangeEventId(LGameNetEvent.ConfigDataLoadFinish)
        	self:SendMsg(LGameMsg.m_baseMsg)
        end
    end
end


function LXMLCenter:ProcessEvent(msg)
	-- if msg.msgId == 0 then
	-- end
end

return LXMLCenter:Awake()
--[[
lua里面的游戏逻辑控制
神将-图鉴(阵容推荐)
]]

local PetArchiveFormationSubUI = LUIBase:New()
PetArchiveFormationSubUI.__index = PetArchiveFormationSubUI
function PetArchiveFormationSubUI:New()
    local o = LUIBase:New()
    setmetatable(o, PetArchiveFormationSubUI)
    o:Init()
    return o
end


function PetArchiveFormationSubUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/LineupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    --self:RegistMsgs()
    self:InitData()
    self:LoadPetList()

end

function PetArchiveFormationSubUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_descLabel = nil
    --神将阵容ListView
    self.m_petListView = nil
    if self.m_subPanel then
        self.m_subPanel:release()
        self.m_subPanel = nil
    end
end



function PetArchiveFormationSubUI:InitData()

    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("Lineup")
    --信息
    self.m_descLabel = panel:getChildByName("LineupTips")
    --神将阵容ListView
    self.m_petListView = panel:getChildByName("LineupList")
    self.m_subPanel = panel:getChildByName("Lineup1")
    self.m_subPanel:retain()
    self.m_subPanel:removeFromParent()
end

--加载总的列表
function PetArchiveFormationSubUI:LoadPetList()
    if self.m_petListView == nil then return end
 
    local roleInfo = LRoleDataMgr.MyHeroInfo
    if roleInfo == nil  then return end
    local professional = roleInfo:Getprofessional()
    local level = roleInfo:Getlevel()

    local pets = LDataConstMgr:GetPetFormationConfig(professional,level)
    if pets == nil then return end
    self.m_petListView:removeAllChildren()

    for k,v in pairs(pets) do
        local pet = self.m_subPanel:clone()   
        self:ShowItemList(pet,string.split(v.pets,","), v.name,v.desc,v.formation)
        self.m_petListView:pushBackCustomItem(pet)
    end
    self.m_descLabel:setString(Utils:JointString(GUITips.RSI_PET_MSG31,level,AppDef:GetProfNameBy5BaseIndex(professional)))
end

--加载一个阵容列表
function PetArchiveFormationSubUI:ShowItemList(parent,petIds,titleName,desc,zhenfaId)
    local listview = parent:getChildByName("IconList")
    listview:setTouchEnabled(false)

    for i = 1,4 do
        local item = listview:getChildByName("IconBg"..i)
        if item ~= nil then
            self:ShowItem(item,tonumber(petIds[i]))
        end
    end

    local titleLabel = parent:getChildByName("TitleBg"):getChildByName("Text")
    titleLabel:setString(titleName)
    local descLabel = parent:getChildByName("Tips")
    descLabel:setString(desc)

    local zhenfaInfo = LDataConstMgr:GetFormationDataById(zhenfaId)
    if zhenfaInfo == nil  then return end
    local zhenfaImage = parent:getChildByName("lineupIcon")
    zhenfaImage:ignoreContentAdaptWithSize(false)
    zhenfaImage:loadTexture("res2/Icon/ui_zhenfa_icon/zhenfa_"..zhenfaId..".png",ccui.TextureResType.localType)
    local zhenfaLabel = zhenfaImage:getChildByName("Text")
    zhenfaLabel:setString(zhenfaInfo.name)
end

--加载单个神将
function PetArchiveFormationSubUI:ShowItem(item,id)
    item:setVisible(true)
    item:setTouchEnabled(true)   
    item.userObject = id  
    local info = LPetDataMgr:FindPetDataById(tonumber(id))
    if info == nil then return end
    
    local iconPanel = item:getChildByName("Bg")
    local nameLabel = iconPanel:getChildByName("Name")
    nameLabel:setString(info.name)
    nameLabel:setTextColor(AppDef:GetPetQualityColor(info.quality))
    --icon
    local icon = iconPanel:getChildByName("Icon")
    Utils:ShowPetHeadImg(icon,info.pic,iconPanel,info.quality,info:IsShiny())
    --评分
    local scoreImage = iconPanel:getChildByName("Quality")
    AppDef:GetPetQualityScore(scoreImage,info.quality)
    --神将类型
    local typeImage = iconPanel:getChildByName("Career")
    AppDef:ShowPetType(typeImage,info.petType)
    --拥有标识
    local sign = iconPanel:getChildByName("Have")
    local signHave = LRoleDataMgr.Pet:GetPetById(id)
    if signHave ~= nil then
        sign:setVisible(true)
    else
        sign:setVisible(false)
    end

    local function ShowPetInfo(sender)--查看信息
        local id = sender.userObject
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    item:addClickEventListener(ShowPetInfo)
	self:MarkIntaractCObj(item)
end

return PetArchiveFormationSubUI
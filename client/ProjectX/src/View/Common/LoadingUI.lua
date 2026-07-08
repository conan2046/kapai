--Loading提示界面
local LoadingUI = LUIBase:New()
--local this = LTcpSocket

local ScriptPath = "Common.LoadingUI"
local CsbFilePath = "csd/Login/LoadingLayer.csb"
local NpcResPath = "res2/Monster_Bust/"
local BgResPath = "res/UI/ui_login/"
--local bg = {"res/UI/ui_login/bg.png","loading_1.jpg","loading_2.jpg"}

function LoadingUI:New()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self:Init()
    return o
end

function LoadingUI:Init()
    self:RegistMsgs()
    self:InitViewSize()
    self:InitData()
    self:HideLoadingUI()
end

function LoadingUI:InitData()
    local panel = self.m_pUILayer:getChildByName("LoadingUI")
    self.m_loadingBar = panel:getChildByName("LoadingBar")
	self.m_loadingBg = panel:getChildByName("bg")
    if Utils:isIOSPlatform() then
        self.m_loadingBar:setVisible(false)
        local barBg =  panel:getChildByName("bg_LoadingBar")
        barBg:setVisible(false)
        local textLabel = panel:getChildByName("Text")
        textLabel:setVisible(false)
    end
    self.m_petImage = panel:getChildByName("PetImage")
    local petInfoPanel = panel:getChildByName("ImageBg")
    self.m_petNameLabel = petInfoPanel:getChildByName("PetName")
    self.m_petQualityImg = petInfoPanel:getChildByName("Quality")
    local descPanel = petInfoPanel:getChildByName("Desc")
    for i=1,4 do
        self["m_desc"..i.."Label"] = descPanel:getChildByName("type_"..i):getChildByName("Text")
        self["m_desc"..i.."LabelParent"] = self["m_desc"..i.."Label"]:getParent()
    end
    for i=1,4 do
        self["m_attr"..i.."LoadingBar"] = petInfoPanel:getChildByName("Image_"..i):getChildByName("LoadingBar")
    end
    --self.m_tip1Label = panel:getChildByName("Text")
    --self.m_tip2Label = panel:getChildByName("Text_0")
end

function LoadingUI:RegistMsgs()
    self.msgIds = 
    {
        LUILoadingEvt.ShowLoading,
        LUILoadingEvt.HideLoading,
        LUILoadingEvt.ShowLoadingProcess,
        --LUILoadingEvt.ShowLoadingTips,
    }
    self:RegistSelf(self,self.msgIds)
end

function LoadingUI:ProcessEvent(msg)  

    if msg:GetMsgId() == LUILoadingEvt.ShowLoading then
        self:ShowLoadingUI()
    elseif msg:GetMsgId() == LUILoadingEvt.HideLoading then
        self:HideLoadingUI()
    elseif msg:GetMsgId() == LUILoadingEvt.ShowLoadingProcess then
        local rate = msg:GetRate()
        --print("GetRate ",rate)
        self:ShowProcess(rate)
        --self:ClearWaitAni()
    end
end

function LoadingUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end


function LoadingUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

function LoadingUI:ShowLoadingUI()

    local num = LDataConstMgr:GetLoadingCfgDataMaxNum()
    --随机背景资源
	local id = math.random(1,num)
    local cfgData = LDataConstMgr:GetLoadingCfgData(id)
    if cfgData == nil then return end
	self.m_loadingBg:loadTexture(BgResPath..cfgData.bgPic)		
    	
    self.m_pUILayer:setVisible(true)
    self.m_loadingBar:setPercent(0)

    for i=1,4 do
        local label = self["m_desc"..i.."Label"]
        local labelParent = self["m_desc"..i.."LabelParent"] 
        if i <= #cfgData.content then 
            label:setString(cfgData.content[i])
            labelParent:setVisible(true)
        else
            labelParent:setVisible(false)
        end
    end
    for i=1,4 do
        self["m_attr"..i.."LoadingBar"]:setPercent(cfgData.value[i])
    end

    self.m_petImage:loadTexture(NpcResPath..cfgData.iconPic..".png")		
    self.m_petNameLabel:setString(cfgData.name)
    AppDef:GetPetQualityScore(self.m_petQualityImg,cfgData.quality)
    
end

function LoadingUI:ShowProcess(rate)

    self.m_loadingBar:setPercent(rate)

end

function LoadingUI:HideLoadingUI()
    self.m_pUILayer:setVisible(false)
end 


return LoadingUI
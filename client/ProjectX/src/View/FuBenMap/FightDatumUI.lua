--战斗统计界面
local FightDatumUI = LUIBase:New()
FightDatumUI.__index = FightDatumUI

function FightDatumUI:New()
    local o = LUIBase:New()
    setmetatable(o,FightDatumUI) 
    o:Init()
    return o
end

function FightDatumUI:Init()
    self.Script = "FuBenMap.FightDatumUI"
    self:CreateUINode("csd/common/zhandoutongji.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/Xuezhanshuxingxuanze.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:initControlUI()
    --LRoleDataMgr:InitFightDatum()
    self:ShowInfo()
end

function FightDatumUI:InitData()
    self.m_roleNameLabel = {}
    self.m_winImgs = {}
    self.m_loseImgs = {}
end

function FightDatumUI:initControlUI()
    local panel = self.m_pUILayer:findChildByName("Panel/Panel_zhandoutongji")
    local namePanel = panel:getChildByName("Panel_title_2")
    for i=1,2 do
        local titlePanel = namePanel:getChildByName("Panel_"..i)
        self.m_roleNameLabel[i] = titlePanel:getChildByName("name")
        self.m_winImgs[i] = titlePanel:getChildByName("Panel_win")
        self.m_loseImgs[i] = titlePanel:getChildByName("Panel_lose")
    end
    self.m_listView = panel:getChildByName("ListView")
    self.m_cell = self.m_listView:getChildByName("ActivityList")
    self.m_cell:retain()
    self.m_cell:removeFromParent()

     --通用底框设置
    Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_FIGHT_TONGJI)
    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, FightDatumUI.RemoveUI))
end 

function FightDatumUI:ShowInfo()
    local data = LRoleDataMgr:GetFightDatum()
    if data == nil then
        return
    end
    self:ShowRoleName(data.Names)
    self:ShowWin()
    self:ShowPetList()
end

function FightDatumUI:ShowRoleName(names)
    if names == nil then
        return
    end
    for i = 1,2 do
        self.m_roleNameLabel[i]:setString(names[i])
    end
end

function FightDatumUI:ShowWin()
    for i = 1,2 do
        self.m_winImgs[i]:setVisible(false)
        self.m_loseImgs[i]:setVisible(false)
    end
    local data = LRoleDataMgr.m_fightResultData
    if data == nil or data.win == nil then
        return
    end
    if data.win then
        self.m_winImgs[1]:setVisible(true)
        self.m_loseImgs[1]:setVisible(false)
        self.m_winImgs[2]:setVisible(false)
        self.m_loseImgs[2]:setVisible(true)
    else
        self.m_winImgs[1]:setVisible(false)
        self.m_loseImgs[1]:setVisible(true)
        self.m_winImgs[2]:setVisible(true)
        self.m_loseImgs[2]:setVisible(false)
    end
end

function FightDatumUI:ShowPetList()
    local data = LRoleDataMgr:GetFightDatum()
    if data == nil or data.Units == nil then
        return
    end
    --self.m_listView:removeAllItems()
    local max = math.max(#data.Units[1],#data.Units[2])
    for i=1,max do
        local cell = self.m_cell:clone()
        self:ShowPetOne(cell:getChildByName("Panel_1"),data.Units[1][i])
        self:ShowPetOne(cell:getChildByName("Panel_2"),data.Units[2][i])
        self.m_listView:pushBackCustomItem(cell)
    end
end

function FightDatumUI:ShowPetOne(sender,data)
    --dump(data)
    if data == nil then
        sender:setVisible(false)
        return
    end
    local pic = 0
    if data.type == AppDef.BTConst.Type.Pet then
        cfg = JsonConfig.m_heroCfg.getDefByID(data.id)
        pic = cfg.pic
    elseif data.type == AppDef.BTConst.Type.Monster then
        pic = data.id
    end
    if pic == 0 then
        sender:setVisible(false)
        return
    end
    local qualityImg = sender:findChildByName("IconBg_1/Bg")
    local iconImg = qualityImg:getChildByName("Icon")
    local nameLabel = qualityImg:getChildByName("Name")
    local LoadingBars = {}
    local valLabels = {}
    for i=1,3 do
        local tmp = sender:getChildByName("Image"..i)
        LoadingBars[i] = tmp:getChildByName("EXPBar")
        valLabels[i] = tmp:getChildByName("txt2")
        valLabels[i]:setString(Utils:getPowerStr(data.value[i].curVal))    
        if data.value[i].maxVal == 0 then
            data.value[i].maxVal = 1
        end
        LoadingBars[i]:setPercent(data.value[i].curVal*100/data.value[i].maxVal)                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    end
    local str = AppDef.ColorKuangArr[data.quality]
    Utils:SafeLoadTexture(qualityImg,str,ccui.TextureResType.plistType)
    local imgPath = "res2/Monster_Bust/" ..pic.. "_tou.png"
    Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
    nameLabel:setString(data.name)
    nameLabel:setColor(AppDef:GetQualityColor(data.quality))
end

function FightDatumUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_roleNameLabel = nil
    self.Script  = nil
end

return FightDatumUI
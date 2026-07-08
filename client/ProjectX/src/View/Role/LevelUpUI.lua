--Loading提示界面
local LevelUpUI = LUIBase:New()
--local this = LTcpSocket

-- local ScriptPath = "Common.LevelUpUI"
local CsbFilePath = "csd/zhujue/zhujueshengji.csb"
local NpcResPath = "res2/Monster_Bust/"
local BgResPath = "res/UI/ui_login/"
--local bg = {"res/UI/ui_login/bg.png","loading_1.jpg","loading_2.jpg"}

function LevelUpUI:New()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self:Init()
    return o
end

function LevelUpUI:Init()
    self.Script = "Role.LevelUpUI"
    LRoleDataMgr.isShowLvUp = false;
    self._isShowAni = true;
    self:RegistMsgs()
    self:InitViewSize();
    self:ShowLvUp();
end

function LevelUpUI:ShowLvUp()
    local label = self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongxi/Num");
    label:setString(LRoleDataMgr.MyHeroInfo.level)
    local curTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili();
    self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili/Image_tili/Text2"):setString(curTili);

    local oldValue = curTili - LRoleDataMgr.lvUpAddTili;
    self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili/Image_tili/Text1"):setString(oldValue);

    -- if LRoleDataMgr.lvUpAddTili and LRoleDataMgr.lvUpAddTili > 0 then
    --     self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili"):setVisible(true);
    --     local addValue = 500 - LRoleDataMgr.lvUpAddTili;
    --     self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili/Image_tili/Text1"):setString(addValue);
    -- else
    --     self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili"):setVisible(true);
    --     local addValue = 500 - LRoleDataMgr.lvUpAddTili;
    --     self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili/Image_tili/Text1"):setString(addValue);
    -- end

    self:ShowOpenFunc();
end

function LevelUpUI:ShowOpenFunc()
    local myLv = LRoleDataMgr.MyHeroInfo.level;
    local functios = LDataConstMgr:GetFLDataByCondition(1);
    function sortFunc(a, b) 
        local infoA = LDataConstMgr:GetFunctionLevelData(a);
        local infoB = LDataConstMgr:GetFunctionLevelData(b);
        return infoA.open_condition[1][2] < infoB.open_condition[1][2]
    end 
    table.sort(functios, sortFunc)

    local maxLv = JsonConfig.m_config.getDefByID(19).value + myLv
    local nextFuncIdArr = {}
    for i = 1, #functios do
        local id = functios[i]
        local info = LDataConstMgr:GetFunctionLevelData(id)
        if info.level_show == 1 and info.open_condition[1][2] >= myLv and info.open_condition[1][2] <= maxLv then
            table.insert(nextFuncIdArr,id)
        end
        if #nextFuncIdArr == 3 then
            break
        end
    end

    local baseRes = "res2/Icon/ui_main_icon/"
    local cnt = 1;
    for i = 1, #nextFuncIdArr do
        local id = nextFuncIdArr[i]
        local info = LDataConstMgr:GetFunctionLevelData(id)
        local nameLabel = self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng/Panel_" .. i .. "/Text");
        nameLabel:setString(info.name);
        if string.len(info.icon) > 0 then
            local imgNode = self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng/Panel_" .. i .. "/Icon");
            local str = baseRes .. info.icon .. ".png";
            imgNode:loadTexture(str, UI_TEX_TYPE_LOCAL)
        end
        if info.open_condition[1][2] == myLv then
            --已开启
            self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng/Panel_" .. i .. "/Text_2"):setVisible(false);
        else
            --未开启
            self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng/Panel_" .. i .. "/Text_1"):setVisible(false);
            self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng/Panel_" .. i .. "/Text_2"):setString( "" .. info.open_condition[1][2] .. GUITips.UI_JiKaiqi);
        end
        cnt = cnt + 1;
    end
    for i = cnt, 3 do
        self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng/Panel_" .. i):setVisible(false);
    end
end

function LevelUpUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     LUILoadingEvt.ShowLoading,
    --     LUILoadingEvt.HideLoading,
    --     LUILoadingEvt.ShowLoadingProcess,
    --     --LUILoadingEvt.ShowLoadingTips,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

function LevelUpUI:ProcessEvent(msg)  
end

function LevelUpUI:InitViewSize()
    self:CreateUINode(CsbFilePath);
    local ani =  cc.CSLoader:createTimeline(CsbFilePath);
    self.m_pUILayer:runAction(ani)
    ani:gotoFrameAndPlay(0, false)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    ani:setAnimationEndCallFunc("animation0",handler(self,LevelUpUI.PlayEndCallback))


    self.m_pUILayer:getChildByName("Panel_shengji"):setTouchEnabled(false);
    self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongneng"):setTouchEnabled(false);
    self.m_pUILayer:findChildByName("Panel_shengji/Panel_tili"):setTouchEnabled(false);
    self.m_pUILayer:findChildByName("Panel_shengji/Panel_gongxi"):setTouchEnabled(false);

    local btn = self.m_pUILayer:getChildByName("Mask");
    local function onCloseClicked(sender)
        self:RemoveUI()
    end
    btn:addClickEventListener(onCloseClicked)
end

function LevelUpUI:PlayEndCallback()
    self._isShowAni = false;
end


function LevelUpUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    Utils:CheckLvGuide()
end

return LevelUpUI
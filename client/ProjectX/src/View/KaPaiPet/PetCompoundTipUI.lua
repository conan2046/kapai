--[[
宠物合成提示
]]
--Loading提示界面
local PetCompoundTipUI = LUIBase:New()
--local this = LTcpSocket

-- local ScriptPath = "Common.PetCompoundTipUI"
local CsbFilePath = "csd/common/hechengtixing.csb"

--local bg = {"res/UI/ui_login/bg.png","loading_1.jpg","loading_2.jpg"}

function PetCompoundTipUI:New(datas)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self:Init(datas)
    return o
end

function PetCompoundTipUI:Init(datas)
    self.Script = "KaPaiPet.PetCompoundTipUI"
    LRoleDataMgr.isShowLvUp = false;
    Utils:SendMsg(LUILogicEvent.DeleteUI,"Shop.JiangHunShop")
    self._isShowAni = true;
    self:RegistMsgs()
    self:InitViewSize();
    self:ShowTip(datas);
end

function PetCompoundTipUI:ShowTip(datas)
	local curNum = LRoleDataMgr.Equip:CountItemNumById(datas[1])
	local itemConf = JsonConfig.m_Item.getDefByID(datas[1])
	local str = string.format(GUITips.UI_Pet_SuiPianComp_Tips,curNum, itemConf.name);
	self.m_pUILayer:findChildByName("hechengtixing/Text"):setString(str);
    
end

function PetCompoundTipUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     LUILoadingEvt.ShowLoading,
    --     LUILoadingEvt.HideLoading,
    --     LUILoadingEvt.ShowLoadingProcess,
    --     --LUILoadingEvt.ShowLoadingTips,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

function PetCompoundTipUI:ProcessEvent(msg)  
end

function PetCompoundTipUI:InitViewSize()
    self:CreateUINode(CsbFilePath);
    -- local ani =  cc.CSLoader:createTimeline(CsbFilePath);
    -- self.m_pUILayer:runAction(ani)
    -- ani:gotoFrameAndPlay(0, false)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local btn = self.m_pUILayer:findChildByName("hechengtixing/Btn_Cancel");
    local function onCloseClicked(sender)
        self:RemoveUI()
    end
    btn:addClickEventListener(onCloseClicked)

    btn = self.m_pUILayer:findChildByName("hechengtixing/Btn_Confirm");
    local function onOkClicked(sender)
        self:RemoveUI()
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FRAGMENT_BAGS)
    end
    btn:addClickEventListener(onOkClicked)

    local checkBox = self.m_pUILayer:findChildByName("hechengtixing/CheckBox_1");

    local function tipClicked( sender )
        -- body
        LRoleDataMgr.m_isTipPetCompound = not sender:isSelected()
    end
    checkBox:addClickEventListener(tipClicked)
end

function PetCompoundTipUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    --Utils:CheckLvGuide()
end

return PetCompoundTipUI
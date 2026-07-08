--  ----------------------------------------------
-- 福利UI逻辑
local FirstAwardUI = LUIBase:New()
FirstAwardUI.__index = FirstAwardUI

--战斗中是否隐藏
FirstAwardUI.IsHideInBattle = true
-- ----------------------------------------------
-- 常量区
local ScriptPath = "FirstAward.FirstAwardUI"
local CsbFilePath = "csd/FirstRewardLayer.csb"
local ItemCsbFilePath = "csd/ItemIconLayer.csb"
local PlistFileName = "res/csd/Plist/ui_commonPlist"
local StarImageName = "res/UI/ui_common/ui_zuoqi_xing_0"


-- ----------------------------------------------
local _DEBUG = false
local function Debug(msg)
    if not _DEBUG then return end
end

-- ----------------------------------------------
local function _ShowImage(image , show)
    local show = show or false 
    image:setVisible(show)
end

-- ----------------------------------------------
local function _DrawTexture(image, texture, type)
    local type = type or ccui.TextureResType.localType
    image:loadTexture(texture, type)
end

-- ----------------------------------------------
local function _DrawText(text, str)
    if text == nil then
        return 
    end
    text:setString(str)
end

-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end

-- ----------------------------------------------
local function _BindClickFunctionToButton(object,btn,fuc)
    btn:addClickEventListener(fuc)
	object:MarkIntaractCObj(btn)
end

-- ----------------------------------------------
function FirstAwardUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o, FirstAwardUI)
    o:Init(userData)
    return o
end

-- ----------------------------------------------
function FirstAwardUI:RegistMsgs()
    self.msgIds = 
    {
        
    }
    self:RegistSelf(self, self.msgIds)
end

-- ----------------------------------------------
function FirstAwardUI:ProcessEvent(msg)

end

-- ----------------------------------------------
function FirstAwardUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.rpanel = nil
    self.lpanel = nil
end

-- ----------------------------------------------
function FirstAwardUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            Debug("onNodeEvent")
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    
    --LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    --self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- ----------------------------------------------
function FirstAwardUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    local RootPanel = self.m_pUILayer:getChildByName("Reward")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- ----------------------------------------------
local ITMENUM = 3
local tagid = 1886
function FirstAwardUI:InitUIControl()
    if not self.ui then self.ui = {} end 
    self.ui.items = {}
    -- =============================
    cc.SpriteFrameCache:getInstance():addSpriteFrames(PlistFileName..".plist", PlistFileName..".png")
    local itme_node  = cc.CSLoader:createNode(ItemCsbFilePath)
    if itme_node then 
        self.itme_node = itme_node
    end
    local reward_panel = self.m_pUILayer:getChildByName("Reward")

    self.tip_panel =  reward_panel:getChildByName("TipsText")
    self.class_text = self.tip_panel:getChildByName("AtlasLabel_1")
    self.confirm_btn = reward_panel:getChildByName("Btn_Confirm")
    self.confirm_btn_text = self.confirm_btn:getChildByName("Text")

    self.icon_panel = reward_panel:getChildByName("IconBg")
    self.itmelist = self.icon_panel:getChildByName("List")

    --标题
    self.title_panel = reward_panel:getChildByName("bg"):getChildByName("Title")
    self.title_text = self.title_panel:getChildByName("TitleBg"):getChildByName("Text")
    --星星
    self.star_panel = reward_panel:getChildByName("StarsList")
    self.star_images = {}
    for i=1,3 do
        self.star_images[i] = self.star_panel:getChildByName("Star"..i)
    end
    --文本-累计星数、经验
    self.text_panel = reward_panel:getChildByName("TextBg")
    self.star_text = self.text_panel:getChildByName("Text_1"):getChildByName("Value")
    self.exp_text = self.text_panel:getChildByName("Text_2"):getChildByName("Value")
end 

function FirstAwardUI:UpdateUI(userData)
    if userData == nil then return end
    self.m_activityId = userData[1]
    self.m_callback = userData[2]
    if self.m_activityId ~= nil and self.m_activityId == AppDef.EActivityID.EAID_BOSS then
        --每日Boss
        _ShowImage(self.tip_panel,false)
        _ShowImage(self.text_panel,false)
        _ShowImage(self.title_panel,true)
        _ShowImage(self.star_panel,true)
        _ShowImage(self.icon_panel,true)

        local result = LActivityManager:GetDailyBossResultData()
        --_DrawText(self.star_text,tostring(result.m_totalStarNum))
        --_DrawText(self.exp_text,tostring(result.m_battleExp1))
        local nodes = {}
		for i = 1, ITMENUM do 
			local name = "IconBtn"..i
			local node = self.itmelist:getChildByName(name)
			node:setVisible(false)
			if i == 1 then
				node:setVisible(true)
				local userDefine ={picFilePath = "item/equip3007.png", quality = 0, num = result.m_battleExp1}
				local itemValue = {}
				itemValue.userDefine = userDefine
				itemValue.isShowNum = true
				itemValue.isShowQualityBg = true
				ItemCellUI:New(node, itemValue)
                table.insert(nodes,node)
            elseif i== 2 then
                node:setVisible(true)
                Utils:GetItemCellValue(node, 0, result.m_itemId, true, true, result.m_itemNum)
                table.insert(nodes,node)
			end
		end
        Utils:AlignNodes(self.itmelist, nodes, {90,90,90}, 1, false)
        for i=1,3 do
            if i> result.m_battleStarNum then
                _DrawTexture(self.star_images[i],StarImageName.."2.png",ccui.TextureResType.plistType)
            else 
                _DrawTexture(self.star_images[i],StarImageName.."1.png",ccui.TextureResType.plistType)
            end
        end
        if result.m_battleStarNum == nil or result.m_battleStarNum < 1 then 
            result.m_battleStarNum = 1
        end
        if result.m_battleStarNum > 3 then
            result.m_battleStarNum = 3
        end
         _DrawText(self.title_text,GUITips["RSI_STAR_TIP"..result.m_battleStarNum]..GUITips.RSI_PASS)
         _DrawText(self.confirm_btn_text,GUITips.RSI_KNOW)
         _BindClickFunctionToButton(self,self.confirm_btn,self.m_callback)
    end
end

-- ----------------------------------------------
function FirstAwardUI:Init(userData)
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    self:UpdateUI(userData)
end

-- ----------------------------------------------
return FirstAwardUI
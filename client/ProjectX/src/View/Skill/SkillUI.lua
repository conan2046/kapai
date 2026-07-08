-- 技能ui逻辑

local SkillUI = LUIBase:New()
SkillUI.__index = SkillUI

-- -----------------------------------
-- 常量
local ScriptPath = "Skill.SkillUI"
local CsbFilePath = "csd/SkillLayer.csb"
local LvStr= " LV"
local SkillUiPath = "Skill/UI/"


-- ---------------------------------
local _DEBUG = false
local function Debug(msg)
    if not _DEBUG then return end
    
end


-- ---------------------------------
local function _CatSkillTextureFileName(id,name, ex)
    if id ~=nil then
        return  SkillUiPath..name..id..ex
    else
        return SkillUiPath..name..ex
    end
end

-- -----------------------------------
local function _ShowImage(image , show)
    local show = show or false 
    image:setVisible(show)
end

-- -----------------------------------
local function _DrawTexture(image, texture, type)
    local type = type or ccui.TextureResType.localType
    image:loadTexture(texture, type)
end

-- -----------------------------------
local function _DrawText(text, str)
    if text == nil then
        return 
    end
    text:setString(str)
end

-- -----------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	SkillUI:MarkIntaractCObj(btn)
end

-- -----------------------------------
function SkillUI:RegistMsgs()
    self.msgIds = 
    {
        LUISkillEvent.SkillNextDepInfo,
        LUISkillEvent.SkillUpGrade,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function SkillUI:ProcessEvent(msg)
    if msg.msgId == LUISkillEvent.SkillNextDepInfo then
        self:DrawSelectSkillUpgrageDepInfo(msg.value)
    end

    if msg.msgId == LUISkillEvent.SkillUpGrade then
        self:SkillUpGradeOneTime(msg.value)
        self:ShowMoneyQianneng()
        self:DrawSkillInfo()
        LRedDotCheckMgr:MainSkillCheck()
        self:SkillLevelUp()
    end
end

function SkillUI:SkillLevelUp()
    local function aniPlayEndCallback(sender)
        sender:removeFromParent()
    end
    local function showLvupAni(ind)
        local ani = ImodAnim:createWithFileSync("res2/fx/shengji_yuan")
        ani:registerScriptEndCBHandler(aniPlayEndCallback)
        ani:PlayAction(0)
        local btnSize = self.skill_infos[ind].icon:getContentSize()
        ani:setPosition(cc.p(btnSize.width/2,btnSize.height/2))
        self.skill_infos[ind].icon:addChild(ani)
    end

    for i = 1, #self.skill_infos do
        local info = self.skill_infos[i]
        local skill = LRoleDataMgr:GetSkillDetailById(info.skill.id)
        if skill  and self.rpanel.lvup[i]
            and self.rpanel.lvup[i] ~= skill.level then
            showLvupAni(i)
            self.rpanel.lvup[i] = skill.level
        end
        
    end
end

-- -----------------------------------
function SkillUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.rpanel = nil
    self.skill_infos = nil
    self.skillBtns = nil
end

-- -----------------------------------
function SkillUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function closeCallback()
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- -----------------------------------
function SkillUI:DrawWindowTitle()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_SKILL_TITLE)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- -----------------------------------
function SkillUI:Init()
    Debug("SkillUI:Init")
    self:RegistMsgs()
    self.InitSpriteFrames()
    self:InitViewSize()
    self:InitUIControl()

    local cur = 1
    for i=1,#self.skill_infos do
        local si = self.skill_infos[i].skill
        local skill = LRoleDataMgr:GetSkillDetailById(si.id)
        if skill ~= nil and Utils:CheckSkillLevelUp(i, skill.level, true) then
            cur = i
            break
        end
    end

    self:DrawSelectSkillDetailInfo(cur, true)
    self:DrawSkillInfo()
    self:BindButtonFunction()
    self:RegisterQuik()
    self:DrawWindowTitle()
    self:ShowMoneyQianneng()

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


-- -----------------------------------
function SkillUI:New()
    local o = LUIBase:New()
    setmetatable(o, SkillUI)
    o:Init()
    return o
end

-- -----------------------------------
local sprite_plist_path = "res/UI/csd/Plist/ui_juesePlist.plist"
local sprite_texture_path = "res/UI/csd/Plist/ui_juesePlist.png"
function SkillUI:InitSpriteFrames()
    
end

-- -----------------------------------
function SkillUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function SkillUI:InitUIControl()
    local rp = self.m_pUILayer:getChildByName("Panel")
    local rightpanel = rp:getChildByName("SkillDescribeBg")
    self.rpanel = {}
    
    local DT1 = rightpanel:getChildByName("DescribeTitle1")
    self.rpanel.namelv_text = DT1:getChildByName("TitleName")
    
    local DTDT1 = DT1:getChildByName("DescribeText")
    --self.rpanel.cur_describe_text = DTDT1:getChildByName("Name1"):getChildByName("Text")
    
    local descLabel = DTDT1:getChildByName("Name1"):getChildByName("Text")
    local fontSize = descLabel:getFontSize()
    local defalutColor = descLabel:getTextColor()
    local color = cc.c3b(defalutColor.r,defalutColor.g,defalutColor.b)
    self.rpanel.cur_describe_text = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width - 10,fontSize,color,false)
    self.rpanel.cur_describe_text:setPosition(descLabel:getPosition())
    DTDT1:getChildByName("Name1"):addChild(self.rpanel.cur_describe_text)
    descLabel:removeFromParent()


    --self.rpanel.next_describe_text = DTDT1:getChildByName("Name2"):getChildByName("Text")
    local descLabel = DTDT1:getChildByName("Name2"):getChildByName("Text")
    local fontSize = descLabel:getFontSize()
    local defalutColor = descLabel:getTextColor()
    local color = cc.c3b(defalutColor.r,defalutColor.g,defalutColor.b)
    self.rpanel.next_describe_text = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width - 10,fontSize,color,false)
    self.rpanel.next_describe_text:setPosition(descLabel:getPosition())
    DTDT1:getChildByName("Name2"):addChild(self.rpanel.next_describe_text)
    descLabel:removeFromParent()
    
    local DT2 = rightpanel:getChildByName("DescribeTitle2")
    local DTDT2 = DT2:getChildByName("DescribeText")
    self.rpanel.desTitle = DT2:getChildByName("TitleName")
    self.rpanel.player_lv_text = DTDT2:getChildByName("Name1"):getChildByName("Text")
    self.rpanel.oldColor = self.rpanel.player_lv_text:getTextColor()
    self.rpanel.redColor = cc.c4b(255,0,0,255)
    self.rpanel.develop_text = DTDT2:getChildByName("Name2"):getChildByName("Text")
    self.rpanel.money_text = DTDT2:getChildByName("Name3"):getChildByName("Text")

    self.rpanel.up_btn = rightpanel:getChildByName("SkillBtn1")                                   -- 技能升级按钮
    self.rpanel.upall_btn = rightpanel:getChildByName("SkillBtn2")                                -- 1键升级按钮
    self.rpanel.upRedDot = self.rpanel.up_btn:getChildByName("RedDot")
    self.rpanel.upallRedDot = self.rpanel.upall_btn:getChildByName("RedDot")
    local leftpanel = rp:getChildByName("SkillBg")
    self.skill_infos = {}

    self.rpanel.qianneng = rightpanel:getChildByName("QiannengBg"):getChildByName("Value")
    self.rpanel.money = rightpanel:getChildByName("CoinBg"):getChildByName("Value")
    local skillIds,skillNum = LSkillMgr:GetSkillInfo(LRoleDataMgr.MyHeroInfo.professional)
    if skillIds ~= nil then
        for k,v in pairs(skillIds) do
            local namestr = "SkillIconBg"..k
            local info = {}
            info.id = 0
            info.index = 0
            info.btn = leftpanel:getChildByName(namestr)
            info.icon = info.btn:getChildByName("SkillIcon")
            info.level = info.btn:getChildByName("Text")
            info.canUp = info.btn:getChildByName("UpImage")
            info.name = info.btn:getChildByName("SkillNameBg"):getChildByName("SkillName")
            info.lockicon = info.btn:getChildByName("CloseIcon")
            info.choose = info.btn:getChildByName("Choose")
            info.skill = LSkillMgr:getSkillById(v[1])
            info.skill.learnLevel = v[2]
            table.insert(self.skill_infos, info)
        end
    end
    self.rpanel.qiannengBg = rightpanel:getChildByName("QiannengBg")
    self.rpanel.moneyBg = rightpanel:getChildByName("CoinBg")
    self.rpanel.qiannengBtn = self.rpanel.qiannengBg:getChildByName("Button")
    self.rpanel.moneyBtn = self.rpanel.moneyBg:getChildByName("Button")
    self.rpanel.lvup = {}
end

function SkillUI:ShowMoneyQianneng()
    self.rpanel.money:setString(tostring(LRoleDataMgr.MyHeroInfo:GetDetailData().Money))
    self.rpanel.qianneng:setString(tostring(LRoleDataMgr.MyHeroInfo:GetDetailData().potential))
    if self.curskill and self.curskill.index then
        Utils:CheckSkillLevelUp(self.curskill.index, self.curskill.level, true)
    end
end

-- -----------------------------------
function SkillUI:SpawnButtonClickFunction(skillid, index)
    local f = function(sender)
        self:DrawSelectSkillDetailInfo(index)
    end
    return f
end

-- -----------------------------------
function SkillUI:BindButtonFunction()
    -- ----------------------
    -- 升级按钮
    local function OnUpButtonClick(sender)
		if self.m_pbuyGold == true then
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
			return
		end
        if not self.curskill then return end 
        if not self.curskill.index  then return end
        if not Utils:CheckSkillLevelUp(self.curskill.index, self.curskill.level) then
            return
        end
		if self.curskill and self.curskill.index then
			local result = Utils:CheckSkillLevelUp(self.curskill.index, self.curskill.level, false)
			if result == false then return end
		end
        self.rpanel.lvup[self.curskill.index] = self.curskill.level
        --dump(self.rpanel.lvup)
        LuaNetSendMsg:ReqSendLevelUpSkill(self.curskill.id, self.curskill.index)
    end
    _BindClickFunctionToButton(self.rpanel.up_btn, OnUpButtonClick)

    -- ----------------------
    -- 1键升级
    local function OnUpAllButtonClick(sender)
		local can_money = false
		local can_upall = false
        for i = 1, #self.skill_infos do
            local info = self.skill_infos[i]
            local skill = LRoleDataMgr:GetSkillDetailById(info.skill.id)
            if skill ~= nil then
                local lvUp = LDataConstMgr:GetSkillLvUpCost(i, skill.level)
                local cost = lvUp.cost[1]
                if lvUp.learn_level <= LRoleDataMgr.MyHeroInfo.level then
                    can_upall = true
                    if cost[2] <= LRoleDataMgr.MyHeroInfo:GetDetailData().Money then
                        can_money = true
                    end
                end
                self.rpanel.lvup[i] = skill.level
            end
        end
		if can_upall == true and can_money == false then
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
			return
		end
        --[[
        成功失败服务器给提示
        ]]
		if self.curskill == nil then
			return
		end	
        LuaNetSendMsg:ReqSendYiJianLevelUpSkill(self.curskill.id, self.curskill.index)
    end
    _BindClickFunctionToButton(self.rpanel.upall_btn, OnUpAllButtonClick)

    for key,value in pairs(self.skill_infos) do
        if value.skill.id ~= 0 then
            local fc = self:SpawnButtonClickFunction(value.skill.id, key)
            _BindClickFunctionToButton(self.skill_infos[key].btn, fc)
        end
    end
    
    local function AddQianneng(sender)
        Utils:OpenFunction(AppDef.EActivityID.EMID_QIANNENGCOPY)
    end
    _BindClickFunctionToButton(self.rpanel.qiannengBtn, AddQianneng)
    

    local function AddMoney(sender)
        Utils:OpenFunction(AppDef.EActivityID.EAID_SHAKEMONEYTREE)
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.MoneyTreeMainUI",AppDef.UIType.FirstClassLayer)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    end
    _BindClickFunctionToButton(self.rpanel.moneyBtn, AddMoney)
end

-- -----------------------------------
function SkillUI:SetCurSelectSkill(index)
    if  self.curskill == nil then  self.curskill = {} end
    self.curskill.id = self.skill_infos[index].id
    self.curskill.index = self.skill_infos[index].index

end

-- -----------------------------------
function SkillUI:DrawSelectSkillDetailInfo(index, init)
    local show = false
    for i=1,#self.skill_infos do
        local si = self.skill_infos[i].skill
        local skill = LRoleDataMgr:GetSkillDetailById(si.id)
        if skill ~= nil and Utils:CheckSkillLevelUp(i, skill.level, true) then
            show = true
            break
        end
    end
    if self.skill_infos[index] == nil then
        return
    end
    local si = self.skill_infos[index].skill
    local skill = LRoleDataMgr:GetSkillDetailById(si.id)
    if skill ~= nil then
        self:ShowUnLockSkill(skill, index)
        if  self.curskill == nil then  self.curskill = {} end
        self.curskill.id = si.id
        self.curskill.index = index
        self.curskill.level = skill.level
    else
        self:ShowLockSkill(si)
    end
    if self.oldSelect ~= nil then
        self.skill_infos[self.oldSelect].choose:setVisible(false)
    end
    self.oldSelect = index
    self.skill_infos[self.oldSelect].choose:setVisible(true)
    self.rpanel.upallRedDot:setVisible(show)
end

--[[
显示已经解锁信息
]]
function SkillUI:ShowUnLockSkill(skill, index)
    _DrawText(self.rpanel.namelv_text, skill.name..LvStr..skill.level)
    local cur_describe_text =  LDataConstMgr:GetHeroSkillDesc(skill.id, skill.level)    
    _DrawText(self.rpanel.cur_describe_text, cur_describe_text)
    local next_describe_text =  LDataConstMgr:GetHeroSkillDesc(skill.id, skill.level + 1)    
    _DrawText(self.rpanel.next_describe_text, next_describe_text)
    if init then
        self:QueryNextSkillDep(skill.id, skill.level + 1)
    end
    self.rpanel.develop_text:getParent():setVisible(false)
    self.rpanel.money_text:getParent():setVisible(true)
    _DrawText(self.rpanel.desTitle, GUITips.Rsi_Level_Up_Condition)
    self.rpanel.up_btn:setVisible(true)
    self.rpanel.upall_btn:setVisible(true)

    local lvUp = LDataConstMgr:GetSkillLvUpCost(index, skill.level)
    if lvUp == nil then
        _DrawText(self.rpanel.player_lv_text, GUITips.RSI_Skill_Level_Tips_Null)
        _DrawText(self.rpanel.money_text, GUITips.RSI_Skill_Level_Tips_Null)
        --_DrawText(self.rpanel.develop_text, GUITips.RSI_Skill_Level_Tips_Null)
        _DrawText(self.rpanel.next_describe_text, GUITips.RSI_Skill_Level_Tips_Full)
        self.rpanel.up_btn:setVisible(false)
        self.rpanel.upall_btn:setVisible(false)
        self.rpanel.qiannengBg:setVisible(false)
        self.rpanel.moneyBg:setVisible(false)
        -- self.skill_infos[index].canUp:setVisible(false)
    else
        if lvUp.learn_level > LRoleDataMgr.MyHeroInfo.level then
            self.rpanel.player_lv_text:setTextColor(self.rpanel.redColor)
        else
            self.rpanel.player_lv_text:setTextColor(self.rpanel.oldColor)
        end
        _DrawText(self.rpanel.player_lv_text, lvUp.learn_level)
		self.m_pbuyGold = false
        for k,v in pairs(lvUp.cost) do
            if v[1] == AppDef.AwrdItem.AWRD_ITEM_COIN then
				if v[1] == AppDef.AwrdItem.AWRD_ITEM_COIN then
					if v[2] > LRoleDataMgr.MyHeroInfo:GetDetailData().Money then
						self.m_pbuyGold = true
					end
				end
                _DrawText(self.rpanel.money_text, v[2])
            -- elseif v[1] == AppDef.AwrdItem.AWRD_ITEM_POTEN then
            --     _DrawText(self.rpanel.develop_text, v[2])
            end
        end

        local show = Utils:CheckSkillLevelUp(index, skill.level, true)
        self.rpanel.upRedDot:setVisible(show)
        self.rpanel.qiannengBg:setVisible(false)
        self.rpanel.moneyBg:setVisible(true)
    end
end

--[[
显示未解锁信息
]]
function SkillUI:ShowLockSkill(skill)
    _DrawText(self.rpanel.namelv_text, skill.name)
    local cur_describe_text =  LDataConstMgr:GetHeroSkillDesc(skill.id, 1)    
    _DrawText(self.rpanel.cur_describe_text, cur_describe_text)
    local next_describe_text =  LDataConstMgr:GetHeroSkillDesc(skill.id, 2)    
    _DrawText(self.rpanel.next_describe_text, next_describe_text)
    self.rpanel.develop_text:getParent():setVisible(false)
    self.rpanel.money_text:getParent():setVisible(false)
    _DrawText(self.rpanel.desTitle, GUITips.Rsi_Learn_Condition)
    self.rpanel.player_lv_text:setTextColor(self.rpanel.redColor)
    _DrawText(self.rpanel.player_lv_text, skill.learnLevel)
    self.rpanel.up_btn:setVisible(false)
    self.rpanel.upall_btn:setVisible(false)
    self.rpanel.qiannengBg:setVisible(false)
    self.rpanel.moneyBg:setVisible(false)
end

-- -----------------------------------
function SkillUI:DrawSelectSkillUpgrageDepInfo(info)
    _DrawText(self.rpanel.develop_text, info.develop)
	if info.money > LRoleDataMgr.MyHeroInfo:GetDetailData().Money then
		self.m_pbuyGold = true
	end
    _DrawText(self.rpanel.money_text, info.money)
end

-- -----------------------------------
function SkillUI:SkillUpGradeOneTime(res)
    if self.curskill ~= nil then
        local sucess = res.sucess
        local errmsg = res.errmsg
        if sucess > 0  then
            self:DrawSelectSkillDetailInfo(self.curskill.index)
        end
    end
    -- LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errmsg)
    -- self:SendMsg(LGameMsg.m_scrollTipsMsg)

end
-- -----------------------------------
function SkillUI:DrawSkillInfo()
    for i = 1, #self.skill_infos do
        local info = self.skill_infos[i]
        local skill = LRoleDataMgr:GetSkillDetailById(info.skill.id)
        local imagefile = _CatSkillTextureFileName(info.skill.id, "skill_", ".png")
        _DrawTexture(info.icon, imagefile, nil)
        if skill == nil then
            info.level:setVisible(false)
            _DrawText(info.name, tostring(info.skill.learnLevel)..GUITips.UI_JiKaiqi)
            info.canUp:setVisible(false)
        else
            info.level:setVisible(true)
            _DrawText(info.level, tostring(skill.level))
            _DrawText(info.name, info.skill.name)

            local show = Utils:CheckSkillLevelUp(i, skill.level, true)
            info.canUp:setVisible(show)
        end
        _ShowImage(info.lockicon, skill==nil)
    end

end

-- -----------------------------------
function SkillUI:QueryNextSkillDep(id, lv)
    Debug("QueryNextSkillDep skill id "..id.." skill lv "..lv)
    LuaNetSendMsg:QueryNextSkillDep(id, lv)
end

-- -----------------------------------
return SkillUI
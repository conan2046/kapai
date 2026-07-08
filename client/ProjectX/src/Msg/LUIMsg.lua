--[[
UI消息类集合
]]


--[[
UI初始化的消息
]]
LUIInitMsg = LMsgBase:New()
LUIInitMsg.__index = LUIInitMsg
function LUIInitMsg:New(msgid, luaScript,uitype)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIInitMsg)
    o.m_pScript = luaScript
    o.m_uiType = uitype
    o.userData = nil
    return o
end

function LUIInitMsg:Change(luaScript, uitype, userData)
    self.m_pScript = luaScript
    self.m_uiType = uitype
    self.userData = userData
    --print("LUIInitMsg:Change",luaScript,uitype)
end

function LUIInitMsg:ChangeWithMsgId(msgid, luaScript,uitype,userData)
    self.msgId = msgid
    self.m_pScript = luaScript
    self.m_uiType = uitype
    self.userData = userData
end

--[[
上浮提示的UI消息
]]
LUIScrollTipsMsg = LMsgBase:New()
LUIScrollTipsMsg.__index = LUIScrollTipsMsg
--[[
tipsArr是数组
]]
function LUIScrollTipsMsg:New(msgid, tipsArr)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIScrollTipsMsg)
    o.m_strTips = tips
    return o
end

function LUIScrollTipsMsg:Change(tipsArr)
    self.m_strTips = tips
end

function LUIScrollTipsMsg:ChangeWithMsgId(msgid, tipsArr)
     self.msgId = msgid
    self.m_strTips = tipsArr
end

--[[
通用带一个参数的消息
]]
LUIMsg1 = LMsgBase:New()
LUIMsg1.__index = LUIMsg1
function LUIMsg1:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIMsg1)
    return o
end

function LUIMsg1:Change(msgid,value)
    self.msgId = msgid
    self.value = value
end

--[[
通用带两个参数的消息
]]
LUIMsgTwo = LMsgBase:New()
LUIMsgTwo.__index = LUIMsgTwo
function LUIMsgTwo:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIMsgTwo)
    return o
end

function LUIMsgTwo:Change(msgid,v1, v2)
    --print("LUIMsgTwo:Change:",v1,v2)
    self.msgId = msgid
    self.value1 = v1
    self.value2 = v2
end



--[[
走马灯
]]
 LUIFloatNoticeMsg = LMsgBase:New()
 LUIFloatNoticeMsg.__index = LUIFloatNoticeMsg
 function LUIFloatNoticeMsg:New(msgid, tipsArr)
     local o = LMsgBase:New(msgid)
     setmetatable(o,LUIFloatNoticeMsg)
     o.m_strTips = tipsArr
     return o
 end

function LUIFloatNoticeMsg:Change(tipsArr)
    self.m_strTips = tipsArr
end

function LUIFloatNoticeMsg:ChangeWithMsgId(msgid, tipsArr)
    self.msgId = msgid
    self.m_strTips = tipsArr
end


--[[
loadingprogress
]]
 LUILoadingProgressMsg = LMsgBase:New()
 LUILoadingProgressMsg.__index = LUILoadingProgressMsg
 function LUILoadingProgressMsg:New(msgid, rate)
     local o = LMsgBase:New(msgid)
     setmetatable(o,LUILoadingProgressMsg)
     o.m_Rate = rate
     return o
 end

function LUILoadingProgressMsg:Change(rate)
    self.m_Rate = rate
end

function LUILoadingProgressMsg:ChangeWithMsgId(msgid, rate)
    self.msgId = msgid
    self.m_Rate = rate
end

function LUILoadingProgressMsg:GetRate()
	return self.m_Rate;
end

-- --[[
-- 个人竞技场消息
-- ]]
-- LUIPersonalJingjiMsg = LMsgBase:New()
-- LUIPersonalJingjiMsg.__index = LUIPersonalJingjiMsg
-- function LUIPersonalJingjiMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIPersonalJingjiMsg)
--     return o
-- end

-- function LUIPersonalJingjiMsg:Change(message)
--     print("change personaljingji ===================")
--     self.m_jingjimsg = message
-- end






-- --[[
-- 头像删除的消息
-- ]]
-- LUIHeadUIDeleteMsg = LMsgBase:New()
-- LUIHeadUIDeleteMsg.__index = LUIHeadUIDeleteMsg
-- function LUIHeadUIDeleteMsg:New(msgid, parent)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIHeadUIDeleteMsg)
--     o.m_headParent = parent
--     return o
-- end

-- function LUIHeadUIDeleteMsg:Change(msgid, parent)
--     self.msgId = msgid;
--     self.m_headParent = parent
-- end

-- function LUIHeadUIDeleteMsg:Reset()
--     self.m_headParent = nil
-- end

-- --[[
-- messageBox删除的消息
-- ]]
-- LUIMessageBoxUIDeleteMsg = LMsgBase:New()
-- LUIMessageBoxUIDeleteMsg.__index = LUIMessageBoxUIDeleteMsg
-- function LUIMessageBoxUIDeleteMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIMessageBoxUIDeleteMsg)
--     return o
-- end

-- function LUIMessageBoxUIDeleteMsg:Change(parent)
--     self.m_headParent = parent
-- end

-- function LUIMessageBoxUIDeleteMsg:Reset()
--     self.m_headParent = nil
-- end


-- --[[
-- 技能头像删除的消息
-- ]]
-- LUISkillUIDeleteMsg = LMsgBase:New()
-- LUISkillUIDeleteMsg.__index = LUISkillUIDeleteMsg
-- function LUISkillUIDeleteMsg:New(msgid,sKillObject)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUISkillUIDeleteMsg)
--     o.m_skillObject = sKillObject
--     return o
-- end

-- function LUISkillUIDeleteMsg:Change(sKillObject)
--     self.m_skillObject = sKillObject
-- end

-- --[[
-- UI头像删除的消息
-- ]]
-- LUICommonUIDeleteMsg = LMsgBase:New()
-- LUICommonUIDeleteMsg.__index = LUICommonUIDeleteMsg
-- function LUICommonUIDeleteMsg:New(msgid,uiobject)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUICommonUIDeleteMsg)
--     o.m_uiobject = uiobject
--     return o
-- end

-- function LUICommonUIDeleteMsg:Change(uiobject)
--     self.m_uiobject = uiobject
-- end

-- --[[
-- 增加聊天信息
-- ]]
-- LUIRecvChatMsg = LMsgBase:New()
-- LUIRecvChatMsg.__index = LUIRecvChatMsg
-- function LUIRecvChatMsg:New(msgid,message)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIRecvChatMsg)
--     o.m_chatDataMessage = message
--     return o
-- end

-- function LUIRecvChatMsg:Change(msgid, message)
--     self.msgId = msgid
--     self.m_chatDataMessage = message
-- end

-- --[[
-- 角色界面信息
-- ]]
-- LUIRoleVUpdateAllMsg = LMsgBase:New()
-- LUIRoleVUpdateAllMsg.__index = LUIRoleVUpdateAllMsg
-- function LUIRoleVUpdateAllMsg:New(msgid,message)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIRoleVUpdateAllMsg)
--     o.m_RoleInfoViewMessage = message
--     return o
-- end

-- function LUIRoleVUpdateAllMsg:Change(message)
--     self.m_RoleInfoViewMessage = message
-- end

-- LUIRoleVUpdateLifeSkillMsg = LMsgBase:New()
-- LUIRoleVUpdateLifeSkillMsg.__index = LUIRoleVUpdateLifeSkillMsg
-- function LUIRoleVUpdateLifeSkillMsg:New(msgid,message)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIRoleVUpdateLifeSkillMsg)
--     o.m_RoleInfoViewMessage = message
--     return o
-- end

-- function LUIRoleVUpdateLifeSkillMsg:Change(message,data)
--     self.m_data = data
--     self.LUIRoleVUpdateLifeSkillMsg = message
-- end

-- LUIRoleVUpdateAddAttrMsg = LMsgBase:New()
-- LUIRoleVUpdateAddAttrMsg.__index = LUIRoleVUpdateAddAttrMsg
-- function LUIRoleVUpdateAddAttrMsg:New(msgid,message)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIRoleVUpdateAddAttrMsg)
--     o.m_RoleInfoViewMessage = message
--     return o
-- end

-- function LUIRoleVUpdateAddAttrMsg:Change(message)
--     self.m_RoleInfoViewMessage = message
-- end

-- LUIRoleVUpdateSkillMsg = LMsgBase:New()
-- LUIRoleVUpdateSkillMsg.__index = LUIRoleVUpdateSkillMsg
-- function LUIRoleVUpdateSkillMsg:New(msgid,message)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIRoleVUpdateSkillMsg)
--     o.m_RoleInfoViewMessage = message
--     return o
-- end

-- function LUIRoleVUpdateSkillMsg:Change(message)
--     self.m_RoleInfoViewMessage = message
-- end

-- LUIMainViewUIMsg = LMsgBase:New()
-- LUIMainViewUIMsg.__index = LUIMainViewUIMsg
-- function LUIMainViewUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIMainViewUIMsg)
--     return o
-- end

-- function LUIMainViewUIMsg:Change(msg,data,data1)
--     self.msgId = msg
--     self.m_data = data
--     self.m_data1 = data1
-- end

-- --itme 消息发送
-- LUIItemUIMsg = LMsgBase:New()
-- LUIItemUIMsg.__index = LUIItemUIMsg
-- function LUIItemUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIItemUIMsg)
--     return o
-- end

-- function LUIItemUIMsg:Change(msgid,nameKey,clickFun,itemData)
--     self.msgId = msgid
--     self.nameKey = nameKey
--     self.itemData = itemData
--     self.clickFun = clickFun
--     self.newNameKey = nil
-- end

-- function LUIItemUIMsg:ChangeID(msgid,nameKey,newNameKey)
--     self.msgId = msgid
--     self.nameKey = nameKey
--     self.newNameKey = newNameKey
-- end

-- --背包消息发送
-- LUIPackViewUIMsg = LMsgBase:New()
-- LUIPackViewUIMsg.__index = LUIPackViewUIMsg
-- function LUIPackViewUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIPackViewUIMsg)
--     return o
-- end

-- function LUIPackViewUIMsg:Change(msgid,pos,itemData)
--     self.msgId = msgid
--     self.pos = pos
--     self.itemData = itemData
-- end

-- --帮派消息发送
-- LUIBangPaiUIMsg = LMsgBase:New()
-- LUIBangPaiUIMsg.__index = LUIBangPaiUIMsg
-- function LUIBangPaiUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIBangPaiUIMsg)
--     return o
-- end

-- function LUIBangPaiUIMsg:Change(msgid,data,data1)
--     self.msgId = msgid
--     self.data = data
--     self.data1 = data1
-- end

-- --ItemTipsUI
-- LUIItemTipsUIMsg = LMsgBase:New()
-- LUIItemTipsUIMsg.__index = LUIItemTipsUIMsg
-- function LUIItemTipsUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIItemTipsUIMsg)
--     return o
-- end

-- --修改显示Item
-- function LUIItemTipsUIMsg:Change(item,IsShowBtn,position,showType)
--     self.item = item
--     self.IsShowBtn = IsShowBtn
--     self.position = position
--     self.showType = showType
-- end

-- --背包换装消息发送
-- LUIPackFashionViewUIMsg = LMsgBase:New()
-- LUIPackFashionViewUIMsg.__index = LUIPackFashionViewUIMsg
-- function LUIPackFashionViewUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIPackFashionViewUIMsg)
--     return o
-- end

-- function LUIPackFashionViewUIMsg:Change(fashionData)
--     self.fashionData = fashionData
-- end

-- --活动消息发送
-- LUIActivityUIMsg = LMsgBase:New()
-- LUIActivityUIMsg.__index = LUIActivityUIMsg
-- function LUIActivityUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIActivityUIMsg)
--     return o
-- end

-- function LUIActivityUIMsg:Change(msgid)
--     self.msgId = msgid
-- end

-- LUIActivityUpdateUIMsg = LMsgBase:New()
-- LUIActivityUpdateUIMsg.__index = LUIActivityUpdateUIMsg
-- function LUIActivityUpdateUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIActivityUpdateUIMsg)
--     return o
-- end

-- function LUIActivityUpdateUIMsg:Change(msgid,actData)
--     self.msgId = msgid
--     self.m_ActData = actData
-- end

-- LUIBattleUIMsg = LMsgBase:New()
-- LUIBattleUIMsg.__index = LUIBattleUIMsg
-- function LUIBattleUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIBattleUIMsg)
--     return o
-- end

-- function LUIBattleUIMsg:Change(msgid,data)
--     self.msgId = msgid
--     self.m_data = data
-- end

-- --显示帮助提示，只有标准配表生效
-- LUIHelpTipsUIMsg = LMsgBase:New()
-- LUIHelpTipsUIMsg.__index = LUIHelpTipsUIMsg
-- function LUIHelpTipsUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIHelpTipsUIMsg)
--     return o
-- end

-- --修改显示Item
-- function LUIHelpTipsUIMsg:Change(title,desc)
--     self.m_sTitle = title
--     self.m_sDesc = desc
-- end

-- --好友信息更新
-- LUIFriendsUIMsg = LMsgBase:New()
-- LUIFriendsUIMsg.__index = LUIFriendsUIMsg
-- function LUIFriendsUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIFriendsUIMsg)
--     return o
-- end

-- function LUIFriendsUIMsg:Change(msgid,List)
--     self.msgId = msgid
--     self.m_List = List
-- end
-- --
-- LUIPlayerOperationMsg = LMsgBase:New()
-- LUIPlayerOperationMsg.__index = LUIPlayerOperationMsg
-- function LUIPlayerOperationMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIPlayerOperationMsg)
--     return o
-- end

-- function LUIPlayerOperationMsg:Change(PlayerData)
--     self.m_PlayerData = PlayerData
-- end
-- --通用面板信息更新
-- LUICommonMenuUIMsg = LMsgBase:New()
-- LUICommonMenuUIMsg.__index = LUICommonMenuUIMsg
-- function LUICommonMenuUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUICommonMenuUIMsg)
--     return o
-- end

-- function LUICommonMenuUIMsg:Change(msgid,data)
--     self.msgId = msgid
--     self.m_data = data
-- end

-- --对话界面消息
-- LUIDialogUIMsg = LMsgBase:New()
-- LUIDialogUIMsg.__index = LUIDialogUIMsg
-- function LUIDialogUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIDialogUIMsg)
--     return o
-- end

-- function LUIDialogUIMsg:Change(msgid,bgId,soundId,dialog,npcDatas)
--     self.msgId = msgid
--     self.m_bgId = bgId
--     self.m_soundId = soundId
--     self.m_dialog = dialog
--     self.m_npcDatas = npcDatas
-- end

-- --宠物面板信息更新
-- LUIPetMainUIMsg = LMsgBase:New()
-- LUIPetMainUIMsg.__index = LUIPetMainUIMsg
-- function LUIPetMainUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIPetMainUIMsg)
--     return o
-- end

-- function LUIPetMainUIMsg:Change(msgid,data,data1,data2)
--     self.msgId = msgid
--     self.m_data = data
--     self.m_data1 = data1
--     self.m_data2 = data2
-- end

-- --[[
-- 道具选择界面初始化消息
-- ]]
-- LUIItemChoiceUIMsg = LMsgBase:New()
-- LUIItemChoiceUIMsg.__index = LUIItemChoiceUIMsg
-- function LUIItemChoiceUIMsg:New(msgid)
--     local o = LMsgBase:New(msgid)
--     setmetatable(o,LUIItemChoiceUIMsg)
--     return o
-- end

-- function LUIItemChoiceUIMsg:Change(msgid,itemTable,func,position,panelType,titleText)
--     self.msgId = msgid
--     self.itemTable = itemTable
--     self.position = position
--     self.panelType = panelType
--     self.titleText = titleText
--     self.callback = func
-- end


LUIEquipUI = LMsgBase:New()
LUIEquipUI.__index = LUIEquipUI
function LUIEquipUI:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIEquipUI)
    return o
end

function LUIEquipUI:Change(msgid,item)
    self.msgId = msgid
    self.m_Item = item
end

--转移更新
function LUIEquipUI:ChangeZY(msgid,item,item1)
    self.msgId = msgid
    self.m_Item = item
    self.m_Item1 = item1
end

--更新左边列表
function LUIEquipUI:ChangeLB(msgid,leftBtnData)
    self.msgId = msgid
    self.m_LeftBtnData = leftBtnData
end

--[[
聊天消息插入
]]
LUIChatInputMsg = LMsgBase:New()
LUIChatInputMsg.__index = LUIChatInputMsg
function LUIChatInputMsg:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIChatInputMsg)
    o.type = nil--插入类型（0普通1表情2背包道具3已装备道具4宠物）
    o.value = nil--消息值，0就是普通字符串，不等于0就是下标
    return o
end

function LUIChatInputMsg:Change(msgid,type,value)
    self.msgId = msgid
    self.type = type
    self.value = value
 
end

--[[
    商城信息
]]
LUIMallMsg = LMsgBase:New()
LUIMallMsg.__index = LUIMallMsg
function LUIMallMsg:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LUIMallMsg)
    return o
end

function LUIMallMsg:Change(msgid,data)
    self.msgId = msgid
    self.data = data
end

function LUIMallMsg:ChangeSellPrice(msgid,id,price)
    self.msgId = msgid
    self.m_itemId = id
    self.m_price = price
 end

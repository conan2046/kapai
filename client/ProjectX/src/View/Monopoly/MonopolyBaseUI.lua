
local MonopolyBaseUI = LUIBase:New()
MonopolyBaseUI.__index = MonopolyBaseUI

local Node_Offset_x = 5
local Node_Offset_y = 10

local TAGFINALVALUE = 2018

function MonopolyBaseUI:New()
	local o = LUIBase:New()
	setmetatable(o,MonopolyBaseUI)	
    o:Init()
	return o
end


function MonopolyBaseUI:Init()
    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_chuangguanPlist.plist","csd/Plist/ui_chuangguanPlist.png")
    self.m_pUILayer = cc.CSLoader:createNode("csd/kunlunxunbao/GameSceneLayer.csb")
    local layerSize = self.m_pUILayer:getContentSize()
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local CC_WINSIZE = AppDef.Director:getWinSize()
--    --print("CC_WINSIZE *******", CC_WINSIZE.width, CC_WINSIZE.height, layerSize.width, layerSize.height)
    self._VIEW_RIGHT = -layerSize.width + CC_WINSIZE.width        --右边边界
    self._VIEW_TOP = -layerSize.height + CC_WINSIZE.height       --上边边界
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
   
   self:RegistMsgs()
   self._initIndex = 0; --异步加载资源数量
   self._curPosIndex = 1 --当前位置索引
   self._lastWidth = 0;  --上次图片的宽度，用于加载地图
   self._lastHeight = 0; --上次图片的高度，用于加载地图
   self._NodePosArr = {} --所有格子坐标
   self:asynLoadTexture(); --异步加载资源
   self._isMoveing = false --角色是否在移动
   --停止自动寻路
   LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
   self:SendMsg(LGameMsg.m_cBaseMsg)
end


function MonopolyBaseUI:onExit()
    AppDef.spriteFrameCache:removeSpriteFramesFromFile("csd/Plist/ui_chuangguanPlist.plist")
    self.m_pUILayer = nil
    self._initIndex = nil
    self._curPosIndex = nil
    self._lastWidth = nil
    self._lastHeight = nil
    self._isMoveing = nil
    self._panel = nil
    self._touchBeginPos = nil
    self._touchMovePos = nil
    self.m_pRoleModel = nil
    Utils:FreeTable(self._NodePosArr)
    Utils:FreeTable(self._textureArr)
    LRoleDataMgr.MonopolyData.isMonopolyState = false
    self:Destory()
end

--[[
注册消息
]]
function MonopolyBaseUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMonopolyEvent.RoleMove,
        LUIMonopolyEvent.updateMoveOverUI, --角色移动完毕，更新界面
        LUIMonopolyEvent.updateMonopoly,   --得到数据后，更新数据
        LUIMonopolyEvent.showBattleChatLayer,    --展示对话界面
        LUIMonopolyEvent.updateAwardUIIcon,  --得到奖励后，更新数据
        LUIMonopolyEvent.updateBattleUIIcon, --战斗结束后，隐藏人物
        LUIMonopolyEvent.ResetRolePos,       --还原位置
        LUIMonopolyEvent.justShowBattleChatLayer, --显示战斗对话界面
        LUIMonopolyEvent.monopolyChatDialog, --对话框事件
        LUIKunLunEvent.GetRobotZhenFaInfo,
    }
    self:RegistSelf(self,self.msgIds)
end


function MonopolyBaseUI:ProcessEvent(msg)

--人物移动
    if msg.msgId == LUIMonopolyEvent.RoleMove then
        self:roleMove(msg.value)
    end

--根据界面加载UI
    if msg.msgId == LUIMonopolyEvent.updateMonopoly then
        self:fillUIData();
    end 

--角色移动完毕,更新UI
    if msg.msgId == LUIMonopolyEvent.updateMoveOverUI then

    end

    if msg.msgId == LUIMonopolyEvent.showBattleChatLayer then
        self:setChatData(msg.value)
        self:showBattleChatLayer()
    end

    if msg.msgId == LUIMonopolyEvent.justShowBattleChatLayer then
        --LuaNetSendMsg:QueryMonopolyInfo(AppDef.monopoly.ECGOp_QueryEnemy)
        local data = LRoleDataMgr.MonopolyData.cellData[self._curPosIndex + 1]
        print("cur Index = self._curPosIndex", self._curPosIndex)
        self:setChatData(data)
        self:showBattleChatLayer()
    end

    if  msg.msgId == LUIMonopolyEvent.updateAwardUIIcon then
        self:updateAwardUIIcon();
    end

    if msg.msgId == LUIMonopolyEvent.updateBattleUIIcon then
        self:updateBattleUIIcon();
    end

    if msg.msgId == LUIMonopolyEvent.ResetRolePos then
        --还原位置
        self:resetRolePos();
    end

    if msg.msgId == LUIMonopolyEvent.monopolyChatDialog then
        self:monopolyHeroEvent(msg.value)
    elseif msg.msgId == LUIKunLunEvent.GetRobotZhenFaInfo then
        self:OpenFormationUI(msg.value)
    end

end

function MonopolyBaseUI:OpenFormationUI(zhenfaData)
    local value = {}
    value.enemyZhenfaId = zhenfaData.zhengfaId
    value.enemyInfos = zhenfaData.zhengfaData

    local fun = function()
        LuaNetSendMsg:QueryMonopolyInfo(12, 1)
    end
    value.callback = fun
    value.isrole = zhenfaData.isRole
    Utils:InitUI("Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
end

function MonopolyBaseUI:monopolyHeroEvent(ind)
    -- body
    if ind == 1 then
        --挑战
        -- LuaNetSendMsg:QueryMonopolyInfo(12, 1);
        print("self._chatDialogData.userid ==>", self._chatDialogData.userid)
        LuaNetSendMsg:QueryRobotInfo(self._chatDialogData.userid)
    elseif ind == 2 then
        --求助
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Monopoly.SeekHelpUI",AppDef.UIType.SecondClassLayer)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function MonopolyBaseUI:initUI()
    
    local heigth = 0;
    local width = 0
    self._panel = self.m_pUILayer:getChildByName("bg")
    for i = 1, #self._textureArr do
        local sprit = cc.Sprite:createWithTexture(self._textureArr[i])
        sprit:setAnchorPoint(cc.p(0, 0))

        if self._lastWidth > 0 then
            width = width + self._lastWidth
            if (i -1) % 8 == 0 then
                width = 0
            end
        end

        if self._lastHeight > 0 then
            if (i -1) % 8 == 0 then
                heigth = heigth + self._lastHeight
            end
        end

        self._lastWidth = sprit:getContentSize().width
        self._lastHeight = sprit:getContentSize().height

        sprit:setPosition(cc.p(width, heigth))
        self._panel:addChild(sprit, -1)
    end

 --   local nodeStart = self._panel:getChildByName("Node_1"):getChildByName("Image_1")
 --   nodeStart:loadTexture("res/UI/ui_chuangguan/Start.png", ccui.TextureResType.plistType)
 --   nodeStart:setContentSize(cc.size(197, 111))
    
    for i = 1, 82 do
        local nodeRoot = self._panel:getChildByName("Node_"..i)
 --       local node = nodeRoot:getChildByName("Image_1")
 --       node:loadTexture("res/UI/ui_chuangguan/gezi.png", ccui.TextureResType.plistType)
 --       node:setContentSize(cc.size(197, 111))

        table.insert(self._NodePosArr, cc.p(nodeRoot:getPosition()))

        -- local lable = cc.Label:createWithSystemFont( i, AppDef.FNT_NAME, 25)
        -- self._panel:addChild(lable)
        -- lable:setPosition(nodeRoot:getPosition())

    end

    local data = LRoleDataMgr.MyHeroInfo
    self.m_pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,
                                            data.model,
                                            0, 
                                            0,
                                            0,
                                            0,
                                            0)
     self._panel:addChild(self.m_pRoleModel)

     self.m_pRoleModel:PlayStand(2)
     self.m_pRoleModel:setLocalZOrder(999)

    
    local function showMainChatlayer(pTouch, pEvent)

        if pEvent == ccui.TouchEventType.began then
           if self._isMoveing then
                return

           end

           self._touchBeginPos = self._panel:getTouchBeganPosition()
           self._touchMovePos = self._touchBeginPos
        end

        if pEvent == ccui.TouchEventType.moved then

            if self._isMoveing then
                return
            end

            local movey = self._panel:getTouchMovePosition()
            -- self._panel:setPosition(cc.p(movey.x, movey.y))

            local offetX = 0
            local offsetY = 0
            if self._touchMovePos then
                offetX = movey.x - self._touchMovePos.x
                offsetY = movey.y - self._touchMovePos.y
            end

            self._touchMovePos = movey

            --边界判断
            local posX = self._panel:getPositionX() + offetX
            if posX > 0 then 
                posX = 0
            end

            if posX < self._VIEW_RIGHT then
                posX = self._VIEW_RIGHT
            end

            local posY = self._panel:getPositionY() + offsetY
            if posY > 0 then
                posY = 0
            end

            if posY < self._VIEW_TOP then
                posY = self._VIEW_TOP
            end

            self._panel:setPosition(cc.p(posX, posY))

        end

        if pEvent == ccui.TouchEventType.ended then
            
        end
    end

    self._panel:addTouchEventListener(showMainChatlayer)
	self:MarkIntaractCObj(self._panel)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Monopoly.MonopolyUI",AppDef.UIType.Battle)
    self:SendMsg(LGameMsg.m_initUIMsg)
    LuaNetSendMsg:QueryMonopolyInfo(15) --多人闯关

end

function MonopolyBaseUI:asynLoadTexture()
    local function callback(texture)
        if self._initIndex == nil then
            return
        end
        self._initIndex = self._initIndex + 1
        LGameMsg.m_loadingProgressMsg:ChangeWithMsgId(LUILoadingEvt.ShowLoadingProcess, self._initIndex * 100.0 / 40)
        LUIManager:SendMsg(LGameMsg.m_loadingProgressMsg)
        table.insert(self._textureArr, texture)

        if self._initIndex >= 40 then
            LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.HideLoading)
            self:SendMsg(LGameMsg.m_baseMsg)
            self:initUI()
        end
    end

    local imageArr = {}
    self._textureArr = {}
    local textureCache = AppDef.textureCache
    for i = 1, 40 do
         table.insert(imageArr, string.format("chuangguan/UI_Scene_%d.jpg" ,i - 1))
         textureCache:addImageAsync(imageArr[i], callback) 
    end
    
end

function MonopolyBaseUI:roleMove(toIndex)
    
    local function callback(node, value)
        self.m_pRoleModel:PlayStand(value.value)
        Utils:SendMsg(LUIMonopolyEvent.RoleMoveOver)
        self._isMoveing = false
    end

    local function callbackRunDir(node, value)
        self.m_pRoleModel:PlayRun(value.value)
    end

    --print("MonopolyBaseUI:roleMove toIndex =", toIndex)

    if toIndex > 82 then
        toIndex = 82
    end

    if toIndex < 0 or toIndex == self._curPosIndex then
        return
    end

    self._isMoveing = true
    local frameSize = AppDef.frameSize
    local actionArr = {}
    local mapActionArr = {}
    
    if toIndex < self._curPosIndex then
--处理倒走
        local  beginIndex = self._curPosIndex - 1
        local  endIndex = toIndex
        for i = beginIndex, endIndex, -1 do
            local dir = self:getRoldDir(self._NodePosArr[i + 1], self._NodePosArr[i])
            local func = cc.CallFunc:create(callbackRunDir, {value = dir})
            table.insert(actionArr, func);
            if self._NodePosArr[i] then
                local action = cc.MoveTo:create( 0.5, self._NodePosArr[i])
                table.insert(actionArr, action)
            end

            local xSpace = -self._NodePosArr[i].x + self._NodePosArr[i + 1].x
            if self._NodePosArr[i].x >= self._NodePosArr[81].x  then
                xSpace = 0
            end

            local mapAction = cc.MoveBy:create( 0.5, cc.p(xSpace, -self._NodePosArr[i].y + self._NodePosArr[i + 1].y))
            table.insert(mapActionArr, mapAction)
        end

        local endPosIndex = toIndex - 1
        if endPosIndex <= 0 then
            endPosIndex = 1
        end
        local dir = self:getRoldDir(self._NodePosArr[toIndex], self._NodePosArr[endPosIndex])
        table.insert(actionArr, cc.CallFunc:create(callback, {value = dir}));
    else
        local  beginIndex = self._curPosIndex + 1
        local  endIndex = toIndex
        for i = beginIndex, endIndex do    
            local dir = self:getRoldDir(self._NodePosArr[i - 1], self._NodePosArr[i])
            local func = cc.CallFunc:create(callbackRunDir, {value = dir})
            table.insert(actionArr, func);

            local action = cc.MoveTo:create( 0.5, self._NodePosArr[i])
            table.insert(actionArr, action);

            local xSpace = -self._NodePosArr[i].x + self._NodePosArr[i - 1].x

            if self._NodePosArr[i].x >= self._NodePosArr[81].x  then
                xSpace = 0
            end

            local mapAction = cc.MoveBy:create( 0.5, cc.p(xSpace, -self._NodePosArr[i].y + self._NodePosArr[i - 1].y))
            table.insert(mapActionArr, mapAction)
        end

        local targetPos
        if toIndex >= 82 then
            targetPos = self._NodePosArr[toIndex]
        else
            targetPos = self._NodePosArr[toIndex + 1]
        end

        local dir = self:getRoldDir(self._NodePosArr[toIndex], targetPos)
        --print("dir = ", dir, self._NodePosArr[toIndex], targetPos)
        table.insert(actionArr, cc.CallFunc:create(callback, {value = dir}));
    end
    
    
    self._curPosIndex = toIndex;

--    --print("MonopolyBaseUI:roleMove size = ", #self._NodePosArr, self._NodePosArr[toIndex].x, self._NodePosArr[toIndex].y)
    
    local oldPosX, oldPosY = self.m_pRoleModel:getPosition()
    local offetX = self._NodePosArr[toIndex].x - oldPosX
    local offerY = self._NodePosArr[toIndex].y - oldPosY

    local sequence = cc.Sequence:create(actionArr)
    self.m_pRoleModel:runAction(sequence)

    local mapSequence = cc.Sequence:create(mapActionArr)
    self._panel:runAction(mapSequence)

end

function MonopolyBaseUI:getRoldDir(pos, targetPos)
    if targetPos == nil then
        return 0
    end
    if targetPos.x > pos.x and targetPos.y < pos.y then
        return 0
    elseif targetPos.x < pos.x and targetPos.y < pos.y then
        return 2
    elseif targetPos.x < pos.x and targetPos.y > pos.y then
        return 4
    elseif targetPos.x >= pos.x and targetPos.y >= pos.y then
        return 6
    end
end

function MonopolyBaseUI:resetRolePos()
    -- body

    local rolePosX, rolePosY = self.m_pRoleModel:getPosition()
    local bgPos = self:GetCameraLeftDownPoint(rolePosX, rolePosY)
    if bgPos.x < self._VIEW_RIGHT then
        bgPos.x = self._VIEW_RIGHT
    end
    local action = cc.MoveTo:create(0.5, bgPos)
    self._panel:runAction(action)
    
--    self._panel:setPosition(bgPos)



end

function MonopolyBaseUI:fillUIData()
    -- body
    local function battleEvent( sender )
        -- body
        --对话
 --       LuaNetSendMsg:QueryRushGateInfo(12, 1);

        local pUserDefault = CCUserDefault:getInstance()
        local userId = LRoleDataMgr.MyHeroInfo.id
        local monopolyIsCanBattle = userId.."monopoly"

        local isCanBattle = pUserDefault:getBoolForKey(monopolyIsCanBattle, false)
        if not isCanBattle then
            return
        end

        local tag = sender:getTag();
        local data = LRoleDataMgr.MonopolyData.cellData[tag]



--        --print("MonopolyBaseUI:fillUIData $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", tag, data.eventid, self._curPosIndex)
        
        --如果前方不是战斗类型则不处理
        if self._curPosIndex + 1 ~= tag and  data.eventid ~= 2 then
            return
        end
        LuaNetSendMsg:QueryMonopolyInfo(AppDef.monopoly.ECGOp_QueryEnemy)

    end
    self:resetMonopolyUI()
    self:initRoleUI();
    
    for i = 1, LRoleDataMgr.MonopolyData.cellnum do
        local data = LRoleDataMgr.MonopolyData.cellData[i]
        if i == data.cellid then

            if data.eventid == 0 then
                local image = self._panel:getChildByName("Node_"..i):getChildByName("Image_1")
                image:setTouchEnabled(false)
            elseif data.eventid == 2 and data.eventnum > 0 then
            --战斗
                -- dump(data, "monopoly data =====================>")
                -- data.career = 4
                -- data.weapen = 0
                -- data.effect = 0
                local pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,
                                                                data.career,
                                                                data.weapen,
                                                                data.effect, 0, 0, 0)

                local _pRoleModel = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_MONSTER, petId)

                self._panel:addChild(pRoleModel)
                pRoleModel:setTag(i + TAGFINALVALUE)
            
                local begin = i
                local endDirPos = i - 1
                if endDirPos < 1 then
                    endDirPos = 1
                end
    
                local dir = self:getRoldDir(self._NodePosArr[begin], self._NodePosArr[endDirPos])
                pRoleModel:PlayStand(dir)

                local roleName = cc.Label:createWithSystemFont( data.name, AppDef.FNT_NAME, 20)
                roleName:enableShadow()
                roleName:setColor(cc.YELLOW)
                pRoleModel:addChild(roleName)
                roleName:setPosition(cc.p(pRoleModel:getContentSize().width / 2, -17))

            --战斗位置增加点击事件
                pRoleModel:setPosition(self._panel:getChildByName("Node_"..i):getPosition())
                local image = self._panel:getChildByName("Node_"..i):getChildByName("Image_1")
                image:setTouchEnabled(true)
                image:setTag(i)
                image:addClickEventListener(battleEvent)
				self:MarkIntaractCObj(image)
            elseif data.eventid == 3 and data.eventnum > 0 then
            --宝箱
                local baoxiang = cc.Sprite:createWithSpriteFrameName("res/UI/ui_chuangguan/baoxiang.png")
                self._panel:addChild(baoxiang)
                baoxiang:setAnchorPoint(cc.p(0.5, 0.5))
                baoxiang:setTag(i + TAGFINALVALUE)
                local positionX, positionY = self._panel:getChildByName("Node_"..i):getPosition()
                baoxiang:setPosition(cc.p(positionX + Node_Offset_x, positionY + Node_Offset_y))
            elseif data.eventid == 4 and data.eventnum > 0 then
            --猜拳
                local caiquang = cc.Sprite:createWithSpriteFrameName("res/UI/ui_chuangguan/caiquan.png")
                self._panel:addChild(caiquang)
                caiquang:setAnchorPoint(cc.p(0.5, 0.5))
                caiquang:setTag(i + TAGFINALVALUE)
                local positionX, positionY = self._panel:getChildByName("Node_"..i):getPosition()
                caiquang:setPosition(cc.p(positionX + Node_Offset_x, positionY + Node_Offset_y))
            elseif data.eventid == 5 then
            --终点

            elseif data.eventid == 6 and data.eventnum > 0 then
            --元宝
                local yuanbao = cc.Sprite:createWithSpriteFrameName("res/UI/ui_chuangguan/yuanbao.png")
                self._panel:addChild(yuanbao)
                yuanbao:setAnchorPoint(cc.p(0.5, 0.5))
                yuanbao:setTag(i + TAGFINALVALUE)
                local positionX, positionY = self._panel:getChildByName("Node_"..i):getPosition()
                yuanbao:setPosition(cc.p(positionX + Node_Offset_x, positionY + Node_Offset_y))
            elseif data.eventid == 7 and data.eventnum > 0 then
            --金币
                local coin = cc.Sprite:createWithSpriteFrameName("res/UI/ui_chuangguan/jinbi.png")
                self._panel:addChild(coin)
                coin:setAnchorPoint(cc.p(0.5, 0.5))
                coin:setTag(i + TAGFINALVALUE)
                local positionX, positionY = self._panel:getChildByName("Node_"..i):getPosition()
                coin:setPosition(cc.p(positionX + Node_Offset_x, positionY + Node_Offset_y))
            elseif data.eventid == 8 and data.eventnum > 0 then
            --问号事件
                local wenhao = cc.Sprite:createWithSpriteFrameName("res/UI/ui_chuangguan/wenhao.png")
                self._panel:addChild(wenhao)
                wenhao:setAnchorPoint(cc.p(0.5, 0.5))
                wenhao:setTag(i + TAGFINALVALUE)
                local positionX, positionY = self._panel:getChildByName("Node_"..i):getPosition()
                wenhao:setPosition(cc.p(positionX + Node_Offset_x, positionY + Node_Offset_y))
            end
        end
        
    end
end

function MonopolyBaseUI:resetMonopolyUI()
    -- body
    for i = 1, LRoleDataMgr.MonopolyData.cellnum do
        local mapItems = self._panel:getChildByTag(i + TAGFINALVALUE)
        if mapItems then
            mapItems:removeFromParent()
        end
    end
end

function MonopolyBaseUI:initRoleUI()
    -- body
    self._curPosIndex = LRoleDataMgr.MonopolyData.curPos
    if self._curPosIndex <= 0 then
        self._curPosIndex = 1
    end

    local begin = self._curPosIndex
    if begin < 1 then
        begin = 1
    end
    local endDirPos = self._curPosIndex + 1
    if endDirPos > 82 then
        endDirPos = 82
    end
    local dir = self:getRoldDir(self._NodePosArr[begin], self._NodePosArr[endDirPos])
    self.m_pRoleModel:PlayStand(dir)

    self._beginPos = cc.p(self._panel:getChildByName("Node_".. self._curPosIndex):getPosition())

    --起点位置
     self.m_pRoleModel:setPosition(self._beginPos)
     local firstPos = cc.p(self._panel:getChildByName("Node_1"):getPosition())

     local bgPos = self:GetCameraLeftDownPoint(self._beginPos.x, self._beginPos.y)
     if bgPos.x < self._VIEW_RIGHT then
        bgPos.x = self._VIEW_RIGHT
    end
     self._panel:setPosition(bgPos)
     LRoleDataMgr.MonopolyData.isMonopolyState = true
end

function MonopolyBaseUI:GetCameraLeftDownPoint(px, py)
    -- body
    local x, y
    local maxWidth = self._panel:getContentSize().width
    local visibleSize = AppDef.frameSize
    if px - visibleSize.width / 2 <= 0 then
        x = 0
    elseif px >= maxWidth  - visibleSize.width / 2 then
        x = maxWidth - visibleSize.width
    else
        x = px - visibleSize.width / 2
    end

    local maxHeight = self._panel:getContentSize().height
    if py - visibleSize.height / 2 <= 0 then
        y = 0
    elseif py >= maxHeight  - visibleSize.height / 2 then
        y = maxHeight - visibleSize.height
    else
        y = py - visibleSize.height / 2
    end

    return cc.p(-x, -y)
end


function MonopolyBaseUI:setChatData(data)
    -- body
    dump(data, "MonopolyBaseUI setChatData ============>")
    self._chatDialogData = data
end


function MonopolyBaseUI:showBattleChatLayer()
    -- body
    --显示战斗对话框
    if self._chatDialogData == nil then
        return
    end
    local npcChat = LNpcChatData:New()
    npcChat.Name = self._chatDialogData.name



--    dump(self._chatDialogData, "netData -------------")
    if self._chatDialogData.eventid == 2 then
        npcChat.prof = self._chatDialogData.career
    else
    --默认形象
        npcChat.prof = 1
    end
    
    npcChat.type = 4
    --print("MonopolyBaseUI:showBattleChatLayer id", npcChat.prof)
--    local data = LRoleDataMgr.MonopolyData.cellData[tag]
    
    npcChat.monopolyChatData.id = self._chatDialogData.userid
    npcChat.monopolyChatData.power = self._chatDialogData.power


    if self._chatDialogData.awardInfo ~= nil and #self._chatDialogData.awardInfo > 0 then
        npcChat.monopolyChatData.awardType = self._chatDialogData.awardInfo[1].awardType
        npcChat.monopolyChatData.awardNum = self._chatDialogData.awardInfo[1].awardNum
    else
        npcChat.monopolyChatData.awardType = AppDef.AwrdItem.AWRD_ITEM_YUANBAO
        npcChat.monopolyChatData.awardNum = 30
    end

    dump(npcChat.monopolyChatData, "showBattleChatLayer =====================>")

    -- for i = 1, 2 do
    --     local index = i
    --     table.insert(npcChat.TextIndex, index)
    --     if i== 1 then
    --         local str = GUITips.RSI_MONOPOLY_CHALLENGE
    --         table.insert(npcChat.Text, str)
    --     else
    --         local str = GUITips.RSI_MONOPOLY_ASK
    --         table.insert(npcChat.Text, str)
    --     end
    -- end

    local str = GUITips.RSI_MONOPOLY_CHALLENGE
    table.insert(npcChat.TextIndex, 1)
    table.insert(npcChat.Text, str)
    --print("show the NPC chat")
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCChatUI", AppDef.UIType.PopWindow,npcChat)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function MonopolyBaseUI:updateAwardUIIcon()
    -- body
    local obj = self._panel:getChildByTag(self._curPosIndex + TAGFINALVALUE)
    if obj then
        local action = cc.FadeOut:create(1)
        obj:runAction(action)
    end
end

function MonopolyBaseUI:updateBattleUIIcon()
    -- body
    local obj = self._panel:getChildByTag(self._curPosIndex + 1 + TAGFINALVALUE)
    if obj then
        obj:setVisible(false)
    end

    local image = self._panel:getChildByName("Node_"..(self._curPosIndex + 1)):getChildByName("Image_1")
    if image then
        image:setTouchEnabled(false)
    end
end

return MonopolyBaseUI
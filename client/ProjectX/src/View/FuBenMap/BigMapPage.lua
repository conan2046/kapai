--[[
大地图每个页面显示控制
]]
local BigMapPage = {}
BigMapPage.__index = BigMapPage

--local this = LTcpSocket
function BigMapPage:New(ctrl, curPage, pageNode, pageParent)
	local o = LUIBase:New()
	setmetatable(o,BigMapPage)	
    o:Init(ctrl, curPage, pageNode, pageParent)
	return o
end

function BigMapPage:Init(ctrl, curPage, pageNode, pageParent)
	self._curPage = curPage
	self._ctrl = ctrl
    self.m_pUILayer = pageNode;
    -- self._stageData = stageData;
    self._pageView = pageParent;
    self._mapResArr = {}
    self._view = {}
    self._isOnDelete = false;
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:LoadAllObject(self.m_pUILayer,"")
    self:LoadMap(curPage)
end

function BigMapPage:LoadAllObject(root, path)
	local children = root:getChildren();
	local num = #children;
	for i = 1, num do
		local childName = children[i]:getName();
		self._view[path .. childName] = children[i];
		self:LoadAllObject(children[i], path .. childName .. "/")
	end
	-- 
end

function BigMapPage:UpdatePage(curPage)
	if self._curPage == curPage then
		return
	end

	self:DeleteCurRes();
	self._curPage = curPage;
	self:LoadMap()
	
	
end

function BigMapPage:ResetShow()
	-- for i = 1, 15 do
 --        self.m_pUILayer:getChildByName("btn_" .. i):setVisible(false);
 --    end
end

function BigMapPage:RefreshPageNode(ind)
	local mylevel = LRoleDataMgr.MyHeroInfo.level
	local i = self._curPage;
	local bg = self.m_pUILayer;
	local j = ind
	local index = (i - 1)*5 + j
    local data
    if self._ctrl._allPageData ~= nil and #self._ctrl._allPageData >= index then
        data = self._ctrl._allPageData[index]
    end

    if data == nil then
        return
    end

    local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
    --local btn = bg:getChildByName(configData.Chapter_btn)
    local btnName = "btn_" .. j;
    local btn = self._view[btnName]
    btn:setVisible(true);
    
    --local  Label = btn:getChildByName("Label")
    local Label = self._view[btnName .. "/Label"];
    --local name = Label:getChildByName("Text")
    local name = self._view[btnName .. "/Label/Text"];
    Label:setVisible(true)
    name:setVisible(false)
    --local xuhao = name:getChildByName("xuhao")
    local xuhao = self._view[btnName .. "/Label/Text/xuhao"];
    --local Finish = btn:getChildByName("Finish")
    local Finish = self._view[btnName .. "/Finish"];
    Finish:setVisible(false)

    --local perfect = btn:getChildByName("perfect")
    local perfect = self._view[btnName .. "/perfect"];
    perfect:setVisible(false)

    
    --锁的状态显示
    --local suo = btn:getChildByName("suo")
    local suo = self._view[btnName .. "/suo"];
    --local lock = suo:getChildByName('lock')
    local lock = self._view[btnName .. "/suo/lock"];
    --print(self._mapIndex,i,self._openChapterIndex,j,"锁的状态显示=========>")
    lock:setVisible(false)
    suo:setVisible(true)
    if self._ctrl._mapIndex > i then --已通关
        suo:setVisible(false)
        name:setVisible(true)
    elseif self._ctrl._mapIndex == i then--当前关卡
        if self._ctrl._openChapterIndex >= index then
            suo:setVisible(false)
            name:setVisible(true)
        else
            suo:setVisible(true)
            name:setVisible(false)
        end
    else--未解锁
        suo:setVisible(true)
        name:setVisible(false)

    end
    --local HeadBg = btn:getChildByName("HeadBg")
    local HeadBg = self._view[btnName .. "/HeadBg"];
    HeadBg:setVisible(false)
    --local boxBg =  btn:getChildByName("boxBg")
    local boxBg =  self._view[btnName .. "/boxBg"];
    local red = self._view[btnName .. "/boxBg/Prompt"];
    boxBg:setVisible(false)
    red:setVisible(false)
    --local Text_xing1 = btn:getChildByName("Text_xing")
    local Text_xing1 = self._view[btnName .. "/Text_xing"];
    Text_xing1:setVisible(false)

    if data then
        --print("--------------------data.chapterId",data.chapterId,data.chapterMaxStarNum)
        --local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
        if configData.OpenLv > mylevel then
            --等级未达到,未解锁
            lock:setVisible(true)
            lock:setString(string.format(GUITips.RSI_XUEZHAN_TIP18, configData.OpenLv))
        end

        if not lock:isVisible() and not name:isVisible() then
            Label:setVisible(false)
        end
       
        local ownBoxNum = self._ctrl:getChapterOwnBoxNum(data.chapterId)
        --print("normalUI refreshUI ===>", data.chapterId, ownBoxNum, self:getChapterOwnStar(data.chapterId))
        if ownBoxNum > 0 then
            boxBg:setVisible(true)
            red:setVisible(true)
        end
        -- print("self._ctrl._datas.curChapterId",self._ctrl._datas.curChapterId,"data.chapterId",data.chapterId)
        if self._ctrl._datas.curChapterId == data.chapterId then
            --后面一章开头
            --print("normalUI refreshUI ===>1")
            local afterIndex = (i - 1)*5 + 5
            HeadBg:setVisible(true)
            self:PlayBoxAndHead(HeadBg)
            local prof = LRoleDataMgr.MyHeroInfo.head
            local strHeadImage = AppDef:GetHeroPicFileName(prof, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
            HeadBg:getChildByName("Icon"):loadTexture(strHeadImage, ccui.TextureResType.localType)

            Text_xing1:setVisible(true)
            Text_xing1:setString(string.format("%d/%d", self._ctrl:getChapterOwnStar(data.chapterId), data.chapterMaxStarNum))
        elseif self._ctrl._datas.curChapterId > data.chapterId then
            --print("normalUI refreshUI ===>2")
            Text_xing1:setVisible(true)
            Text_xing1:setString(string.format("%d/%d", self._ctrl:getChapterOwnStar(data.chapterId), data.chapterMaxStarNum))
            --过关
            Finish:setVisible(true)
            perfect:setVisible(false)
        end

        --完美过关
        if self._ctrl:getChapterOwnStar(data.chapterId) >= data.chapterMaxStarNum then
            Finish:setVisible(false)
            perfect:setVisible(true)
        end

    
    end
end

function BigMapPage:RefreshPage()
	-- local mylevel = LRoleDataMgr.MyHeroInfo.level
	-- local i = self._curPage;
	-- local bg = self.m_pUILayer;
	for j=1, 5 do
        self:RefreshPageNode(j)
    end
end

function BigMapPage:ShowCurPage()
	local mylevel = LRoleDataMgr.MyHeroInfo.level
	local i = self._curPage;
	local bg = self.m_pUILayer;
	self.m_pUILayer:setVisible(true)

	for j=1, 5 do
        local index = (i - 1)*5 + j
        local data
        if self._ctrl._allPageData ~= nil and #self._ctrl._allPageData >= index then
            data = self._ctrl._allPageData[index]
        end
        
        if data == nil then
            for k = j, 5 do
                local btnName = "btn_" .. k;
                self._view[btnName]:setVisible(false)
            end
            break
        end
        local btnName = "btn_" .. j;
        local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
        local btn = self._view[btnName]
        btn:setVisible(true);
        btn:setTag(index);
        ScriptHandlerMgr:getInstance():removeObjectAllHandlers(btn);
        btn:addClickEventListener(handler(self, BigMapPage.enterEvent))
        btn:setPosition(Utils:GetRelativePoint(cc.p(configData.Position_btn[1],configData.Position_btn[2])))

        btn:loadTextureNormal("res/UI/ditu_shijie/" .. configData.btn_Image.. ".png", UI_TEX_TYPE_PLIST);
        local Label = self._view[btnName .. "/Label"];
        local name = self._view[btnName .. "/Label/Text"];
        Label:setVisible(true)
        name:setVisible(false)
        local xuhao = self._view[btnName .. "/Label/Text/xuhao"];
        local Finish = self._view[btnName .. "/Finish"];
        Finish:setVisible(false)
        local perfect = self._view[btnName .. "/perfect"];
        perfect:setVisible(false)

        
        --锁的状态显示
        local suo = self._view[btnName .. "/suo"];
        local lock = self._view[btnName .. "/suo/lock"];
        lock:setVisible(false)
        suo:setVisible(true)
        if self._ctrl._mapIndex > i then --已通关
            suo:setVisible(false)
            name:setVisible(true)
        elseif self._ctrl._mapIndex == i then--当前关卡
            if self._ctrl._openChapterIndex >= index then
                suo:setVisible(false)
                name:setVisible(true)
            else
                suo:setVisible(true)
                name:setVisible(false)
            end
        else--未解锁
            suo:setVisible(true)
            name:setVisible(false)

        end
        local HeadBg = self._view[btnName .. "/HeadBg"];
        self:PlayBoxAndHead(HeadBg)
        HeadBg:setTag(index)
        ScriptHandlerMgr:getInstance():removeObjectAllHandlers(HeadBg);
        HeadBg:addClickEventListener(handler(self, BigMapPage.enterEvent))
        HeadBg:setVisible(false)
        if index == 1 and data.chapterId == 1001 then
            self._ctrl.m_guideBtn1 = HeadBg
        elseif index == 2 and data.chapterId == 1002 then
            self._ctrl.m_guideBtn2 = HeadBg
        end
        local boxBg =  self._view[btnName .. "/boxBg"];
        self:PlayBoxAndHead(boxBg)
        local red = self._view[btnName .. "/boxBg/Prompt"];
        boxBg:setVisible(false)
        red:setVisible(false)
        local Text_xing1 = self._view[btnName .. "/Text_xing"];
        Text_xing1:setVisible(false)

        if data then
            --print("--------------------data.chapterId",data.chapterId,data.chapterMaxStarNum)
            --local configData = JsonConfig.m_FuBenMapConfig.getDefByID(data.chapterId)
            if configData.OpenLv > mylevel then
                --等级未达到,未解锁
                lock:setVisible(true)
                lock:setString(string.format(GUITips.RSI_XUEZHAN_TIP18, configData.OpenLv))
            end

            if not lock:isVisible() and not name:isVisible() then
                Label:setVisible(false)
            end

            if j == 1 then
                local bgImg = self._view["Image"];
                self._bgResName = "res/UI/Icon/ui_map_icon/" ..configData.World_bg .. ".png";
                bgImg:loadTexture(self._bgResName, ccui.TextureResType.localType)
            end
           
            name:setString(data.chapterName)
            xuhao:setString(data.chapterId % 1000)
            
            -- self._mapName:setString(data.chapterId)
            local ownBoxNum = self._ctrl:getChapterOwnBoxNum(data.chapterId)
            --print("normalUI refreshUI ===>", data.chapterId, ownBoxNum, self:getChapterOwnStar(data.chapterId))
            if ownBoxNum > 0 then
                boxBg:setVisible(true)
                red:setVisible(true)
            end

            if self._ctrl._datas.curChapterId == data.chapterId then
                --后面一章开头
                --print("normalUI refreshUI ===>1")
                local afterIndex = (i - 1)*5 + 5

                self._ctrl:updateRLTipsUI(curIndex, afterIndex)

                HeadBg:setVisible(true)
                local prof = LRoleDataMgr.MyHeroInfo.head
                local strHeadImage = AppDef:GetHeroPicFileName(prof, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
                HeadBg:getChildByName("Icon"):loadTexture(strHeadImage, ccui.TextureResType.localType)

                Text_xing1:setVisible(true)
                Text_xing1:setString(string.format("%d/%d", self._ctrl:getChapterOwnStar(data.chapterId), data.chapterMaxStarNum))
            elseif self._ctrl._datas.curChapterId > data.chapterId then
                --print("normalUI refreshUI ===>2")
                Text_xing1:setVisible(true)
                Text_xing1:setString(string.format("%d/%d", self._ctrl:getChapterOwnStar(data.chapterId), data.chapterMaxStarNum))
                --过关
                Finish:setVisible(true)
                perfect:setVisible(false)
            end

            --完美过关
            if self._ctrl:getChapterOwnStar(data.chapterId) >= data.chapterMaxStarNum then
                Finish:setVisible(false)
                perfect:setVisible(true)
            end

        
        end
    end
end

function BigMapPage:PlayBoxAndHead(node)
    local move = cc.MoveTo:create(0.4,cc.p(node:getPositionX(),node:getPositionY()+5))
    local move1 = cc.MoveTo:create(0.4,cc.p(node:getPositionX(),node:getPositionY()-5))
    local moveAction = {}
    table.insert(moveAction, move)
    table.insert(moveAction, cc.DelayTime:create(0.2))
    table.insert(moveAction, move1)
    local actRepeat=cc.RepeatForever:create(cc.Sequence:create(moveAction))
    node:stopAllActions()
    node:runAction(actRepeat)
end

function BigMapPage:enterEvent(sender)
	self._ctrl:enterEvent(sender)
end

function BigMapPage:DeleteCurRes()
	if self._bgResName then
		self._bgResName = nil
		display.removeImage(self._bgResName)
		self._bgResName = nil
	end
end

function BigMapPage:onExit()
	self:DeleteCurRes();
end

function BigMapPage:LoadMap()
	local pageNode = self._pageView:getItem(self._curPage - 1);
	self._isOnDelete = false
	self.m_pUILayer:retain();
	if self.m_pUILayer:getParent() then
		self.m_pUILayer:removeFromParent();
	end
	pageNode:addChild(self.m_pUILayer);
	self.m_pUILayer:release();
	self:ResetShow();
	self:ShowCurPage();
end

return BigMapPage
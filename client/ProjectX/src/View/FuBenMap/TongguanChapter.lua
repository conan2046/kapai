
local TongguanChapter = LUIBase:New()
TongguanChapter.__index = TongguanChapter
--local this = LTcpSocket
function TongguanChapter:New(stageData)
	local o = LUIBase:New()
	setmetatable(o,TongguanChapter)	
    o:Init(stageData)
	return o
end

--注册事件
-- -----------------------------------
function TongguanChapter:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function TongguanChapter:ProcessEvent(msg)

end

function TongguanChapter:Init(stageData)

   

    self.m_pUILayer = cc.CSLoader:createNode("csd/fuben/tongguanLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)


   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local action = cc.CSLoader:createTimeline("csd/fuben/tongguanLayer.csb")
    local timeline = ccs.Timeline:create()
    local frame = ccs.EventFrame:create()
    frame:setEvent("End")
    frame:setFrameIndex(30)
    timeline:addFrame(frame)
    action:addTimeline(timeline)
    -- action:setFrameEventCallFunc(callback)
    self.m_pUILayer:runAction(action)
    action:pause()
    action:clearFrameEventCallFunc()
    action:gotoFrameAndPlay(0,30,false)
    self:initData(stageData)
    self:initControlUI()
end

function TongguanChapter:initData( stageData )
    -- body
    self._stageData = stageData
end

function TongguanChapter:initControlUI( ... )
    -- body
    local Panel = self.m_pUILayer:getChildByName("Panel")
    self._text = Panel:getChildByName("Text")
    self._text:setString(string.format(GUITips.RSI_FUBENMAP_RES15, self._stageData.curChapterID % 1000, self._stageData.chapterName))

    -- local function showEnd()
    --     self:closeDialog()
    -- end
    -- performWithDelay(self.m_pUILayer,showEnd, 2)

    local showEnd =  cc.CallFunc:create(function()
                Utils:SendMsg(LUIFuBenMapEvent.tongGuanEvent)
                self:closeDialog()
            end)
    self.m_pUILayer:runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.FadeOut:create(2), showEnd))

end

function TongguanChapter:closeDialog( sender )
    -- body
    -- Utils:DeleteUI("FuBenMap.FuBenMainUI")
    Utils:DeleteUI("FuBenMap.TongguanChapter")
end


function TongguanChapter:onExit()
    if self._stageData.curChapterID % 1000 == 1 then
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen4,true)
    end
    self.m_pUILayer = nil
    self:Destory()
end

return TongguanChapter
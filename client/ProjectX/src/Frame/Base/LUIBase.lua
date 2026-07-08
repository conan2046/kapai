LUIBase = {}

LUIBase.__index = LUIBase

function LUIBase:New()
	local o = {}
	setmetatable(o,LUIBase)
	o.msgIds = {}
	o.Script = nil
    o.m_pUILayer = nil
    o.csbFilePath = nil
    o.isUseResBuffer = false--是否使用统一的加载接口加载csb
    o.loadImageKey = {}
    
    --o.intaractCObjs = {}
    --setmetatable(self.intaractCObjs, {__mode = "v"})--设置值为弱引用
	return o
end

--[[
需要和C++添加点击或触摸事件的obj元素
]]
function LUIBase:MarkIntaractCObj(cobj)
    -- for i, v in pairs(self.intaractCObjs) do--迭代数组
    --     if v == cobj then
    --         return  
    --     end
    -- end 
    -- cobj:retain()
    -- table.insert(self.intaractCObjs, cobj)
end

function LUIBase:CreateUINode(csbFilePath)
    self.m_pUILayer = cc.CSLoader:createNode(csbFilePath)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    -- self.isUseResBuffer = true
    -- self.csbFilePath = csbFilePath
    -- local function callback(csbNode)
    --     self.m_pUILayer = csbNode
    --     local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
    -- end

    -- LGameMsg.m_resMsg:Change(LResEvent.LoadCsb, csbFilePath, callback)
    -- self:SendMsg(LGameMsg.m_resMsg)
end

function LUIBase:RegistSelf(script, msgs)
	LUIManager:RegistMsg(script,msgs)
end


function LUIBase:UnRegistSelf(script, msgs)
    LUIManager:UnRegistMsg(script, msgs)
end

function LUIBase:SendMsg(msg)
    LUIManager:SendMsg(msg)
end

function LUIBase:ProcessEvent(tmpMsg)
   --
end

function LUIBase:DeleteIntaractCObj()
    -- for i, v in pairs(self.intaractCObjs) do--迭代
    --     if v then
    --         ScriptHandlerMgr:getInstance():removeObjectAllHandlers(v)
    --         v:release()
    --         self.intaractCObjs[i] = nil
    --     end
    -- end 
    -- self.intaractCObjs = nil
end

function LUIBase:Destory()
    
    self:UnRegistSelf(self, self.msgIds)
    self.msgIds = nil
    self:DeleteIntaractCObj()
--    self.csbFilePath = nil
--    self.isUseResBuffer = nil--是否使用统一的加载接口加载csb
    if self.loadImageKey then
        for k,v in pairs(self.loadImageKey) do
            local _ = k and Utils:UnbindAsyncImg(k)
            self.loadImageKey[k] = nil
        end
    end
    if self.m_pUILayer then
        self.m_pUILayer:unregisterScriptHandler()
    end
    self.loadImageKey = nil
    self.Script = nil
    --self.m_pUILayer = nil
    self.csbFilePath = nil
    self.isUseResBuffer = nil--是否使用统一的加载接口加载csb
end

function LUIBase:OnEnter()
end

function LUIBase:RemoveUI()
	if Utils:ToBool(self.Script) then
        if LGameMsg.m_deleteUIMsg == nil then
            LGameMsg.m_deleteUIMsg = LUIInitMsg:New(LUILogicEvent.InitUI, 0)
        end
		LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.Script)
	    self:SendMsg(LGameMsg.m_deleteUIMsg)
	end
end

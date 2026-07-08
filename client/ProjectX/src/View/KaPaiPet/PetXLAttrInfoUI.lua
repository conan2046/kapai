
local PetXLAttrInfoUI = LUIBase:New()
PetXLAttrInfoUI.__index = PetXLAttrInfoUI
--local this = LTcpSocket
function PetXLAttrInfoUI:New(xlData)
	local o = LUIBase:New()
	setmetatable(o,PetXLAttrInfoUI)	
    o:Init(xlData)
	return o
end

--注册事件
-- -----------------------------------
function PetXLAttrInfoUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetXLAttrInfoUI:ProcessEvent(msg)

end

function PetXLAttrInfoUI:Init(xlData)

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongxiulian3.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData(xlData)
    self:initControlUI()
    self:updateUI()
end

function PetXLAttrInfoUI:initData(xlData)
    -- body
    self._curXllv = xlData.curXLLv
    self._xlInfo = xlData.xlInfo
    print("PetJiHuoSucUI:updateData ====>", self._curXllv)
end

function PetXLAttrInfoUI:initControlUI( ... )
    -- body
    local Popup = self.m_pUILayer:getChildByName("Popup")
    local Btn_close = Popup:getChildByName("Btn_close")
    Btn_close:addClickEventListener(function ( sender )
        -- body
        self:CloseUI()
    end)
    ------------------------------------------------------------
    local ListView = Popup:getChildByName("ListView_1")
    local Content_1 = ListView:getChildByName("Content_1")
    self._xlAttrArr = {}
    for i=1, 4 do
        local Atrribute = Content_1:getChildByName("Atrribute_"..i)
        table.insert(self._xlAttrArr, Atrribute)
    end
    local Content_2 = ListView:getChildByName("Content_2")
    self._jhJCArr = {}
    for i=1, 4 do
        local jhAttr = Content_2:getChildByName("Atrribute_"..i)
        table.insert(self._jhJCArr, jhAttr)
    end
    local Content_3 = ListView:getChildByName("Content_3")
    self._SkillAttrCell = Content_3:getChildByName("Atrribute_1")
    self._SkillAttrCell:setVisible(false)
end

function PetXLAttrInfoUI:updateUI( ... )
    -- body
    --计算属性
    local attrValue = {0, 0, 0, 0}
    local cfg = JsonConfig.m_config.getDefByID(23)
    local addAttrArr = json.decode("[".. cfg.value .. "]", 1)
    local tmJC = 0
    local openSkill = {}

    for i=1, self._curXllv do
        local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(i)

        for j=1, #attrValue do
            attrValue[j] = xiulian.cost_type * addAttrArr[j][2] + attrValue[j]
        end
        
        --天命加成
        tmJC = tmJC + xiulian.attr[1][3]

        if #xiulian.attr > 4 then
            local extraData = xiulian.attr[5]
            openSkill[extraData[2]] = extraData[3]
        end
    end
    --当前的加成
    for k=1, #attrValue do
        attrValue[k] = attrValue[k] + self._xlInfo[k] * addAttrArr[k][2]
        local attrName = Utils:getAttrName(k)
        local addAttrArr = attrName .. "+" .. attrValue[k]
        self._xlAttrArr[k]:setString(addAttrArr)

        local attrName = Utils:getAttrName(k + 9)
        local addStr = attrName .. "+" .. (tmJC/ 100) .. "%"
        self._jhJCArr[k]:setString(addStr)
    end

    local index = 0

    for k,v in pairs(openSkill) do
        local attrStr = LDataConstMgr:GetHeroSkillDesc(k, v)
        local SkillAttr = Utils:CreateColorText3(self._SkillAttrCell, false)
        SkillAttr:setVisible(true)
        SkillAttr:setPositionY(SkillAttr:getPositionY() - index * 30)
        SkillAttr:setString(attrStr)
        index = index + 1
    end

end

function PetXLAttrInfoUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.PetXLAttrInfoUI")
end

function PetXLAttrInfoUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetXLAttrInfoUI
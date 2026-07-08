
local PetJiHuoSucSecUI = LUIBase:New()
PetJiHuoSucSecUI.__index = PetJiHuoSucSecUI
--local this = LTcpSocket
function PetJiHuoSucSecUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetJiHuoSucSecUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetJiHuoSucSecUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetJiHuoSucSecUI:ProcessEvent(msg)

end

function PetJiHuoSucSecUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongxiulian2.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()

    self:initControlUI()
    self._curSelect = 11
end

function PetJiHuoSucSecUI:updateData( data )
    -- body
    self._curXllv = data.curXLLv
    self._xlInfo = data.xlInfo

    self:updateUI()
end

function PetJiHuoSucSecUI:initControlUI( ... )

    local shenjaingxiiuliantanchuang = self.m_pUILayer:getChildByName("shenjaingxiiuliantanchuang")
    local Popup = shenjaingxiiuliantanchuang:getChildByName("Popup")

    local Panel_xing = Popup:getChildByName("Panel_xing")
    self._PCell = Panel_xing:getChildByName("Button")

    self._nodeArr = {}
    for i=1, 20 do
        local Node = Panel_xing:getChildByName("Node_"..i)
        table.insert(self._nodeArr, Node)
    end
    ---------------------------------------------------------------------
    local Button = Popup:getChildByName("Button")
    Button:addClickEventListener(function ( sender )
        -- body
        local xlData = {}
        xlData.curXLLv = self._curXllv
        xlData.xlInfo = self._xlInfo
        Utils:InitUI("KaPaiPet.PetXLAttrInfoUI", AppDef.UIType.PopWindow, xlData)
    end)
    ---------------------------------------------------------------------
    self._Panel_di = Popup:getChildByName("Panel_di")

    self._attrArr = {}
    for i=1, 4  do
        local arr = self._Panel_di:getChildByName("txt_"..i)
        table.insert(self._attrArr, arr)
    end

    self._extraStr = self._Panel_di:getChildByName("txt_5")
    local desStr = self._extraStr:getChildByName("txt_5_0")
    Utils:CreateColorText3(desStr, true)
end

function PetJiHuoSucSecUI:updateUI( ... )
    -- body
    for i=11, 20 do
        local item = self._PCell:clone()
        item:setTag(i)
        item:addClickEventListener(handler(self, PetJiHuoSucSecUI.clickEvent))
        item:setPosition(cc.p(0, 0))
        self._nodeArr[i]:addChild(item)

        local Image_choose = item:getChildByName("Image_choose")
        if i == self._curSelect then
            Image_choose:setVisible(true)
            self._lastSelect = Image_choose
        else
            Image_choose:setVisible(false)
        end

        local image1 = item:getChildByName("Image_bg_1")
        local text1 = image1:getChildByName("txt_1")
        local image2 = item:getChildByName("Image_bg_2")
        local text2 = image2:getChildByName("txt_1")
        if i > self._curXllv then
            image1:setVisible(false)
            image2:setVisible(true)
        else
            image1:setVisible(true)
            image2:setVisible(false)
        end

        local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(i)
        if xiulian then
            text1:setString(xiulian.name)
            text2:setString(xiulian.name)
        end

    end
    self:ShowTianMingInfo()
end

function PetJiHuoSucSecUI:clickEvent( sender )
    -- body
    if self._lastSelect then
        self._lastSelect:setVisible(false)
    end
    local curChoose = sender:getChildByName("Image_choose")
    curChoose:setVisible(true)
    self._lastSelect = curChoose
    local tag = sender:getTag()
    self._curSelect = tag
    self:ShowTianMingInfo()
end

function PetJiHuoSucSecUI:ShowTianMingInfo( ... )
    -- body
    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(self._curSelect)
    if xiulian == nil then
        return
    end

    for i=1, #self._attrArr do
        local arr = self._attrArr[i]
        local attrName = Utils:getAttrName(xiulian.attr[i][2])
        local addStr = "+" .. (xiulian.attr[1][3]/ 100) .. "%"
        local addAttrStr = attrName .. addStr
        arr:setString(addAttrStr)
    end

    local extraStr = PetkaPaiManager:getXLExtraAttrStr(self._curSelect)
    if string.len(extraStr) > 0 then
        self._extraStr:setVisible(true)
        local value =  self._extraStr:getChildByName("txt_5_0")
        value:setString(extraStr)
    else
        self._extraStr:setVisible(false)
    end
end

function PetJiHuoSucSecUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.PetJiHuoSucSecUI")
end

function PetJiHuoSucSecUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetJiHuoSucSecUI
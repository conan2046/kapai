
local PetJiHuoSucUI = LUIBase:New()
PetJiHuoSucUI.__index = PetJiHuoSucUI
--local this = LTcpSocket
function PetJiHuoSucUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetJiHuoSucUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetJiHuoSucUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetJiHuoSucUI:ProcessEvent(msg)

end

function PetJiHuoSucUI:Init()

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
    self._curSelect = 1
end

function PetJiHuoSucUI:updateData( data )
    -- body
    self._curXllv = data.curXLLv
    self._xlInfo = data.xlInfo
    self._isPlayEffect = data.unLockIM or false
    print("PetJiHuoSucUI:updateData ====>", self._curXllv)
    self:updateUI()
end

function PetJiHuoSucUI:initControlUI( ... )

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

function PetJiHuoSucUI:updateUI( ... )
    -- body
    for i=1, 10 do
        local item = self._PCell:clone()
        item:setTag(i)
        item:addClickEventListener(handler(self, PetJiHuoSucUI.clickEvent))
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
        elseif i == self._curXllv then
            if self._isPlayEffect then
                self:OpenTianMingJH(self._nodeArr[i])
            end
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

function PetJiHuoSucUI:OpenTianMingJH(parent)
    -- body
    local function afterEffect( ... )
            -- body        
    end
    PetkaPaiManager:CreatEffect(parent, "effect_shenjiangyangcheng_6", 1.5, afterEffect)
end

function PetJiHuoSucUI:clickEvent( sender )
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

function PetJiHuoSucUI:ShowTianMingInfo( ... )
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

function PetJiHuoSucUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.PetJiHuoSucUI")
end

function PetJiHuoSucUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetJiHuoSucUI
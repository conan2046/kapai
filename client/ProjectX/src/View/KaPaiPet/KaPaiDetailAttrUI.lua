
local KaPaiDetailAttrUI = LUIBase:New()
KaPaiDetailAttrUI.__index = KaPaiDetailAttrUI
--local this = LTcpSocket
function KaPaiDetailAttrUI:New(id)
	local o = LUIBase:New()
	setmetatable(o,KaPaiDetailAttrUI)	
    o:Init(id)
	return o
end

--注册事件
-- -----------------------------------
function KaPaiDetailAttrUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function KaPaiDetailAttrUI:ProcessEvent(msg)

end

function KaPaiDetailAttrUI:Init(id)
    --self.m_pId=id
    self.petData=LRoleDataMgr.Pet:GetPetById(id)
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/shenjiangxiangxishuxing.csb")
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
end

function KaPaiDetailAttrUI:initControlUI( ... )
    -- body
    local Mask_close = self.m_pUILayer:getChildByName("Mask_close")
    Mask_close:addClickEventListener(function ( sender )
        -- body
        self:CloseUI()
    end)
    self.m_Icon=self.m_pUILayer:findChildByName("Node_1/Popup/Icon")
    self.m_Name=self.m_Icon:getChildByName("name")
    self.m_ZhanLi=self.m_Icon:findChildByName("text_zhanli/num")
    self.m_DingWei=self.m_Icon:findChildByName("text_dingwei/num")
    self.m_ListView=self.m_pUILayer:findChildByName("Node_1/Popup/ListView")
    self.m_ListView:setClippingEnabled(true)
    self.m_cell= self.m_ListView:findChildByName("name")
    self.m_cell:setName("name"..1)
    self:setInfo()
end

function KaPaiDetailAttrUI:CheckAttrs(id)

    if id>50 or id==5 or id==18 or id==24 or id==27 or id==30  then
        return false
    end
    return true


    

   
end

function KaPaiDetailAttrUI:setInfo()
    self.m_Name:setString(self.petData.name)
    Utils:ShowPetHeadImg(self.m_Icon,self.petData.baseData.pic,nil,self.petData.baseData.quality, PetkaPaiManager:IsShiny(self.petData.baseData))
    self.m_ZhanLi:setString(Utils:getPowerStr(self.petData.zhandouli))
    self.m_DingWei:setString(self.petData.baseData.feature)
    for k,v in pairs(self.petData.attrs) do
        if self:CheckAttrs(k) then
            local cell = self.m_ListView:getChildByName("name"..tostring(k))
            if cell==nil then
                cell=self.m_cell:clone()
                cell:setString("name"..tostring(k))
                self.m_ListView:addChild(cell)
            end  
            local tempName,tempValue = Utils:getAttrNameAndValue1(k,v)
            cell:setString(tempName..":")
            cell:getChildByName("value"):setString(tempValue)


        end
      
       
    end
end
function KaPaiDetailAttrUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.KaPaiDetailAttrUI")
end

function KaPaiDetailAttrUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return KaPaiDetailAttrUI
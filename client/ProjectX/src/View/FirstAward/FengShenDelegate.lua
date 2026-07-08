local NomalCopyDelegate = require("View.FirstAward.NomalCopyDelegate")
local FengShenDelegate = NomalCopyDelegate:New()
FengShenDelegate.__index = FengShenDelegate

----------------------------------------------
function FengShenDelegate:New()
    local o = {}
    setmetatable(o, FengShenDelegate)
    o:Init()
    return o
end

function FengShenDelegate:UpdateSelfUI()
	if self.m_data == nil or self.m_data.star == nil or self.m_pUILayer == nil then
		return
	end
	local pStarList = self.m_pUILayer:getChildByName("StarsList")
	pStarList:setVisible(true)
	local items = pStarList:getItems()
	for i=1,3 do
		items[i]:setVisible(i <= self.m_data.star)
	end
	local pText = self.m_pUILayer:getChildByName("Text")
	pText:setVisible(false)
end

function FengShenDelegate:GetBtnClick(sender)
    self.m_pUI:RemoveUI()
end

return FengShenDelegate
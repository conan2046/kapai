local RedDotItem = require("View.ImproveUI.RedDotItem")

local RedDotSystem = LUIBase:New()
RedDotSystem.__index = RedDotSystem
-------------------------------------------
function RedDotSystem:New()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:Init()
    return o
end
-----------------------------------
function RedDotSystem:Init()
	----------------------------------------------
	self.m_itemMap = {}
	self.m_root = nil
	----------------------------------------------
	self:initConfig()
	self:RegistMsgs()
end
-----------------------------------
function RedDotSystem:onExit()
    self:Destory()
    for k,v in pairs(self.m_itemMap) do
    	if self.m_itemMap[k] and self.m_itemMap[k].onExit then
    		self.m_itemMap[k]:onExit()
    		self.m_itemMap[k] = nil
    	end
    end
    self.m_itemMap = nil
    self.m_root = nil
end
-----------------------------------
function RedDotSystem:RegistMsgs()
    self.msgIds = 
    {
    	LUIRedDotEvent.RegisterRedDot,
    	LUIRedDotEvent.SetRedDotState,
    	LUIRedDotEvent.GetRedDotState,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function RedDotSystem:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.SetRedDotState then
    	self:DealSetRedDotState(msg.value)
    elseif msg.msgId == LUIRedDotEvent.GetRedDotState then
    	self:DealGetRedDotState(msg.value)
    elseif msg.msgId == LUIRedDotEvent.RegisterRedDot then
    	self:DealRegisterRedDot(msg.value)
    end
end
-----------------------------------
function RedDotSystem:_RegisterItem(id, parentItem, pid)
	if id == nil then
		return nil
	end
	if pid then
		parentItem = self.m_itemMap[pid]
	end
	if parentItem == nil then
		return nil
	end
	if self.m_itemMap[id] then
		return nil
	end
	local item = RedDotItem:New(id)
	if parentItem then
		parentItem:addChild(item)
	end
	self.m_itemMap[id] = item
	return item
end
-----------------------------------
function RedDotSystem:initFriendConfig()
	local pRoot 		= self:_RegisterItem(RedDotDef.ID.Friend, self.m_root);

	self:_RegisterItem(RedDotDef.ID.FriendApply, pRoot);
	self:_RegisterItem(RedDotDef.ID.FriendGift, pRoot);
end

function RedDotSystem:initMailConfig()
	local pRoot = self:_RegisterItem(RedDotDef.ID.Mail, self.m_root);

	self:_RegisterItem(RedDotDef.ID.MailNew, pRoot);
end

function RedDotSystem:initChatConfig()
	local pRoot = self:_RegisterItem(RedDotDef.ID.Chat, self.m_root);
	self:_RegisterItem(RedDotDef.ID.Chat_Private, pRoot);
end

function RedDotSystem:initFuliConfig( ... )
	-- body
	local pRoot = self:_RegisterItem(RedDotDef.ID.Fuli, self.m_root);
	self:_RegisterItem(RedDotDef.ID.Fuli_Tili, pRoot);
	self:_RegisterItem(RedDotDef.ID.Fuli_ResRecovery, pRoot);
end

function RedDotSystem:initDaliyTaskConfig()
	local pRoot = self:_RegisterItem(RedDotDef.ID.DaliyTask, self.m_root);
	-- self:_RegisterItem(RedDotDef.ID.Fuli_Tili, pRoot);
	-- self:_RegisterItem(RedDotDef.ID.Fuli_ResRecovery, pRoot);
end

function RedDotSystem:initConfig()
	self.m_root = RedDotItem:New(0)
	self:initFriendConfig();
	self:initMailConfig();
	self:initChatConfig();
	self:initFuliConfig();
	self:initDaliyTaskConfig();
	----------------------------------------------------------
	local pBPRoot 		= self:_RegisterItem(RedDotDef.ID.BangPai, self.m_root)
	
	local pBPXinXi 	= self:_RegisterItem(RedDotDef.ID.BPXinXi, pBPRoot)

	local pBPFuBen = self:_RegisterItem(RedDotDef.ID.BPFuben, pBPXinXi)
	
	local pBPSkillUpgrade 	= self:_RegisterItem(RedDotDef.ID.BPSkillUpgrade, pBPFuBen)

	local pBPChengYuan 	= self:_RegisterItem(RedDotDef.ID.BPChengYuan, pBPXinXi)
	local pBPShiJian 	= self:_RegisterItem(RedDotDef.ID.BPShiJian, pBPXinXi)
	local pBPJiangLi 	= self:_RegisterItem(RedDotDef.ID.BPJiangLi, pBPXinXi)
	local pBPFuBenJiangLi 	= self:_RegisterItem(RedDotDef.ID.BPFubenJiangLi, pBPFuBen)
	-- local pBPHuoDong 	= self:_RegisterItem(RedDotDef.ID.BPHuoDong, pBPXinXi)
	
	local pBPXiuLian = self:_RegisterItem(RedDotDef.ID.BPXiuLian, pBPXinXi)
	
	local _ 			= self:_RegisterItem(RedDotDef.ID.BPShenQing, pBPChengYuan)
	local _ 			= self:_RegisterItem(RedDotDef.ID.BPZongHuoYueDu, pBPXinXi)

	----------------------------------------------------------
	local pYuYiRoot 	= self:_RegisterItem(RedDotDef.ID.YuYi, self.m_root)
	local pYuYiXinXi 	= self:_RegisterItem(RedDotDef.ID.YuYiXinXi, pYuYiRoot)
	local pYuYiJinJie 	= self:_RegisterItem(RedDotDef.ID.YuYiJinJie, pYuYiRoot)
	local _ 			= self:_RegisterItem(RedDotDef.ID.YuYiJJPeiYang, pYuYiJinJie)

	----------------------------------------------------------
	local _ 			= self:_RegisterItem(RedDotDef.ID.HuoDong, self.m_root)
	----------------------------------------------------------

		--副本
	local fuBenMap = self:_RegisterItem(RedDotDef.ID.FuBenMap, self.m_root)
	local pFengSheng 	= self:_RegisterItem(RedDotDef.ID.FengShengShiLian, fuBenMap)
	
	--副本成就
	local _ = self:_RegisterItem(RedDotDef.ID.FuBenAchievement, fuBenMap)

	local _ 			= self:_RegisterItem(RedDotDef.ID.FengShengTab1, pFengSheng)
	local _ 			= self:_RegisterItem(RedDotDef.ID.FengShengTab2, pFengSheng)
	local _ 			= self:_RegisterItem(RedDotDef.ID.FengShengTab3, pFengSheng)
	local _ 			= self:_RegisterItem(RedDotDef.ID.FengShengTab4, pFengSheng)
	------------------------------------------------------------------------------------------
	--穿戴
	local pChuanDai = self:_RegisterItem(RedDotDef.ID.ChuanDai, self.m_root)
	--装备
    local pZhuangBei    = self:_RegisterItem(RedDotDef.ID.ZhuangBei, pChuanDai)
    local _             = self:_RegisterItem(RedDotDef.ID.ZBBeiBao, pZhuangBei)
    local _             = self:_RegisterItem(RedDotDef.ID.ZBSuiPian, pZhuangBei)
	--法宝
	local pFaBao    = self:_RegisterItem(RedDotDef.ID.FaBao, pChuanDai)
    local _             = self:_RegisterItem(RedDotDef.ID.FBBeiBao, pFaBao)
    local _             = self:_RegisterItem(RedDotDef.ID.FBSuiPian, pFaBao)
    -------------------------------------------------------------------------------------------
    --神将背包
	local pShenJiangPet 		= self:_RegisterItem(RedDotDef.ID.ShenjiangBag, self.m_root)
	local pShenjiangTag 	= self:_RegisterItem(RedDotDef.ID.Shenjiang_tag, pShenJiangPet)
	local pShuiPianTag 	   = self:_RegisterItem(RedDotDef.ID.ShuiPian_tag, pShenJiangPet)
	local pShenJiangTuJian = self:_RegisterItem(RedDotDef.ID.ShenJiangTuJian,pShenJiangPet)

	---------------------------------------------------------------------------------------------
	--阵容
	local pShenJiangZhenRong = self:_RegisterItem(RedDotDef.ID.ShenJiangZhenRong, self.m_root)
	local pShenJiangYangCheng = self:_RegisterItem(RedDotDef.ID.ShenJiangYangCheng, pShenJiangZhenRong)

	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_LVUp, pShenJiangYangCheng)
	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_StarUp, pShenJiangYangCheng)
	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_BreakUp, pShenJiangYangCheng)
	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_BuZhen, pShenJiangYangCheng)
	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_XiuLian, pShenJiangYangCheng)

	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_ShangZhen, pShenJiangZhenRong)
	local _ = self:_RegisterItem(RedDotDef.ID.ShenJiang_Change, pShenJiangZhenRong)

	--装备养成
	local _  = self:_RegisterItem(RedDotDef.ID.EquipShengJiang1, pShenJiangZhenRong)
	local _  = self:_RegisterItem(RedDotDef.ID.EquipShengJiang2, pShenJiangZhenRong)
	local _  = self:_RegisterItem(RedDotDef.ID.EquipShengJiang3, pShenJiangZhenRong)
	local _  = self:_RegisterItem(RedDotDef.ID.EquipShengJiang4, pShenJiangZhenRong)
	local _  = self:_RegisterItem(RedDotDef.ID.EquipShengJiang5, pShenJiangZhenRong)
	
	

	--------------------------------------------------------------------------------------------
	--抽卡
	local pHappyDraw = self:_RegisterItem(RedDotDef.ID.HappyDraw, self.m_root)

	local _  = self:_RegisterItem(RedDotDef.ID.HD_Normal_DanCi, pHappyDraw)
	local _ = self:_RegisterItem(RedDotDef.ID.HD_Normal_ShiLian, pHappyDraw)
	
	local _ = self:_RegisterItem(RedDotDef.ID.HD_GaoJi_DanCi, pHappyDraw)
	local _  = self:_RegisterItem(RedDotDef.ID.HD_GaoJi_ShiLian, pHappyDraw)

	local _ = self:_RegisterItem(RedDotDef.ID.HD_FriendLy_DanCi, pHappyDraw)
	local _ = self:_RegisterItem(RedDotDef.ID.HD_FriendLy_ShiLian, pHappyDraw)

	---------------------------------------------------------------------------------
	--七日活动
	local _ = self:_RegisterItem(RedDotDef.ID.QiRiActivity, self.m_root)
	--玩法
	local pWanFa 		= self:_RegisterItem(RedDotDef.ID.WanFa, self.m_root)
	--昆仑决战
	local _ 			= self:_RegisterItem(RedDotDef.ID.KunLunJueZhan, pWanFa)
	-----------------------------------------------------------------------------------
	--竞技场
	local _ = self:_RegisterItem(RedDotDef.ID.ArenaTask, pWanFa)
	local _ = self:_RegisterItem(RedDotDef.ID.AreanReport, self.m_root)
	--血战
	local _ = self:_RegisterItem(RedDotDef.ID.XueZhanDraw, pWanFa)
	--寻宝
	local xunBao = self:_RegisterItem(RedDotDef.ID.XunBao, pWanFa)
	local _ = self:_RegisterItem(RedDotDef.ID.XunBaoTask, xunBao)
	local _ = self:_RegisterItem(RedDotDef.ID.XunBaoHeCheng, xunBao)
	---------------------------------------------------------------------------------
	--商店
	local MainShop = self:_RegisterItem(RedDotDef.ID.ShopMain, self.m_root)
	local JianghunShop = self:_RegisterItem(RedDotDef.ID.ShopJiangHun, MainShop)
	local ShopWanFa = self:_RegisterItem(RedDotDef.ID.ShopWanFa, MainShop)

	local _ = self:_RegisterItem(RedDotDef.ID.ShopWanFaJingji, ShopWanFa)
	local _ = self:_RegisterItem(RedDotDef.ID.ShopWanFaXueZhan, ShopWanFa)
	------------------------------------------------------
end
-----------------------------------
function RedDotSystem:DealGetRedDotState(ret)
	ret = ret or {}
	local id = ret.id
	if id and self.m_itemMap[id] then
		ret.isShow = self.m_itemMap[id]:isShown()
	else
		ret.isShow = false
	end
end
-----------------------------------
function RedDotSystem:DealSetRedDotState(ret)
	if ret == nil or type(ret) ~= "table" or ret.id == nil then
		return
	end
	------------------------------------------
	local id = ret.id
	local isShow = Utils:ToBool(ret.isShow)
	------------------------------------------
	local item = self.m_itemMap[id]
	if item == nil then
		return
	end
	------------------------------------------
	local ids = item:setShown(isShow)
	if ids then
		for i=1,#ids do
			local itemId = ids[i]
			if itemId > 0 then
				local isItemShow = self.m_itemMap[itemId]:isShown()
				local data = {id=itemId, isShow=isItemShow}
				Utils:SendMsg(LUIRedDotEvent.UpdateRedDotState, data, true)
			end
		end
	end
end

function RedDotSystem:DealRegisterRedDot(ret)
	local id,pid = ret.id,ret.pid
	self:_RegisterItem(id, nil, pid)
end

function RedDotSystem:Reset()
	if self.m_root then
		self.m_root:Reset()
	end
end

return RedDotSystem
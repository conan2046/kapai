--社交系统
LCSocial = {}
LCSocial.__index = LCSocial
function LCSocial:New()
	local o = {}
	setmetatable(o, LCSocial)	
    
	o:Init()
	return o
end

function LCSocial:Init()

    self.NewMailData = {}   --未领取邮件列表
    self.OldMailData = {}   --已领取邮件列表

    self.TmpChatList = {}		   --私聊列表
    self.FriendData = {}            --好友信息
    self._friendApplyList = {}--好友申请列表
    self.CoupleList = {}            --夫妻信息
    self.BlackList = {}             --黑名单
    self.RecommendList = {}--推荐好友
    self._friendGiftList = {}--礼物列表
    self._friendMaxGetGift = 0--最大收几次礼物
    self._friendGetGiftLeft = 0--还可以收几次礼物
    self._maxFriendNum = 0;--最大好友数量
    self._maxApplyNum = 0;--最大好友申请数量

    self.MasterInfo = LFriendsData:New()				--师徒中师父的信息（徒弟or师父）
    self.PupilList = {}				--师徒信息

    self.CoupleInfo = LCoupleData:New()				--夫妻信息
    self._isInfriend = false
end

function LCSocial:Reset()

    self.NewMailData = {}   --未领取邮件列表
    self.OldMailData = {}   --已领取邮件列表
    self.RecommendList = {}--推荐好友
    self.TmpChatList = {}          --私聊列表
    self.FriendData = {}            --好友信息
    self._friendApplyList = {}
    self._friendGiftList = {}--礼物列表
    self._friendMaxGetGift = 0
    self._friendGetGiftLeft = 0--还可以收几次礼物
    self._maxFriendNum = 0;
    self._maxApplyNum = 0;
    self.CoupleList = {}            --夫妻信息
    self.BlackList = {}             --黑名单

    self.MasterInfo = LFriendsData:New()                --师徒中师父的信息（徒弟or师父）
    self.PupilList = {}             --师徒信息

    self.CoupleInfo = LCoupleData:New()             --夫妻信息
    self._isInfriend = false
end

function LCSocial:Delete()
    self.NewMailData = nil
    self.OldMailData = nil
    self.TmpChatList = nil
    self.FriendData = nil
    self._friendApplyList = nil
    self.CoupleList = nil
    self.BlackList = nil
    self.MasterInfo = nil
    self.PupilList = nil
    self.CoupleInfo = nil
    self._isInfriend = nil
end

function LCSocial:AddPcChatMsg(fromid, tarid, msg)	--添加私聊信息
    local isFound = false;
    for i = 1, #self.TmpChatList do
        if self.TmpChatList[i].id == fromid or self.TmpChatList[i].id == tarid then
            table.insert(self.TmpChatList[i].msgList, msg)
            local userId = LRoleDataMgr.MyHeroInfo.id
            self.TmpChatList[i].msgUread = (msg.sendId ~= userId)
            --好友信息不更新，如果收到信息则认为在线，（默认1000）
            self.TmpChatList[i].mapId = 1000
            isFound = true;
            if i > 1 then
                local data = self.TmpChatList[i];
                table.remove(self.TmpChatList,i)
                table.insert(self.TmpChatList,1,data)
            end
            break
        end
    end

    if isFound == true then
        Utils:SendMsg(LUISocialEvent.updateFriendLayer)
        return
    end
    --陌生人消息

    local data = LFriendsData:New()
    data.id = msg.sendId
    data.level = msg.sendLv
    data.head = msg.sendProf
    data.sex = msg.sendSex
    data.name = msg.sendName
    data.mapId = LRoleDataMgr.MyHeroInfo.mid


--              data.msgList.push_back(msg)
    table.insert(data.msgList, msg)

    data.msgUread = (msg.sendId ~= LRoleDataMgr.MyHeroInfo.id)
--              TmpChatList.push_back(data)
    table.insert(self.TmpChatList, 1, data)
    Utils:SendMsg(LUISocialEvent.updateFriendLayer)
    -- --刷新界面
    -- if not self._isInfriend then
    --     self:SortFriendList()
    -- end

end

function LCSocial:addATmpChatList(data)
    if data == nil or data.id == nil then
        return false
    end

    -- local data = LRoleDataMgr.OtherHeroInfo
    -- if data == nil or data.id == nil or data.id == 0 or data.roleType == 1 then
    --     return
    -- end


    local ind = self:FindFriend(data.id, self.TmpChatList)
    if ind < 0 then
        local strangerData = LFriendsData:New()
        strangerData.id = data.id
        strangerData.level = data.level
        strangerData.head = data.head
        strangerData.name = data.name
        strangerData.msgList = {}
        strangerData.msgUread = false
        table.insert(self.TmpChatList, strangerData)
        return true
    end
    return false
end

function LCSocial:updateTmpReadMsgData(id, isRead)
    -- body
    for i = 1, #self.TmpChatList do
        if self.TmpChatList[i].id == id then
            self.TmpChatList[i].msgUread = isRead
            break
        end
    end
end

function LCSocial:updateFriendReadMsgData(id, isRead)
    -- body
    for i = 1, #self.FriendData do
        if self.FriendData[i].id == id then
            self.FriendData[i].msgUread = isRead
            break
        end
    end
    Utils:SetRedDotState(RedDotDef.ID.Chat_Private, LRedDotCheckMgr:ChatCheck());
end

--[[
不需要了
]]
function LCSocial:UpdateTmpChatList(fromId, msg)		--更新私聊列表
 --    if #self.TmpChatList <= 0 then
 --        local Gm = LFriendsData:New()
	-- 	Gm.id = 0
	-- 	Gm.name = GUITips.RSI_UI_TITLE_SYSTEMONLINE
 --        table.insert(self.TmpChatList, Gm)
	-- end

    --[[
    cMsg.sendId = stream:ReadUInt()
    cMsg.sendName = stream:ReadString()
    cMsg.sendVip = stream:ReadByte()
    cMsg.sendProf = stream:ReadByte()
    cMsg.sendSex = stream:ReadByte()
    cMsg.sendLv = stream:ReadWord()
    cMsg.sendTeamId = stream:ReadUInt()
    cMsg.sendFactionId = stream:ReadUInt()
    cMsg.revId = stream:ReadUInt()
    cMsg.time = stream:ReadUInt()
    cMsg.msg = stream:ReadString()
    ]]
	--如果是我发的消息 查找接收者
    local userId = LRoleDataMgr.MyHeroInfo.id
    local IsFriend = false
	if fromId == userId then
		local revId = msg.revId
		local idx = self:FindFriend(revId, self.FriendData)
		if idx > 0 then
			IsFriend = true
			self.FriendData[idx].roleType = 0
			local tpidx = self:FindFriend(revId, self.TmpChatList)
			if tpidx > 0 then
                self.TmpChatList[tpidx] = self.FriendData[idx]
                self.TmpChatList[tpidx].msgUread = true
            end
		end

		if false == IsFriend then
			idx = self:FindFriend(revId, self.TmpChatList)
			if idx > 0 then
                table.insert(self.TmpChatList[idx].msgList, msg)
            end
		end
	
	else
	
		local idx = self:FindFriend(fromId, self.FriendData)
		if idx > 0 then
			IsFriend = true
			self.FriendData[idx].roleType = 0
			local tpidx = self:FindFriend(fromId, self.TmpChatList)
			if tpidx > 0 then
                self.TmpChatList[tpidx] = self.FriendData[idx]
                self.TmpChatList[tpidx].msgUread = true
			else
                table.insert(self.TmpChatList, self.FriendData[idx])
            end
		end

		--更新到私聊列表
        local isNew = false
		if false == IsFriend then
			idx = self:FindFriend(fromId, self.TmpChatList)
			if idx > 0 then
				IsFriend = true
                table.insert(self.TmpChatList[idx].msgList, msg)
				self.TmpChatList[idx].msgUread =  string.len(msg.msg) > 0
			else
                local data = LFriendsData:New()
				data.id = fromId
				data.level = msg.sendLv
				data.head = msg.sendProf
				data.sex = msg.sendSex
				data.name = msg.sendName
				data.mapId = LRoleDataMgr.MyHeroInfo.mid


--				data.msgList.push_back(msg)
                table.insert(data.msgList, msg)

				data.msgUread = string.len(msg.msg) > 0
--				TmpChatList.push_back(data)
                table.insert(self.TmpChatList, data)
                isNew = true
                
			end
		end
	end

	self:SortTmpChatList(self.TmpChatList)
    if isNew then
        Utils:SendMsg(LUISocialEvent.updateFriendLayer)
    end

end

function LCSocial:SortTmpChatList()
    -- body
    local function big_mid(m1, m2)
        if m1.mapId > m2.mapId then
            return true
        elseif m1.mapId == m2.mapId then
            return m1.qingMiDu > m2.qingMiDu
        else
            return false
        end
    end

    local gmData = self.TmpChatList[1]
    table.remove(self.TmpChatList, 1)
    table.sort(self.TmpChatList, big_mid)
    table.insert(self.TmpChatList, 1, gmData)
end

function LCSocial:IsMyFriend(id)
    local ind = self:FindFriend(id,self.FriendData)
    if ind < 0 then
        return false;
    end
    return true;
end

function LCSocial:GetMyFriendData(id)
    local ind = self:FindFriend(id,self.FriendData)
    if ind < 0 then
        return nil;
    end
    return self.FriendData[ind];
end

function LCSocial:GetChatFriendData(id)
    local ind = self:FindFriend(id,self.TmpChatList)
    if ind < 0 then
        return nil;
    end
    return self.TmpChatList[ind];
end

function LCSocial:IsInBlack(id)
    local ind = self:FindFriend(id,self.BlackList)
    if ind < 0 then
        return false;
    end
    return true;
end

function LCSocial:DelBlack(id)
    -- body
    local idx = self:FindFriend(id, self.BlackList)
    if idx < 0 then
        return
    end

    table.remove(self.BlackList, idx)
end

function  LCSocial:GetFriendIdByIndex(idx)
    
    if idx + 1 > #self.FriendData then
        return -1
    end

    local oneData = self.FriendData[idx + 1]
    return oneData.id
end

function LCSocial:delFriend(id)
	-- body
	local idx = self:FindFriend(id, self.FriendData)
	if idx < 0 then
		return
	end

	table.remove(self.FriendData, idx)
end

function  LCSocial:FindFriend(fromId, friendList)	--按Id查找 返回idx

    if(friendList == nil) then
        return -1
    end

    for i = 1, #friendList do
        if friendList[i].id == fromId then
            return i
        end
    end
    return -1
end


function LCSocial:UpdateFriendList(id, data)

	local idx = self:FindFriend(id, self.FriendData)
	if idx > 0 then
    	self.FriendData[idx] = data
	else
        table.insert(self.FriendData, data)
    end
    
	self:SortFriendList()

end

function LCSocial:UpdateFriendApplyList(id, data)

    local idx = self:FindFriend(id, self._friendApplyList)
    --print("UpdateFriendApplyList",#self._friendApplyList, idx)
    if idx > 0 then
        self._friendApplyList[idx] = data
    else
        table.insert(self._friendApplyList, data)
    end
end

function LCSocial:CheckFriendApplyRedDot()
    local list = self:GetFriendApplyList()
    if not list or #list == 0 then
        Utils:SetRedDotState(RedDotDef.ID.FriendApply, false)
    end
end

function LCSocial:CheckFriendGiftRedDot()
    if not self._friendGiftList or #self._friendGiftList == 0 then
        Utils:SetRedDotState(RedDotDef.ID.FriendGift, false)
    end
end
function LCSocial:DeleteFriendApplyList(id)
    local idx = self:FindFriend(id, self._friendApplyList)
    if idx > 0 then
        table.remove(self._friendApplyList,idx);
        return true;
    else
        return false;
    end
end

function LCSocial:SortFriendList()
    local function big_mid(m1, m2)
        if m1 == nil or m2 == nil then
            return false
        end

        if m1.mapId == nil or m2.mapId == nil then
            return false
        end

        if m1.mapId == m2.mapId then
            if m1.qingMiDu == nil or m2.qingMiDu then
                return false
            end

            if m1.qingMiDu == m2.qingMiDu then
                return false
            end

            return m1.qingMiDu > m2.qingMiDu
        end

        return m1.mapId > m2.mapId
        
    end

    local gmData = self.FriendData[1]
    table.remove(self.FriendData, 1)
    table.sort(self.FriendData, big_mid)
    table.insert(self.FriendData, 1, gmData)
end

function  LCSocial:IsUnReadMsg()								--是否有未读信息 0没有1好友信息2私聊信息
    return self:HasFreindChatUnRead() or self:HasWaspChatUnRead()
end

function LCSocial:HasFreindChatUnRead( ... )
    -- body
    for  i=1, #self.FriendData do
        if self.FriendData[i].msgUread then
            return true
        end
    end
    return false
end

function LCSocial:HasWaspChatUnRead( ... )
    -- body
    for i=1, #self.TmpChatList do
        local idx = self:FindFriend(self.TmpChatList[i].id, self.FriendData)
        if idx < 0 then
            if self.TmpChatList[i].msgUread then
                return true
            end
        end
    end
    return false
end

function  LCSocial:IsShituAward()
    for i=1, #self.PupilList do
		if self.PupilList[i].msgUread then
			return 1
        end
    end

	return 0
end

function LCSocial:GetTmpChatList()      		--私聊列表
    return self.TmpChatList
end

function LCSocial:GetFriendData()                 --好友信息
    return self.FriendData
end

function LCSocial:SortFriendData()  --好友信息排序
    local function sortFuc(m1, m2)
        if m1.sendFlag == m2.sendFlag then
            return m1.offSecond < m2.offSecond
        else
            return m1.sendFlag < m2.sendFlag
        end
    end               
    table.sort(self.FriendData, sortFuc)
end

function LCSocial:DecodeFriendList(stream)
    local friendList = {}
    self.TmpChatList = {}
    self._maxFriendNum = stream:ReadByte();
    local num = stream:ReadByte()
    -- print("=------------------------ReadFriendList---------------------------------",num)
    for  i = 1, num do
        local data = LFriendsData:New()
        data:DecodeFromServer(stream);
        if string.len(data.name) > 0 then
            local idx = self:FindFriend(data.id, self.FriendData)
            if idx > 0 then
                data.msgList = self.FriendData[idx].msgList
                data.msgUread = self.FriendData[idx].msgUread
            end
            table.insert(friendList, data)
        end
        table.insert(self.TmpChatList, data)
    end
    self.FriendData = friendList;
end

function LCSocial:DecodeFriendGiftFromServer(stream)
    self._friendGiftList = {};
    self._friendMaxGetGift = stream:ReadByte();
    self._friendGetGiftLeft = stream:ReadByte();
    local num = stream:ReadByte();
    --print("DecodeFriendGiftFromServer",self._friendMaxGetGift,self._friendGetGiftLeft,num)
    for i = 1, num do
        local roleId = stream:ReadUInt();
        --print("roleId",roleId)
        local dataInd = self:FindFriend(roleId, self.FriendData)
        if dataInd > 0 then
            table.insert(self._friendGiftList,self.FriendData[dataInd]);
        end
    end
end

function LCSocial:DeleteFriendGift(roleId)
        --print("DeleteFriendGift",roleId)
    if not self._friendGiftList then
        return
    end
    for i = 1, #self._friendGiftList do
        if self._friendGiftList[i].id == roleId then
            table.remove(self._friendGiftList,i)
            break
        end
    end
end
function LCSocial:DecodeBlackList(stream)
    --[[
    op=12  maxNum   num   { roleId  roleName  level   sex   head   power  offSecond  bangpaiId  bangpaiName  }
    1byte  1byte   1byte    4byte    string   2byte  1byte  1byte  4byte    4byte      4byte      string
    ]]
    self.BlackList = {}
    local maxBlackNum = stream:ReadByte()
    local num = stream:ReadByte()
    --print("num",num)
    if num <= 0 then
        return false
    end

    for i = 1, num do
        local data = LFriendsData:New();
        data:DecodeBlackDataFromServer(stream);
        table.insert(self.BlackList, data);
    end
end

function LCSocial:DecodeRecommendList(stream)
    --[[
    op=15   num   { roleId  roleName  level   sex   head   power  offSecond  bangpaiId  bangpaiName  }
    1byte  1byte    4byte    string   2byte  1byte  1byte  4byte    4byte      4byte      string
    ]]
    
    local num = stream:ReadByte()
    if num <= 0 then
        return false
    end
    self.RecommendList = {}
    for i = 1, num do
        local data = LFriendsData:New();
        data:DecodeBlackDataFromServer(stream);
        table.insert(self.RecommendList, data);
    end
    return true
end

function LCSocial:DecodeApplyList(stream)
    --[[
    op=15   num   { roleId  roleName  level   sex   head   power  offSecond  bangpaiId  bangpaiName  }
    1byte  1byte    4byte    string   2byte  1byte  1byte  4byte    4byte      4byte      string
    ]]
    
    self._friendApplyList = {}
    self._maxApplyNum = stream:ReadByte();
    --print("=------------------------maxApplyNum---------------------------------",LRoleDataMgr.Social._maxApplyNum)
    local num = stream:ReadByte()
    --print("=------------------------DecodeApplyList---------------------------------",num)
    for  i = 1, num do
        local data = LFriendsData:New()
        data:DecodeApplyDataFromServer(stream);
        if string.len(data.name) > 0 then
            table.insert(self._friendApplyList, data)
        end
    end
end

function LCSocial:GetFriendGiftList()
    local function sortFuc(m1, m2)
        return m1.offSecond < m2.offSecond
    end 
    table.sort(self._friendGiftList, sortFuc)
    return self._friendGiftList
end

function LCSocial:GetFriendApplyList()                 --好友申请信息
    self:SortFriendApplyData()
    return self._friendApplyList
end

function LCSocial:SortFriendApplyData()  --好友申请排序
    local function sortFuc(m1, m2)
        return m1.offSecond < m2.offSecond
    end               
    table.sort(self._friendApplyList, sortFuc)
end

function LCSocial:GetFriendTuiJianList()                 --好友推荐列表
    self:SortFriendTuiJianData()
    return self.RecommendList
end

function LCSocial:SortFriendTuiJianData()  --推荐好友排序
    local function sortFuc(m1, m2)
        return m1.offSecond < m2.offSecond
    end               
    table.sort(self.RecommendList, sortFuc)
end

function LCSocial:GetCoupleList()        --夫妻信息
    return self.CoupleList
end

function LCSocial:GetPupilList()            --师徒信息
    return self.PupilList
end

function LCSocial:GetBlackList()                 --黑名单
    return self.BlackList
end

function LCSocial:GetMasterInfo()
    return self.MasterInfo
end

function LCSocial:GetCoupleInfo() 
    return self.CoupleInfo
end

function LCSocial:getQingMiDu(value)
    -- body
    if value <= 500 then
        return 3
    elseif value <= 1000 then
        return 4
    elseif value <= 5000 then
        return 5
    else
        return 6
    end
end

function LCSocial:delNewMailData(id)
    -- body
    local idx = 0
    for i = 1, #self.NewMailData do
        if self.NewMailData[i].id == id then
            idx = i
            break
        end
    end

    if idx > 0 then
        table.remove(self.NewMailData, idx)
    end
    
end

function LCSocial:saveMail(type, owner_id, id, mailData)
    -- body
    local FileName = tostring(owner_id)
    FileName = FileName..tostring(id)

    local writeStr = ""
    local writeFileName = tostring(id)

    local pUserDefault = CCUserDefault:getInstance()
    writeStr = pUserDefault:getStringForKey(tostring(owner_id))

    local pos = string.find(writeStr, writeFileName, 0)
--    --print("LCSocial:saveMail pos", pos)
    if pos then
        return
    end

    local tableID = {}
    if string.len(writeStr) > 0 then
      tableID = string.split(writeStr, "|")
    end

    table.insert(tableID, writeFileName)
    writeStr = table.concat(tableID, "|")
--    --print("writeStr", writeStr)

    pUserDefault:setStringForKey(tostring(owner_id), writeStr)

    --写入发件人ID
    writeFileName = FileName
    writeFileName = writeFileName.."FromId"
    pUserDefault:setStringForKey(writeFileName, mailData.from_id)

    --写入发件人ID
    writeFileName = FileName
    writeFileName = writeFileName.."Name" 
    pUserDefault:setStringForKey(writeFileName, mailData.from_name)

    --写入邮件时间
    writeFileName = FileName
    writeFileName = writeFileName.."Time"
    pUserDefault:setStringForKey(writeFileName, mailData.endTime)

    --写入文件内容
    writeFileName = FileName
    writeFileName = writeFileName.."Text"
    writeStr = pUserDefault:getStringForKey(writeFileName)
    writeStr = writeStr..mailData.message
    pUserDefault:setStringForKey(writeFileName, writeStr)


    pUserDefault:flush()

end

function LCSocial:DeleteMail(owner_id, id)
    -- body
    local FileName = tostring(owner_id)
    local FriendName = tostring(id)

    local pUserDefault = CCUserDefault:getInstance()
    local totalfriendName = pUserDefault:getStringForKey(FileName)
--    --print("delete totalfriendName", totalfriendName)

    --删除信息
--删除Id

    local tableID = string.split(totalfriendName, "|")
    --Utils:dump(tableID)
    local pos = 0
    for i = 1, #tableID do
        if tableID[i] == FriendName then
            pos = i 
        end
    end

    if pos > 0 then
        table.remove(tableID, pos)
    end

    local writeStr = table.concat(tableID, "|")
    pUserDefault:setStringForKey(FileName, writeStr)
--    --print("delete writeStr", writeStr)

    --删除From_ID
    FileName = FileName..FriendName
    local WriteFileName = FileName.."FromId"
    pUserDefault:setStringForKey(WriteFileName, "")

    --删除姓名
    WriteFileName = FileName.."Name"
    pUserDefault:setStringForKey(WriteFileName, "")

    WriteFileName = FileName.."Time"
    pUserDefault:setStringForKey(WriteFileName, "")

    --删除文件内容与时间
    WriteFileName = FileName.."Text"
    pUserDefault:setStringForKey(WriteFileName, "")

    pUserDefault:flush()

end

-- function LCSocial:DeleteAll (owner_id)
--     -- body
--     for i = 1, #self.OldMailData do
--         self:DeleteMail(owner_id, self.OldMailData[i].id)
--     end
-- end

function LCSocial:DeleteAll ()
    -- body
    self.OldMailData = {}
    local FileName = tostring(LRoleDataMgr.MyHeroInfo.id)
    local FriendName = tostring(id)
    local pUserDefault = CCUserDefault:getInstance()
    pUserDefault:deleteValueForKey(FileName)
end

function LCSocial:ReadMail(owner_id)
    -- body
    self.OldMailData = {}
    local FileName = tostring(owner_id)
    local pUserDefault = CCUserDefault:getInstance()
    local totalfriendName = pUserDefault:getStringForKey(FileName)
--    --print('ReadMail totalfriendName', totalfriendName)

    local dataInfo = string.split(totalfriendName, "|")
    --Utils:dump(dataInfo)

    for i = 1, #dataInfo do
        local data = LMailData:New()
        data.id = tonumber(dataInfo[i])
--        --print("data.id", data.id)
        if data.id == nil then
            return
        end

        --获得发件人id
        local tmpName = FileName..data.id
        tmpName = tmpName.."FromId"
        data.from_id = pUserDefault:getStringForKey(tmpName)

        --获得名字
        tmpName = FileName..data.id
        tmpName = tmpName.."Name"
        data.from_name = pUserDefault:getStringForKey(tmpName)

        --获取邮件时间
        tmpName = FileName..data.id
        tmpName = tmpName.."Time"
        local timeStr = pUserDefault:getStringForKey(tmpName, "0")
--        --print("tmpName ------------ ###############", timeStr)
        data.endTime = tonumber(timeStr)
        -- --print("time = ", data.endTime)

        --获得文本
        tmpName = FileName..data.id
        tmpName = tmpName.."Text"
        data.message = pUserDefault:getStringForKey(tmpName)

        table.insert(self.OldMailData, data)
    end

end

function LCSocial:isMailRead(owner_id)
    -- body
    for i = 1, #self.OldMailData do
        if owner_id == self.OldMailData[i].id then
            return true
        end
    end
    return false
end

--鲜花系统
function LCSocial:createEffectAnim( id )
    -- body
        --按钮动画

    local lastPartical = AppDef.CurScene:getChildByTag(AppDef.XIANHUA_TAG)
    if lastPartical then
        lastPartical:removeFromParentAndCleanup(true)
        lastPartical = nil
    end

    local str = self:getSrcByID(id)
    local partical = cc.ParticleSystemQuad:create(str)
    local frameSize = AppDef.frameSize
    local offsetX = 0
    local offsetY = 0
    if id == 2986 then
        offsetX = frameSize.width / 4
    elseif id == 2988 then
        partical:setRotation(90)
        offsetY = frameSize.height / 4
    end
    partical:setPosition(cc.p(frameSize.width / 2 - offsetX, frameSize.height / 2 + offsetY))
    partical:setAutoRemoveOnFinish(true)
    partical:setDuration(8)
    AppDef.CurScene:addChild(partical, 5, AppDef.XIANHUA_TAG)


    local function callback()
        if partical then
            partical:removeFromParentAndCleanup(true)
            partical = nil
        end 
    end
    local actions = {}
    local delay = cc.DelayTime:create(8)
    table.insert(actions, delay)
    local func = cc.CallFunc:create(callback)
    table.insert(actions, func)
    partical:runAction(cc.Sequence:create(actions))

end

function LCSocial:getSrcByID(id)
    -- body
    local res = "effect/par" .. id .. ".plist"
    return res
end


--聊天数据
LCChat = {}
LCChat.__index = LCChat
function LCChat:New()
	local o = {}
	setmetatable(o,LCChat)	
    
	o:Init()
	return o
end

function LCChat:Init()
    self._IsChannelOpen = {}
	--list<ChatMsgNode>	MsgList
    self.MsgList = {}
	--vector<AllSerMsgInfo> CrossSerMsgList//跨服信息列表
    self.CrossSerMsgList = {}

    self._SendType = 0
    self._IsVoiceClick = false
    self._PersonalName = ""
	self._RoleId = 0
	self._Voice_ays_text = ""
	self._VoicePlayID = 0
end

function LCChat:Reset()
    self._IsChannelOpen = {}
    --list<ChatMsgNode> MsgList
    self.MsgList = {}
    --vector<AllSerMsgInfo> CrossSerMsgList//跨服信息列表
    self.CrossSerMsgList = {}

    self._SendType = 0
    self._IsVoiceClick = false
    self._PersonalName = ""
    self._RoleId = 0
    self._Voice_ays_text = ""
    self._VoicePlayID = 0
end

--    int         GetSendType(){return _SendType}
function LCChat:GetSendType()
    return self._SendType
end

--void        SetSendType(int value_){_SendType = value_}
function LCChat:SetSendType(value_)
    self._SendType = value_
end
    
--    bool        GetIsVoiceClick(){return _IsVoiceClick}
function LCChat:GetIsVoiceClick()
    return self._IsVoiceClick
end

--void        SetIsVoiceClick(bool value_){_IsVoiceClick = value_}
function LCChat:SetIsVoiceClick(value_)
    self._IsVoiceClick = value_
end

  --  string      GetPersonalName(){return _PersonalName}
function LCChat:GetPersonalName()
    return self._PersonalName
end

-- void		SetPersonalName(string value_){_PersonalName = value_}
function LCChat:SetPersonalName(value_)
    self._PersonalName = value_
end

--	string		GetVoice_ays_text(){return _Voice_ays_text}
function LCChat:GetVoice_ays_text()
    return self._Voice_ays_text
end

--void		SetVoice_ays_text(string value_){_Voice_ays_text = value_}
function LCChat:SetVoice_ays_text(value_)
    self._Voice_ays_text = value_
end

--	int			GetVoicePlayID(){return _VoicePlayID}
function LCChat:GetVoicePlayID()
    return self._VoicePlayID
end

--void		SetVoicePlayID(int value_){_VoicePlayID = value_}
function  LCChat:SetVoicePlayID(value_)
    self._VoicePlayID = value_
end


function LCChat:isChannelOpen(type)
--[[
    if type  > #self._IsChannelOpen then
        return false
    end

    return self._IsChannelOpen[type]
]]--
    return true
end

function LCChat:setChannelOpenState(type, val)
    if(type < 1 or type > #self._IsChannelOpen) then
        return
    end

     self._IsChannelOpen[type] = val
     
end

function LCChat:AddChatMsg(msg)

    --刚从后台回来,暂停的聊天信息不再处理
    if LRoleDataMgr.m_isEnterIngForeground then
        return
    end

    local num = self:getChatListNumByType(msg.chanel)
    local maxNum = self:getChannelMaxNum(msg.chanel)

    if num > maxNum then
        local lastMsgIndex = self:getLastMsgIndexByType(msg.chanel)
        if lastMsgIndex > 0 then
            table.remove(self.MsgList, lastMsgIndex)
        end
    end

    -- if #self.MsgList >= 100 then
    --     table.remove(self.MsgList, 1)
    -- end

    table.insert(self.MsgList, msg)
end

function LCChat:delLastMsg(chanelType)
    -- body
    local lastMsgIndex = self:getLastMsgIndexByType(chanelType)
    if lastMsgIndex > 0 then
        table.remove(self.MsgList, lastMsgIndex)
    end
end

function LCChat:getChannelMaxNum( chanelType )
    -- body
    if chanelType == AppDef.ChatChanelType.CCT_WORLD then
        return AppDef.Chat_Msg_Type.CCT_WORLD_MAXNUM
    elseif chanelType == AppDef.ChatChanelType.CCT_NEAR or AppDef.ChatChanelType.CCT_LEITAI then
        return AppDef.Chat_Msg_Type.CCT_CUR_MAXNUM
    elseif chanelType == AppDef.ChatChanelType.CCT_FACTION then
        return AppDef.Chat_Msg_Type.CCT_BP_MAXNUM
    elseif chanelType == AppDef.ChatChanelType.CCT_TEAM then
        return AppDef.Chat_Msg_Type.CCT_TEAM_MAXNUM
    elseif chanelType == AppDef.ChatChanelType.CCT_SYS then
        return AppDef.Chat_Msg_Type.CCT_SYS_MAXNUM
    end
    return AppDef.Chat_Msg_Type.CCT_NUM_DEFAULT
end

function LCChat:getLastMsgIndexByType(chanelType)
    -- body
    local num = 0
    for i = 1, #self.MsgList do
        if self.MsgList[i].chanel == chanelType then
            num = i
            break
        end
    end
    return num
end

function LCChat:getChatListNumByType (chanelType)
    -- body
    local num = 0
    for i = 1, #self.MsgList do
        if self.MsgList[i].chanel == chanelType then
            num = num + 1
        end
    end
    return num
end

function LCChat:GetChatMessageList()
    return self.MsgList
end



LCFaction = {}
LCFaction.__index = LCFaction
function LCFaction:New()
	local o = {}
	setmetatable(o,LCFaction)	
    
	o:Init()
	return o
end

function LCFaction:Init()
	self.Info = LFactionInfo:New()--帮派信息
    self.InviteList = {}--LFactionInviteInfo帮派邀请列表
	self.memberList = {}--LFactionMemberInfo本帮成员列表
    self._VecPlantArea = {}          --种植区域信息(当前进入的帮派)
    self._PlantFactionId = 0        --种植帮派ID
    self._PlantFactionName = ""      --种植帮派名称
    self._VecPlantGuard = {}         --种植护卫列表
    self._GodTree = LPlantGodTree:New()               --神树界面信息
    self._IsMagicBurning = false        --魔火是否燃烧状态
    self._IsGodTreeCanRob = false       --神树是否可以被掠夺
    self._ManorInfo = LFactionZoneInfo:New()             --帮派领地信息
    self._FactionTaskList = {}       --种植任务信息
    self._FactionList = {}           --帮派列表信息
    self._PlantExtraData = {}--帮派种植种子信息
    self.chapterArr = {}--帮派副本
    self.canFightNum = 0;--帮派副本可挑战次数
    self.factionChapterFightTotal = 0;--帮派副本可挑战总次数
    self.buffList = {};--副本buff
    self.copyHuoyue = 0;
    self.todayHuoyue = 0;--今日活跃度
    self.huoyueAward = {};--活跃奖励
end

function LCFaction:Reset()
    self.Info:Reset()
    self.InviteList = {}--LFactionInviteInfo帮派邀请列表
    self.memberList = {}--LFactionMemberInfo本帮成员列表
    self._VecPlantArea = {}          --种植区域信息(当前进入的帮派)
    self:SetPlantFactionId(0)
    self._PlantFactionName = ""      --种植帮派名称
    self._VecPlantGuard = {}         --种植护卫列表
    self._GodTree:Reset()
    self._IsMagicBurning = false        --魔火是否燃烧状态
    self._IsGodTreeCanRob = false       --神树是否可以被掠夺
    self._ManorInfo:Reset()
    self._FactionTaskList = {}       --种植任务信息
    self._FactionList = {}           --帮派列表信息
    self._PlantExtraData = {}--帮派种植种子信息
    self.chapterArr = {}--帮派副本
    self.canFightNum = 0;--帮派副本可挑战次数
    self.factionChapterFightTotal = 0;--帮派副本可挑战总次数
    self.buffList = {};--副本buff
    self.copyHuoyue = 0;
    self.todayHuoyue = 0;--今日活跃度
    self.huoyueAward = {};--活跃奖励
end

function LCFaction:GetCurChapter()
    local id = 0;
    for key,v in pairs(self.chapterArr) do
        if id < key then
            id = key
        end
    end
    if id == 0 then
        return nil
    end
    return self.chapterArr[id]
    
end

function LCFaction:GetPlantFactionId()
	return self._PlantFactionId 
end

function LCFaction:SetPlantFactionId(id)   
	self._PlantFactionId = id 
end 

function LCFaction:GetPlantFactionName()   
	return self._PlantFactionName 
end
function LCFaction:SetPlantFactionName(name)  
	self._PlantFactionName = name 
end
function LCFaction:SetMagicFireBurning(b)   
	self._IsMagicBurning = b 
end
function LCFaction:GetMagicFireBurning()   
	return self._IsMagicBurning 
end
function LCFaction:SetGodTreeCanRob(b)   
	self._IsGodTreeCanRob = b 
end
function LCFaction:GetGodTreeCanRob()   
	return self._IsGodTreeCanRob 
end

--种植区是否属于自己
function LCFaction:IsPlantFactionBelongMe()   
	return self.Info.id ~= 0 and self.Info.id == self._PlantFactionId
end
--是否和自己属于同一个帮派
function LCFaction:IsSameFactionToMe(factionId)
	if self.Info.id == 0 and self.factionId == 0 then
        return false
    end
    return self.Info.id == factionId
end

function LCFaction:FindPlantArea(index)
	for i = 1, #self._VecPlantArea do
        if self._VecPlantArea[i].Index == index then
            return i
        end
    end
    return -1
end

function LCFaction:FindPlantCell(area, cellIndex)
	for i = 1, #area.VecPlantData do
        if area.VecPlantData[i].Index == cellIndex then
            return i
        end
    end
    return -1
end
function LCFaction:AddPlantArea(area)
	local idx = self:FindPlantArea(area.Index)
    if idx ~= -1 then
    	self._VecPlantArea[idx]:Delete()
    	table.remove(self._VecPlantArea,idx)
    end
    table.insert(self._VecPlantArea, area)
end
function LCFaction:UpdatePlantCell(areaIndex, cellInfo)
	local idx = self:FindPlantArea(areaIndex)
    if idx == -1 then
        return
    end

    local area = self._VecPlantArea[idx]
    
    --查找是否存在指定地块
    local findIdx = self:FindPlantCell(area, cellInfo.Index)

    --不存在则直接增加, 存在则修改地块信息
    if findIdx == -1 then
    	table.insert(area.VecPlantData,cellInfo)
    else
    	area.VecPlantData[findIdx]:Delete()
        area.VecPlantData[findIdx] = cellInfo
    end
end
function LCFaction:GetPlantCellPtr(areaIndex, cellIndex)
	local aIdx = self:FindPlantArea(areaIndex)
    if aIdx == -1 then
        return nil
    end

    local cIdx = self:FindPlantCell(_VecPlantArea[aIdx], cellIndex)
    if cIdx == -1 then
        return nil
    end

    return self._VecPlantArea[aIdx].VecPlantData[cIdx]
end

function LCFaction:FindPlantGuard(guardIdx)
	for i = 1, #self._VecPlantGuard do
        if self._VecPlantGuard[i].AreaIndex == guardIdx then
            return i
        end
    end
    return -1
end
function LCFaction:UpdatePlantGuard(guardIdx, info)
	local aIdx = self:FindPlantGuard(guardIdx)
    if aIdx == -1 then
    	table.insert(self._VecPlantGuard, info)
    else
    	self._VecPlantGuard[aIdx]:Delete()
        self._VecPlantGuard[aIdx] = info
    end
end
function LCFaction:GetPlantGuardPtr(guardIdx)
	local aIdx = self:FindPlantGuard(guardIdx)
    if aIdx == -1 then
        return nil
    end

    return self._VecPlantGuard[aIdx]
end

function LCFaction:GetPlantAreaList()   
	return self._VecPlantArea 
end
function LCFaction:GetPlantGuardList()   
	return self._VecPlantGuard 
end

function LCFaction:UpdateGodTree(info)  
	local _ = self._GodTree and self._GodTree:Delete()
    self._GodTree = nil
	self._GodTree = info
end
function LCFaction:GetGodTree()   
	return self._GodTree 
end

function LCFaction:ClearAllPlantData()
    self:SetPlantFactionId(0)
    self._PlantFactionName = ""
    self._GodTree:Reset()
    local num = #self._VecPlantArea
    for i =1, num do
    	self._VecPlantArea[i]:Delete()
    	self._VecPlantArea[i] = nil
    end
    self._VecPlantArea = {}
    num = #self._VecPlantGuard
    for i =1,num do
    	self._VecPlantGuard[i]:Delete()
    	self._VecPlantGuard[i] = nil
    end
    self._VecPlantGuard = {}
    Utils:FreeTable(self._PlantExtraData)
end

function LCFaction:UpdateManorInfo(info)  
	self._ManorInfo:Delete()
	self._ManorInfo = info 
end
function LCFaction:GetManorInfo()   
	return self._ManorInfo 
end

function LCFaction:FindFactionTask(t)
	for i = 1, #self._FactionTaskList do
		if t == self._FactionTaskList[i].taskType then
            return i
        end
	end
    return -1
end
function LCFaction:UpdateTaskInfo(type, info)
	local idx = self:FindFactionTask(type)
    if idx == -1 then
    	table.insert(self._FactionTaskList, info)
    elseif info.getAward == true then
    	table.remove(self._FactionTaskList, idx)
    else
    	self._FactionTaskList[idx]:Delete()
        self._FactionTaskList[idx] = info
    end
end
function LCFaction:GetFactionTaskInfo(idx)
	 if idx > #self._FactionTaskList.size() or idx < 0 then
        return nil
    end
    return self._FactionTaskList[idx]
end
function LCFaction:GetFactionTaskList()  
	return self._FactionTaskList 
end

function LCFaction:GetFactionList()  
	return self._FactionList 
end
function LCFaction:FindFactionInfo(id)
	for i = 1, #self._FactionList do
        if id == self._FactionList[i].id then
            return i
        end
    end
    return -1
end
function LCFaction:UpdateFactionList(id, info)
	local idx = self:FindFactionInfo(id)
    if idx ~= -1 then
    	self._FactionList[idx]:Delete()
        self._FactionList[idx] = nil
        self._FactionList[idx] = info
    else
    	table.insert(self._FactionList, info)
    end
end

function LCFaction:GetFactionInfo(id)
	local idx = self:FindFactionInfo(id)
    if idx == -1 then
        return nil
    else
        return self._FactionList[idx]
    end
end
function LCFaction:ClearFactionList()  
	local num = #self._FactionList
	for i = 1, num do
		self._FactionList[i]:Delete()
		self._FactionList[i] = nil
	end
    self._FactionList = nil
	self._FactionList = {}
end
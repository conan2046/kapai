--25.lua--帮派总管 id=25
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
--[[	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
--]]
	local s
	local lv = pUser:GetLevel()
	
	if lv >= 30 and not pUser:HaveBitSet(246) then
		s = pUser:GetMission(246)
		if s == nil then
			MissionBanner(pUser,BANNER_TYPE_ACCETP,246)
			pUser:SetCallFun("MissionBannerCallBack0")
			return
		else
			if tonumber(s) == 2 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,246)
				pUser:SetCallFun("MissionBannerCallBack1")
				return
			end
		end
	end

	Option(pUser,LANGUAGE_TRANSFORM_1074,LANGUAGE_TRANSFORM_1075,LANGUAGE_TRANSFORM_1076)
--	Option(pUser,"帮派总管","有什么需要我帮忙的么？尽管说好了!","1|帮派宣战|2|帮派结盟|3|帮战规则|4|离开")
	pUser:SetCallFun("BangZhan")	
end

function MissionBannerCallBack0(pUser,missionId)
	if missionId==246 then
		if pUser:GetBangPai() > 0 then
			pUser:AddMission(246,"2")
			j.UpdateNpcState(pUser,25,3)
		else
			pUser:AddMission(246,"0")
			j.UpdateNpcState(pUser,25,2)
		end
	end
end

function MissionBannerCallBack1(pUser,missionId)
	local award
	if missionId==246 then
		award =GetAward(pUser,missionId)
		pUser:DelMission(246)
		pUser:AddExp(MISSION_EXP[missionId])
		pUser:SetBitSet(246)
		j.UpdateNpcState(pUser,25,0)
		j.SendSysInfoRD(pUser,award)
	end
end

function BangZhan(pUser,sel)
	if sel==1 then
		if pUser:GetBangPai()==0 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1077,LANGUAGE_TRANSFORM_1078)
			return
		end
		r=pUser:GetBangRank()
		if r>2 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1079,LANGUAGE_TRANSFORM_1080)
			return
		end
		h=j.GetHour()
		--    if h<6 or h>11 then
		--      Dialog(pUser,"帮派总管","只有每天6:00~12:00可以宣战。")
		--      return
		--    end
		j.ListBang(pUser,1)
		pUser:SetCallFun("DeclareWar")
	elseif sel==2 then
		Option(pUser,LANGUAGE_TRANSFORM_1081,LANGUAGE_TRANSFORM_1082,LANGUAGE_TRANSFORM_1083)
		pUser:SetCallFun("BangZhan2")
	elseif sel==3 then
		BangZhanRule(pUser)
	elseif sel == 4 then
		j.CloseInteract(pUser)
	elseif sel == 5 then
		if pUser:GetBangPai()>0 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1084,LANGUAGE_TRANSFORM_1085)
			return
		end
		lv=pUser:GetLevel()
		if lv<22 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1086,LANGUAGE_TRANSFORM_1087)
			return
		end
		if pUser:GetData32(2) + 2*3600 > os.time() then
			Dialog(pUser,LANGUAGE_TRANSFORM_1088,LANGUAGE_TRANSFORM_1089)
			return
		end
--		if pUser:GetTongBao() < 100 then
--			Dialog(pUser,"帮派总管","你的元宝不足100，不能创建帮派。")
--			return
--		end
		
		j.CreateBangPaiPanel(pUser)
		pUser:SetCallFun("CreateBang2")
	elseif sel == 6 then
		j.ShowJoinBangPaiPanel(pUser)
		CloseInteract(pUser)
	end
end

function CreateBang2(pUser,Name,gongGao)
	local type
	local res
	local num = j.CheckBangPaiName(Name)
	local serverType = j.GetServerType()
	if serverType == "yuenan" then
		if num == -2 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1090,LANGUAGE_TRANSFORM_1091)
			return
		elseif num == -1 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1092,LANGUAGE_TRANSFORM_1093)
			return
		elseif num < 4 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1094,LANGUAGE_TRANSFORM_1095)
			return
		elseif num > 12 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1096,LANGUAGE_TRANSFORM_1097)
			return
		end
	else
		if num == -2 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1090,LANGUAGE_TRANSFORM_1091)
			return
		elseif num == -1 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1092,LANGUAGE_TRANSFORM_1093)
			return
		elseif num < 2 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1094,LANGUAGE_TRANSFORM_1095)
			return
		elseif num > 6 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1096,LANGUAGE_TRANSFORM_1097)
			return
		end
	end

	res=j.CreateBangPai(pUser,Name,gongGao,0)
	if res == 0 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1098,LANGUAGE_TRANSFORM_1099)
	elseif res == 4 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1100,LANGUAGE_TRANSFORM_1101)
	elseif res == 2 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1102,LANGUAGE_TRANSFORM_1103)
	else
		Dialog(pUser,LANGUAGE_TRANSFORM_1104,LANGUAGE_TRANSFORM_1105)
	end
end

function DeclareWar(pUser,op,v)
	if op==0 then --页面跳转
		j.ListBang(pUser,v)
		pUser:SetCallFun("DeclareWar")
	elseif op==1 then --宣战
		Option(pUser,LANGUAGE_TRANSFORM_1106,LANGUAGE_TRANSFORM_1107..j.GetBangName(v)..LANGUAGE_TRANSFORM_1108,LANGUAGE_TRANSFORM_1109)
		pUser:SetVal(0,v)
		pUser:SetCallFun("DeclareWar2")
	end
end

function DeclareWar2(pUser,sel)
	local v
	local ret

	v=pUser:GetVal(0)
	if sel==1 then
		CloseInteract(pUser)
		return
	end
	ret=j.DeclareWar(pUser,v)
	if ret==3 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1110,LANGUAGE_TRANSFORM_1111)
	elseif ret==4 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1112,LANGUAGE_TRANSFORM_1113)
	elseif ret==6 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1114,LANGUAGE_TRANSFORM_1115)
	elseif ret==7 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1116,LANGUAGE_TRANSFORM_1117)
	elseif ret==8 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1118,j.GetBangName(v)..LANGUAGE_TRANSFORM_1119)
	elseif ret==9 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1120,LANGUAGE_TRANSFORM_1121..j.GetBangName(v)..LANGUAGE_TRANSFORM_1122)
	elseif ret==0 then
		Dialog(pUser,LANGUAGE_TRANSFORM_1123,LANGUAGE_TRANSFORM_1124)
	end
end

function BangZhanRule(pUser)
	Dialog(pUser,LANGUAGE_TRANSFORM_1125,LANGUAGE_TRANSFORM_1126)
	pUser:SetCallFun("BangZhanRule2")
end

function BangZhanRule2(pUser)
	Dialog(pUser,LANGUAGE_TRANSFORM_1127,LANGUAGE_TRANSFORM_1128)
	pUser:SetCallFun("BangZhanRule3")
end

function BangZhanRule3(pUser)
	Dialog(pUser,LANGUAGE_TRANSFORM_1129,LANGUAGE_TRANSFORM_1130)
	pUser:SetCallFun("BangZhanRule4")
end

function BangZhanRule4(pUser)
	Dialog(pUser,LANGUAGE_TRANSFORM_1131,LANGUAGE_TRANSFORM_1132)
	--  Dialog(pUser,"帮派总管","4.每周繁荣度排名前三的帮派可获得专属勋章，繁荣度每周一更新一次。|5.不可对繁荣度小于0的帮派宣战。")
end

function BangZhan2(pUser,sel)
	local pMember
	local cid
	local bid
	local r
	local s
	local t

	if sel==1 then --帮派结盟
		if j.GetTeamMemNum(pUser)~=2 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1133,LANGUAGE_TRANSFORM_1134)
			return
		end
		pMember=j.GetTeamMember1(pUser)
		bid=pMember:GetBangPai()
		cid=pUser:GetBangPai()
		if cid==0 or bid==0 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1135,LANGUAGE_TRANSFORM_1136)
			return
		end
		r=pUser:GetBangRank()
		if r>1 or pMember:GetBangRank()>1 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1137,LANGUAGE_TRANSFORM_1138);
			return
		end
		r=j.CheckAlly(pUser,bid)
		if r==0 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1139,LANGUAGE_TRANSFORM_1140..j.GetBangName(bid)..LANGUAGE_TRANSFORM_1141)
			Option(pMember,LANGUAGE_TRANSFORM_1142,j.GetBangName(cid)..LANGUAGE_TRANSFORM_1143,LANGUAGE_TRANSFORM_1144)
			pMember:SetCall(213,"AllyBang2")
		elseif r==1 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1145,LANGUAGE_TRANSFORM_1146)
		elseif r==2 or r==3 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1147,LANGUAGE_TRANSFORM_1148)
		elseif r==5 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1149,LANGUAGE_TRANSFORM_1150)
		end
	elseif sel==2 then --解散结盟
		if pUser:GetBangPai()==0 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1151,LANGUAGE_TRANSFORM_1152)
			return
		end
		r=pUser:GetBangRank()
		if r>1 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1153,LANGUAGE_TRANSFORM_1154);
			return
		end
		s=j.GetAllyBang(pUser)
		if s==nil then
			Dialog(pUser,LANGUAGE_TRANSFORM_1155,LANGUAGE_TRANSFORM_1156);
			return
		end
		t=FormatMission(s)
		if t[1]~=nil then
			s="1|"..j.GetBangName(tonumber(t[1]))
		end
		if t[2]~=nil then
			s=s.."|2|"..j.GetBangName(tonumber(t[2]))
		end
		Option(pUser,LANGUAGE_TRANSFORM_1157,LANGUAGE_TRANSFORM_1158,s)
		pUser:SetCallFun("UnallyBang")
	elseif sel==3 then --规则说明
		Dialog(pUser,LANGUAGE_TRANSFORM_1159,LANGUAGE_TRANSFORM_1160)
	else --返回上一页
		Option(pUser,LANGUAGE_TRANSFORM_1161,LANGUAGE_TRANSFORM_1162,LANGUAGE_TRANSFORM_1163)
		pUser:SetCallFun("BangZhan")
	end
end

function AllyBang2(pUser,sel)
	local pCap
	local ret
	local bid

	pCap=j.GetTeamLeader(pUser)
	if pCap==nil then
		j.CloseInteract(pUser)
		return
	end
	if sel==1 then
		print("AllyBang2:"..j.GetBangName(pUser:GetBangPai()))
		j.AllyBang(pCap,pUser:GetBangPai())
		Dialog(pUser,LANGUAGE_TRANSFORM_1164,LANGUAGE_TRANSFORM_1165)
		Dialog(pCap,LANGUAGE_TRANSFORM_1166,LANGUAGE_TRANSFORM_1167)
		return
	elseif sel==2 then
		Dialog(pCap,LANGUAGE_TRANSFORM_1168,LANGUAGE_TRANSFORM_1169)
		return
	end
	j.CloseInteract(pUser)
end

function UnallyBang(pUser,sel)
	local s
	local t
	local r
	local bid

	if pUser:GetBangPai()==0 then
		return
	end
	r=pUser:GetBangRank()
	if r>1 then
		return
	end
	s=j.GetAllyBang(pUser)
	if s==nil then
		return
	end
	t=FormatMission(s)
	if sel==1 then
		bid=tonumber(t[1])
	elseif sel==2 then
		bid=tonumber(t[2])
	end
	j.UnallyBang(pUser,bid)
	Dialog(pUser,LANGUAGE_TRANSFORM_1170,LANGUAGE_TRANSFORM_1171)
end


function GetState(pUser)
	local s 
	local t

	return 0
end


function AutoTransportUser(pUser,nextSceneId)
	local s
	if nextSceneId~=47 then
		return
	end
	j.TransportUser(pUser,47,1186,480,3)
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end



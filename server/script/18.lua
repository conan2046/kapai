--18.lua--师徒见证人 id=18
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   
SendSysInfo = j.SendSysInfo

thisId = 18
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_560,LANGUAGE_TRANSFORM_561)

--	Option(pUser,NPCName,"二人组队一起来找我，我可以见证你们的师徒情分。","1|师徒关系|2|提升师傅等级|3|领取徒弟升级奖励|4|师徒任务|5|师徒中介榜|6|规则说明|7|离开")
	pUser:SetCallFun("DoOption")
end

function DoOption(pUser,sel)
	if sel == 1 then	
		if pUser:GetTeam() == 0 then
			if pUser:TempLeaveTeam() == 0 then
				SendSysInfo(pUser,LANGUAGE_TRANSFORM_562)
			else
				SendSysInfo(pUser,LANGUAGE_TRANSFORM_563)
			end
			return
		end
		
		local roleId = pUser:GetRoleId()
		if pUser:GetTeam() ~= roleId then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_564)
			return
		end
		
		local allmemNum = j.GetTeamAllMemNum(pUser)
		if allmemNum ~= 2 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_565)
			return
		end
		local memNum = j.GetTeamMemNum(pUser)
		if memNum ~= 2 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_566)
			return
		end
		
		local shifu
		local tudi
		local mem = j.GetTeamMember1(pUser)
		if mem == nil then
			mem = j.GetTeamMember2(pUser)
		end
		if mem == nil then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_567)
			return		
		end
		if mem:GetLevel() > pUser:GetLevel() then
			shifu = mem
			tudi = pUser
		else
			shifu = pUser
			tudi = mem
		end
		
		if shifu:GetLevel() < 40 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_568)
			return
		elseif j.GetMaster(shifu:GetRoleId()) > 0 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_569)
			return
		end

		local time = 0
		if tudi:GetLevel() < 28 or tudi:GetLevel() >= 40 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_570)
			return
		end
		if j.GetMaster(tudi:GetRoleId()) > 0 then
			SendSysInfo(pUser,"[c1]"..tudi:GetName()..LANGUAGE_TRANSFORM_571)
			return
		end

		time = tudi:GetExtData32(60) - os.time()
		if time > 0 then
			SendSysInfo(pUser,"[c1]"..math.floor(time/3600)..LANGUAGE_TRANSFORM_572..math.floor(time%3600/60)..LANGUAGE_TRANSFORM_573..tudi:GetName()..LANGUAGE_TRANSFORM_574)
			return
		end
		if j.GetPrenticeNum(shifu) >= (shifu:GetExtData8(385)+1) then
			SendSysInfo(pUser,"[c1]"..shifu:GetName()..LANGUAGE_TRANSFORM_575)
			return
		end
		
		local time = shifu:GetExtData32(59) - os.time()
		if time > 0 then
			SendSysInfo(pUser,"[c1]"..math.floor(time/3600)..LANGUAGE_TRANSFORM_576..math.floor(time%3600/60)..LANGUAGE_TRANSFORM_577..shifu:GetName()..LANGUAGE_TRANSFORM_578)
			return
		end
		
		-- 发送收徒拜师信息
		j.SendBaiShiPanel(shifu,tudi)
		return
	elseif sel == 2 then
		CloseInteract(pUser)
		j.ShowShiTuPanel(pUser)
	end
end



function DoMaster(pUser,sel)
	if sel==1 then
		Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_579)
		pUser:SetCallFun("DoMaster2")
	elseif sel ==2 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_580,LANGUAGE_TRANSFORM_581)
		pUser:SetCallFun("UpgradeShi")
	elseif sel ==3 then
		Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_582)
		pUser:SetCallFun("STAward")
	elseif sel==4 then
		Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_583)
		pUser:SetCallFun("ChushiRenWu")
	elseif sel==5 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_584,LANGUAGE_TRANSFORM_585)
		pUser:SetCallFun("DoMasterNext")
	end
end

function DoMasterNext(pUser,sel)
	if sel==5 then
		if j.IsShiFuDengJiDone(pUser) or j.IsTuDiDengJiDone(pUser) then
			Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_586)
		else
			Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_587)
		end
		pUser:SetCallFun("ShiTuBang")
	elseif sel==6 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_588)
		pUser:SetCallFun("ShouTuInfo")
	elseif sel==7 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_589,LANGUAGE_TRANSFORM_590)
		pUser:SetCallFun("DoMaster")
	else
		j.CloseInteract(pUser)
	end	
end

function DoMaster2(pUser,sel)
	if sel==1 then
		ShouTu(pUser)
	elseif sel==2 then
		DismissShiTu(pUser)
	elseif sel==3 then
		j.CloseInteract(pUser)
	end
end

function ShouTu(pUser)
	local pMember
	local lv

	if j.GetTeamMemNum(pUser)~=2 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_591)
		return
	end  
	if j.master_level(pUser)==0 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_592)
		return
	end
	pMember=j.GetTeamMember1(pUser)
	lv=pMember:GetLevel()
	if lv<10 or lv>40 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_593)
		return
	end
	if j.have_master(pMember) then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_594)
		return
	end
	OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_595..pMember:GetName()..LANGUAGE_TRANSFORM_596,LANGUAGE_TRANSFORM_597)
	pUser:SetCallFun("ShouTu2")
end

function ShouTu2(pUser,sel)
	local pMember

	if sel==1 then
		if j.GetTeamMemNum(pUser)==0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_598)
			return
		end
		pMember=j.GetTeamMember1(pUser)
		OptionConfirm(pMember,NPCName,LANGUAGE_TRANSFORM_599..pUser:GetName()..LANGUAGE_TRANSFORM_600,LANGUAGE_TRANSFORM_601)
		pMember:SetCall(18,"ShouTu3")
	else
		j.CloseInteract(pUser)
	end
end

function ShouTu3(pUser,sel)
	local pCap
	local ret

	pCap=j.GetTeamLeader(pUser)
	if pCap==nil then
		j.CloseInteract(pUser)
		return
	end
	if sel==1 then
		if j.GetTeamMemNum(pCap)~=2 then
			return
		end  
		if j.master_level(pCap)==0 then
			return
		end
		lv=pUser:GetLevel()
		if lv<10 or lv>40 then
			return
		end
		if j.have_master(pUser) then
			return
		end
		ret=j.do_master(pCap)
		if ret==0 then 
			pCap:SetBitSet(523)
			j.SysInfoToAllUser(LANGUAGE_TRANSFORM_602..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_603..ROLE_NAME_COLOR.."]"..pCap:GetName()..LANGUAGE_TRANSFORM_604)
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_605..pCap:GetName()..LANGUAGE_TRANSFORM_606)
			Dialog(pCap,NPCName,LANGUAGE_TRANSFORM_607..pUser:GetName()..LANGUAGE_TRANSFORM_608)
		elseif ret==3 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_609)
			Dialog(pCap,NPCName,LANGUAGE_TRANSFORM_610)
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_611)
			Dialog(pCap,NPCName,LANGUAGE_TRANSFORM_612)
		end
	else
		j.CloseInteract(pUser)
		Dialog(pCap,NPCName,pUser:GetName()..LANGUAGE_TRANSFORM_613)
	end
end

function DismissShiTu(pUser)
	local s
	local t
	local i

	if j.master_level(pUser)>0 then
		if j.have_disciple(pUser) then
			s=j.get_disciple(pUser)
			t=FormatMission(s)
			s="1|"..t[1]
			for i=2,#t,1 do
				s=s.."|"..i.."|"..t[i]
			end
			Option(pUser,NPCName,LANGUAGE_TRANSFORM_614,s)
			pUser:SetCallFun("DismissShitu2")
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_615)
		end
	else
		if not j.have_master(pUser) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_616)
			return
		end
		OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_617..j.get_master(pUser)..LANGUAGE_TRANSFORM_618,LANGUAGE_TRANSFORM_619)
		pUser:SetCallFun("DismissShitu4")
	end
end

function DismissShitu2(pUser,sel)
	local s
	local t

	s=j.get_disciple(pUser)
	t=FormatMission(s)
	OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_620..t[sel]..LANGUAGE_TRANSFORM_621,LANGUAGE_TRANSFORM_622)
	pUser:SetVal(1,sel)
	pUser:SetCallFun("DismissShitu3")
end

function DismissShitu3(pUser,sel)
	local ind

	if sel==1 then
		ind=pUser:GetVal(1)
		j.cancel_disciple(pUser,ind-1)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_623)
	else
		j.CloseInteract(pUser)
	end
end

function DismissShitu4(pUser,sel)
	if sel==1 then
		j.cancel_master(pUser)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_624)
	else
		j.CloseInteract(pUser)
	end
end

function UpgradeShi(pUser,sel)
	local mlv

	if sel==1 then
		if j.have_master(pUser) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_625)
			return
		end
		if pUser:GetLevel()<50 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_626)
			return
		end
		if pUser:GetShengWang()<1000 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_627)
			return
		end
		mlv=j.master_level(pUser)
		if mvl==1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_628)
			return
		elseif mlv==2 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_629)
			return
		elseif mlv==3 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_630)
			return
		end
		j.upgrade_master(pUser)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_631)
	elseif sel==2 then
		if pUser:GetLevel()<55 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_632)
			return
		end
		if pUser:GetShengWang()<3000 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_633)
			return
		end
		mlv=j.master_level(pUser)
		if mlv==2 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_634)
			return
		end      
		if mlv~=1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_635)
			return
		end
		if pUser:GetChuShiNum()<1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_636)
			return
		end
		j.upgrade_master(pUser)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_637)
	elseif sel==3 then
		if pUser:GetLevel()<60 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_638)
			return
		end
		if pUser:GetShengWang()<5000 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_639)
			return
		end
		mlv=j.master_level(pUser)
		if mlv==3 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_640)
			pUser:AddTitle(4)
			return
		end
		if mlv~=2 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_641)
			return
		end
		if pUser:GetChuShiNum()<3 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_642)
			return
		end
		j.upgrade_master(pUser)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_643)
	elseif sel==4 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_644)
		pUser:SetCallFun("DengjiInfo")
	else	
		j.CloseInteract(pUser)
	end
end

function DengjiInfo(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_645)
	pUser:SetCallFun("DengjiInfo2")
end

function DengjiInfo2(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_646)
	pUser:SetCallFun("DengjiInfo3")
end

function DengjiInfo3(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_647)
end

function ChushiRenWu(pUser,sel)
	if sel==1 then
		j.CloseInteract(pUser)
	elseif sel==2 then
		Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_648)
		pUser:SetCallFun("ChushiRenWu2")
	else
		j.CloseInteract(pUser)
	end	
end

function ChushiRenWu2(pUser,sel)
	local pMember
	local lv

	if sel==1 then
		lv=pUser:GetLevel()
		if lv<50 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_649)
			return
		end
		if j.GetTeamMemNum(pUser)~=2 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_650)
			return
		end
		pMember=j.GetTeamMember1(pUser)
		if j.GetMaster(pUser)~=pMember:GetRoleId() then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_651)
			return
		end
		j.ChuShiFight(pUser)
		pUser:SetCallFun("BattleOver")
	elseif sel==2 then
		OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_652,LANGUAGE_TRANSFORM_653)
		pUser:SetCallFun("ChushiRenWu3")
	elseif sel==3 then
		j.CloseInteract(pUser)
	end
end

function ChushiRenWu3(pUser,sel)
	local pMember
	local lv

	if sel==1 then
		lv=pUser:GetLevel()
		if lv<50 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_654)
			return
		end
		if j.GetTeamMemNum(pUser)>0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_655)
			return
		end
		if not j.have_master(pUser) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_656)
			return
		end
		j.ChuShiFight(pUser)
		pUser:SetCallFun("BattleOver")
	else
		j.CloseInteract(pUser)
	end
end

function BattleOver(pUser,state)
	if state==0 then
		j.ChuShi(pUser)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_657)
		return
	else
		j.CloseInteract(pUser)
	end
end


function ShouTuInfo(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_658)
	pUser:SetCallFun("ShouTuInfo2")
end

function ShouTuInfo2(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_659)
	pUser:SetCallFun("ShouTuInfo3")
end

function ShouTuInfo3(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_660)
end


function STAward(pUser,sel)
	if sel==1 then
		pUser:SetVal(0,0)
		Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_661)
		pUser:SetCallFun("STAward2")
	elseif sel==2 then
		pUser:SetVal(0,1)
		Option(pUser,NPCName,"",LANGUAGE_TRANSFORM_662)
		pUser:SetCallFun("STAward2")
	else
		j.CloseInteract(pUser)
	end
end

function STAward2(pUser,sel)
	local t

	t=pUser:GetVal(0)
	if t==0 then
		ShiAward(pUser,sel)
	else
		TudiAward(pUser,sel)
	end
end

--经验（1轮师门的经验）
--经验（2轮师门的经验和钱）
--4轮师门的经验和钱，2轮召讨使任务的潜能，2轮药材收集任务的道行
--轮道行: 师傅等级*15+500
--潜能: 师傅等级*150+5000
function ShiAward(pUser,sel)
	local exp
	local qn
	local dh
	local lv
	local tb
	local bslv

	if sel==1 then --领取升30级奖励
		if j.GetMasterAward(pUser,1)==0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_663)
			return
		end

		j.DelMasterAward(pUser,1)
		exp=pUser:GetLevel()*100+1000
		pUser:AddExp(exp)
		local worldExpPer = GetWorldExpPercent(pUser)
		if worldExpPer > 0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_664..exp..LANGUAGE_TRANSFORM_665..worldExpPer..LANGUAGE_SSJ_0175)
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_666..exp)
		end
	elseif sel==2 then --领取升40级奖励
		if j.GetMasterAward(pUser,2)==0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_667)
			return
		end
	
		j.DelMasterAward(pUser,2)
		exp=pUser:GetLevel()*200+2000
		pUser:AddExp(exp)

		local worldExpPer = GetWorldExpPercent(pUser)
		if worldExpPer > 0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_668..exp..LANGUAGE_TRANSFORM_665..worldExpPer..LANGUAGE_SSJ_0175)
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_670..exp)
		end
	elseif sel==3 then --领取出师奖励
		bslv=j.GetMasterAward(pUser,3)
		if bslv==0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_671)
			return
		end

		j.DelMasterAward(pUser,3)
		lv=pUser:GetLevel()
		exp=lv*400+4000
		qn=(lv*15+500)*2
		dh=(lv*150+5000)
		pUser:AddExp(exp)
		pUser:AddQianNeng(qn)
		pUser:AddDaoHang(dh)
		local worldExpPer = GetWorldExpPercent(pUser)
		if worldExpPer > 0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_672..exp..LANGUAGE_TRANSFORM_665..worldExpPer..LANGUAGE_SSJ_0175..LANGUAGE_TRANSFORM_674..qn..LANGUAGE_TRANSFORM_675..dh)
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_676..exp..LANGUAGE_TRANSFORM_677..qn..LANGUAGE_TRANSFORM_678..dh)
		end
	end
end

--+3 30级装备一套
--+3 40级装备一套
--+3 50级装备一套，升级宝石*3，归原露*3
function TudiAward(pUser,sel)
	local x
	local wid
	local sex

	if sel==1 then --领取升25级奖励
		if not j.GetDiscipleAward(pUser,1) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_679)
			return
		end
		if pUser:EmptyPackage()<5 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_680)
			return
		end

		x=pUser:GetXiang()
		if x==1 then
			wid=4
		elseif x==2 then
			wid=54
		else--5
			wid=204
		end
		pUser:AddLevelPackage(wid,3)
		sex=pUser:GetSex()
		if sex==0 then
			pUser:AddLevelPackage(254,3)
			pUser:AddLevelPackage(304,3)
			pUser:AddLevelPackage(354,3)
			pUser:AddLevelPackage(384,3)
		else
			pUser:AddLevelPackage(268,3)
			pUser:AddLevelPackage(318,3)
			pUser:AddLevelPackage(354,3)
			pUser:AddLevelPackage(384,3)
		end
		j.DelDiscipleAward(pUser,1)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_681)
	elseif sel==2 then --领取升40级奖励
		if not j.GetDiscipleAward(pUser,2) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_682)
			return
		end
		if pUser:EmptyPackage()<5 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_683)
			return
		end
		x=pUser:GetXiang()
		if x==1 then
			wid=5
		elseif x==2 then
			wid=55
		else--5
			wid=205
		end
		pUser:AddLevelPackage(wid,3)
		sex=pUser:GetSex()
		if sex==0 then
			pUser:AddLevelPackage(255,3)
			pUser:AddLevelPackage(305,3)
			pUser:AddLevelPackage(355,3)
			pUser:AddLevelPackage(385,3)
		else
			pUser:AddLevelPackage(269,3)
			pUser:AddLevelPackage(319,3)
			pUser:AddLevelPackage(355,3)
			pUser:AddLevelPackage(385,3)
		end
		j.DelDiscipleAward(pUser,2)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_684)
	elseif sel==3 then --领取出师奖励
		if not j.GetDiscipleAward(pUser,3) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_685)
			return
		end
		if pUser:EmptyPackage()<7 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_686)
			return
		end
		x=pUser:GetXiang()
		if x==1 then
			wid=6
		elseif x==2 then
			wid=56
		else--5
			wid=206
		end
		pUser:AddLevelPackage(wid,3)
		sex=pUser:GetSex()
		if sex==0 then
			pUser:AddLevelPackage(256,3)
			pUser:AddLevelPackage(306,3)
			pUser:AddLevelPackage(356,3)
			pUser:AddLevelPackage(386,3)
		else
			pUser:AddLevelPackage(270,3)
			pUser:AddLevelPackage(320,3)
			pUser:AddLevelPackage(356,3)
			pUser:AddLevelPackage(386,3)
		end
		pUser:AddBangDingPackage(851,3)
		pUser:AddBangDingPackage(631,3)
		j.DelDiscipleAward(pUser,3)
		SMessage(pUser,LANGUAGE_TRANSFORM_687)
	end
end


function ShiTuBang(pUser,sel)
	local lv=pUser:GetLevel()
 	if sel==1 then
 		j.SendTuDi(pUser)
 	elseif sel==2 then
 		j.SendShiFu(pUser)
 	elseif sel==3 then 
 		if lv <50 then
	 		if j.IsTuDiDengJiDone(pUser) then
	 			Option(pUser,NPCName,LANGUAGE_TRANSFORM_688,LANGUAGE_TRANSFORM_689)
				pUser:SetCallFun("ChexiaoTudiDJ")
				return
			else
				if lv >=40 then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_690)
					return
				end
				local err= j.TuDiDengJi(pUser)
				if err==0 then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_691)
				elseif err==-1 then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_692)
				else
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_693)
				end
				return
	 		end
 		else
	 		if j.IsShiFuDengJiDone(pUser) then
	 			Option(pUser,NPCName,LANGUAGE_TRANSFORM_694,LANGUAGE_TRANSFORM_695)
				pUser:SetCallFun("ChexiaoShifuDJ")
				return
			else
				if(not j.is_master(pUser))then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_696)
					return
				end
				local err = j.ZJDengJi(pUser)
				if err == 0 then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_697)
				elseif err == 1 then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_698)
				elseif err == 2 then
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_699)
				end
				return
	 		end
	 	end	
 	elseif sel==4 then
 		Option(pUser,NPCName,LANGUAGE_TRANSFORM_700,LANGUAGE_TRANSFORM_701)
		pUser:SetCallFun("DoMaster")
 	else
 		j.CloseInteract(pUser)
 	end	
 end

function ChexiaoShifuDJ(pUser,sel)
 	if sel==1 then
 		j.ShiFuCheXiao(pUser)
 		return
 	end
 	j.CloseInteract(pUser)
 end

function ChexiaoTudiDJ(pUser,sel)
 	if sel==1 then
 		j.TuDiCheXiao(pUser)
 		return
 	end
 	j.CloseInteract(pUser)
 end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end


--235.lua--活跃天官 id=235
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 235
NPCName = nil

local bit = require "bit"
local task = {}
local taskAward = {}
local dataAnd = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608}
--srcItemId,srcItemNum,tarItemId,tarItemNum
local duihuanList = {{2946,30,2933,1},{2947,60,2934,1},{2949,400,2919,1}}

------------------------------------------
--以下为脚本部分：
------------------------------------------

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local opt = ""
	local lv = pUser:GetLevel()
	local ad = pUser:GetAd()
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()

--	if serverId > 500 then
		opt = opt..LANGUAGE_LLD_0081
		opt = opt..LANGUAGE_LLD_0082
--	end
	--opt = opt..LANGUAGE_SSJ_0063

	opt = string.sub(opt,1,-2)
	if #opt ~= 0 then
--		if serverId > 500 then
			Option(pUser,NPCName,LANGUAGE_LLD_0080,opt)
--		else
--			Option(pUser,NPCName,"机会只会留给有准备的人，每日提高一点点，终会水滴石穿，成就大业。记得每日都要来看一看啊！\n[c1](假期将至，活跃天官已被临时召回神界参与节日盛会，因此暂不发放任务。盛会结束后会尽快回来，继续使命。)[c/]",opt)
--		end
		pUser:SetCallFun("NpcMainSel")
	else
		Dialog(pUser,NPCName,LANGUAGE_LLD_0080)
	end
end

function NpcMainSel(pUser,sel)
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local lv = pUser:GetLevel()
	local opt = ""
		
	if sel == 1 then
		opt = opt .. LANGUAGE_LLD_0082
		opt = string.sub(opt,1,-2)
		Option(pUser,NPCName,LANGUAGE_LLD_0083,opt)
		pUser:SetCallFun("NpcMainSel")
		return
	elseif sel == 2 then
		ShowTask(pUser)
		return
	end
end

function ShowTask(pUser)
	local taskNumStr = j.GetHuoYueTask(pUser,#task)

	local taskInfoStr = CreateTaskInfoStr(pUser,taskNumStr)
	j.ShowHuoYueTaskPanel(pUser,taskInfoStr)
end

--任务名字|任务需求|已完成次数|等级|说明
function CreateTaskInfoStr(pUser,taskNumStr)
	local taskList = taskNumStr:split("|")
	local str = ""
	for k,v in ipairs(taskList) do
		local idx = tonumber(v)
		local name = task[idx].name
		local complete = task[idx].count_callback(pUser)
		local needStr = string.format(task[idx].format_str,task[idx].count)
		local info = complete.."/"..needStr
		local document = string.format(task[idx].document,name..needStr)
		str = str .. name .. '|' .. info .. '|' .. complete .. '|' .. task[idx].level ..'|'..document..'|'..task[idx].count..'|'..task[idx].pic..'|'
	end
	str = string.sub(str,1,-2)
	return str
end

function MissionBannerCallBack0(pUser,missionId)
	--AddMison
	--Call剧情Dialog
	if missionId==1 then

	end
end

function MissionBannerCallBack1(pUser,missionId)
	--DelMison
	--AddAward
	if missionId==1 then


	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

task[1] = {name = LANGUAGE_LLD_0086,format_str = LANGUAGE_LLD_0087,count = 10, level = 1,document=LANGUAGE_LLD_0166,pic = 1
								,count_callback = function(pUser) return pUser:GetExtData32(391) end}
task[2] = {name = LANGUAGE_LLD_0086,format_str = LANGUAGE_LLD_0087,count = 50, level = 2,document=LANGUAGE_LLD_0166,pic = 1
								,count_callback = function(pUser) return pUser:GetExtData32(391) end}
task[3] = {name = LANGUAGE_LLD_0086,format_str = LANGUAGE_LLD_0087,count = 200,level = 3,document=LANGUAGE_LLD_0166,pic = 1
								,count_callback = function(pUser) return pUser:GetExtData32(391) end}
								
task[4] = {name = LANGUAGE_LLD_0088,format_str = LANGUAGE_LLD_0089,count = 5, level = 1,document=LANGUAGE_LLD_0166,pic = 2
								,count_callback = function(pUser) return pUser:GetExtData8(17) end}	
task[5] = {name = LANGUAGE_LLD_0088,format_str = LANGUAGE_LLD_0089, count = 15,level = 2,document=LANGUAGE_LLD_0166,pic = 2
								,count_callback = function(pUser) return pUser:GetExtData8(17) end}	
task[6] = {name = LANGUAGE_LLD_0088,format_str = LANGUAGE_LLD_0089,count = 50,level = 3,document=LANGUAGE_LLD_0166,pic = 2
								,count_callback = function(pUser) return pUser:GetExtData8(17) end}
								
task[7] = {name = LANGUAGE_LLD_0090,format_str = LANGUAGE_LLD_0091,count = 5,level = 1,document=LANGUAGE_LLD_0166,pic = 3
								,count_callback = function(pUser) return pUser:GetExtData32(392) end}
task[8] = {name = LANGUAGE_LLD_0090,format_str = LANGUAGE_LLD_0091, count = 15,level = 2,document=LANGUAGE_LLD_0166,pic = 3
								,count_callback = function(pUser) return pUser:GetExtData32(392) end}
task[9] = {name = LANGUAGE_LLD_0090,format_str = LANGUAGE_LLD_0091,count = 50,level = 3,document=LANGUAGE_LLD_0166,pic = 3
								,count_callback = function(pUser) return pUser:GetExtData32(392) end}
								
task[10] = {name = LANGUAGE_LLD_0092,format_str = LANGUAGE_LLD_0093,count = 5,level = 1,document=LANGUAGE_LLD_0166,pic = 4
								,count_callback = function(pUser) return pUser:GetExtData32(393) end}	
task[11] = {name = LANGUAGE_LLD_0092,format_str = LANGUAGE_LLD_0093, count = 30,level = 2,document=LANGUAGE_LLD_0166,pic = 4
								,count_callback = function(pUser) return pUser:GetExtData32(393) end}							
task[12] = {name = LANGUAGE_LLD_0092,format_str = LANGUAGE_LLD_0093,count = 100,level = 3,document=LANGUAGE_LLD_0166,pic = 4
								,count_callback = function(pUser) return pUser:GetExtData32(393) end}								
								

task[13] = {name = LANGUAGE_LLD_0094,format_str = LANGUAGE_LLD_0095,count = 30,level = 1,document=LANGUAGE_LLD_0166,pic = 5
								,count_callback = function(pUser) return pUser:GetExtData32(394) end}
task[14] = {name = LANGUAGE_LLD_0094,format_str = LANGUAGE_LLD_0095, count = 50,level = 2,document=LANGUAGE_LLD_0166,pic = 5
								,count_callback = function(pUser) return pUser:GetExtData32(394) end}								
task[15] = {name = LANGUAGE_LLD_0094,format_str = LANGUAGE_LLD_0095,count = 100,level = 3,document=LANGUAGE_LLD_0166,pic = 5
								,count_callback = function(pUser) return pUser:GetExtData32(394) end}
								
task[16] = {name = LANGUAGE_LLD_0096,format_str = LANGUAGE_LLD_0097,count = 50,level = 1,document=LANGUAGE_LLD_0166,pic = 6
								,count_callback = function(pUser) return pUser:GetExtData32(395) end}
task[17] = {name = LANGUAGE_LLD_0096,format_str = LANGUAGE_LLD_0097,count = 400,level = 2,document=LANGUAGE_LLD_0166,pic = 6
								,count_callback = function(pUser) return pUser:GetExtData32(395) end}								
task[18] = {name = LANGUAGE_LLD_0096,format_str = LANGUAGE_LLD_0097,count = 1000,level = 3,document=LANGUAGE_LLD_0166,pic = 6
								,count_callback = function(pUser) return pUser:GetExtData32(395) end}								
								
								
task[19] = {name = LANGUAGE_LLD_0098,format_str = LANGUAGE_LLD_0099,count = 50,level = 1,document=LANGUAGE_LLD_0166,pic = 7
								,count_callback = function(pUser) return pUser:GetExtData32(396) end}
task[20] = {name = LANGUAGE_LLD_0098,format_str = LANGUAGE_LLD_0099,count = 200,level = 2,document=LANGUAGE_LLD_0166,pic = 7
								,count_callback = function(pUser) return pUser:GetExtData32(396) end}								
task[21] = {name = LANGUAGE_LLD_0098,format_str = LANGUAGE_LLD_0099,count = 1000,level = 3,document=LANGUAGE_LLD_0166,pic = 7
								,count_callback = function(pUser) return pUser:GetExtData32(396) end}
															
							
task[22] = {name = LANGUAGE_LLD_0100,format_str = LANGUAGE_LLD_0101,count = 5,level = 1,document=LANGUAGE_LLD_0166,pic = 8
								,count_callback = function(pUser) return pUser:GetExtData32(397) end}
task[8] = {name = LANGUAGE_LLD_0100,format_str = LANGUAGE_LLD_0101,count = 20,level = 2,document=LANGUAGE_LLD_0166,pic = 8
								,count_callback = function(pUser) return pUser:GetExtData32(397) end}
task[23] = {name = LANGUAGE_LLD_0100,format_str = LANGUAGE_LLD_0101,count = 100,level = 3,document=LANGUAGE_LLD_0166,pic = 8
								,count_callback = function(pUser) return pUser:GetExtData32(397) end}

	
task[24] = {name = LANGUAGE_LLD_0102,format_str = LANGUAGE_LLD_0103,count = 50,level = 1,document=LANGUAGE_LLD_0166,pic = 9
								,count_callback = function(pUser) return pUser:GetExtData32(398) end}
task[25] = {name = LANGUAGE_LLD_0102,format_str = LANGUAGE_LLD_0103,count = 100,level = 2,document=LANGUAGE_LLD_0166,pic = 9
								,count_callback = function(pUser) return pUser:GetExtData32(398) end}
task[26] = {name = LANGUAGE_LLD_0102,format_str = LANGUAGE_LLD_0103,count = 200,level = 3,document=LANGUAGE_LLD_0166,pic = 9
								,count_callback = function(pUser) return pUser:GetExtData32(398) end}

								
task[27] = {name = LANGUAGE_LLD_0104,format_str = LANGUAGE_LLD_0105,count = 5,level = 1,document=LANGUAGE_LLD_0166,pic = 10
								,count_callback = function(pUser) return pUser:GetExtData8(584) end}
task[28] = {name = LANGUAGE_LLD_0104,format_str = LANGUAGE_LLD_0105, count = 8,level = 2,document=LANGUAGE_LLD_0166,pic = 10
								,count_callback = function(pUser) return pUser:GetExtData8(584) end}								
task[29] = {name = LANGUAGE_LLD_0104,format_str = LANGUAGE_LLD_0105,count = 10,level = 3,document=LANGUAGE_LLD_0166,pic = 10
								,count_callback = function(pUser) return pUser:GetExtData8(584) end}								
								
task[30] = {name = LANGUAGE_LLD_0106,format_str = LANGUAGE_LLD_0107,count = 10,level = 1,document=LANGUAGE_LLD_0166,pic = 11
								,count_callback = function(pUser) return pUser:GetExtData8(291) + pUser:GetExtData8(292) + pUser:GetExtData8(293) + pUser:GetExtData8(436) end}
task[31] = {name = LANGUAGE_LLD_0106,format_str = LANGUAGE_LLD_0107, count = 25,level = 2,document=LANGUAGE_LLD_0166,pic = 11
								,count_callback = function(pUser) return pUser:GetExtData8(291) + pUser:GetExtData8(292) + pUser:GetExtData8(293) + pUser:GetExtData8(436) end}						
task[32] = {name = LANGUAGE_LLD_0106,format_str = LANGUAGE_LLD_0107,count = 50,level = 3,document=LANGUAGE_LLD_0166,pic = 11
								,count_callback = function(pUser) return pUser:GetExtData8(291) + pUser:GetExtData8(292) + pUser:GetExtData8(293) + pUser:GetExtData8(436) end}								
								
								
task[33] = {name = LANGUAGE_LLD_0108,format_str = LANGUAGE_LLD_0109,count = 5,level = 1,document=LANGUAGE_LLD_0166,pic = 12
								,count_callback = function(pUser) return pUser:GetExtData8(14) + pUser:GetExtData8(587) end}
task[34] = {name = LANGUAGE_LLD_0108,format_str = LANGUAGE_LLD_0109,count = 8,level = 2,document=LANGUAGE_LLD_0166,pic = 12
								,count_callback = function(pUser) return pUser:GetExtData8(14) + pUser:GetExtData8(587) end}								
task[35] = {name = LANGUAGE_LLD_0108,format_str = LANGUAGE_LLD_0109,count = 10,level = 3,document=LANGUAGE_LLD_0166,pic = 12
								,count_callback = function(pUser) return pUser:GetExtData8(14) + pUser:GetExtData8(587) end}
																
								
task[36] = {name = LANGUAGE_LLD_0110,format_str = LANGUAGE_LLD_0111,count = 3,level = 1,document=LANGUAGE_LLD_0166,pic = 13
								,count_callback = function(pUser) return pUser:GetExtData8(588) end}
task[37] = {name = LANGUAGE_LLD_0110,format_str = LANGUAGE_LLD_0111,count = 8,level = 2,document=LANGUAGE_LLD_0166,pic = 13
								,count_callback = function(pUser) return pUser:GetExtData8(588) end}								
task[38] = {name = LANGUAGE_LLD_0110,format_str = LANGUAGE_LLD_0111,count = 15,level = 3,document=LANGUAGE_LLD_0166,pic = 13
								,count_callback = function(pUser) return pUser:GetExtData8(588) end}								
								
task[39] = {name = LANGUAGE_LLD_0112,format_str = LANGUAGE_LLD_0113,count = 4, level = 1,document=LANGUAGE_LLD_0166,pic = 14
								,count_callback = function(pUser) return pUser:GetExtData32(399) end}
task[40] = {name = LANGUAGE_LLD_0112,format_str = LANGUAGE_LLD_0113, count = 12,level = 2,document=LANGUAGE_LLD_0166,pic = 14
								,count_callback = function(pUser) return pUser:GetExtData32(399) end}								
task[41] = {name = LANGUAGE_LLD_0112,format_str = LANGUAGE_LLD_0113,count = 20,level = 3,document=LANGUAGE_LLD_0166,pic = 14
								,count_callback = function(pUser) return pUser:GetExtData32(399) end}								
								
task[42] = {name = LANGUAGE_LLD_0114,format_str = LANGUAGE_LLD_0115,count = 3, level = 1,document=LANGUAGE_LLD_0166,pic = 15
								,count_callback = function(pUser) return pUser:GetExtData32(400) end}
task[43] = {name = LANGUAGE_LLD_0114,format_str = LANGUAGE_LLD_0115, count = 8, level = 2,document=LANGUAGE_LLD_0166,pic = 15
								,count_callback = function(pUser) return pUser:GetExtData32(400) end}								
task[44] = {name = LANGUAGE_LLD_0114,format_str = LANGUAGE_LLD_0115,count = 12, level = 3,document=LANGUAGE_LLD_0166,pic = 15
								,count_callback = function(pUser) return pUser:GetExtData32(400) end}								
								
task[45] = {name = LANGUAGE_LLD_0116,format_str = LANGUAGE_LLD_0117,count = 1, level = 1,document=LANGUAGE_LLD_0166,pic = 16
								,count_callback = function(pUser) return pUser:GetExtData8(576) end}
task[46] = {name = LANGUAGE_LLD_0116,format_str = LANGUAGE_LLD_0117,count = 3, level = 2,document=LANGUAGE_LLD_0166,pic = 16
								,count_callback = function(pUser) return pUser:GetExtData8(576) end}								
task[47] = {name = LANGUAGE_LLD_0116,format_str = LANGUAGE_LLD_0117,count = 8, level = 3,document=LANGUAGE_LLD_0166,pic = 16
								,count_callback = function(pUser) return pUser:GetExtData8(576) end}								
								
task[48] = {name = LANGUAGE_LLD_0118,format_str = LANGUAGE_LLD_0119,count = 2, level = 1,document=LANGUAGE_LLD_0166,pic = 17
								,count_callback = function(pUser) return pUser:GetExtData32(401) end}
task[49] = {name = LANGUAGE_LLD_0118,format_str = LANGUAGE_LLD_0119,count = 5, level = 2,document=LANGUAGE_LLD_0166,pic = 17
								,count_callback = function(pUser) return pUser:GetExtData32(401) end}								
task[50] = {name = LANGUAGE_LLD_0118,format_str = LANGUAGE_LLD_0119,count = 8, level = 3,document=LANGUAGE_LLD_0166,pic = 17
								,count_callback = function(pUser) return pUser:GetExtData32(401) end}								
							
task[51] = {name = LANGUAGE_LLD_0120,format_str = LANGUAGE_LLD_0123,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 18
								,count_callback = function(pUser) return pUser:GetExtData8(577) end}
task[52] = {name = LANGUAGE_LLD_0121,format_str = LANGUAGE_LLD_0123,count = 3,level = 2,document=LANGUAGE_LLD_0166,pic = 18
								,count_callback = function(pUser) return pUser:GetExtData8(578) + pUser:GetExtData8(579) end}
task[53] = {name = LANGUAGE_LLD_0122,format_str = LANGUAGE_LLD_0123,count = 5,level = 3,document=LANGUAGE_LLD_0166,pic = 18
								,count_callback = function(pUser) return pUser:GetExtData8(579) end}																
								
task[54] = {name = LANGUAGE_LLD_0124,format_str = LANGUAGE_LLD_0127,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 19
								,count_callback = function(pUser) return pUser:GetExtData8(580) end}
task[55] = {name = LANGUAGE_LLD_0125,format_str = LANGUAGE_LLD_0127, count = 1,level = 2,document=LANGUAGE_LLD_0166,pic = 19
								,count_callback = function(pUser) return pUser:GetExtData8(581)end}							
task[56] = {name = LANGUAGE_LLD_0126,format_str = LANGUAGE_LLD_0127,count = 2,level = 3,document=LANGUAGE_LLD_0166,pic = 19
								,count_callback = function(pUser) return pUser:GetExtData8(581) end}								
								
								
task[57] = {name = LANGUAGE_LLD_0128,format_str = LANGUAGE_LLD_0129,count = 3,level = 1,document=LANGUAGE_LLD_0166,pic = 20
								,count_callback = function(pUser) return pUser:GetExtData8(582) end}
task[58] = {name = LANGUAGE_LLD_0128,format_str = LANGUAGE_LLD_0129, count = 8,level = 2,document=LANGUAGE_LLD_0166,pic = 20
								,count_callback = function(pUser) return pUser:GetExtData8(582) end}								
task[59] = {name = LANGUAGE_LLD_0128,format_str = LANGUAGE_LLD_0129,count = 20,level = 3,document=LANGUAGE_LLD_0166,pic = 20
								,count_callback = function(pUser) return pUser:GetExtData8(582) end}								
								
								
task[60] = {name = LANGUAGE_LLD_0130,format_str = LANGUAGE_LLD_0131,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 21
								,count_callback = function(pUser) return pUser:GetExtData8(583) end}
task[61] = {name = LANGUAGE_LLD_0130,format_str = LANGUAGE_LLD_0131, count = 5,level = 2,document=LANGUAGE_LLD_0166,pic = 21
								,count_callback = function(pUser) return pUser:GetExtData8(583) end}								
task[62] = {name = LANGUAGE_LLD_0130,format_str = LANGUAGE_LLD_0131,count = 15,level = 3,document=LANGUAGE_LLD_0166,pic = 21
								,count_callback = function(pUser) return pUser:GetExtData8(583) end}								
								
task[63] = {name = LANGUAGE_LLD_0132,format_str = LANGUAGE_LLD_0133,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 22
								,count_callback = function(pUser) return pUser:GetExtData8(140) end}
task[64] = {name = LANGUAGE_LLD_0132,format_str = LANGUAGE_LLD_0133, count = 2,level = 2,document=LANGUAGE_LLD_0166,pic = 22
								,count_callback = function(pUser) return pUser:GetExtData8(140) end}								
task[65] = {name = LANGUAGE_LLD_0132,format_str = LANGUAGE_LLD_0133,count = 8,level = 3,document=LANGUAGE_LLD_0166,pic = 22
								,count_callback = function(pUser) return pUser:GetExtData8(140) end}								
								
task[66] = {name = LANGUAGE_LLD_0134,format_str = LANGUAGE_LLD_0135,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 23
								,count_callback = function(pUser) return pUser:GetExtData8(114) + pUser:GetExtData8(115) end}
task[67] = {name = LANGUAGE_LLD_0134,format_str = LANGUAGE_LLD_0135,count = 5,level = 2,document=LANGUAGE_LLD_0166,pic = 23
								,count_callback = function(pUser) return pUser:GetExtData8(114) + pUser:GetExtData8(115) end}								
task[68] = {name = LANGUAGE_LLD_0134,format_str = LANGUAGE_LLD_0135,count = 10,level = 3,document=LANGUAGE_LLD_0166,pic = 23
								,count_callback = function(pUser) return pUser:GetExtData8(114) + pUser:GetExtData8(115) end}								
								
task[69] = {name = LANGUAGE_LLD_0136,format_str = LANGUAGE_LLD_0137,count = 2,level = 1,document=LANGUAGE_LLD_0166,pic = 24
								,count_callback = function(pUser) return pUser:GetExtData8(113) end}
task[70] = {name = LANGUAGE_LLD_0136,format_str = LANGUAGE_LLD_0137, count = 5,level = 2,document=LANGUAGE_LLD_0166,pic = 24
								,count_callback = function(pUser) return pUser:GetExtData8(113) end}
task[71] = {name = LANGUAGE_LLD_0136,format_str = LANGUAGE_LLD_0137,count = 10,level = 3,document=LANGUAGE_LLD_0166,pic = 24
								,count_callback = function(pUser) return pUser:GetExtData8(113) end}
																
task[72] = {name = LANGUAGE_LLD_0164,format_str = LANGUAGE_LLD_0165,count = 1,level = 2,document=LANGUAGE_LLD_0166,pic = 26
								,count_callback = function(pUser) return pUser:GetExtData8(64) end}

task[73] = {name = LANGUAGE_SSJ_0113,format_str = LANGUAGE_LLD_0137,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 27
								,count_callback = function(pUser) return pUser:GetExtData32(440) end}
task[74] = {name = LANGUAGE_SSJ_0113,format_str = LANGUAGE_LLD_0137, count = 3,level = 2,document=LANGUAGE_LLD_0166,pic = 27
								,count_callback = function(pUser) return pUser:GetExtData32(440) end}
task[75] = {name = LANGUAGE_SSJ_0113,format_str = LANGUAGE_LLD_0137,count = 10,level = 3,document=LANGUAGE_LLD_0166,pic = 27
								,count_callback = function(pUser) return pUser:GetExtData32(440) end}

task[76] = {name = LANGUAGE_SSJ_0114,format_str = LANGUAGE_LLD_0137,count = 1,level = 1,document=LANGUAGE_LLD_0166,pic = 28
								,count_callback = function(pUser) return pUser:GetExtData32(441) end}
task[77] = {name = LANGUAGE_SSJ_0114,format_str = LANGUAGE_LLD_0137, count = 2,level = 2,document=LANGUAGE_LLD_0166,pic = 28
								,count_callback = function(pUser) return pUser:GetExtData32(441) end}
task[78] = {name = LANGUAGE_SSJ_0114,format_str = LANGUAGE_LLD_0137,count = 5,level = 3,document=LANGUAGE_LLD_0166,pic = 28
								,count_callback = function(pUser) return pUser:GetExtData32(441) end}









--task[73] = {name = LANGUAGE_LLD_0162,format_str = LANGUAGE_LLD_0163,count = 1,level = 2,document=LANGUAGE_LLD_0166,pic = 25
--								,count_callback = function(pUser) return pUser:GetExtData8(89) end}

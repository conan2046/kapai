--22582.lua--技能书宝箱（元宝购买）
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

Award_Item_List = 
{
	--	技能书道具  odd/100000
		[1]={   912 ,   6250    },  --  物理减免加强
		[2]={   915 ,   6250    },  --  忽视抗物理
		[3]={   918 ,   6250    },  --  忽视抗法术
		[4]={   921 ,   6250    },  --  单体加血强化
		[5]={   924 ,   6250    },  --  群体加血强化
		[6]={   927 ,   6250    },  --  致命打击
		[7]={   930 ,   6250    },  --  韧性
		[8]={   948 ,   6250    },  --  抗混乱
		[9]={   951 ,   6250    },  --  抗昏睡
		[10]={  957 ,   6250    },  --  命中强化
		[11]={  564 ,   6250    },  --  神将提升伤害
		[12]={  565 ,   6250    },  --  神将提升防御
		[13]={  566 ,   6250    },  --  神将提升气血
		[14]={  567 ,   6250    },  --  神将提升速度
		[15]={  597 ,   6250    },  --  反伤
		[16]={  598 ,   6250    },  --  反伤抵抗
}



function Main(pUser,pos,num)

	pItem=pUser:GetItem(pos)
	if pItem == nil or num > 200 then
		return
	end
	pUser:DelPackage(pos,num)
	
	reward ={} --奖励数组 item_id num
	local size = 0
	local isIn = 0
	for counter = 1 ,num, 1 do
		isIn = 0
		local reward_id = 0
		local reward_num = 0
		local odds=math.random(100000)
		local sum_odds = 0
		for item_counter=1,#Award_Item_List,1 do
			sum_odds = sum_odds + Award_Item_List[item_counter][2]
			if sum_odds >= odds then
				for reward_counter=1,#reward,1 do
					if reward[reward_counter][1] == Award_Item_List[item_counter][1] then
						reward[reward_counter][2] = reward[reward_counter][2]+1
						isIn = 1
					end 
				end --end of for reward
				if isIn == 0 then
					reward[size+1]={Award_Item_List[item_counter][1],1}
					size = size + 1
				end
				break
			end  --end of if sum_odds >= odds
		end -- end of for Award_Item_List
	end -- end  of for num

	--发送奖励
	for count =1  ,#reward,1 do
		pUser:AddPackage(reward[count][1],reward[count][2])
	    j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_538..j.GetItemName(reward[count][1]).."*"..reward[count][2] .."[/c]")
		j.SaveDate(pUser,706,reward[count][1],LANGUAGE_TRANSFORM_539)
	end --end of for reward
end


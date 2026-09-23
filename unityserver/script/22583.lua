--22583.lua--技能书宝箱（绑元购买）
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

Award_Item_List = 
{
	--	技能书道具  odd/100000
		[1]={   912 ,   8330    },  --  物理减免加强
		[2]={   915 ,   8330    },  --  忽视抗物理
		[3]={   918 ,   8330    },  --  忽视抗法术
		[4]={   921 ,   8330    },  --  单体加血强化
		[5]={   924 ,   8330    },  --  群体加血强化
		[6]={   927 ,   8330    },  --  致命打击
		[7]={   930 ,   8330    },  --  韧性
		[8]={   948 ,   8330    },  --  抗混乱
		[9]={   951 ,   8330    },  --  抗昏睡
		[10]={  957 ,   8330    },  --  命中强化
		[11]={  597 ,   8330    },  --  反伤
		[12]={  598 ,   8370    },  --  反伤抵抗
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
	    j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4586..j.GetItemName(reward[count][1]).."*"..reward[count][2] .."[/c]")
		j.SaveDate(pUser,707,reward[count][1],LANGUAGE_TRANSFORM_4587)
	end --end of for reward
end


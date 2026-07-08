struct SItemTemplate
{
	SItemTemplate():
		pScript(NULL)
	{
		quality = 0;
		useType = 0;
		level = 0;
		id = 0;
		type = 0;
		pic = 0;
		activityId = 0;
		jiage = 0;
		sortPriority = 0;
		limitTime = 0;
		subValue = 0;
		name.clear();
		describe.clear();
		subVec.clear();
	}

	uint8 quality;	// 品质
    uint8 useType;  // 使用类型
    uint16 level;   // 需求等级
    uint16 id;      // 物品id
    uint16 type;    // 种类
    uint16 pic;     // 图片
	uint16 activityId;  // 活动id
    int jiage;      	// 价格
    int sortPriority;	// 从小到大排序
	uint32 limitTime;	// 额外存在时间
	uint32 subValue;	// 额外数值
    string name;		// 名字
	string describe;//说明
};

#define MAX_ADD_ATTR_NUM 9

struct SItemInstance
{
	uint8 level;	//强化等级
	uint8 quality;	//品质
	uint16 tmplId;
	int extData;
	uint16 num;
	
	int GetItemValue();
	int GetAddAttrType(uint8 pos);
	void SetAddAttrType(uint8 pos,uint16 val);
	void SetAddAttrVal(uint8 pos,uint16 val);
	int GetAddAttrVal(uint8 pos);
};

struct SPlantSeed
{
	uint16 itemId;
	string treeName;
	uint16 step_pic1;		// 模型1
	uint16 step_pic2;		// 模型2
	uint16 step_pic3;		// 模型3
	uint32 ripeTimeGap;		// 成熟时间间隔
	uint32 wateringTimeGap;
	uint32 wateringReduceTime;
	uint16 wateringLimit;	// 浇水次数上限
	uint32 killBugTimeGap;
	uint16 killBugLimit;	// 除虫次数上限
	uint8 stealNumLimit;	// 偷取次数上限
	uint8 gainType;
	uint32 gainValue;
	uint32 gainItemId;
	uint8 priceType;
	uint32 price;
	uint32 witheredTimeGap;	// 枯萎时间间隔
};



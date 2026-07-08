#ifndef _UNIT_BASIC_ATTR_
#define _UNIT_BASIC_ATTR_

#include <vector>

struct SAttrData;

struct SUnitBasicAttr
{
	SUnitBasicAttr()
	{
		Clear();
	}
	void Clear()
	{
		attack = 0;
		wufang = 0;
		fafang = 0;
		maxHp = 0;
		speed = 0;
		mingzhong = 0;
		shanbi = 0;
		baoji = 0;
		baojikang = 0;
		mingzhongLv = 0;
		shanbiLv = 0;
		baojiLv = 0;
		baojikangLv = 0;
		zengshangLv = 0;
		wumianLv = 0;
		famianLv = 0;
		baojiAdd = 0;
		fanjiLv = 0;
		fanjikangLv = 0;
		fanjiAdd = 0;
		lianjiLv = 0;
		lianjikangLv = 0;
		lianjiAdd = 0;
		fanzhenLv = 0;
		fanzhenkangLv = 0;
		fanzhenAdd = 0;
		fumianAdd = 0;
		fumianKangAdd = 0;
		attack_percent_fight = 0;
		wufang_percent_fight = 0;
		fafang_percent_fight = 0;
		speed_percent_fight = 0;
		attackEx = 0;
		wufangEx = 0;
		fafangEx = 0;
		maxHpEx = 0;
		attackBase = 0;
		wufangBase = 0;
		fafangBase = 0;
		maxHpBase = 0;
		attackRatio = 0;
		wufangRatio = 0;
		fafangRatio = 0;
		maxHpRatio = 0;
	}
	
	void CalVaryAttr(const SUnitBasicAttr &other,float ratio)
	{
		attack *= other.attack/ratio;
		wufang *= other.wufang/ratio;
		fafang *= other.fafang/ratio;
		maxHp *= other.maxHp/ratio;
		speed *= other.speed/ratio;
		mingzhong *= other.mingzhong/ratio;
		shanbi *= other.shanbi/ratio;
		baoji *= other.baoji/ratio;
		baojikang *= other.baojikang/ratio;
		mingzhongLv *= other.mingzhongLv/ratio;
		shanbiLv *= other.shanbiLv/ratio;
		baojiLv *= other.baojiLv/ratio;
		baojikangLv *= other.baojikangLv/ratio;
		zengshangLv *= other.zengshangLv/ratio;
		wumianLv *= other.wumianLv/ratio;
		famianLv *= other.famianLv/ratio;
		baojiAdd *= other.baojiAdd/ratio;
		fanjiLv *= other.fanjiLv/ratio;
		fanjikangLv *= other.fanjikangLv/ratio;
		fanjiAdd *= other.fanjiAdd/ratio;
		lianjiLv *= other.lianjiLv/ratio;
		lianjikangLv *= other.lianjikangLv/ratio;
		lianjiAdd *= other.lianjiAdd/ratio;
		fanzhenLv *= other.fanzhenLv/ratio;
		fanzhenkangLv *= other.fanzhenkangLv/ratio;
		fanzhenAdd *= other.fanzhenAdd/ratio;
		fumianAdd *= other.fumianAdd/ratio;
		fumianKangAdd *= other.fumianKangAdd/ratio;
	}
	
	void AddAttrValue(vector<SAttrData> &attrList);
	
	int attack;
	int wufang;
	int fafang;
	int speed;
	int mingzhong;
	int shanbi;
	int baoji;
	int baojikang;
	int mingzhongLv;
	int shanbiLv;
	int baojiLv;
	int baojikangLv;
	int zengshangLv;
	int wumianLv;
	int famianLv;
	int baojiAdd;
	int fanjiLv;
	int fanjikangLv;
	int fanjiAdd;
	int lianjiLv;
	int lianjikangLv;
	int lianjiAdd;
	int fanzhenLv;
	int fanzhenkangLv;
	int fanzhenAdd;
	int fumianAdd;
	int fumianKangAdd;

	int attack_percent_fight;
	int wufang_percent_fight;
	int fafang_percent_fight;
	int speed_percent_fight;
	int attackEx;
	int wufangEx;
	int fafangEx;
	
	int attackBase;
	int wufangBase;
	int fafangBase;
	int attackRatio;
	int wufangRatio;
	int fafangRatio;
	int maxHpRatio;

	int64 maxHp;
	int64 maxHpEx;
	int64 maxHpBase;
};



#endif


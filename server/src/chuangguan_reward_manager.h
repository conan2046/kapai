#ifndef _chuangguan_reward_manager_h_
#define _chuangguan_reward_manager_h_
#include <map>
#include "singleton.h"

typedef std::map<int, int> CGDropMap;
typedef std::map<int, int>::iterator CGDropMapIt;
class ChuangguanRewardManager
{
public:
	ChuangguanRewardManager();
	~ChuangguanRewardManager();

public:
	bool Init();

	int GetDropId(int type);

private:
	CGDropMap m_dropIds;
};
#define sChuangguanRewardManager boost::details::pool::singleton_default<ChuangguanRewardManager>::instance()

#endif // _chuangguan_reward_manager_h_

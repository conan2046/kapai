#ifndef _FISH_SINGLE_PLAYER_H_
#define _FISH_SINGLE_PLAYER_H_

#include "self_typedef.h"
#include <boost/thread/mutex.hpp>
#include <map>

class CUser;

class CFishSinglePlayerService
{
public:
	static CFishSinglePlayerService& Instance();
	bool IsEnabled();
	void Join(CUser* pUser);
	void SendBasket(CUser* pUser);
	void Start(CUser* pUser, uint8 face);
	void Collect(CUser* pUser, uint16 slotIndex);
	void SyncTime(CUser* pUser);
	void Stop(CUser* pUser);
	void Exit(CUser* pUser);
	void Tick(CUser* pUser);

private:
	struct Session
	{
		Session():joined(false),fishing(false),face(2),duration(0),finishAt(0){}
		bool joined;
		bool fishing;
		uint8 face;
		uint16 duration;
		time_t finishAt;
	};

	CFishSinglePlayerService(){}
	CFishSinglePlayerService(const CFishSinglePlayerService&);
	CFishSinglePlayerService& operator=(const CFishSinglePlayerService&);
	std::map<uint32, Session> m_sessions;
	boost::mutex m_mutex;
};

#endif

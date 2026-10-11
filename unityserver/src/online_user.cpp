#include "online_user.h"
#include "user.h"

ShareUserPtr COnlineUser::GetUserByRoleId(uint32 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	ShareUserPtr ptr;
	m_roleIdList.Find(id,ptr);
	return ptr;
}

ShareUserPtr COnlineUser::GetUserBySock(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	ShareUserPtr ptr;
	m_sockIdList.Find(id,ptr);
	return ptr;
}

CUser *COnlineUser::AddUser(int sock,uint32 userId)
{
	ShareUserPtr ptr;
	CUser *pUser;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pUser = new CUser;
		if(pUser == NULL)
			return NULL;
		ptr.reset(pUser);
		m_sockIdList.Insert(sock,ptr);
	}
	pUser->SetSock(sock);
	pUser->SetUserId(userId);
	pUser->SetRoleId(0);
	return pUser;
}

void COnlineUser::SetRoleId(int sock,uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	ShareUserPtr ptr;
	if (m_sockIdList.Find(sock,ptr))
	{
		ptr->SetRoleId(roleId);
		m_roleIdList.Erase(roleId);
		m_roleIdList.Insert(roleId,ptr);
	}
}

void COnlineUser::DelUser(CUser *pU,bool isRelease)
{
	if(pU == NULL)
		return;
	int sock = pU->GetSock();
	uint32 roleId = pU->GetRoleId();

	CUser *pUser = NULL;
	ShareUserPtr ptr;
	{//find user 
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(sock < 0)
		{
			m_roleIdList.Find(roleId,ptr);
		}
		else
		{
			m_sockIdList.Find(sock,ptr);
		}
	}
	pUser = ptr.get();
	if(pUser == NULL)
		return;

	if(pUser != pU)
		return;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	pUser->SaveData(pDb);
	pUser->SaveLoginLog(pDb);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(sock < 0)
		{
			m_roleIdList.Erase(roleId,ptr);
		}
		else
		{
			m_sockIdList.Erase(sock,ptr);
			pUser = ptr.get();
			if (pUser != NULL)
			{
				pUser->SetSock(-1);
				if(isRelease)
				{
					if(pUser->GetFightId() == 0)
						m_roleIdList.Erase(pUser->GetRoleId());
				}
			}
		}
	}
}

//sock new user sock
CUser *COnlineUser::ReLogin(int sock,uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	ShareUserPtr pSrc;
	m_sockIdList.Erase(sock,pSrc);
	CUser *pUser = pSrc.get();
	if (pUser != NULL)
		pUser->SetSock(-1);

	ShareUserPtr ptrOld;
	m_roleIdList.Erase(roleId,ptrOld);
	CUser *pOld = ptrOld.get();
	if(pOld == NULL)
		return NULL;
	if(pOld->GetSock() > 0)
		m_sockIdList.Erase(pOld->GetSock());

	pOld->SetSock(sock);
	m_sockIdList.Insert(sock,ptrOld);
	m_roleIdList.Insert(roleId,ptrOld);
	pOld->UserLogout(false);
	return pOld;
}

static bool EachUser(uint32,ShareUserPtr pUser,boost::function<void(CUser*)> *f)
{
	CUser *p = pUser.get();
	if(p != NULL)
	{
		(*f)(p);
	}
	return true;
}

void COnlineUser::ForEachUser(boost::function<void(CUser*)> f)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_roleIdList.ForEach(boost::bind(EachUser,_1,_2,&f));
}

static bool AddAllUser(uint32 id,ShareUserPtr,list<uint32> *pUserList)
{
	pUserList->push_back(id);
	return true;
}

void COnlineUser::GetUserList(list<uint32> &userList)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_roleIdList.ForEach(boost::bind(AddAllUser,_1,_2,&userList));
}

void COnlineUser::ForEachUserNoLock(boost::function<void(CUser*)> f)
{
	m_roleIdList.ForEach(boost::bind(EachUser,_1,_2,&f));
}


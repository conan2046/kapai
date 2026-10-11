
class CScene
{
public:
	CScene(uint16 id,uint16 mapId,const char *name,char *monsters,int mapFile);
	~CScene();
	void Exit(CUser*);
	uint16 GetId();
	uint16 GetMapId();
	uint16 GetSrcSceneId();
	const char *GetName();
	void AddJumpPoint(uint16 x,uint16 y,uint16 toX,uint16 toY,uint16 sceneId);
	int GetState();
	void SetState(int state);
	bool Clear();
	void DelNpc(uint16 id,uint16 index);
	int GetUserNum();
	void AddNpc(uint16 tmplId, uint16 x, uint16 y, uint8 direct);
	bool CreateTeam(CUser *pUser,uint32 request);
	void UpdateTeamData(uint32 teamId);

	void AddNpcWithIndex(uint16 tmplId,uint16 pic, uint16 x, uint16 y, uint8 direct,uint16 index,const char *name,uint8 type);

	void AddVisibleMonsterBoss(const char *name,uint16 pic,uint16 center_x,uint16 center_y,uint16 radius,uint8 type,time_t createTime);
	int GetVisibleMonsterBossNum();
	
};




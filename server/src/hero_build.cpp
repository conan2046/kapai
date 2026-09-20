#include "user.h"
#include "hero_build.h"

bool CUser::SetHeroBuild(uint16 heroId, uint8 branch, uint8 strategy, string &error)
{
    boost::recursive_mutex::scoped_lock lock(m_mutex);
    if (!HeroBuild::Supported(heroId) || NoLockGetPet(heroId).get() == NULL)
    {
        error = "该神将尚未开放流派，或尚未拥有";
        return false;
    }
    if (!HeroBuild::Valid(branch, strategy))
    {
        error = "流派或策略无效";
        return false;
    }
    if (GetFightId() != 0)
    {
        error = "战斗中不能切换流派与策略";
        return false;
    }
    const uint16 key = HeroBuild::SaveKey(heroId);
    const uint8 previous = GetExtData8(key);
    const uint8 selected = HeroBuild::Encode(branch, strategy);
    if (previous == selected) return true;
    CGetDbConnect connection;
    CDatabaseSql *database = connection.GetDbConnect();
    if (database == NULL)
    {
        error = "暂时无法保存，请稍后重试";
        return false;
    }
    SetExtData8(key, selected);
    if (!NoLockSaveData(database))
    {
        SetExtData8(key, previous);
        error = "流派保存失败，已保留原设置";
        return false;
    }
    return true;
}

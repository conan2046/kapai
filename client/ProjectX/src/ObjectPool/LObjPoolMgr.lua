--[[
对象池管理器，分普通类对象池+资源游戏对象池
]]
require "ObjectPool.LObjectPool"
require "ObjectPool.LGameObjectPool"
LObjPoolMgr = {}
LObjPoolMgr.__index = LObjPoolMgr
local this = LObjPoolMgr
this._poolNode = nil;
--luaTable对象池
this.m_ObjectPools = {}--new Dictionary<string, object>();
--GameObject对象池
this.m_GameObjectPools = {}--new Dictionary<string, GameObjectPool>();

function LObjPoolMgr.Awake()
    local poolNode = AppDef.Director:getRunningScene():getChildByName("GameMapLayer");
    if poolNode == nil then
        poolNode = cc.Node:create()
        AppDef.Director:getRunningScene():addChild(poolNode,AppDef.GameZOrder.PoolLayer);
    end
    this._poolNode = poolNode
end

function LObjPoolMgr.CreateGameObjectPool(poolName, initSize, maxSize, prefab)


    local pool = LGameObjectPool.New(poolName, prefab, initSize, maxSize, this._poolNode);
    this.m_GameObjectPools[poolName] = pool;
    return pool;
end

function LObjPoolMgr.GetGameObjectPool(poolName)
    if this.m_GameObjectPools[poolName] ~= nil then
        return this.m_GameObjectPools[poolName];
    end
    return nil;
end

function LObjPoolMgr.GetGameObjectAvailableNum(poolName)
    local pool = this.GetGameObjectPool(poolName)
    if pool == nil then
        return 0
    end
    return pool:GetAvailableNum()
end

function LObjPoolMgr.GetGameObject(poolName)
    local result = nil;
    if this.m_GameObjectPools[poolName] ~= nil then
        local pool = this.m_GameObjectPools[poolName];
        result = pool:NextAvailableObject();
        if result == nil then
            --logWarn("No object available in pool. Consider setting fixedSize to false.: " .. poolName);
        end
    else
        --logError("Invalid pool name specified: " .. poolName);
    end
    return result;
end

function LObjPoolMgr.ReleaseGameObject(poolName, go)
    if this.m_GameObjectPools[poolName] ~= nil then
        local pool = this.m_GameObjectPools[poolName];
        pool:ReturnObjectToPool(poolName, go);
    else
        --logWarn("No pool available with name: " .. poolName);
    end
end

--------------------------------------------------------------------------------------------------
---lua table对象池相关方法
--------------------------------------------------------------------------------------------------
function LObjPoolMgr.CreatePool(tableName, actionOnGet,actionOnRelease)
    local pool = LObjectPool.New(actionOnGet, actionOnRelease);
    this.m_ObjectPools[tableName] = pool;
    return pool;
end

function LObjPoolMgr.GetPool(tableName)
    return this.m_ObjectPools[tableName]
end

function LObjPoolMgr.Get(tableName)
    local pool = this.GetPool(tableName);
    if pool ~= nil then
        return pool:Get();
    end
    return nil
end

function LObjPoolMgr.Release(tableName, obj)
    local pool = this.GetPool(tableName);
    if pool ~= nil then
        return pool:Release(obj);
    end
    return nil
end


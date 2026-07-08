--[[
GameObject 对象池
]]
LGameObjectPool = {}
LGameObjectPool.__index = LGameObjectPool

function LGameObjectPool.New(poolName, poolObjectPrefab, initCount, maxSize, pool)
	local o = {}
	setmetatable(o,LGameObjectPool)
	o:ctor(poolName, poolObjectPrefab, initCount, maxSize, pool)
	return o
end

function LGameObjectPool:ctor(poolName, poolObjectPrefab, initCount, maxSize, pool)
	self.poolName = poolName;
	self.poolSize = initCount;
    self.maxSize = maxSize;
    self.poolRoot = pool;
    self.poolObjectPrefab = poolObjectPrefab;
    self.availableObjStack = {}
	--populate the pool
	self:GenObjPool()
end

--[[
生成对象
]]
function LGameObjectPool:GenObjPool()
	
	self:AddObjectToPool(self.poolObjectPrefab);
	for i = 2, self.poolSize do
		local obj = self.poolObjectPrefab:clone();
		--obj.name = self.poolName .. "_" .. i
		self:AddObjectToPool(obj);
	end
end

function LGameObjectPool:AddObjectToPool(go)
	--add to pool
	go:setName(self.poolName)
    go:setVisible(false);
    table.insert(self.availableObjStack,go);
    self.poolRoot:addChild(go);
    -- go.transform:SetParent(self.poolRoot, false);
end

-- function LGameObjectPool:Test()
-- 	local function Update()
-- 		print("Update",#self.availableObjStack)
-- 		if #self.availableObjStack > 0 then
-- 			local go = self.availableObjStack[#self.availableObjStack]
-- 			local children = go:getChildren();
-- 			for i=1,#children do
-- 				print("self.poolObjectPrefab  childName=",children[i]:getName())
				
-- 	    	end
-- 	    end
-- 	end
-- 	 Utils:schedule(pNode, Update, 0)
-- end

function LGameObjectPool:GetAvailableNum()
	return #self.availableObjStack
end

function LGameObjectPool:NextAvailableObject()
	-- print("NextAvailableObject")
    local go = nil;
	if #self.availableObjStack > 0 then
		go = self.availableObjStack[#self.availableObjStack]
		table.remove(self.availableObjStack, #self.availableObjStack)
	else
		go = self.poolObjectPrefab:clone();
		-- self:AddObjectToPool(self.poolObjectPrefab:clone());
		--Debug.LogWarning("No object available & cannot grow pool: " + poolName);
	end
	if go ~= nil then
		

    	go:setVisible(true);

  --   	local children = go:getChildren();
		-- for i=1,#children do
		-- 	print("self.poolObjectPrefab  childName=",children[i]:getName())
			
	 --    end
	end
    return go;
end

function LGameObjectPool:ReturnObjectToPool(pool, po)
    if self.poolName == pool then
    	if #self.availableObjStack >= self.poolSize then
    		return
    	end
        self:AddObjectToPool(po);
	else
		--Debug.LogError(string.Format("Trying to add object to incorrect pool {0} ", poolName));
	end
end
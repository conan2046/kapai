local Collector = require("Validation.RuntimeSnapshotCollector")
local Sha256 = require("Validation.Sha256")
local Replay = { started=false }

local function trace(message)
    local file=io.open((AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_OUTPUT or "cocos-session.jsonl")..".trace.log","a")
    if file then file:write(os.date("!%H:%M:%S")," ",message,"\n");file:close() end
end

local function nowMs() return math.floor(os.clock()*1000) end
local function vectorCenter(node)
    local size=node:getContentSize(); local point=node:convertToWorldSpace(cc.p(size.width/2,size.height/2)); return point
end

local function dispatchTouch(node, point, operation)
    if type(projectx_validation_dispatch_touch)~="function" then
        return false,"native GLView validation touch bridge is unavailable"
    end
    local function emit(phase,x,y)
        local dispatched,dispatchError=pcall(projectx_validation_dispatch_touch,phase,0,x,y)
        if not dispatched then return false,"native GLView touch dispatch failed: "..tostring(dispatchError) end
        return true,nil
    end
    if operation=="scroll" or operation=="drag" then
        local began,beginError=emit("began",point.x,point.y); if not began then return false,beginError end
        local moved,moveError=emit("moved",point.x,point.y+80); if not moved then return false,moveError end
        local ended,endError=emit("ended",point.x,point.y+80); if not ended then return false,endError end
    else
        local began,beginError=emit("began",point.x,point.y); if not began then return false,beginError end
        local ended,endError=emit("ended",point.x,point.y); if not ended then return false,endError end
    end
    return true,nil
end

local function controlIndex(scenario)
    local result={}
    for _,definition in ipairs(scenario.actions or {}) do result[definition.action.cocosPath]=definition.action.targetControlId end
    return result
end

local function protocolComplete(expected,packets)
    for _,item in ipairs(expected or {}) do
        local found=false
        for _,packet in ipairs(packets) do
            if packet.direction==item.direction and packet.command==item.command and (item.op==nil or packet.op==item.op) then found=true; break end
        end
        if not found then return false end
    end
    return true
end

local function changed(before,after)
    local left={}; local right={}; local result={}
    for _,row in ipairs(before) do left[row.nodePath]=json.encode(row) end
    for _,row in ipairs(after) do right[row.nodePath]=json.encode(row) end
    for key,value in pairs(left) do if right[key]~=value then table.insert(result,key) end end
    for key,_ in pairs(right) do if left[key]==nil then table.insert(result,key) end end
    table.sort(result); return result
end

local function storeTree(hash,tree)
    local outputPath=AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_OUTPUT or "cocos-session.jsonl"
    local directory=outputPath:match("^(.*)[/\\]") or "."
    local fileName="cocos-tree-"..string.upper(hash)..".json"
    local path=directory.."/"..fileName
    local existing=io.open(path,"rb")
    if existing then existing:close(); return fileName end
    local file=assert(io.open(path,"wb")); file:write(Collector.treeJson(tree)); file:close()
    return fileName
end

local function failureRecord(scenario,definition,sequence,message,inputFingerprint,before,beforeHash)
    local zero=string.rep("0",64)
    before=before or {}; beforeHash=beforeHash or zero
    local treeRef=#before>0 and storeTree(beforeHash,before) or nil
    return {schemaVersion=1,recordType="action",module=scenario.module,stateId=definition.expectedState,actionId=definition.actionId,controlId=definition.action.targetControlId,sequence=sequence,timestampUtc=os.date("!%Y-%m-%dT%H:%M:%SZ"),engine="cocos",operationType=definition.action.type,inputMode="engine-input-replay",inputCoordinates={x=0,y=0,coordinateSpace="1334x750-top-left"},preUiTreeHash=beforeHash,preUiTree={},preUiTreeRef=treeRef,preUiTreeNodeCount=#before,targetNodePath=definition.action.cocosPath,targetSemanticId=definition.expectedHit,hitTest={hits={},firstHit=""},engineEventDispatched=false,protocol={sent={},received={},errors={message},timedOut=false,disconnected=false},changedNodes={},postUiTreeHash=beforeHash,postUiTree={},postUiTreeRef=treeRef,postUiTreeNodeCount=#before,stableState={outcome="business-error",stableFrames=0,reason=message,elapsedMs=0},animation={started=false,ended=false,durationMs=0,cleanupPassed=false},visualStateId=definition.visualStateId,identity={account="",userId=AppDef.LOCAL_TEST_UID or 0,roleId=AppDef.LOCAL_TEST_ROLE_ID or 0},resolution={width=1334,height=750,dpiScale=1},inputFingerprint=inputFingerprint or zero,automationPassed=false,engineInputReplayPassed=false,protocolSemanticPassed=false,runtimeTreePassed=(#before>0)}
end

local function dispatchPath(path, operation)
    local node=Collector.findTarget(path)
    if not node then return false,"active runtime target not found: "..path end
    local point=vectorCenter(node); local hits=Collector.hitTestTarget(node,point); local first=hits[1] or ""
    if not Collector.pathMatches(first,path) then return false,"first hit mismatch: "..first end
    return dispatchTouch(node,point,operation)
end

local cleanupPaths={
    "Panel/Bg/CloseBtnBg/CloseBtn",
    "dancichouka/dancichoukaUI/btn_Close",
    "shilianchouka/btn_Close",
    "shop_bg/shopBg/Popup/Btn_close",
    "MessageBoxUI/Popup/Btn_close",
    "MessageBoxUI/Btn_Confirm"
}

local function normalizeToDrawMain(host,complete,attempt)
    attempt=attempt or 1
    if attempt>60 then complete(false,"could not reach Draw main through engine input"); return end
    local singleBg=Collector.findTarget("dancichouka/dancichoukaUI/Bg")
    if singleBg then
        local singleClose=Collector.findTarget("dancichouka/dancichoukaUI/btn_Close")
        local closed=singleClose and dispatchPath("dancichouka/dancichoukaUI/btn_Close","close")
        performWithDelay(host,function() normalizeToDrawMain(host,complete,attempt+1) end,closed and 0.75 or 0.25); return
    end
    local tenBg=Collector.findTarget("shilianchouka/dancichoukaUI/bg")
    if tenBg then
        local tenClose=Collector.findTarget("shilianchouka/btn_Close")
        local closed=tenClose and dispatchPath("shilianchouka/btn_Close","close")
        performWithDelay(host,function() normalizeToDrawMain(host,complete,attempt+1) end,closed and 0.75 or 0.25); return
    end
    for _,path in ipairs(cleanupPaths) do
        if Collector.findTarget(path) then
            local ok=dispatchPath(path,"click")
            if ok then performWithDelay(host,function() normalizeToDrawMain(host,complete,attempt+1) end,0.2); return end
        end
    end
    if Collector.findTarget("shenjiangzhaomu/Popup1/Btn_Recruit_2") then complete(true,nil); return end
    if Collector.findTarget("Layer/Main_UI/ButtonGroup3/btn_zhaomu") then
        local ok=dispatchPath("Layer/Main_UI/ButtonGroup3/btn_zhaomu","open")
        if ok then performWithDelay(host,function() normalizeToDrawMain(host,complete,attempt+1) end,0.5); return end
    end
    performWithDelay(host,function() normalizeToDrawMain(host,complete,attempt+1) end,0.2)
end

function Replay:Attach(host)
    if Sha256.hex("abc") ~= "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" then
        self:writeError("SHA-256 runtime self-test failed")
        return false
    end
    if self.started or not AppDef.LOCAL_TEST or AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_MODULE~="Draw" then return false end
    self.started=true
    Collector.setValidationRoot(host)
    local ok,text=pcall(function() local f=assert(io.open(AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_SCENARIO,"rb")); local value=f:read("*a"); f:close(); return value end)
    if not ok then self:writeError(text); return false end
    local scenario=json.decode(text,1); local index=controlIndex(scenario); local output=assert(io.open(AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_OUTPUT,"w")); local sequence=0
    local byId={}; for _,item in ipairs(scenario.actions or {}) do byId[item.actionId]=item end
    local setupIds={
        ["DRAW-A18"]={"DRAW-A15"}, ["DRAW-A19"]={"DRAW-A15"}, ["DRAW-A20"]={"DRAW-A15"},
        ["DRAW-A21"]={"DRAW-A02"},
        ["DRAW-A22"]={"DRAW-A02","DRAW-A21"}, ["DRAW-A23"]={"DRAW-A02","DRAW-A21"}, ["DRAW-A24"]={"DRAW-A02","DRAW-A21"}, ["DRAW-A28"]={"DRAW-A02","DRAW-A21"},
        ["DRAW-A25"]={"DRAW-A03"}, ["DRAW-A26"]={"DRAW-A03","DRAW-A25"}, ["DRAW-A27"]={"DRAW-A03","DRAW-A25"}
    }
    local prepared={}
    local function prepareAction(definition,complete)
        if definition.actionId=="DRAW-A01" then
            local attempts=0
            local function waitInventory()
                attempts=attempts+1
                local ready=false
                if LRoleDataMgr and LRoleDataMgr.Equip then
                    local okBasic,basic=pcall(LRoleDataMgr.Equip.CountItemNumById,LRoleDataMgr.Equip,1000)
                    local okHigh,high=pcall(LRoleDataMgr.Equip.CountItemNumById,LRoleDataMgr.Equip,1001)
                    local okFriend,friend=pcall(LRoleDataMgr.Equip.CountItemNumById,LRoleDataMgr.Equip,1002)
                    ready=okBasic and okHigh and okFriend and basic>0 and high>0 and friend>0
                end
                if ready then
                    if Collector.findTarget("Panel/Bg/CloseBtnBg/CloseBtn") then
                        local closed=dispatchPath("Panel/Bg/CloseBtnBg/CloseBtn","close")
                        performWithDelay(host,waitInventory,closed and 0.5 or 0.25); return
                    end
                    if Collector.findTarget("Layer/Main_UI/ButtonGroup3/btn_zhaomu") then complete(true,nil); return end
                end
                if attempts>=60 then complete(false,"authoritative Draw inventory did not initialize"); return end
                performWithDelay(host,waitInventory,0.25)
            end
            waitInventory(); return
        end
        normalizeToDrawMain(host,function(okNormalize,errorNormalize)
            if not okNormalize then complete(false,errorNormalize); return end
            local ids=setupIds[definition.actionId] or {}; local setupIndex=0
            local function runSetup()
                setupIndex=setupIndex+1; local setupId=ids[setupIndex]
                if not setupId then complete(true,nil); return end
                local setup=byId[setupId]
                if not setup then complete(false,"missing setup action: "..setupId); return end
                local okSetup,errorSetup=dispatchPath(setup.action.cocosPath,setup.action.type)
                if not okSetup then complete(false,setupId..": "..tostring(errorSetup)); return end
                performWithDelay(host,runSetup,(setupId=="DRAW-A02" or setupId=="DRAW-A03") and 0.2 or 0.3)
            end
            runSetup()
        end)
    end
    local runNext
    local function writeAndContinue(record)
        output:write(json.encode(record),"\n"); output:flush(); performWithDelay(host,runNext,0.25)
    end
    runNext=function()
        sequence=sequence+1; local definition=scenario.actions[sequence]
        if not definition then output:close(); return end
        if not prepared[sequence] then
            prepareAction(definition,function(okPrepare,errorPrepare)
                if okPrepare then prepared[sequence]=true; sequence=sequence-1; performWithDelay(host,runNext,0.05); return end
                writeAndContinue(failureRecord(scenario,definition,sequence,"scenario precondition failed: "..tostring(errorPrepare),AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_FINGERPRINT))
            end)
            return
        end
        local started=nowMs(); trace(definition.actionId.." capture-before begin")
        local before=Collector.captureTree(index); local beforeHash=Collector.treeHash(before); trace(definition.actionId.." capture-before end")
        local okAction,state=pcall(function()
            local node=Collector.findTarget(definition.action.cocosPath)
            if not node then error("active runtime target not found: "..definition.action.cocosPath) end
            local point=vectorCenter(node); local rawHits=Collector.hitTestTarget(node,point); local first=rawHits[1] or ""; local targetPath=definition.action.cocosPath
            if not Collector.pathMatches(first,targetPath) then error("first hit mismatch: "..first) end
            local hits={}; for _,hit in ipairs(rawHits) do table.insert(hits,Collector.pathMatches(hit,targetPath) and definition.expectedHit or hit) end
            local packetStart=Collector.beginAction(); trace(definition.actionId.." dispatch begin"); local dispatched,dispatchError=dispatchTouch(node,point,definition.action.type); trace(definition.actionId.." dispatch end")
            if not dispatched then error(dispatchError) end
            return {before=before,beforeHash=beforeHash,point=point,hits=hits,targetPath=targetPath,packetStart=packetStart,previousHash="",stableFrames=0,animationStarted=false}
        end)
        if not okAction then writeAndContinue(failureRecord(scenario,definition,sequence,state,AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_FINGERPRINT,before,beforeHash)); return end
        local function pollStable()
            if state.previousHash=="" then trace(definition.actionId.." stable-poll begin") end
            local stabilityHash=Collector.stabilityHash(index)
            if state.previousHash~="" and state.previousHash~=stabilityHash then state.animationStarted=true end
            if state.previousHash==stabilityHash then state.stableFrames=state.stableFrames+1 else state.stableFrames=0 end
            state.previousHash=stabilityHash
            local packets=Collector.actionPackets(state.packetStart); local protocolPassed=protocolComplete(definition.expectedProtocols,packets)
            for _,packet in ipairs(packets) do if packet.length<0 or packet.rawPacketHash=="" then protocolPassed=false end end
            local elapsed=nowMs()-started; local timedOut=elapsed>=(definition.timeout or 10000)
            if state.stableFrames<3 or (not protocolPassed and not timedOut) then performWithDelay(host,pollStable,0.05); return end
            trace(definition.actionId.." capture-after begin"); local after=Collector.captureTree(index); local afterHash=Collector.treeHash(after); trace(definition.actionId.." capture-after end")
            local sent={}; local received={}
            for _,packet in ipairs(packets) do local copy={sequence=packet.sequence,command=packet.command,op=packet.op,decodedFields=packet.decodedFields,length=packet.length,rawPacketHash=packet.rawPacketHash,timestampUtc=packet.timestampUtc}; if packet.direction=="sent" then table.insert(sent,copy) else table.insert(received,copy) end end
            local treePassed=#state.before>0 and #after>0 and state.stableFrames>=3
            local cleanupPassed=definition.cleanup=="keep-draw-open" or definition.cleanup=="keep-preview-open"
            local passed=protocolPassed and treePassed and cleanupPassed and not timedOut
            local preTreeRef=storeTree(state.beforeHash,state.before); local postTreeRef=storeTree(afterHash,after)
            local record={schemaVersion=1,recordType="action",module=scenario.module,stateId=definition.expectedState,actionId=definition.actionId,controlId=definition.action.targetControlId,sequence=sequence,timestampUtc=os.date("!%Y-%m-%dT%H:%M:%SZ"),engine="cocos",operationType=definition.action.type,inputMode="engine-input-replay",inputCoordinates={x=state.point.x,y=750-state.point.y,coordinateSpace="1334x750-top-left"},preUiTreeHash=state.beforeHash,preUiTree={},preUiTreeRef=preTreeRef,preUiTreeNodeCount=#state.before,targetNodePath=state.targetPath,targetSemanticId=definition.expectedHit,hitTest={hits=state.hits,firstHit=state.hits[1] or ""},engineEventDispatched=true,protocol={sent=sent,received=received,errors=cleanupPassed and {} or {"scenario cleanup requires external snapshot restore/re-entry"},timedOut=timedOut or not protocolPassed,disconnected=false},changedNodes=changed(state.before,after),postUiTreeHash=afterHash,postUiTree={},postUiTreeRef=postTreeRef,postUiTreeNodeCount=#after,stableState={outcome=passed and "stable" or "timeout",stableFrames=state.stableFrames,reason=passed and "protocol complete and UI hash stable" or "protocol, stability, or cleanup contract incomplete",elapsedMs=elapsed},animation={started=state.animationStarted,ended=state.stableFrames>=3,durationMs=elapsed,cleanupPassed=cleanupPassed},visualStateId=definition.visualStateId,identity={account="",userId=AppDef.LOCAL_TEST_UID or 0,roleId=AppDef.LOCAL_TEST_ROLE_ID or 0},resolution={width=1334,height=750,dpiScale=1},inputFingerprint=AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_FINGERPRINT,automationPassed=passed,engineInputReplayPassed=true,protocolSemanticPassed=protocolPassed,runtimeTreePassed=treePassed}
            writeAndContinue(record)
        end
        performWithDelay(host,pollStable,0.05)
    end
    performWithDelay(host,runNext,1.0); return true
end

function Replay:writeError(message)
    local path=(AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_OUTPUT or "cocos-session.jsonl")..".error.json"; local file=io.open(path,"w")
    if file then file:write(json.encode({recordType="collector-error",engine="cocos",timestampUtc=os.date("!%Y-%m-%dT%H:%M:%SZ"),error=tostring(message)})); file:close() end
end

return Replay

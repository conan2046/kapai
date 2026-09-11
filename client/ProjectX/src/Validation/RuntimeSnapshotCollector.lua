local Sha256 = require("Validation.Sha256")
local Collector = { packets = {}, current = nil, packetSequence = 0 }
local encodedTrees = setmetatable({}, { __mode = "k" })

function Collector.note(message)
    local file=io.open((AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_OUTPUT or "cocos-session.jsonl")..".trace.log","a")
    if file then file:write(os.date("!%H:%M:%S")," ",tostring(message),"\n");file:close() end
end

function Collector.setValidationRoot(node)
    Collector.validationRoot = node
end

local function safe(object, method, default, ...)
    if not object or type(object[method]) ~= "function" then return default end
    local ok, value = pcall(object[method], object, ...)
    if ok then return value end
    return default
end

local function round(value)
    value = tonumber(value) or 0
    return math.floor(value * 1000 + 0.5) / 1000
end

local function pathOf(node)
    local names = {}
    local current = node
    while current do
        table.insert(names, 1, safe(current, "getName", ""))
        current = safe(current, "getParent", nil)
    end
    return table.concat(names, "/")
end

local function pathMatches(actual, expected)
    if type(actual)~="string" or type(expected)~="string" or expected=="" then return false end
    if actual==expected or string.sub(actual,-#expected)==expected then return true end
    local runtimeSuffix=expected:match("^[^/]+/(.+)$")
    return runtimeSuffix~=nil and (actual==runtimeSuffix or string.sub(actual,-#runtimeSuffix)==runtimeSuffix)
end

local function pointInRect(point, rect)
    return point.x >= rect.x and point.y >= rect.y and point.x <= rect.x + rect.width and point.y <= rect.y + rect.height
end

local function canonicalRect(node)
    local size = safe(node, "getContentSize", {width=0,height=0})
    local origin = safe(node, "convertToWorldSpace", {x=0,y=0}, cc.p(0,0))
    local scaleX = math.abs(safe(node, "getScaleX", 1)); local scaleY = math.abs(safe(node, "getScaleY", 1))
    return { x=round(origin.x), y=round(750-(origin.y+size.height*scaleY)), width=round(size.width*scaleX), height=round(size.height*scaleY) }
end

local function selfVisible(node)
    return safe(node, "isVisible", true) and safe(node, "getOpacity", 255) > 0
end

local function effectiveVisible(node, rect)
    local current = node
    while current do if not selfVisible(current) then return false end; current = safe(current, "getParent", nil) end
    if rect.x + rect.width <= 0 or rect.y + rect.height <= 0 or rect.x >= 1334 or rect.y >= 750 then return false end
    local parent = safe(node, "getParent", nil)
    while parent do
        if safe(parent, "isClippingEnabled", false) or safe(parent, "isClippingToBounds", false) then
            local clip = canonicalRect(parent)
            if rect.x + rect.width <= clip.x or rect.x >= clip.x + clip.width or rect.y + rect.height <= clip.y or rect.y >= clip.y + clip.height then return false end
        end
        parent = safe(parent, "getParent", nil)
    end
    return true
end

local function nodeType(node)
    local ok, value = pcall(tolua.type, node)
    return ok and value or "cc.Node"
end

local function captureNode(node, parentPath, sibling, rows, controlByPath, seen, parentVisible)
    if not node or seen[node] then return end
    seen[node] = true
    local name = safe(node, "getName", "")
    local path = parentPath and (parentPath .. "/" .. name) or name
    local visibleFromRoot = parentVisible and selfVisible(node)
    if not visibleFromRoot then return end
    local controlId = nil
    for suffix, id in pairs(controlByPath or {}) do if pathMatches(path,suffix) then controlId = id; break end end
    local kind = nodeType(node); local touchEnabled = safe(node,"isTouchEnabled",false)
    local visualNode = kind:find("Label") or kind:find("Text") or kind:find("Sprite") or kind:find("Image") or kind:find("Button") or kind:find("Widget") or kind:find("Scroll") or kind:find("List") or kind:find("Page") or kind:find("CheckBox") or kind:find("LoadingBar")
    if controlId or touchEnabled or visualNode then
        local rect = canonicalRect(node); local visibleOnScreen = effectiveVisible(node, rect)
        local anchor = safe(node, "getAnchorPoint", {x=0,y=0}); local pos = {x=safe(node,"getPositionX",0),y=safe(node,"getPositionY",0)}
        local world = safe(node, "convertToWorldSpace", {x=0,y=0}, cc.p(0,0)); local color = safe(node, "getColor", {r=255,g=255,b=255})
        local text = safe(node, "getString", nil); local texture = safe(node, "getTexture", nil)
        local row = {
            semanticId=path, controlId=controlId, nodePath=path, nodeType=kind, parentPath=parentPath,
            siblingIndex=sibling, localZOrder=safe(node,"getLocalZOrder",0), active=true, selfVisible=true,
            effectiveVisible=visibleOnScreen, enabled=safe(node,"isEnabled",true), interactable=safe(node,"isEnabled",true),
            raycast=safe(node,"isTouchEnabled",false), opacity=round(safe(node,"getOpacity",255)/255),
            color=string.format("#%02X%02X%02X%02X",color.r or 255,color.g or 255,color.b or 255,safe(node,"getOpacity",255)),
            anchor={x=round(anchor.x),y=round(anchor.y)}, pivot={x=round(anchor.x),y=round(anchor.y)},
            localPosition={x=round(pos.x),y=round(pos.y)}, worldPosition={x=round(world.x),y=round(750-world.y)},
            screenRect=rect, width=rect.width, height=rect.height, scale={x=round(safe(node,"getScaleX",1)),y=round(safe(node,"getScaleY",1))},
            rotation=round(safe(node,"getRotation",0)), clippingRect=nil, text=text, font=safe(node,"getFontName",nil),
            fontSize=safe(node,"getFontSize",nil), resource=texture and tostring(texture) or nil, source=safe(node,"getResourceName",nil),
            animationResource=safe(node,"getAnimation",nil) and kind or nil, animationAction=nil,
            scroll=nil, toggle=safe(node,"isSelected",nil), inputValue=kind:find("TextField") and text or nil,
            dataId=(parentPath and parentPath:find("List")) and name or nil,
            dataIndex=(parentPath and parentPath:find("List")) and sibling or nil
        }
        table.insert(rows,row)
    end
    local children = safe(node,"getChildren",{}) or {}
    for index, child in ipairs(children) do captureNode(child,path,index-1,rows,controlByPath,seen,visibleFromRoot) end
end

function Collector.captureTree(controlByPath)
    local scene = cc.Director:getInstance():getRunningScene(); local rows = {}; local roots = {}; local seen = {}
    local function capture(root)
        if not root or roots[root] then return end
        roots[root] = true
        captureNode(root,nil,0,rows,controlByPath,seen,true)
    end
    capture(scene)
    local current = Collector.validationRoot
    while current and current ~= scene do current = safe(current,"getParent",nil) end
    if current ~= scene then capture(Collector.validationRoot) end
    return rows
end

function Collector.treeJson(tree)
    local encoded = encodedTrees[tree]
    if not encoded then encoded = json.encode(tree); encodedTrees[tree] = encoded end
    return encoded
end

function Collector.treeHash(tree)
    local encoded = Collector.treeJson(tree)
    if type(projectx_validation_sha256) == "function" then return projectx_validation_sha256(encoded) end
    return Sha256.hex(encoded)
end

function Collector.stabilityHash(controlByPath)
    local scene = cc.Director:getInstance():getRunningScene(); local values = {}; local seen = {}
    local function visit(node, parentPath, parentVisible)
        if not node or seen[node] then return end
        seen[node] = true
        local name = safe(node,"getName",""); local path = parentPath and (parentPath.."/"..name) or name
        local visible = parentVisible and selfVisible(node)
        if not visible then return end
        local controlId = nil
        for suffix,id in pairs(controlByPath or {}) do if pathMatches(path,suffix) then controlId=id; break end end
        local touchEnabled = safe(node,"isTouchEnabled",false)
        if controlId or touchEnabled then
            local rect=canonicalRect(node)
            table.insert(values,table.concat({controlId or "",path,round(rect.x),round(rect.y),round(rect.width),round(rect.height),safe(node,"getString","") or "",safe(node,"getOpacity",255),safe(node,"isEnabled",true) and "1" or "0"},"|"))
        end
        for _,child in ipairs(safe(node,"getChildren",{}) or {}) do visit(child,path,visible) end
    end
    visit(scene,nil,true)
    if Collector.validationRoot and not seen[Collector.validationRoot] then visit(Collector.validationRoot,nil,true) end
    table.sort(values); local encoded=table.concat(values,"\n")
    if type(projectx_validation_sha256)=="function" then return projectx_validation_sha256(encoded) end
    return Sha256.hex(encoded)
end

function Collector.findTarget(path)
    local scene = cc.Director:getInstance():getRunningScene(); if not scene then return nil end
    local result = nil; local seen = {}
    local function visit(node)
        if result or not node or seen[node] then return end
        seen[node] = true
        if selfVisible(node) and effectiveVisible(node,canonicalRect(node)) and pathMatches(pathOf(node),path) then result=node; return end
        for _, child in ipairs(safe(node,"getChildren",{}) or {}) do visit(child) end
    end
    visit(Collector.validationRoot); visit(scene); return result
end

function Collector.hitTest(point)
    local scene = cc.Director:getInstance():getRunningScene(); local hits = {}; local seen = {}; local hitPaths = {}
    local function visit(node)
        if not node or seen[node] or not selfVisible(node) then return end
        seen[node] = true
        local children=safe(node,"getChildren",{}) or {}; for index=#children,1,-1 do visit(children[index]) end
        if safe(node,"isTouchEnabled",false) then
            local hit = false
            if type(node.hitTest)=="function" then local ok,value=pcall(node.hitTest,node,point,nil,nil); hit=ok and value or false end
            if not hit then hit=pointInRect({x=point.x,y=750-point.y},canonicalRect(node)) end
            local path=pathOf(node)
            if hit and not hitPaths[path] then hitPaths[path]=true; table.insert(hits,path) end
        end
    end
    visit(scene); visit(Collector.validationRoot)
    return hits
end

function Collector.hitTestTarget(node,point)
    if not node or not selfVisible(node) then return {} end
    local rect=canonicalRect(node)
    if not effectiveVisible(node,rect) or not safe(node,"isTouchEnabled",false) then return {} end
    local hit=false
    if type(node.hitTest)=="function" then local ok,value=pcall(node.hitTest,node,point,nil,nil); hit=ok and value or false end
    if not hit then hit=pointInRect({x=point.x,y=750-point.y},rect) end
    return hit and {pathOf(node)} or {}
end

function Collector.firstHit(point)
    local scene=cc.Director:getInstance():getRunningScene(); local seen={}; local result=nil
    local function visit(node,parentPath,parentVisible)
        if result or not node or seen[node] then return end
        seen[node]=true
        local name=safe(node,"getName",""); local path=parentPath and (parentPath.."/"..name) or name
        local visible=parentVisible and selfVisible(node)
        if not visible then return end
        local children=safe(node,"getChildren",{}) or {}; local ordered={}
        for index,child in ipairs(children) do table.insert(ordered,{node=child,z=safe(child,"getLocalZOrder",0),index=index}) end
        table.sort(ordered,function(left,right) if left.z==right.z then return left.index>right.index end return left.z>right.z end)
        for _,entry in ipairs(ordered) do visit(entry.node,path,visible); if result then return end end
        if not safe(node,"isTouchEnabled",false) then return end
        local rect=canonicalRect(node); if not effectiveVisible(node,rect) then return end
        local hit=false
        if type(node.hitTest)=="function" then local ok,value=pcall(node.hitTest,node,point,nil,nil);hit=ok and value or false end
        if not hit then hit=pointInRect({x=point.x,y=750-point.y},rect) end
        if hit then result=path end
    end
    visit(scene,nil,true)
    return result or ""
end

local function rawBytes(stream)
    if not stream then return nil end
    if type(projectx_validation_packet_bytes)=="function" then
        local nativeStream=stream.m_pNetMsg or stream
        local ok,value=pcall(projectx_validation_packet_bytes,nativeStream)
        if ok and type(value)=="string" and #value>0 then return value end
    end
    for _, method in ipairs({"GetBufferString","GetHexString","GetBuffer"}) do
        if type(stream[method])=="function" then local ok,value=pcall(stream[method],stream); if ok and type(value)=="string" then return value end end
    end
    if stream.m_pNetMsg then
        for _, method in ipairs({"GetBufferString","GetHexString","GetBuffer"}) do
            if type(stream.m_pNetMsg[method])=="function" then local ok,value=pcall(stream.m_pNetMsg[method],stream.m_pNetMsg); if ok and type(value)=="string" then return value end end
        end
    end
    return nil
end

function Collector.observe(direction,command,op,decoded,stream)
    local tracePath=(AppDef.LOCAL_TEST_RUNTIME_SNAPSHOT_OUTPUT or "cocos-session.jsonl")..".trace.log"
    local trace=io.open(tracePath,"a"); if trace then trace:write(os.date("!%H:%M:%S")," observe ",direction,"/",tostring(command),"/",tostring(op)," begin\n");trace:close() end
    Collector.packetSequence=Collector.packetSequence+1; local raw=rawBytes(stream); local rawHash=""
    if raw then
        if type(projectx_validation_sha256)=="function" then local ok,value=pcall(projectx_validation_sha256,raw); if ok then rawHash=value end
        else rawHash=Sha256.hex(raw) end
    end
    table.insert(Collector.packets,{sequence=Collector.packetSequence,direction=direction,command=command,op=op,decodedFields=decoded or {},length=raw and #raw or -1,rawPacketHash=rawHash,timestampUtc=os.date("!%Y-%m-%dT%H:%M:%SZ")})
    trace=io.open(tracePath,"a"); if trace then trace:write(os.date("!%H:%M:%S")," observe ",direction," end length=",tostring(raw and #raw or -1),"\n");trace:close() end
end

function Collector.beginAction() return #Collector.packets end
function Collector.actionPackets(index)
    local result={}; for i=index+1,#Collector.packets do table.insert(result,Collector.packets[i]) end; return result
end
function Collector.redact(value)
    if type(value)~="string" then return value end
    value=value:gsub("[Tt][Oo][Kk][Ee][Nn][^%s]*","[redacted]")
    value=value:gsub("[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][^%s]*","[redacted]")
    return value
end


Collector.pathMatches = pathMatches
return Collector

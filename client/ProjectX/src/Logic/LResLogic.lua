--[[
资源管理逻辑
]]

require "Frame.Manager.LAssetManager"
require "Frame.Base.LAssetBase"

--资源类
LResData = {}
LResData.__index = LResData
function LResData:New()
    local o = {}
    setmetatable(o,LResData) 
    
    o:Init()
    return o
end

function LResData:Init()
    self.tex = nil--资源类
    self.texFilePath = ""--资源名
    --self.resType = UI_TEX_TYPE_LOCAL
    self.lastUsedTime = 0--上次使用的时间
end

function LResData:Delete()
    self.tex = nil--资源类
    self.texFilePath = nil--资源名
    --self.resType = nil
    self.lastUsedTime = nil--上次使用的时间
end

LResLogic = LAssetBase:New()
LResLogic.__index = LResLogic

--local this = LTcpSocket
function LResLogic:New()
    --------print("LResLogic:New")
    local o = LAssetBase:New()
    setmetatable(o,LResLogic)
    o:Init()
    return o
end

function LResLogic:Init()
    --------print("LResLogic:Init")

    self.msgIds = 
    {
        LResEvent.Init,--初始化
        LResEvent.LoadCsb,
        LResEvent.UnusedCsb,
        LResEvent.LoadImg,
        LResEvent.LoadAni,
        LResEvent.LoadImgSync,
        LResEvent.UnLoadImgSync,
        LResEvent.DeleteUnUsedImg,
        LResEvent.DeleteImg,
        LResEvent.ChangeMap,
        LResEvent.ChangeMapSuccess,
    }
    self:RegistSelf(self,self.msgIds)
    self:InitData()
    --self:InitAudio()
end

--[[
初始化一下UI数据，比如UI的父节点之类
]]
function LResLogic:InitData()
    self._maxResNum = 10--最大保存的资源数量
    self._resArr = {}--资源数组
    self._maxCsbNum = 50--最大缓存的csb文件
    self._csbNodeArr = {}--csb节点缓存
    self._textureCache = AppDef.textureCache
    self._changingScene = false

    self._syncLoadBuff = {}
    self._loadImgBuff = {}
    self._loadImgSyncBuff = {}

    self._maxAniNum = 50--lua最大缓存动画数量
    self._aniUsedArr = {}
    self._aniFreeArr = {}
end

function LResLogic:ProcessEvent(msg)
    local msgId = msg:GetMsgId()
    if msgId == LResEvent.Init then
    elseif msgId == LResEvent.LoadCsb then
        self:LoadCsbFile(msg)
    elseif msgId == LResEvent.LoadAni then
        self:LoadAni(msg)
    elseif msgId == LResEvent.UnusedCsb then
        self:UnunseCsbNode(msg.value[1],msg.value[2])
    elseif msgId == LResEvent.LoadImg then
        if self._changingScene then
            return
        end
        self:LoadImg(msg)
    elseif msgId == LResEvent.LoadImgSync then
        if self._changingScene then
            return
        end
        self:LoadImgSync(msg)
    elseif msgId == LResEvent.UnLoadImgSync then
        if self._changingScene then
            return
        end
        self:UnbindImg(msg.filePath)
    elseif msgId == LResEvent.DeleteImg then
        self:DeleteImg(msg.filePath)
    elseif msgId == LResEvent.DeleteUnUsedImg then
        self:DeleteUnUsedImg()
    elseif msgId == LResEvent.ChangeMap then
        --切换地图后所有未使用的资源在C++那边清理了，所以这里只需清空数组就行
        self._changingScene = true
        self:DeleteAll()
    elseif msgId == LResEvent.ChangeMapSuccess then
        self:HandleChangeMapSuccess()
    end
end

function LResLogic:HandleChangeMapSuccess()
    self._changingScene = false
end

function LResLogic:DeleteAll()
    ------print("LResLogic:DeleteAll()")
    while #self._resArr > 0 do
        local resData = self._resArr[1]
        resData:Delete()
        table.remove(self._resArr, 1)
    end
    -- for i = #self._resArr, 1,-1 do
    --     local resData = self._resArr[i]
    --     resData:Delete()
    --     table.remove(self._resArr, i)
    -- end
    -- self._resArr = {}

    if self._syncLoadBuff then
        for k,v in pairs(self._syncLoadBuff) do 
            if v and v[2] then
                while #v[2] > 0 do
                    v[2][1]:release()
                    table.remove(v[2],1)
                end
            end
        end
    end  
    self._syncLoadBuff = {}
end

function LResLogic:DeleteImg(filePath)
    for i = #self._resArr, 1,-1 do
        local resData = self._resArr[i]
        if resData.texFilePath == filePath then
            local curRef = resData.tex:getReferenceCount()
            if curRef == 1 then
                ----print("DeleteImg removeTextureForKey",resData.texFilePath)
                self._textureCache:removeTextureForKey(resData.texFilePath) 
                resData:Delete()
                table.remove(self._resArr, i)
            end
            break
        end
    end
end

function LResLogic:DeleteUnUsedImg()
    for i = #self._resArr, 1,-1 do
        local resData = self._resArr[i]
        local curRef = resData.tex:getReferenceCount()
        if curRef == 1 then
            ----print("DeleteUnUsedImg removeTextureForKey",resData.texFilePath,i)
            self._textureCache:removeTextureForKey(resData.texFilePath) 
            resData:Delete()
            table.remove(self._resArr, i)
        end
    end
end

function LResLogic:UnbindImg(filePath)
    for i = 1, #self._resArr do
        if self._resArr[i].texFilePath == filePath then
            return 
        end
    end
    if self._syncLoadBuff[filePath] == nil or self._syncLoadBuff[filePath][1] == 1 then

        if self._syncLoadBuff[filePath] ~= nil and self._syncLoadBuff[filePath][1] == 1 and self._syncLoadBuff[filePath][2] then
            while #self._syncLoadBuff[filePath][2] > 0 do
                self._syncLoadBuff[filePath][2][1]:release()
                table.remove(self._syncLoadBuff[filePath][2],1)
            end
        end

        self._textureCache:unbindImageAsync(filePath)
        if self._syncLoadBuff[filePath] ~= nil then
            self._syncLoadBuff[filePath][1] = 0
        end
    end
end

function LResLogic:GetCsbNodeInBuffer(filePath)
    for i = 1, #self._csbNodeArr do
        if self._csbNodeArr[i].texFilePath == filePath then
            return i
        end
    end
    return 0
end

--[[
csb不使用了，放到缓存里面去
]]
function LResLogic:UnunseCsbNode(csbFile, node)
    local curCnt = #self._csbNodeArr
    if curCnt >= self._maxCsbNum then
        self:DeleteOneUsedNode()
    end
    local data = LResData:New()
    node:retain()
    node:removeFromParent()
    data.tex = node
    data.lastUsedTime = os.time()
    data.texFilePath = csbFile
    table.insert(self._csbNodeArr, data)
end


function LResLogic:DeleteOneUsedNode()
    local cnt = #self._csbNodeArr
    local time = self._csbNodeArr[1].lastUsedTime
    local ind = 1
    local refCnt = self._csbNodeArr[1].tex:getReferenceCount()
    for i = 2, cnt do
        local resData = self._resArr[i]
        if time > resData.lastUsedTime then
            ind = i
            time = resData.lastUsedTime
            refCnt = curRef
        end
    end

    if refCnt == 1 then
        local data = self._csbNodeArr[ind]
        data.tex:release()
        data:Delete()
        table.remove(self._csbNodeArr, ind)
        --return data
    end
end

function LResLogic:LoadCsbFile(msg)
    local filePath = msg.filePath
    local callback = msg.callback
    local ind = self:GetCsbNodeInBuffer(filePath)

    if ind == 0 then
        local layer = cc.CSLoader:createNode(filePath)
        layer:setContentSize(AppDef.frameSize)
        ccui.Helper:doLayout(layer)
        if callback then
            layer:retain()
            callback(layer)
        end
    else
        local csbData = self._csbNodeArr[ind]
        table.remove(self._csbNodeArr,ind)
        local csbNode = csbData.tex
        csbData:Delete()
        if callback then
            callback(csbNode)
        end
        --csbNode:release()
    end
end

function LResLogic:LoadImg(msg)
    local filePath = msg.filePath
    local callback = msg.callback
    ----print("LoadImg",filePath)
    local resData = self:GetResDataInBuffer(filePath)
    if resData then
        resData.lastUsedTime = os.time()

        local function CheckTex()
            resData.tex:getReferenceCount()
        end
        local isError = false
        local function TexErr()
            isError = true
            --resData.tex:getReferenceCount()
        end
        xpcall(CheckTex,TexErr)

        if isError then
            self:DeleteResDataByFilePath(filePath)
        else
            if callback then
                callback(resData.tex)
            end
            return
        end
    end
    
    local tex = self._textureCache:addImage(filePath)
    if tex then
        self:AddResData(filePath, tex)
        if callback then
            callback(tex)
        end
    end
end

function LResLogic:LoadAni(msg)
    local filePath = msg.filePath
    local callback = msg.callback
    local ani = self:GetFreedAni(filePath)
    if ani == nil then
        
        local data = LResData:New()
        local imod = ImodAnim:createWithFileSync(filePath)
        imod:retain()
        data.tex = imod
        data.lastUsedTime = os.time()
        data.texFilePath = filePath
        table.insert(self._aniUsedArr, data)
    end
    if callback then
        callback(ani.tex)
    end
    
    self._maxAniNum = 50--lua最大缓存动画数量
    self._aniUsedArr = {}
    self._aniFreeArr = {}
end

function LResLogic:GetFreedAni(filePath)
    for i = 1, #self._aniFreeArr do
        if self._aniFreeArr[i].texFilePath == filePath then
            local aniData = self._aniFreeArr[i]
            table.remove(self._aniFreeArr, i)
            table.insert(self._aniUsedArr, aniData)
            aniData.lastUsedTime = os.time()
            return aniData
        end
    end
end

--[[
csb不使用了，放到缓存里面去
]]
function LResLogic:UnunseAni(csbFile, aniNode)
    -- local curCnt = #self._csbNodeArr
    -- if curCnt >= self._maxAniNum then
    --     self:DeleteOneUsedNode()
    -- end
    -- local data = LResData:New()
    -- node:retain()
    -- node:removeFromParent()
    -- data.tex = node
    -- data.lastUsedTime = os.time()
    -- data.texFilePath = csbFile
    -- table.insert(self._csbNodeArr, data)
end

function LResLogic:LoadImgSync(msg)
    local filePath = msg.filePath
    local callback = msg.callback
    local node = msg.node
    local resData = self:GetResDataInBuffer(filePath)
    if resData then
        ----print("GetImgInBuffer")
        resData.lastUsedTime = os.time()
        local function CheckTex()
            resData.tex:getReferenceCount()
        end
        local isError = false
        local function TexErr()
            isError = true
            --resData.tex:getReferenceCount()
        end
        xpcall(CheckTex,TexErr)

        if isError then
            self:DeleteResDataByFilePath(filePath)
        else
            if callback then
                callback(resData.tex)
            end
            return
        end
    end
    local function LoadImgSuccess(texture)
        ----print("LoadImgSuccess",filePath)
        if texture == nil then
            return
        end
        
        ----print("RefCnt1",texture:getReferenceCount())
        self:AddResData(filePath, texture)
        if callback then
            callback(texture)
        end
        if self._syncLoadBuff[filePath] ~= nil then
            if self._syncLoadBuff[filePath][2] then
                while #self._syncLoadBuff[filePath][2] > 0 do
                    self._syncLoadBuff[filePath][2][1]:release()
                    table.remove(self._syncLoadBuff[filePath][2],1)
                end
            end
            self._syncLoadBuff[filePath][1] = 0
        end
        ----print("RefCnt2",texture:getReferenceCount())
    end

    if self._syncLoadBuff[filePath] == nil then
        self._syncLoadBuff[filePath] = {}
        self._syncLoadBuff[filePath][2] = {}
        self._syncLoadBuff[filePath][1] = 0
    end
    self._syncLoadBuff[filePath][1] = 1
    if node then
        node:retain()
        local isExit = false
        for i = 1, #self._syncLoadBuff[filePath][2] do
            if self._syncLoadBuff[filePath][2][i] == node then
                isExit = true
                break
            end
        end
        if isExit == false then
            table.insert(self._syncLoadBuff[filePath][2], node)
        end
    end
    self._textureCache:addImageAsync(filePath, LoadImgSuccess)

end

function LResLogic:AddResData(filePath, texture)
    for i = 1, #self._resArr do
        if self._resArr[i].texFilePath == filePath then
            return
        end
    end
    local data = self:GetEmptyResData()
    data.lastUsedTime = os.time()
    data.tex = texture
    data.texFilePath = filePath
end

function LResLogic:DeleteResByInd(ind)
    --print("DeleteResByInd",ind,"AllNum",#self._resArr)
    if ind == nil or ind == 0 then
        return
    end
    if ind > #self._resArr then
        return
    end
    ----print("deleteFile=",self._resArr[ind].texFilePath)
    self._resArr[ind]:Delete()
    table.remove(self._resArr,ind)
end


--[[
删除最久未使用的一个数据并返回
]]
function LResLogic:GetEmptyResData()
    local cnt = #self._resArr
    --print("GetEmptyResData",cnt)
    if cnt >= self._maxResNum then
        
        local time = self._resArr[1].lastUsedTime
        local ind = 1
        local tmpInd = ind
        local refCnt = 0
        local curRef = 0
        local isError = false
        local function GetRefCnt()
            refCnt = self._resArr[tmpInd].tex:getReferenceCount()
            --print("refCnt=",refCnt,"FilePath=",self._resArr[tmpInd].texFilePath,"ind=",tmpInd)
        end
        
        local function GetRefCntError()
            --print("GetRefCntError",tmpInd,self._resArr[tmpInd].texFilePath)
            isError = true
        end

        local function GetCurRefCnt()
            ----print("GetCurRefCnt",tmpInd)
            curRef = self._resArr[tmpInd].tex:getReferenceCount()
            --print("curRef=",curRef,"FilePath=",self._resArr[tmpInd].texFilePath,"ind=",tmpInd)
        end
    
        xpcall(GetRefCnt,GetRefCntError)
        if isError then
            self:DeleteResByInd(tmpInd)
            return self:GetEmptyResData()
        end
        isError = false
        for i = 2, cnt do
            tmpInd = i
            local resData = self._resArr[i]
            curRef = 0
            xpcall(GetCurRefCnt,GetRefCntError)
            if isError then
                self:DeleteResByInd(tmpInd)
                return self:GetEmptyResData()
            end
            --curRef = resData.tex:getReferenceCount()
            --print("curRef=",curRef)
            if (curRef == 1 and time > resData.lastUsedTime)
                or (curRef == 1 and refCnt > 1) then
                ind = i
                time = resData.lastUsedTime
                refCnt = curRef
            end
        end
        --print("End",refCnt,ind,self._resArr[ind].texFilePath)
        if refCnt == 1 then
            local data = self._resArr[ind]
            --print("22removeTextureForKey",data.texFilePath,ind)
            self._textureCache:removeTextureForKey(data.texFilePath) 
            data:Delete()
            -- table.remove(self._resArr, ind)
            -- table.insert(self._resArr, data)
            return data
        end
    end
    local data = LResData:New()
    table.insert(self._resArr, data)
    return data
end

function LResLogic:DeleteResDataByFilePath(filePath)
    for i = 1, #self._resArr do
        if self._resArr[i].texFilePath == filePath then
            self._resArr[i]:Delete()
            table.remove(self._resArr,i)
            break
        end
    end
end

function LResLogic:GetResDataInBuffer(filePath)
    for i = 1, #self._resArr do
        if self._resArr[i].texFilePath == filePath then
            return self._resArr[i]
        end
    end
    return nil
end 


LResLogic:Init()
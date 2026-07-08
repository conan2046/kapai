--[[
lua里面的UI逻辑控制
]]

LSoundLogic = LAudioBase:New()
LSoundLogic.__index = LSoundLogic
LSoundLogic.SoundPath = "res2/Sound/"

--local this = LTcpSocket
function LSoundLogic:New()
	--print("LSoundLogic:New")
	local o = LAudioBase:New()
	setmetatable(o,LSoundLogic)
	o:Init()
	return o
end

function LSoundLogic:Init()
	--print("LSoundLogic:Init")
	self.msgIds = 
	{
		LAudioEvent.Init,--初始化
		LAudioEvent.ChangeMap,
	    LAudioEvent.PlayMapMusic,
	    LAudioEvent.PlayBgMusic,
	    LAudioEvent.StopBgMusic,
	    LAudioEvent.PauseBgMusic,
    	LAudioEvent.ResumeBgMusic,
	    LAudioEvent.SetMusicVolume,
	    LAudioEvent.PlayEffect,
	    LAudioEvent.PlayShortEffect,
	    LAudioEvent.PlayNPCEffect,
	    LAudioEvent.CPlayNPCEffect,
	    LAudioEvent.PlayBTEffect,
	    LAudioEvent.SetEffectVolume,
	    LAudioEvent.EnableEffects,
	    LAudioEvent.DisableEffects,
	    LAudioEvent.EnableBgMusic,
	    LAudioEvent.DisableBgMusic,
	    LAudioEvent.StopEffect,
	    LAudioEvent.StartSpeakVoice,
    	LAudioEvent.StopSpeakVoice,
    	LAudioEvent.PlayShortEffect2,
		LAudioEvent.ExitBattle,
	}
	self:RegistSelf(self,self.msgIds)
	self:InitData()
	--self:InitAudio()
end

--[[
初始化一下UI数据，比如UI的父节点之类
]]
function LSoundLogic:InitData()
	self._MapEffect = {}
	self._IsAllowPlayEffect = not LUserConfigMgr:GetIsEffectClosed()
	self._bgAudioId = -1--当前播放的背景音乐id，循环播放
	self._effAudioId = -1--长音效id，不循播放
	self._shortEffAudioId = -1--短音效id，不循播放
	self._npcEffAudioId = -1--NPC音效id，不循播放
	self._bgFilePath = nil
	self._bgVolume = 1.0--背景音量大小
	self._effVolume = 1.0--音效音量大小
	self.m_isPlayNPCBGM = false
	self.m_isSpeakVoice = false
	self._bgPlayingFilePath = nil
	self._isPlayStageBGM = false--是否正在播放章节的背景音乐
	self._stageId = 0;
end

function LSoundLogic:ProcessEvent(msg)
	local msgId = msg:GetMsgId()
	if msgId == LAudioEvent.Init then
		self:InitAudio()
	elseif msgId == LAudioEvent.ChangeMap then
		self:ChangeMap()
	elseif msgId == LAudioEvent.ExitBattle then
		self:ExitBattle()
	elseif msgId == LAudioEvent.PlayMapMusic then
		self:PlayBGMusicByMapId(msg.value)
	elseif msgId == LAudioEvent.PlayBgMusic then
		self._isPlayStageBGM = false;
		self:PlayBGMusic(msg.value)
	elseif msgId == LAudioEvent.StopBgMusic then
		self:StopBGMusic()
	elseif msgId == LAudioEvent.PauseBgMusic then
		self:PauseBgMusic()
    elseif msgId == LAudioEvent.ResumeBgMusic then
    	self:ResumeBgMusic()
	elseif msgId == LAudioEvent.SetMusicVolume then
		self:SetMusicVolume()
	elseif msgId == LAudioEvent.PlayEffect then
		if self.m_isSpeakVoice then
			return
		end
		-- dump({self._npcEffAudioId, msg.value})
		if self._npcEffAudioId > 0 then
			ccexp.AudioEngine:stop(self._npcEffAudioId)
			self._npcEffAudioId = 0
		end
		self._effAudioId = self:PlayEffect(msg.value, true)
	elseif msgId == LAudioEvent.PlayShortEffect then
		self._shortEffAudioId = self:PlayEffect(msg.value, true)
	elseif msgId == LAudioEvent.PlayShortEffect2 then
		self:PlayEffect(msg.value)
	elseif msgId == LAudioEvent.PlayNPCEffect then
		if self.m_isSpeakVoice then
			return
		end
		local npcId = msg.value
		self:PlayNPCEffect(npcId)

	elseif msgId == LAudioEvent.CPlayNPCEffect then
		local npcId = msg:GetOp()
		self:PlayNPCEffect(npcId)
	elseif msgId == LAudioEvent.PlayBTEffect then
		if self.m_isSpeakVoice then
			return
		end
		self._shortEffAudioId = self:PlayEffect(msg.value, false)

	elseif msgId == LAudioEvent.DisableEffects then
		self:DisableEffect()
	elseif msgId == LAudioEvent.SetEffectVolume then
		self:SetEffectVolume()
	elseif msgId == LAudioEvent.EnableEffects then
		self:EnableEffect()
	elseif msgId == LAudioEvent.EnableBgMusic then
		self:EnableBgMusic()
	elseif msgId == LAudioEvent.DisableBgMusic then
		self:DisableBgMusic()
	elseif msgId == LAudioEvent.StopEffect then
		self:StopEffectAudio()
		if self._npcEffAudioId > 0 then
			ccexp.AudioEngine:stop(self._npcEffAudioId)
			self._npcEffAudioId = 0
		end
	elseif msgId == LAudioEvent.StartSpeakVoice then
		self:StartVoice()
	elseif msgId == LAudioEvent.StopSpeakVoice then
		self:StopVioce()
	end
end

function LSoundLogic:StartVoice()
	self.m_isSpeakVoice = true
	self:PauseBgMusic()
end

function LSoundLogic:StopVioce()
	self.m_isSpeakVoice = false
	self:ResumeBgMusic()
end

function LSoundLogic:ChangeMap()
	ccexp.AudioEngine:uncacheAll()
end

function LSoundLogic:EnableBgMusic()
	LUserConfigMgr:SetIsMusicClosed(false)

	if self._bgAudioId > 0 then
		self:ResumeBGMusic()
	elseif self._bgFilePath ~= nil then
		self._bgAudioId = ccexp.AudioEngine:play2d(self._bgFilePath, true, self._bgVolume)
		self._bgFilePath = nil
	end
end

function LSoundLogic:DisableBgMusic()
	self:PauseBGMusic()
	LUserConfigMgr:SetIsMusicClosed(true)

end

--[[
停止播放音效
]]
function LSoundLogic:StopEffectAudio()
	if self._effAudioId > 0 then
		ccexp.AudioEngine:stop(self._effAudioId)
		self._effAudioId = 0
	end
	if self._shortEffAudioId > 0 then
		ccexp.AudioEngine:stop(self._shortEffAudioId)
		self._shortEffAudioId = 0
	end
end

function LSoundLogic:PlayNPCEffect(npcid)
	for i = 1,#AppDef.NPCBGM do
		if AppDef.NPCBGM[i].npcId == npcid then
			local soundStr = AppDef.NPCBGM[i].bgm
			local arr = string.split(soundStr,"|")
			
			local num = #arr
			local curInd = math.random(1,num)
			local playFile = arr[curInd]
			-- self.m_isPlayNPCBGM = true
			if self._npcEffAudioId > 0 then
				ccexp.AudioEngine:stop(self._npcEffAudioId)
			end
			self._npcEffAudioId = self:PlayEffect(playFile, true)
			if self._npcEffAudioId > 0 then
				local function AudioPlayEnd()
					-- self.m_isPlayNPCBGM = false
					self._npcEffAudioId = -1
				end
				ccexp.AudioEngine:setFinishCallback(self._npcEffAudioId, AudioPlayEnd)
			end
			return
		end
	end
end

--[[
开始播放音效，音效不循环播放
@param1:key
]]
function LSoundLogic:PlayEffect(key, stopLast)
	if self._IsAllowPlayEffect == false then
		return 0
	end
	if stopLast then
		self:StopEffectAudio()
	end
	local filePath = LSoundLogic.SoundPath .. key .. ".mp3"
	-- dump({self._IsAllowPlayEffect, filePath}, "filePath======================>")
	return ccexp.AudioEngine:play2d(filePath, false, self._effVolume*0.7)
end

function LSoundLogic:PlayBGMusicByMapId(sId)
	for i = 1,#AppDef.MapBGM do
		if AppDef.MapBGM[i].mapPicId == sId then
			local soundStr = AppDef.MapBGM[i].bgm
			local arr = string.split(soundStr,"|")
			
			local num = #arr
			local curInd = math.random(1,num)
			local playFile = arr[curInd]
			self._isPlayStageBGM = true;
			self._stageId = sId;
			self:PlayBGMusic(playFile)
			return
		end
	end

	--该地图没有音乐就停止不放背景音乐
	self:StopBGMusic()
	self._bgAudioId = 0
end

function LSoundLogic:ExitBattle()
	if self._isPlayStageBGM == true then
		self:PlayBGMusicByMapId(self._stageId)
	else
		self:PlayBGMusic(AppDef.MainBGM)
	end
end

function LSoundLogic:PauseBgMusic()
	if self._bgAudioId >= 0 then
		ccexp.AudioEngine:pause(self._bgAudioId)
	end
end

function LSoundLogic:ResumeBgMusic()
	if self._bgAudioId >= 0 then
		ccexp.AudioEngine:resume(self._bgAudioId)
	end
end

function LSoundLogic:StopBGMusic()
	if self._bgAudioId >= 0 then
		ccexp.AudioEngine:stop(self._bgAudioId)
	end
end

function LSoundLogic:PlayBGMusic(key)
	self:StopBGMusic()
	local filePath = LSoundLogic.SoundPath .. key .. ".mp3"
	self._bgPlayingFilePath = filePath
	
	if LUserConfigMgr:GetIsMusicClosed() == true then
		self._bgFilePath = filePath
		self._bgAudioId = 0
	else
		self._bgAudioId = ccexp.AudioEngine:play2d(filePath, true, self._bgVolume * 0.8)
	end
end

function LSoundLogic:PauseAllEffects()
	--cc.SimpleAudioEngine:getInstance():stopAllEffects()
	self._IsAllowPlayEffect = false
end

function LSoundLogic:StopAllEffects()
	--cc.SimpleAudioEngine:getInstance():stopAllEffects()
end

function LSoundLogic:StopAllVoices()
	self:StopBGMusic()
	self:StopEffect()
end


function LSoundLogic:PauseBGMusic()
	if self._bgAudioId >= 0 then
		ccexp.AudioEngine:pause(self._bgAudioId)
	end
end

function LSoundLogic:ResumeBGMusic()
	if LUserConfigMgr:GetIsMusicClosed() == true then
		return
	end
	if self._bgAudioId >= 0 then
		ccexp.AudioEngine:resume(self._bgAudioId)
		ccexp.AudioEngine:setVolume(self._bgAudioId, self._bgVolume)
	end
end

function LSoundLogic:SetMusicVolume()
	self._bgVolume = LUserConfigMgr:GetMusicVolume()

	if LUserConfigMgr:GetIsMusicClosed() == true then
		return
	end

	if self._bgAudioId >= 0 then
		ccexp.AudioEngine:setVolume(self._bgAudioId, self._bgVolume)
	end
end

function LSoundLogic:SetEffectVolume()
    self._effVolume = LUserConfigMgr:GetEffectVolume()
end

function LSoundLogic:EnableEffect()
	self._IsAllowPlayEffect = true
	LUserConfigMgr:SetIsEffectClosed(false)
end

function LSoundLogic:DisableEffect()
	self._IsAllowPlayEffect = false
	LUserConfigMgr:SetIsEffectClosed(true)
end

function LSoundLogic:InitAudio()
	self._bgVolume = LUserConfigMgr:GetMusicVolume()
	self._effVolume = LUserConfigMgr:GetEffectVolume()
	self:PreloadMusic()
end

--[[
预加载音乐
]]
function LSoundLogic:PreloadMusic()

end

LSoundLogic:Init()
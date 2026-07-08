local lAudioMsg = LManagerID.LAudioManager
local function MsgIdAdd()
    lAudioMsg = lAudioMsg + 1
    return lAudioMsg
end

LAudioEvent = 
{
    Init = MsgIdAdd(),--初始化
    ChangeMap = MsgIdAdd(),
    PlayMapMusic = MsgIdAdd(),
    PlayBgMusic = MsgIdAdd(),
    ExitBattle = MsgIdAdd(),
    EnableBgMusic = MsgIdAdd(),
    DisableBgMusic = MsgIdAdd(),
    StopBgMusic = MsgIdAdd(),
    PauseBgMusic = MsgIdAdd(),
    ResumeBgMusic = MsgIdAdd(),
    SetMusicVolume = MsgIdAdd(),
    PlayEffect = MsgIdAdd(),
    PlayShortEffect = MsgIdAdd(),
    PlayShortEffect2 = MsgIdAdd(),
    CPlayNPCEffect = MsgIdAdd(),--C#调用
    PlayNPCEffect = MsgIdAdd(),
    PlayBTEffect = MsgIdAdd(),--这个和上一个有区别，这个播放的时候不停止上一个音效的播放
    --NewPlayEffect = MsgIdAdd(),
    --NewPlayEffectByFile = MsgIdAdd(),
    StopEffect = MsgIdAdd(),
    SetEffectVolume = MsgIdAdd(),
    EnableEffects = MsgIdAdd(),
    DisableEffects = MsgIdAdd(),
    StartSpeakVoice = MsgIdAdd(),
    StopSpeakVoice = MsgIdAdd(),
}
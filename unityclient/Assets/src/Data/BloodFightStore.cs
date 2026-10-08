using System;

namespace ProjectX.Data
{
    public sealed class BloodFightStore
    {
        public event Action Changed;
        public byte Remaining { get; private set; }
        public byte Revives { get; private set; }
        public byte State { get; private set; }
        public byte RewardState { get; private set; }
        public byte Chapter { get; private set; }
        public ushort Level { get; private set; }
        public ushort TodayMaxLevel { get; private set; }
        public ushort HistoricalMaxStar { get; private set; }
        public ushort TotalStar { get; private set; }
        public ushort TodayMaxStar { get; private set; }
        public ushort CurrentStar { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }

        public void Replace(byte remaining, byte revives, byte state, byte rewardState, byte chapter,
            ushort level, ushort todayMaxLevel, ushort historicalMaxStar, ushort totalStar,
            ushort todayMaxStar, ushort currentStar)
        {
            Remaining=remaining; Revives=revives; State=state; RewardState=rewardState; Chapter=chapter;
            Level=level; TodayMaxLevel=todayMaxLevel; HistoricalMaxStar=historicalMaxStar;
            TotalStar=totalStar; TodayMaxStar=todayMaxStar; CurrentStar=currentStar;
            HasAuthoritativeResponse=true; Changed?.Invoke();
        }

        public void Clear()
        {
            Remaining=Revives=State=RewardState=Chapter=0;
            Level=TodayMaxLevel=HistoricalMaxStar=TotalStar=TodayMaxStar=CurrentStar=0;
            HasAuthoritativeResponse=false; Changed?.Invoke();
        }
    }
}

using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public enum FundKind : byte { Growth = 83, Active = 94 }

    public sealed class FundReward
    {
        public FundReward(ushort itemId, uint amount) { ItemId = itemId; Amount = amount; }
        public ushort ItemId { get; }
        public uint Amount { get; }
    }

    public sealed class FundTier
    {
        public FundTier(byte condition, byte state, IReadOnlyList<FundReward> rewards)
        { Condition = condition; State = state; Rewards = rewards ?? Array.Empty<FundReward>(); }
        public byte Condition { get; }
        public byte State { get; }
        public IReadOnlyList<FundReward> Rewards { get; }
    }

    public sealed class FundPlan
    {
        public FundPlan(byte id, byte bought, uint buyTime, byte progress, uint rate, uint price,
            uint total, IReadOnlyList<FundTier> tiers)
        { Id=id; Bought=bought; BuyTime=buyTime; Progress=progress; Rate=rate; Price=price; Total=total; Tiers=tiers??Array.Empty<FundTier>(); }
        public byte Id { get; }
        public byte Bought { get; }
        public uint BuyTime { get; }
        public byte Progress { get; }
        public uint Rate { get; }
        public uint Price { get; }
        public uint Total { get; }
        public IReadOnlyList<FundTier> Tiers { get; }
    }

    public sealed class FundPage
    {
        public FundPage(FundKind kind, uint endTime, byte boughtPlanId, IReadOnlyList<FundPlan> plans, bool authoritative)
        { Kind=kind; EndTime=endTime; BoughtPlanId=boughtPlanId; Plans=plans??Array.Empty<FundPlan>(); HasAuthoritativeResponse=authoritative; }
        public FundKind Kind { get; }
        public uint EndTime { get; }
        public byte BoughtPlanId { get; }
        public IReadOnlyList<FundPlan> Plans { get; }
        public bool HasAuthoritativeResponse { get; }
    }

    public sealed class FundsStore
    {
        private readonly Dictionary<FundKind, FundPage> pages = new Dictionary<FundKind, FundPage>();
        public event Action Changed;
        public FundPage Get(FundKind kind) => pages.TryGetValue(kind, out FundPage page) ? page : new FundPage(kind,0,0,null,false);
        public bool HasAllAuthoritativeResponses => Get(FundKind.Growth).HasAuthoritativeResponse && Get(FundKind.Active).HasAuthoritativeResponse;
        public void Replace(FundPage page) { pages[page.Kind]=page; Changed?.Invoke(); }
        public void Reset() { pages.Clear(); Changed?.Invoke(); }
    }
}

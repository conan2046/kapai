namespace ProjectX.Data
{
    public sealed class FundsCatalog
    {
        public string PageName(FundKind kind) => kind == FundKind.Growth ? "成长基金" : "活跃基金";
        public string Condition(FundKind kind, byte value) => kind == FundKind.Growth ? $"达到 {value} 级" : $"累计登录 {value} 天";
        public string State(byte state) => state == 3 ? "已领取" : state == 2 ? "可领取" : "未达成";
    }
}

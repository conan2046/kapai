using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class ResourceRecoveryCatalog
    {
        private readonly Dictionary<int, string> names = new Dictionary<int, string>
        {
            { 3, "封神列传" }, { 6, "竞技场" }, { 7, "决战昆仑" }, { 8, "血战到底" },
            { 9, "法宝搜索" }, { 18, "体力领取" }, { 1022, "封神试炼-金币" },
            { 1023, "封神试炼-突破" }, { 1024, "封神试炼-经验" }, { 1025, "封神试炼-法宝" }
        };

        public string GetName(int id) => names.TryGetValue(id, out string name) ? name : $"玩法 {id}";
    }
}

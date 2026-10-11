namespace ProjectX.Data
{
    public static class CultivationDisplay
    {
        private static JingJieConfigData config;
        public static string Name(int stage)
        {
            if (stage <= 0) return "未修炼";
            config = config ?? new JingJieConfigData();
            return config.TryGet(stage, out JingJieDefinition definition) ? definition.Name : $"第{stage}阶";
        }
    }
}

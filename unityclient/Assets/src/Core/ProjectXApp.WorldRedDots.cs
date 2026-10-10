using System.Linq;
using ProjectX.Data;
using ProjectX.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private bool worldRedDotsSubscribed;
        private void InitializeWorldRedDots()
        {
            redDots.Define("dungeon");
            redDots.Define("dungeon.achievement", "dungeon");
            redDots.Define("dungeon.boxes", "dungeon");
            redDots.Define("dungeon.boxes.normal", "dungeon.boxes");
            redDots.Define("dungeon.boxes.star", "dungeon.boxes");
            services.World.Changed += RefreshWorldRedDots;
            services.Player.Changed += RefreshWorldRedDots;
            worldRedDotsSubscribed = true;
        }
        private void RefreshWorldRedDots()
        {
            if (!worldRedDotsSubscribed) return;
            redDots.SetEnabled("dungeon", services.Player.Level > 0);
            redDots.Set("dungeon.achievement", !worldChainMode && Enumerable.Range(1, 6).Any(services.World.CanClaimAchievement));
            redDots.Set("dungeon.boxes", !worldChainMode && services.World.HasReadyBoxes(services.Player.Level));
            redDots.Set("dungeon.boxes.normal", !worldChainMode && services.World.HasReadyBoxKind(false, services.Player.Level));
            redDots.Set("dungeon.boxes.star", !worldChainMode && services.World.HasReadyBoxKind(true, services.Player.Level));
            RedDotVisual.Set(mainView?.FindNode(WorldPath)?.transform, redDots.IsVisible("dungeon"), RedDotTemplate);
            RedDotVisual.Set(worldMapView?.FindNode("Layer/Panel_youxia/Button_zhuxianchengjiu")?.transform,
                redDots.IsVisible("dungeon.achievement"), RedDotTemplate);
            RenderWorldAchievement();
        }
        public void SetWorldAchievementPending(int index) => services.World.SetAchievementPending(index);
        public void SetWorldBoxPending(double chapterId, double boxId) => services.World.SetBoxPending(checked((uint)chapterId), checked((uint)boxId));
        public uint[] GetWorldBoxSnapshotChapterIds() => services.World.Chapters.Where(c => c.ClaimedBoxes > 0
            && c.Id <= services.World.CurrentChapterId && services.Player.Level >= c.OpenLevel).Select(c => c.Id).ToArray();
        private void DisposeWorldRedDots()
        {
            if (!worldRedDotsSubscribed) return;
            if (services != null)
            {
                services.World.Changed -= RefreshWorldRedDots;
                services.Player.Changed -= RefreshWorldRedDots;
            }
            worldRedDotsSubscribed = false;
        }
    }
}

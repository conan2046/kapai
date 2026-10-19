using System.Collections;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private LuaFunction onHeroBuildQuery, onHeroBuildSave;
        private HeroBuildSelectionView heroBuildSelectionView;
        private HeroPresenter heroBuildSelectionSource;
        private void EnsureHeroBuildSelection()
        {
            heroBuildSelectionView = heroDetailView.GameObject.GetComponentInChildren<HeroBuildSelectionView>(true);
            if (heroBuildSelectionView == null) return;
            heroBuildSelectionView.Bind(services.HeroBuildSelections, RequestHeroBuildSelection, SaveHeroBuildSelection);
            if (heroBuildSelectionSource != heroPresenter)
            {
                if (heroBuildSelectionSource != null) heroBuildSelectionSource.SelectionChanged -= OnHeroBuildHeroChanged;
                heroBuildSelectionSource = heroPresenter;
                heroBuildSelectionSource.SelectionChanged += OnHeroBuildHeroChanged;
            }
            OnHeroBuildHeroChanged(heroPresenter.SelectedId);
        }
        private void OnHeroBuildHeroChanged(int hero)
        {
            string name = services.Heroes.TryGet(hero, out HeroRecord value) ? value.Name : string.Empty;
            if (heroBuildSelectionView != null) heroBuildSelectionView.SetHero(hero, name);
        }
        private void RequestHeroBuildSelection(int hero) => SendHeroBuildSelection(hero, false, 0, 0);
        private void SaveHeroBuildSelection(int hero, int branch, int strategy) => SendHeroBuildSelection(hero, true, branch, strategy);
        private void SendHeroBuildSelection(int hero, bool save, int branch, int strategy)
        {
            if (hero <= 0 || !services.Heroes.TryGet(hero, out _) || services.HeroBuildSelections.IsPending(hero)) return;
            int token = services.HeroBuildSelections.Begin(hero, save);
            try
            {
                if (save) InvokeLuaOrFail(onHeroBuildSave, "HeroBuild.Save", hero, branch, strategy);
                else InvokeLuaOrFail(onHeroBuildQuery, "HeroBuild.Query", hero);
                StartCoroutine(ExpireHeroBuildSelection(services.HeroBuildSelections, hero, token));
            }
            catch
            {
                services.HeroBuildSelections.Cancel(hero, token, "请求失败，请重试");
                throw;
            }
        }
        private IEnumerator ExpireHeroBuildSelection(HeroBuildSelectionStore source, int hero, int token)
        {
            yield return new WaitForSecondsRealtime(10f);
            source.Cancel(hero, token, "请求超时，请重试");
        }
        public void ApplyHeroBuildSelection(int hero, int branch, int strategy, int available,
            int effectiveBranch, int effectiveStrategy, bool success, string error)
            => services.HeroBuildSelections.Apply(new HeroBuildSelection(hero, branch, strategy, available,
                effectiveBranch, effectiveStrategy), success, error);
        public void ClearHeroBuildSelections() => services.HeroBuildSelections.Clear();
        private void DisposeHeroBuildSelection()
        {
            if (heroBuildSelectionSource != null) heroBuildSelectionSource.SelectionChanged -= OnHeroBuildHeroChanged;
            heroBuildSelectionSource = null;
        }
    }
}

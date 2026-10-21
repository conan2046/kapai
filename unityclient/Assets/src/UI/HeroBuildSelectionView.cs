using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

namespace ProjectX.UI
{
    // Geometry, text styles and assets belong to the current authored prefab.
    public sealed class HeroBuildSelectionView : MonoBehaviour
    {
        [SerializeField] private Button openButton;
        [SerializeField] private Button closeButton;
        [SerializeField] private GameObject panel;
        [SerializeField] private Text heroName;
        [SerializeField] private Text selection;
        [SerializeField] private Text status;
        [SerializeField] private Button[] branchButtons = new Button[3];
        [SerializeField] private Button[] strategyButtons = new Button[6];
        [SerializeField] private GameObject[] branchSelected = new GameObject[3];
        [SerializeField] private GameObject[] strategySelected = new GameObject[6];
        private HeroBuildSelectionStore store;
        private Action<int> query;
        private Action<int, int, int> save;
        private UnityAction[] branchActions, strategyActions;
        private int hero;
        private string displayName;
        public bool IsConfigured => openButton != null && closeButton != null && panel != null
            && heroName != null && selection != null && status != null && Complete(branchButtons, 3) && Complete(strategyButtons, 6);
        public bool IsOpen => panel != null && panel.activeInHierarchy;
        public int HeroId => hero;

        public void Bind(HeroBuildSelectionStore value, Action<int> request, Action<int, int, int> submit)
        {
            if (!IsConfigured) throw new InvalidOperationException("Hero build prefab bindings are incomplete.");
            if (store != null) store.Changed -= Render;
            store = value ?? throw new ArgumentNullException(nameof(value)); query = request; save = submit;
            store.Changed += Render;
            if (branchActions == null)
            {
                openButton.onClick.AddListener(Open); closeButton.onClick.AddListener(Close);
                branchActions = new UnityAction[3]; strategyActions = new UnityAction[6];
                for (int i = 0; i < branchActions.Length; i++)
                { int index = i; branchActions[i] = () => ChooseBranch(index); branchButtons[i].onClick.AddListener(branchActions[i]); }
                for (int i = 0; i < strategyActions.Length; i++)
                { int index = i; strategyActions[i] = () => ChooseStrategy(index); strategyButtons[i].onClick.AddListener(strategyActions[i]); }
            }
            Render();
        }
        public void SetHero(int id, string name)
        {
            bool changed = hero != id; hero = id; displayName = name;
            if (hero <= 0) Close();
            else if (changed && IsOpen) query?.Invoke(hero);
            Render();
        }
        private void OnEnable() { Close(); Render(); }
        private void Open() { if (hero <= 0 || store == null) return; panel.SetActive(true); query?.Invoke(hero); Render(); }
        public bool TryHandleBack()
        {
            if (!IsOpen) return false;
            Close();
            return true;
        }
        private void Close() { if (panel != null) panel.SetActive(false); }
        private void ChooseBranch(int branch)
        {
            // Branch selection is retired from the player-facing formation UI.
            return;
        }
        private void ChooseStrategy(int strategy)
        {
            if (store == null || store.IsPending(hero) || !store.TryGet(hero, out HeroBuildSelection state) || !state.CanSelect(0)) return;
            save?.Invoke(hero, 0, strategy);
        }
        private void Render()
        {
            if (!IsConfigured) return;
            bool hasHero = hero > 0;
            openButton.gameObject.SetActive(hasHero);
            openButton.interactable = hasHero;
            heroName.text = string.IsNullOrEmpty(displayName) ? "战前配置" : displayName + "·战前配置";
            HeroBuildSelection state = default;
            bool ready = store != null && store.TryGet(hero, out state), pending = store != null && store.IsPending(hero);
            for (int i = 0; i < branchButtons.Length; i++)
            { branchButtons[i].gameObject.SetActive(false); branchButtons[i].interactable = false; Mark(branchSelected, i, false); }
            for (int i = 0; i < strategyButtons.Length; i++)
            { strategyButtons[i].interactable = ready && !pending && state.CanSelect(0); Mark(strategySelected, i, ready && state.Strategy == i); }
            selection.text = ready ? StrategyName(state.Strategy) : "请选择自动策略";
            string error = store != null ? store.Error(hero) : string.Empty;
            status.text = pending ? (store.IsSaving(hero) ? "保存中…" : "读取中…") : !string.IsNullOrEmpty(error) ? error
                : ready && !state.CanSelect(0) ? "当前英雄配置不可用" : "战斗中自动执行";
        }
        private static string StrategyName(int value)
        { string[] names = { "原有策略", "救场", "守护", "控制", "爆发", "持续" }; return value >= 0 && value < names.Length ? names[value] : names[0]; }
        private static bool Complete(Button[] values, int count)
        { if (values == null || values.Length != count) return false; foreach (Button value in values) if (value == null) return false; return true; }
        private static void Mark(GameObject[] values, int index, bool active)
        { if (values != null && index < values.Length && values[index] != null) values[index].SetActive(active); }
        private void OnDestroy()
        {
            if (store != null) store.Changed -= Render;
            if (branchActions == null) return;
            if (openButton != null) openButton.onClick.RemoveListener(Open);
            if (closeButton != null) closeButton.onClick.RemoveListener(Close);
            for (int i = 0; i < branchActions.Length; i++) if (branchButtons[i] != null) branchButtons[i].onClick.RemoveListener(branchActions[i]);
            for (int i = 0; i < strategyActions.Length; i++) if (strategyButtons[i] != null) strategyButtons[i].onClick.RemoveListener(strategyActions[i]);
        }
    }
}

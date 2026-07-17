using System;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class MainTaskTrackerPresenter : IDisposable
    {
        private const string PanelPath = "Layer/Main_UI/Panel_QuestAndTeam";
        private const string PromptPath = "Layer/Main_UI/ButtonGroup5/btn_renwu/Prompt";
        private readonly TaskStore store;
        private readonly VirtualList<TaskRecord> list;
        private readonly GameObject prompt;
        private readonly Action openTasks;
        private bool serverHotPoint;

        public MainTaskTrackerPresenter(CocosUiView main, CocosUiView backup, TaskStore store, Action openTasks)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.openTasks = openTasks ?? throw new ArgumentNullException(nameof(openTasks));
            prompt = main?.Binding.Find(PromptPath)
                ?? throw new InvalidOperationException("Main task red-dot node was not found.");
            GameObject panel = backup?.Binding.Find(PanelPath)
                ?? throw new InvalidOperationException("Backup main task tracker panel was not found.");
            GameObject mainRoot = main.Binding.Find("Layer/Main_UI")
                ?? throw new InvalidOperationException("Main UI root node was not found.");
            panel.transform.SetParent(mainRoot.transform, false);
            panel.SetActive(true);
            SetVisible(panel.transform, "CheckBox_Team", false);
            SetVisible(panel.transform, "Item_Team", false);
            SetVisible(panel.transform, "Panel", false);
            SetVisible(panel.transform, "teamListView", false);
            GameObject viewport = Require(panel.transform, "ListView_1");
            GameObject template = Require(panel.transform, "Item_Quest");
            float height = Math.Max(62f, template.GetComponent<RectTransform>()?.rect.height ?? 62f);
            list = new VirtualList<TaskRecord>(viewport, template, height, BindRow);
            store.Changed += Render;
            Render();
        }

        public int ItemCount => list.Count;
        public bool IsHotPointVisible => prompt.activeSelf;

        public void SetServerHotPoint(bool visible)
        {
            serverHotPoint = visible;
            RenderHotPoint();
        }

        public void Render()
        {
            list.SetItems(store.Items.Where(item => item.State < 2).Take(3).ToArray());
            RenderHotPoint();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            list.Dispose();
        }

        private void RenderHotPoint()
        {
            // Once the daily list is loaded it is the authoritative state. This
            // also prevents a delayed /65 visible push from surviving a claim.
            prompt.SetActive(store.Count > 0 ? store.HasClaimable : serverHotPoint);
        }

        private void BindRow(RectTransform row, TaskRecord item, int index)
        {
            SetText(row, "Title", item.Title);
            SetText(row, "Condition", $"{item.Description}  {Math.Min(item.Progress, (uint)item.Target)}/{item.Target}");
            SetText(row, "State", item.State == 1 ? "可领取" : "进行中");
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => openTasks());
            row.gameObject.name = $"TrackedTask_{item.Id}_{index}";
        }

        private static GameObject Require(Transform root, string path) => root.Find(path)?.gameObject
            ?? throw new InvalidOperationException($"Task tracker node was not found: {path}");

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(Transform root, string path, bool visible)
        {
            Transform target = root.Find(path);
            if (target != null) target.gameObject.SetActive(visible);
        }
    }
}

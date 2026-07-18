using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ResourceRecoveryPresenter : IDisposable
    {
        private readonly ResourceRecoveryStore store;
        private readonly ResourceRecoveryCatalog catalog;
        private readonly Transform root;
        private readonly VirtualList<ResourceRecoveryRecord> list;
        private readonly GameObject itemTemplate;

        public ResourceRecoveryPresenter(CocosUiView view, ResourceRecoveryStore store, ResourceRecoveryCatalog catalog)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            root = view?.GameObject.transform ?? throw new ArgumentNullException(nameof(view));
            Normalize(root);
            GameObject listRoot = Require("Panel_ziyuanzhaohui/ListView").gameObject;
            GameObject rowTemplate = Require("Panel_ziyuanzhaohui/Panel_zhaohui1").gameObject;
            itemTemplate = Require("Panel_ziyuanzhaohui/Icon_1").gameObject;
            float itemHeight = Mathf.Max(120f, rowTemplate.GetComponent<RectTransform>()?.rect.height ?? 120f);
            list = new VirtualList<ResourceRecoveryRecord>(listRoot, rowTemplate, itemHeight, BindRow);
            itemTemplate.SetActive(false);
            this.store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.Items.Count == RenderedCount;
        public int RenderedCount { get; private set; }

        public void Render()
        {
            IReadOnlyList<ResourceRecoveryRecord> records = store.Items;
            list.SetItems(records);
            Transform empty = root.Find("Panel_ziyuanzhaohui/RolePic/TextBg");
            if (empty != null) empty.gameObject.SetActive(records.Count == 0);
            RenderedCount = records.Count;
        }

        private void BindRow(RectTransform row, ResourceRecoveryRecord record, int index)
        {
            row.gameObject.name = $"Recovery_{record.FunctionId}_{index}";
            SetText(row, "title/name", catalog.GetName(record.FunctionId));
            SetText(row, "times", $"剩余 {record.LeftTimes} 次");
            SetText(row, "buyBtn/GoldIcon/Num", record.CostAmount.ToString());
            Button buy = row.Find("buyBtn")?.GetComponent<Button>();
            if (buy != null) { buy.onClick.RemoveAllListeners(); buy.interactable = false; }
            Transform rewards = row.Find("item_layer");
            if (rewards == null) return;
            for (int child = rewards.childCount - 1; child >= 0; child--)
                if (rewards.GetChild(child).name.StartsWith("Reward_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(rewards.GetChild(child).gameObject);
            for (int rewardIndex = 0; rewardIndex < record.Rewards.Count; rewardIndex++)
            {
                ResourceRecoveryReward reward = record.Rewards[rewardIndex];
                GameObject item = UnityEngine.Object.Instantiate(itemTemplate, rewards, false);
                item.SetActive(true); item.name = $"Reward_{reward.ItemId}_{rewardIndex}";
                SetText(item.transform, "Name", $"{reward.ItemId} ×{reward.Amount}");
            }
        }

        private Transform Require(string path) => root.Find(path) ?? throw new InvalidOperationException($"ResourceRecovery node missing: {path}");
        private static void SetText(Transform root, string path, string value) { Text text = root.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value; }
        private static void Normalize(Transform root) { if (!(root is RectTransform rect)) return; rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero; rect.localScale = Vector3.one; rect.localRotation = Quaternion.identity; }

        public void Dispose()
        {
            store.Changed -= Render;
            list.Dispose();
        }
    }
}

using System;
using System.Collections.Generic;
using System.IO;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public enum SinglePlayerSaveMenuMode
    {
        NewGame,
        Continue,
        SaveCurrent
    }

    public sealed class OldMemoryPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly SinglePlayerSaveService saves;
        private readonly IUiResourceProvider resources;
        private readonly Action<int, bool> playSlot;
        private readonly Action<int> saveSlot;
        private readonly Action close;
        private readonly Action<string, string, Action> confirm;
        private readonly Action<string> showError;
        private readonly Action<string> setStatus;
        private readonly ScrollRect slotScroll;
        private IReadOnlyList<SinglePlayerSaveSlot> slots = Array.Empty<SinglePlayerSaveSlot>();
        private SinglePlayerSaveMenuMode mode;
        private int selectedSlotId;

        public OldMemoryPresenter(CocosUiView view, SinglePlayerSaveService saves, IUiResourceProvider resources,
            Action<int, bool> playSlot, Action<int> saveSlot, Action close, Action<string, string, Action> confirm,
            Action<string> showError, Action<string> setStatus)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.saves = saves ?? throw new ArgumentNullException(nameof(saves));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.playSlot = playSlot ?? throw new ArgumentNullException(nameof(playSlot));
            this.saveSlot = saveSlot ?? throw new ArgumentNullException(nameof(saveSlot));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.confirm = confirm ?? throw new ArgumentNullException(nameof(confirm));
            this.showError = showError ?? (_ => { });
            this.setStatus = setStatus ?? (_ => { });
            view.BindClick("Btn_Back", Close, true);
            slotScroll = view.Binding.Find("SlotContent")?.GetComponent<ScrollRect>();
            SetActive("Tabs", false);
            SetActive("BackupContent", false);
            view.SetVisible(false);
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;
        public SinglePlayerSaveMenuMode Mode => mode;

        public void Show(SinglePlayerSaveMenuMode value)
        {
            mode = value;
            slots = saves.GetSlots();
            selectedSlotId = ChooseInitialSlot(slots, value);
            SetText("Title", value == SinglePlayerSaveMenuMode.NewGame
                ? "新 的 回 忆"
                : value == SinglePlayerSaveMenuMode.SaveCurrent ? "保 存 回 忆" : "旧 的 回 忆");
            SetText("Subtitle", value == SinglePlayerSaveMenuMode.NewGame
                ? "选择已有存档重新开始新的封神之路"
                : value == SinglePlayerSaveMenuMode.SaveCurrent
                    ? "选择档位，保存当前游戏进度"
                    : "选择一段回忆，继续封神之路");
            view.ShowPopup();
            RenderSlots();
            ShowSlots();
            if (value == SinglePlayerSaveMenuMode.Continue)
                view.Binding.RetireLegacyNodeMetadataAtRuntime();
        }

        public void Hide() => view.SetVisible(false);

        public void Dispose() { }

        private void RenderSlots()
        {
            foreach (SinglePlayerSaveSlot slot in slots)
            {
                string root = SlotPath(slot.SlotId);
                GameObject card = Require(root);
                EnsureButton(card, () => SelectSlot(slot.SlotId));
                SetText(root + "/SlotTitle", $"存档 {slot.SlotId:00}");
                SetActive(root + "/State_Selected", slot.SlotId == selectedSlotId);
                SetActive(root + "/FilledState", slot.Exists);
                SetActive(root + "/EmptyState", !slot.Exists);
                SetActive(root + "/State_Corrupt", slot.IsCorrupt);
                SetActive(root + "/State_CloudConflict", false);
                if (slot.Exists) RenderFilledSlot(slot, root);
                else RenderEmptySlot(slot, root);
            }
        }

        private void RenderFilledSlot(SinglePlayerSaveSlot slot, string root)
        {
            SinglePlayerSaveMetadata metadata = slot.Metadata ?? new SinglePlayerSaveMetadata();
            string filled = root + "/FilledState";
            SetText(filled + "/RoleName", string.IsNullOrWhiteSpace(metadata.roleName)
                ? (slot.IsLegacyImport ? "本地旧存档" : "未记录角色") : metadata.roleName);
            SetText(filled + "/Realm", "境界：--");
            SetText(filled + "/Level", metadata.level > 0 ? $"等级：{metadata.level}" : "等级：--");
            SetText(filled + "/PowerBg/CombatPower", metadata.combatPower > 0 ? $"战力：{metadata.combatPower}" : "战力：--");
            SetText(filled + "/PlayTime", "游戏时间：" + FormatDuration(metadata.totalPlaySeconds));
            SetText(filled + "/LastSaved", "最后保存：" + FormatSavedTime(metadata.updatedUtc, slot.DatabasePath));
            ApplyPortrait(filled, metadata.heroPicture);

            bool saving = mode == SinglePlayerSaveMenuMode.SaveCurrent;
            Button enter = view.BindClick(filled + "/Btn_Enter", () => RequestPlay(slot), true);
            enter.gameObject.SetActive(!saving);
            enter.interactable = mode == SinglePlayerSaveMenuMode.NewGame || !slot.IsCorrupt;
            SetButtonLabel(enter, mode == SinglePlayerSaveMenuMode.NewGame ? "重新开始" : "进入游戏");
            Button manage = view.BindClick(filled + "/Btn_Manage", () => RequestDeleteSlot(slot), true);
            manage.gameObject.SetActive(!saving);
            manage.interactable = true;
            SetButtonLabel(manage, "删除存档");

            GameObject saveObject = view.Binding.Find(filled + "/Btn_Create");
            if (saveObject == null)
                throw new InvalidOperationException("OldMemory filled save button was not found: " + filled + "/Btn_Create");
            saveObject.SetActive(saving);
            if (saving)
            {
                Button save = view.BindClick(filled + "/Btn_Create", () => RequestSave(slot), true);
                save.interactable = true;
                SetButtonLabel(save, "保存回忆");
            }
        }

        private void RenderEmptySlot(SinglePlayerSaveSlot slot, string root)
        {
            string empty = root + "/EmptyState";
            GameObject createObject = view.Binding.Find(empty + "/Btn_Create");
            if (createObject == null)
                throw new InvalidOperationException("OldMemory empty save button was not found: " + empty + "/Btn_Create");
            bool saving = mode == SinglePlayerSaveMenuMode.SaveCurrent;
            createObject.SetActive(saving);
            if (!saving) return;
            Button create = view.BindClick(empty + "/Btn_Create", () => RequestSave(slot), true);
            create.interactable = true;
            SetButtonLabel(create, "保存回忆");
        }

        private void RequestSave(SinglePlayerSaveSlot slot)
        {
            SelectSlot(slot.SlotId);
            Action save = () =>
            {
                try
                {
                    saveSlot(slot.SlotId);
                    slots = saves.GetSlots();
                    RenderSlots();
                    ShowSlots();
                }
                catch (Exception exception) { showError(exception.Message); }
            };
            if (slot.Exists)
            {
                confirm("覆盖存档", $"确定用当前游戏进度覆盖存档 {slot.SlotId:00} 吗？", save);
                return;
            }
            save();
        }

        private void RequestPlay(SinglePlayerSaveSlot slot)
        {
            SelectSlot(slot.SlotId);
            if (mode == SinglePlayerSaveMenuMode.NewGame)
            {
                confirm("重新开始", $"存档 {slot.SlotId:00} 的当前进度将被覆盖，确定开始新的回忆吗？",
                    () => playSlot(slot.SlotId, true));
                return;
            }
            if (slot.IsCorrupt)
            {
                showError($"存档 {slot.SlotId:00} 已损坏，请删除后重新创建。");
                return;
            }
            playSlot(slot.SlotId, false);
        }

        private void SelectSlot(int slotId)
        {
            selectedSlotId = slotId;
            for (int index = 1; index <= SinglePlayerSaveService.SlotCount; index++)
                SetActive(SlotPath(index) + "/State_Selected", index == slotId);
        }

        private void ShowSlots()
        {
            SetActive("SlotContent", true);
            SetActive("BackupContent", false);
            SetActive("Tabs", false);
            Canvas.ForceUpdateCanvases();
            if (slotScroll != null) slotScroll.verticalNormalizedPosition = 1f;
            SetText("Footer/Hint", mode == SinglePlayerSaveMenuMode.NewGame
                ? "选择已有存档可从头开始新的回忆"
                : mode == SinglePlayerSaveMenuMode.SaveCurrent
                    ? "空档直接保存；已有档位将被当前进度覆盖"
                    : "选择任意存档，进入该存档记录的角色与进度");
        }

        private void RequestDeleteSlot(SinglePlayerSaveSlot slot)
        {
            SelectSlot(slot.SlotId);
            confirm("删除存档", $"存档 {slot.SlotId:00} 将永久删除，确定继续吗？", () =>
            {
                try
                {
                    saves.DeleteSlot(slot.SlotId);
                    slots = saves.GetSlots();
                    RenderSlots();
                    ShowSlots();
                    setStatus($"存档 {slot.SlotId:00} 已删除。");
                }
                catch (Exception exception) { showError("删除失败：" + exception.Message); }
            });
        }

        private void ApplyPortrait(string filledPath, int picture)
        {
            Transform filled = Require(filledPath).transform;
            Transform portraitTransform = filled.Find("iocn_bg/PortraitFrame") ?? filled.Find("HeroPortrait");
            if (portraitTransform == null)
            {
                GameObject portraitObject = new GameObject("HeroPortrait", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                portraitTransform = portraitObject.transform;
                RectTransform rect = (RectTransform)portraitTransform;
                rect.SetParent(filled, false);
                rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = new Vector2(-405f, -7f);
                rect.sizeDelta = new Vector2(88f, 88f);
                Image portrait = portraitObject.GetComponent<Image>();
                portrait.preserveAspect = true;
                portrait.raycastTarget = false;
            }
            Image image = portraitTransform.GetComponent<Image>();
            image.sprite = picture > 0 ? resources.LoadPlayerSavePortrait(picture) : null;
            image.gameObject.SetActive(image.sprite != null);
        }

        private void Close()
        {
            Hide();
            close();
        }

        private static string SlotPath(int slotId)
            => $"SlotContent/Viewport/Content/Slot_{slotId:00}";

        private int ChooseInitialSlot(IReadOnlyList<SinglePlayerSaveSlot> values, SinglePlayerSaveMenuMode menuMode)
        {
            if (menuMode == SinglePlayerSaveMenuMode.SaveCurrent && saves.ActiveSlotId > 0)
                return saves.ActiveSlotId;
            if (menuMode == SinglePlayerSaveMenuMode.NewGame)
                foreach (SinglePlayerSaveSlot slot in values) if (!slot.Exists) return slot.SlotId;
            foreach (SinglePlayerSaveSlot slot in values) if (slot.Exists) return slot.SlotId;
            return values.Count > 0 ? values[0].SlotId : 1;
        }

        private GameObject Require(string path) => view.Binding.Find(path)
            ?? throw new InvalidOperationException("OldMemory node was not found: " + path);

        private void SetActive(string path, bool active)
        {
            GameObject node = view.Binding.Find(path);
            if (node != null) node.SetActive(active);
        }

        private void SetText(string path, string value)
        {
            Text text = view.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static Button EnsureButton(GameObject node, Action callback)
        {
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            button.interactable = true;
            return button;
        }

        private static void SetButtonLabel(Button button, string value)
        {
            Text[] labels = button.GetComponentsInChildren<Text>(true);
            foreach (Text label in labels)
                if (label.gameObject.name == "Label" || label.gameObject.name == "Text_2") label.text = value;
        }

        private static string FormatDuration(long seconds)
        {
            seconds = Math.Max(0L, seconds);
            long hours = seconds / 3600;
            return $"{hours:00}:{seconds / 60 % 60:00}:{seconds % 60:00}";
        }

        private static string FormatSavedTime(string utc, string databasePath)
        {
            if (DateTime.TryParse(utc, out DateTime parsed) && parsed.Year > 2000)
                return parsed.ToLocalTime().ToString("yyyy-MM-dd HH:mm");
            try
            {
                return File.Exists(databasePath) ? File.GetLastWriteTime(databasePath).ToString("yyyy-MM-dd HH:mm") : "--";
            }
            catch { return "--"; }
        }

    }
}

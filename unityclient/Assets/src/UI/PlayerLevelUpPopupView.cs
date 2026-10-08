using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class PlayerLevelUpPopupView
    {
        private readonly UnityUiView view;
        private readonly Action close;

        public PlayerLevelUpPopupView(UnityUiView view, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            view.BindClick("Mask", this.close, addButtonIfMissing: true);
        }

        public void Show(int currentLevel, int staminaBefore, int staminaAfter)
        {
            SetText("Panel_shengji/Panel_gongxi/Num", currentLevel.ToString());
            SetText("Panel_shengji/Panel_tili/Image_tili/Text1", staminaBefore.ToString());
            SetText("Panel_shengji/Panel_tili/Image_tili/Text2", staminaAfter.ToString());

            FunctionUnlockDefinition[] upcoming = FunctionUnlockCatalog.GetUpcoming(currentLevel, 3);
            for (int i = 0; i < 3; i++)
            {
                string rowPath = $"Panel_shengji/Panel_gongneng/Panel_{i + 1}";
                GameObject row = view.FindNode(rowPath);
                if (row == null)
                    throw new InvalidOperationException($"Player level-up function row is missing: {rowPath}");
                bool hasData = i < upcoming.Length;
                row.SetActive(hasData);
                if (!hasData) continue;

                FunctionUnlockDefinition definition = upcoming[i];
                SetText(rowPath + "/Text", definition.Name);
                SetText(rowPath + "/Text_2", definition.OpenLevel <= currentLevel
                    ? string.Empty : $"{definition.OpenLevel}级开启");
                Image iconImage = view.FindNode(rowPath + "/Icon")?.GetComponent<Image>();
                if (iconImage == null)
                    throw new InvalidOperationException($"Player level-up icon binding is missing: {rowPath}/Icon");
                Sprite icon = FunctionUnlockCatalog.LoadIcon(definition);
                if (icon != null) iconImage.sprite = icon;
                GameObject opened = view.FindNode(rowPath + "/Text_1");
                if (opened != null) opened.SetActive(definition.OpenLevel <= currentLevel);
                GameObject locked = view.FindNode(rowPath + "/Text_2");
                if (locked != null) locked.SetActive(definition.OpenLevel > currentLevel);
            }

            view.FindNode("Panel_shengji/Panel_tili")?.SetActive(true);
            view.ShowPopup();
            Animator animator = view.GameObject.GetComponent<Animator>();
            if (animator == null)
                throw new InvalidOperationException("Player level-up Prefab has no Unity Animator.");
            animator.Play("animation0", 0, 0f);
        }

        private void SetText(string path, string value)
        {
            GameObject node = view.FindNode(path);
            Text text = node != null ? node.GetComponent<Text>() : null;
            if (text == null)
                throw new InvalidOperationException($"Player level-up Text binding is missing: {path}");
            text.text = value;
        }
    }
}

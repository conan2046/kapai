using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class MainHudPresenter : IDisposable
    {
        private readonly PlayerStore player;
        private readonly CurrencyStore currencies;
        private readonly Core.ResourceService resources;
        private readonly Image portrait;
        private readonly Text nameText;
        private readonly Text levelText;
        private readonly Text vipText;
        private readonly Text powerText;
        private readonly Text goldText;
        private readonly Text premiumText;
        private readonly Text staminaText;

        public MainHudPresenter(CocosUiView view, PlayerStore player, CurrencyStore currencies,
            Core.ResourceService resources)
        {
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            nameText = RequireText(view, "Layer/Main_UI/Head/name_bg/name");
            levelText = RequireText(view, "Layer/Main_UI/Head/bg_Level/Value");
            vipText = RequireText(view, "Layer/Main_UI/Head/bg_VIP/Value");
            powerText = RequireText(view, "Layer/Main_UI/Head/bg_CombatEffetiveness/Value");
            goldText = RequireText(view, "Layer/Main_UI/ButtonGroup6/Icon_jinbi/NumBg/Num");
            premiumText = RequireText(view, "Layer/Main_UI/ButtonGroup6/Icon_yuanbao/GoldNumBg/Num");
            staminaText = RequireText(view, "Layer/Main_UI/ButtonGroup6/Icon_tili/NumBg/Num");
            portrait = view.Binding.Find("Layer/Main_UI/Head/Icon")?.GetComponent<Image>();
            if (portrait != null)
            {
                portrait.preserveAspect = true;
                portrait.color = Color.white;
            }
            player.Changed += Render;
            currencies.Changed += Render;
            Render();
        }

        public void Render()
        {
            nameText.text = player.Name;
            levelText.text = player.Level.ToString();
            vipText.text = "贵族0";
            powerText.text = FormatCompact(player.Power);
            if (portrait != null)
            {
                portrait.sprite = resources.LoadPlayerRoundPortrait(player.Head);
            }
            goldText.text = FormatCompact(unchecked((ulong)Math.Max(0, currencies.Gold)));
            premiumText.text = FormatCompact(unchecked((ulong)Math.Max(0, currencies.Premium)));
            staminaText.text = currencies.Get(CurrencyIds.Stamina).ToString();
        }

        public bool Validate(out string detail)
        {
            detail = string.Empty;
            if (!player.IsLoaded || string.IsNullOrEmpty(player.Name)) { detail = "player snapshot is not loaded"; return false; }
            if (nameText.text != player.Name || levelText.text != player.Level.ToString()) { detail = "name/level HUD mismatch"; return false; }
            if (goldText.text != FormatCompact(unchecked((ulong)currencies.Gold))) { detail = "gold HUD mismatch"; return false; }
            if (premiumText.text != FormatCompact(unchecked((ulong)currencies.Premium))) { detail = "premium HUD mismatch"; return false; }
            if (currencies.Stamina <= 0 || staminaText.text != currencies.Stamina.ToString()) { detail = "stamina HUD mismatch"; return false; }
            detail = $"role={player.RoleId} name={player.Name} level={player.Level} gold={currencies.Gold} premium={currencies.Premium} stamina={currencies.Stamina}";
            return true;
        }

        public void Dispose()
        {
            player.Changed -= Render;
            currencies.Changed -= Render;
        }

        private static Text RequireText(CocosUiView view, string path)
        {
            GameObject node = view?.Binding.Find(path) ?? throw new InvalidOperationException($"Main HUD node was not found: {path}");
            return node.GetComponent<Text>() ?? throw new InvalidOperationException($"Main HUD node has no Text component: {path}");
        }

        private static string FormatCompact(ulong value)
        {
            if (value < 10000) return value.ToString();
            if (value < 100000000) return $"{value / 10000d:0.#}万";
            return $"{value / 100000000d:0.#}亿";
        }
    }
}

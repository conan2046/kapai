using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class JingJieIncomeView : MonoBehaviour
    {
        private JingJieViewState state;
        private Scrollbar progress;
        private Text rate;
        public void Bind(JingJieViewState value, Scrollbar bar, Text number)
        {
            state = value ?? throw new ArgumentNullException(nameof(value));
            progress = bar != null ? bar : throw new InvalidOperationException("Jingjie expect Scrollbar is missing.");
            rate = number != null ? number : throw new InvalidOperationException("Jingjie expect Num is missing.");
            Refresh();
        }

        private void Update() => Refresh();

        private void Refresh()
        {
            if (state == null || progress == null) return;
            progress.SetValueWithoutNotify(0f);
            progress.size = state.CycleProgress;
            string value = state.ExperiencePerSecond.ToString("N0");
            if (rate.text != value) rate.text = value;
        }

    }
}

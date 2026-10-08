using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>
    /// Serialized Unity references for the Login startup sequence.
    /// </summary>
    public sealed class StartupViewBindings : MonoBehaviour
    {
        [SerializeField] private Image background;
        [SerializeField] private Image tipBackground;
        [SerializeField] private Text tip;
        [SerializeField] private Sprite logoSprite;
        [SerializeField] private Sprite preloadSprite;
        [SerializeField] private Sprite tipBackgroundSprite;

        public GameObject Root => gameObject;
        public Image Background => background;
        public Image TipBackground => tipBackground;
        public Text Tip => tip;
        public Sprite LogoSprite => logoSprite;
        public Sprite PreloadSprite => preloadSprite;
        public Sprite TipBackgroundSprite => tipBackgroundSprite;
    }
}
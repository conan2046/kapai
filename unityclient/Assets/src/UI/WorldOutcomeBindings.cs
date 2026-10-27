using UnityEngine;

namespace ProjectX.UI
{
    public sealed class WorldOutcomeBindings : MonoBehaviour
    {
        [SerializeField] private Sprite[] heroQualityRatings = new Sprite[8];

        public Sprite GetHeroQualityRating(int quality)
        {
            if (heroQualityRatings == null || heroQualityRatings.Length == 0) return null;
            return heroQualityRatings[Mathf.Clamp(quality - 1, 0, heroQualityRatings.Length - 1)];
        }
    }
}

using UnityEngine;

namespace ProjectX.UI
{
    // Camera, render target, particle resources and all transforms are authored
    // in the stage prefab. The view only owns its lifetime and visibility.
    public sealed class UiPrefabEffectStage : MonoBehaviour
    {
        [SerializeField] private GameObject stagePrefab;
        private GameObject stage;

        private void OnEnable()
        {
            if (stagePrefab != null && stage == null) stage = Instantiate(stagePrefab);
        }

        private void OnDisable()
        {
            if (stage != null) Destroy(stage);
            stage = null;
        }
    }
}

using System;
using ProjectX.UI.Migration;
using UnityEngine;

namespace ProjectX.UI
{
    public static class UiPrefabLoader
    {
        private const string ResourceRoot = "UiPrefabs/";

        public static CocosUiView Load(string key, Transform parent)
        {
            if (string.IsNullOrWhiteSpace(key)) throw new ArgumentException("UI prefab key is required.", nameof(key));
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            UiPrefabReference reference = Resources.Load<UiPrefabReference>(ResourceRoot + key);
            if (reference == null || reference.Prefab == null)
                throw new InvalidOperationException($"Dynamic UI prefab reference was not found: {key}");
            GameObject instance = UnityEngine.Object.Instantiate(reference.Prefab, parent, false);
            instance.name = $"DynamicUi_{key}";
            CocosUiBinding binding = instance.GetComponent<CocosUiBinding>()
                ?? instance.GetComponentInChildren<CocosUiBinding>(true);
            if (binding == null)
            {
                UnityEngine.Object.Destroy(instance);
                throw new InvalidOperationException($"Dynamic UI prefab has no CocosUiBinding: {key}");
            }
            instance.SetActive(false);
            return new CocosUiView(binding);
        }

        public static void Release(CocosUiView view)
        {
            if (view?.GameObject != null) UnityEngine.Object.Destroy(view.GameObject);
        }
    }
}

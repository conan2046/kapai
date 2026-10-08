using UnityEngine;

namespace ProjectX.UI
{
    public sealed class UiPrefabReference : ScriptableObject
    {
        [SerializeField] private GameObject prefab;

        public GameObject Prefab => prefab;

        public void SetPrefab(GameObject value) => prefab = value;
    }
}

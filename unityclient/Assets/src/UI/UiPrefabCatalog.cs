using System;
using System.Collections.Generic;
using UnityEngine;

namespace ProjectX.UI
{
    [Serializable]
    public sealed class UiPrefabCatalogEntry
    {
        [SerializeField] private string key;
        [SerializeField] private string source;
        [SerializeField] private string parentKey;
        [SerializeField] private bool defaultActive;

        public UiPrefabCatalogEntry(string key, string source, string parentKey, bool defaultActive)
        {
            this.key = key;
            this.source = source;
            this.parentKey = parentKey;
            this.defaultActive = defaultActive;
        }

        public string Key => key;
        public string Source => source;
        public string ParentKey => parentKey;
        public bool DefaultActive => defaultActive;
    }

    public sealed class UiPrefabCatalog : ScriptableObject
    {
        [SerializeField] private List<UiPrefabCatalogEntry> entries = new List<UiPrefabCatalogEntry>();

        public IReadOnlyList<UiPrefabCatalogEntry> Entries => entries;

        public void Replace(IEnumerable<UiPrefabCatalogEntry> values)
        {
            entries.Clear();
            if (values != null) entries.AddRange(values);
        }
    }
}

using System;
using System.Collections.Generic;
using UnityEngine;

namespace ProjectX.UI.Migration
{
    // Serialized identity data retained after legacy path-binding removal.
    // Source, node and alias tuples were checked against existing Prefabs and snapshots.
    [DisallowMultipleComponent]
    public sealed class UiPrefabIdentity : MonoBehaviour
    {
        [SerializeField] private string source;
        [SerializeField] private List<CocosNodeReference> nodes = new List<CocosNodeReference>();
        [SerializeField] private List<CocosNodeReference> retiredMetadataAliases =
            new List<CocosNodeReference>();

        public string Source => source;
        public bool ExcludeFromSourceLookup { get; set; }
        public IReadOnlyList<CocosNodeReference> Nodes => nodes;
        public IReadOnlyList<CocosNodeReference> RetiredMetadataAliases => retiredMetadataAliases;

        public void Initialize(string sourcePath, IReadOnlyList<CocosNodeReference> references,
            IReadOnlyList<CocosNodeReference> aliases = null)
        {
            source = sourcePath;
            nodes = Copy(references);
            retiredMetadataAliases = Copy(aliases);
        }

        public GameObject FindSerializedActionTag(int actionTag)
        {
            CocosNodeReference reference = nodes?.Find(item => item != null
                && item.actionTag == actionTag);
            return reference?.target;
        }

        public GameObject Find(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) return null;
            CocosNodeReference reference = nodes?.Find(item => item != null && item.path == path);
            if (reference?.target != null) return reference.target;
            reference = retiredMetadataAliases?.Find(item => item != null && item.path == path);
            if (reference?.target != null) return reference.target;
            Transform target = transform.Find(path);
            if (target == null && path.StartsWith("Layer/", StringComparison.Ordinal))
                target = transform.Find(path.Substring("Layer/".Length));
            return target != null ? target.gameObject : null;
        }

        public GameObject Find(string path, string nodeType, int actionTag)
        {
            CocosNodeReference reference = nodes?.Find(item => item != null
                && item.path == path && item.nodeType == nodeType
                && item.actionTag == actionTag);
            if (reference?.target != null) return reference.target;
            reference = retiredMetadataAliases?.Find(item => item != null
                && item.path == path && item.nodeType == nodeType
                && item.actionTag == actionTag);
            return reference?.target;
        }

        private static List<CocosNodeReference> Copy(IReadOnlyList<CocosNodeReference> references)
        {
            var result = new List<CocosNodeReference>(references?.Count ?? 0);
            if (references == null) return result;
            foreach (CocosNodeReference reference in references)
            {
                if (reference == null)
                {
                    result.Add(null);
                    continue;
                }
                result.Add(new CocosNodeReference
                {
                    path = reference.path,
                    nodeType = reference.nodeType,
                    tag = reference.tag,
                    actionTag = reference.actionTag,
                    target = reference.target
                });
            }
            return result;
        }
    }
}

using System;
using System.Collections.Generic;
using UnityEngine;

namespace ProjectX.UI.Migration
{
    [Serializable]
    public sealed class CocosNodeReference
    {
        public string path;
        public string nodeType;
        public int tag;
        public int actionTag;
        public GameObject target;
    }

    public sealed class CocosUiBinding : MonoBehaviour
    {
        private static readonly Dictionary<GameObject, CocosNodeReference> retiredMetadataIdentities =
            new Dictionary<GameObject, CocosNodeReference>();

        [SerializeField] private string source;
        [SerializeField] private List<CocosNodeReference> nodes = new List<CocosNodeReference>();

        public string Source => source;
        public IReadOnlyList<CocosNodeReference> Nodes => nodes;
        public static IReadOnlyDictionary<GameObject, CocosNodeReference> RetiredMetadataIdentities => retiredMetadataIdentities;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void ResetRetiredMetadataIdentities()
        {
            retiredMetadataIdentities.Clear();
        }

        public static void PreserveRetiredMetadataIdentity(CocosNodeMetadata metadata)
        {
            if (metadata == null || metadata.gameObject == null
                || retiredMetadataIdentities.ContainsKey(metadata.gameObject))
                return;

            retiredMetadataIdentities.Add(metadata.gameObject, new CocosNodeReference
            {
                path = metadata.CocosPath,
                nodeType = metadata.NodeType,
                tag = metadata.Tag,
                actionTag = metadata.ActionTag,
                target = metadata.gameObject
            });
        }

        public void Initialize(string sourcePath, List<CocosNodeReference> nodeReferences)
        {
            source = sourcePath;
            nodes = nodeReferences;
        }

        public int RetireLegacyNodeMetadataAtRuntime()
        {
            if (!Application.isPlaying) return 0;

            CocosNodeMetadata[] metadata = GetComponentsInChildren<CocosNodeMetadata>(true);
            foreach (CocosNodeMetadata item in metadata)
            {
                if (item == null) continue;
                PreserveExactAncestorIdentity(item);
                PreserveRetiredMetadataIdentity(item);
                Destroy(item);
            }
            return metadata.Length;
        }

        private void PreserveExactAncestorIdentity(CocosNodeMetadata metadata)
        {
            if (metadata == null || string.IsNullOrWhiteSpace(metadata.CocosPath)) return;
            nodes = nodes ?? new List<CocosNodeReference>();

            // Existing targets and paths keep their current canonical identity.
            // Only synthesize a reference when both the target and Cocos path are
            // absent, so Find(path) cannot change which object it resolves.
            if (nodes.Exists(node => node != null && node.target == metadata.gameObject)
                || nodes.Exists(node => node != null && node.path == metadata.CocosPath))
                return;

            CocosNodeReference ancestorReference = null;
            Transform ancestor = metadata.transform.parent;
            while (ancestor != null)
            {
                foreach (CocosNodeReference candidate in nodes)
                {
                    if (candidate == null || candidate.target != ancestor.gameObject
                        || string.IsNullOrWhiteSpace(candidate.path))
                        continue;

                    if (ancestorReference == null
                        || string.CompareOrdinal(candidate.path, ancestorReference.path) < 0
                        || (string.Equals(candidate.path, ancestorReference.path, StringComparison.Ordinal)
                            && string.CompareOrdinal(candidate.nodeType, ancestorReference.nodeType) < 0))
                        ancestorReference = candidate;
                }

                if (ancestorReference != null || ancestor == transform) break;
                ancestor = ancestor.parent;
            }
            if (ancestorReference == null) return;

            var segments = new Stack<string>();
            for (Transform current = metadata.transform;
                 current != null && current != ancestorReference.target.transform;
                 current = current.parent)
                segments.Push(current.name);

            string relativePath = string.Join("/", segments.ToArray());
            string derivedPath = string.IsNullOrEmpty(relativePath)
                ? ancestorReference.path
                : ancestorReference.path + "/" + relativePath;
            if (!string.Equals(derivedPath, metadata.CocosPath, StringComparison.Ordinal)) return;

            nodes.Add(new CocosNodeReference
            {
                path = metadata.CocosPath,
                nodeType = metadata.NodeType,
                tag = metadata.Tag,
                actionTag = metadata.ActionTag,
                target = metadata.gameObject
            });
        }

        public int RetireMetadataWithSerializedIdentityAtRuntime(Transform preserveSubtree)
        {
            if (!Application.isPlaying) return 0;

            int retired = 0;
            CocosNodeMetadata[] metadata = GetComponentsInChildren<CocosNodeMetadata>(true);
            foreach (CocosNodeMetadata item in metadata)
            {
                if (item == null) continue;
                if (preserveSubtree != null
                    && (item.transform == preserveSubtree || item.transform.IsChildOf(preserveSubtree)))
                    continue;

                CocosNodeReference reference = nodes.Find(node => node != null
                    && node.target == item.gameObject
                    && node.path == item.CocosPath
                    && node.nodeType == item.NodeType
                    && node.tag == item.Tag
                    && node.actionTag == item.ActionTag);
                if (reference == null) continue;

                PreserveRetiredMetadataIdentity(item);
                Destroy(item);
                retired++;
            }
            return retired;
        }

        public int RetireMetadataWithSerializedIdentityAtRuntimePreserving(params Transform[] preserveSubtrees)
        {
            if (!Application.isPlaying) return 0;

            int retired = 0;
            CocosNodeMetadata[] metadata = GetComponentsInChildren<CocosNodeMetadata>(true);
            foreach (CocosNodeMetadata item in metadata)
            {
                if (item == null) continue;

                bool preserve = false;
                if (preserveSubtrees != null)
                {
                    foreach (Transform subtree in preserveSubtrees)
                    {
                        if (subtree == null) continue;
                        if (item.transform == subtree || item.transform.IsChildOf(subtree))
                        {
                            preserve = true;
                            break;
                        }
                    }
                }
                if (preserve) continue;

                CocosNodeReference reference = nodes.Find(node => node != null
                    && node.target == item.gameObject
                    && node.path == item.CocosPath
                    && node.nodeType == item.NodeType
                    && node.tag == item.Tag
                    && node.actionTag == item.ActionTag);
                if (reference == null) continue;

                PreserveRetiredMetadataIdentity(item);
                Destroy(item);
                retired++;
            }
            return retired;
        }

        public int RetireMetadataInSubtreeWithSerializedIdentityAtRuntime(Transform subtree)
        {
            if (!Application.isPlaying || subtree == null
                || (subtree != transform && !subtree.IsChildOf(transform))) return 0;

            int retired = 0;
            CocosNodeMetadata[] metadata = subtree.GetComponentsInChildren<CocosNodeMetadata>(true);
            foreach (CocosNodeMetadata item in metadata)
            {
                if (item == null) continue;

                CocosNodeReference reference = nodes.Find(node => node != null
                    && node.target == item.gameObject
                    && node.path == item.CocosPath
                    && node.nodeType == item.NodeType
                    && node.tag == item.Tag
                    && node.actionTag == item.ActionTag);
                if (reference == null) continue;

                PreserveRetiredMetadataIdentity(item);
                Destroy(item);
                retired++;
            }
            return retired;
        }

        public int RetireMetadataClonedFromSerializedTemplateAtRuntime(Transform template, Transform clonesRoot)
        {
            if (!Application.isPlaying || template == null || clonesRoot == null) return 0;

            CocosNodeMetadata[] templateMetadata = template.GetComponentsInChildren<CocosNodeMetadata>(true);
            if (templateMetadata.Length == 0) return 0;

            int retired = 0;
            for (int rowIndex = 0; rowIndex < clonesRoot.childCount; rowIndex++)
            {
                Transform row = clonesRoot.GetChild(rowIndex);
                if (row == template) continue;
                CocosNodeMetadata[] cloneMetadata = row.GetComponentsInChildren<CocosNodeMetadata>(true);
                if (cloneMetadata.Length != templateMetadata.Length) continue;

                bool matchesTemplate = true;
                var retireTargets = new List<CocosNodeMetadata>();
                var matchedSources = new HashSet<CocosNodeMetadata>();
                foreach (CocosNodeMetadata clone in cloneMetadata)
                {
                    string relativePath = RelativeSiblingIndexPath(row, clone.transform);
                    CocosNodeMetadata[] sources = Array.FindAll(templateMetadata, item => item != null
                        && RelativeSiblingIndexPath(template, item.transform) == relativePath);
                    CocosNodeMetadata source = sources.Length == 1 ? sources[0] : null;
                    if (source == null || !matchedSources.Add(source) || source.CocosPath != clone.CocosPath
                        || source.NodeType != clone.NodeType || source.Tag != clone.Tag
                        || source.ActionTag != clone.ActionTag)
                    {
                        matchesTemplate = false;
                        break;
                    }

                    if (nodes.Exists(reference => reference != null
                        && reference.target == source.gameObject
                        && reference.path == source.CocosPath
                        && reference.nodeType == source.NodeType
                        && reference.tag == source.Tag
                        && reference.actionTag == source.ActionTag))
                        retireTargets.Add(clone);
                }
                if (!matchesTemplate || matchedSources.Count != templateMetadata.Length) continue;

                foreach (CocosNodeMetadata clone in retireTargets)
                {
                    PreserveRetiredMetadataIdentity(clone);
                    Destroy(clone);
                    retired++;
                }
            }
            return retired;
        }

        private static string RelativeSiblingIndexPath(Transform root, Transform target)
        {
            var segments = new Stack<string>();
            for (Transform current = target; current != null && current != root; current = current.parent)
                segments.Push(current.GetSiblingIndex().ToString());
            return target == root || target.IsChildOf(root) ? string.Join("/", segments.ToArray()) : null;
        }

        public int RetireMetadataWithCompleteRuntimeIdentityAtRuntime()
        {
            if (!Application.isPlaying) return 0;

            int retired = 0;
            CocosNodeMetadata[] metadata = GetComponentsInChildren<CocosNodeMetadata>(true);
            foreach (CocosNodeMetadata item in metadata)
            {
                if (item == null) continue;

                PreserveExactAncestorIdentity(item);
                CocosNodeReference pathReference = nodes.Find(node => node != null
                    && node.path == item.CocosPath);
                CocosNodeReference typedReference = nodes.Find(node => node != null
                    && node.path == item.CocosPath
                    && node.nodeType == item.NodeType
                    && node.actionTag == item.ActionTag);
                if (pathReference == null || pathReference.target != item.gameObject
                    || typedReference == null || typedReference.target != item.gameObject
                    || !nodes.Exists(node => node != null && node.actionTag == item.ActionTag))
                    continue;

                PreserveRetiredMetadataIdentity(item);
                Destroy(item);
                retired++;
            }
            return retired;
        }

        public GameObject Find(string cocosPath)
        {
            CocosNodeReference node = nodes.Find(item => item.path == cocosPath);
            if (node != null && node.target != null)
            {
                return node.target;
            }

            CocosNodeMetadata metadata = Array.Find(
                GetComponentsInChildren<CocosNodeMetadata>(true),
                item => item.CocosPath == cocosPath);
            if (metadata != null)
                return metadata.gameObject;

            // Unity-authored hierarchy moves can intentionally diverge from the
            // normalized Cocos metadata while retaining the same node names.
            Transform hierarchyTarget = transform.Find(cocosPath);
            if (hierarchyTarget == null && cocosPath.StartsWith("Layer/", StringComparison.Ordinal))
                hierarchyTarget = transform.Find(cocosPath.Substring("Layer/".Length));
            return hierarchyTarget != null ? hierarchyTarget.gameObject : null;
        }

        public GameObject Find(string cocosPath, string cocosNodeType, int cocosActionTag)
        {
            CocosNodeReference node = nodes.Find(item =>
                item.path == cocosPath
                && item.nodeType == cocosNodeType
                && item.actionTag == cocosActionTag);
            if (node != null && node.target != null)
            {
                return node.target;
            }

            CocosNodeMetadata metadata = Array.Find(
                GetComponentsInChildren<CocosNodeMetadata>(true),
                item => item.CocosPath == cocosPath
                    && item.NodeType == cocosNodeType
                    && item.ActionTag == cocosActionTag);
            return metadata != null ? metadata.gameObject : null;
        }

        public GameObject FindActionTag(int cocosActionTag)
        {
            GameObject serializedTarget = FindSerializedActionTag(cocosActionTag);
            if (serializedTarget != null) return serializedTarget;
            CocosNodeMetadata metadata = Array.Find(
                GetComponentsInChildren<CocosNodeMetadata>(true),
                item => item.ActionTag == cocosActionTag);
            return metadata != null ? metadata.gameObject : null;
        }

        public GameObject FindSerializedActionTag(int cocosActionTag)
        {
            CocosNodeReference node = nodes.Find(item => item.actionTag == cocosActionTag);
            return node != null ? node.target : null;
        }
    }

}

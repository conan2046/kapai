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
        [SerializeField] private string source;
        [SerializeField] private List<CocosNodeReference> nodes = new List<CocosNodeReference>();

        public string Source => source;
        public IReadOnlyList<CocosNodeReference> Nodes => nodes;

        public void Initialize(string sourcePath, List<CocosNodeReference> nodeReferences)
        {
            source = sourcePath;
            nodes = nodeReferences;
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
            return metadata != null ? metadata.gameObject : null;
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
    }

}

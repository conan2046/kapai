using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    // Business state survives navigation; visibility gates exclude locked/hidden children.
    public sealed class RedDotStore
    {
        private sealed class Node
        {
            public bool Active;
            public bool Enabled = true;
            public readonly List<string> Children = new List<string>();
        }

        private readonly Dictionary<string, Node> nodes = new Dictionary<string, Node>();
        public event Action Changed;

        public void Define(string key, string parent = null)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentException(nameof(key));
            if (nodes.ContainsKey(key)) throw new InvalidOperationException("Duplicate red-dot node: " + key);
            if (parent != null && !nodes.ContainsKey(parent))
                throw new InvalidOperationException("Missing red-dot parent: " + parent);
            nodes.Add(key, new Node());
            if (parent != null) nodes[parent].Children.Add(key);
        }

        public bool IsVisible(string key)
        {
            if (!nodes.TryGetValue(key, out Node node) || !node.Enabled) return false;
            if (node.Active) return true;
            foreach (string child in node.Children)
                if (IsVisible(child)) return true;
            return false;
        }

        public void Set(string key, bool active)
        {
            Node node = Require(key);
            if (node.Active == active) return;
            node.Active = active;
            Changed?.Invoke();
        }

        public void SetEnabled(string key, bool enabled)
        {
            Node node = Require(key);
            if (node.Enabled == enabled) return;
            node.Enabled = enabled;
            Changed?.Invoke();
        }

        public void Clear()
        {
            foreach (Node node in nodes.Values) node.Active = false;
            Changed?.Invoke();
        }

        private Node Require(string key) => nodes.TryGetValue(key, out Node node) ? node
            : throw new InvalidOperationException("Unknown red-dot node: " + key);
    }
}

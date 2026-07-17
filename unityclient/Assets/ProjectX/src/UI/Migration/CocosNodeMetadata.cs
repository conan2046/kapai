using UnityEngine;

namespace ProjectX.UI.Migration
{
    public sealed class CocosNodeMetadata : MonoBehaviour
    {
        [SerializeField] private string cocosPath;
        [SerializeField] private string nodeType;
        [SerializeField] private new int tag;
        [SerializeField] private int actionTag;

        public string CocosPath => cocosPath;
        public string NodeType => nodeType;
        public int Tag => tag;
        public int ActionTag => actionTag;

        public void Initialize(string path, string type, int cocosTag, int cocosActionTag)
        {
            cocosPath = path;
            nodeType = type;
            tag = cocosTag;
            actionTag = cocosActionTag;
        }
    }
}

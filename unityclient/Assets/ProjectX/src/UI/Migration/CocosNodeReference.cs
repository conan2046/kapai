using System;
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
}

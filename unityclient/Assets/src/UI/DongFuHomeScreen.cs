using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class DongFuHomeScreen : MonoBehaviour
    {
        [SerializeField] private Button[] buildingEntries;
        public event Action<int> BuildingRequested;
        public event Action CloseRequested;
        public event Action BecameVisible;
        private void Awake()
        {
            if(buildingEntries==null||buildingEntries.Length!=5)throw new InvalidOperationException("洞府首页必须绑定5个建筑入口");
            for(int i=0;i<buildingEntries.Length;i++)
            {
                int index=i;
                buildingEntries[i].onClick.AddListener(()=>BuildingRequested?.Invoke(index));
            }
        }
        private void OnEnable()=>BecameVisible?.Invoke();
        public void Back()=>CloseRequested?.Invoke();
    }
}

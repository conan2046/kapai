using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GardenCropRowView : MonoBehaviour
    {
        [SerializeField] private Button plant;
        [SerializeField] private Image icon;
        [SerializeField] private Text cropName;
        [SerializeField] private Text duration;
        [SerializeField] private Text stock;
        [SerializeField] private Text price;
        private int quantity;
        private int seedPrice;
        private Action select;
        private Action purchase;
        public void Bind(GardenCropDefinition crop,Sprite sprite,Action select,Action purchase)
        {
            icon.sprite=sprite;cropName.text=crop.Name;
            duration.text="时长："+TimeSpan.FromSeconds(crop.GrowSeconds).ToString(@"hh\:mm\:ss");
            seedPrice=crop.SeedPriceGold;price.text=seedPrice>0?"单价："+seedPrice:"不可购种";
            this.select=select;this.purchase=purchase;
            plant.onClick.AddListener(()=>{if(quantity>0)this.select();else if(seedPrice>0)this.purchase();});
            SetStock(0);
        }
        public void SetStock(int count){quantity=count;stock.text="种子："+count;}
        public void SetPending(bool pending){plant.interactable=!pending&&(quantity>0||seedPrice>0);}
    }
}

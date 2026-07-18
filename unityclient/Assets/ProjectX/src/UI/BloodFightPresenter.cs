using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class BloodFightPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly BloodFightStore store;
        private readonly Text today;
        private readonly Text forecast;
        private readonly Text startStatus;

        public BloodFightPresenter(CocosUiView view, BloodFightStore store, Action close)
        {
            this.view=view??throw new ArgumentNullException(nameof(view));
            this.store=store??throw new ArgumentNullException(nameof(store));
            Transform root=view.GameObject.transform;
            Normalize(root); EnsureBackground(root);
            SetVisible(root.Find("Panel_xuezhan"),true);
            SetVisible(root.Find("Panel_xuezhan/Popup"),true);
            SetVisible(root.Find("Panel_xuezhan/today"),true);
            today=RequireText(root,"Panel_xuezhan/today/Text1");
            forecast=RequireText(root,"Panel_xuezhan/today/Text2");
            startStatus=RequireText(root,"Panel_xuezhan/start/btn_paihangbang/Text");
            DisableActions(root);
            store.Changed+=Render; Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && today!=null && startStatus!=null;
        public void Dispose()=>store.Changed-=Render;

        private void Render()
        {
            if(!store.HasAuthoritativeResponse){today.text=forecast.text=startStatus.text="--";return;}
            today.text=store.TodayMaxLevel>0
                ? $"今日最高：第{store.TodayMaxLevel}关  {store.TodayMaxStar}星"
                : "今日尚未挑战";
            forecast.text=$"当前：第{store.Chapter}章 第{store.Level}关  总星{store.TotalStar}";
            startStatus.text=$"剩余次数：{store.Remaining}  复活：{store.Revives}";
            SetText(view.GameObject.transform,"Panel_xuezhan/Popup/MyRank","当前未请求排行榜");
            SetText(view.GameObject.transform,"Panel_xuezhan/youxia/btn_paihangbang/base/Text",$"最高星：{store.HistoricalMaxStar}");
        }

        private static void EnsureBackground(Transform root)
        {
            if(root.Find("BloodFightBackgroundRuntime")!=null)return;
            Sprite sprite=Resources.Load<Sprite>("Backgrounds/bg_xuezhan");
            if(sprite==null){Texture2D texture=Resources.Load<Texture2D>("Backgrounds/bg_xuezhan");if(texture==null)return;sprite=Sprite.Create(texture,new Rect(0,0,texture.width,texture.height),new Vector2(.5f,.5f),100f);}
            GameObject go=new GameObject("BloodFightBackgroundRuntime",typeof(RectTransform),typeof(CanvasRenderer),typeof(Image));
            RectTransform rect=(RectTransform)go.transform;rect.SetParent(root,false);rect.anchorMin=Vector2.zero;rect.anchorMax=Vector2.one;rect.offsetMin=rect.offsetMax=Vector2.zero;rect.SetAsFirstSibling();
            Image image=go.GetComponent<Image>();image.sprite=sprite;image.raycastTarget=false;
        }

        private static void DisableActions(Transform root)
        {
            string[] paths={"Panel_xuezhan/start/btn_paihangbang","Panel_xuezhan/youxia/btn_paihangbang","Panel_xuezhan/youxia/btn_shangdian","Panel_xuezhan/Popup/btn_Upgrade"};
            foreach(string path in paths){Button button=root.Find(path)?.GetComponent<Button>();if(button==null)continue;button.onClick.RemoveAllListeners();button.interactable=false;}
        }
        private static Text RequireText(Transform root,string path)=>root.Find(path)?.GetComponent<Text>()??throw new InvalidOperationException($"BloodFight imported text was not found: {path}");
        private static void SetText(Transform root,string path,string value){Text text=root.Find(path)?.GetComponent<Text>();if(text!=null)text.text=value;}
        private static void SetVisible(Transform target,bool visible){if(target!=null)target.gameObject.SetActive(visible);}
        private static void Normalize(Transform root){if(!(root is RectTransform rect))return;rect.anchorMin=Vector2.zero;rect.anchorMax=Vector2.one;rect.pivot=new Vector2(.5f,.5f);rect.offsetMin=rect.offsetMax=Vector2.zero;rect.anchoredPosition=Vector2.zero;rect.localScale=Vector3.one;rect.localRotation=Quaternion.identity;}
    }
}

using System;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    // A child of the hero detail view: closing the parent cannot leave an
    // invisible modal in the global raycast stack. State comes only from /24.
    public sealed class HeroBuildPresenter : IDisposable
    {
        private readonly GameObject root;
        private readonly Text title, body, status;
        private readonly Action<int, int, int> send;
        private readonly Button[] branches = new Button[3];
        private readonly Button[] strategies = new Button[6];
        private int heroId, selectedBranch, selectedStrategy;
        private bool ready;
        private HeroBuildDetail detail;
        private readonly Font font;
        private readonly Dictionary<int,int> skillLevels = new Dictionary<int,int>();
        public HeroBuildPresenter(Transform parent, Font font, Action<int,int,int> send)
        {
            this.font = font; this.send = send;
            root = new GameObject("HeroBuildPanel", typeof(RectTransform), typeof(Image));
            root.transform.SetParent(parent, false);
            var rect = (RectTransform)root.transform;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            root.GetComponent<Image>().color = new Color(.10f,.06f,.04f,.98f);
            title = Label("Title", new Vector2(0,270), new Vector2(720,40), 24);
            ButtonAt("Close", "关闭", new Vector2(430,270), new Vector2(85,38), Close);
            string[] branchLabels = {"基础", "流派 A", "流派 B"};
            for (int i=0;i<3;i++)
            {
                int captured=i;
                branches[i]=ButtonAt("Branch"+i, branchLabels[i], new Vector2(-300+i*180,220), new Vector2(160,38), () => Apply(captured, selectedStrategy));
            }
            string[] strategyLabels = {"默认", "救场", "守护", "控制", "爆发", "持续"};
            for (int i=0;i<6;i++)
            {
                int captured=i;
                strategies[i]=ButtonAt("Strategy"+i,strategyLabels[i],new Vector2(-375+i*150,170),new Vector2(138,36),()=>Apply(selectedBranch,captured));
            }
            var viewport=new GameObject("Descriptions",typeof(RectTransform),typeof(Image),typeof(Mask),typeof(ScrollRect));
            viewport.transform.SetParent(root.transform,false);
            var viewRect=(RectTransform)viewport.transform;
            viewRect.sizeDelta=new Vector2(910,365); viewRect.anchoredPosition=new Vector2(0,-45);
            viewport.GetComponent<Image>().color=new Color(.92f,.85f,.70f);
            viewport.GetComponent<Mask>().showMaskGraphic=true;
            var textObject=new GameObject("Content",typeof(RectTransform),typeof(Text),typeof(ContentSizeFitter));
            textObject.transform.SetParent(viewport.transform,false);
            var content=(RectTransform)textObject.transform;
            content.anchorMin=new Vector2(0,1);content.anchorMax=Vector2.one;content.pivot=new Vector2(.5f,1);
            content.sizeDelta=new Vector2(-32,0);content.anchoredPosition=new Vector2(0,-12);
            body=textObject.GetComponent<Text>();body.font=font;body.fontSize=18;
            body.color=new Color(.22f,.12f,.07f);body.supportRichText=true;
            body.alignment=TextAnchor.UpperLeft;body.horizontalOverflow=HorizontalWrapMode.Wrap;
            body.verticalOverflow=VerticalWrapMode.Overflow;body.raycastTarget=false;
            textObject.GetComponent<ContentSizeFitter>().verticalFit=ContentSizeFitter.FitMode.PreferredSize;
            var scroll=viewport.GetComponent<ScrollRect>();scroll.viewport=viewRect;scroll.content=content;
            scroll.horizontal=false;scroll.vertical=true;scroll.movementType=ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity=28;
            status=Label("Status",new Vector2(0,-270),new Vector2(900,55),17);
            root.SetActive(false);
        }
        public void Open(int id)
        {
            heroId=id;detail=HeroBuildDetailCatalog.Find(id);ready=false;
            selectedBranch=selectedStrategy=0;
            skillLevels.Clear();
            root.SetActive(true);root.transform.SetAsLastSibling();
            title.text=(detail?.name ?? "神将")+" · 技能与流派";
            status.text="正在读取服务端设置…";Render();send(id,-1,0);
        }
        public bool IsShowing(int id) => id==heroId && root.activeInHierarchy;
        public void Receive(int id,int branch,int strategy,string error,string levels="")
        {
            if(id!=heroId || !root.activeSelf)return;
            ready=string.IsNullOrEmpty(error);
            if(ready)
            {
                selectedBranch=branch;selectedStrategy=strategy;
                foreach(string entry in (levels ?? "").Split(';'))
                {
                    string[] fields=entry.Split(':');
                    if(fields.Length==2 && int.TryParse(fields[0],out int skill) && int.TryParse(fields[1],out int level) && level>0)
                        skillLevels[skill]=level;
                }
            }
            status.text=ready ? "当前："+new[]{"基础","A","B"}[branch]+"；策略："+new[]{"默认","救场","守护","控制","爆发","持续"}[strategy] : error;
            Render();
        }
        public void Reset(){ready=false;heroId=0;Close();}
        public void Close(){root.SetActive(false);}
        private void Apply(int branch,int strategy)
        {
            if(!ready)return;
            ready=false;status.text="正在保存…";Render();send(heroId,branch,strategy);
        }
        private void Render()
        {
            // Server acknowledgements own selection; pending requests cannot overlap.
            for(int i=0;i<branches.Length;i++)branches[i].interactable=ready && detail!=null;
            foreach(var b in strategies)b.interactable=ready;
            if(detail==null){body.text="缺少该神将的技能配置。";return;}
            var text=new StringBuilder(skillLevels.Count>0 ? "<b>基础技能 · 当前等级数值</b>\n\n" : "<b>基础技能 · 1级参考数值</b>\n正在读取实际技能等级。\n\n");
            foreach(var skill in detail.skills)
            {
                text.Append("<b>").Append(skill.name).Append(" · ").Append(skill.role).Append("</b>");
                if(skill.cd>0)text.Append("　CD ").Append(skill.cd);
                if(skill.cost>0)text.Append("　战意 ").Append(skill.cost);
                int level=skillLevels.TryGetValue(skill.id,out int currentLevel)?currentLevel:1;
                text.Append("　Lv.").Append(level);
                string template=Regex.Replace(skill.description ?? "",@"\[/?c\d*\]",string.Empty);
                text.Append('\n').Append(HeroCatalog.ResolveSkillDescription(template,level)).Append("\n\n");
            }
            text.Append("<b>流派 A · ").Append(detail.build_a).Append("</b>\n").Append(detail.description_a);
            text.Append("\n\n<b>流派 B · ").Append(detail.build_b).Append("</b>\n").Append(detail.description_b);
            text.Append("\n\n<b>流派 A 配装与品质数值</b>\n").Append(HeroBuildGearCatalog.Describe(detail.artifact_a, detail.set_a));
            text.Append("\n\n<b>流派 B 配装与品质数值</b>\n").Append(HeroBuildGearCatalog.Describe(detail.artifact_b, detail.set_b));
            text.Append("\n\n策略保留战意：救场40、守护/控制30、爆发/持续20。\n救场优先复活和急救；守护优先保护低血目标；控制先降抗再控制；爆发优先斩杀或易伤目标；持续优先铺设自身持续伤害，再引爆。救场复活和35%以下急救可越过保留线。\n切换后从下一场战斗生效。");
            body.text=text.ToString();
        }
        private Text Label(string name,Vector2 pos,Vector2 size,int fontSize)
        {
            var obj=new GameObject(name,typeof(RectTransform),typeof(Text));obj.transform.SetParent(root.transform,false);
            var rt=(RectTransform)obj.transform;rt.anchoredPosition=pos;rt.sizeDelta=size;
            var text=obj.GetComponent<Text>();text.font=font;text.fontSize=fontSize;text.color=new Color(1,.9f,.7f);
            text.alignment=TextAnchor.MiddleCenter;text.raycastTarget=false;return text;
        }
        private Button ButtonAt(string name,string label,Vector2 pos,Vector2 size,Action action)
        {
            var obj=new GameObject(name,typeof(RectTransform),typeof(Image),typeof(Button));obj.transform.SetParent(root.transform,false);
            var rt=(RectTransform)obj.transform;rt.anchoredPosition=pos;rt.sizeDelta=size;
            obj.GetComponent<Image>().color=new Color(.55f,.28f,.10f);
            var button=obj.GetComponent<Button>();button.targetGraphic=obj.GetComponent<Image>();button.onClick.AddListener(()=>action());
            var t=Label(name+"Label",Vector2.zero,size,18);t.transform.SetParent(obj.transform,false);return button;
        }
        public void Dispose(){UnityEngine.Object.Destroy(root);}
    }
}

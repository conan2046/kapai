using System;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;
namespace ProjectX.UI
{
    // Layout, typography, sprites and scrolling dimensions belong to the prefab.
    public sealed class SpiritScreen : MonoBehaviour
    {
        [SerializeField] private Text[] bonusValues;
        [SerializeField] private Text[] rootNames;
        [SerializeField] private Text upgradeLabel;
        [SerializeField] private Button upgrade;
        [SerializeField] private GameObject confirmation;
        [SerializeField] private Text confirmText;
        [SerializeField] private Button confirm;
        [SerializeField] private Button cancel;
        [SerializeField] private Image productionProgress;
        [SerializeField] private Text productionProgressLabel;
        [SerializeField] private Text productionProgressValue;
        [SerializeField] private Text[] positionTitles;
        [SerializeField] private Text[] positionEmptyLabels;
        [SerializeField] private Text[] positionAttributeNames;
        [SerializeField] private Text[] positionAttributeValues;
        [SerializeField] private GameObject attributesPanel;
        [SerializeField] private Button details;
        [SerializeField] private Button detailsClose;
        [SerializeField] private Button[] rootButtons;
        [SerializeField] private GameObject rootPanel;
        [SerializeField] private Text rootTitle;
        [SerializeField] private Text rootText;
        [SerializeField] private Button rootConfirm;
        [SerializeField] private Text rootConfirmLabel;
        [SerializeField] private Button rootClose;
        private SpiritEnvelope state;
        private Action<int,int,string> request;
        private Func<int,string> itemName;
        private bool pending;
        private int selectedRoot=1;
        private float productionReceivedAt;
        private string reportedError;
        public event Action BecameVisible;
        public event Action CloseRequested;
        public event Action<string> ErrorReported;
        private static readonly string[] RootNames={"","金灵根","木灵根","水灵根","火灵根","土灵根"};
        private static readonly string[] Names={"","攻击","物防","法防","生命","速度","命中","闪避","暴击","抗暴","攻击加成","物防加成","法防加成","生命加成","速度加成","命中率","闪避率","暴击率","抗暴率","增伤率","物免率","法免率","暴击伤害","反击率","抗反率","反击伤害","连击率","抗连率","连击伤害","反震率","抗震率","反震伤害","负面强化","负面抵抗"};
        private void OnEnable()=>BecameVisible?.Invoke();
        private void Update()
        {
            if(productionProgress==null)return;
            bool full=state!=null&&long.TryParse(state.Spirit,out long owned)&&long.TryParse(state.Storage,out long capacity)&&capacity>0&&owned>=capacity;
            bool producing=state!=null&&state.Configured&&state.Unlocked&&!full&&string.IsNullOrEmpty(state.Error)&&state.ProductionPeriodMs>0;
            float period=state?.ProductionPeriodMs>0?state.ProductionPeriodMs/1000f:5f;
            float elapsed=producing?Mathf.Min(period,state.ProductionElapsedMs/1000f+Time.realtimeSinceStartup-productionReceivedAt):0f;
            productionProgress.fillAmount=full?1f:elapsed/period;
            if(productionProgressLabel!=null)productionProgressLabel.text=state==null?"聚灵阵 正在同步…":"聚灵阵 "+(state.Configured?state.Level+"级":"待配置")+"  灵气 "+state.Spirit+" / "+state.Storage;
            if(productionProgressValue!=null)productionProgressValue.text=producing?elapsed.ToString("0.0")+" / "+period.ToString("0")+"秒":full?"已满":"0 / 5秒";
        }
        private void OnDisable(){confirmation?.SetActive(false);attributesPanel?.SetActive(false);rootPanel?.SetActive(false);pending=false;}
        public void Bind(Action<int,int,string> send,Func<int,string> names)
        {
            request=send;itemName=names;
            upgrade.onClick.AddListener(()=>{if(pending||state==null||!state.Configured||!state.Unlocked||state.NextId==0)return;confirmText.text="升级聚灵阵至 "+(state.Level+1)+"级\n"+Materials(state.Costs)+"\n提升灵根等级上限、灵气存储与每5秒产量";confirmation.SetActive(true);});
            confirm.onClick.AddListener(()=>{if(pending||state==null)return;confirmation.SetActive(false);SetPending();request(1,0,state.Revision);});
            cancel.onClick.AddListener(()=>confirmation.SetActive(false));
            details.onClick.AddListener(()=>{RenderPosition();attributesPanel.SetActive(true);});
            detailsClose.onClick.AddListener(()=>attributesPanel.SetActive(false));
            for(int i=0;i<rootButtons.Length;i++){int type=i+1;rootButtons[i].onClick.AddListener(()=>{selectedRoot=type;RenderRoot();rootPanel.SetActive(true);});}
            rootClose.onClick.AddListener(()=>rootPanel.SetActive(false));
            foreach(var common in GetComponentsInChildren<GameErrorViewBindings>(true))
                common.CloseButton.onClick.AddListener(()=>common.gameObject.SetActive(false));
            rootConfirm.onClick.AddListener(()=>{if(pending||state==null||!CanUpgradeRoot(SelectedRoot()))return;rootPanel.SetActive(false);SetPending();request(2,selectedRoot,state.Revision);});
        }
        public void Back(){if(confirmation.activeSelf){confirmation.SetActive(false);return;}if(rootPanel.activeSelf){rootPanel.SetActive(false);return;}if(attributesPanel.activeSelf){attributesPanel.SetActive(false);return;}CloseRequested?.Invoke();}
        public void SetPending(){pending=true;upgrade.interactable=false;confirm.interactable=false;rootConfirm.interactable=false;}
        public void Fail(string message){pending=false;confirmation.SetActive(false);upgrade.interactable=false;confirm.interactable=false;rootConfirm.interactable=false;ReportError(message);}
        private void ReportError(string message){if(string.IsNullOrEmpty(message)){reportedError=null;return;}if(reportedError==message)return;reportedError=message;ErrorReported?.Invoke(message);}
        private static string Attribute(int[] pair)=>pair==null||pair.Length!=2?"—":(pair[0]>0&&pair[0]<Names.Length?Names[pair[0]]:"属性"+pair[0])+" +"+(pair[0]>9?(pair[1]/100m).ToString("0.##")+"%":pair[1].ToString());
        private string Materials(long[][] value)=>value==null||value.Length==0?"无额外材料":string.Join("  ",value.Select(p=>itemName((int)p[0])+" "+p[2]+"/"+p[1]));
        private static bool Enough(long[][] value)=>(value??Array.Empty<long[]>()).All(p=>p.Length==3&&p[2]>=p[1]);
        private SpiritRootState SelectedRoot()=>state?.Roots?.FirstOrDefault(r=>r.Type==selectedRoot);
        private bool CanUpgradeRoot(SpiritRootState root)=>!pending&&state!=null&&state.Unlocked&&root!=null&&root.Configured&&root.NextId!=0&&!root.Capped&&Enough(root.Costs)&&long.TryParse(state.Spirit,out long owned)&&long.TryParse(root.SpiritCost,out long need)&&owned>=need&&string.IsNullOrEmpty(state.Error);
        private void RenderPosition()
        {
            for(int slot=1;slot<=5;slot++){
                positionTitles[slot-1].text=slot+"号位";
                var attrs=state?.Positions?.FirstOrDefault(p=>p.Position==slot)?.Attributes??Array.Empty<int[]>();
                bool hasBonus=attrs.Any(a=>a!=null&&a.Length==2&&a[1]>0);
                positionEmptyLabels[slot-1].gameObject.SetActive(!hasBonus);
                positionAttributeNames[(slot-1)*33].transform.parent.gameObject.SetActive(hasBonus);
                for(int type=1;type<=33;type++){
                    int index=(slot-1)*33+type-1;
                    var pair=attrs.FirstOrDefault(a=>a!=null&&a.Length==2&&a[0]==type);
                    positionAttributeNames[index].gameObject.SetActive(pair!=null&&pair[1]>0);
                    positionAttributeNames[index].text=Names[type]+"：";
                    int value=pair==null?0:pair[1];
                    positionAttributeValues[index].text=type>9?(value/100m).ToString("0.##")+"%":value.ToString();
                }
            }
        }
        private void RenderRoot()
        {
            var root=SelectedRoot();rootTitle.text=RootNames[selectedRoot]+"升级";
            rootConfirm.interactable=CanUpgradeRoot(root);
            if(root==null||!root.Configured){rootText.text="该灵根正式配置尚未启用";rootConfirmLabel.text="待配置";return;}
            string attrs=string.Join("，",(root.Attributes??Array.Empty<int[]>()).Take(3).Select(Attribute));
            string slots=string.Join("、",root.TargetPositions??Array.Empty<int>());
            string status=root.NextId==0?"该灵根已满级":root.Capped?"请先升级聚灵阵，提高灵根等级上限":!Enough(root.Costs)?"升级材料不足":CanUpgradeRoot(root)?"点击升级，获得下一级配置效果":"灵气不足或正在同步";
            rootText.text="当前 "+root.Level+"级 / 上限 "+state.RootLevelCap+"级\n当前成长缩时 "+(root.Growth/100m).ToString("0.##")+"%  收获加成 "+(root.Yield/100m).ToString("0.##")+"%\n本级新增："+(attrs.Length==0?"无战斗属性":attrs)+"\n本级站位："+(slots.Length==0?"无":slots+"号位")+"\n灵气 "+state.Spirit+" / 消耗 "+root.SpiritCost+"\n"+Materials(root.Costs)+"\n"+status;
            rootConfirmLabel.text=root.NextId==0?"已满级":root.Capped?"需升聚灵阵":"升级灵根";
        }
        public void Apply(SpiritEnvelope value)
        {
            if(value==null||value.Schema!=2)throw new InvalidOperationException("聚灵阵回包格式错误");
            if(state!=null&&long.TryParse(state.Revision,out long oldVersion)&&long.TryParse(value.Revision,out long version)&&version<oldVersion)return;
            if(state!=null&&(state.RecordId!=value.RecordId||state.Revision!=value.Revision))confirmation.SetActive(false);
            pending=false;state=value;productionReceivedAt=Time.realtimeSinceStartup;confirm.interactable=true;
            for(int i=0;i<bonusValues.Length;i++){
                var root=value.Roots?.FirstOrDefault(r=>r.Type==i+1);
                string effect=root==null?"":root.Growth>0?"成长 -"+(root.Growth/100m).ToString("0.##")+"%":root.Yield>0?"收获 +"+(root.Yield/100m).ToString("0.##")+"%":root.Attributes?.Length>0?Attribute(root.Attributes[0]):"暂无加成";
                bonusValues[i].text=RootNames[i+1]+" "+(root?.Configured==true?root.Level+"级":"待配置")+"\n"+effect;
                if(rootNames!=null&&i<rootNames.Length)rootNames[i].text=root?.Configured==true?root.Name:"待配置";
                rootButtons[i].interactable=value.Configured&&value.Unlocked;
            }
            upgrade.interactable=value.Configured&&value.Unlocked&&value.NextId!=0&&Enough(value.Costs)&&string.IsNullOrEmpty(value.Error);
            upgradeLabel.text=!value.Configured?"待配置":value.NextId==0?"聚灵阵已满级":"升级聚灵阵";
            ReportError(value.Error);
            RenderPosition();RenderRoot();
        }
        public void ResetSession(){state=null;reportedError=null;confirmation.SetActive(false);attributesPanel.SetActive(false);rootPanel.SetActive(false);SetPending();}
    }
}

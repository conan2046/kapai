using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json.Linq;
using ProjectX.Data;
using ProjectX.Foundation;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        JObject storyState;
        Dictionary<int,JObject> storySteps;
        JObject[] storyLines;
        UnityUiView storyDialog,storyGuide;
        uint storyRole; int storySession,storyShownStep,storyLineIndex;
        float storyNextRead,storyPendingUntil,storyLineStarted;
        bool storyPending,storyFinishing,storyWasWorld,storySuppressOfflineNotice;
        string storyUiSurface;
        string storyText;
        public int CurrentStoryStep => storyState?.Value<int>("step") ?? -1;
        public bool IsStoryDialogueOpen => storyDialog?.GameObject.activeInHierarchy==true;
        void ResetStory()
        {
            storyPlacementErrors.Clear();
            storyAppliedLayouts.Clear();
            storySuppressOfflineNotice=false;
            storyState=null;storyRole=0;storyPending=false;storyShownStep=0;storyFinishing=false;storyUiSurface=null;storyWasWorld=false;
            storyDialog?.SetVisible(false);storyGuide?.SetVisible(false);
        }
        void TickStory()
        {
            if(services==null)return;
            if(!services.Player.IsLoaded||!services.Network.IsConnected){if(storyRole!=0)ResetStory();return;}
            if(storyRole!=services.Player.RoleId||storySession!=services.Network.SessionVersion)
            {ResetStory();storyRole=services.Player.RoleId;storySession=services.Network.SessionVersion;storyNextRead=Time.realtimeSinceStartup+0.5f;}
            if(storyState!=null){ReportStoryUiSurface();if(!storyState.Value<bool>("enabled")||CurrentStoryStep==0)return;}
            if(storyPending&&Time.realtimeSinceStartup>=storyPendingUntil){storyPending=false;storyFinishing=false;storyNextRead=Time.realtimeSinceStartup+1f;}
            if(!storyPending&&Time.realtimeSinceStartup>=storyNextRead)RequestStory(0);
            if(storyState==null||!storyState.Value<bool>("enabled")||CurrentStoryStep==0)return;
            if(storySteps==null)LoadStoryCatalog();
            if(!storySteps.TryGetValue(CurrentStoryStep,out JObject step))return;
            bool started=storyState.Value<bool>("started");
            int expected=step.Value<int>(started?"complete_event_id":"trigger_event_id");
            GlobalEventDefinition e=services.GlobalEvents.Get(expected);
            bool atMain=mainView?.GameObject.activeInHierarchy==true&&services.UiStack.Current==mainView;
            if(!storyPending&&((e.Type==1002&&atMain)||(e.Type==1003&&e.Parameter1==22&&IsJingJieOpen)))
            {RequestStory(1,expected);return;}
            if(!started){ShowStoryGuide(step);return;}
            if(step.Value<int>("dialogid")>0)
            {
                if(worldBattleInFlight||worldBattlePlaybackCoroutine!=null||worldBattleRuntime.PendingResult)return;
                if(storyShownStep!=CurrentStoryStep||storyDialog==null||!storyDialog.IsAlive)BeginStoryDialogue(step);
                if(storyLines==null||storyLineIndex<0||storyLineIndex>=storyLines.Length)return;
                PlaceStoryView(storyDialog,storyLines[storyLineIndex],false);
                TickStoryText();return;
            }
            storyDialog?.SetVisible(false);ShowStoryGuide(step);
        }
        void ReportStoryUiSurface()
        {
            bool main=mainView?.GameObject.activeInHierarchy==true&&services.UiStack.Current==mainView;
            bool world=worldView?.GameObject.activeInHierarchy==true||worldMapView?.GameObject.activeInHierarchy==true||worldDetailView?.GameObject.activeInHierarchy==true;
            if(world)storyWasWorld=true;
            string surface=main?"main":IsJingJieOpen?"realm":IsHeroOpen?"hero":"";
            if(surface==storyUiSurface)return;
            storyUiSurface=surface;if(surface.Length==0)return;
            int type=surface=="main"?1002:1003,parameter=surface=="realm"?22:surface=="hero"?1030:storyWasWorld?2:0;
            if(main&&storyState.Value<bool>("enabled")&&CurrentStoryStep>0)
            {
                if(storySteps==null)LoadStoryCatalog();
                var step=storySteps[CurrentStoryStep];var e=services.GlobalEvents.Get(step.Value<int>(storyState.Value<bool>("started")?"complete_event_id":"trigger_event_id"));
                if(e.Type==1002&&step.Value<int>("pre_id")==0)parameter=1;
            }
            if(main)storyWasWorld=false;
            var packet=LegacyTcpMessage.New();packet.WriteWord(328);packet.WriteByte(2);packet.WriteString(new JObject{["type"]=type,["parameter"]=parameter}.ToString(Newtonsoft.Json.Formatting.None));
            services.Network.Send(packet);
        }
        void LoadStoryCatalog()
        {
            var a=ResourceLoader.Load<TextAsset>("ProjectXData/Configs/story_event");
            storySteps=JArray.Parse(a.text).Cast<JObject>().ToDictionary(x=>x.Value<int>("id"));
        }
        void RequestStory(int op,int eventId=0)
        {
            if(storyPending||!services.Network.IsConnected)return;
            var payload=new JObject{["step"]=CurrentStoryStep,["revision"]=storyState?.Value<int>("revision")??0,["event_id"]=eventId};
            var packet=LegacyTcpMessage.New();packet.WriteWord(328);packet.WriteByte((byte)op);packet.WriteString(payload.ToString(Newtonsoft.Json.Formatting.None));
            storyPending=true;storyPendingUntil=Time.realtimeSinceStartup+8;storyNextRead=Time.realtimeSinceStartup+1;
            try{services.Network.Send(packet);}catch{storyPending=false;throw;}
        }
        void ApplyStoryPacket(LegacyTcpMessage packet)
        {
            if(packet.ReadByte()!=128)throw new InvalidOperationException("剧情回包版本错误");
            var next=JObject.Parse(packet.ReadString());
            if(storyRole!=services.Player.RoleId||storySession!=services.Network.SessionVersion)return;
            storyPending=false;storyNextRead=Time.realtimeSinceStartup+1f;
            int old=CurrentStoryStep;storyState=next;
            string error=next.Value<string>("error");
            if(!string.IsNullOrEmpty(error)){storyFinishing=false;ShowToast(error,4);storyNextRead=Time.realtimeSinceStartup+3;}
            if(CurrentStoryStep!=old)
            {
                storyFinishing=false;storyDialog?.SetVisible(false);storyShownStep=0;
                // Refresh authoritative hero/formation data without navigating away.
                InvokeLuaOrFail(onHeroRedDotRefresh,"Story.HeroSnapshot");
            }
            if(!next.Value<bool>("enabled")||CurrentStoryStep==0){storyGuide?.SetVisible(false);storyDialog?.SetVisible(false);}
        }
        UnityUiView StoryView(ref UnityUiView view,string key)
        {
            if(view==null||!view.IsAlive)
            {
                var prefab=ResourceLoader.Load<GameObject>(key);
                if(prefab==null)throw new InvalidOperationException("剧情预制体缺失："+key);
                view=new UnityUiView(Instantiate(prefab,GetDynamicUiRoot(),false));
                view.GameObject.name=prefab.name;
            }
            return view;
        }
        // Wait for this login's story snapshot, then suppress this session's notice if dialogue takes priority.
        bool TryResolveOfflineStoryPriority(out bool suppress)
        {
            suppress=storySuppressOfflineNotice||IsStoryDialogueOpen;
            if(suppress)return true;
            return services!=null&&storyRole==services.Player.RoleId
                &&storySession==services.Network.SessionVersion&&storyState!=null&&!storyPending;
        }
        void BeginStoryDialogue(JObject step)
        {
            storySuppressOfflineNotice=true;
            StoryView(ref storyDialog,"UI/StoryDialog");
            storyGuide?.SetVisible(false);
            var rows=JArray.Parse(ResourceLoader.Load<TextAsset>("ProjectXData/Configs/story_dialog").text);
            storyLines=rows.Cast<JObject>().Where(r=>r.Value<int>("dialogid")==step.Value<int>("dialogid")).OrderBy(r=>r.Value<int>("order")).ToArray();
            if(storyLines.Length==0)throw new InvalidOperationException("剧情对白为空");
            storyShownStep=CurrentStoryStep;storyLineIndex=0;storyFinishing=false;
            storyDialog.FindNode("DialogUI").GetComponent<Button>().onClick.RemoveAllListeners();
            storyDialog.FindNode("DialogUI").GetComponent<Button>().onClick.AddListener(NextStoryLine);
            var skip=storyDialog.FindNode("DialogUI/Image_1/btn_Skip").GetComponent<Button>();
            skip.onClick.RemoveAllListeners();skip.onClick.AddListener(FinishStoryDialogue);
            ShowStoryLine();
        }
        void ShowStoryLine()
        {
            var line=storyLines[storyLineIndex];storyText=line.Value<string>("dialog");storyLineStarted=Time.realtimeSinceStartup;
            var name=storyDialog.FindNode("DialogUI/bg_Name/Name").GetComponent<Text>();
            var portrait=storyDialog.FindNode("DialogUI/NPC").GetComponent<Image>();
            bool hero=line.Value<int>("actor_type")==3;
            HeroDefinition actor=default;
            if(hero&&!HeroCatalog.TryGet(line.Value<int>("actor_id"),out actor))throw new InvalidOperationException("剧情神将配置缺失");
            name.text=hero?actor.Name:services.Player.Name;
            portrait.gameObject.SetActive(hero);
            if(hero)portrait.sprite=services.Resources.LoadHeroBodyPortrait(actor.Picture);
            storyDialog.FindNode("DialogUI/Image_1/btn_Skip").SetActive(line.Value<int>("showskip")==1);
            storyDialog.FindNode("DialogUI/Content").GetComponent<Text>().text="";
            PlaceStoryView(storyDialog,line,false);
        }
        void TickStoryText()
        {
            if(storyFinishing||storyLines==null)return;
            int speed=storyLines[storyLineIndex].Value<int>("speed");
            int count=Math.Min(storyText.Length,(int)((Time.realtimeSinceStartup-storyLineStarted)*speed));
            storyDialog.FindNode("DialogUI/Content").GetComponent<Text>().text=storyText.Substring(0,count);
        }
        void NextStoryLine()
        {
            if(storyFinishing||storyPending)return;
            var line=storyLines[storyLineIndex];
            float elapsed=Time.realtimeSinceStartup-storyLineStarted;
            if(elapsed<storyText.Length/(float)line.Value<int>("speed"))
            {storyLineStarted=Time.realtimeSinceStartup-storyText.Length/(float)line.Value<int>("speed");TickStoryText();return;}
            if(elapsed<storyText.Length/(float)line.Value<int>("speed")+line.Value<int>("delay")/1000f)return;
            if(storyLineIndex+1<storyLines.Length){storyLineIndex++;ShowStoryLine();}
            else FinishStoryDialogue();
        }
        void FinishStoryDialogue()
        {
            if(storyFinishing||storyPending)return;
            storyFinishing=true;RequestStory(1,storySteps[CurrentStoryStep].Value<int>("complete_event_id"));
            storyDialog.FindNode("DialogUI/Content").GetComponent<Text>().text="正在继续……";
        }
        readonly HashSet<string> storyPlacementErrors=new HashSet<string>();
        readonly Dictionary<UnityUiView,string> storyAppliedLayouts=new Dictionary<UnityUiView,string>();
        bool PlaceStoryView(UnityUiView view,JObject row,bool guide)
            =>PlaceStoryView(view,row,guide,out _);
        bool PlaceStoryView(UnityUiView view,JObject row,bool guide,out bool configurationChanged)
        {
            configurationChanged=false;
            string parentPath=row.Value<string>("parent_node");
            string scope=guide?"story_event "+row.Value<int>("id"):"story_dialog "+row.Value<int>("dialogid")+":"+row.Value<int>("order");
            if(string.IsNullOrWhiteSpace(parentPath))return FailStoryPlacement(view,scope,"parent_node is empty");
            Transform parent=GetDynamicUiRoot();
            if(parentPath!="Canvas")
            {
                string[] parts=parentPath.Split('/');
                var existing=services.UiAssets.FindExisting(parts[0]);
                if(existing!=null)parent=existing.transform;
                else
                {
                    var active=Resources.FindObjectsOfTypeAll<UiPrefabKey>()
                        .Where(x=>x.Key==parts[0]&&x.gameObject.scene==parent.gameObject.scene&&x.gameObject.activeInHierarchy).ToArray();
                    if(active.Length==0){view.SetVisible(false);return false;}
                    if(active.Length!=1)return FailStoryPlacement(view,scope,"multiple visible UI instances: "+parts[0]);
                    parent=active[0].transform;
                }
                if(!parent.gameObject.activeInHierarchy){view.SetVisible(false);return false;}
                for(int i=1;i<parts.Length;i++)
                {
                    parent=parent.Find(parts[i]);
                    if(parent==null)return FailStoryPlacement(view,scope,"node not found: "+parentPath);
                }
                if(!parent.gameObject.activeInHierarchy){view.SetVisible(false);return false;}
            }
            var root=view.GameObject.transform as RectTransform;
            var target=parent as RectTransform;
            if(root==null||target==null||parent==root||parent.IsChildOf(root))
                return FailStoryPlacement(view,scope,"invalid UI parent: "+parentPath);
            float x=row.Value<float>("offset_x"),y=row.Value<float>("offset_y");
            if(float.IsNaN(x)||float.IsInfinity(x)||float.IsNaN(y)||float.IsInfinity(y))
                return FailStoryPlacement(view,scope,"offset must be finite");
            string layoutKey=CurrentStoryStep+"|"+scope+"@"+parent.GetInstanceID();
            if(!storyAppliedLayouts.TryGetValue(view,out string applied)||applied!=layoutKey||root.parent!=parent)
            {
                if(root.parent!=parent)root.SetParent(parent,false);
                if(guide)
                {
                    // story_event coordinates belong to the StoryGuide root, using its authored anchors/pivot.
                    root.anchoredPosition=new Vector2(x,y);
                }
                else
                {
                    var box=view.FindNode("DialogUI").GetComponent<RectTransform>();
                    Vector3 center=root.InverseTransformPoint(box.TransformPoint(box.rect.center));
                    Vector3 displacement=root.localRotation*Vector3.Scale(center,root.localScale);
                    root.anchorMin=root.anchorMax=new Vector2(.5f,.5f);
                    root.anchoredPosition=new Vector2(x-displacement.x,y-displacement.y);
                }
                storyAppliedLayouts[view]=layoutKey;
                configurationChanged=true;
            }
            view.ShowPopup();
            return true;
        }
        bool FailStoryPlacement(UnityUiView view,string scope,string message)
        {
            view.SetVisible(false);
            string error=scope+": "+message;
            if(storyPlacementErrors.Add(error))Debug.LogError("[Story placement] "+error);
            return false;
        }
        void ShowStoryGuide(JObject step)
        {
            if(IsErrorVisible){storyGuide?.SetVisible(false);return;}
            if(worldBattleInFlight||worldBattlePlaybackCoroutine!=null||worldBattleRuntime.PendingResult){storyGuide?.SetVisible(false);return;}
            StoryView(ref storyGuide,"UI/StoryGuide");
            var effect=storyGuide.FindNode("SelectImage");
            var bg=storyGuide.FindNode("GuideBg");
            var leftImage=storyGuide.FindNode("GuideBg/Image_1");
            var leftText=storyGuide.FindNode("GuideBg/Text_1");
            var rightImage=storyGuide.FindNode("GuideBg/Image_2");
            var rightText=storyGuide.FindNode("GuideBg/Text_2");
            string scope="story_event "+step.Value<int>("id");
            if(effect==null||bg==null||leftImage==null||leftText==null||rightImage==null||rightText==null)
            {FailStoryPlacement(storyGuide,scope,"StoryGuide requires SelectImage and GuideBg with both image/text pairs");return;}
            int visible=step.Value<int>("select_visible"),side=step.Value<int>("hint_side");
            if((visible!=0&&visible!=1)||(side!=1&&side!=2))
            {FailStoryPlacement(storyGuide,scope,"select_visible must be 0/1 and hint_side must be 1/2");return;}
            var effectPosition=new Vector2(step.Value<float>("select_offset_x"),step.Value<float>("select_offset_y"));
            var hintPosition=new Vector2(step.Value<float>("hint_offset_x"),step.Value<float>("hint_offset_y"));
            if(!IsFiniteStoryPoint(effectPosition)||!IsFiniteStoryPoint(hintPosition))
            {FailStoryPlacement(storyGuide,scope,"child offsets must be finite");return;}
            // A running step keeps Inspector adjustments; a new step/view/parent reapplies the table.
            if(!PlaceStoryView(storyGuide,step,true,out bool configurationChanged)||!configurationChanged)return;
            // Positions are the existing RectTransform Pos X/Y; keep authored anchors, pivots, size and inner layout.
            effect.GetComponent<RectTransform>().anchoredPosition=effectPosition;
            bg.GetComponent<RectTransform>().anchoredPosition=hintPosition;
            effect.SetActive(visible==1);
            bg.SetActive(true);
            leftImage.SetActive(side==1);leftText.SetActive(side==1);
            rightImage.SetActive(side==2);rightText.SetActive(side==2);
            string hint=step.Value<string>("hint");
            leftText.GetComponent<Text>().text=hint;rightText.GetComponent<Text>().text=hint;
            var button=bg.GetComponent<Button>();
            button.onClick.RemoveAllListeners();button.onClick.AddListener(()=>NavigateStory(step));

        }
        static bool IsFiniteStoryPoint(Vector2 point)
            =>!float.IsNaN(point.x)&&!float.IsInfinity(point.x)&&!float.IsNaN(point.y)&&!float.IsInfinity(point.y);
        void NavigateStory(JObject step)
        {
            if(storyPending)return;
            int action=step.Value<int>("action_type");
            if(!storyState.Value<bool>("started"))
            {
                var trigger=services.GlobalEvents.Get(step.Value<int>("trigger_event_id"));
                if(trigger.Type==30){HandleStoryRealm();return;}
                return;
            }
            switch(action)
            {
                case 1:if(step.Value<int>("action_id")==22)HandleStoryRealm();else HandleFormationClick();break;
                case 2:
                    if(services.UiStack.Current!=mainView){HandleBack();if(services.UiStack.Current!=mainView)return;}
                    RememberLastWorldChapter((uint)step.Value<int>("action_id"));
                    InvokeLuaOrFail(onWorldClicked,"Story.World.Open");
                    break;
                case 5:
                    if(worldBattleInFlight)return;
                    if(services.UiStack.Current!=mainView)HandleBack();
                    break;
                case 6:
                    if(!IsHeroOpen)HandleFormationClick();
                    break;
            }
        }
        void HandleStoryRealm(){if(!IsJingJieOpen)InvokeLuaOrFail(onJingJieClicked,"Story.JingJie.Open");}
        bool StoryBlocksAutoNext => storyState?.Value<bool>("enabled")==true&&CurrentStoryStep>0&&storySteps!=null&&
            storySteps.Values.Any(s=>s.Value<int>("action_type")==6&&s.Value<int>("id")>=CurrentStoryStep);
    }
}

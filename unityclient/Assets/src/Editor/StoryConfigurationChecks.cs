using System;
using System.Linq;
using Newtonsoft.Json.Linq;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.Foundation;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;
namespace ProjectX.Editor
{
    public static class StoryConfigurationChecks
    {
        static void Check(bool value,string text){if(!value)throw new InvalidOperationException("Story: "+text);}
        public static string Run()
        {
            ResourceLoader.Configure(new UnityResourceLoader());
            var events=new GlobalEventCatalog();
            var rows=JArray.Parse(ResourceLoader.Load<TextAsset>("ProjectXData/Configs/story_event").text).Cast<JObject>().ToArray();
            var dialogs=JArray.Parse(ResourceLoader.Load<TextAsset>("ProjectXData/Configs/story_dialog").text).Cast<JObject>().ToArray();
            Check(rows.Length==11&&dialogs.Length==3,"formal opening rows");
            var steps=rows.ToDictionary(r=>r.Value<int>("id"));
            foreach(var s in rows){events.Get(s.Value<int>("trigger_event_id"));events.Get(s.Value<int>("complete_event_id"));Check(s.Value<int>("once")==1,"one-time state");}
            var opening=rows.Single(s=>s.Value<int>("pre_id")==0);
            Check(events.Get(opening.Value<int>("trigger_event_id")).Type==1002,"main interface trigger");
            var partner=rows.Single(s=>events.Get(s.Value<int>("trigger_event_id")).Type==30);
            Check(events.Get(partner.Value<int>("trigger_event_id")).Target==2&&partner.Value<int>("dialogid")>0,"first small realm breakthrough");
            var heroReward=rows.Single(s=>s.Value<int>("pre_id")==partner.Value<int>("id"));
            Check(heroReward.Value<int>("action_type")==3&&heroReward.Value<int>("trigger_event_id")==partner.Value<int>("complete_event_id"),"hero grant follows completed partner dialogue");
            var equip=rows.Single(s=>s.Value<int>("action_type")==6);
            Check(equip.Value<int>("param1")==57&&equip.Value<int>("param2")==1,"hero and weapon slot");
            var second=rows.Single(s=>s.Value<int>("pre_id")==equip.Value<int>("id"));
            Check(second.Value<int>("action_type")==2&&second.Value<int>("action_id")==1002,"second chapter follows actual equip");
            foreach(var d in dialogs){Check(!string.IsNullOrWhiteSpace(d.Value<string>("dialog"))&&d.Value<int>("enabled")==1,"dialogue enabled");if(d.Value<int>("actor_type")==3){Check(HeroCatalog.TryGet(d.Value<int>("actor_id"),out var h),"portrait actor");using(var r=new ResourceService()){var sprite=r.LoadHeroBodyPortrait(h.Picture,out bool missing);Check(sprite!=null&&!missing,"portrait asset");}}}
            var dialog=ResourceLoader.Load<GameObject>("UI/StoryDialog");
            var guide=ResourceLoader.Load<GameObject>("UI/StoryGuide");
            Check(dialog!=null&&guide!=null,"registered native prefab references");
            Check(dialog.transform.Find("DialogUI").GetComponent<Button>()!=null,"dialogue click area");
            Check(dialog.transform.Find("DialogUI/Image_1/btn_Skip").GetComponent<Button>()!=null,"skip binding");
            Check(dialog.transform.Find("DialogUI/Content").GetComponent<Text>()!=null,"dialogue body binding");
            Check(guide.transform.Find("GuideBg").GetComponent<Button>()!=null,"guide entry button");
            Check(guide.transform.Find("SelectImage")?.GetComponent<RectTransform>()!=null,"guide effect node");
            foreach(var name in new[]{"Image_1","Text_1","Image_2","Text_2"})Check(guide.transform.Find("GuideBg/"+name)!=null,"guide side binding "+name);
            foreach(var row in rows){Check(row.Value<int>("select_visible")==0||row.Value<int>("select_visible")==1,"guide effect flag");Check(row.Value<int>("hint_side")==1||row.Value<int>("hint_side")==2,"guide side flag");}
            Check(dialog.GetComponent<PrefabAuthoredLayout>()!=null&&guide.GetComponent<PrefabAuthoredLayout>()!=null,"authored layout");
            return "PASS: 11 linked steps, 3 dialogues, breakthrough before partner reward, actual weapon before chapter2, public event references, native dialog/guide bindings.";
        }
    }
}

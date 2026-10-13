using System;
using System.Linq;
using Newtonsoft.Json.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class LibraryRegressionTests
    {
        public static string Run()
        {
            var catalog=new LibraryCatalogData();
            Require(catalog.Realms.Count==55,"55 formal realms");
            Require(catalog.Sets.Count==110&&catalog.Books.Count==440&&catalog.Rewards.Count==660,"approved configuration counts");
            var items=JArray.Parse(Resources.Load<TextAsset>("ProjectXData/Configs/item").text);
            foreach(var book in catalog.Books.Values)
                Require(items.Any(i=>(int)i["id"]==book.Item&&(int)i["jiage"]==100),"formal item price "+book.Item);
            var set=catalog.InRealm(1).First();var rewards=catalog.InSet(set.Id).ToArray();
            var state=new LibraryEnvelope{Configured=true,Unlocked=true,Realm=1,Obtained=set.Books,Owned=set.Books.Select(id=>new[]{id,1}).ToArray()};
            Require(rewards.Count(r=>catalog.Eligible(state,r))==4,"obtained history does not unlock set bonuses");
            state.Books=set.Books.Take(2).ToArray();state.Owned=Array.Empty<int[]>();
            Require(catalog.Eligible(state,rewards.Single(r=>r.Kind=="count")),"two activated books unlock count reward without inventory");
            Require(!catalog.Eligible(state,rewards.Single(r=>r.Kind=="complete")),"two books do not unlock whole set");
            Require(!catalog.Eligible(state,rewards.First()),"already activated book cannot be consumed again");
            state.Books=set.Books;Require(catalog.Eligible(state,rewards.Last()),"whole set activation uses active books");
            state.Rewards=new[]{rewards.Last().Id};Require(!catalog.Eligible(state,rewards.Last()),"claimed reward is ineligible");
            state.Realm=0;Require(!catalog.Eligible(state,rewards.Single(r=>r.Kind=="count")),"future realm lock is enforced");
            var prefab=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/DongFu/DongFuLibrary.prefab");
            Require(prefab.GetComponent<LibraryScreen>()!=null,"screen binding");
            Require(prefab.transform.Find("States")==null,"no library-specific modal dialogs");
            var template=prefab.transform.Find("Details/RewardViewport/Reward/Reward0");
            Require(template!=null&&!template.gameObject.activeSelf,"reward template is hidden");
            Require(template.parent.childCount==1,"only one authored reward template");
            var realm=prefab.transform.Find("Sets/Scroll View/Viewport/Content/Set0");
            Require(realm.Find("Name").GetComponent<UnityEngine.UI.Button>()!=null,"authored realm header input");
            var layout=realm.GetComponent<UnityEngine.UI.VerticalLayoutGroup>();
            Require(layout!=null,"authored realm layout");
            Require(realm.Find("VirtualContent/VirtualRow_0").GetComponent<UnityEngine.UI.Button>()!=null,"authored set row input");
            foreach(var node in prefab.GetComponentsInChildren<Transform>(true))
                Require(GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(node.gameObject)==0,"missing script "+node.name);
            return "Library regressions: formal items, activation conditions, realm locks, authored template and shared modal contract passed.";
        }
        static void Require(bool valid,string message){if(!valid)throw new InvalidOperationException(message);}
    }
}

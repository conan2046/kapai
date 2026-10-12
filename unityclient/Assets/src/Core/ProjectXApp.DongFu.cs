using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private UnityUiView dongFuView;
        private DongFuHomeScreen dongFuScreen;
        private UnityUiView dongFuSubView;
        private int dongFuBuilding;
        private readonly System.Collections.Generic.Dictionary<int,UnityUiView> dongFuPages=new System.Collections.Generic.Dictionary<int,UnityUiView>();
        private static readonly string[] DongFuPageKeys={"DongFuGardenScene","DongFuSpirit","DongFuAlchemy","DongFuForge","DongFuLibrary"};
        private static readonly string[] DongFuPageTitles={"灵园","聚灵阵","炼丹房","炼器室","藏书阁"};
        public bool IsDongFuOpen => dongFuView?.GameObject.activeInHierarchy == true
            && services?.UiStack.Current == dongFuView
            || dongFuSubView?.GameObject.activeInHierarchy==true&&services?.UiStack.Current==dongFuSubView;

        private void BindDongFuEntry()
        {
            GameObject node = FindMainHudNode("Layer/Bg/btn_donfu");
            Button button = node != null ? node.GetComponent<Button>() : null;
            if (button == null) return;
            button.onClick.RemoveListener(ShowDongFu);
            button.onClick.AddListener(ShowDongFu);
        }

        public void ShowDongFu()
        {
            if (dongFuView == null || !dongFuView.IsAlive)
            {
                dongFuView = services.UiRouter.FindByKey("DongFuHome", true);
                dongFuScreen = dongFuView.GameObject.GetComponent<DongFuHomeScreen>();
                if (dongFuScreen == null) throw new System.InvalidOperationException("DongFu prefab has no screen binding.");
                dongFuScreen.CloseRequested += CloseDongFu;
                dongFuScreen.BuildingRequested += ShowDongFuBuilding;
                dongFuScreen.BecameVisible += RestoreDongFuFrame;
            }
            if (services.UiStack.Current != dongFuView) services.UiStack.Push(dongFuView);
            RestoreDongFuFrame();
        }

        private void CloseDongFu()
        {
            if(services.UiStack.Current==dongFuSubView)
            {
                services.UiStack.Pop();RestoreDongFuFrame();return;
            }
            if (services.UiStack.Current == dongFuView) services.UiStack.Pop();
            else dongFuView?.SetVisible(false);
            if(!IsGardenOpen && !IsDongFuOpen)SetOneLevelFrameVisible(false);
        }

        private void RestoreDongFuFrame()
        {
            ConfigureDongFuSharedFrame(dongFuView,dongFuScreen.Back,null);
            oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<Text>().text="洞府";
        }

        private void ShowDongFuBuilding(int building)
        {
            if(building==0){ShowGarden();return;}
            if(building<1||building>=DongFuPageKeys.Length)return;
            if(!dongFuPages.TryGetValue(building,out UnityUiView page)||!page.IsAlive)
            {
                page=services.UiRouter.FindByKey(DongFuPageKeys[building],true);dongFuPages[building]=page;
            }
            dongFuSubView=page;dongFuBuilding=building;
            if(services.UiStack.Current!=page)services.UiStack.Push(page);
            RestoreDongFuSubFrame();
        }

        private void RestoreDongFuSubFrame()
        {
            ConfigureDongFuSharedFrame(dongFuSubView,CloseDongFu,null);
            oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<Text>().text=DongFuPageTitles[dongFuBuilding];
        }

        // All DongFu subpages use the existing OneLevelLayer instance and currency binding.
        // This route changes visibility, text and callbacks only; authored geometry is retained.
        private void ConfigureDongFuSharedFrame(UnityUiView content, System.Action back, System.Action help)
        {
            var frame = EnsureOneLevelFrame();
            if(content!=gardenView)gardenView?.SetVisible(false);
            if(content!=dongFuView)dongFuView?.SetVisible(false);
            foreach(var page in dongFuPages.Values)if(content!=page)page.SetVisible(false);
            frame.AttachContent(content, keepSiblingOrder:true);
            content.GameObject.transform.SetAsFirstSibling();
            frame.Apply(OneLevelFrameMode.DongFu);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => back(), true);
            var helpNode=oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName/Button_1");
            helpNode.SetActive(help!=null);
            if(help!=null)oneLevelFrameView.BindClick("Layer/Panel_12/Title/TitleName/Button_1", () => help(), true);
            BindTaskFrameButton(oneLevelFrameView.FindNode("Layer/GoldCheck/GoldIcon1/AddBtn").transform,HandleBagClick,true);
            BindTaskFrameButton(oneLevelFrameView.FindNode("Layer/GoldCheck/GoldIcon3/AddBtn").transform,HandleShopClick,true);
            BindTaskFrameButton(oneLevelFrameView.FindNode("Layer/GoldCheck/GoldIcon4/AddBtn").transform,null,false);
            RefreshStandardCurrencyHeader(oneLevelFrameView,"Layer/GoldCheck");
        }
    }
}

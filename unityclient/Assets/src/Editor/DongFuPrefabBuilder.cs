#if UNITY_EDITOR
using System;
using System.IO;
using System.Linq;
using Newtonsoft.Json.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    /// <summary>Initial authoring only. Never runs at startup or rewrites an existing screen.</summary>
    public static class DongFuPrefabBuilder
    {
        public const string Folder = "Assets/Prefabs/DongFu";
        public const string RootPath = Folder + "/DongFuLayer.prefab";
        const string Shared = "Assets/Prefabs/Shared/OneLevelLayer.prefab";
        const string Fish = "Assets/Prefabs/Fish/FishLayer.prefab";
        const string Realm = "Assets/Prefabs/OneLevel/JingjieLayer.prefab";
        static Font font;
        static GameObject buttonTemplate, panelTemplate, slotTemplate, progressTemplate;
        static readonly Color Ink = new Color(.42f, .224f, .224f, 1f);
        static readonly string[] Titles = { "洞府", "灵植园", "聚灵阵", "炼丹房", "炼器室", "藏书阁" };

        [MenuItem("Tools/ProjectX 洞府/生成第一版预制体（仅首次）")]
        public static void Build()
        {
            if (AssetDatabase.LoadAssetAtPath<GameObject>(RootPath) != null)
                throw new InvalidOperationException("DongFu already exists. Edit authored prefabs directly; the builder will not overwrite them.");
            Directory.CreateDirectory(Folder + "/Components");
            AssetDatabase.Refresh();
            font = AssetDatabase.LoadAssetAtPath<Font>("Assets/Art/Fonts/xiaokaiSJ2.ttf");
            buttonTemplate = Extract(Fish, "FishUI/Panel_caozuo/btn_shouqi", "ActionButton");
            panelTemplate = Extract(Realm, "JingjieUI/Panel/Image_1", "ContentPanel");
            slotTemplate = Extract(Realm, "JingjieUI/Panel/Panel_tupo/bg_cost/btn_Material", "ItemSlot");
            progressTemplate = Extract(Fish, "FishUI/Panel_caozuo/Time", "Progress");
            GameObject root = Node("DongFuLayer", null, 0, 0, 1334, 750);
            root.AddComponent<PrefabAuthoredLayout>();
            var key = root.AddComponent<UiPrefabKey>();
            Set(key, "key", "DongFuLayer");
            DongFuScreen screen = root.AddComponent<DongFuScreen>();
            GameObject frame = (GameObject)PrefabUtility.InstantiatePrefab(AssetDatabase.LoadAssetAtPath<GameObject>(Shared), root.transform);
            frame.name = "Frame";
            Place(frame, 0, 0, 1334, 750);
            frame.SetActive(true);
            // Keep the existing frame, title and close visuals, hide unrelated routes and currencies.
            foreach (string path in new[] { "GoldCheck", "Panel_12/Bg/Btn_ListView", "Panel_12/Bg/bg1_4", "Panel_12/SubBtnList", "Panel_12/Title/TitleName/Button_1" })
                frame.transform.Find(path)?.gameObject.SetActive(false);
            Text title = frame.transform.Find("Panel_12/Title/TitleName").GetComponent<Text>();
            title.text = Titles[0];
            Button close = frame.transform.Find("Panel_12/Title/CloseBtn").GetComponent<Button>();
            close.GetComponent<RectTransform>().anchoredPosition=new Vector2(1258,0);
            RectTransform parchment=frame.transform.Find("Panel_12/Bg/bg1_2").GetComponent<RectTransform>();
            parchment.anchoredPosition=new Vector2(572,parchment.anchoredPosition.y);
            parchment.sizeDelta=new Vector2(1110,parchment.sizeDelta.y);
            Button back = Action(root.transform, "Back", "返回", -525, 329, 100, 42);
            Button help = Action(root.transform, "Help", "说明", 492, 329, 100, 42);
            GameObject nav = Node("Navigation", root.transform, -537, -4, 128, 570);
            GameObject content = Node("Pages", root.transform, 64, -18, 1020, 545);
            Button[] navButtons = new Button[6];
            GameObject[] selections = new GameObject[6];
            for (int i = 0; i < 6; i++)
            {
                navButtons[i] = Action(nav.transform, "Tab" + i, Titles[i], 0, 229 - i * 86, 120, 60);
                GameObject selected = Node("Selected", navButtons[i].transform, 0, 0, 114, 54);
                Image border = selected.AddComponent<Image>();
                border.sprite = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/ui_common/ui_common_youyeqian_xuanzhong.png");
                border.color = new Color(1f, .88f, .5f, .4f);
                border.raycastTarget = false;
                selected.transform.SetAsFirstSibling(); selected.SetActive(i == 0); selections[i] = selected;
                GameObject red = Node("RedDot", navButtons[i].transform, 49, 24, 12, 12);
                red.AddComponent<Image>().color = Color.red; red.SetActive(false);
            }
            GameObject[] pages = new GameObject[6];
            Button[] entries = new Button[5];
            for (int i = 0; i < 6; i++)
            {
                GameObject page = Node("DongFu" + i, null, 0, 0, 1020, 545);
                page.AddComponent<PrefabAuthoredLayout>();
                if (i == 0) Home(page);
                if (i == 1) Garden(page);
                if (i == 2) Spirit(page);
                if (i == 3 || i == 4) Craft(page, i == 3);
                if (i == 5) Books(page);
                AddStates(page);
                GameObject prefab = PrefabUtility.SaveAsPrefabAsset(page, Folder + "/" + new[] { "DongFuHome", "DongFuGarden", "DongFuSpirit", "DongFuAlchemy", "DongFuForge", "DongFuLibrary" }[i] + ".prefab");
                UnityEngine.Object.DestroyImmediate(page);
                pages[i] = (GameObject)PrefabUtility.InstantiatePrefab(prefab, content.transform);
                pages[i].name = new[] { "Home", "Garden", "Spirit", "Alchemy", "Forge", "Library" }[i];
                pages[i].SetActive(i == 0);
                if (i == 0) for (int j = 0; j < 5; j++) entries[j] = pages[i].transform.Find("Building" + j + "/Enter").GetComponent<Button>();
            }
            GameObject dialogs = Node("Dialogs", root.transform, 0, 0, 1334, 750);
            GameObject helpDialog = null;
            Button helpClose = null;
            foreach (string kind in new[] { "Help", "Confirm", "OfflineResult", "Reward", "Attributes", "ItemDetail", "Error" })
            {
                GameObject dialog = Dialog(kind);
                GameObject prefab = PrefabUtility.SaveAsPrefabAsset(dialog, Folder + "/Components/" + kind + "Dialog.prefab");
                UnityEngine.Object.DestroyImmediate(dialog);
                GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab, dialogs.transform);
                instance.name = kind; instance.SetActive(false);
                if (kind == "Help") { helpDialog = instance; helpClose = instance.transform.Find("Panel/Close").GetComponent<Button>(); }
            }
            var binding = new SerializedObject(screen);
            AssignArray(binding, "pages", pages);
            AssignArray(binding, "navigation", navButtons);
            AssignArray(binding, "selectedStates", selections);
            AssignArray(binding, "homeEntries", entries);
            binding.FindProperty("back").objectReferenceValue = back;
            binding.FindProperty("close").objectReferenceValue = close;
            binding.FindProperty("help").objectReferenceValue = help;
            binding.FindProperty("helpDialog").objectReferenceValue = helpDialog;
            binding.FindProperty("helpClose").objectReferenceValue = helpClose;
            binding.FindProperty("title").objectReferenceValue = title;
            SerializedProperty names = binding.FindProperty("pageTitles"); names.arraySize = Titles.Length;
            for (int i = 0; i < Titles.Length; i++) names.GetArrayElementAtIndex(i).stringValue = Titles[i];
            binding.ApplyModifiedPropertiesWithoutUndo();
            GameObject saved = PrefabUtility.SaveAsPrefabAsset(root, RootPath);
            UnityEngine.Object.DestroyImmediate(root);
            Register(saved); AssetDatabase.SaveAssets();
            DongFuSharedFrameAuthoring.Apply();
            Debug.Log("DongFu first authored prefab revision created; subsequent layout changes are manual.");
        }

        static void Home(GameObject root)
        {
            Label(root.transform, "Summary", "洞府生产与藏书养成", 0, 246, 900, 40, 26);
            // Horizontal scenic composition using an existing background as a temporary resource.
            Image scene = Node("Scenery", root.transform, 0, -8, 992, 480).AddComponent<Image>();
            scene.sprite = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/Backgrounds/map33.jpg");
            scene.raycastTarget = false;
            Vector2[] pos = { new Vector2(-327,-121), new Vector2(0,-108), new Vector2(324,-120), new Vector2(282,112), new Vector2(-268,127) };
            for (int i = 0; i < 5; i++)
            {
                GameObject building = Panel(root.transform, "Building" + i, pos[i].x, pos[i].y, 186, 134);
                Label(building.transform, "Name", Titles[i+1], 0, 38, 174, 34, 25);
                Label(building.transform, "Status", "", 0, 5, 174, 28, 18);
                Action(building.transform, "Enter", "进入", 0, -38, 118, 40);
                GameObject locked = Node("Locked", building.transform, 0, 0, 180, 126);
                locked.AddComponent<Image>().color = new Color(0,0,0,.65f);
                Label(locked.transform,"Condition","尚未解锁",0,0,170,40,20).color = Color.white;
                locked.SetActive(false);
            }
            Label(root.transform, "Notice", "", 0, -247, 950, 30, 18);
        }

        static void Garden(GameObject root)
        {
            GameObject left = Panel(root.transform, "Overview", -385, 0, 210, 510);
            Label(left.transform, "Title", "灵植生产", 0, 219, 190, 38, 26);
            Label(left.transform, "Summary", "等级：—\n可用灵田：—\n成长加速：—\n收获加成：—", 0, 116, 184, 145, 21);
            Label(left.transform, "EventsTitle", "灵田状态", 0, 6, 184, 34, 23);
            Label(left.transform, "Events", "尚未同步生产状态", 0, -84, 184, 110, 20);
            Action(left.transform,"Upgrade","升级灵田",0,-209,164,48).interactable=false;
            GameObject plots = Panel(root.transform, "Plots", 115, 46, 735, 398);
            Label(plots.transform,"Title","灵田",0,172,690,32,25);
            for(int i=0;i<12;i++)
            {
                GameObject plot = Panel(plots.transform,"Plot"+i,-268+(i%4)*178,94-(i/4)*115,158,102);
                Slot(plot.transform,"Crop",-48,7,48);
                Label(plot.transform,"Name","空闲",30,24,92,26,19);
                Label(plot.transform,"Remaining","",30,-4,92,26,17);
                foreach(string state in new[]{"Empty","Growing","Ready","Locked"})
                {
                    GameObject n=Node(state,plot.transform,27,-34,108,24);
                    Label(n.transform,"Label",new[]{"种植","成长中","可收获","未解锁"}[Array.IndexOf(new[]{"Empty","Growing","Ready","Locked"},state)],0,0,108,24,18);
                    n.SetActive(state=="Empty");
                }
                Button b=plot.AddComponent<Button>();b.targetGraphic=plot.GetComponent<Image>();b.interactable=false;
            }
            GameObject queue=Panel(root.transform,"Queue",115,-193,735,74);
            Label(queue.transform,"Title","等待队列",-283,0,140,30,22);
            for(int i=0;i<4;i++) Slot(queue.transform,"Batch"+i,-123+i*113,0,50);
            GameObject picker=Panel(root.transform,"SeedPicker",115,0,650,405);picker.SetActive(false);
            Label(picker.transform,"Title","选择灵种",0,165,560,32,26);
            for(int i=0;i<6;i++) Slot(picker.transform,"Seed"+i,-220+(i%3)*220,70-(i/3)*115,72);
            Action(picker.transform,"Plant","确认种植",0,-157,200,50).interactable=false;
        }

        static void Spirit(GameObject root)
        {
            GameObject left=Panel(root.transform,"LevelPanel",-342,0,292,510);
            Label(left.transform,"Title","聚灵阵",0,216,270,40,28);
            Image seal=Node("ArrayArt",left.transform,0,82,226,226).AddComponent<Image>();
            seal.sprite=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/ui_duanzao/ui_huawen_long.png");seal.raycastTarget=false;
            Label(left.transform,"Level","等级：—",0,-69,264,40,24);
            Slot(left.transform,"Cost",-75,-130,58);
            Label(left.transform,"CostText","升级材料：—",30,-130,184,44,20);
            Action(left.transform,"Upgrade","升级聚灵阵",0,-214,224,52).interactable=false;
            GameObject right=Panel(root.transform,"BonusPanel",172,0,630,510);
            Label(right.transform,"ProductionTitle","灵植生产加成",0,216,590,36,26);
            Label(right.transform,"Growth","成长时间缩短：—",0,155,564,42,24);
            Label(right.transform,"Yield","收获量增加：—",0,103,564,42,24);
            Label(right.transform,"CombatTitle","上阵神将战斗属性",0,26,564,40,26);
            for(int i=0;i<4;i++) Label(right.transform,"Attribute"+i,"—",0,-34-i*45,564,38,23);
            Label(right.transform,"EffectNotice","上阵神将享受加成，换阵后同步生效",0,-225,564,32,19);
        }

        static void Craft(GameObject root,bool alchemy)
        {
            GameObject recipes=Panel(root.transform,"Recipes",-334,0,310,510);
            Label(recipes.transform,"Title",alchemy?"丹方列表":"打造图纸",0,218,288,34,27);
            Action(recipes.transform,"Filter","全部品质 / 部位",0,165,264,42);
            for(int i=0;i<4;i++)
            {
                GameObject row=Panel(recipes.transform,"Recipe"+i,0,94-i*80,275,70);
                Slot(row.transform,"Icon",-99,0,46);
                Label(row.transform,"Name","",29,13,190,28,21);
                Label(row.transform,"State","",29,-17,190,24,18);
                row.SetActive(false);
            }
            Label(recipes.transform,"Empty","暂无已学习配方",0,-20,264,68,23);
            GameObject work=Panel(root.transform,"Workbench",171,0,636,510);
            Label(work.transform,"Title",alchemy?"炼丹炉":"打造炉",0,215,600,40,28);
            Image furnace=Node("FurnaceArt",work.transform,0,83,182,182).AddComponent<Image>();
            furnace.sprite=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/ui_duanzao/ui_huawen_long.png");furnace.raycastTarget=false;
            for(int i=0;i<4;i++) Slot(work.transform,"Material"+i,(i%2==0?-225:225),139-(i/2)*127,72);
            Label(work.transform,"SelectedRecipe","请选择配方",0,-31,570,38,24);
            Label(work.transform,"Outcome","",0,-72,570,42,21);
            Action(work.transform,"Decrease","−",-169,-118,42,38).interactable=false;
            Label(work.transform,"Quantity","1",-85,-118,96,38,25);
            Action(work.transform,"Increase","+",0,-118,42,38).interactable=false;
            Action(work.transform,"Maximum","最大",97,-118,96,38).interactable=false;
            GameObject progress=(GameObject)PrefabUtility.InstantiatePrefab(progressTemplate,work.transform);
            progress.name="Progress";Place(progress,0,-165,548,30);
            foreach(Text text in progress.GetComponentsInChildren<Text>(true))text.text="";
            foreach(Image image in progress.GetComponentsInChildren<Image>(true))if(image.type==Image.Type.Filled)image.fillAmount=0;
            Action(work.transform,"Start",alchemy?"开始炼丹":"开始打造",0,-216,246,50).interactable=false;
            foreach(string name in new[]{"Working","Ready","Unlearned"})
            {
                GameObject state=Node(name,work.transform,0,-216,560,54);state.SetActive(false);
                if(name=="Working"){Label(state.transform,"Time","",-80,0,330,40,23);Action(state.transform,"Cancel","取消",204,0,116,44);}
                if(name=="Ready")Action(state.transform,"Claim","领取产物",0,0,246,50);
                if(name=="Unlearned")Label(state.transform,"Notice","尚未学习该配方",0,0,500,40,23);
            }
        }

        static void Books(GameObject root)
        {
            GameObject sets=Panel(root.transform,"Sets",-289,0,406,510);
            Label(sets.transform,"Title","套书总览",0,219,370,38,28);
            Action(sets.transform,"Filter","全部品质 / 状态",0,167,355,42);
            for(int i=0;i<4;i++)
            {
                GameObject card=Panel(sets.transform,"Set"+i,(i%2==0?-96:96),72-(i/2)*158,176,144);
                Slot(card.transform,"Cover",0,28,50);
                Label(card.transform,"Name","",0,-22,160,28,21);
                Label(card.transform,"Progress","",0,-50,160,24,18);card.SetActive(false);
            }
            Label(sets.transform,"Empty","暂无书籍收集记录",0,0,360,80,24);
            Action(sets.transform,"Attributes","属性总览",0,-215,225,48);
            GameObject detail=Panel(root.transform,"Details",211,0,555,510);
            Label(detail.transform,"SetName","请选择书套",0,215,520,38,29);
            Label(detail.transform,"Collection","收集进度：—",0,161,520,34,23);
            for(int i=0;i<4;i++)Slot(detail.transform,"Book"+i,-195+i*130,92,78);
            Label(detail.transform,"RewardsTitle","收集奖励 · 激活后永久生效",0,16,520,38,24);
            for(int i=0;i<3;i++)
            {
                GameObject reward=Panel(detail.transform,"Reward"+i,0,-52-i*78,513,67);
                Label(reward.transform,"Condition",new[]{"单本奖励","多本奖励","整套奖励"}[i],-65,15,350,28,21);
                Label(reward.transform,"Attributes","—",-65,-16,350,24,18);
                Action(reward.transform,"Activate","激活",196,0,99,43).interactable=false;
                GameObject active=Node("Activated",reward.transform,196,0,99,43);
                Label(active.transform,"Label","已激活",0,0,99,43,20);active.SetActive(false);
            }
        }

        static void AddStates(GameObject root)
        {
            GameObject states=Node("States",root.transform,0,0,1000,510);
            foreach(string kind in new[]{"Loading","Locked","Error"})
            {
                GameObject state=Panel(states.transform,kind,0,0,600,180);
                Label(state.transform,"Message",kind=="Loading"?"正在同步洞府信息":kind=="Locked"?"尚未解锁":"信息同步失败，请重试",0,20,550,74,25);
                Action(state.transform,"Action",kind=="Error"?"重试":"知道了",0,-53,180,42);state.SetActive(false);
            }
        }

        static GameObject Dialog(string kind)
        {
            GameObject root=Node(kind+"Dialog",null,0,0,1334,750);
            root.AddComponent<PrefabAuthoredLayout>();
            Image shade=root.AddComponent<Image>();shade.color=new Color(0,0,0,.68f);shade.raycastTarget=true;
            GameObject panel=Panel(root.transform,"Panel",0,0,660,450);
            string title=new[]{"玩法说明","操作确认","离线收获","获得奖励","属性总览","道具详情","操作提示"}[Array.IndexOf(new[]{"Help","Confirm","OfflineResult","Reward","Attributes","ItemDetail","Error"},kind)];
            Label(panel.transform,"Title",title,0,181,600,42,30);
            Label(panel.transform,"Body",kind=="Help"?"灵植园提供制作材料。\n聚灵阵提升灵植成长、收获与上阵神将战斗属性。\n炼丹与打造消耗材料。\n藏书阁按单本、多本、整套解锁永久属性。":"",0,30,594,230,24);
            for(int i=0;i<4;i++){GameObject slot=Slot(panel.transform,"Item"+i,-210+i*140,-65,70);slot.SetActive(false);}
            Action(panel.transform,"Close","关闭",139,-172,198,50);
            Button confirm=Action(panel.transform,"Confirm","确认",-139,-172,198,50);confirm.gameObject.SetActive(kind=="Confirm");
            return root;
        }

        static GameObject Extract(string path,string node,string name)
        {
            GameObject source=AssetDatabase.LoadAssetAtPath<GameObject>(path).transform.Find(node).gameObject;
            GameObject copy=UnityEngine.Object.Instantiate(source);copy.name=name;
            if(name!="Progress") foreach(Transform child in copy.transform.Cast<Transform>().ToArray())UnityEngine.Object.DestroyImmediate(child.gameObject);
            foreach(MonoBehaviour behaviour in copy.GetComponents<MonoBehaviour>())
                if(!(behaviour is Image)&&!(behaviour is Button))UnityEngine.Object.DestroyImmediate(behaviour);
            GameObject result=PrefabUtility.SaveAsPrefabAsset(copy,Folder+"/Components/"+name+".prefab");
            UnityEngine.Object.DestroyImmediate(copy);return result;
        }
        static GameObject Node(string name,Transform parent,float x,float y,float w,float h)
        {var go=new GameObject(name,typeof(RectTransform));go.transform.SetParent(parent,false);Place(go,x,y,w,h);return go;}
        static void Place(GameObject go,float x,float y,float w,float h)
        {var r=go.GetComponent<RectTransform>();r.anchorMin=r.anchorMax=r.pivot=new Vector2(.5f,.5f);r.anchoredPosition=new Vector2(x,y);r.sizeDelta=new Vector2(w,h);r.localScale=Vector3.one;}
        static GameObject Panel(Transform parent,string name,float x,float y,float w,float h)
        {var go=(GameObject)PrefabUtility.InstantiatePrefab(panelTemplate,parent);go.name=name;Place(go,x,y,w,h);go.GetComponent<Image>().raycastTarget=false;return go;}
        static Text Label(Transform parent,string name,string text,float x,float y,float w,float h,int size)
        {Text label=Node(name,parent,x,y,w,h).AddComponent<Text>();label.font=font;label.fontSize=size;label.text=text;label.color=Ink;label.alignment=TextAnchor.MiddleCenter;label.raycastTarget=false;label.horizontalOverflow=HorizontalWrapMode.Wrap;label.verticalOverflow=VerticalWrapMode.Truncate;label.resizeTextForBestFit=false;return label;}
        static Button Action(Transform parent,string name,string text,float x,float y,float w,float h)
        {var go=(GameObject)PrefabUtility.InstantiatePrefab(buttonTemplate,parent);go.name=name;Place(go,x,y,w,h);var b=go.GetComponent<Button>();b.onClick.RemoveAllListeners();b.transition=Selectable.Transition.ColorTint;Label(go.transform,"Label",text,0,0,w-12,h-4,22).color=Color.white;return b;}
        static GameObject Slot(Transform parent,string name,float x,float y,float size)
        {var go=(GameObject)PrefabUtility.InstantiatePrefab(slotTemplate,parent);go.name=name;Place(go,x,y,size,size);go.GetComponent<Button>().interactable=false;var icon=Node("Icon",go.transform,0,0,size-10,size-10).AddComponent<Image>();icon.sprite=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/Icons/JingJie/ui_jingjie_icon_jingjie_01.png");icon.raycastTarget=false;Label(go.transform,"Count","",0,-size*.32f,size-4,24,17);return go;}
        static void Set(UnityEngine.Object target,string field,string value)
        {var obj=new SerializedObject(target);obj.FindProperty(field).stringValue=value;obj.ApplyModifiedPropertiesWithoutUndo();}
        static void AssignArray(SerializedObject obj,string field,UnityEngine.Object[] values)
        {var a=obj.FindProperty(field);a.arraySize=values.Length;for(int i=0;i<values.Length;i++)a.GetArrayElementAtIndex(i).objectReferenceValue=values[i];}
        static void Register(GameObject prefab)
        {
            const string refPath="Assets/Prefabs/Catalog/DongFuLayer.asset";
            var reference=ScriptableObject.CreateInstance<UiPrefabReference>();reference.SetPrefab(prefab);AssetDatabase.CreateAsset(reference,refPath);
            var catalog=AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>("Assets/Prefabs/Catalog/Catalog.asset");
            if(!catalog.Entries.Any(e=>e.Key=="DongFuLayer")){catalog.Replace(catalog.Entries.Concat(new[]{new UiPrefabCatalogEntry("DongFuLayer","Unity/DongFu/DongFuLayer",null,false)}).ToArray());EditorUtility.SetDirty(catalog);}
            string settings=Path.GetFullPath("ProjectSettings/ProjectXAssetReferences.json");
            JArray refs=JArray.Parse(File.ReadAllText(settings));
            refs.Add(new JObject{["key"]="UiPrefabs/DongFuLayer",["guid"]=AssetDatabase.AssetPathToGUID(refPath)});
            File.WriteAllText(settings,refs.ToString(Newtonsoft.Json.Formatting.Indented)+"\n");
            UnityNativeUiAssetValidator.RebuildResourceReference("UiPrefabs/DongFuLayer");
        }

        [MenuItem("Tools/ProjectX 洞府/检查并输出预制体预览")]
        public static void ValidateAndCapture()
        {
            GameObject prefab=AssetDatabase.LoadAssetAtPath<GameObject>(RootPath);
            if(prefab==null)throw new InvalidOperationException("DongFu prefab is missing.");
            string output=Path.GetFullPath(Path.Combine(Application.dataPath,"../../.local/dongfu-development/prefab-v1"));
            Directory.CreateDirectory(output);
            var preview=UnityEditor.SceneManagement.EditorSceneManager.NewPreviewScene();
            RenderTexture texture=null;
            Camera camera=null;
            RenderTexture previous=RenderTexture.active;
            try
            {
                var cameraObject=new GameObject("DongFuPreviewCamera",typeof(Camera));
                UnityEngine.SceneManagement.SceneManager.MoveGameObjectToScene(cameraObject,preview);
                camera=cameraObject.GetComponent<Camera>();camera.scene=preview;camera.clearFlags=CameraClearFlags.SolidColor;
                camera.backgroundColor=Color.black;camera.orthographic=true;camera.orthographicSize=375;
                camera.transform.position=new Vector3(0,0,-100);camera.nearClipPlane=.1f;camera.farClipPlane=1000;
                texture=new RenderTexture(1334,750,24);camera.targetTexture=texture;
                var canvasObject=new GameObject("DongFuPreviewCanvas",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
                UnityEngine.SceneManagement.SceneManager.MoveGameObjectToScene(canvasObject,preview);
                Canvas canvas=canvasObject.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceCamera;canvas.worldCamera=camera;canvas.planeDistance=10;
                CanvasScaler scaler=canvasObject.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1334,750);
                GameObject root=UnityEngine.Object.Instantiate(prefab,canvasObject.transform,false);
                root.SetActive(true);
                if(root.GetComponentsInChildren<Component>(true).Any(c=>c==null))throw new InvalidOperationException("DongFu contains missing components.");
                var screen=root.GetComponent<DongFuScreen>();
                var rectangles=root.GetComponentsInChildren<RectTransform>(true);
                var geometry=rectangles.Select(r=>r.anchoredPosition.ToString()+r.sizeDelta.ToString()+r.localScale.ToString()).ToArray();
                var binding=new SerializedObject(screen);
                foreach(string field in new[]{"pages","navigation","selectedStates","homeEntries"})
                {
                    var a=binding.FindProperty(field);
                    if(a.arraySize!=(field=="homeEntries"?5:6))throw new InvalidOperationException("DongFu binding count: "+field);
                    for(int i=0;i<a.arraySize;i++)if(a.GetArrayElementAtIndex(i).objectReferenceValue==null)throw new InvalidOperationException("DongFu null binding: "+field);
                }
                for(int i=0;i<6;i++)
                {
                    screen.ShowPage(i);Canvas.ForceUpdateCanvases();camera.Render();RenderTexture.active=texture;
                    var image=new Texture2D(1334,750,TextureFormat.RGB24,false);
                    image.ReadPixels(new Rect(0,0,1334,750),0,0);image.Apply();
                    File.WriteAllBytes(Path.Combine(output,new[]{"home","garden","spirit","alchemy","forge","library"}[i]+".png"),image.EncodeToPNG());
                    UnityEngine.Object.DestroyImmediate(image);
                }
                var after=rectangles.Select(r=>r.anchoredPosition.ToString()+r.sizeDelta.ToString()+r.localScale.ToString()).ToArray();
                if(!geometry.SequenceEqual(after))throw new InvalidOperationException("DongFu page switching changed authored geometry.");
                foreach(string name in new[]{"Help","Confirm","OfflineResult","Reward","Attributes","ItemDetail","Error"})
                    if(root.transform.Find("Dialogs/"+name)==null)throw new InvalidOperationException("DongFu missing dialog: "+name);
                File.WriteAllText(Path.Combine(output,"validation.txt"),"Prefab references: passed\nSix pages / five entries / seven dialogs: passed\nMissing components: 0\nPage-switch geometry: unchanged\nBusiness protocol / rewards / persistence: not yet implemented\nPlayer visual acceptance: pending\n");
                Debug.Log("DongFu prefab validation and six editor previews: "+output);
            }
            finally
            {
                RenderTexture.active=previous;
                if(camera!=null)camera.targetTexture=null;
                if(texture!=null){texture.Release();UnityEngine.Object.DestroyImmediate(texture);}
                UnityEditor.SceneManagement.EditorSceneManager.ClosePreviewScene(preview);
            }
        }
    }
}
#endif

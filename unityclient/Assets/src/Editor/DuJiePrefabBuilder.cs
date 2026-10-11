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
    public static class DuJiePrefabBuilder
    {
        public const string PrefabPath = "Assets/Prefabs/OneLevel/DuJieLayer.prefab";
        private const string Effects = "Assets/Prefabs/Effects/DuJie/";

        [MenuItem("Tools/ProjectX 境界/构建独立渡劫预制体")]
        public static void Build()
        {
            if (!File.Exists(PrefabPath)) CreatePrefab();
            // Once authored, the user's layout is preserved on subsequent runs.
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(PrefabPath);
            DuJieViewBindings binding = prefab.GetComponent<DuJieViewBindings>();
            if (binding == null || binding.RoleAnchor == null || binding.HealthFill == null
                || binding.CloudPrefab == null || binding.LightningPrefab == null
                || binding.ShieldPrefab == null || binding.SuccessPrefab == null)
                throw new InvalidDataException("DuJie prefab bindings are incomplete.");
            foreach (GameObject effect in new[] {binding.CloudPrefab,binding.LightningPrefab,binding.ShieldPrefab,binding.SuccessPrefab})
            {
                if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(effect) != 0)
                    throw new InvalidDataException("Missing effect script: " + effect.name);
                foreach (Renderer renderer in effect.GetComponentsInChildren<Renderer>(true).Where(value => value.enabled))
                    foreach (Material material in renderer.sharedMaterials)
                        if (material == null || material.shader == null || !material.shader.isSupported
                            || ShaderUtil.ShaderHasError(material.shader))
                            throw new InvalidDataException("Unsupported active effect material: " + effect.name + "/" + renderer.name);
            }
            Register(prefab);
            Debug.Log("[DuJiePrefabBuilder] Independent prefab registered; role anchor is empty; existing authored layout preserved.");
        }

        private static void CreatePrefab()
        {
            GameObject source = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/OneLevel/JingjieLayer.prefab");
            Font font = source.GetComponentsInChildren<Text>(true).Select(text => text.font).FirstOrDefault(value => value != null);
            if (font == null) throw new InvalidDataException("Shared JingJie font is missing.");
            RectTransform root = Node("DuJieLayer", null, Vector2.zero, new Vector2(960,1440));
            try
            {
                root.anchorMin=Vector2.zero;root.anchorMax=Vector2.one;root.sizeDelta=Vector2.zero;
                DuJieViewBindings b=root.gameObject.AddComponent<DuJieViewBindings>();
                Image background=Node("Backdrop",root,Vector2.zero,new Vector2(960,1440)).gameObject.AddComponent<Image>();
                background.color=new Color(.025f,.035f,.055f,1f);
                RectTransform bgRect=background.rectTransform;bgRect.anchorMin=Vector2.zero;bgRect.anchorMax=Vector2.one;bgRect.sizeDelta=Vector2.zero;
                b.CloudViewport=Viewport("CloudViewport",root);
                b.CloudAnchor=Node("CloudAnchor",root,new Vector2(0,490),new Vector2(850,400));
                b.LightningAnchor=Node("LightningAnchor",root,new Vector2(0,100),new Vector2(600,750));
                b.RoleAnchor=Node("RoleAnchor",root,new Vector2(0,-250),new Vector2(300,450));
                Node("SpineAnchor",b.RoleAnchor,Vector2.zero,Vector2.zero);
                b.ShieldViewport=Viewport("ShieldViewport",root);
                b.ShieldAnchor=Node("ShieldAnchor",root,new Vector2(0,-250),new Vector2(380,480));
                b.ResultAnchor=Node("ResultAnchor",root,new Vector2(0,80),new Vector2(750,500));
                RectTransform health=Node("HpBar",root,new Vector2(0,-560),new Vector2(440,40));
                Image healthBg=health.gameObject.AddComponent<Image>();healthBg.color=new Color(.06f,.1f,.08f,1);
                b.HealthFill=Node("Fill",health,Vector2.zero,new Vector2(440,40)).gameObject.AddComponent<Image>();
                b.HealthFill.sprite=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/ui_juese/ui_juese_xuetiao.png");
                b.HealthFill.color=Color.white;b.HealthFill.type=Image.Type.Filled;
                b.HealthFill.fillMethod=Image.FillMethod.Horizontal;b.HealthFill.fillOrigin=0;b.HealthFill.fillAmount=1;
                b.HealthFill.raycastTarget=false;
                b.HealthValue=Label("Num",health,Vector2.zero,new Vector2(440,40),font,26,"");
                b.RoleName=Label("RoleName",root,new Vector2(0,-520),new Vector2(440,45),font,30,"");
                b.Status=Label("Status",root,new Vector2(0,650),new Vector2(850,70),font,34,"渡劫");
                RectTransform back=Node("Return",root,new Vector2(0,-650),new Vector2(220,60));
                Image backImage=back.gameObject.AddComponent<Image>();backImage.color=new Color(.16f,.2f,.26f,1);
                b.ReturnButton=back.gameObject.AddComponent<Button>();b.ReturnButton.targetGraphic=backImage;
                Label("Text",back,Vector2.zero,new Vector2(220,60),font,28,"返回");back.gameObject.SetActive(false);
                RectTransform[] anchors={b.CloudAnchor,b.LightningAnchor,b.RoleAnchor,b.ShieldAnchor,b.ResultAnchor,health,b.RoleName.rectTransform,b.Status.rectTransform,back};
                float[] heights={.82f,.45f,.35f,.35f,.5f,.13f,.18f,.94f,.06f};
                for(int index=0;index<anchors.Length;index++)
                {
                    anchors[index].anchorMin=anchors[index].anchorMax=new Vector2(.5f,heights[index]);
                    anchors[index].anchoredPosition=Vector2.zero;
                }
                b.CloudPrefab=Effect("fx_ui_dujie");b.LightningPrefab=Effect("fx_skill_XuanLeiTianJue1");
                b.ShieldPrefab=Effect("fx_buff_JinZhongShenJi");b.SuccessPrefab=Effect("fx_ui_JingJieTuPo");
                Material composite=AssetDatabase.LoadAssetAtPath<Material>("Assets/Art/Effects/Materials/DuJieComposite.mat");
                if(composite==null)throw new FileNotFoundException("DuJie compositing material is missing.");
                b.CloudViewport.material=b.ShieldViewport.material=composite;
                Directory.CreateDirectory(Path.GetDirectoryName(PrefabPath));
                PrefabUtility.SaveAsPrefabAsset(root.gameObject,PrefabPath);
            }
            finally { UnityEngine.Object.DestroyImmediate(root.gameObject); }
        }

        private static GameObject Effect(string name) => AssetDatabase.LoadAssetAtPath<GameObject>(Effects+name+".prefab")
            ?? throw new FileNotFoundException("DuJie effect is missing: "+name);

        private static RectTransform Node(string name,Transform parent,Vector2 position,Vector2 size)
        {
            var node=new GameObject(name,typeof(RectTransform));var rect=node.GetComponent<RectTransform>();
            rect.SetParent(parent,false);rect.anchorMin=rect.anchorMax=new Vector2(.5f,.5f);
            rect.pivot=new Vector2(.5f,.5f);rect.anchoredPosition=position;rect.sizeDelta=size;return rect;
        }
        private static RawImage Viewport(string name,Transform parent)
        {
            RectTransform rect=Node(name,parent,Vector2.zero,new Vector2(960,1440));
            rect.anchorMin=Vector2.zero;rect.anchorMax=Vector2.one;rect.sizeDelta=Vector2.zero;
            var image=rect.gameObject.AddComponent<RawImage>();image.raycastTarget=false;image.enabled=false;return image;
        }
        private static Text Label(string name,Transform parent,Vector2 position,Vector2 size,Font font,int fontSize,string value)
        {
            Text text=Node(name,parent,position,size).gameObject.AddComponent<Text>();text.font=font;
            text.fontSize=fontSize;text.color=Color.white;text.alignment=TextAnchor.MiddleCenter;
            text.text=value;text.raycastTarget=false;return text;
        }

        private static void Register(GameObject prefab)
        {
            const string refPath="Assets/Prefabs/Catalog/DuJieLayer.asset";
            var reference=AssetDatabase.LoadAssetAtPath<UiPrefabReference>(refPath);
            if(reference==null){reference=ScriptableObject.CreateInstance<UiPrefabReference>();AssetDatabase.CreateAsset(reference,refPath);}
            reference.SetPrefab(prefab);EditorUtility.SetDirty(reference);AssetDatabase.SaveAssetIfDirty(reference);
            var catalog=AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>("Assets/Prefabs/Catalog/Catalog.asset");
            if(!catalog.Entries.Any(entry=>entry.Key=="DuJieLayer"))
            {
                catalog.Replace(catalog.Entries.Concat(new[]{new UiPrefabCatalogEntry("DuJieLayer","Unity/DuJieLayer",null,false)}).ToArray());
                EditorUtility.SetDirty(catalog);AssetDatabase.SaveAssetIfDirty(catalog);
            }
            string settings=Path.GetFullPath("ProjectSettings/ProjectXAssetReferences.json");
            JArray entries=JArray.Parse(File.ReadAllText(settings));
            entries.Where(entry=>(string)entry["key"]=="UiPrefabs/DuJieLayer").ToList().ForEach(entry=>entry.Remove());
            entries.Add(new JObject{["key"]="UiPrefabs/DuJieLayer",["guid"]=AssetDatabase.AssetPathToGUID(refPath)});
            File.WriteAllText(settings,entries.ToString(Newtonsoft.Json.Formatting.Indented)+"\n");
            UnityNativeUiAssetValidator.RebuildResourceReference("UiPrefabs/DuJieLayer");
        }
    }
}

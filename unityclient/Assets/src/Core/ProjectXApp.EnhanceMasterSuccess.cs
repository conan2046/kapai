using System.Collections;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private const string EnhanceMasterSuccessPopupKey = "EnhanceMasterSuccessPopup";

        private void ShowEnhanceMasterSuccessPopup(int type, int level)
        {
            if (type < 1 || type > 6 || level <= 0) return;

            EquipmentMasterDefinition current = services.EquipmentCatalog.GetMaster(type, level);
            if (current == null)
            {
                SetStatus($"强化大师数据缺失：类型{type} 等级{level}");
                return;
            }

            EquipmentMasterDefinition previous = level > 1
                ? services.EquipmentCatalog.GetMaster(type, level - 1) : null;
            UnityUiView view = services.UiAssets.InstantiateUnity(
                EnhanceMasterSuccessPopupKey, GetDynamicUiRoot());

            string[] masterNames =
            {
                "强化大师", "精炼大师", "觉醒大师", "神铸大师", "法宝强化大师", "法宝精炼大师"
            };
            SetEnhanceMasterSuccessText(view, "dashidacheng/jichushuxing/name_1",
                $"{masterNames[type - 1]} {level - 1}级");
            SetEnhanceMasterSuccessText(view, "dashidacheng/jichushuxing/name_2",
                $"{masterNames[type - 1]} {level}级");

            int[][] currentAttributes = current.Attributes ?? System.Array.Empty<int[]>();
            int[][] previousAttributes = previous != null
                ? previous.Attributes ?? System.Array.Empty<int[]>() : System.Array.Empty<int[]>();
            for (int index = 0; index < 4; index++)
            {
                string rowPath = $"dashidacheng/jichushuxing/Atrribute_{index + 1}";
                GameObject row = view.FindNode(rowPath);
                if (row == null)
                    throw new System.InvalidOperationException($"EnhanceMaster success row is missing: {rowPath}");

                if (index >= currentAttributes.Length || currentAttributes[index] == null
                    || currentAttributes[index].Length < 2)
                {
                    row.SetActive(false);
                    continue;
                }

                int attributeType = currentAttributes[index][0];
                int currentValue = currentAttributes[index][1];
                int previousValue = FindMasterAttributeValue(previousAttributes, attributeType);
                row.SetActive(true);
                SetEnhanceMasterSuccessText(view, rowPath,
                    MasterAttributeName(attributeType) + "：");
                SetEnhanceMasterSuccessText(view, rowPath + "/Value_1", $"+{previousValue}");
                SetEnhanceMasterSuccessText(view, rowPath + "/Value_2", $"+{currentValue}");
                SetEnhanceMasterSuccessText(view, rowPath + "/Value_3", (currentValue - previousValue).ToString());
            }

            view.FindNode("dashidacheng/jichushuxing/name_1/Level")?.SetActive(false);
            view.FindNode("dashidacheng/jichushuxing/name_2/Level")?.SetActive(false);
            view.ShowPopup();
            Animator animator = view.GameObject.GetComponent<Animator>();
            if (animator == null)
                throw new System.InvalidOperationException("EnhanceMaster success Prefab has no Unity Animator.");
            animator.Play("animation0", 0, 0f);
            StartCoroutine(HideEnhanceMasterSuccessPopup(view));
        }

        private IEnumerator HideEnhanceMasterSuccessPopup(UnityUiView view)
        {
            yield return new WaitForSecondsRealtime(2.05f);
            services?.UiAssets?.Release(view);
        }

        private static int FindMasterAttributeValue(int[][] attributes, int type)
        {
            foreach (int[] attribute in attributes)
                if (attribute != null && attribute.Length > 1 && attribute[0] == type)
                    return attribute[1];
            return 0;
        }

        private static void SetEnhanceMasterSuccessText(UnityUiView view, string path, string value)
        {
            GameObject node = view.FindNode(path);
            Text text = node != null ? node.GetComponent<Text>() : null;
            if (text == null)
                throw new System.InvalidOperationException($"EnhanceMaster success Text binding is missing: {path}");
            text.text = value;
        }
    }
}

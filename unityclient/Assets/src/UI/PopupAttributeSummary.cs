using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>Two attributes per authored row, with scrolling for longer summaries.</summary>
    public sealed class PopupAttributeSummary : MonoBehaviour
    {
        [SerializeField] private RectTransform rowTemplate;
        [SerializeField] private ScrollRect scroll;
        [SerializeField] private Text empty;
        [SerializeField] private Text note;
        private readonly List<GameObject> rows = new List<GameObject>();

        public void Show(IReadOnlyList<string> attributes, string footer)
        {
            if (attributes == null) attributes = Array.Empty<string>();
            rowTemplate.gameObject.SetActive(false);
            int count = (attributes.Count + 1) / 2;
            while (rows.Count < count)
            {
                var row = Instantiate(rowTemplate.gameObject, rowTemplate.parent, false);
                row.name = "AttributeRow_" + rows.Count;
                rows.Add(row);
            }
            for (int i = 0; i < rows.Count; i++)
            {
                rows[i].SetActive(i < count);
                if (i >= count) continue;
                rows[i].transform.Find("Left").GetComponent<Text>().text = attributes[i * 2];
                var right = rows[i].transform.Find("Right").GetComponent<Text>();
                bool hasRight = i * 2 + 1 < attributes.Count;
                right.gameObject.SetActive(hasRight);
                right.text = hasRight ? attributes[i * 2 + 1] : string.Empty;
            }
            empty.gameObject.SetActive(attributes.Count == 0);
            note.text = footer ?? string.Empty;
            gameObject.SetActive(true);
            Canvas.ForceUpdateCanvases();
            scroll.verticalNormalizedPosition = 1f;
        }
    }
}

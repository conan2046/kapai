using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>Only switches authored states. Geometry and styling belong to the prefabs.</summary>
    public sealed class DongFuScreen : MonoBehaviour
    {
        [SerializeField] private GameObject[] pages;
        [SerializeField] private Button[] navigation;
        [SerializeField] private GameObject[] selectedStates;
        [SerializeField] private Button[] homeEntries;
        [SerializeField] private Button back;
        [SerializeField] private Button close;
        [SerializeField] private Button help;
        [SerializeField] private GameObject helpDialog;
        [SerializeField] private Button helpClose;
        [SerializeField] private Text title;
        [SerializeField] private string[] pageTitles;
        public event Action CloseRequested;
        public event Action GardenRequested;
        public event Action BecameVisible;
        public int CurrentPage { get; private set; }

        private void Awake()
        {
            for (int i = 0; i < navigation.Length; i++)
            {
                int page = i;
                navigation[i].onClick.AddListener(() => ShowPage(page));
            }
            for (int i = 0; i < homeEntries.Length; i++)
            {
                int page = i + 1;
                homeEntries[i].onClick.AddListener(() => ShowPage(page));
            }
            if(back!=null)back.onClick.AddListener(Back);
            if(close!=null)close.onClick.AddListener(() => CloseRequested?.Invoke());
            if(help!=null)help.onClick.AddListener(ShowHelp);
            helpClose.onClick.AddListener(() => helpDialog.SetActive(false));
        }

        private void OnEnable() => BecameVisible?.Invoke();
        public void ShowHelp() => helpDialog.SetActive(true);
        public void BindSharedTitle(Text value)
        {
            title = value;
            title.text = pageTitles[CurrentPage];
        }

        public void ShowPage(int page)
        {
            if (page < 0 || page >= pages.Length) throw new ArgumentOutOfRangeException(nameof(page));
            if (page == 1 && GardenRequested != null) { GardenRequested.Invoke(); return; }
            CurrentPage = page;
            for (int i = 0; i < pages.Length; i++)
            {
                pages[i].SetActive(i == page);
                selectedStates[i].SetActive(i == page);
            }
            if(title!=null)title.text = pageTitles[page];
            helpDialog.SetActive(false);
        }

        public void Back()
        {
            if (helpDialog.activeSelf) helpDialog.SetActive(false);
            else if (CurrentPage != 0) ShowPage(0);
            else CloseRequested?.Invoke();
        }
    }
}

using System;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    // Exercises production presentation and acknowledgement state without an
    // account or database. This is not a replacement for in-game click QA.
    public static class HeroBuildPresentationValidation
    {
        public static void RunBatch()
        {
            GameObject host = null;
            try
            {
                host = new GameObject("HeroBuildValidation", typeof(RectTransform), typeof(Canvas));
                ((RectTransform)host.transform).sizeDelta = new Vector2(1334, 750);
                int requests = 0, sentHero = 0, sentBranch = 0;
                var presenter = new HeroBuildPresenter(host.transform,
                    Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"),
                    (hero, branch, strategy) => { requests++; sentHero = hero; sentBranch = branch; });
                for (int hero = 10; hero <= 68; hero++)
                {
                    var detail = HeroBuildDetailCatalog.Find(hero);
                    Require(detail != null && detail.skills.Length == 4, "Four skill slots: " + hero);
                    Require(detail.artifact_a > 0 && detail.artifact_b > 0 && detail.set_a > 0 && detail.set_b > 0,
                        "Both equipment recommendations: " + hero);
                    presenter.Open(hero);
                    var panel = host.transform.Find("HeroBuildPanel");
                    var a = panel.Find("Branch1").GetComponent<Button>();
                    var b = panel.Find("Branch2").GetComponent<Button>();
                    Require(!a.interactable && !b.interactable, "Pending query must lock choices");
                    presenter.Receive(hero, 0, 1, "", string.Join(";", detail.skills.Select(s => s.id + ":10")));
                    Require(a.interactable && b.interactable, "Acknowledged choices must unlock");
                    string text = panel.Find("Descriptions/Content").GetComponent<Text>().text;
                    Require(!text.Contains("待开放") && !text.Contains("缺少") && text.Contains("Lv.10"), "Live skill descriptions: " + hero);
                    Require(text.Contains("2件：") && text.Contains("4件：") && text.Contains("同品质"), "Equipment details: " + hero);
                    int before = requests;
                    a.onClick.Invoke();
                    Require(requests == before + 1 && sentHero == hero && sentBranch == 1 && !a.interactable, "Save A request");
                    b.onClick.Invoke();
                    Require(requests == before + 1, "Concurrent save must be ignored");
                    presenter.Receive(hero, 1, 1, "");
                    Require(a.interactable, "Save acknowledgement");
                    presenter.Close();
                    Require(!presenter.IsShowing(hero), "Close must hide panel");
                }
                Debug.Log("[HeroBuildPresentationValidation] PASS 59 heroes, 236 skills, both builds, equipment values, pending/save/ack/close. In-game raycast and persistence not covered.");
                UnityEngine.Object.DestroyImmediate(host);
                EditorApplication.Exit(0);
            }
            catch (Exception error)
            {
                Debug.LogError("[HeroBuildPresentationValidation] " + error);
                if (host != null) UnityEngine.Object.DestroyImmediate(host);
                EditorApplication.Exit(1);
            }
        }

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message);
        }
    }
}

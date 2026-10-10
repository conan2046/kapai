using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.Serialization;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>Non-Play ownership predicates on disposable views; no game services constructor or UI actions.</summary>
    public static class PlayerHubOwnershipTests
    {
        public static string Run()
        {
            if (Application.isPlaying) throw new InvalidOperationException("Ownership unit test requires non-Play Editor.");
            var passed = new List<string>();
            Action<string, bool> check = (name, success) =>
            {
                if (!success) throw new InvalidOperationException("Ownership regression: " + name);
                passed.Add(name);
            };
            ProjectXApp originalInstance = ProjectXApp.Instance;
            var root = new GameObject("PlayerHubOwnershipTest-" + Guid.NewGuid().ToString("N"))
                { hideFlags = HideFlags.HideAndDontSave };
            var host = new GameObject("inactive-app") { hideFlags = HideFlags.HideAndDontSave };
            host.SetActive(false);
            host.transform.SetParent(root.transform, false);
            ProjectXApp app = host.AddComponent<ProjectXApp>();
            const BindingFlags fields = BindingFlags.Instance | BindingFlags.NonPublic;
            Action<string, object> set = (name, value) => typeof(ProjectXApp).GetField(name, fields).SetValue(app, value);
            try
            {
                check("test-app-never-initializes-live-services", typeof(ProjectXApp).GetField("services", fields).GetValue(app) == null
                    && ReferenceEquals(originalInstance, ProjectXApp.Instance));
                // Only UiStack is needed. Bypass the services constructor, which would open Lua/assets.
                var services = (GameServices)FormatterServices.GetUninitializedObject(typeof(GameServices));
                var stack = new UiStack();
                typeof(GameServices).GetField("<UiStack>k__BackingField", fields).SetValue(services, stack);
                set("services", services);
                UnityUiView main = View("main", root.transform);
                UnityUiView frame = View("frame", root.transform);
                UnityUiView jingjie = View("jingjie", frame.GameObject.transform);
                UnityUiView bag = View("bag", frame.GameObject.transform);
                UnityUiView hero = View("hero", frame.GameObject.transform);
                UnityUiView mail = View("mail", frame.GameObject.transform);
                UnityUiView settings = View("settings", frame.GameObject.transform);
                set("oneLevelFrameView", frame);
                set("jingJieView", jingjie);
                set("bagView", bag);
                set("heroListView", hero);
                set("mailView", mail);
                set("settingsView", settings);
                set("heroHubOpen", true); // Retained tab intent must not take ownership of another page.
                Func<bool> presentHero = () => (bool)typeof(ProjectXApp).GetProperty(
                    "ShouldPresentHeroHubFromSnapshot", fields).GetValue(app);
                stack.SetRoot(main);
                frame.SetVisible(false);
                jingjie.SetVisible(false);
                bag.SetVisible(false);
                mail.SetVisible(false);
                settings.SetVisible(false);
                check("main-is-not-a-hero-surface", !app.IsHeroOpen && !presentHero());
                stack.Push(frame);
                check("hero-frame-retains-snapshot-ownership", app.IsHeroOpen && presentHero());
                hero.SetVisible(false);
                bag.SetVisible(true);
                set("jingJieSurfaceMode", PlayerHubTab.Bag);
                check("embedded-bag-remains-player-hub", app.IsBagOpen && app.IsJingJieBagSurfaceActive);
                check("embedded-bag-is-not-hero", !app.IsHeroOpen);
                check("stale-hero-intent-cannot-steal-bag", !presentHero());
                var store = new BagStore();
                int notifications = 0;
                store.Changed += () => notifications++;
                store.Replace(new[] { new BagItemRecord(1, 500, 3, "fixture", "", 0, 1, 1, 0, 1) });
                check("authoritative-store-still-notifies-with-bag-owner", notifications == 1 && store.GetQuantity(1) == 3
                    && app.IsJingJieBagSurfaceActive && !presentHero());
                bag.SetVisible(false);
                jingjie.SetVisible(true);
                set("jingJieSurfaceMode", PlayerHubTab.JingJie);
                check("jingjie-is-not-hero", app.IsJingJieOpen && !app.IsHeroOpen && !presentHero());
                jingjie.SetVisible(false);
                mail.SetVisible(true);
                set("jingJieSurfaceMode", PlayerHubTab.Mail);
                check("mail-tab-keeps-player-hub-ownership", app.IsJingJieOpen && !app.IsHeroOpen && !presentHero());
                mail.SetVisible(false);
                settings.SetVisible(true);
                set("jingJieSurfaceMode", PlayerHubTab.Settings);
                check("settings-tab-keeps-player-hub-ownership", app.IsJingJieOpen && !app.IsHeroOpen && !presentHero());
                set("heroEntryRequestPending", true);
                check("explicit-hero-entry-remains-authorized", presentHero());
                set("heroEntryRequestPending", false);
                stack.Pop();
                check("return-to-main-removes-frame-ownership", ReferenceEquals(stack.Current, main)
                    && !app.IsHeroOpen && !presentHero());
                check("cached-active-child-is-not-visible", hero.GameObject.activeSelf == false
                    && settings.GameObject.activeSelf && !settings.GameObject.activeInHierarchy);
            }
            finally
            {
                // The disposable app must never run cleanup against the deliberately partial services fixture.
                set("services", null);
                UnityEngine.Object.DestroyImmediate(root);
            }
            check("live-app-instance-is-preserved", ReferenceEquals(originalInstance, ProjectXApp.Instance));
            return JsonUtility.ToJson(new Result { passed = passed.ToArray() }, true);
        }

        private static UnityUiView View(string name, Transform parent)
        {
            var node = new GameObject(name) { hideFlags = HideFlags.HideAndDontSave };
            node.transform.SetParent(parent, false);
            return new UnityUiView(node);
        }

        [Serializable]
        private sealed class Result { public string[] passed; }
    }
}

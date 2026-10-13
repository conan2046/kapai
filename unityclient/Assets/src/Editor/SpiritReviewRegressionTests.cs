using System;
using System.IO;
using System.Linq;
using System.Reflection;
using ProjectX.Core;
using ProjectX.Data;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class SpiritReviewRegressionTests
    {
        // Runs outside Play: no network, real UI, configuration or save mutations.
        public static string Run()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
                throw new InvalidOperationException("Run Spirit regressions outside Play.");
            CheckRecovery();
            CheckBagRequests();
            return "PASS: failed upgrade recovery, read backoff, full-storage stop, explicit bag entry and unsolicited bag snapshots.";
        }

        private static void CheckRecovery()
        {
            var host = new GameObject("SpiritRecoveryTest") { hideFlags = HideFlags.HideAndDontSave };
            host.SetActive(false);
            try
            {
                var app = host.AddComponent<ProjectXApp>();
                const BindingFlags flags = BindingFlags.Instance | BindingFlags.NonPublic;
                var schedule = typeof(ProjectXApp).GetMethod("ScheduleSpiritProduction", flags);
                var nextPoll = typeof(ProjectXApp).GetField("spiritNextPoll", flags);
                var state = new SpiritEnvelope {
                    Configured = true, Unlocked = true, Spirit = "100", Storage = "100",
                    ProductionPeriodMs = 5000, Operation = 2, Error = "升级材料不足"
                };
                Action apply = () => schedule.Invoke(app, new object[] { state });
                Func<float> delay = () => (float)nextPoll.GetValue(app) - Time.realtimeSinceStartup;
                apply();
                if (!(delay() >= 0 && delay() <= 2)) throw new Exception("Failed mutation never resynchronizes at full storage.");
                state.Operation = 0;
                apply();
                if (!(delay() >= 4 && delay() <= 6)) throw new Exception("Read failure lacks bounded retry backoff.");
                state.Error = null;
                apply();
                if (!float.IsPositiveInfinity((float)nextPoll.GetValue(app))) throw new Exception("Healthy full storage keeps polling.");
                state.Spirit = "50";
                state.ProductionElapsedMs = 3000;
                apply();
                if (!(delay() > 0 && delay() <= 3)) throw new Exception("Production did not resume after a successful read.");
            }
            finally { UnityEngine.Object.DestroyImmediate(host); }
        }

        private static void CheckBagRequests()
        {
            var luaType = AppDomain.CurrentDomain.GetAssemblies()
                .Select(a => a.GetType("XLua.LuaEnv")).First(t => t != null);
            var environment = Activator.CreateInstance(luaType);
            try
            {
                string source = File.ReadAllText(Path.Combine(Application.dataPath, "Resources/Lua/Bag/BagController.lua.txt"));
                string setup = @"
package.preload['Protocol'] = function() return {ROLE_PACKAGE=8, newMessage=function() return {} end} end
package.preload['Data.ItemCatalog'] = function() return {} end
Bridge = {spirit=true, header=0, full=0, completed=0, sent=0}
function Bridge:IsSpiritActive() return self.spirit end
function Bridge:IsDrawActive() return false end
function Bridge:IsAutomation() return false end
function Bridge:GetBagCount() return 0 end
function Bridge:BeginBagHeaderUpdate() self.header=self.header+1 end
function Bridge:EndBagHeaderUpdate() end
function Bridge:BeginBagUpdate() self.full=self.full+1 end
function Bridge:EndBagUpdate() self.spirit=false end
function Bridge:Complete() self.completed=self.completed+1 end
function Bridge:Send() self.sent=self.sent+1 end
local module = (function()
";
                string assertions = @"
end)()
local packet={Remaining=0,ReadWord=function() return 0 end}
assert(module.onPacket(8,packet), 'Unsolicited snapshot was not consumed')
assert(Bridge.header==1 and Bridge.full==0 and Bridge.completed==0 and Bridge.spirit, 'Background snapshot opened the bag')
module.onClick()
assert(Bridge.sent==1, 'Explicit entry did not request a package')
assert(module.onPacket(8,packet), 'Explicit entry response was not consumed')
assert(Bridge.full==1 and Bridge.completed==1 and not module.requested and not Bridge.spirit, 'Spirit swallowed an explicit bag entry')
";
                var execute = luaType.GetMethods().First(m => m.Name == "DoString"
                    && m.GetParameters().Length == 3 && m.GetParameters()[0].ParameterType == typeof(string));
                execute.Invoke(environment, new object[] { setup + source + assertions, "SpiritBagRegression", null });
            }
            finally { ((IDisposable)environment).Dispose(); }
        }
    }
}

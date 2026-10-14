using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        const string DongFuDot = "dongfu";
        const string DongFuReadPrefix = "dongfu-dot-";
        static readonly ushort[] DongFuReadCommands = { 324, 325, 326, 327 };
        readonly Dictionary<ushort, string> dongFuDotPending = new Dictionary<ushort, string>();
        readonly Dictionary<ushort, float> dongFuDotDeadlines = new Dictionary<ushort, float>();
        readonly Dictionary<ushort, float> dongFuDotNext = new Dictionary<ushort, float>();
        GardenEnvelope dongFuDotGarden;
        SpiritEnvelope dongFuDotSpirit;
        LibraryEnvelope dongFuDotLibrary;
        AlchemyEnvelope dongFuDotAlchemy;
        LibraryCatalogData dongFuDotBooks;
        float dongFuDotAlchemyReceived, dongFuDotTick;
        int dongFuDotSession = -1;
        uint dongFuDotRole;
        bool dongFuDotsSubscribed;

        void InitializeDongFuRedDots()
        {
            redDots.Define(DongFuDot);
            for (int i = 0; i < 5; i++) redDots.Define(DongFuDot + "." + i, DongFuDot);
            redDots.SetEnabled(DongFuDot + ".3", false);
            dongFuDotBooks = new LibraryCatalogData();
            redDots.Changed += RenderDongFuRedDots;
            services.Player.Changed += InvalidateDongFuReminderReads;
            services.Currencies.Changed += InvalidateDongFuReminderReads;
            services.Bag.Changed += InvalidateDongFuReminderReads;
            services.JingJie.Changed += InvalidateDongFuReminderReads;
            dongFuDotsSubscribed = true;
            RenderDongFuRedDots();
        }

        void InvalidateDongFuReminderReads()
        {
            if (!dongFuDotsSubscribed) return;
            foreach (ushort command in DongFuReadCommands) dongFuDotNext[command] = 0;
        }

        void ResetDongFuReminderState()
        {
            dongFuDotPending.Clear(); dongFuDotDeadlines.Clear(); dongFuDotNext.Clear();
            dongFuDotGarden = null; dongFuDotSpirit = null;
            dongFuDotLibrary = null; dongFuDotAlchemy = null;
            for (int i = 0; i < 5; i++) redDots.Set(DongFuDot + "." + i, false);
            RenderDongFuRedDots();
        }

        bool EnsureDongFuReminderSession()
        {
            if (!dongFuDotsSubscribed || services == null) return false;
            uint role = services.Network.IsConnected && services.Player.IsLoaded ? services.Player.RoleId : 0;
            if (dongFuDotSession != services.Network.SessionVersion || dongFuDotRole != role)
            {
                dongFuDotSession = services.Network.SessionVersion; dongFuDotRole = role;
                ResetDongFuReminderState();
            }
            return role != 0;
        }

        void TickDongFuRedDots()
        {
            if (!EnsureDongFuReminderSession()) return;
            float now = Time.realtimeSinceStartup;
            if (now < dongFuDotTick) return;
            dongFuDotTick = now + .25f;
            RefreshDongFuRedDots();
            foreach (ushort command in DongFuReadCommands)
            {
                bool pageOpen = command == 324 ? IsGardenOpen : command == 325 ? IsSpiritOpen
                    : command == 326 ? IsLibraryOpen : IsAlchemyOpen || IsAlchemyShopOpen;
                if (pageOpen) continue;
                if (dongFuDotPending.ContainsKey(command))
                {
                    if (now < dongFuDotDeadlines[command]) continue;
                    dongFuDotPending.Remove(command); dongFuDotNext[command] = now + 5;
                }
                if (dongFuDotNext.TryGetValue(command, out float due) && now < due) continue;
                string id = DongFuReadPrefix + Guid.NewGuid().ToString("N");
                var payload = new JObject { ["request_id"] = id, ["revision"] = "0" };
                var packet = LegacyTcpMessage.New(); packet.WriteWord(command); packet.WriteByte(0);
                packet.WriteString(payload.ToString(Formatting.None));
                dongFuDotPending[command] = id; dongFuDotDeadlines[command] = now + 8;
                try { services.Network.Send(packet); }
                catch { dongFuDotPending.Remove(command); dongFuDotNext[command] = now + 5; }
            }
        }

        // Garden's legacy read response deliberately has an empty request ID.
        // Other modules echo a separate ID, so background reads cannot clear page actions.
        bool HandleDongFuReminderRead(ushort command, string request, object state)
        {
            bool tagged = request?.StartsWith(DongFuReadPrefix, StringComparison.Ordinal) == true;
            bool gardenRead = command == 324 && string.IsNullOrEmpty(request) && dongFuDotPending.ContainsKey(command);
            if (!tagged && !gardenRead) return false;
            if (!EnsureDongFuReminderSession() || !dongFuDotPending.TryGetValue(command, out string expected)
                || (!gardenRead && expected != request)) return true;
            dongFuDotPending.Remove(command);
            RecordDongFuReminder(command, state);
            dongFuDotNext[command] = Time.realtimeSinceStartup + (command == 326 ? 10 : 2);
            return true;
        }

        static bool OlderReminder(string candidate, string current) =>
            long.TryParse(candidate, out long a) && long.TryParse(current, out long b) && a < b;

        void RecordDongFuReminder(ushort command, object snapshot)
        {
            if (!EnsureDongFuReminderSession()) return;
            if (command == 324 && snapshot is GardenEnvelope garden && string.IsNullOrEmpty(garden.Error))
                dongFuDotGarden = garden;
            else if (command == 325 && snapshot is SpiritEnvelope spirit && string.IsNullOrEmpty(spirit.Error)
                && !OlderReminder(spirit.Revision, dongFuDotSpirit?.Revision)) dongFuDotSpirit = spirit;
            else if (command == 326 && snapshot is LibraryEnvelope library && string.IsNullOrEmpty(library.Error)
                && !OlderReminder(library.Revision, dongFuDotLibrary?.Revision)) dongFuDotLibrary = library;
            else if (command == 327 && snapshot is AlchemyEnvelope alchemy && string.IsNullOrEmpty(alchemy.Error)
                && !OlderReminder(alchemy.Revision, dongFuDotAlchemy?.Revision))
            {
                dongFuDotAlchemy = alchemy; dongFuDotAlchemyReceived = Time.realtimeSinceStartup;
            }
            RefreshDongFuRedDots();
        }

        void RefreshDongFuRedDots()
        {
            redDots.Set(DongFuDot + ".0", dongFuDotGarden?.Plots?.Any(DongFuReminderRules.Harvest) == true);
            redDots.Set(DongFuDot + ".1", DongFuReminderRules.SpiritFull(dongFuDotSpirit)
                || dongFuDotSpirit?.Roots?.Any(r => DongFuReminderRules.RootUpgrade(dongFuDotSpirit, r)) == true);
            long alchemyNow = long.TryParse(dongFuDotAlchemy?.Server, out long server)
                ? server + (long)((Time.realtimeSinceStartup - dongFuDotAlchemyReceived) * 1000) : 0;
            redDots.Set(DongFuDot + ".2", DongFuReminderRules.AlchemyClaim(dongFuDotAlchemy, alchemyNow));
            redDots.Set(DongFuDot + ".4", dongFuDotBooks.Rewards.Values.Any(r => dongFuDotBooks.Eligible(dongFuDotLibrary, r)));
            RenderDongFuRedDots();
        }

        void RenderDongFuRedDots()
        {
            if (!dongFuDotsSubscribed || services == null) return;
            RedDotVisual.SetAuthored(FindMainHudNode("Layer/Bg/btn_donfu")?.transform, redDots.IsVisible(DongFuDot));
            for (int i = 0; i < 5; i++)
                RedDotVisual.SetAuthored(dongFuView?.GameObject?.transform.Find("Building" + i), redDots.IsVisible(DongFuDot + "." + i));
        }

        void DisposeDongFuRedDots()
        {
            if (!dongFuDotsSubscribed) return;
            services.Player.Changed -= InvalidateDongFuReminderReads;
            services.Currencies.Changed -= InvalidateDongFuReminderReads;
            services.Bag.Changed -= InvalidateDongFuReminderReads;
            services.JingJie.Changed -= InvalidateDongFuReminderReads;
            redDots.Changed -= RenderDongFuRedDots;
            dongFuDotsSubscribed = false;
        }
    }
}

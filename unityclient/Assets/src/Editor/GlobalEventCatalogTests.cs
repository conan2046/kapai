using System;
using Newtonsoft.Json.Linq;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.Foundation;
using UnityEngine;

namespace ProjectX.Editor
{
    // Real configuration readers; no account, save or network changes.
    public static class GlobalEventCatalogTests
    {
        public static string Run()
        {
            ResourceLoader.Configure(new UnityResourceLoader());
            var events = new GlobalEventCatalog();
            var store = new TaskStore(new ConfigService(), new EquipmentCatalog(), events);
            var asset = Resources.Load<TextAsset>("ProjectXData/Configs/daily");
            if (asset == null) throw new InvalidOperationException("Missing real daily config.");
            var rows = JArray.Parse(asset.text);
            if (rows.Count != 148 || events.Count != 162)
                throw new InvalidOperationException("Unexpected formal task/event count.");
            foreach (JObject row in rows)
            {
                int id = row.Value<int>("id");
                var record = store.CreateRecord(id, 0, 0);
                if (row["condition"] != null || record.Definition == null ||
                    !ReferenceEquals(events.Get(row.Value<int>("event_id")), record.Definition.Event) ||
                    record.Target != record.Definition.Event.Target)
                    throw new InvalidOperationException("Task does not resolve shared event: " + id);
            }
            if (events.Get(1001).Type != 7)
                throw new InvalidOperationException("Strengthen event type changed.");
            bool rejected = false;
            try { events.Get(1015); } catch (InvalidOperationException) { rejected = true; }
            if (!rejected) throw new InvalidOperationException("Disabled task example was published.");
            return "PASS: 148 real task definitions resolve shared catalog instances, 162 enabled events, no inline conditions, disabled task example absent.";
        }
    }
}

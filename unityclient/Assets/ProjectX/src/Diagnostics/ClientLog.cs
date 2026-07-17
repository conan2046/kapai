using System;
using System.Collections.Generic;
using UnityEngine;

namespace ProjectX.Diagnostics
{
    public readonly struct ClientLogEntry
    {
        public ClientLogEntry(DateTime utc, LogType level, string module, string message, string context)
        {
            Utc = utc;
            Level = level;
            Module = module;
            Message = message;
            Context = context;
        }

        public DateTime Utc { get; }
        public LogType Level { get; }
        public string Module { get; }
        public string Message { get; }
        public string Context { get; }
    }

    public static class ClientLog
    {
        private const int Capacity = 200;
        private static readonly Queue<ClientLogEntry> Entries = new Queue<ClientLogEntry>(Capacity);

        public static IReadOnlyCollection<ClientLogEntry> Recent => Entries;

        public static void Info(string module, string message, string context = null) => Write(LogType.Log, module, message, context);
        public static void Warning(string module, string message, string context = null) => Write(LogType.Warning, module, message, context);
        public static void Error(string module, string message, string context = null) => Write(LogType.Error, module, message, context);

        private static void Write(LogType level, string module, string message, string context)
        {
            string safeModule = string.IsNullOrWhiteSpace(module) ? "General" : module;
            string safeMessage = message ?? string.Empty;
            var entry = new ClientLogEntry(DateTime.UtcNow, level, safeModule, safeMessage, context ?? string.Empty);
            while (Entries.Count >= Capacity) Entries.Dequeue();
            Entries.Enqueue(entry);
            string line = $"[ProjectX][{safeModule}] {safeMessage}"
                + (string.IsNullOrEmpty(context) ? string.Empty : $" | {context}");
            if (level == LogType.Error || level == LogType.Exception) Debug.LogError(line);
            else if (level == LogType.Warning) Debug.LogWarning(line);
            else Debug.Log(line);
        }
    }
}

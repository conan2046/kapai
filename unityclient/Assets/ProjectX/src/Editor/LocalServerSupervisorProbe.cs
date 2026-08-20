using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Threading;
using ProjectX.Core;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class LocalServerSupervisorProbe
    {
        [Serializable]
        private sealed class ProbeReport
        {
            public int schemaVersion = 1;
            public string generatedAt;
            public string status;
            public string missingLayout;
            public string portConflict;
            public string ownedStartup;
            public string repeatedStartup;
            public string crashDetection;
            public string loopbackBinding;
            public string writableLog;
            public string backupRotation;
            public string gracefulShutdown;
            public int maximumConcurrentKapai;
            public int residualKapai;
        }

        public static void Run()
        {
            var report = new ProbeReport { generatedAt = DateTime.UtcNow.ToString("o"), status = "Failed" };
            int exitCode = 1;
            LocalServerSupervisor owner = null;
            LocalServerSupervisor adopted = null;
            LocalServerSupervisor crashOwner = null;
            TcpListener conflict = null;
            try
            {
                string root = Directory.GetParent(Application.dataPath)?.Parent?.FullName
                    ?? throw new InvalidOperationException("Repository root could not be resolved.");
                string executable = Path.Combine(root, "build", "server-win", "Debug", "kapai.exe");
                string config = Path.Combine(root, "server", "config");
                string schema = Path.Combine(root, "server", "sql", "sqlite", "001_initial_schema.sql");
                string evidencePath = ResolveEvidencePath(root);
                Directory.CreateDirectory(Path.GetDirectoryName(evidencePath));
                EnsureNoKapai();

                using (var missing = new LocalServerSupervisor(
                    Path.Combine(root, ".local", "missing-s6", "kapai.exe"), config,
                    Path.Combine(root, ".local", "unity-validation", "s6-missing.db"), schema, 8711, 2f))
                {
                    missing.Start();
                    Require(missing.State == LocalServerState.Failed && missing.Detail.Contains("缺少本机游戏服务"),
                        "Missing-layout failure was not explicit.");
                    report.missingLayout = "Passed";
                }

                conflict = new TcpListener(IPAddress.Loopback, 8711);
                conflict.Start();
                using (var blocked = NewSupervisor(root, executable, config, schema, "s6-conflict"))
                {
                    blocked.Start();
                    Require(blocked.State == LocalServerState.Failed && blocked.Detail.Contains("端口 8711"),
                        "Port-conflict failure was not explicit.");
                    report.portConflict = "Passed";
                }
                conflict.Stop();
                conflict = null;

                owner = NewSupervisor(root, executable, config, schema, "s6-owned");
                owner.Start();
                WaitForTerminal(owner, 30f);
                Require(owner.State == LocalServerState.ReadyOwned && owner.ProcessId > 0,
                    "Supervisor did not own a ready packaged server: " + owner.Detail);
                report.ownedStartup = "Passed";
                Require(IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners()
                        .Where(endpoint => endpoint.Port == 8711)
                        .All(endpoint => IPAddress.IsLoopback(endpoint.Address)),
                    "Local server exposed port 8711 on a non-loopback address.");
                report.loopbackBinding = "Passed";
                report.maximumConcurrentKapai = CountKapai();

                adopted = NewSupervisor(root, executable, config, schema, "s6-adopted");
                adopted.Start();
                WaitForTerminal(adopted, 5f);
                Require(adopted.State == LocalServerState.ReadyAdopted, "Second supervisor did not adopt the server.");
                report.maximumConcurrentKapai = Math.Max(report.maximumConcurrentKapai, CountKapai());
                Require(report.maximumConcurrentKapai == 1, "Repeated startup created duplicate kapai processes.");
                adopted.Dispose();
                adopted = null;
                Require(CountKapai() == 1, "Adopted supervisor incorrectly stopped the owner process.");
                report.repeatedStartup = "Passed";
                owner.Dispose();
                Require(owner.GracefulShutdownCompleted, "Owning supervisor did not complete graceful shutdown.");
                Require(File.Exists(owner.LogPath)
                        && File.ReadAllText(owner.LogPath).Contains("graceful shutdown requested by owning client"),
                    "Persistent local-server log did not capture graceful shutdown.");
                report.gracefulShutdown = "Passed";
                report.writableLog = "Passed";
                owner = null;
                WaitForNoKapai(8f);

                crashOwner = NewSupervisor(root, executable, config, schema, "s6-crash");
                crashOwner.Start();
                WaitForTerminal(crashOwner, 30f);
                Require(crashOwner.State == LocalServerState.ReadyOwned, "Crash probe server was not ready.");
                Require(!string.IsNullOrWhiteSpace(crashOwner.LatestBackupPath)
                        && File.Exists(crashOwner.LatestBackupPath),
                    "Existing SQLite database was not backed up before restart.");
                report.backupRotation = "Passed";
                Process.GetProcessById(crashOwner.ProcessId).Kill();
                float crashDeadline = Time.realtimeSinceStartup + 8f;
                while (crashOwner.State != LocalServerState.Failed && Time.realtimeSinceStartup < crashDeadline)
                {
                    crashOwner.Tick();
                    Thread.Sleep(50);
                }
                Require(crashOwner.State == LocalServerState.Failed && crashOwner.Detail.Contains("异常退出"),
                    "Runtime crash was not surfaced explicitly.");
                report.crashDetection = "Passed";
                crashOwner.Dispose();
                crashOwner = null;
                WaitForNoKapai(8f);

                report.residualKapai = CountKapai();
                Require(report.residualKapai == 0, "S6 probe left kapai processes running.");
                report.status = "Passed";
                File.WriteAllText(evidencePath, JsonUtility.ToJson(report, true) + Environment.NewLine);
                UnityEngine.Debug.Log("[LocalServerSupervisorProbe] Passed: " + evidencePath);
                exitCode = 0;
            }
            catch (Exception exception)
            {
                UnityEngine.Debug.LogError("[LocalServerSupervisorProbe] " + exception);
            }
            finally
            {
                conflict?.Stop();
                adopted?.Dispose();
                owner?.Dispose();
                crashOwner?.Dispose();
                EditorApplication.Exit(exitCode);
            }
        }

        private static LocalServerSupervisor NewSupervisor(string root, string executable, string config,
            string schema, string databaseName) => new LocalServerSupervisor(executable, config,
            Path.Combine(root, ".local", "unity-validation", databaseName + ".db"), schema, 8711, 25f);

        private static void WaitForTerminal(LocalServerSupervisor supervisor, float timeoutSeconds)
        {
            float deadline = Time.realtimeSinceStartup + timeoutSeconds;
            while (!supervisor.IsTerminal && Time.realtimeSinceStartup < deadline)
            {
                supervisor.Tick();
                Thread.Sleep(50);
            }
            supervisor.Tick();
        }

        private static string ResolveEvidencePath(string root)
        {
            const string prefix = "-projectXS6Evidence=";
            string value = Environment.GetCommandLineArgs().FirstOrDefault(argument =>
                argument.StartsWith(prefix, StringComparison.OrdinalIgnoreCase));
            return string.IsNullOrWhiteSpace(value)
                ? Path.Combine(root, ".local", "unity-validation", "steam-sqlite-s6-supervisor-latest.json")
                : Path.GetFullPath(value.Substring(prefix.Length));
        }

        private static int CountKapai() => Process.GetProcessesByName("kapai").Count(process =>
        {
            try { return !process.HasExited; }
            finally { process.Dispose(); }
        });

        private static void EnsureNoKapai()
        {
            if (CountKapai() != 0) throw new InvalidOperationException("Stop kapai.exe before the S6 supervisor probe.");
        }

        private static void WaitForNoKapai(float timeoutSeconds)
        {
            DateTime deadline = DateTime.UtcNow.AddSeconds(timeoutSeconds);
            while (CountKapai() != 0 && DateTime.UtcNow < deadline) Thread.Sleep(100);
        }

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message);
        }
    }
}

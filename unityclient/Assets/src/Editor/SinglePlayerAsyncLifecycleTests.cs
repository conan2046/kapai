using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.Network;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>Fresh temporary fixtures, an owned protocol stub and ephemeral loopback sockets only.</summary>
    public static class SinglePlayerAsyncLifecycleTests
    {
        private static Task running;
        private static readonly List<string> passed = new List<string>();
        private static string failure;

        public static string Begin()
        {
            if (running != null && !running.IsCompleted) throw new InvalidOperationException("Test already running.");
            passed.Clear();
            failure = null;
            running = RunAsync();
            return Status();
        }

        public static string Status() => JsonUtility.ToJson(new Result
        {
            complete = running?.IsCompleted == true,
            passed = passed.ToArray(),
            error = failure ?? (running?.IsFaulted == true ? running.Exception.ToString() : null)
        }, true);

        private static void Check(string name, bool condition)
        {
            if (!condition) throw new InvalidOperationException("Async lifecycle regression: " + name);
            passed.Add(name);
        }

        private static async Task RunAsync()
        {
            string root = Path.Combine(Path.GetTempPath(), "ProjectX-AsyncLifecycle-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            try
            {
                int mainThread = Thread.CurrentThread.ManagedThreadId;
                var saves = new SinglePlayerSaveService(Path.Combine(root, "Saves"));
                saves.PrepareForPlay(1, true);
                saves.ResolveLocalUserId(1, true, 1);
                saves.BeginSession(1);
                byte[] original = Encoding.ASCII.GetBytes("SQLite format 3\0source-fixture");
                File.WriteAllBytes(saves.ReadSlot(1).DatabasePath, original);

                using (LocalServerSupervisor supervisor = StartStub(root))
                {
                    string staging = saves.CreateSnapshotStagingPath(2);
                    Task snapshot = supervisor.CreateSnapshotAsync(staging);
                    Task shutdown = supervisor.DisposeAsync();
                    await Task.Delay(40);
                    Check("snapshot-and-shutdown-do-not-block-caller", !snapshot.IsCompleted && !shutdown.IsCompleted);
                    Check("await-retains-unity-main-thread", Thread.CurrentThread.ManagedThreadId == mainThread);
                    await snapshot;
                    Check("snapshot-finishes-before-owned-shutdown", File.Exists(staging));
                    saves.CommitCurrentSnapshot(1, 2, staging, 42, "fixture", 1, 2, 3);
                    Check("snapshot-commit-keeps-source-database", original.SequenceEqual(File.ReadAllBytes(saves.ReadSlot(1).DatabasePath)));
                    Check("snapshot-commit-keeps-active-session", saves.ActiveSlotId == 1);
                    Check("snapshot-commit-copies-local-identity", saves.ReadSlot(2).Metadata.localUserId == saves.ReadSlot(1).Metadata.localUserId);
                    await shutdown;
                    Check("owned-stub-exits-gracefully", supervisor.GracefulShutdownCompleted && supervisor.State == LocalServerState.Stopped);
                    Check("repeated-shutdown-shares-completion", ReferenceEquals(shutdown, supervisor.DisposeAsync()));
                    bool rejected = false;
                    try { await supervisor.CreateSnapshotAsync(saves.CreateSnapshotStagingPath(3)); }
                    catch (ObjectDisposedException) { rejected = true; }
                    Check("snapshot-after-shutdown-is-rejected", rejected);
                }

                using (LocalServerSupervisor supervisor = StartStub(root))
                {
                    string bad = Path.Combine(root, "invalid.db");
                    bool rejected = false;
                    try { await supervisor.CreateSnapshotAsync(bad); }
                    catch (InvalidOperationException) { rejected = true; }
                    Check("invalid-server-snapshot-is-rejected", rejected);
                    string valid = Path.Combine(root, "valid.db");
                    await supervisor.CreateSnapshotAsync(valid);
                    Check("snapshot-failure-releases-operation-gate", File.Exists(valid));
                    var pendingSave = new TaskCompletionSource<bool>();
                    Task close = (Task)typeof(ProjectXApp).GetMethod("StopSinglePlayerServerAsync",
                        BindingFlags.Static | BindingFlags.NonPublic).Invoke(null, new object[] { supervisor, saves, pendingSave.Task });
                    await Task.Delay(20);
                    Check("app-shutdown-waits-for-accepted-save", !close.IsCompleted && saves.ActiveSlotId == 1);
                    pendingSave.SetResult(true);
                    await close;
                    Check("app-shutdown-ends-session-and-service", saves.ActiveSlotId == 0 && supervisor.State == LocalServerState.Stopped);
                }
                await CheckNetworkAsync();
                Check("all-continuations-retain-main-thread", Thread.CurrentThread.ManagedThreadId == mainThread);
            }
            catch (Exception exception) { failure = exception.ToString(); }
            finally { Directory.Delete(root, true); }
        }

        private static LocalServerSupervisor StartStub(string root)
        {
            string script = Path.Combine(root, "server-stub.ps1");
            File.WriteAllText(script, @"while ($null -ne ($line = [Console]::ReadLine())) {
  $parts = $line.Split([char]9)
  if ($parts[0] -eq 'snapshot') {
    Start-Sleep -Milliseconds 300
    $bytes = if ($parts[2].EndsWith('invalid.db')) { [byte[]](1,2,3) } else { [Text.Encoding]::ASCII.GetBytes('SQLite format 3' + [char]0 + 'isolated-stub') }
    [IO.File]::WriteAllBytes($parts[2], $bytes)
    [Console]::WriteLine('[local] snapshot' + [char]9 + $parts[1] + [char]9 + 'ok')
    [Console]::Out.Flush()
  } elseif ($parts[0] -eq 'shutdown') { Start-Sleep -Milliseconds 200; break }
}");
            var process = new Process { StartInfo = new ProcessStartInfo
            {
                FileName = @"C:\Program Files\PowerShell\7\pwsh.exe",
                Arguments = "-NoProfile -NonInteractive -File \"" + script + "\"",
                WorkingDirectory = root,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardInput = true,
                RedirectStandardOutput = true
            }};
            var supervisor = new LocalServerSupervisor("fixture.exe", root, Path.Combine(root, "fixture.db"), "fixture.sql");
            const BindingFlags fields = BindingFlags.Instance | BindingFlags.NonPublic;
            typeof(LocalServerSupervisor).GetField("process", fields).SetValue(supervisor, process);
            typeof(LocalServerSupervisor).GetField("ownsProcess", fields).SetValue(supervisor, true);
            typeof(LocalServerSupervisor).GetField("<State>k__BackingField", fields).SetValue(supervisor, LocalServerState.ReadyOwned);
            MethodInfo queue = typeof(LocalServerSupervisor).GetMethod("QueueServerLine", fields);
            process.OutputDataReceived += (_, args) => queue.Invoke(supervisor, new object[] { args.Data, false });
            process.Start();
            process.BeginOutputReadLine();
            return supervisor;
        }

        private static async Task CheckNetworkAsync()
        {
            var listener = new TcpListener(IPAddress.Loopback, 0);
            listener.Start();
            int port = ((IPEndPoint)listener.LocalEndpoint).Port;
            var sockets = new List<TcpClient>();
            var network = new NetworkService();
            try
            {
                Task<TcpClient> accepted = listener.AcceptTcpClientAsync();
                await network.ConnectAsync("127.0.0.1", port, 2);
                TcpClient oldSocket = await accepted;
                sockets.Add(oldSocket);
                // Leave an old receive suspended halfway through a header.
                await oldSocket.GetStream().WriteAsync(new byte[] { 0, 0 }, 0, 2);
                network.Disconnect();
                accepted = listener.AcceptTcpClientAsync();
                await network.ConnectAsync("127.0.0.1", port, 2);
                TcpClient newSocket = await accepted;
                sockets.Add(newSocket);
                oldSocket.Close();
                var commands = new List<ushort>();
                network.PacketReceived += (command, _) => commands.Add(command);
                byte[] packet = { 0, 0, 0, 0, 0xc8, 1 }; // command 456, empty body
                await newSocket.GetStream().WriteAsync(packet, 0, packet.Length);
                DateTime deadline = DateTime.UtcNow.AddSeconds(2);
                while (commands.Count == 0 && DateTime.UtcNow < deadline) { await Task.Delay(10); network.Tick(); }
                Check("new-session-receives-own-packet", commands.SequenceEqual(new ushort[] { 456 }));
                Check("old-receive-does-not-disconnect-new-session", network.IsConnected);
                int events = 0;
                network.StateChanged += _ => events++;
                network.Disconnect();
                Task pending = network.ConnectAsync("127.0.0.1", port, 2);
                network.Dispose();
                int eventsAfterDispose = events;
                try { await pending; } catch (Exception) { }
                Check("disposed-connect-cannot-resurrect-state", network.State == NetworkState.Idle && !network.IsConnected);
                Check("disposed-connect-emits-no-late-state-event", events == eventsAfterDispose);
                bool rejected = false;
                try { await network.ConnectAsync("127.0.0.1", port, 2); }
                catch (ObjectDisposedException) { rejected = true; }
                Check("disposed-service-rejects-reuse", rejected);
                using (var cancelled = new CancellationTokenSource())
                using (var service = new NetworkService())
                {
                    cancelled.Cancel();
                    rejected = false;
                    try { await service.ConnectAsync("127.0.0.1", port, 2, cancelled.Token); }
                    catch (OperationCanceledException) { rejected = true; }
                    Check("caller-cancellation-closes-connect", rejected && !service.IsConnected);
                }
            }
            finally
            {
                network.Dispose();
                foreach (TcpClient socket in sockets) socket.Dispose();
                listener.Stop();
            }
        }

        [Serializable]
        private sealed class Result { public bool complete; public string[] passed; public string error; }
    }
}

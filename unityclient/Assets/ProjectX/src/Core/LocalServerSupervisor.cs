using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Threading;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Core
{
    public enum LocalServerState
    {
        NotStarted,
        Starting,
        ReadyOwned,
        ReadyAdopted,
        Failed,
        Stopped
    }

    /// <summary>
    /// Owns the packaged loopback game server for a Windows player.  Editor and
    /// explicit external-server runs keep the existing validation workflow.
    /// </summary>
    public sealed class LocalServerSupervisor : IDisposable
    {
        private readonly string executablePath;
        private readonly string configDirectory;
        private readonly string sqlitePath;
        private readonly string sqliteSchemaPath;
        private readonly int port;
        private readonly float timeoutSeconds;
        private readonly string dataRoot;
        private readonly ConcurrentQueue<Tuple<string, bool>> processLines =
            new ConcurrentQueue<Tuple<string, bool>>();
        private Process process;
        private Semaphore ownershipLease;
        private bool leaseHeld;
        private StreamWriter logWriter;
        private bool ownsProcess;
        private float deadline;
        private bool disposed;

        public LocalServerSupervisor(string executablePath, string configDirectory,
            string sqlitePath, string sqliteSchemaPath, int port = 8711, float timeoutSeconds = 20f)
        {
            this.executablePath = Path.GetFullPath(executablePath ?? throw new ArgumentNullException(nameof(executablePath)));
            this.configDirectory = Path.GetFullPath(configDirectory ?? throw new ArgumentNullException(nameof(configDirectory)));
            this.sqlitePath = Path.GetFullPath(sqlitePath ?? throw new ArgumentNullException(nameof(sqlitePath)));
            this.sqliteSchemaPath = Path.GetFullPath(sqliteSchemaPath ?? throw new ArgumentNullException(nameof(sqliteSchemaPath)));
            dataRoot = Path.GetDirectoryName(this.sqlitePath);
            this.port = port;
            this.timeoutSeconds = Math.Max(1f, timeoutSeconds);
        }

        public LocalServerState State { get; private set; } = LocalServerState.NotStarted;
        public string Detail { get; private set; } = "等待准备本地服务";
        public bool IsTerminal => State == LocalServerState.ReadyOwned || State == LocalServerState.ReadyAdopted
            || State == LocalServerState.Failed || State == LocalServerState.Stopped;
        public bool IsReady => State == LocalServerState.ReadyOwned || State == LocalServerState.ReadyAdopted;
        public bool OwnsProcess => ownsProcess;
        public int ProcessId => process != null && !SafeHasExited(process) ? process.Id : 0;
        public bool GracefulShutdownCompleted { get; private set; }
        public string LogPath { get; private set; } = string.Empty;
        public string LatestBackupPath { get; private set; } = string.Empty;
        public bool RecoveredOrphanProcess { get; private set; }

        public event Action<string> Failed;

        public static bool ShouldRun(AppLaunchOptions options)
        {
            options = options ?? AppLaunchOptions.Current();
            if (options.HasFlag("-projectXExternalServer")) return false;
            // Interactive Editor Play should match the shipped player's one-click
            // startup. Batch validations continue to own their server lifecycle.
            return !Application.isEditor || !Application.isBatchMode;
        }

        public static LocalServerSupervisor CreateDefault()
        {
            string serverRoot;
            string configRoot;
            string schemaPath;
            if (Application.isEditor)
            {
                string repositoryRoot = Directory.GetParent(Application.dataPath)?.Parent?.FullName
                    ?? throw new InvalidOperationException("Repository root could not be resolved for Editor Play.");
                serverRoot = Path.Combine(repositoryRoot, ".local", "server-build", "server-win", "Debug");
                configRoot = Path.Combine(repositoryRoot, "server", "config");
                schemaPath = Path.Combine(repositoryRoot, "server", "sql", "sqlite", "001_initial_schema.sql");
            }
            else
            {
                serverRoot = Path.Combine(Application.streamingAssetsPath, "ProjectXServer");
                configRoot = Path.Combine(serverRoot, "config");
                schemaPath = Path.Combine(serverRoot, "sqlite", "001_initial_schema.sql");
            }
            string userRoot = Path.Combine(Application.persistentDataPath, "LocalServer");
            return new LocalServerSupervisor(
                Path.Combine(serverRoot, "kapai.exe"),
                configRoot,
                Path.Combine(userRoot, "projectx.db"),
                schemaPath);
        }

        public void Start()
        {
            if (State != LocalServerState.NotStarted) return;
            if (!ValidateLayout(out string layoutError))
            {
                SetFailed(layoutError);
                return;
            }

            ownershipLease = new Semaphore(1, 1, "Local\\Xuancai.ProjectX.LocalServer.8711");
            leaseHeld = ownershipLease.WaitOne(0);

            Directory.CreateDirectory(dataRoot);
            bool portOpen = IsPortOpen(port, 80);
            Process matching = FindMatchingServerProcess();
            if (portOpen)
            {
                if (matching == null)
                {
                    SetFailed($"本地端口 {port} 已被其他程序占用，请关闭冲突程序后重试。");
                    return;
                }
                if (!leaseHeld)
                {
                    process = matching;
                    ownsProcess = false;
                    State = LocalServerState.ReadyAdopted;
                    Detail = $"已复用本机游戏服务（PID {process.Id}）";
                    ClientLog.Info("LocalServer", Detail, executablePath);
                    return;
                }
                try { RecoverOrphan(matching); }
                catch (Exception exception) { SetFailed(exception.Message); return; }
                portOpen = IsPortOpen(port, 80);
                if (portOpen)
                {
                    SetFailed($"孤儿本机游戏服务未释放端口 {port}。");
                    return;
                }
                matching = null;
            }

            if (matching != null)
            {
                if (leaseHeld)
                {
                    try { RecoverOrphan(matching); }
                    catch (Exception exception) { SetFailed(exception.Message); return; }
                    matching = null;
                }
                else
                {
                process = matching;
                ownsProcess = false;
                State = LocalServerState.Starting;
                Detail = $"正在等待已启动的本机游戏服务（PID {process.Id}）";
                deadline = Time.realtimeSinceStartup + timeoutSeconds;
                return;
                }
            }
            if (!leaseHeld)
            {
                SetFailed("另一客户端正在启动本机游戏服务，请稍后重试。");
                return;
            }

            try
            {
                PrepareWritableState();
                var startInfo = new ProcessStartInfo
                {
                    FileName = executablePath,
                    Arguments = $"--sqlite \"{sqlitePath}\" --sqlite-schema \"{sqliteSchemaPath}\"",
                    WorkingDirectory = configDirectory,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                process = new Process { StartInfo = startInfo, EnableRaisingEvents = true };
                process.OutputDataReceived += (_, args) => QueueServerLine(args.Data, false);
                process.ErrorDataReceived += (_, args) => QueueServerLine(args.Data, true);
                if (!process.Start())
                {
                    SetFailed("无法启动本机游戏服务进程。");
                    return;
                }
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                ownsProcess = true;
                State = LocalServerState.Starting;
                Detail = $"正在启动本机游戏服务（PID {process.Id}）";
                deadline = Time.realtimeSinceStartup + timeoutSeconds;
                ClientLog.Info("LocalServer", Detail, executablePath);
            }
            catch (Exception exception)
            {
                SetFailed("本机游戏服务启动失败：" + exception.Message);
            }
        }

        public void Tick()
        {
            DrainProcessLines();
            if (disposed || process == null) return;
            if (State == LocalServerState.Starting)
            {
                if (SafeHasExited(process))
                {
                    SetFailed($"本机游戏服务启动后异常退出（exit={SafeExitCode(process)}）。");
                    return;
                }
                if (IsPortOpen(port, 25))
                {
                    State = ownsProcess ? LocalServerState.ReadyOwned : LocalServerState.ReadyAdopted;
                    Detail = ownsProcess
                        ? $"本机游戏服务已就绪（PID {process.Id}）"
                        : $"已复用本机游戏服务（PID {process.Id}）";
                    //ClientLog.Info("LocalServer", Detail);
                    return;
                }
                if (Time.realtimeSinceStartup >= deadline)
                    SetFailed($"本机游戏服务在 {timeoutSeconds:F0} 秒内未监听 127.0.0.1:{port}。");
                return;
            }

            if (IsReady && SafeHasExited(process))
                SetFailed($"本机游戏服务运行中异常退出（exit={SafeExitCode(process)}），请重新启动客户端。");
        }

        public void Dispose()
        {
            if (disposed) return;
            disposed = true;
            if (ownsProcess && process != null && !SafeHasExited(process))
            {
                try
                {
                    process.StandardInput.WriteLine("shutdown");
                    process.StandardInput.Flush();
                    GracefulShutdownCompleted = process.WaitForExit(10000);
                    if (GracefulShutdownCompleted) process.WaitForExit();
                    if (!GracefulShutdownCompleted)
                    {
                        ClientLog.Warning("LocalServer", "本机游戏服务优雅退出超时，执行强制回收。", $"pid={process.Id}");
                        process.Kill();
                        process.WaitForExit(3000);
                    }
                }
                catch (Exception exception)
                {
                    ClientLog.Warning("LocalServer", "回收本机游戏服务失败。", exception.Message);
                }
            }
            DrainProcessLines();
            logWriter?.Dispose();
            logWriter = null;
            process?.Dispose();
            process = null;
            if (leaseHeld)
            {
                try { ownershipLease?.Release(); }
                catch (SemaphoreFullException) { }
                leaseHeld = false;
            }
            ownershipLease?.Dispose();
            ownershipLease = null;
            State = LocalServerState.Stopped;
        }

        private bool ValidateLayout(out string error)
        {
            if (!File.Exists(executablePath))
            {
                error = "正式包缺少本机游戏服务：" + executablePath;
                return false;
            }
            if (!Directory.Exists(configDirectory) || !File.Exists(Path.Combine(configDirectory, "config")))
            {
                error = "正式包缺少本机游戏服务配置目录：" + configDirectory;
                return false;
            }
            if (!File.Exists(sqliteSchemaPath))
            {
                error = "正式包缺少 SQLite 初始结构：" + sqliteSchemaPath;
                return false;
            }
            error = string.Empty;
            return true;
        }

        private Process FindMatchingServerProcess()
        {
            string expected = NormalizePath(executablePath);
            foreach (Process candidate in Process.GetProcessesByName(Path.GetFileNameWithoutExtension(executablePath)))
            {
                try
                {
                    if (!candidate.HasExited && string.Equals(NormalizePath(candidate.MainModule?.FileName), expected,
                        StringComparison.OrdinalIgnoreCase)) return candidate;
                }
                catch
                {
                    candidate.Dispose();
                    continue;
                }
                candidate.Dispose();
            }
            return null;
        }

        private void RecoverOrphan(Process orphan)
        {
            int orphanId = 0;
            try
            {
                orphanId = orphan.Id;
                orphan.Kill();
                orphan.WaitForExit(5000);
                RecoveredOrphanProcess = true;
                ClientLog.Warning("LocalServer", "已回收上次客户端崩溃遗留的本机游戏服务。", $"pid={orphanId}");
            }
            catch (Exception exception)
            {
                throw new InvalidOperationException($"无法回收孤儿本机游戏服务 PID {orphanId}。", exception);
            }
            finally { orphan.Dispose(); }
        }

        private void SetFailed(string detail)
        {
            if (State == LocalServerState.Failed) return;
            Detail = string.IsNullOrWhiteSpace(detail) ? "本机游戏服务发生未知错误。" : detail;
            State = LocalServerState.Failed;
            ClientLog.Error("LocalServer", Detail);
            Failed?.Invoke(Detail);
        }

        private static bool IsPortOpen(int targetPort, int timeoutMilliseconds)
        {
            try
            {
                using (var client = new TcpClient())
                {
                    IAsyncResult result = client.BeginConnect("127.0.0.1", targetPort, null, null);
                    bool connected = result.AsyncWaitHandle.WaitOne(timeoutMilliseconds);
                    if (!connected) return false;
                    client.EndConnect(result);
                    return client.Connected;
                }
            }
            catch { return false; }
        }

        private void QueueServerLine(string line, bool error)
        {
            if (string.IsNullOrWhiteSpace(line)) return;
            processLines.Enqueue(Tuple.Create(line, error));
        }

        private void DrainProcessLines()
        {
            while (processLines.TryDequeue(out Tuple<string, bool> entry))
            {
                if (entry.Item2) ClientLog.Warning("LocalServer.Process", entry.Item1);
                else ClientLog.Info("LocalServer.Process", entry.Item1);
                if (logWriter != null)
                {
                    logWriter.WriteLine($"{DateTime.UtcNow:o} [{(entry.Item2 ? "stderr" : "stdout")}] {entry.Item1}");
                    logWriter.Flush();
                }
            }
        }

        private void PrepareWritableState()
        {
            string logsDirectory = Path.Combine(dataRoot, "Logs");
            string backupsDirectory = Path.Combine(dataRoot, "Backups");
            Directory.CreateDirectory(logsDirectory);
            Directory.CreateDirectory(backupsDirectory);
            LogPath = Path.Combine(logsDirectory, "kapai-current.log");
            if (File.Exists(LogPath) && new FileInfo(LogPath).Length > 0)
            {
                string archivedLog = Path.Combine(logsDirectory, "kapai-" + DateTime.UtcNow.ToString("yyyyMMdd-HHmmssfff") + ".log");
                File.Move(LogPath, archivedLog);
            }
            RetainNewest(logsDirectory, "kapai-*.log", 5);
            logWriter = new StreamWriter(new FileStream(LogPath, FileMode.Create, FileAccess.Write, FileShare.Read))
            { AutoFlush = true };

            if (File.Exists(sqlitePath) && new FileInfo(sqlitePath).Length > 0)
            {
                LatestBackupPath = Path.Combine(backupsDirectory,
                    "projectx-" + DateTime.UtcNow.ToString("yyyyMMdd-HHmmssfff") + ".db");
                File.Copy(sqlitePath, LatestBackupPath, false);
                RetainNewest(backupsDirectory, "projectx-*.db", 3);
                ClientLog.Info("LocalServer", "启动前数据库备份完成。", LatestBackupPath);
            }
        }

        private static void RetainNewest(string directory, string pattern, int retainCount)
        {
            FileInfo[] files = new DirectoryInfo(directory).GetFiles(pattern)
                .OrderByDescending(file => file.LastWriteTimeUtc).ToArray();
            for (int index = Math.Max(0, retainCount); index < files.Length; index++) files[index].Delete();
        }

        private static bool SafeHasExited(Process value)
        {
            try { return value == null || value.HasExited; }
            catch { return true; }
        }

        private static int SafeExitCode(Process value)
        {
            try { return value != null && value.HasExited ? value.ExitCode : -1; }
            catch { return -1; }
        }

        private static string NormalizePath(string path) =>
            string.IsNullOrWhiteSpace(path) ? string.Empty : Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar);
    }
}

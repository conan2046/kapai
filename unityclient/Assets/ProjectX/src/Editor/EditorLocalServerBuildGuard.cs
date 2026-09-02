using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    [InitializeOnLoad]
    public static class EditorLocalServerBuildGuard
    {
        private static readonly HashSet<string> CompiledExtensions = new HashSet<string>(
            new[] { ".c", ".cc", ".cpp", ".h", ".hpp" }, StringComparer.OrdinalIgnoreCase);
        private static bool buildInProgress;

        static EditorLocalServerBuildGuard()
        {
            EditorApplication.playModeStateChanged += HandlePlayModeStateChanged;
        }

        [MenuItem("Tools/ProjectX App/Ensure Editor Local Server", priority = 110)]
        public static void EnsureFromMenu()
        {
            if (EnsureServerBuilt(false))
                UnityEngine.Debug.Log("[EditorLocalServerBuildGuard] kapai.exe is ready for Editor Play.");
        }

        public static void EnsureForBatch()
        {
            int exitCode = EnsureServerBuilt(false) ? 0 : 1;
            EditorApplication.Exit(exitCode);
        }

        private static void HandlePlayModeStateChanged(PlayModeStateChange state)
        {
            if (state != PlayModeStateChange.ExitingEditMode || Application.isBatchMode || buildInProgress)
                return;
            if (Environment.GetCommandLineArgs().Any(argument =>
                    string.Equals(argument, "-projectXExternalServer", StringComparison.OrdinalIgnoreCase)))
                return;
            if (!EnsureServerBuilt(false)) EditorApplication.isPlaying = false;
        }

        private static bool EnsureServerBuilt(bool force)
        {
            string repositoryRoot = Directory.GetParent(Application.dataPath)?.Parent?.FullName;
            if (string.IsNullOrWhiteSpace(repositoryRoot))
            {
                UnityEngine.Debug.LogError("[EditorLocalServerBuildGuard] 无法定位仓库根目录，已取消 Play。");
                return false;
            }

            string buildDirectory = Path.Combine(repositoryRoot, ".local", "server-build", "server-win");
            string executable = Path.Combine(buildDirectory, "Debug", "kapai.exe");
            if (!force && !NeedsBuild(repositoryRoot, executable)) return true;

            string buildScript = Path.Combine(repositoryRoot, "tools", "local", "Build-Server.ps1");
            if (!File.Exists(buildScript))
            {
                UnityEngine.Debug.LogError("[EditorLocalServerBuildGuard] 缺少服务端构建脚本：" + buildScript);
                return false;
            }

            buildInProgress = true;
            EditorUtility.DisplayProgressBar("ProjectX", "正在自动构建 SQLite 本地服务端…", 0.5f);
            try
            {
                string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
                string knownPwsh = Path.Combine(programFiles, "PowerShell", "7", "pwsh.exe");
                string pwsh = File.Exists(knownPwsh) ? knownPwsh : "pwsh.exe";
                var output = new StringBuilder();
                var errors = new StringBuilder();
                var startInfo = new ProcessStartInfo
                {
                    FileName = pwsh,
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -File " + Quote(buildScript)
                        + " -BuildDir " + Quote(buildDirectory),
                    WorkingDirectory = repositoryRoot,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (var process = new Process { StartInfo = startInfo })
                {
                    process.OutputDataReceived += (_, args) => AppendLine(output, args.Data);
                    process.ErrorDataReceived += (_, args) => AppendLine(errors, args.Data);
                    if (!process.Start()) throw new InvalidOperationException("无法启动 PowerShell 7 构建进程。");
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();
                    process.WaitForExit();
                    if (process.ExitCode != 0 || !File.Exists(executable))
                    {
                        UnityEngine.Debug.LogError(
                            $"[EditorLocalServerBuildGuard] 服务端自动构建失败（exit={process.ExitCode}），已取消 Play。\n"
                            + Tail(errors.Length > 0 ? errors.ToString() : output.ToString(), 80));
                        return false;
                    }
                }
                UnityEngine.Debug.Log("[EditorLocalServerBuildGuard] 服务端自动构建完成：" + executable);
                return true;
            }
            catch (Exception exception)
            {
                UnityEngine.Debug.LogError("[EditorLocalServerBuildGuard] 服务端自动构建异常，已取消 Play：" + exception);
                return false;
            }
            finally
            {
                EditorUtility.ClearProgressBar();
                buildInProgress = false;
            }
        }

        private static bool NeedsBuild(string repositoryRoot, string executable)
        {
            if (!File.Exists(executable)) return true;
            DateTime builtAt = File.GetLastWriteTimeUtc(executable);
            foreach (string input in BuildInputs(repositoryRoot))
                if (File.GetLastWriteTimeUtc(input) > builtAt) return true;
            return false;
        }

        private static IEnumerable<string> BuildInputs(string repositoryRoot)
        {
            string serverRoot = Path.Combine(repositoryRoot, "server");
            string sourceRoot = Path.Combine(serverRoot, "src");
            foreach (string file in new[]
            {
                Path.Combine(serverRoot, "CMakeLists.txt"),
                Path.Combine(repositoryRoot, "tools", "local", "Build-Server.ps1")
            })
                if (File.Exists(file)) yield return file;
            if (!Directory.Exists(sourceRoot)) yield break;
            foreach (string file in Directory.GetFiles(sourceRoot, "*", SearchOption.AllDirectories))
                if (CompiledExtensions.Contains(Path.GetExtension(file))) yield return file;
        }

        private static void AppendLine(StringBuilder builder, string line)
        {
            if (line == null) return;
            lock (builder) builder.AppendLine(line);
        }

        private static string Quote(string value) => "\"" + value.Replace("\"", "\\\"") + "\"";

        private static string Tail(string value, int maximumLines)
        {
            string[] lines = (value ?? string.Empty).Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            return string.Join(Environment.NewLine, lines.Skip(Math.Max(0, lines.Length - maximumLines)));
        }
    }
}

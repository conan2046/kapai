using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class SteamWindowsBuild
    {
        private static readonly HashSet<string> ServerBuildExtensions = new HashSet<string>(
            new[] { ".c", ".cc", ".cpp", ".h", ".hpp" }, StringComparer.OrdinalIgnoreCase);

        [Serializable]
        private sealed class PackageEntry
        {
            public string path;
            public long bytes;
            public string sha256;
        }

        [Serializable]
        private sealed class PackageManifest
        {
            public int schemaVersion = 1;
            public string generatedAt;
            public string productVersion;
            public string unityVersion;
            public string target = "Windows x64";
            public string compression;
            public string clientEntry = "ProjectX.exe";
            public string serverEntry = "ProjectX_Data/StreamingAssets/ProjectXServer/kapai.exe";
            public string database = "Application.persistentDataPath/LocalServer/projectx.db";
            public List<PackageEntry> files = new List<PackageEntry>();
        }

        [MenuItem("Tools/ProjectX 应用/构建 Steam Windows 包", priority = 120)]
        public static void BuildMenu() => Build(false);

        public static void BuildBatch() => Build(true);

        private static void Build(bool exitEditor)
        {
            int exitCode = 1;
            try
            {
                string repositoryRoot = Directory.GetParent(Application.dataPath)?.Parent?.FullName
                    ?? throw new InvalidOperationException("Repository root could not be resolved.");
                string outputExe = ResolveOutputPath(repositoryRoot);
                EnsurePackagedServerBuilt(repositoryRoot);
                ValidatePreflight(repositoryRoot, outputExe);
                Directory.CreateDirectory(Path.GetDirectoryName(outputExe));
                BootstrapSceneBuilder.Build();
                PlayerSettings.companyName = "Xuancai";
                PlayerSettings.productName = "ProjectX";
                PlayerSettings.SetArchitecture(BuildTargetGroup.Standalone, 1);

                var options = new BuildPlayerOptions
                {
                    scenes = EditorBuildSettings.scenes.Where(scene => scene.enabled).Select(scene => scene.path).ToArray(),
                    locationPathName = outputExe,
                    target = BuildTarget.StandaloneWindows64,
                    options = BuildOptions.CompressWithLz4HC
                };
                BuildReport report = BuildPipeline.BuildPlayer(options);
                if (report.summary.result != BuildResult.Succeeded)
                    throw new InvalidOperationException($"Unity player build failed: {report.summary.result}");

                string outputDirectory = Path.GetDirectoryName(outputExe);
                RemoveDoNotShipArtifacts(outputDirectory);
                string dataDirectory = Path.Combine(outputDirectory, Path.GetFileNameWithoutExtension(outputExe) + "_Data");
                string serverRoot = Path.Combine(dataDirectory, "StreamingAssets", "ProjectXServer");
                PackageServer(repositoryRoot, serverRoot);
                ValidateReleaseTree(outputDirectory);
                string packageManifest = WritePackageManifest(outputDirectory);
                UnityEngine.Debug.Log($"[SteamWindowsBuild:LZ4HC] Passed: {outputExe} manifest={packageManifest}");
                exitCode = 0;
            }
            catch (Exception exception)
            {
                UnityEngine.Debug.LogError("[SteamWindowsBuild] " + exception);
                if (!exitEditor) throw;
            }
            finally
            {
                if (exitEditor) EditorApplication.Exit(exitCode);
            }
        }

        private static void PackageServer(string repositoryRoot, string serverRoot)
        {
            string buildRoot = Path.Combine(repositoryRoot, ".local", "steam-server-build", "server-win", "Debug");
            string executable = Path.Combine(buildRoot, "kapai.exe");
            string config = Path.Combine(repositoryRoot, "unityserver", "config");
            string scripts = Path.Combine(repositoryRoot, "unityserver", "script");
            string schema = Path.Combine(repositoryRoot, "unityserver", "sql", "sqlite", "001_initial_schema.sql");
            foreach (string required in new[] { executable, schema })
                if (!File.Exists(required)) throw new FileNotFoundException("Steam server runtime input is missing.", required);
            foreach (string required in new[] { config, scripts })
                if (!Directory.Exists(required)) throw new DirectoryNotFoundException(required);

            if (Directory.Exists(serverRoot)) Directory.Delete(serverRoot, true);
            Directory.CreateDirectory(serverRoot);
            File.Copy(executable, Path.Combine(serverRoot, "kapai.exe"), true);
            foreach (string dll in Directory.GetFiles(buildRoot, "*.dll", SearchOption.TopDirectoryOnly))
                File.Copy(dll, Path.Combine(serverRoot, Path.GetFileName(dll)), true);
            CopyDirectory(config, Path.Combine(serverRoot, "config"));
            CopyDirectory(scripts, Path.Combine(serverRoot, "script"));
            Directory.CreateDirectory(Path.Combine(serverRoot, "sqlite"));
            File.Copy(schema, Path.Combine(serverRoot, "sqlite", Path.GetFileName(schema)), true);

            if (Directory.GetFiles(serverRoot, "*.pdb", SearchOption.AllDirectories).Length != 0)
                throw new InvalidOperationException("Steam server package contains PDB files.");
            if (Directory.GetFiles(serverRoot, "mysqld.exe", SearchOption.AllDirectories).Length != 0)
                throw new InvalidOperationException("Steam server package must not contain a MySQL server process.");
        }

        private static string WritePackageManifest(string outputDirectory)
        {
            var manifest = new PackageManifest
            {
                generatedAt = DateTime.UtcNow.ToString("o"),
                productVersion = PlayerSettings.bundleVersion,
                unityVersion = Application.unityVersion,
                compression = "LZ4HC"
            };
            string manifestPath = Path.Combine(outputDirectory, "steam-package-manifest.json");
            IEnumerable<string> files = Directory.GetFiles(outputDirectory, "*", SearchOption.AllDirectories)
                .Where(file => !string.Equals(Path.GetFullPath(file), Path.GetFullPath(manifestPath),
                    StringComparison.OrdinalIgnoreCase));
            foreach (string file in files.OrderBy(value => value, StringComparer.OrdinalIgnoreCase))
            {
                var info = new FileInfo(file);
                manifest.files.Add(new PackageEntry
                {
                    path = RelativePath(outputDirectory, file).Replace('\\', '/'),
                    bytes = info.Length,
                    sha256 = HashFile(file)
                });
            }
            File.WriteAllText(manifestPath, JsonUtility.ToJson(manifest, true) + Environment.NewLine);
            return manifestPath;
        }

        private static void RemoveDoNotShipArtifacts(string outputDirectory)
        {
            foreach (string directory in Directory.GetDirectories(outputDirectory, "*DoNotShip*",
                         SearchOption.TopDirectoryOnly))
                Directory.Delete(directory, true);
        }

        private static void ValidateReleaseTree(string outputDirectory)
        {
            string[] forbiddenDirectories = Directory.GetDirectories(outputDirectory, "*DoNotShip*",
                SearchOption.AllDirectories);
            if (forbiddenDirectories.Length != 0)
                throw new InvalidOperationException("Steam package contains DoNotShip directories: "
                    + string.Join(", ", forbiddenDirectories));

            string[] forbiddenFiles = Directory.GetFiles(outputDirectory, "*", SearchOption.AllDirectories)
                .Where(file => string.Equals(Path.GetExtension(file), ".pdb", StringComparison.OrdinalIgnoreCase)
                    || new[] { "mysqld.exe", "pwsh.exe", "powershell.exe" }.Contains(
                        Path.GetFileName(file), StringComparer.OrdinalIgnoreCase))
                .ToArray();
            if (forbiddenFiles.Length != 0)
                throw new InvalidOperationException("Steam package contains development-only files: "
                    + string.Join(", ", forbiddenFiles));
        }

        private static void ValidatePreflight(string repositoryRoot, string outputExe)
        {
            string projectVersionPath = Path.Combine(repositoryRoot, "unityclient", "ProjectSettings", "ProjectVersion.txt");
            if (!File.Exists(projectVersionPath))
                throw new FileNotFoundException("Unity project version file is missing.", projectVersionPath);
            string editorVersion = File.ReadLines(projectVersionPath)
                .FirstOrDefault(line => line.StartsWith("m_EditorVersion:", StringComparison.Ordinal))?
                .Substring("m_EditorVersion:".Length).Trim();
            if (string.IsNullOrWhiteSpace(editorVersion)
                || !string.Equals(editorVersion, Application.unityVersion, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException(
                    $"Unity Editor version mismatch: project={editorVersion ?? "<missing>"}, editor={Application.unityVersion}.");

            if (string.IsNullOrWhiteSpace(PlayerSettings.bundleVersion))
                throw new InvalidOperationException("PlayerSettings.bundleVersion must be set before a Steam Release build.");
            if (!outputExe.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Steam Windows build output must be an .exe path.");
            if (!BuildPipeline.IsBuildTargetSupported(BuildTargetGroup.Standalone, BuildTarget.StandaloneWindows64))
                throw new InvalidOperationException("Windows x64 Build Support is not installed in this Unity Editor.");

            EditorBuildSettingsScene[] scenes = EditorBuildSettings.scenes.Where(scene => scene.enabled).ToArray();
            if (scenes.Length == 0 || !scenes.Any(scene => string.Equals(
                    Path.GetFileName(scene.path), "Bootstrap.unity", StringComparison.OrdinalIgnoreCase)))
                throw new InvalidOperationException("Steam Release scenes must include the Bootstrap scene.");
            foreach (EditorBuildSettingsScene scene in scenes)
            {
                string scenePath = Path.Combine(repositoryRoot, "unityclient", scene.path);
                if (!File.Exists(scenePath))
                    throw new FileNotFoundException("An enabled Steam build scene is missing.", scenePath);
            }

            string serverBuildRoot = Path.Combine(repositoryRoot, ".local", "steam-server-build", "server-win", "Debug");
            string[] requiredFiles =
            {
                Path.Combine(serverBuildRoot, "kapai.exe"),
                Path.Combine(repositoryRoot, "unityserver", "sql", "sqlite", "001_initial_schema.sql")
            };
            foreach (string required in requiredFiles)
                if (!File.Exists(required)) throw new FileNotFoundException("Steam Release input is missing.", required);
            foreach (string requiredDirectory in new[]
                     {
                         Path.Combine(repositoryRoot, "unityserver", "config"),
                         Path.Combine(repositoryRoot, "unityserver", "script")
                     })
                if (!Directory.Exists(requiredDirectory))
                    throw new DirectoryNotFoundException("Steam Release input directory is missing: " + requiredDirectory);
        }

        private static void EnsurePackagedServerBuilt(string repositoryRoot)
        {
            string buildDirectory = Path.Combine(repositoryRoot, ".local", "steam-server-build", "server-win");
            string executable = Path.Combine(buildDirectory, "Debug", "kapai.exe");
            if (!NeedsServerBuild(repositoryRoot, executable)) return;

            string buildScript = Path.Combine(repositoryRoot, "tools", "local", "Build-Server.ps1");
            if (!File.Exists(buildScript))
                throw new FileNotFoundException("Steam server build script is missing.", buildScript);
            string vcpkgRoot = Path.Combine(repositoryRoot, "tools", "local", "vcpkg");
            string vcpkgToolchain = Path.Combine(vcpkgRoot, "scripts", "buildsystems", "vcpkg.cmake");
            if (!File.Exists(vcpkgToolchain))
                throw new FileNotFoundException("C-worktree vcpkg toolchain is missing; refusing shared external toolchains.",
                    vcpkgToolchain);

            string cachePath = Path.Combine(buildDirectory, "CMakeCache.txt");
            if (File.Exists(cachePath)
                && File.ReadAllText(cachePath).IndexOf("E:\\neiwang_kapai\\Game", StringComparison.OrdinalIgnoreCase) >= 0)
                throw new InvalidOperationException(
                    "Steam server build cache contains an external E-drive path; use a clean C-worktree build directory.");

            string knownPwsh = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "PowerShell", "7", "pwsh.exe");
            string pwsh = File.Exists(knownPwsh) ? knownPwsh : "pwsh.exe";
            var output = new StringBuilder();
            var errors = new StringBuilder();
            var startInfo = new ProcessStartInfo
            {
                FileName = pwsh,
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File " + Quote(buildScript)
                    + " -BuildDir " + Quote(Path.Combine(".local", "steam-server-build", "server-win"))
                    + " -VcpkgRoot " + Quote(vcpkgRoot),
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
                if (!process.Start()) throw new InvalidOperationException("Could not start PowerShell 7 server build.");
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.WaitForExit();
                if (process.ExitCode != 0 || !File.Exists(executable))
                    throw new InvalidOperationException(
                        $"Steam server build failed (exit={process.ExitCode}).\n"
                        + Tail(errors.Length > 0 ? errors.ToString() : output.ToString(), 80));
            }
        }

        private static bool NeedsServerBuild(string repositoryRoot, string executable)
        {
            if (!File.Exists(executable)) return true;
            DateTime builtAt = File.GetLastWriteTimeUtc(executable);
            foreach (string input in ServerBuildInputs(repositoryRoot))
                if (File.GetLastWriteTimeUtc(input) > builtAt) return true;
            return false;
        }

        private static IEnumerable<string> ServerBuildInputs(string repositoryRoot)
        {
            string serverRoot = Path.Combine(repositoryRoot, "server");
            string sourceRoot = Path.Combine(serverRoot, "src");
            foreach (string input in new[]
                     {
                         Path.Combine(serverRoot, "CMakeLists.txt"),
                         Path.Combine(repositoryRoot, "tools", "local", "Build-Server.ps1")
                     })
                if (File.Exists(input)) yield return input;
            if (!Directory.Exists(sourceRoot)) yield break;
            foreach (string file in Directory.GetFiles(sourceRoot, "*", SearchOption.AllDirectories))
                if (ServerBuildExtensions.Contains(Path.GetExtension(file))) yield return file;
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

        private static void CopyDirectory(string source, string destination)
        {
            Directory.CreateDirectory(destination);
            foreach (string directory in Directory.GetDirectories(source, "*", SearchOption.AllDirectories))
                Directory.CreateDirectory(Path.Combine(destination, RelativePath(source, directory)));
            foreach (string file in Directory.GetFiles(source, "*", SearchOption.AllDirectories))
            {
                string target = Path.Combine(destination, RelativePath(source, file));
                Directory.CreateDirectory(Path.GetDirectoryName(target));
                File.Copy(file, target, true);
            }
        }

        private static string ResolveOutputPath(string repositoryRoot)
        {
            const string prefix = "-projectXSteamBuildPath=";
            string argument = Environment.GetCommandLineArgs().FirstOrDefault(value =>
                value.StartsWith(prefix, StringComparison.OrdinalIgnoreCase));
            return string.IsNullOrWhiteSpace(argument)
                ? Path.Combine(repositoryRoot, ".local", "steam-build", "ProjectX", "ProjectX.exe")
                : Path.GetFullPath(argument.Substring(prefix.Length));
        }

        private static string RelativePath(string root, string path)
        {
            string rootUri = new Uri(Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar).AbsoluteUri;
            return Uri.UnescapeDataString(new Uri(rootUri).MakeRelativeUri(new Uri(Path.GetFullPath(path))).ToString())
                .Replace('/', Path.DirectorySeparatorChar);
        }

        private static string HashFile(string path)
        {
            using (SHA256 sha = SHA256.Create())
            using (FileStream stream = File.OpenRead(path))
                return string.Concat(sha.ComputeHash(stream).Select(value => value.ToString("x2")));
        }
    }
}

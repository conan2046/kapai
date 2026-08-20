using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class SteamWindowsBuild
    {
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
            public string target = "Windows x64";
            public string clientEntry = "ProjectX.exe";
            public string serverEntry = "ProjectX_Data/StreamingAssets/ProjectXServer/kapai.exe";
            public string database = "Application.persistentDataPath/LocalServer/projectx.db";
            public List<PackageEntry> files = new List<PackageEntry>();
        }

        [MenuItem("Tools/ProjectX App/Build Steam Windows Package", priority = 120)]
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
                    options = BuildOptions.None
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
                UnityEngine.Debug.Log($"[SteamWindowsBuild] Passed: {outputExe} manifest={packageManifest}");
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
            string buildRoot = Path.Combine(repositoryRoot, "build", "server-win", "Debug");
            string executable = Path.Combine(buildRoot, "kapai.exe");
            string config = Path.Combine(repositoryRoot, "server", "config");
            string scripts = Path.Combine(repositoryRoot, "server", "script");
            string schema = Path.Combine(repositoryRoot, "server", "sql", "sqlite", "001_initial_schema.sql");
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
            var manifest = new PackageManifest { generatedAt = DateTime.UtcNow.ToString("o") };
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

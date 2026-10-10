using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Foundation;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>Uses only fresh temporary directories; never opens a player's SQLite save.</summary>
    public static class SinglePlayerLifecycleTests
    {
        public static string Run()
        {
            var passed = new List<string>();
            Action<string, bool> check = (name, condition) =>
            {
                if (!condition) throw new InvalidOperationException("Lifecycle regression: " + name);
                passed.Add(name);
            };
            var firstError = new IOException("injected metadata failure");
            var secondError = new InvalidOperationException("injected cleanup failure");
            var order = new List<int>();
            Exception[] errors = CleanupSequence.Run(
                () => { order.Add(1); throw firstError; },
                () => { order.Add(2); throw secondError; },
                null,
                () => order.Add(3));
            check("cleanup-continues-after-each-failure", order.SequenceEqual(new[] { 1, 2, 3 }));
            check("cleanup-retains-original-errors", errors.Length == 2
                && ReferenceEquals(errors[0], firstError) && ReferenceEquals(errors[1], secondError));
            check("empty-cleanup-succeeds", CleanupSequence.Run().Length == 0);

            string isolatedRoot = Path.Combine(Path.GetTempPath(), "ProjectX-Lifecycle-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(isolatedRoot);
            try
            {
                var saves = new SinglePlayerSaveService(isolatedRoot);
                string draftDatabase = saves.PrepareForPlay(2, true);
                saves.ResolveLocalUserId(2, true, 1);
                File.WriteAllBytes(draftDatabase, System.Text.Encoding.ASCII.GetBytes("SQLite format 3\0draft"));
                check("creation-screen-does-not-publish-save", !saves.ReadSlot(2).Exists);
                saves.DiscardPendingCreation();
                check("cancelled-creation-removes-draft", !Directory.Exists(Path.GetDirectoryName(draftDatabase)));
                draftDatabase = saves.PrepareForPlay(2, true);
                saves.ResolveLocalUserId(2, true, 1);
                File.WriteAllBytes(draftDatabase, System.Text.Encoding.ASCII.GetBytes("SQLite format 3\0role"));
                saves.UpdatePlayer(2, 42, "Created role", 5, 1, 1);
                check("successful-role-login-publishes-save", saves.ReadSlot(2).Exists);
                saves.DiscardPendingCreation();
                check("completed-role-save-is-preserved", File.Exists(draftDatabase));
                saves.PrepareForPlay(1, true);
                uint userId = saves.ResolveLocalUserId(1, true, 1);
                saves.BeginSession(1);
                saves.CompleteSession();
                check("successful-session-ends", saves.ActiveSlotId == 0);
                check("metadata-identity-preserved", saves.ReadSlot(1).Metadata.localUserId == userId);
                string metadataPath = Path.Combine(saves.RootPath, "Slot01", "metadata.json");
                byte[] completedMetadata = File.ReadAllBytes(metadataPath);
                saves.CompleteSession();
                check("repeated-completion-does-not-write", completedMetadata.SequenceEqual(File.ReadAllBytes(metadataPath)));

                saves.BeginSession(1);
                byte[] previousMetadata = File.ReadAllBytes(metadataPath);
                // A directory at the write staging path forces a real file I/O failure.
                Directory.CreateDirectory(metadataPath + ".tmp");
                bool transportReleased = false;
                errors = CleanupSequence.Run(saves.CompleteSession, () => transportReleased = true);
                check("metadata-write-failure-remains-visible", errors.Length == 1
                    && (errors[0] is IOException || errors[0] is UnauthorizedAccessException));
                check("metadata-failure-still-releases-runtime", transportReleased);
                check("failed-session-is-ended", saves.ActiveSlotId == 0);
                check("failed-write-preserves-existing-metadata", previousMetadata.SequenceEqual(File.ReadAllBytes(metadataPath)));
                check("repeat-after-failed-completion-is-noop", CleanupSequence.Run(saves.CompleteSession).Length == 0);
            }
            finally
            {
                // This exact GUID directory was created by this test, outside user save roots.
                Directory.Delete(isolatedRoot, true);
            }
            return JsonUtility.ToJson(new Result { passed = passed.ToArray() }, true);
        }

        public static void RunBatch()
        {
            const string prefix = "-projectXLifecycleReport=";
            string argument = Environment.GetCommandLineArgs().Single(value => value.StartsWith(prefix, StringComparison.Ordinal));
            string reportPath = Path.GetFullPath(argument.Substring(prefix.Length));
            string temporaryRoot = Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            if (!reportPath.StartsWith(temporaryRoot, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Lifecycle report must be in the temporary directory.");
            File.WriteAllText(reportPath, Run());
            Debug.Log("Single-player lifecycle isolated tests passed: " + reportPath);
        }

        [Serializable]
        private sealed class Result { public string[] passed; }
    }
}

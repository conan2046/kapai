using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace ProjectX.Data
{
    [Serializable]
    public sealed class SinglePlayerSaveMetadata
    {
        public int version = 1;
        public int slotId;
        public uint localUserId;
        public uint roleId;
        public string roleName = string.Empty;
        public int heroPicture;
        public int level;
        public ulong combatPower;
        public long totalPlaySeconds;
        public string createdUtc = string.Empty;
        public string updatedUtc = string.Empty;
    }

    public sealed class SinglePlayerSaveSlot
    {
        public int SlotId { get; set; }
        public string DatabasePath { get; set; }
        public string MetadataPath { get; set; }
        public bool Exists { get; set; }
        public bool IsCorrupt { get; set; }
        public bool IsLegacyImport { get; set; }
        public string Error { get; set; }
        public SinglePlayerSaveMetadata Metadata { get; set; }
    }

    /// <summary>
    /// Owns the ten Steam single-player save slots.  The packaged server is
    /// started only after one slot has supplied its database path.
    /// </summary>
    public sealed class SinglePlayerSaveService
    {
        public const int SlotCount = 10;
        private const string DatabaseName = "projectx.db";
        private const string MetadataName = "metadata.json";
        private readonly string root;
        private readonly string legacyDatabasePath;
        private readonly bool includeLegacyDatabase;
        private DateTime sessionStartedUtc;
        private int sessionSlotId;

        public SinglePlayerSaveService(string persistentDataPath, bool includeLegacyDatabase = false)
        {
            if (string.IsNullOrWhiteSpace(persistentDataPath))
                throw new ArgumentException("Persistent data path is required.", nameof(persistentDataPath));
            root = Path.Combine(Path.GetFullPath(persistentDataPath), "Saves");
            legacyDatabasePath = Path.Combine(Path.GetFullPath(persistentDataPath), "LocalServer", DatabaseName);
            this.includeLegacyDatabase = includeLegacyDatabase;
        }

        public string RootPath => root;
        public int ActiveSlotId => sessionSlotId;

        public IReadOnlyList<SinglePlayerSaveSlot> GetSlots()
        {
            var result = new List<SinglePlayerSaveSlot>(SlotCount);
            for (int slotId = 1; slotId <= SlotCount; slotId++) result.Add(ReadSlot(slotId));
            return result;
        }

        public SinglePlayerSaveSlot ReadSlot(int slotId)
        {
            ValidateSlotId(slotId);
            string slotDirectory = GetSlotDirectory(slotId);
            string databasePath = Path.Combine(slotDirectory, DatabaseName);
            string metadataPath = Path.Combine(slotDirectory, MetadataName);
            // Steam save selection owns only Saves/Slot01..10. The old
            // LocalServer database is a development/compatibility fixture and
            // must never appear as a second player save unless an explicit
            // migration flow opts in.
            bool legacy = includeLegacyDatabase && slotId == 1
                && !File.Exists(databasePath) && File.Exists(legacyDatabasePath);
            string resolvedDatabase = legacy ? legacyDatabasePath : databasePath;
            bool exists = File.Exists(resolvedDatabase) && new FileInfo(resolvedDatabase).Length > 0;
            bool corrupt = exists && !HasSqliteHeader(resolvedDatabase);
            SinglePlayerSaveMetadata metadata = ReadMetadata(metadataPath, slotId, out string metadataError);
            return new SinglePlayerSaveSlot
            {
                SlotId = slotId,
                DatabasePath = resolvedDatabase,
                MetadataPath = metadataPath,
                Exists = exists,
                IsCorrupt = corrupt,
                IsLegacyImport = legacy,
                Error = corrupt ? "SQLite 文件头无效" : metadataError,
                Metadata = metadata
            };
        }

        public string PrepareForPlay(int slotId, bool startNew)
        {
            ValidateSlotId(slotId);
            SinglePlayerSaveSlot slot = ReadSlot(slotId);
            string slotDirectory = GetSlotDirectory(slotId);
            if (startNew)
            {
                if (Directory.Exists(slotDirectory)) Directory.Delete(slotDirectory, true);
                Directory.CreateDirectory(slotDirectory);
                WriteMetadata(Path.Combine(slotDirectory, MetadataName), NewMetadata(slotId));
                return Path.Combine(slotDirectory, DatabaseName);
            }
            if (!slot.Exists) throw new InvalidOperationException($"存档 {slotId:00} 尚未创建。");
            if (slot.IsCorrupt) throw new InvalidOperationException($"存档 {slotId:00} 已损坏，请删除后重新创建。");
            Directory.CreateDirectory(slotDirectory);
            string targetDatabase = Path.Combine(slotDirectory, DatabaseName);
            if (slot.IsLegacyImport)
            {
                File.Copy(legacyDatabasePath, targetDatabase, false);
                SinglePlayerSaveMetadata imported = slot.Metadata ?? NewMetadata(slotId);
                imported.slotId = slotId;
                imported.updatedUtc = DateTime.UtcNow.ToString("o");
                WriteMetadata(Path.Combine(slotDirectory, MetadataName), imported);
            }
            return targetDatabase;
        }

        public uint ResolveLocalUserId(int slotId, bool startNew, uint legacyFallback)
        {
            ValidateSlotId(slotId);
            string metadataPath = Path.Combine(GetSlotDirectory(slotId), MetadataName);
            SinglePlayerSaveMetadata metadata = ReadMetadata(metadataPath, slotId, out _) ?? NewMetadata(slotId);
            if (startNew) metadata.localUserId = 9100000u + (uint)slotId;
            else if (metadata.localUserId == 0) metadata.localUserId = Math.Max(1u, legacyFallback);
            metadata.updatedUtc = DateTime.UtcNow.ToString("o");
            WriteMetadata(metadataPath, metadata);
            return metadata.localUserId;
        }

        public void DeleteSlot(int slotId)
        {
            ValidateSlotId(slotId);
            if (sessionSlotId == slotId)
                throw new InvalidOperationException($"存档 {slotId:00} 正在游戏中，请先返回标题界面。");

            SinglePlayerSaveSlot slot = ReadSlot(slotId);
            if (!slot.Exists) return;
            if (slot.IsLegacyImport)
                throw new InvalidOperationException("本地旧存档尚未导入，不能从档位界面移除。");

            string slotDirectory = GetSlotDirectory(slotId);
            if (Directory.Exists(slotDirectory)) Directory.Delete(slotDirectory, true);
        }

        public void BeginSession(int slotId)
        {
            ValidateSlotId(slotId);
            CompleteSession();
            sessionSlotId = slotId;
            sessionStartedUtc = DateTime.UtcNow;
            TouchMetadata(slotId);
        }

        public void UpdatePlayer(int slotId, uint roleId, string roleName, int heroPicture, int level, ulong combatPower)
        {
            ValidateSlotId(slotId);
            string metadataPath = Path.Combine(GetSlotDirectory(slotId), MetadataName);
            SinglePlayerSaveMetadata metadata = ReadMetadata(metadataPath, slotId, out _) ?? NewMetadata(slotId);
            metadata.roleId = roleId;
            metadata.roleName = roleName ?? string.Empty;
            metadata.heroPicture = heroPicture;
            metadata.level = Math.Max(0, level);
            metadata.combatPower = combatPower;
            metadata.updatedUtc = DateTime.UtcNow.ToString("o");
            WriteMetadata(metadataPath, metadata);
        }

        public string CreateSnapshotStagingPath(int targetSlotId)
        {
            ValidateSlotId(targetSlotId);
            string pendingDirectory = Path.Combine(root, "Pending");
            Directory.CreateDirectory(pendingDirectory);
            return Path.Combine(pendingDirectory,
                $"Slot{targetSlotId:00}-{Guid.NewGuid():N}.db");
        }

        public void CommitCurrentSnapshot(int sourceSlotId, int targetSlotId, string stagingPath,
            uint roleId, string roleName, int heroPicture, int level, ulong combatPower)
        {
            ValidateSlotId(sourceSlotId);
            ValidateSlotId(targetSlotId);
            if (sourceSlotId == targetSlotId)
                throw new InvalidOperationException("当前档位无需复制快照。");
            if (sessionSlotId != sourceSlotId)
                throw new InvalidOperationException("当前游戏档位与存档会话不一致。");

            string verifiedStaging = ValidateStagingPath(stagingPath);
            if (!HasSqliteHeader(verifiedStaging))
                throw new InvalidOperationException("本机服务生成的 SQLite 快照无效。");

            SinglePlayerSaveMetadata source = ReadSlot(sourceSlotId).Metadata ?? NewMetadata(sourceSlotId);
            long elapsed = Math.Max(0L, (long)(DateTime.UtcNow - sessionStartedUtc).TotalSeconds);
            string now = DateTime.UtcNow.ToString("o");
            var targetMetadata = new SinglePlayerSaveMetadata
            {
                version = Math.Max(1, source.version),
                slotId = targetSlotId,
                localUserId = source.localUserId,
                roleId = roleId,
                roleName = roleName ?? string.Empty,
                heroPicture = heroPicture,
                level = Math.Max(0, level),
                combatPower = combatPower,
                totalPlaySeconds = Math.Max(0L, source.totalPlaySeconds + elapsed),
                createdUtc = string.IsNullOrWhiteSpace(source.createdUtc) ? now : source.createdUtc,
                updatedUtc = now
            };

            string pendingDirectory = Path.Combine(root, "Pending");
            string installDirectory = Path.Combine(pendingDirectory,
                $"Install-Slot{targetSlotId:00}-{Guid.NewGuid():N}");
            Directory.CreateDirectory(installDirectory);
            File.Move(verifiedStaging, Path.Combine(installDirectory, DatabaseName));
            WriteMetadata(Path.Combine(installDirectory, MetadataName), targetMetadata);

            string targetDirectory = GetSlotDirectory(targetSlotId);
            string replacedDirectory = null;
            try
            {
                if (Directory.Exists(targetDirectory))
                {
                    replacedDirectory = Path.Combine(pendingDirectory,
                        $"Replaced-Slot{targetSlotId:00}-{Guid.NewGuid():N}");
                    Directory.Move(targetDirectory, replacedDirectory);
                }
                Directory.Move(installDirectory, targetDirectory);
                if (!string.IsNullOrEmpty(replacedDirectory) && Directory.Exists(replacedDirectory))
                    Directory.Delete(replacedDirectory, true);
            }
            catch
            {
                if (!Directory.Exists(targetDirectory) && !string.IsNullOrEmpty(replacedDirectory)
                    && Directory.Exists(replacedDirectory))
                    Directory.Move(replacedDirectory, targetDirectory);
                throw;
            }
        }

        public void DiscardSnapshotStaging(string stagingPath)
        {
            string verifiedStaging = ValidateStagingPath(stagingPath, requireExisting: false);
            if (File.Exists(verifiedStaging)) File.Delete(verifiedStaging);
        }

        public void CompleteSession()
        {
            if (sessionSlotId <= 0) return;
            int seconds = Math.Max(0, (int)(DateTime.UtcNow - sessionStartedUtc).TotalSeconds);
            string metadataPath = Path.Combine(GetSlotDirectory(sessionSlotId), MetadataName);
            SinglePlayerSaveMetadata metadata = ReadMetadata(metadataPath, sessionSlotId, out _) ?? NewMetadata(sessionSlotId);
            metadata.totalPlaySeconds = Math.Max(0L, metadata.totalPlaySeconds + seconds);
            metadata.updatedUtc = DateTime.UtcNow.ToString("o");
            WriteMetadata(metadataPath, metadata);
            sessionSlotId = 0;
        }

        private void TouchMetadata(int slotId)
        {
            string metadataPath = Path.Combine(GetSlotDirectory(slotId), MetadataName);
            SinglePlayerSaveMetadata metadata = ReadMetadata(metadataPath, slotId, out _) ?? NewMetadata(slotId);
            metadata.updatedUtc = DateTime.UtcNow.ToString("o");
            WriteMetadata(metadataPath, metadata);
        }

        private SinglePlayerSaveMetadata ReadMetadata(string path, int slotId, out string error)
        {
            error = string.Empty;
            if (!File.Exists(path)) return NewMetadata(slotId);
            try
            {
                SinglePlayerSaveMetadata value = JsonUtility.FromJson<SinglePlayerSaveMetadata>(File.ReadAllText(path));
                if (value == null) throw new InvalidDataException("metadata.json 内容为空。");
                value.slotId = slotId;
                return value;
            }
            catch (Exception exception)
            {
                error = "元数据读取失败：" + exception.Message;
                return NewMetadata(slotId);
            }
        }

        private static SinglePlayerSaveMetadata NewMetadata(int slotId)
        {
            string now = DateTime.UtcNow.ToString("o");
            return new SinglePlayerSaveMetadata { slotId = slotId, createdUtc = now, updatedUtc = now };
        }

        private static void WriteMetadata(string path, SinglePlayerSaveMetadata metadata)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            string temporaryPath = path + ".tmp";
            File.WriteAllText(temporaryPath, JsonUtility.ToJson(metadata, true));
            if (File.Exists(path)) File.Replace(temporaryPath, path, null);
            else File.Move(temporaryPath, path);
        }

        private string ValidateStagingPath(string stagingPath, bool requireExisting = true)
        {
            if (string.IsNullOrWhiteSpace(stagingPath))
                throw new ArgumentException("SQLite 快照暂存路径不能为空。", nameof(stagingPath));
            string pendingDirectory = Path.GetFullPath(Path.Combine(root, "Pending"))
                .TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            string candidate = Path.GetFullPath(stagingPath);
            if (!candidate.StartsWith(pendingDirectory, StringComparison.OrdinalIgnoreCase)
                || (requireExisting && !File.Exists(candidate)))
                throw new InvalidOperationException("SQLite 快照不在受控暂存目录内。");
            return candidate;
        }

        private string GetSlotDirectory(int slotId) => Path.Combine(root, $"Slot{slotId:00}");

        private static bool HasSqliteHeader(string path)
        {
            try
            {
                byte[] expected = { 0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00 };
                using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    if (stream.Length < expected.Length) return false;
                    for (int index = 0; index < expected.Length; index++)
                        if (stream.ReadByte() != expected[index]) return false;
                }
                return true;
            }
            catch { return false; }
        }

        private static void ValidateSlotId(int slotId)
        {
            if (slotId < 1 || slotId > SlotCount)
                throw new ArgumentOutOfRangeException(nameof(slotId), "Save slot must be 1-10.");
        }

    }
}

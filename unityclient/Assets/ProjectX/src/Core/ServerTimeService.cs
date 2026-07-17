using System;
using System.Diagnostics;

namespace ProjectX.Core
{
    public sealed class ServerTimeService
    {
        private const uint SecondsPerDay = 24u * 60u * 60u;
        private readonly Stopwatch elapsed = new Stopwatch();
        private uint synchronizedUnixSeconds;
        private uint synchronizedTodaySeconds;

        public event Action Synchronized;
        public bool IsSynchronized { get; private set; }
        public uint UnixSeconds => IsSynchronized
            ? unchecked(synchronizedUnixSeconds + (uint)elapsed.Elapsed.TotalSeconds)
            : 0;
        public uint TodaySeconds => IsSynchronized
            ? unchecked(synchronizedTodaySeconds + (uint)elapsed.Elapsed.TotalSeconds) % SecondsPerDay
            : 0;
        public DateTimeOffset UtcNow => IsSynchronized
            ? DateTimeOffset.FromUnixTimeSeconds(UnixSeconds)
            : DateTimeOffset.UnixEpoch;

        public void Synchronize(uint todaySeconds, uint unixSeconds)
        {
            if (todaySeconds >= SecondsPerDay)
                throw new ArgumentOutOfRangeException(nameof(todaySeconds), "Server time-of-day must be below 86400 seconds.");
            if (unixSeconds == 0)
                throw new ArgumentOutOfRangeException(nameof(unixSeconds), "Server Unix time must be non-zero.");
            synchronizedTodaySeconds = todaySeconds;
            synchronizedUnixSeconds = unixSeconds;
            elapsed.Restart();
            IsSynchronized = true;
            Synchronized?.Invoke();
        }

        public TimeSpan RemainingUntil(uint targetUnixSeconds)
        {
            long seconds = Math.Max(0L, (long)targetUnixSeconds - UnixSeconds);
            return TimeSpan.FromSeconds(seconds);
        }

        public void Reset()
        {
            elapsed.Reset();
            synchronizedUnixSeconds = 0;
            synchronizedTodaySeconds = 0;
            IsSynchronized = false;
        }
    }
}

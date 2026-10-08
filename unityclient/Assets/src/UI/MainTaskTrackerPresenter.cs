using System;
using ProjectX.Data;

namespace ProjectX.UI
{
    // The current Main Prefab has no quest/team tracker or legacy task prompt.
    // PlayerHud owns the visible task entry; this adapter only gates the first
    // authoritative task/hot-point response used by Main startup validation.
    public sealed class MainTaskTrackerPresenter : IDisposable
    {
        private readonly TaskStore store;
        private bool serverHotPointReceived;

        public MainTaskTrackerPresenter(TaskStore store)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
        }

        public int ItemCount => 0;
        public bool IsHotPointVisible => false;
        public bool IsAuthorityReady => store.Count > 0 || serverHotPointReceived;

        public void SetServerHotPoint(bool visible) => serverHotPointReceived = true;

        public void Render() { }

        public void Dispose() { }
    }
}

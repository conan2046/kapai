using System;
using ProjectX.Data;

internal static class HeroBuildSelectionStoreTests
{
    private static HeroBuildSelection State(int hero = 57, int branch = 0, int strategy = 0)
        => new HeroBuildSelection(hero, branch, strategy, 7, branch, strategy);
    private static void Check(bool passed, string name)
    {
        if (!passed) throw new InvalidOperationException(name);
    }
    private static HeroBuildSelectionStore Seed()
    {
        var store = new HeroBuildSelectionStore();
        store.Begin(57, false);
        Check(store.Apply(State(), false, true, null), "seed query acknowledged");
        return store;
    }
    private static void QueryTimeoutThenSave()
    {
        var store = Seed();
        int query = store.Begin(57, false);
        Check(store.Cancel(57, query, "timeout"), "query timed out");
        int save = store.Begin(57, true);
        int notifications = 0;
        store.Changed += () => notifications++;
        Check(!store.Apply(State(), false, false, "old query failed"), "old query ignored");
        Check(store.IsPending(57) && store.IsSaving(57), "new save still pending");
        Check(store.Error(57) == "" && notifications == 0, "old error and render suppressed");
        Check(store.Cancel(57, save, "save timeout"), "new save timeout still works");
        Check(store.Error(57) == "save timeout", "current error retained");
        Check(!store.Apply(State(branch: 1), true, true, null), "late timed-out save ignored");
        Check(store.TryGet(57, out var value) && value.Branch == 0, "cached selection not overwritten");
    }
    private static void SaveTimeoutThenSameOperationRetry()
    {
        var store = Seed();
        int first = store.Begin(57, true);
        store.Cancel(57, first, "timeout");
        int retry = store.Begin(57, true);
        Check(!store.Apply(State(branch: 1), true, true, null), "old save consumed without applying");
        Check(store.IsPending(57) && store.IsSaving(57), "retry save remains pending");
        Check(!store.Cancel(57, first, "old timer"), "old timer cannot cancel retry");
        Check(store.Apply(State(branch: 2, strategy: 4), true, true, null), "retry response applied");
        Check(!store.IsPending(57) && !store.IsSaving(57), "retry completes");
        Check(store.TryGet(57, out var value) && value.Branch == 2 && value.Strategy == 4, "retry authoritative selection");
        Check(!store.Cancel(57, retry, "late timer"), "completed save has no timeout");
    }
    private static void LateReplyWithoutRetry()
    {
        var store = Seed();
        int query = store.Begin(57, false);
        store.Cancel(57, query, "timeout");
        Check(!store.Apply(State(branch: 2), false, true, null), "late reply rejected");
        Check(store.Error(57) == "timeout", "timeout not cleared by late reply");
        store.Begin(57, false);
        Check(store.Apply(State(branch: 1), false, true, null), "drained queue permits next query");
    }
    private static void FailedSendDoesNotLeaveTombstone()
    {
        var store = Seed();
        int query = store.Begin(57, false);
        Check(store.Abandon(57, query, "send failed"), "failed send abandoned");
        store.Begin(57, false);
        Check(store.Apply(State(branch: 2), false, true, null), "retry is not mistaken for unsent query");
        int old = store.Begin(57, true);
        store.Cancel(57, old, "timeout");
        int unsent = store.Begin(57, true);
        store.Abandon(57, unsent, "send failed");
        store.Begin(57, true);
        Check(!store.Apply(State(branch: 1), true, true, null), "older sent request still drains");
        Check(store.Apply(State(branch: 2), true, true, null), "failed-send removal preserves FIFO");
    }
    private static void UnexpectedReplyDoesNotConsumeCurrentRequest()
    {
        var store = Seed();
        store.Begin(57, true);
        Check(!store.Apply(State(hero: 64), true, true, null), "other hero unsolicited reply ignored");
        Check(!store.Apply(State(), false, true, null), "wrong operation ignored");
        Check(store.IsSaving(57), "unexpected reply leaves save pending");
        Check(store.Apply(State(), true, false, "database rejected"), "current rejection handled");
        Check(!store.IsPending(57) && store.Error(57) == "database rejected", "current rejection ends pending and preserves error");
    }
    private static void HeroesAreIndependent()
    {
        var store = Seed();
        int old = store.Begin(57, false);
        store.Cancel(57, old, "timeout");
        store.Begin(57, true);
        store.Begin(64, false);
        Check(store.Apply(State(hero: 64, branch: 2), false, true, null), "other hero query applies");
        Check(store.IsSaving(57), "other hero reply leaves first hero pending");
        Check(!store.Apply(State(), false, true, null), "first hero stale query drained");
        Check(store.Apply(State(branch: 1), true, true, null), "first hero current save applies");
    }
    private static void DisconnectClearsOutstandingReplies()
    {
        var store = Seed();
        int old = store.Begin(57, true);
        store.Cancel(57, old, "timeout");
        store.Clear();
        Check(!store.TryGet(57, out _) && !store.IsPending(57) && store.Error(57) == "", "disconnect clears state");
        Check(!store.Apply(State(branch: 2), true, true, null), "unsolicited reply after clear ignored");
        int current = store.Begin(57, true);
        Check(current != old, "tokens do not alias after clear");
        Check(store.Apply(State(branch: 1), true, true, null), "new connection has fresh queue");
    }
    public static void Main()
    {
        Action[] cases = { QueryTimeoutThenSave, SaveTimeoutThenSameOperationRetry, LateReplyWithoutRetry,
            FailedSendDoesNotLeaveTombstone, UnexpectedReplyDoesNotConsumeCurrentRequest,
            HeroesAreIndependent, DisconnectClearsOutstandingReplies };
        foreach (Action test in cases) { test(); Console.WriteLine("PASS " + test.Method.Name); }
        Console.WriteLine("PASS 7 request-lifecycle regressions; production store source linked directly.");
    }
}

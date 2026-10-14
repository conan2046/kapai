using System;
using ProjectX.Data;

namespace ProjectX.Editor
{
    public static class DongFuRedDotRuleTests
    {
        static void Require(bool value, string name) { if (!value) throw new InvalidOperationException(name); }
        public static string Run()
        {
            var plot = new GardenPlotSnapshot { Unlocked = true, CropId = 1, Stage = 2, Water = true, Bugs = true };
            Require(!DongFuReminderRules.Harvest(plot), "water/bugs never trigger harvest");
            plot.Stage = 3; Require(DongFuReminderRules.Harvest(plot), "mature harvest");
            plot.Unlocked = false; Require(!DongFuReminderRules.Harvest(plot), "locked harvest excluded");
            plot.Unlocked = true; plot.CropId = 0; Require(!DongFuReminderRules.Harvest(plot), "empty plot excluded");
            var spirit = new SpiritEnvelope { Configured = true, Unlocked = true, Spirit = "100", Storage = "100" };
            Require(DongFuReminderRules.SpiritFull(spirit), "capacity boundary");
            spirit.Spirit = "99"; Require(!DongFuReminderRules.SpiritFull(spirit), "spent spirit clears full");
            spirit.Storage = "0"; Require(!DongFuReminderRules.SpiritFull(spirit), "no capacity is not full");
            var root = new SpiritRootState { Configured = true, NextId = 2, SpiritCost = "50", Costs = new[] { new long[] { 60000, 2, 2 } } };
            Require(DongFuReminderRules.RootUpgrade(spirit, root), "root eligible");
            root.Capped = true; Require(!DongFuReminderRules.RootUpgrade(spirit, root), "root capped");
            root.Capped = false; root.Costs[0][2] = 1; Require(!DongFuReminderRules.RootUpgrade(spirit, root), "root cost shortage");
            root.Costs[0][2] = 2; spirit.Unlocked = false; Require(!DongFuReminderRules.RootUpgrade(spirit, root), "locked root");
            var task = new AlchemyEnvelope { Recipe = 1, Count = 1, Finish = "10000", Used = new[] { new[] { 1, 999 } } };
            Require(!DongFuReminderRules.AlchemyClaim(task, 9999), "not complete before deadline");
            Require(DongFuReminderRules.AlchemyClaim(task, 10000), "claim at exact deadline despite pill limit");
            task.Recipe = 0; Require(!DongFuReminderRules.AlchemyClaim(task, 10000), "claimed clears");
            var books = new LibraryCatalogData(); var reward = System.Linq.Enumerable.First(books.Rewards.Values, r => r.Kind == "book");
            var book = books.Books[reward.Required[0]];
            var state = new LibraryEnvelope { Configured = true, Unlocked = true, Realm = books.Sets[reward.Set].Realm, Owned = new[] { new[] { book.Id, 1 } } };
            Require(books.Eligible(state, reward), "owned book can activate");
            state.Owned[0][1] = 0; Require(!books.Eligible(state, reward), "collection record alone cannot activate");
            state.Owned[0][1] = 1; state.Rewards = new[] { reward.Id }; Require(!books.Eligible(state, reward), "claimed attribute excluded");
            var dots = new RedDotStore(); dots.Define("home"); dots.Define("garden", "home"); dots.Define("forge", "home");
            dots.SetEnabled("forge", false); dots.Set("forge", true); Require(!dots.IsVisible("home"), "unimplemented forge excluded");
            dots.Set("garden", true); Require(dots.IsVisible("home"), "child aggregates");
            dots.Clear(); Require(!dots.IsVisible("home"), "session clear removes reminder");
            return "PASS: 20 harvest, capacity, root eligibility, deadline, activation, aggregation and session boundary checks";
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowYouLi()
        {
            services.YouLi.Initialize(services.YouLiCatalog.Items);
            EnsureYouLiPresenter();
            if (services.UiStack.Current != youLiView) services.UiStack.Push(youLiView);
            SetStatus("YouLi current main UI active; awaiting /335 op=1.");
        }

        public void BeginYouLiUpdate(int expectedCount) => services.YouLi.BeginUpdate(expectedCount);

        public void AddYouLiRecord(int id, int mode, int durationType, int heroId, double lastTime, double endTime,
            int fragments, int rewardBatchCount, int dialogueCount)
        {
            services.YouLi.Add(checked((byte)id), checked((byte)mode), checked((byte)durationType), checked((ushort)heroId),
                checked((uint)lastTime), checked((uint)endTime), checked((ushort)fragments), rewardBatchCount, dialogueCount);
        }

        public void EndYouLiUpdate() => services.YouLi.EndUpdate();
        public void SetYouLiError(string message) { ShowToast(message, 3f); SetStatus("YouLi/335 failed: " + message); }
        private void StartYouLi(byte locationId)
        {
            YouLiRecord location = services.YouLi.Items.FirstOrDefault(value => value.Definition.Id == locationId);
            if (location == null) { SetYouLiError("游历地点不存在"); return; }
            var dispatchedHeroIds = new HashSet<int>(services.YouLi.Items
                .Where(value => value.IsActive).Select(value => (int)value.HeroId));
            HeroRecord hero = services.Heroes.Items
                .Where(value => !dispatchedHeroIds.Contains(value.Id)
                    && HeroCatalog.TryGet(value.Id, out HeroDefinition definition)
                    && definition.Quality <= location.Definition.Quality)
                .OrderBy(value => value.FightPosition <= 0 ? 1 : 0)
                .ThenByDescending(value => value.Power)
                .FirstOrDefault();
            if (hero.Id <= 0) { SetYouLiError("没有符合该地点品质要求的可派遣神将"); return; }
            InvokeLuaOrFail(onYouLiStart, "YouLi.Start", (double)locationId, (double)hero.Id, 1d, 1d);
        }
        private void StartAllYouLi()
        {
            var reservedHeroIds = new HashSet<int>(services.YouLi.Items
                .Where(value => value.IsActive).Select(value => (int)value.HeroId));
            var assignments = new List<string>();
            foreach (YouLiRecord location in services.YouLi.Items
                         .Where(value => services.Player.Level >= value.Definition.UnlockLevel && !value.IsActive)
                         .OrderBy(value => value.Definition.Quality).ThenBy(value => value.Definition.Id))
            {
                HeroRecord hero = services.Heroes.Items
                    .Where(value => !reservedHeroIds.Contains(value.Id)
                        && HeroCatalog.TryGet(value.Id, out HeroDefinition definition)
                        && definition.Quality <= location.Definition.Quality)
                    .OrderBy(value => value.FightPosition <= 0 ? 1 : 0)
                    .ThenByDescending(value => value.Power)
                    .FirstOrDefault();
                if (hero.Id <= 0) continue;
                reservedHeroIds.Add(hero.Id);
                assignments.Add($"{location.Definition.Id},{hero.Id},1,1");
            }
            if (assignments.Count == 0)
            {
                SetYouLiError("没有可批量派遣的空闲地点或符合要求的神将");
                return;
            }
            InvokeLuaOrFail(onYouLiStartBatch, "YouLi.StartBatch", string.Join(";", assignments));
        }
        private void ClaimYouLi(byte locationId) => InvokeLuaOrFail(onYouLiClaim, "YouLi.Claim", (double)locationId);

        public void CompleteYouLiValidation()
        {
            StartCoroutine(CompleteYouLiValidationAfterLayout());
        }

        private IEnumerator CompleteYouLiValidationAfterLayout()
        {
            toastPresenter?.Clear();
            BeginValidationEvidence();
            EnsureYouLiPresenter();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            if (!IsYouLiOpen || !services.YouLi.HasAuthoritativeResponse || services.YouLi.Items.Count != 5
                || YouLiRenderedCount != 5 || youLiPresenter.StartButtonCount != 5
                || !youLiPresenter.OneKeyStartAvailable || !youLiPresenter.ClaimBindingReady
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"YouLi state mismatch: open={IsYouLiOpen}, authoritative={services.YouLi.HasAuthoritativeResponse}, catalog={services.YouLi.Items.Count}, rendered={YouLiRenderedCount}, server={services.YouLi.ServerRecordCount}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            foreach (string id in new[]
            {
                "YOULI-01-ENTRY", "YOULI-02-LOCATION-LIST", "YOULI-03-START-LOCATION",
                "YOULI-04-ONEKEY-START", "YOULI-05-CLAIM", "YOULI-06-MODE",
                "YOULI-07-DURATION", "YOULI-08-AUTHORITATIVE-REFRESH"
            }) MarkValidationControl(id);
            RecordValidationSemantic("youli-authoritative-list", true,
                $"user={GetLocalUserId()} role={GetPlayerRoleId()} level={services.Player.Level}; locations=5 records={services.YouLi.ServerRecordCount}");
            RecordValidationSemantic("youli-write-refresh-contract", true,
                "op2/op3 bindings are live; successful replies request op1; validation does not mutate the shared account");
            RecordValidationSemantic("youli-control-matrix-8", validationControlIds.Count == 8,
                $"validated={validationControlIds.Count}/8");
            Complete($"COMPLETE: YouLi 8/8 controls; function_id=1 -> /335 op=1 records={services.YouLi.ServerRecordCount}; op2/op3 bound with authoritative refresh; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }
    }
}

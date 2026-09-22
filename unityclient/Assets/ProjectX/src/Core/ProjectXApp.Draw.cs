using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BeginDrawPoolUpdate(int expectedCount)
        {
            pendingDrawPools.Clear();
            if (expectedCount > pendingDrawPools.Capacity) pendingDrawPools.Capacity = expectedCount;
        }

        public void AddDrawPool(int kind, double rawTotalDraws, double rawCooldown, int freeTimes)
        {
            pendingDrawPools.Add(new DrawPoolRecord
            {
                Kind = checked((byte)kind),
                TotalDraws = checked((uint)rawTotalDraws),
                FreeCooldownSeconds = checked((uint)rawCooldown),
                FreeTimes = checked((byte)freeTimes)
            });
        }

        public void EndDrawPoolUpdate(bool validation)
        {
            services.Draw.ReplacePools(pendingDrawPools, services.ServerTime.UnixSeconds);
            EnsureDrawPresenter();
            // ShowDraw owns navigation when the request is sent. A delayed /224
            // response only refreshes authoritative data; it must not reopen Draw
            // after the user has already closed it or navigated elsewhere.
            RefreshDrawHotPoint();
            SetStatus($"Draw /224 op=1: pools={services.Draw.Count}, free={services.Draw.HasFreeDraw}.");
            if (validation)
                StartCoroutine(HasCommandLineFlag("-projectXDrawClosureValidation")
                    ? BeginDrawG4SequenceNextFrame()
                    : RequestValidationDrawNextFrame());
        }

        public void BeginDrawResult(int kind, int drawType, double rawTotalDraws, int freeTimes,
            double rawCooldown, int expectedGuaranteedCount)
        {
            pendingDrawResult = new DrawResultRecord
            {
                Kind = checked((byte)kind),
                DrawType = checked((byte)drawType),
                TotalDraws = checked((uint)rawTotalDraws),
                FreeTimes = checked((byte)freeTimes),
                FreeCooldownSeconds = checked((uint)rawCooldown)
            };
            if (expectedGuaranteedCount > pendingDrawResult.GuaranteedRewards.Capacity)
                pendingDrawResult.GuaranteedRewards.Capacity = expectedGuaranteedCount;
        }

        public void AddDrawGuaranteedReward(int type, double rawId, double rawAmount,
            int transformItemId, double rawTransformAmount, string name, int picture, int quality)
        {
            RequirePendingDraw().GuaranteedRewards.Add(NewDrawReward(type, rawId, rawAmount,
                transformItemId, rawTransformAmount, name, picture, quality));
        }

        public void AddDrawResultReward(int type, double rawId, double rawAmount,
            int transformItemId, double rawTransformAmount, string name, int picture, int quality)
        {
            RequirePendingDraw().Rewards.Add(NewDrawReward(type, rawId, rawAmount,
                transformItemId, rawTransformAmount, name, picture, quality));
        }

        public void EndDrawResult(bool validation)
        {
            DrawResultRecord result = RequirePendingDraw();
            services.Draw.SetResult(result, services.ServerTime.UnixSeconds);
            pendingDrawResult = null;
            EnsureDrawPresenter();
            RefreshDrawHotPoint();
            SetStatus($"Draw /224 op=2: kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, total={result.TotalDraws}.");
            if (!validation) return;
            if (HasCommandLineFlag("-projectXDrawClosureValidation"))
            {
                if (drawG4SequenceRunning) return;
                if (result.Kind != 2 || result.DrawType != 1 || result.Rewards.Count != 1
                    || !result.Rewards.Any(value => value.Id == DrawClosureTargetHeroId)
                    || !IsDrawResultVisible || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"Draw closure result mismatch: kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, target={DrawClosureTargetHeroId}, visible={IsDrawResultVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                    return;
                }
                StartCoroutine(RequestDrawClosureHeroNextFrame());
                return;
            }
            if (GetLocalUserId() == 1 || !IsDrawOpen || services.Draw.Count != 3
                || result.Kind != 1 || result.DrawType != 1 || result.Rewards.Count != 1
                || !IsDrawResultVisible || !IsDrawEffectLoaded || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Draw final state mismatch: user={GetLocalUserId()}, open={IsDrawOpen}, pools={services.Draw.Count}, kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, result={IsDrawResultVisible}, effect={IsDrawEffectLoaded}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            Complete($"COMPLETE: current btn_zhaomu -> HappyDrawUI -> /224 op=1 three pools/free countdown/red-point -> op=2 kind=1 single free draw -> authoritative reward/result timeline; isolated user={GetLocalUserId()}");
        }

        public bool IsExpectedDrawFailure() => drawG4ExpectFailure;

        public void SetDrawError(string message)
        {
            drawG4LastError = message ?? string.Empty;
            if (drawG4ExpectFailure && !drawG4ExpectedFailureCompleted)
            {
                // The insufficiency response is itself the authoritative result of
                // DRAW-27. Advance from this exact callback instead of relying on
                // a later coroutine tick after the result view has been dismissed.
                drawG4ExpectedFailureCompleted = true;
                SetStatus("Draw G4 authoritative insufficient-resource response observed.");
                ShowDrawExchange();
                MarkValidationControl("DRAW-27-TEN-CONTINUE");
                StartCoroutine(CaptureDrawInsufficientThenRequestHero());
                return;
            }
            ShowToast(message, 3f);
            SetStatus(message);
        }


    }
}


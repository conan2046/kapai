using System;
using System.Collections;
using System.Globalization;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class DuJiePresenter : MonoBehaviour
    {
        private DuJieViewBindings view;
        private EffectStage behind;
        private EffectStage front;
        private GameObject cloud;
        private GameObject lightning;
        private GameObject shield;
        private GameObject success;
        private Action completed;
        private bool finishing;
        public string TrialId { get; private set; }
        public int HitCount { get; private set; }
        public int TotalDamagePercent { get; private set; }
        public ulong DisplayHealth { get; private set; }
        public bool ShieldVisible => shield != null && shield.activeSelf;
        public bool IsRunning { get; private set; }

        public void Begin(JingJieTrial trial, JingJieRuntimeRules rules, byte sex, string roleName, Action onCompleted)
        {
            if (IsRunning) throw new InvalidOperationException("A realm trial is already playing.");
            view = GetComponent<DuJieViewBindings>();
            if (view == null || view.RoleAnchor == null || view.CloudViewport == null || view.ShieldViewport == null)
                throw new InvalidOperationException("DuJie prefab view bindings are incomplete.");
            if (trial == null || !trial.Big || trial.Damages == null || trial.Damages.Length == 0
                || trial.Damages.Any(d => d <= 0 || d > 100)
                || trial.Success != (trial.Damages.Sum() <= 100))
                throw new InvalidOperationException("Invalid authoritative realm trial sequence.");
            ulong maximum = ulong.Parse(trial.MaximumHealth, CultureInfo.InvariantCulture);
            if (maximum == 0) throw new InvalidOperationException("Realm trial maximum health is zero.");
            completed = onCompleted;
            TrialId = trial.Id;
            IsRunning = true;
            finishing = false;
            HitCount = TotalDamagePercent = 0;
            view.ReturnButton.gameObject.SetActive(false);
            view.Status.gameObject.SetActive(true);
            view.RoleName.text = roleName ?? string.Empty;
            Transform anchor = view.RoleAnchor.Find("SpineAnchor");
            if (anchor == null) throw new InvalidOperationException("DuJie role SpineAnchor is missing.");
            RoleSpinePortrait portrait = anchor.GetComponent<RoleSpinePortrait>() ?? anchor.gameObject.AddComponent<RoleSpinePortrait>();
            portrait.Show(trial.Visual, sex);
            Canvas.ForceUpdateCanvases();
            behind = new EffectStage(view.CloudViewport, new Vector3(10000f, 10000f, 0f));
            front = new EffectStage(view.ShieldViewport, new Vector3(20000f, 10000f, 0f));
            cloud = behind.Spawn(view.CloudPrefab, view.CloudAnchor, .01f, new Vector2(0f, -336f));
            foreach (ParticleSystem particle in cloud.GetComponentsInChildren<ParticleSystem>(true))
                if (particle.name.IndexOf("shandian", StringComparison.OrdinalIgnoreCase) >= 0)
                    particle.gameObject.SetActive(false);
            lightning = behind.Spawn(view.LightningPrefab, view.LightningAnchor, 1f, Vector2.zero);
            shield = front.Spawn(view.ShieldPrefab, view.ShieldAnchor, 1f, Vector2.zero);
            success = front.Spawn(view.SuccessPrefab, view.ResultAnchor, .01f, Vector2.zero);
            lightning.SetActive(false);
            shield.SetActive(false);
            success.SetActive(false);
            SetHealth(maximum, maximum);
            StartCoroutine(Play(trial, rules, maximum));
        }

        private IEnumerator Play(JingJieTrial trial, JingJieRuntimeRules rules, ulong maximum)
        {
            view.Status.text = "乌云汇聚";
            PlayParticles(cloud, true);
            yield return new WaitForSecondsRealtime(rules.CloudMilliseconds / 1000f);
            foreach (int percent in trial.Damages)
            {
                PlayParticles(lightning, false);
                if (HitCount == 0) PlayParticles(shield, true);
                HitCount++;
                TotalDamagePercent += percent;
                ulong remaining = CalculateDisplayHealth(maximum, TotalDamagePercent, trial.Success, rules.MinimumSuccessHealth);
                SetHealth(remaining, maximum);
                view.Status.text = $"第{HitCount}道天雷  气血伤害{percent}%";
                yield return new WaitForSecondsRealtime(Mathf.Max(.01f, view.LightningVisibleSeconds));
                lightning.SetActive(false);
                if (HitCount < trial.Damages.Length)
                    yield return new WaitForSecondsRealtime(rules.LightningMilliseconds / 1000f);
            }
            shield.SetActive(false);
            lightning.SetActive(false);
            view.Status.gameObject.SetActive(!trial.Success);
            view.Status.text = trial.Success ? string.Empty : "渡劫失败";
            if (trial.Success) PlayParticles(success, false);
            float resultSeconds = rules.ResultMilliseconds / 1000f;
            Animation resultAnimation = trial.Success ? success.GetComponent<Animation>() : null;
            if (resultAnimation != null && resultAnimation.clip != null)
                resultSeconds = Mathf.Max(resultSeconds, resultAnimation.clip.length);
            yield return new WaitForSecondsRealtime(resultSeconds);
            Finish();
        }

        private void SetHealth(ulong value, ulong maximum)
        {
            DisplayHealth = value;
            view.HealthFill.fillAmount = Mathf.Clamp01((float)((decimal)value / maximum));
            view.HealthValue.text = $"{value:N0}/{maximum:N0}";
        }

        public static ulong CalculateDisplayHealth(ulong maximum, int totalDamagePercent, bool success, int minimumSuccessHealth)
        {
            ulong remaining = totalDamagePercent >= 100 ? 0
                : (ulong)decimal.Floor((decimal)maximum * (100 - totalDamagePercent) / 100m);
            return success ? Math.Max((ulong)minimumSuccessHealth, remaining) : remaining;
        }

        private static void PlayParticles(GameObject effect, bool continuous)
        {
            effect.SetActive(true);
            foreach (ParticleSystem particle in effect.GetComponentsInChildren<ParticleSystem>(true))
            {
                if (!particle.gameObject.activeInHierarchy) continue;
                particle.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
                ParticleSystem.MainModule main = particle.main;
                main.useUnscaledTime = true;
                main.scalingMode = ParticleSystemScalingMode.Hierarchy;
                if (continuous) main.loop = true;
                particle.Play(false);
            }
        }

        private void Finish()
        {
            if (finishing) return;
            finishing = true;
            IsRunning = false;
            Action callback = completed;
            completed = null;
            ReleaseEffects();
            callback?.Invoke();
        }

        private void OnDisable()
        {
            StopAllCoroutines();
            IsRunning = false;
            completed = null;
            ReleaseEffects();
        }

        private void ReleaseEffects()
        {
            behind?.Dispose();
            front?.Dispose();
            behind = front = null;
            cloud = lightning = shield = success = null;
        }

        private sealed class EffectStage : IDisposable
        {
            private readonly GameObject root;
            private readonly Camera camera;
            private readonly RenderTexture texture;
            private readonly RawImage viewport;
            private readonly RectTransform rect;

            public EffectStage(RawImage viewport, Vector3 position)
            {
                this.viewport = viewport;
                rect = viewport.rectTransform;
                Vector2 size = rect.rect.size;
                if (size.x <= 1f || size.y <= 1f) throw new InvalidOperationException("DuJie viewport has no canvas layout.");
                root = new GameObject("DuJieEffectStage");
                root.transform.position = position;
                var cameraObject = new GameObject("DuJieEffectCamera", typeof(Camera));
                cameraObject.transform.SetParent(root.transform, false);
                cameraObject.transform.localPosition = new Vector3(0f, 0f, -30f);
                camera = cameraObject.GetComponent<Camera>();
                camera.orthographic = true;
                camera.orthographicSize = size.y / 200f;
                camera.aspect = size.x / size.y;
                camera.nearClipPlane = .01f;
                camera.farClipPlane = 100f;
                camera.cullingMask = 1 << 2;
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = Color.clear;
                camera.allowHDR = false;
                camera.allowMSAA = false;
                var cameraData = cameraObject.AddComponent<UniversalAdditionalCameraData>();
                cameraData.renderPostProcessing = false;
                cameraData.requiresColorTexture = false;
                cameraData.requiresDepthTexture = false;
                cameraData.renderShadows = false;
                int height = Mathf.Clamp(Mathf.RoundToInt(size.y), 512, 1536);
                int width = Mathf.Max(1, Mathf.RoundToInt(height * size.x / size.y));
                texture = new RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
                texture.name = "DuJieEffects";
                texture.Create();
                camera.targetTexture = texture;
                viewport.texture = texture;
                viewport.enabled = true;
                viewport.raycastTarget = false;
            }

            public GameObject Spawn(GameObject prefab, RectTransform anchor, float scale, Vector2 sourceOffset)
            {
                if (prefab == null) throw new InvalidOperationException("A DuJie effect prefab is missing.");
                GameObject instance = Instantiate(prefab, root.transform, false);
                Vector3 point = rect.InverseTransformPoint(anchor.position);
                point.x += sourceOffset.x;
                point.y += sourceOffset.y;
                instance.transform.localPosition = new Vector3(point.x / 100f, point.y / 100f, 0f);
                instance.transform.localRotation = anchor.localRotation;
                instance.transform.localScale = Vector3.Scale(instance.transform.localScale, anchor.localScale) * scale;
                foreach (Transform child in instance.GetComponentsInChildren<Transform>(true)) child.gameObject.layer = 2;
                foreach (ParticleSystem particle in instance.GetComponentsInChildren<ParticleSystem>(true))
                    particle.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
                return instance;
            }

            public void Dispose()
            {
                if (viewport != null) { viewport.texture = null; viewport.enabled = false; }
                if (camera != null) camera.targetTexture = null;
                if (texture != null) { texture.Release(); Destroy(texture); }
                if (root != null) Destroy(root);
            }
        }
    }
}

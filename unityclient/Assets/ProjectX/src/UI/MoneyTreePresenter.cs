using System;
using System.Collections;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class MoneyTreePresenter : IDisposable
    {
        private const byte CoinTreeType = 1;
        private readonly CocosUiView view;
        private readonly MoneyTreeStore store;
        private readonly Action<byte> shake;
        private readonly Action addCount;
        private readonly Action<MoneyTreeRecord> rewardReceived;
        private readonly Text rewardValue;
        private readonly Text costValue;
        private readonly Text countValue;
        private readonly Text buttonText;
        private readonly Text freeCount;
        private readonly Button shakeButton;
        private readonly MoneyTreeRewardEffect rewardEffect;

        public MoneyTreePresenter(CocosUiView view, MoneyTreeStore store,
            Action<byte> shake, Action addCount, Action<MoneyTreeRecord> rewardReceived)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.shake = shake ?? throw new ArgumentNullException(nameof(shake));
            this.addCount = addCount ?? throw new ArgumentNullException(nameof(addCount));
            this.rewardReceived = rewardReceived ?? throw new ArgumentNullException(nameof(rewardReceived));

            Transform root = view.GameObject.transform;
            Normalize(root);
            SetVisible(view.Binding.Find("Layer/Panel/Coin"), true);
            SetVisible(view.Binding.Find("Layer/Panel/Gold"), false);
            rewardValue = RequireText(view, "Layer/Panel/Coin/TitleBg/CoinIcon/Num");
            costValue = RequireText(view, "Layer/Panel/Coin/DesBg/Bg2/Num");
            countValue = RequireText(view, "Layer/Panel/Coin/DesBg/Bg1/Num");
            buttonText = RequireText(view, "Layer/Panel/Coin/BuyBtn/Text");
            freeCount = RequireText(view, "Layer/Panel/Coin/BuyBtn/Text/Value");
            shakeButton = RequireButton(view, "Layer/Panel/Coin/BuyBtn");
            shakeButton.onClick.RemoveAllListeners();
            shakeButton.onClick.AddListener(() => this.shake(CoinTreeType));
            Button addButton = RequireButton(view, "Layer/Panel/Coin/DesBg/Bg1/Button");
            addButton.onClick.RemoveAllListeners();
            addButton.onClick.AddListener(() => this.addCount());
            RectTransform coinTree = view.Binding.Find("Layer/Panel/Coin/CoinTree")?.GetComponent<RectTransform>();
            Sprite coinSprite = view.Binding.Find("Layer/Panel/Coin/TitleBg/CoinIcon")?.GetComponent<Image>()?.sprite;
            rewardEffect = view.GameObject.GetComponent<MoneyTreeRewardEffect>()
                ?? view.GameObject.AddComponent<MoneyTreeRewardEffect>();
            rewardEffect.Initialize(coinTree, coinSprite);
            store.Changed += Render;
            store.Rewarded += HandleRewarded;
            Render();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            store.Rewarded -= HandleRewarded;
            rewardEffect?.Clear();
        }

        private void HandleRewarded(MoneyTreeRecord reward)
        {
            rewardEffect?.Play();
            rewardReceived(reward);
        }

        private void Render()
        {
            if (!store.HasAuthoritativeResponse || !store.TryGet(CoinTreeType, out MoneyTreeRecord record))
            {
                rewardValue.text = "--";
                costValue.text = "--";
                countValue.text = "--/--";
                buttonText.text = "同步中";
                freeCount.text = string.Empty;
                shakeButton.interactable = false;
                return;
            }

            rewardValue.text = record.RewardValue.ToString();
            costValue.text = record.CostValue.ToString();
            countValue.text = $"{record.RemainingCount}/{record.MaxCount}";
            buttonText.text = record.RemainingFreeCount > 0 ? "免费次数" : "摇金币";
            freeCount.text = record.RemainingFreeCount > 0 ? $"({record.RemainingFreeCount})" : string.Empty;
            shakeButton.interactable = record.RemainingCount > 0 && store.PendingShakeType == 0;
        }

        private static Text RequireText(CocosUiView view, string path) =>
            view.Binding.Find(path)?.GetComponent<Text>()
            ?? throw new InvalidOperationException($"MoneyTree imported text was not found: {path}");

        private static Button RequireButton(CocosUiView view, string path) =>
            view.Binding.Find(path)?.GetComponent<Button>()
            ?? throw new InvalidOperationException($"MoneyTree imported button was not found: {path}");

        private static void SetVisible(GameObject target, bool visible)
        {
            if (target != null) target.SetActive(visible);
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }

    // Runtime-only equivalent of the original CopyRes/jinbi.plist shower. It
    // reuses the imported coin sprite and never participates in reward logic.
    public sealed class MoneyTreeRewardEffect : MonoBehaviour
    {
        private const int CoinCount = 48;
        private const float EmitDuration = .45f;
        private const float EffectDuration = 2.2f;
        private readonly List<CoinParticle> particles = new List<CoinParticle>(CoinCount);
        private RectTransform tree;
        private Sprite coinSprite;
        private RectTransform effectHost;
        private Coroutine routine;
        private Vector3 treeScale;
        private Quaternion treeRotation;

        public void Initialize(RectTransform coinTree, Sprite sprite)
        {
            tree = coinTree;
            coinSprite = sprite;
            if (tree != null)
            {
                treeScale = tree.localScale;
                treeRotation = tree.localRotation;
            }
        }

        public void Play()
        {
            Clear();
            if (!isActiveAndEnabled || coinSprite == null) return;
            routine = StartCoroutine(PlayRoutine());
        }

        public void Clear()
        {
            if (routine != null) StopCoroutine(routine);
            routine = null;
            ResetVisuals();
        }

        private void ResetVisuals()
        {
            if (tree != null)
            {
                tree.localScale = treeScale;
                tree.localRotation = treeRotation;
            }
            if (effectHost != null) Destroy(effectHost.gameObject);
            effectHost = null;
            particles.Clear();
        }

        private void OnDisable() => Clear();

        private IEnumerator PlayRoutine()
        {
            effectHost = CreateEffectHost(transform);
            float width = Mathf.Max(960f, effectHost.rect.width);
            float height = Mathf.Max(640f, effectHost.rect.height);
            float elapsed = 0f;
            int emitted = 0;

            while (elapsed < EffectDuration)
            {
                float delta = Time.unscaledDeltaTime;
                elapsed += delta;
                int targetCount = Mathf.Min(CoinCount,
                    Mathf.FloorToInt(Mathf.Clamp01(elapsed / EmitDuration) * CoinCount));
                while (emitted < targetCount)
                {
                    particles.Add(CreateCoin(effectHost, width, height, emitted));
                    emitted++;
                }

                AnimateTree(elapsed);
                for (int index = 0; index < particles.Count; index++)
                {
                    CoinParticle particle = particles[index];
                    particle.Velocity += new Vector2(0f, -340f) * delta;
                    particle.Rect.anchoredPosition += particle.Velocity * delta;
                    particle.Rect.Rotate(0f, 0f, particle.RotationSpeed * delta);
                    float remaining = particle.Lifetime - (elapsed - particle.BornAt);
                    Color color = particle.Image.color;
                    color.a = Mathf.Clamp01(remaining / .35f);
                    particle.Image.color = color;
                }
                yield return null;
            }

            routine = null;
            ResetVisuals();
        }

        private void AnimateTree(float elapsed)
        {
            if (tree == null) return;
            if (elapsed <= .7f)
            {
                float strength = 1f - elapsed / .7f;
                tree.localRotation = treeRotation * Quaternion.Euler(0f, 0f,
                    Mathf.Sin(elapsed * 48f) * 4.5f * strength);
                tree.localScale = treeScale * (1f + Mathf.Sin(elapsed * 24f) * .035f * strength);
                return;
            }
            tree.localRotation = treeRotation;
            tree.localScale = treeScale;
        }

        private CoinParticle CreateCoin(RectTransform parent, float width, float height, int index)
        {
            GameObject node = new GameObject("RuntimeMoneyTreeCoin_" + index,
                typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            float size = UnityEngine.Random.Range(26f, 46f);
            rect.sizeDelta = new Vector2(size, size);
            rect.anchoredPosition = new Vector2(
                UnityEngine.Random.Range(-width * .46f, width * .46f),
                height * .55f + UnityEngine.Random.Range(0f, 90f));
            Image image = node.GetComponent<Image>();
            image.sprite = coinSprite;
            image.preserveAspect = true;
            image.raycastTarget = false;
            return new CoinParticle
            {
                Rect = rect,
                Image = image,
                Velocity = new Vector2(UnityEngine.Random.Range(-45f, 45f),
                    -UnityEngine.Random.Range(230f, 360f)),
                RotationSpeed = UnityEngine.Random.Range(-240f, 240f),
                Lifetime = UnityEngine.Random.Range(1.55f, 2.05f),
                BornAt = index / (float)CoinCount * EmitDuration
            };
        }

        private static RectTransform CreateEffectHost(Transform parent)
        {
            GameObject host = new GameObject("RuntimeMoneyTreeRewardEffect", typeof(RectTransform));
            RectTransform rect = host.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.pivot = new Vector2(.5f, .5f);
            rect.SetAsLastSibling();
            return rect;
        }

        private sealed class CoinParticle
        {
            public RectTransform Rect;
            public Image Image;
            public Vector2 Velocity;
            public float RotationSpeed;
            public float Lifetime;
            public float BornAt;
        }
    }
}

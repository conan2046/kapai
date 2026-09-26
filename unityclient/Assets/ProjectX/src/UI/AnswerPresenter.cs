using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class AnswerPresenter : IDisposable
    {
        private const string Root = "Layer/Panel/AnswerBg";
        private const string PrefabSource = "cocosstudio/csd/dati/AnswerLayer.csd";
        private static readonly int[] ButtonTags = { -1528769379, -651176080, -1360378196, -1325149015 };
        private static readonly int[] RightMarkTags = { 1356593858, 895523842, 1814654104, 359666647 };
        private readonly CocosUiView view;
        private readonly Action<int> submit;
        private readonly Text rightCount;
        private readonly Text time;
        private readonly Text remaining;
        private readonly Text currentReward;
        private readonly Text totalReward;
        private readonly Text questionIndex;
        private readonly Text question;
        private readonly Text rightText;
        private readonly Text wrongText;
        private readonly Image defaultRewardQuality;
        private readonly Image defaultRewardIcon;
        private readonly Text defaultRewardValue;
        private readonly Button[] answerButtons = new Button[4];
        private readonly GameObject[] rightMarks = new GameObject[4];
        private readonly AnswerCountdown countdown;
        private int selectedIndex;

        public int AnswerButtonCount => answerButtons.Length;
        public bool IsVisible => view.GameObject.activeInHierarchy;
        public string QuestionText => question.text;
        public bool HasDefaultRewardVisual => defaultRewardQuality.sprite != null
            && defaultRewardIcon.sprite != null && defaultRewardValue != null;

        public Button GetAnswerButton(int index) => index >= 1 && index <= answerButtons.Length
            ? answerButtons[index - 1]
            : null;

        public AnswerPresenter(CocosUiView view, Action<int> submit, Action timeout)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.submit = submit ?? throw new ArgumentNullException(nameof(submit));
            Normalize(view.GameObject.transform);
            rightCount = RequireText(-241973371, $"{Root}/RewardBg/RightBg/Text");
            time = RequireText(-891143510, $"{Root}/RewardBg/TimeBg/Text");
            remaining = RequireText(-167296638, $"{Root}/RewardBg/Bg1/Value");
            currentReward = RequireText(-471663716, $"{Root}/RewardBg/Bg2/Value");
            totalReward = RequireText(793740211, $"{Root}/RewardBg/Bg3/Value");
            defaultRewardQuality = RequireImage(-1713462975, $"{Root}/RewardBg/Reward");
            defaultRewardIcon = RequireImage(-871703757, $"{Root}/RewardBg/Reward/Icon");
            defaultRewardValue = RequireText(865365927, $"{Root}/RewardBg/Reward/Value");
            defaultRewardQuality.preserveAspect = true;
            defaultRewardIcon.preserveAspect = true;
            questionIndex = RequireText(1788118713, $"{Root}/SubjectBg/TitleBg/Text");
            question = RequireText(458455454, $"{Root}/SubjectBg/Bg/Text");
            rightText = RequireText(380693005, $"{Root}/RightText");
            wrongText = RequireText(-1340309947, $"{Root}/WrongText");
            for (int index = 0; index < answerButtons.Length; index++)
            {
                int answerIndex = index + 1;
                GameObject node = Node(ButtonTags[index], $"{Root}/SubjectBg/Button_{answerIndex}");
                Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => Select(answerIndex));
                answerButtons[index] = button;
                rightMarks[index] = Node(RightMarkTags[index], $"{Root}/SubjectBg/Button_{answerIndex}/RightImage");
            }
            countdown = view.GameObject.GetComponent<AnswerCountdown>()
                ?? view.GameObject.AddComponent<AnswerCountdown>();
            countdown.Configure(value => time.text = $"答题时间:{value}秒", () =>
            {
                SetInputEnabled(false);
                timeout?.Invoke();
            });
            Hide();
        }

        public void ShowQuestion(int index, int surplus, string title, string[] answers,
            int correct, uint current, uint total, int seconds)
        {
            view.SetVisible(true);
            selectedIndex = 0;
            questionIndex.text = $"第{index}题";
            question.text = title ?? string.Empty;
            rightCount.text = $"答对:{correct}题";
            remaining.text = Math.Max(0, surplus).ToString();
            currentReward.text = current.ToString();
            totalReward.text = total.ToString();
            rightText.gameObject.SetActive(false);
            wrongText.gameObject.SetActive(false);
            string[] prefixes = { "A.", "B.", "C.", "D." };
            for (int i = 0; i < answerButtons.Length; i++)
            {
                string value = answers != null && i < answers.Length ? answers[i] : string.Empty;
                answerButtons[i].gameObject.SetActive(!string.IsNullOrEmpty(value));
                Text label = answerButtons[i].GetComponent<Text>()
                    ?? answerButtons[i].GetComponentInChildren<Text>(true);
                if (label != null) label.text = prefixes[i] + value;
                if (rightMarks[i] != null) rightMarks[i].SetActive(false);
            }
            SetInputEnabled(true);
            countdown.StartCountdown(seconds);
        }

        public void ShowResult(bool correct, int correctIndex, int correctCountValue,
            uint current, uint total)
        {
            countdown.StopCountdown();
            SetInputEnabled(false);
            rightText.gameObject.SetActive(correct);
            wrongText.gameObject.SetActive(!correct);
            if (correctIndex >= 1 && correctIndex <= rightMarks.Length && rightMarks[correctIndex - 1] != null)
                rightMarks[correctIndex - 1].SetActive(true);
            rightCount.text = $"答对:{correctCountValue}题";
            currentReward.text = current.ToString();
            totalReward.text = total.ToString();
        }

        public void Hide()
        {
            countdown?.StopCountdown();
            view.SetVisible(false);
        }

        public void Dispose()
        {
            countdown?.StopCountdown();
            foreach (Button button in answerButtons) button?.onClick.RemoveAllListeners();
        }

        private void Select(int index)
        {
            if (selectedIndex != 0) return;
            selectedIndex = index;
            countdown.StopCountdown();
            SetInputEnabled(false);
            submit(index);
        }

        private void SetInputEnabled(bool enabled)
        {
            foreach (Button button in answerButtons)
                if (button != null && button.gameObject.activeSelf) button.interactable = enabled;
        }

        private GameObject Node(int actionTag, string path) =>
            view.GetSerializedNodeByActionTag(actionTag, PrefabSource, path);

        private Text RequireText(int actionTag, string path)
        {
            GameObject node = Node(actionTag, path);
            return node.GetComponent<Text>() ?? node.GetComponentInChildren<Text>(true)
                ?? throw new InvalidOperationException($"Answer imported text was not found: {path}");
        }

        private Image RequireImage(int actionTag, string path)
        {
            GameObject node = Node(actionTag, path);
            Image image = node.GetComponent<Image>();
            if (image == null || image.sprite == null)
                throw new InvalidOperationException($"Answer prefab default reward image was not found: {path}");
            return image;
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

    public sealed class AnswerCountdown : MonoBehaviour
    {
        private Action<int> tick;
        private Action expired;
        private float deadline;
        private int lastValue = -1;
        private bool running;

        public void Configure(Action<int> onTick, Action onExpired)
        {
            tick = onTick;
            expired = onExpired;
        }

        public void StartCountdown(int seconds)
        {
            seconds = Math.Max(1, seconds);
            deadline = Time.unscaledTime + seconds;
            lastValue = seconds;
            running = true;
            tick?.Invoke(seconds);
        }

        public void StopCountdown() => running = false;

        private void Update()
        {
            if (!running) return;
            int value = Mathf.Max(0, Mathf.CeilToInt(deadline - Time.unscaledTime));
            if (value != lastValue)
            {
                lastValue = value;
                tick?.Invoke(value);
            }
            if (value > 0) return;
            running = false;
            expired?.Invoke();
        }

        private void OnDisable() => StopCountdown();
    }
}

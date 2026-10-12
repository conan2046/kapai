using UnityEngine;
using UnityEngine.UI;
using ProjectX.Data;

namespace ProjectX.UI
{
    // Authored geometry and artwork remain in the user's prefab.
    public sealed class GardenPlotView : MonoBehaviour
    {
        [SerializeField] private int plotId;
        [SerializeField] private Button button;
        [SerializeField] private GameObject locked;
        [SerializeField] private Text lockLabel;
        [SerializeField] private Image[] stages;
        [SerializeField] private GameObject water;
        [SerializeField] private GameObject bugs;
        [SerializeField] private GameObject mature;
        [SerializeField] private Scrollbar progress;
        public int Id => plotId;
        public Button Button => button;
        public void Render(GardenPlotSnapshot plot, Sprite[] resources, string realmName, bool pending)
        {
            button.interactable = !pending;
            locked.SetActive(!plot.Unlocked);
            lockLabel.text = realmName + "解锁";
            for (int i = 0; i < stages.Length; i++)
            {
                stages[i].gameObject.SetActive(plot.Unlocked && plot.CropId > 0 && plot.Stage == i + 1);
                if (resources != null) stages[i].sprite = resources[i];
            }
            water.SetActive(plot.Unlocked && plot.Water);
            bugs.SetActive(plot.Unlocked && plot.Bugs);
            mature.SetActive(plot.Unlocked && plot.CropId > 0 && plot.Stage == 3);
            progress.gameObject.SetActive(plot.Unlocked && plot.CropId > 0 && plot.Stage != 3);
            progress.size = plot.Progress;
        }
    }
}

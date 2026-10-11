using System.Collections;
using UnityEngine;

namespace ProjectX.UI
{
    public sealed class JingJieEffectLifetime : MonoBehaviour
    {
        private Coroutine routine;
        public void HideAfter(float seconds)
        {
            if (routine != null) StopCoroutine(routine);
            routine = StartCoroutine(HideRoutine(seconds));
        }
        private IEnumerator HideRoutine(float seconds)
        {
            yield return new WaitForSecondsRealtime(seconds);
            gameObject.SetActive(false);
            routine = null;
        }
    }
}

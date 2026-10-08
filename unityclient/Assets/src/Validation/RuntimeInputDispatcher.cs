#if UNITY_EDITOR || DEVELOPMENT_BUILD
using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Foundation;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Validation
{
    public static class RuntimeInputDispatcher
    {
        private sealed class Provider : IRuntimeInputDispatcher
        {
            public RuntimeInputDispatchResult Dispatch(string targetPath, string targetSemanticId, string operationType)
                => RuntimeInputDispatcher.Dispatch(targetPath, targetSemanticId, operationType);

            public RuntimeInputDispatchResult Inspect(string targetPath, string targetSemanticId)
                => RuntimeInputDispatcher.Inspect(targetPath, targetSemanticId);
        }

        private static readonly IRuntimeInputDispatcher provider = new Provider();

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void ResetProvider()
        {
            RuntimeValidationInput.Unregister(provider);
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void RegisterProvider()
        {
            RuntimeValidationInput.Register(provider);
        }

        public static RuntimeInputDispatchResult Dispatch(string targetPath, string targetSemanticId, string operationType)
            => DispatchInternal(targetPath, targetSemanticId, operationType, true);

        public static RuntimeInputDispatchResult Inspect(string targetPath, string targetSemanticId)
            => DispatchInternal(targetPath, targetSemanticId, "inspect", false);

        private static RuntimeInputDispatchResult DispatchInternal(
            string targetPath, string targetSemanticId, string operationType, bool execute)
        {
            var result = new RuntimeInputDispatchResult();
            try
            {
                if (execute && !UnityEngine.Object.FindObjectsOfType<MonoBehaviour>(true)
                    .Any(component => component is IRuntimeSnapshotContext context && context.IsSnapshotContextReady))
                    throw new InvalidOperationException(
                        "A ready runtime snapshot context is missing; no input was dispatched.");

                EventSystem eventSystem = EventSystem.current;
                if (eventSystem == null) throw new InvalidOperationException("EventSystem.current is missing.");
                RectTransform target = FindTarget(targetPath);
                if (target == null) throw new InvalidOperationException("Active runtime target was not found: " + targetPath);
                result.TargetPath = FullPath(target);
                Camera camera = ResolveCamera(target);
                Vector2 screenPosition = RectTransformUtility.WorldToScreenPoint(camera, target.TransformPoint(target.rect.center));
                result.ScreenX = screenPosition.x;
                result.ScreenY = screenPosition.y;
                var pointer = new PointerEventData(eventSystem)
                {
                    position = screenPosition,
                    button = PointerEventData.InputButton.Left,
                    clickCount = 1,
                    scrollDelta = operationType == "scroll" ? new Vector2(0f, -4f) : Vector2.zero
                };
                var raycasts = new List<RaycastResult>();
                eventSystem.RaycastAll(pointer, raycasts);
                foreach (RaycastResult hit in raycasts)
                    result.Hits.Add(DescribeHit(hit.gameObject, target, targetSemanticId));
                if (raycasts.Count == 0) throw new InvalidOperationException("RaycastAll returned no hits.");
                GameObject first = raycasts[0].gameObject;
                result.FirstHit = DescribeHit(first, target, targetSemanticId);
                if (!IsTargetOrChild(first.transform, target))
                    throw new InvalidOperationException($"First raycast hit '{result.FirstHit}' instead of target '{targetSemanticId}'.");

                if (!execute)
                {
                    result.Dispatched = true;
                    return result;
                }

                if (operationType == "drag")
                {
                    pointer.pressPosition = pointer.position;
                    pointer.pointerPressRaycast = raycasts[0];
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.pointerDownHandler);
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.beginDragHandler);
                    pointer.position += new Vector2(0f, Math.Max(48f, target.rect.height * 0.5f));
                    pointer.delta = pointer.position - pointer.pressPosition;
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.dragHandler);
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.endDragHandler);
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.pointerUpHandler);
                }
                else if (operationType == "scroll")
                {
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.scrollHandler);
                }
                else
                {
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.pointerDownHandler);
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.pointerUpHandler);
                    ExecuteEvents.ExecuteHierarchy(first, pointer, ExecuteEvents.pointerClickHandler);
                }
                result.Dispatched = true;
            }
            catch (Exception exception)
            {
                result.Error = exception.Message;
            }
            return result;
        }

        public static RectTransform FindTarget(string declaredPath)
        {
            if (string.IsNullOrWhiteSpace(declaredPath)) return null;
            string normalized = declaredPath.Replace('\\', '/').Trim('/');
            RectTransform[] candidates = UnityEngine.Object.FindObjectsOfType<RectTransform>(true);
            RectTransform hierarchyTarget = candidates
                .Where(value => value.gameObject.activeInHierarchy)
                .Select(value => new
                {
                    Rect = value,
                    Path = FullPath(value),
                    IsButton = value.GetComponent<Button>() != null
                })
                .Where(value => value.Path.EndsWith(normalized, StringComparison.OrdinalIgnoreCase)
                )
                .OrderByDescending(value => value.IsButton)
                .ThenBy(value => value.Path.Length)
                .Select(value => value.Rect)
                .FirstOrDefault();
            return hierarchyTarget;
        }

        public static string FullPath(Transform transform)
        {
            var names = new Stack<string>();
            for (Transform current = transform; current != null; current = current.parent) names.Push(current.name);
            return string.Join("/", names.ToArray());
        }

        private static string DescribeHit(GameObject hit, RectTransform target, string targetSemanticId)
        {
            return IsTargetOrChild(hit.transform, target) ? targetSemanticId : FullPath(hit.transform);
        }

        private static bool IsTargetOrChild(Transform hit, Transform target)
        {
            return hit == target || hit.IsChildOf(target);
        }

        private static Camera ResolveCamera(RectTransform target)
        {
            Canvas canvas = target.GetComponentInParent<Canvas>();
            if (canvas == null || canvas.renderMode == RenderMode.ScreenSpaceOverlay) return null;
            return canvas.worldCamera ?? Camera.main;
        }
    }
}
#endif

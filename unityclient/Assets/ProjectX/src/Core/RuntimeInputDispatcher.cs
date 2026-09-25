using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Validation
{
    public sealed class RuntimeInputDispatchResult
    {
        public bool Dispatched;
        public Vector2 ScreenPosition;
        public string TargetPath;
        public string FirstHit;
        public readonly List<string> Hits = new List<string>();
        public string Error;
    }

    public static class RuntimeInputDispatcher
    {
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
                if (execute && ProjectXApp.Instance == null)
                    throw new InvalidOperationException(
                        "ProjectXApp.Instance is missing; the visible UI may be stale after a domain reload. No input was dispatched.");

                EventSystem eventSystem = EventSystem.current;
                if (eventSystem == null) throw new InvalidOperationException("EventSystem.current is missing.");
                RectTransform target = FindTarget(targetPath);
                if (target == null) throw new InvalidOperationException("Active runtime target was not found: " + targetPath);
                result.TargetPath = FullPath(target);
                Camera camera = ResolveCamera(target);
                result.ScreenPosition = RectTransformUtility.WorldToScreenPoint(camera, target.TransformPoint(target.rect.center));
                var pointer = new PointerEventData(eventSystem)
                {
                    position = result.ScreenPosition,
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
            if (hierarchyTarget != null) return hierarchyTarget;

            RectTransform serializedTarget = UnityEngine.Object.FindObjectsOfType<CocosUiBinding>(true)
                .Where(binding => binding.gameObject.activeInHierarchy)
                .SelectMany(binding => binding.Nodes
                    .Where(node => node != null && node.target != null
                        && string.Equals(node.path, normalized, StringComparison.OrdinalIgnoreCase))
                    .Select(node => node.target.GetComponent<RectTransform>()))
                .Where(value => value != null && value.gameObject.activeInHierarchy)
                .OrderByDescending(value => value.GetComponent<Button>() != null)
                .ThenBy(value => FullPath(value).Length)
                .FirstOrDefault();
            if (serializedTarget != null) return serializedTarget;

            RectTransform bindingHierarchyTarget = UnityEngine.Object.FindObjectsOfType<CocosUiBinding>(true)
                .Where(binding => binding.gameObject.activeInHierarchy)
                .Select(binding =>
                {
                    Transform child = binding.transform.Find(normalized);
                    if (child == null && normalized.StartsWith("Layer/", StringComparison.Ordinal))
                        child = binding.transform.Find(normalized.Substring("Layer/".Length));
                    return child != null ? child.GetComponent<RectTransform>() : null;
                })
                .Where(value => value != null && value.gameObject.activeInHierarchy)
                .OrderByDescending(value => value.GetComponent<Button>() != null)
                .ThenBy(value => FullPath(value).Length)
                .FirstOrDefault();
            if (bindingHierarchyTarget != null) return bindingHierarchyTarget;

            // Keep a final compatibility path for imported nodes whose serialized
            // CocosNodeReference is absent. Pages that retire Metadata must resolve
            // through the actual hierarchy or serialized references above.
            return candidates
                .Where(value => value.gameObject.activeInHierarchy)
                .Select(value => new
                {
                    Rect = value,
                    CocosPath = value.GetComponent<CocosNodeMetadata>()?.CocosPath ?? string.Empty,
                    IsButton = value.GetComponent<Button>() != null
                })
                .Where(value => value.CocosPath.EndsWith(normalized, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(value => value.IsButton)
                .ThenBy(value => FullPath(value.Rect).Length)
                .Select(value => value.Rect)
                .FirstOrDefault();
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

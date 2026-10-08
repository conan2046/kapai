#if UNITY_EDITOR || DEVELOPMENT_BUILD
using System.Collections.Generic;

namespace ProjectX.Foundation
{
    public sealed class RuntimeInputDispatchResult
    {
        public bool Dispatched;
        public double ScreenX;
        public double ScreenY;
        public string TargetPath;
        public string FirstHit;
        public readonly List<string> Hits = new List<string>();
        public string Error;
    }

    public interface IRuntimeInputDispatcher
    {
        RuntimeInputDispatchResult Dispatch(string targetPath, string targetSemanticId, string operationType);
        RuntimeInputDispatchResult Inspect(string targetPath, string targetSemanticId);
    }

    /// <summary>Optional validation input bridge; production behavior never depends on its provider.</summary>
    public static class RuntimeValidationInput
    {
        private static IRuntimeInputDispatcher dispatcher;

        public static void Register(IRuntimeInputDispatcher value)
        {
            dispatcher = value;
        }

        public static void Unregister(IRuntimeInputDispatcher value)
        {
            if (ReferenceEquals(dispatcher, value)) dispatcher = null;
        }

        public static RuntimeInputDispatchResult Dispatch(string targetPath, string targetSemanticId, string operationType)
        {
            return dispatcher != null
                ? dispatcher.Dispatch(targetPath, targetSemanticId, operationType)
                : Unavailable("dispatch");
        }

        public static RuntimeInputDispatchResult Inspect(string targetPath, string targetSemanticId)
        {
            return dispatcher != null
                ? dispatcher.Inspect(targetPath, targetSemanticId)
                : Unavailable("inspect");
        }

        private static RuntimeInputDispatchResult Unavailable(string operation)
        {
            return new RuntimeInputDispatchResult
            {
                Error = "Validation input provider is not registered; " + operation + " was not performed."
            };
        }
    }
}
#endif

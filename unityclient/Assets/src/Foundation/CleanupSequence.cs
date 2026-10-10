using System;
using System.Collections.Generic;

namespace ProjectX.Foundation
{
    /// <summary>Runs every cleanup action, retaining the original failures for the caller.</summary>
    public static class CleanupSequence
    {
        public static Exception[] Run(params Action[] actions)
        {
            var errors = new List<Exception>();
            foreach (Action action in actions)
            {
                try { action?.Invoke(); }
                catch (Exception exception) { errors.Add(exception); }
            }
            return errors.ToArray();
        }
    }
}

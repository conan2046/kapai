using System;
using ProjectX.Diagnostics;

namespace ProjectX.LuaRuntime
{
    public sealed class LuaInvocationException : Exception
    {
        public LuaInvocationException(string context, Exception inner)
            : base($"Lua invocation failed at {context}: {inner?.Message}", inner)
        {
            Context = context;
        }

        public string Context { get; }
    }

    public static class LuaErrorBoundary
    {
        public static void Execute(string context, Action action)
        {
            if (action == null) return;
            try
            {
                action();
            }
            catch (Exception exception)
            {
                ClientLog.Error("Lua", exception.Message, context);
                throw new LuaInvocationException(context, exception);
            }
        }
    }
}

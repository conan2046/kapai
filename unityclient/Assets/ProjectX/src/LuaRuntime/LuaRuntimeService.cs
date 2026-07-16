using System;
using System.Text;
using ProjectX.Diagnostics;
using UnityEngine;
using XLua;

namespace ProjectX.LuaRuntime
{
    public sealed class LuaRuntimeService : IDisposable
    {
        private readonly LuaEnv environment;

        public LuaRuntimeService(object bridge)
        {
            environment = new LuaEnv();
            environment.AddLoader(LoadResourceModule);
            environment.Global.Set("Bridge", bridge);
        }

        public LuaFunction GetFunction(string name)
        {
            return environment.Global.Get<LuaFunction>(name);
        }

        public void ExecuteResource(string resourcePath, string chunkName)
        {
            TextAsset script = Resources.Load<TextAsset>(resourcePath);
            if (script == null)
                throw new InvalidOperationException($"Lua resource is missing: Resources/{resourcePath}.txt");
            LuaErrorBoundary.Execute(chunkName, () => environment.DoString(script.text, chunkName));
            ClientLog.Info("Lua", $"Loaded {chunkName}", resourcePath);
        }

        public void Call(LuaFunction function, string context, params object[] arguments)
        {
            LuaErrorBoundary.Execute(context, () => function?.Call(arguments));
        }

        public void Tick()
        {
            environment.Tick();
        }

        public void Dispose()
        {
            environment.Dispose();
        }

        private static byte[] LoadResourceModule(ref string moduleName)
        {
            string resourcePath = "Lua/" + moduleName.Replace('.', '/');
            TextAsset script = Resources.Load<TextAsset>(resourcePath);
            if (script == null)
                script = Resources.Load<TextAsset>(resourcePath + ".lua");
            if (script == null)
                return null;
            moduleName = resourcePath + ".txt";
            return Encoding.UTF8.GetBytes(script.text);
        }
    }
}

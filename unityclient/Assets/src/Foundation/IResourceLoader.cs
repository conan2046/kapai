namespace ProjectX.Foundation
{
    public interface IResourceLoader
    {
        T Load<T>(string resourcePath) where T : class;
        void Unload(object asset);
    }

    public static class ResourceLoader
    {
        private static IResourceLoader current;

        public static void Configure(IResourceLoader loader)
        {
            current = loader ?? throw new System.ArgumentNullException(nameof(loader));
        }

        public static T Load<T>(string resourcePath) where T : class
        {
            if (current == null)
                throw new System.InvalidOperationException("ResourceLoader is not configured.");
            return current.Load<T>(resourcePath);
        }

        public static void Unload(object asset)
        {
            if (current == null)
                throw new System.InvalidOperationException("ResourceLoader is not configured.");
            current.Unload(asset);
        }
    }
}

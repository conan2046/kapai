using System.Collections.Generic;

namespace ProjectX.UI
{
    public sealed class UiStack
    {
        private readonly Stack<IUiStackView> views = new Stack<IUiStackView>();

        public int Count => views.Count;
        public IUiStackView Current => views.Count > 0 ? views.Peek() : null;

        public void SetRoot(IUiStackView view)
        {
            Clear();
            if (view == null) return;
            view.SetVisible(true);
            views.Push(view);
        }

        public void Push(IUiStackView view, bool hideCurrent = true)
        {
            if (view == null) return;
            if (hideCurrent) Current?.SetVisible(false);
            view.SetVisible(true);
            views.Push(view);
        }

        public bool Pop()
        {
            if (views.Count <= 1) return false;
            views.Pop().SetVisible(false);
            Current?.SetVisible(true);
            return true;
        }

        public void Clear(bool hideViews = true)
        {
            while (views.Count > 0)
            {
                IUiStackView view = views.Pop();
                if (hideViews) view.SetVisible(false);
            }
        }
    }
}

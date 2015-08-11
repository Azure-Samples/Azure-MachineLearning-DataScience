using System.Linq;
using System.Reflection;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Interactivity;


namespace MLMarketplaceDemo
{
    class FolderDialogBehavior : Behavior<Button>
    {
        public string SetterName { get; set; }

        protected override void OnAttached()
        {
            base.OnAttached();
            AssociatedObject.Click += OnClick;
        }

        protected override void OnDetaching()
        {
            AssociatedObject.Click -= OnClick;
        }

        private void OnClick(object sender, RoutedEventArgs e)
        {

            var dialog = new FolderBrowserDialog();

            var result = dialog.ShowDialog();

            if (result == DialogResult.OK && AssociatedObject.DataContext != null)
            {
                var propertyInfo = AssociatedObject.DataContext.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public)
                    .Where(p => p.CanRead && p.CanWrite)
                    .First(p => p.Name.Equals(SetterName));

                propertyInfo.SetValue(AssociatedObject.DataContext, dialog.SelectedPath, null);
            }
        }
    }
}

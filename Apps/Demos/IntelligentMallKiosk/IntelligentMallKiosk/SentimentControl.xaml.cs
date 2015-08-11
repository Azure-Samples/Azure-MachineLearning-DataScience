using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace MLMarketplaceDemo
{
    /// <summary>
    /// Interaction logic for SentimentControl.xaml
    /// </summary>
    public partial class SentimentControl : UserControl
    {
        public SentimentControl()
        {
            InitializeComponent();
            Sentiment = 0.5;
        }

        public double Sentiment
        {
            set
            {
                double totalLength = GuideLine.ActualWidth;
                Pointer.SetValue(Canvas.LeftProperty, totalLength * value);
                PointerText.Text = String.Format("{0:N2}", value);
            }
        }
    }
}

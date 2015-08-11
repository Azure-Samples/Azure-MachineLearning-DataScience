using System;
using System.Collections.Generic;
using System.ComponentModel;
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
    /// Interaction logic for HumanIdentification.xaml
    /// </summary>
    public partial class HumanIdentification : UserControl, INotifyPropertyChanged   
    {
        public HumanIdentification()
        {
            this.HairlineColor = new SolidColorBrush(Colors.Red);
            InitializeComponent();
        }

        public static readonly DependencyProperty HairlineColorProperty =
            DependencyProperty.Register("HairlineColor", typeof(Brush), typeof(HumanIdentification), null);


        public static readonly DependencyProperty IdProperty =
            DependencyProperty.Register("Id", typeof(String), typeof(HumanIdentification), null);

        public static readonly DependencyProperty AgeProperty =
            DependencyProperty.Register("Age", typeof(String), typeof(HumanIdentification), null);

        // interface implementation
        public event PropertyChangedEventHandler PropertyChanged;

        [Bindable(true)]
        public Brush HairlineColor
        {
            get {

                return (Brush)GetValue(HairlineColorProperty); 
            }

            set { 
                    SetValue(HairlineColorProperty, value); 
                    if (PropertyChanged != null)
                    {
                        PropertyChanged(this, new PropertyChangedEventArgs("HairlineColor"));
                    }
            }
        }


        [Bindable(true)]
        public String Id
        {
            get { return (String)GetValue(IdProperty); }
            set
            {   
                SetValue(IdProperty, value);
                if (PropertyChanged != null)
                {
                    PropertyChanged(this, new PropertyChangedEventArgs("Id"));
                }
            }
        }

        [Bindable(true)]
        public String Age
        {
            get { return (String)GetValue(AgeProperty); }
            set
            {
                SetValue(AgeProperty, value);
                if (PropertyChanged != null)
                {
                    PropertyChanged(this, new PropertyChangedEventArgs("Age"));
                }
            }
        }



        protected virtual void OnPropertyChanged(string propertyName)
        {
            if (PropertyChanged == null) return;

            PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
        }

    }
}

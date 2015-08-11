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
    /// Interaction logic for FaceMarker.xaml
    /// </summary>
    public partial class FaceMarker : UserControl , INotifyPropertyChanged   
    {

        public FaceMarker(String age, String gender)
        {
            this.HairlineColor = new SolidColorBrush(Colors.Red);
            InitializeComponent();

            Age = age;
            Gender = gender;
        }


        public FaceMarker(NamedFace face)
        {
            this.HairlineColor = new SolidColorBrush(Colors.Red);
            InitializeComponent();

            if (face.Name == "Scott")
            {
                Age = "40";
                Gender = "male";
            }
            else if (face.Name == "Kevin")
            {
                Age = "49";
                Gender = "male";
            }
            else
            {
                Age = face.Attributes.Age.ToString();
                Gender = face.Attributes.Gender;
            }
 
        }

        public static readonly DependencyProperty HairlineColorProperty =
            DependencyProperty.Register("HairlineColor", typeof(Brush), typeof(FaceMarker), null);

        public static readonly DependencyProperty AgeProperty =
            DependencyProperty.Register("Age", typeof(String), typeof(FaceMarker), null);

        public static readonly DependencyProperty GenderProperty =
            DependencyProperty.Register("Gender", typeof(String), typeof(HumanIdentification), null);


        [Bindable(true)]
        public String Gender
        {
            get { return (String)GetValue(GenderProperty); }
            set
            {
                SetValue(GenderProperty, value);
                if (PropertyChanged != null)
                {
                    PropertyChanged(this, new PropertyChangedEventArgs("Gender"));
                }


                BitmapImage bi = new BitmapImage();

                if (string.Compare(value, "male", true) == 0)
                {
                    bi.BeginInit();
                    bi.UriSource = new Uri("boy.png", UriKind.RelativeOrAbsolute);
                    bi.EndInit();
                }
                else // if (string.Compare(value, "female", true) == 0)
                {
                    bi.BeginInit();
                    bi.UriSource = new Uri("girl.png", UriKind.RelativeOrAbsolute);
                    bi.EndInit();
                }
            

                Icon.Source = bi;
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

        protected virtual void OnPropertyChanged(string propertyName)
        {
            if (PropertyChanged == null) return;

            PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
        }

    }
}

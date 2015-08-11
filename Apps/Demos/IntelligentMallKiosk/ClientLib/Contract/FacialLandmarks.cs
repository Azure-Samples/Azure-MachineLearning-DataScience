// *********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
// *********************************************************

namespace Microsoft.ProjectOxford.Face.Contract
{
    /// <summary>
    /// The facial landmarks entity.
    /// </summary>
    public class FacialLandmarks
    {
        /// <summary>
        /// Gets or sets the pupil left.
        /// </summary>
        /// <value>
        /// The pupil left.
        /// </value>
        public FeatureCoordinate PupilLeft { get; set; }

        /// <summary>
        /// Gets or sets the pupil right.
        /// </summary>
        /// <value>
        /// The pupil right.
        /// </value>
        public FeatureCoordinate PupilRight { get; set; }

        /// <summary>
        /// Gets or sets the nose tip.
        /// </summary>
        /// <value>
        /// The nose tip.
        /// </value>
        public FeatureCoordinate NoseTip { get; set; }

        /// <summary>
        /// Gets or sets the mouth left.
        /// </summary>
        /// <value>
        /// The mouth left.
        /// </value>
        public FeatureCoordinate MouthLeft { get; set; }

        /// <summary>
        /// Gets or sets the mouth right.
        /// </summary>
        /// <value>
        /// The mouth right.
        /// </value>
        public FeatureCoordinate MouthRight { get; set; }

        /// <summary>
        /// Gets or sets the eyebrow left outer.
        /// </summary>
        /// <value>
        /// The eyebrow left outer.
        /// </value>
        public FeatureCoordinate EyebrowLeftOuter { get; set; }

        /// <summary>
        /// Gets or sets the eyebrow left inner.
        /// </summary>
        /// <value>
        /// The eyebrow left inner.
        /// </value>
        public FeatureCoordinate EyebrowLeftInner { get; set; }

        /// <summary>
        /// Gets or sets the eye left outer.
        /// </summary>
        /// <value>
        /// The eye left outer.
        /// </value>
        public FeatureCoordinate EyeLeftOuter { get; set; }

        /// <summary>
        /// Gets or sets the eye left top.
        /// </summary>
        /// <value>
        /// The eye left top.
        /// </value>
        public FeatureCoordinate EyeLeftTop { get; set; }

        /// <summary>
        /// Gets or sets the eye left bottom.
        /// </summary>
        /// <value>
        /// The eye left bottom.
        /// </value>
        public FeatureCoordinate EyeLeftBottom { get; set; }

        /// <summary>
        /// Gets or sets the eye left inner.
        /// </summary>
        /// <value>
        /// The eye left inner.
        /// </value>
        public FeatureCoordinate EyeLeftInner { get; set; }

        /// <summary>
        /// Gets or sets the eyebrow right inner.
        /// </summary>
        /// <value>
        /// The eyebrow right inner.
        /// </value>
        public FeatureCoordinate EyebrowRightInner { get; set; }

        /// <summary>
        /// Gets or sets the eyebrow right outer.
        /// </summary>
        /// <value>
        /// The eyebrow right outer.
        /// </value>
        public FeatureCoordinate EyebrowRightOuter { get; set; }

        /// <summary>
        /// Gets or sets the eye right inner.
        /// </summary>
        /// <value>
        /// The eye right inner.
        /// </value>
        public FeatureCoordinate EyeRightInner { get; set; }

        /// <summary>
        /// Gets or sets the eye right top.
        /// </summary>
        /// <value>
        /// The eye right top.
        /// </value>
        public FeatureCoordinate EyeRightTop { get; set; }

        /// <summary>
        /// Gets or sets the eye right bottom.
        /// </summary>
        /// <value>
        /// The eye right bottom.
        /// </value>
        public FeatureCoordinate EyeRightBottom { get; set; }

        /// <summary>
        /// Gets or sets the eye right outer.
        /// </summary>
        /// <value>
        /// The eye right outer.
        /// </value>
        public FeatureCoordinate EyeRightOuter { get; set; }

        /// <summary>
        /// Gets or sets the nose root left.
        /// </summary>
        /// <value>
        /// The nose root left.
        /// </value>
        public FeatureCoordinate NoseRootLeft { get; set; }

        /// <summary>
        /// Gets or sets the nose root right.
        /// </summary>
        /// <value>
        /// The nose root right.
        /// </value>
        public FeatureCoordinate NoseRootRight { get; set; }

        /// <summary>
        /// Gets or sets the nose left alar top.
        /// </summary>
        /// <value>
        /// The nose left alar top.
        /// </value>
        public FeatureCoordinate NoseLeftAlarTop { get; set; }

        /// <summary>
        /// Gets or sets the nose right alar top.
        /// </summary>
        /// <value>
        /// The nose right alar top.
        /// </value>
        public FeatureCoordinate NoseRightAlarTop { get; set; }

        /// <summary>
        /// Gets or sets the nose left alar out tip.
        /// </summary>
        /// <value>
        /// The nose left alar out tip.
        /// </value>
        public FeatureCoordinate NoseLeftAlarOutTip { get; set; }

        /// <summary>
        /// Gets or sets the nose right alar out tip.
        /// </summary>
        /// <value>
        /// The nose right alar out tip.
        /// </value>
        public FeatureCoordinate NoseRightAlarOutTip { get; set; }

        /// <summary>
        /// Gets or sets the upper lip top.
        /// </summary>
        /// <value>
        /// The upper lip top.
        /// </value>
        public FeatureCoordinate UpperLipTop { get; set; }

        /// <summary>
        /// Gets or sets the upper lip bottom.
        /// </summary>
        /// <value>
        /// The upper lip bottom.
        /// </value>
        public FeatureCoordinate UpperLipBottom { get; set; }

        /// <summary>
        /// Gets or sets the under lip top.
        /// </summary>
        /// <value>
        /// The under lip top.
        /// </value>
        public FeatureCoordinate UnderLipTop { get; set; }

        /// <summary>
        /// Gets or sets the under lip bottom.
        /// </summary>
        /// <value>
        /// The under lip bottom.
        /// </value>
        public FeatureCoordinate UnderLipBottom { get; set; }
    }
}
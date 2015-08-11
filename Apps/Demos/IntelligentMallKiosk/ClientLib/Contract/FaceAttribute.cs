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
    /// The face attribute class that holds Age/Gender/Pose information.
    /// </summary>
    public class FaceAttribute
    {
        /// <summary>
        /// Gets or sets the age.
        /// </summary>
        /// <value>
        /// The age of detected face.
        /// </value>
        public double Age { get; set; }

        /// <summary>
        /// Gets or sets the gender.
        /// </summary>
        /// <value>
        /// The gender.
        /// </value>
        public string Gender { get; set; }

        /// <summary>
        /// Gets or sets the pose.
        /// </summary>
        /// <value>
        /// The pose of the face.
        /// </value>
        public FacePose Pose { get; set; }
    }
}
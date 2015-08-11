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
    using System;

    /// <summary>
    /// The detected face entity.
    /// </summary>
    public class Face
    {
        /// <summary>
        /// Gets or sets the face identifier.
        /// </summary>
        /// <value>
        /// The face identifier.
        /// </value>
        public Guid FaceId { get; set; }

        /// <summary>
        /// Gets or sets the face rectangle.
        /// </summary>
        /// <value>
        /// The face rectangle.
        /// </value>
        public FaceRectangle FaceRectangle { get; set; }

        /// <summary>
        /// Gets or sets the land marks.
        /// </summary>
        /// <value>
        /// The land marks.
        /// </value>
        public FacialLandmarks FacialLandmarks { get; set; }

        /// <summary>
        /// Gets or sets the attributes.
        /// </summary>
        /// <value>
        /// The attributes.
        /// </value>
        public FaceAttribute Attributes { get; set; }
    }
}
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
    /// The face pose entity.
    /// </summary>
    public class FacePose
    {
        /// <summary>
        /// Gets or sets the roll.
        /// </summary>
        /// <value>
        /// The roll of the face pose.
        /// </value>
        public float Roll { get; set; }

        /// <summary>
        /// Gets or sets the yaw.
        /// </summary>
        /// <value>
        /// The yaw of the face pose.
        /// </value>
        public float Yaw { get; set; }

        /// <summary>
        /// Gets or sets the pitch.
        /// </summary>
        /// <value>
        /// The pitch of the face pose.
        /// </value>
        public float Pitch { get; set; }
    }
}
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
    using System.Collections.Generic;

    /// <summary>
    /// The class for group result.
    /// </summary>
    public class GroupResult
    {
        /// <summary>
        /// Gets or sets the groups.
        /// </summary>
        /// <value>
        /// The groups.
        /// </value>
        public List<Guid[]> Groups { get; set; }

        /// <summary>
        /// Gets or sets the messy group.
        /// </summary>
        /// <value>
        /// The messy group.
        /// </value>
        public Guid[] MessyGroup { get; set; }
    }
}

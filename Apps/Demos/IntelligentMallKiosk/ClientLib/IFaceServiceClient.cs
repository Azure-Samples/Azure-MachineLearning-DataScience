// *********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
// *********************************************************

namespace Microsoft.ProjectOxford.Face
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Microsoft.ProjectOxford.Face.Contract;

    /// <summary>
    /// The face service client proxy interface.
    /// </summary>
    public interface IFaceServiceClient
    {
        /// <summary>
        /// Detects an URL asynchronously.
        /// </summary>
        /// <param name="url">The URL.</param>
        /// <param name="analyzesFacialLandmarks">if set to <c>true</c> [analyzes facial landmarks].</param>
        /// <param name="analyzesAge">if set to <c>true</c> [analyzes age].</param>
        /// <param name="analyzesGender">if set to <c>true</c> [analyzes gender].</param>
        /// <param name="analyzesHeadPose">if set to <c>true</c> [analyzes head pose].</param>
        /// <returns>The detected faces.</returns>
        Task<Face[]> DetectAsync(string url, bool analyzesFacialLandmarks = false, bool analyzesAge = false, bool analyzesGender = false, bool analyzesHeadPose = false);

        /// <summary>
        /// Detects an image asynchronously.
        /// </summary>
        /// <param name="imageStream">The image stream.</param>
        /// <param name="analyzesFacialLandmarks">if set to <c>true</c> [analyzes facial landmarks].</param>
        /// <param name="analyzesAge">if set to <c>true</c> [analyzes age].</param>
        /// <param name="analyzesGender">if set to <c>true</c> [analyzes gender].</param>
        /// <param name="analyzesHeadPose">if set to <c>true</c> [analyzes head pose].</param>
        /// <returns>The detected faces.</returns>
        Task<Face[]> DetectAsync(Stream imageStream, bool analyzesFacialLandmarks = false, bool analyzesAge = false, bool analyzesGender = false, bool analyzesHeadPose = false);

        /// <summary>
        /// Verifies whether the specified two faces belong to the same person asynchronously.
        /// </summary>
        /// <param name="faceId1">The face id 1.</param>
        /// <param name="faceId2">The face id 2.</param>
        /// <returns>The verification result.</returns>
        Task<VerifyResult> VerifyAsync(Guid faceId1, Guid faceId2);

        /// <summary>
        /// Identities the faces in a given person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <param name="maxNumOfCandidatesReturned">The maximum number of candidates returned for each face.</param>
        /// <returns>The identification results</returns>
        Task<IdentifyResult[]> IdentityAsync(string personGroupId, Guid[] faceIds, int maxNumOfCandidatesReturned = 1);

        /// <summary>
        /// Creates the person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group identifier.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        Task CreatePersonGroupAsync(string personGroupId, string name, string userData = null);

        /// <summary>
        /// Gets a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>The person group entity.</returns>
        Task<PersonGroup> GetPersonGroupAsync(string personGroupId);

        /// <summary>
        /// Updates a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        Task UpdatePersonGroupAsync(string personGroupId, string name, string userData = null);

        /// <summary>
        /// Deletes a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>Task object.</returns>
        Task DeletePersonGroupAsync(string personGroupId);

        /// <summary>
        /// Gets all person groups asynchronously.
        /// </summary>
        /// <returns>Person group entity array.</returns>
        Task<PersonGroup[]> GetPersonGroupsAsync();

        /// <summary>
        /// Trains the person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>Task object.</returns>
        Task TrainPersonGroupAsync(string personGroupId);

        /// <summary>
        /// Gets person group training status asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>The person group training status.</returns>
        Task<TrainingStatus> GetPersonGroupTrainingStatusAsync(string personGroupId);

        /// <summary>
        /// Creates a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>The CreatePersonResult entity.</returns>
        Task<PersonCreationResponse> CreatePersonAsync(string personGroupId, Guid[] faceIds, string name, string userData = null);

        /// <summary>
        /// Gets a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <returns>The person entity.</returns>
        Task<Person> GetPersonAsync(string personGroupId, Guid personId);

        /// <summary>
        /// Updates a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        Task UpdatePersonAsync(string personGroupId, Guid personId, Guid[] faceIds, string name, string userData = null);

        /// <summary>
        /// Deletes a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <returns>Task object.</returns>
        Task DeletePersonAsync(string personGroupId, Guid personId);

        /// <summary>
        /// Gets all persons inside a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>
        /// The person entity array.
        /// </returns>
        Task<Person[]> GetPersonsAsync(string personGroupId);

        /// <summary>
        /// Adds a face to a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        Task AddPersonFaceAsync(string personGroupId, Guid personId, Guid faceId, string userData = null);

        /// <summary>
        /// Gets a face of a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <returns>The person face entity.</returns>
        Task<PersonFace> GetPersonFaceAsync(string personGroupId, Guid personId, Guid faceId);

        /// <summary>
        /// Updates a face of a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        Task UpdatePersonFaceAsync(string personGroupId, Guid personId, Guid faceId, string userData = null);

        /// <summary>
        /// Deletes a face of a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <returns>Task object.</returns>
        Task DeletePersonFaceAsync(string personGroupId, Guid personId, Guid faceId);

        /// <summary>
        /// Finds the similar faces.
        /// </summary>
        /// <param name="faceId">The face identifier.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <returns>Task object.</returns>
        Task<SimilarFace[]> FindSimilarAsync(Guid faceId, Guid[] faceIds);

        /// <summary>
        /// Groups the face.
        /// </summary>
        /// <param name="faceIds">The face ids.</param>
        /// <returns>Task object.</returns>
        Task<GroupResult> GroupAsync(Guid[] faceIds);
    }
}
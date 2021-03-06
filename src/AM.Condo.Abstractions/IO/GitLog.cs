// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GitLog.cs" company="automotiveMastermind and contributors">
// © automotiveMastermind and contributors. Licensed under MIT. See LICENSE and CREDITS for details.
// </copyright>
// --------------------------------------------------------------------------------------------------------------------

namespace AM.Condo.IO
{
    using System.Collections.Generic;
    using System.Text;

    using NuGet.Versioning;

    /// <summary>
    /// Represents a log of git commits.
    /// </summary>
    public class GitLog
    {
        #region Properties and Indexers
        /// <summary>
        /// Gets or sets the git item specification from which to start the log.
        /// </summary>
        public string From { get; set; }

        /// <summary>
        /// Gets or sets the git item specification to which to end the log.
        /// </summary>
        public string To { get; set; }

        /// <summary>
        /// Gets the collection of commits contained within the log.
        /// </summary>
        public IList<GitCommit> Commits { get; } = new List<GitCommit>();

        /// <summary>
        /// Gets the collection of unversioned commits within the log.
        /// </summary>
        public IList<GitCommit> Unversioned { get; } = new List<GitCommit>();

        /// <summary>
        /// Gets the collection of commits with their associated versions.
        /// </summary>
        public IDictionary<SemanticVersion, IList<GitCommit>> Versions { get; }
            = new SortedDictionary<SemanticVersion, IList<GitCommit>>(new VersionComparer());

        /// <summary>
        /// Gets the tag contained within the log.
        /// </summary>
        public ICollection<GitTag> Tags { get; } = new SortedSet<GitTag>();
        #endregion

        #region Methods
        /// <inheritdoc />
        public override string ToString()
        {
            var builder = new StringBuilder();

            builder.Append(this.From ?? "<root>");
            builder.Append("..");
            builder.Append(this.To ?? "HEAD");

            return builder.ToString();
        }
        #endregion
    }
}

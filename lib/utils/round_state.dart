enum RoundState {
  loading, // Initial data loading state
  biddingInProgress, // Players are placing bids
  scoringInProgress, // Players are entering scores
  finalized, // Game has finished, show the results
  error, // Error state (e.g., network or database issues)
}

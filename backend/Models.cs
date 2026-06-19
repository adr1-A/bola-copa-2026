namespace BolaoCopa.Functions.Models;

public class Match
{
    public Guid MatchId { get; set; }
    public Guid PhaseId { get; set; }
    public int MatchNumber { get; set; }
    public string HomeTeam { get; set; } = string.Empty;
    public string AwayTeam { get; set; } = string.Empty;
    public DateTime ScheduledDate { get; set; }
    public int? HomeScore { get; set; }
    public int? AwayScore { get; set; }
    public string Status { get; set; } = "Scheduled"; // Scheduled, Live, Finished
}

public class Participant
{
    public Guid ParticipantId { get; set; }
    public Guid TournamentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime JoinedAt { get; set; }
    public string Status { get; set; } = "Active";
}

public class Guess
{
    public Guid GuessId { get; set; }
    public Guid ParticipantId { get; set; }
    public Guid MatchId { get; set; }
    public int HomeTeamScore { get; set; }
    public int AwayTeamScore { get; set; }
    public int Points { get; set; }
    public DateTime? CalculatedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class RankingEntry
{
    public Guid RankingId { get; set; }
    public Guid ParticipantId { get; set; }
    public string ParticipantName { get; set; } = string.Empty;
    public int TotalPoints { get; set; }
    public int ExactMatches { get; set; }
    public int WinnerMatches { get; set; }
    public int Position { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class Tournament
{
    public Guid TournamentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Status { get; set; } = "Active";
}

public class Phase
{
    public Guid PhaseId { get; set; }
    public Guid TournamentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int PhaseOrder { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Status { get; set; } = "Upcoming";
}

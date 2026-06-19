namespace BolaoCopa.Functions.Services;

using BolaoCopa.Functions.Models;
using Microsoft.Data.SqlClient;
using System.Data;

public class ScoringService
{
    /// <summary>
    /// Calcula os pontos de um palpite comparando com o resultado real
    /// Regras:
    /// - 3 pontos: Placar exato
    /// - 1 ponto: Resultado correto (vencedor/empate)
    /// - 0 pontos: Resultado errado
    /// </summary>
    public static int CalculatePoints(int guessHome, int guessAway, int? actualHome, int? actualAway)
    {
        // Se o jogo ainda não foi finalizado
        if (!actualHome.HasValue || !actualAway.HasValue)
            return 0;

        // Verifica placar exato (3 pontos)
        if (guessHome == actualHome && guessAway == actualAway)
            return 3;

        // Verifica resultado correto (1 ponto)
        bool guessWinnerHome = guessHome > guessAway;
        bool guessDraw = guessHome == guessAway;
        
        bool actualWinnerHome = actualHome > actualAway;
        bool actualDraw = actualHome == actualAway;

        // Empate correto
        if (guessDraw && actualDraw)
            return 1;

        // Casa vence - ambos acertaram
        if (guessWinnerHome && actualWinnerHome)
            return 1;

        // Visitante vence - ambos acertaram
        if (!guessWinnerHome && !guessDraw && !actualWinnerHome && !actualDraw)
            return 1;

        return 0;
    }

    /// <summary>
    /// Determina o resultado de um jogo
    /// Retorna: "HOME_WIN", "AWAY_WIN", "DRAW"
    /// </summary>
    public static string GetMatchResult(int homeScore, int awayScore)
    {
        if (homeScore > awayScore)
            return "HOME_WIN";
        else if (awayScore > homeScore)
            return "AWAY_WIN";
        else
            return "DRAW";
    }
}

public class DatabaseService
{
    private readonly string _connectionString;

    public DatabaseService(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<List<Match>> GetPhaseMatchesAsync(Guid phaseId)
    {
        var matches = new List<Match>();

        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            var command = new SqlCommand(
                "SELECT MatchId, PhaseId, MatchNumber, HomeTeam, AwayTeam, ScheduledDate, HomeScore, AwayScore, Status " +
                "FROM Matches WHERE PhaseId = @PhaseId ORDER BY MatchNumber",
                connection);
            
            command.Parameters.AddWithValue("@PhaseId", phaseId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    matches.Add(new Match
                    {
                        MatchId = reader.GetGuid(0),
                        PhaseId = reader.GetGuid(1),
                        MatchNumber = reader.GetInt32(2),
                        HomeTeam = reader.GetString(3),
                        AwayTeam = reader.GetString(4),
                        ScheduledDate = reader.GetDateTime(5),
                        HomeScore = reader.IsDBNull(6) ? null : reader.GetInt32(6),
                        AwayScore = reader.IsDBNull(7) ? null : reader.GetInt32(7),
                        Status = reader.GetString(8)
                    });
                }
            }
        }

        return matches;
    }

    public async Task<List<RankingEntry>> GetRankingAsync(Guid tournamentId)
    {
        var rankings = new List<RankingEntry>();

        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            var command = new SqlCommand(
                "SELECT RankingId, ParticipantId, ParticipantName, TotalPoints, ExactMatches, WinnerMatches, Position " +
                "FROM Rankings WHERE TournamentId = @TournamentId ORDER BY Position",
                connection);
            
            command.Parameters.AddWithValue("@TournamentId", tournamentId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    rankings.Add(new RankingEntry
                    {
                        RankingId = reader.GetGuid(0),
                        ParticipantId = reader.GetGuid(1),
                        ParticipantName = reader.GetString(2),
                        TotalPoints = reader.GetInt32(3),
                        ExactMatches = reader.GetInt32(4),
                        WinnerMatches = reader.GetInt32(5),
                        Position = reader.GetInt32(6)
                    });
                }
            }
        }

        return rankings;
    }

    public async Task<bool> SaveGuessAsync(Guess guess)
    {
        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            var command = new SqlCommand(
                "INSERT INTO Guesses (GuessId, ParticipantId, MatchId, HomeTeamScore, AwayTeamScore, Points, CreatedAt) " +
                "VALUES (@GuessId, @ParticipantId, @MatchId, @HomeTeamScore, @AwayTeamScore, @Points, @CreatedAt)",
                connection);
            
            command.Parameters.AddWithValue("@GuessId", guess.GuessId);
            command.Parameters.AddWithValue("@ParticipantId", guess.ParticipantId);
            command.Parameters.AddWithValue("@MatchId", guess.MatchId);
            command.Parameters.AddWithValue("@HomeTeamScore", guess.HomeTeamScore);
            command.Parameters.AddWithValue("@AwayTeamScore", guess.AwayTeamScore);
            command.Parameters.AddWithValue("@Points", guess.Points);
            command.Parameters.AddWithValue("@CreatedAt", DateTime.UtcNow);

            return await command.ExecuteNonQueryAsync() > 0;
        }
    }
}

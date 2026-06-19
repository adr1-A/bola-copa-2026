using BolaoCopa.Functions.Models;
using BolaoCopa.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

namespace BolaoCopa.Functions;

public class MatchesFunction
{
    private readonly ILogger _logger;
    private readonly DatabaseService _dbService;

    public MatchesFunction(ILoggerFactory loggerFactory, DatabaseService dbService)
    {
        _logger = loggerFactory.CreateLogger<MatchesFunction>();
        _dbService = dbService;
    }

    [Function("GetPhaseMatches")]
    public async Task<HttpResponseData> GetPhaseMatches(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "phases/{phaseId}/matches")] 
        HttpRequestData req,
        string phaseId)
    {
        try
        {
            if (!Guid.TryParse(phaseId, out var phaseGuid))
            {
                return req.CreateResponse(HttpStatusCode.BadRequest);
            }

            var matches = await _dbService.GetPhaseMatchesAsync(phaseGuid);
            
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(matches);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error in GetPhaseMatches: {ex.Message}");
            return req.CreateResponse(HttpStatusCode.InternalServerError);
        }
    }
}

public class RankingFunction
{
    private readonly ILogger _logger;
    private readonly DatabaseService _dbService;

    public RankingFunction(ILoggerFactory loggerFactory, DatabaseService dbService)
    {
        _logger = loggerFactory.CreateLogger<RankingFunction>();
        _dbService = dbService;
    }

    [Function("GetRanking")]
    public async Task<HttpResponseData> GetRanking(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "tournaments/{tournamentId}/ranking")] 
        HttpRequestData req,
        string tournamentId)
    {
        try
        {
            if (!Guid.TryParse(tournamentId, out var tournamentGuid))
            {
                return req.CreateResponse(HttpStatusCode.BadRequest);
            }

            var ranking = await _dbService.GetRankingAsync(tournamentGuid);
            
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(ranking);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error in GetRanking: {ex.Message}");
            return req.CreateResponse(HttpStatusCode.InternalServerError);
        }
    }
}

public class GuessFunction
{
    private readonly ILogger _logger;
    private readonly DatabaseService _dbService;

    public GuessFunction(ILoggerFactory loggerFactory, DatabaseService dbService)
    {
        _logger = loggerFactory.CreateLogger<GuessFunction>();
        _dbService = dbService;
    }

    [Function("SaveGuess")]
    public async Task<HttpResponseData> SaveGuess(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "guesses")] 
        HttpRequestData req)
    {
        try
        {
            var guess = await req.ReadFromJsonAsync<Guess>();
            
            if (guess == null)
            {
                return req.CreateResponse(HttpStatusCode.BadRequest);
            }

            guess.GuessId = Guid.NewGuid();
            guess.CreatedAt = DateTime.UtcNow;

            var success = await _dbService.SaveGuessAsync(guess);
            
            var response = req.CreateResponse(success ? HttpStatusCode.Created : HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { success, guessId = guess.GuessId });
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error in SaveGuess: {ex.Message}");
            return req.CreateResponse(HttpStatusCode.InternalServerError);
        }
    }
}

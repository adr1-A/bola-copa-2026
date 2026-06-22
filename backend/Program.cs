// Program.cs — entry point for ASP.NET Core Minimal API
// Runs locally as a plain Kestrel web server and on AWS Lambda via
// Amazon.Lambda.AspNetCoreServer.Hosting (no code change needed between envs).

using BolaoCopa;

var builder = WebApplication.CreateBuilder(args);

// ── Lambda integration ────────────────────────────────────────────────────────
// AddAWSLambdaHosting() is a no-op when running locally, so the same binary
// works for both `dotnet run` and Lambda invocations.
builder.Services.AddAWSLambdaHosting(LambdaEventSource.RestApi);

// ── App services ─────────────────────────────────────────────────────────────
builder.Services.AddSingleton<BolaoService>(sp =>
{
    var connStr = builder.Configuration["SqlConnectionString"]
                  ?? throw new InvalidOperationException(
                      "Missing config key 'SqlConnectionString'. " +
                      "Set it in appsettings.json or as an environment variable.");
    return new BolaoService(connStr);
});

// ── CORS ──────────────────────────────────────────────────────────────────────
var allowedOrigins = (builder.Configuration["AllowedOrigins"] ?? "http://localhost:3000")
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

builder.Services.AddCors(opt =>
    opt.AddDefaultPolicy(p => p.WithOrigins(allowedOrigins)
                                .AllowAnyHeader()
                                .AllowAnyMethod()));

var app = builder.Build();
app.UseCors();

// ── Routes (mirrors the three original Azure Function endpoints) ──────────────

// GET /api/tournaments/{tournamentId}/phases/{phaseId}/matches
app.MapGet("/api/tournaments/{tournamentId}/phases/{phaseId}/matches",
    async (Guid tournamentId, Guid phaseId, BolaoService svc) =>
    {
        var matches = await svc.GetPhaseMatchesAsync(tournamentId, phaseId);
        return Results.Ok(matches);
    });

// GET /api/tournaments/{tournamentId}/ranking
app.MapGet("/api/tournaments/{tournamentId}/ranking",
    async (Guid tournamentId, BolaoService svc) =>
    {
        var ranking = await svc.GetRankingAsync(tournamentId);
        return Results.Ok(ranking);
    });

// POST /api/guesses
app.MapPost("/api/guesses",
    async (GuessRequest guess, BolaoService svc) =>
    {
        await svc.SaveGuessAsync(guess);
        return Results.Ok(new { message = "Palpite salvo com sucesso" });
    });

app.Run();

-- =============================================================================
-- BOLÃO COPA 2026 - Database Schema
-- =============================================================================

-- Tabela de Torneios/Competições
CREATE TABLE Tournaments (
    TournamentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2,
    Status NVARCHAR(20) DEFAULT 'Active', -- Active, Finished
    CreatedAt DATETIME2 DEFAULT GETUTCDATE()
);

-- Tabela de Fases (Rodada 1, Rodada 2, Oitavas, Quartas, etc)
CREATE TABLE Phases (
    PhaseId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TournamentId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(100) NOT NULL, -- "Rodada 1", "Oitavas de Final", etc
    PhaseOrder INT NOT NULL,
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2,
    Status NVARCHAR(20) DEFAULT 'Upcoming', -- Upcoming, Active, Finished
    FOREIGN KEY (TournamentId) REFERENCES Tournaments(TournamentId)
);

-- Tabela de Jogos
CREATE TABLE Matches (
    MatchId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhaseId UNIQUEIDENTIFIER NOT NULL,
    MatchNumber INT NOT NULL,
    HomeTeam NVARCHAR(100) NOT NULL,
    AwayTeam NVARCHAR(100) NOT NULL,
    ScheduledDate DATETIME2 NOT NULL,
    HomeScore INT,
    AwayScore INT,
    Status NVARCHAR(20) DEFAULT 'Scheduled', -- Scheduled, Live, Finished
    FOREIGN KEY (PhaseId) REFERENCES Phases(PhaseId),
    UNIQUE(PhaseId, MatchNumber)
);

-- Tabela de Participantes
CREATE TABLE Participants (
    ParticipantId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TournamentId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    JoinedAt DATETIME2 DEFAULT GETUTCDATE(),
    Status NVARCHAR(20) DEFAULT 'Active', -- Active, Inactive
    FOREIGN KEY (TournamentId) REFERENCES Tournaments(TournamentId),
    UNIQUE(TournamentId, Email)
);

-- Tabela de Palpites (Guesses)
CREATE TABLE Guesses (
    GuessId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ParticipantId UNIQUEIDENTIFIER NOT NULL,
    MatchId UNIQUEIDENTIFIER NOT NULL,
    HomeTeamScore INT NOT NULL,
    AwayTeamScore INT NOT NULL,
    Points INT DEFAULT 0,
    CalculatedAt DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2,
    FOREIGN KEY (ParticipantId) REFERENCES Participants(ParticipantId),
    FOREIGN KEY (MatchId) REFERENCES Matches(MatchId),
    UNIQUE(ParticipantId, MatchId)
);

-- Tabela de Ranking (Desnormalizado para melhor performance)
CREATE TABLE Rankings (
    RankingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TournamentId UNIQUEIDENTIFIER NOT NULL,
    ParticipantId UNIQUEIDENTIFIER NOT NULL,
    ParticipantName NVARCHAR(100) NOT NULL,
    TotalPoints INT DEFAULT 0,
    ExactMatches INT DEFAULT 0,
    WinnerMatches INT DEFAULT 0,
    Position INT,
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (TournamentId) REFERENCES Tournaments(TournamentId),
    FOREIGN KEY (ParticipantId) REFERENCES Participants(ParticipantId),
    UNIQUE(TournamentId, ParticipantId)
);

-- Índices para melhor performance
CREATE INDEX IX_Matches_PhaseId ON Matches(PhaseId);
CREATE INDEX IX_Matches_Status ON Matches(Status);
CREATE INDEX IX_Guesses_ParticipantId ON Guesses(ParticipantId);
CREATE INDEX IX_Guesses_MatchId ON Guesses(MatchId);
CREATE INDEX IX_Rankings_TournamentId ON Rankings(TournamentId);
CREATE INDEX IX_Rankings_TotalPoints ON Rankings(TotalPoints DESC);
CREATE INDEX IX_Participants_TournamentId ON Participants(TournamentId);
CREATE INDEX IX_Phases_TournamentId ON Phases(TournamentId);

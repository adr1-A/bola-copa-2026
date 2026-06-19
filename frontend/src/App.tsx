import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Trophy, Users, Target } from 'lucide-react';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:7071/api';

interface Match {
  matchId: string;
  homeTeam: string;
  awayTeam: string;
  homeScore?: number;
  awayScore?: number;
  scheduledDate: string;
  status: string;
}

interface RankingEntry {
  participantId: string;
  participantName: string;
  totalPoints: number;
  exactMatches: number;
  winnerMatches: number;
  position: number;
}

interface Guess {
  matchId: string;
  homeTeamScore: number;
  awayTeamScore: number;
}

export default function App() {
  const [currentPhase, setCurrentPhase] = useState<string>('rodada-1');
  const [matches, setMatches] = useState<Match[]>([]);
  const [ranking, setRanking] = useState<RankingEntry[]>([]);
  const [guesses, setGuesses] = useState<Record<string, Guess>>({});
  const [participantName, setParticipantName] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<'matches' | 'ranking'>('matches');

  const tournamentId = '550e8400-e29b-41d4-a716-446655440000'; // Replace with actual tournament ID

  useEffect(() => {
    fetchMatches();
    fetchRanking();
  }, [currentPhase]);

  const fetchMatches = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/phases/${currentPhase}/matches`);
      setMatches(response.data);
    } catch (error) {
      console.error('Error fetching matches:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchRanking = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/tournaments/${tournamentId}/ranking`);
      setRanking(response.data);
    } catch (error) {
      console.error('Error fetching ranking:', error);
    }
  };

  const handleGuessChange = (matchId: string, team: 'home' | 'away', score: number) => {
    setGuesses(prev => ({
      ...prev,
      [matchId]: {
        ...prev[matchId],
        matchId,
        [team === 'home' ? 'homeTeamScore' : 'awayTeamScore']: score
      }
    }));
  };

  const submitGuesses = async () => {
    if (!participantName.trim()) {
      alert('Please enter your name');
      return;
    }

    try {
      setLoading(true);
      // Submit all guesses
      for (const [matchId, guess] of Object.entries(guesses)) {
        if (guess.homeTeamScore !== undefined && guess.awayTeamScore !== undefined) {
          await axios.post(`${API_BASE_URL}/guesses`, {
            ...guess,
            participantId: participantName
          });
        }
      }
      alert('Guesses submitted successfully!');
      setGuesses({});
      fetchRanking();
    } catch (error) {
      console.error('Error submitting guesses:', error);
      alert('Error submitting guesses');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-900 via-yellow-50 to-green-900">
      {/* Header */}
      <header className="bg-green-900 text-white shadow-lg">
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Trophy size={40} className="text-yellow-400" />
              <h1 className="text-4xl font-bold">⚽ Bolão Copa 2026</h1>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Matches */}
          <div className="lg:col-span-2">
            {/* Tabs */}
            <div className="flex gap-4 mb-6">
              <button
                onClick={() => setActiveTab('matches')}
                className={`px-6 py-3 rounded-lg font-semibold transition ${
                  activeTab === 'matches'
                    ? 'bg-green-900 text-white'
                    : 'bg-white text-green-900 border-2 border-green-900'
                }`}
              >
                <Target size={20} className="inline mr-2" />
                Jogos e Palpites
              </button>
              <button
                onClick={() => setActiveTab('ranking')}
                className={`px-6 py-3 rounded-lg font-semibold transition ${
                  activeTab === 'ranking'
                    ? 'bg-green-900 text-white'
                    : 'bg-white text-green-900 border-2 border-green-900'
                }`}
              >
                <Users size={20} className="inline mr-2" />
                Ranking
              </button>
            </div>

            {/* Matches Tab */}
            {activeTab === 'matches' && (
              <div className="space-y-6">
                {/* Participant Name Input */}
                <div className="bg-white p-6 rounded-lg shadow-lg">
                  <label className="block text-sm font-semibold text-gray-700 mb-2">
                    Seu Nome:
                  </label>
                  <input
                    type="text"
                    value={participantName}
                    onChange={(e) => setParticipantName(e.target.value)}
                    placeholder="Digite seu nome..."
                    className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-900"
                  />
                </div>

                {/* Matches Grid */}
                {loading ? (
                  <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-green-900 mx-auto"></div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {matches.map((match) => (
                      <div
                        key={match.matchId}
                        className="bg-white p-6 rounded-lg shadow-lg hover:shadow-xl transition"
                      >
                        <div className="text-sm text-gray-600 mb-4">
                          {new Date(match.scheduledDate).toLocaleString('pt-BR')}
                        </div>

                        <div className="grid grid-cols-3 gap-4 items-center">
                          {/* Home Team */}
                          <div className="text-right">
                            <h3 className="font-bold text-lg text-gray-800">{match.homeTeam}</h3>
                            {match.status === 'Finished' && (
                              <div className="text-2xl font-bold text-green-900 mt-2">
                                {match.homeScore}
                              </div>
                            )}
                          </div>

                          {/* Score Input */}
                          <div className="flex justify-center gap-2">
                            {match.status === 'Scheduled' || match.status === 'Live' ? (
                              <>
                                <input
                                  type="number"
                                  min="0"
                                  max="10"
                                  value={guesses[match.matchId]?.homeTeamScore ?? ''}
                                  onChange={(e) =>
                                    handleGuessChange(
                                      match.matchId,
                                      'home',
                                      parseInt(e.target.value) || 0
                                    )
                                  }
                                  className="w-12 h-12 text-center border-2 border-yellow-400 rounded font-bold text-lg"
                                  placeholder="0"
                                />
                                <span className="text-2xl font-bold text-gray-400">x</span>
                                <input
                                  type="number"
                                  min="0"
                                  max="10"
                                  value={guesses[match.matchId]?.awayTeamScore ?? ''}
                                  onChange={(e) =>
                                    handleGuessChange(
                                      match.matchId,
                                      'away',
                                      parseInt(e.target.value) || 0
                                    )
                                  }
                                  className="w-12 h-12 text-center border-2 border-yellow-400 rounded font-bold text-lg"
                                  placeholder="0"
                                />
                              </>
                            ) : (
                              <div className="text-2xl font-bold text-gray-800">
                                {match.homeScore} x {match.awayScore}
                              </div>
                            )}
                          </div>

                          {/* Away Team */}
                          <div className="text-left">
                            <h3 className="font-bold text-lg text-gray-800">{match.awayTeam}</h3>
                            {match.status === 'Finished' && (
                              <div className="text-2xl font-bold text-green-900 mt-2">
                                {match.awayScore}
                              </div>
                            )}
                          </div>
                        </div>

                        {/* Status Badge */}
                        <div className="mt-4">
                          <span
                            className={`px-3 py-1 rounded-full text-sm font-semibold ${
                              match.status === 'Finished'
                                ? 'bg-gray-200 text-gray-800'
                                : match.status === 'Live'
                                  ? 'bg-red-200 text-red-800'
                                  : 'bg-yellow-200 text-yellow-800'
                            }`}
                          >
                            {match.status === 'Scheduled'
                              ? 'Agendado'
                              : match.status === 'Live'
                                ? 'AO VIVO'
                                : 'Finalizado'}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Submit Button */}
                <button
                  onClick={submitGuesses}
                  disabled={loading}
                  className="w-full bg-yellow-400 hover:bg-yellow-500 text-green-900 font-bold py-4 rounded-lg transition disabled:opacity-50"
                >
                  ENVIAR PALPITES
                </button>
              </div>
            )}

            {/* Ranking Tab */}
            {activeTab === 'ranking' && (
              <div className="bg-white rounded-lg shadow-lg overflow-hidden">
                {loading ? (
                  <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-green-900 mx-auto"></div>
                  </div>
                ) : (
                  <table className="w-full">
                    <thead className="bg-green-900 text-white">
                      <tr>
                        <th className="px-6 py-4 text-left">Posição</th>
                        <th className="px-6 py-4 text-left">Participante</th>
                        <th className="px-6 py-4 text-center">Placar Exato</th>
                        <th className="px-6 py-4 text-center">Vencedor</th>
                        <th className="px-6 py-4 text-right font-bold text-yellow-400">Pontos</th>
                      </tr>
                    </thead>
                    <tbody>
                      {ranking.map((entry, idx) => (
                        <tr
                          key={entry.participantId}
                          className={`border-b-2 ${
                            idx === 0
                              ? 'bg-yellow-100'
                              : idx === 1
                                ? 'bg-gray-100'
                                : idx === 2
                                  ? 'bg-orange-100'
                                  : 'hover:bg-gray-50'
                          }`}
                        >
                          <td className="px-6 py-4 font-bold text-lg text-gray-800">
                            {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : entry.position}
                          </td>
                          <td className="px-6 py-4 font-semibold text-gray-800">
                            {entry.participantName}
                          </td>
                          <td className="px-6 py-4 text-center text-green-900 font-bold">
                            {entry.exactMatches}
                          </td>
                          <td className="px-6 py-4 text-center text-blue-900 font-bold">
                            {entry.winnerMatches}
                          </td>
                          <td className="px-6 py-4 text-right font-bold text-lg text-yellow-600">
                            {entry.totalPoints}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}
          </div>

          {/* Right Column - Sidebar */}
          <div>
            {/* Tournament Info */}
            <div className="bg-white p-6 rounded-lg shadow-lg mb-6">
              <h2 className="text-2xl font-bold text-green-900 mb-4">Copa 2026</h2>
              <div className="space-y-3">
                <div>
                  <p className="text-gray-600 text-sm">Fase Atual</p>
                  <p className="text-lg font-semibold text-gray-800">Rodada 2</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Total de Participantes</p>
                  <p className="text-lg font-semibold text-gray-800">{ranking.length}</p>
                </div>
              </div>
            </div>

            {/* Top 3 Podium */}
            {ranking.length > 0 && (
              <div className="bg-white p-6 rounded-lg shadow-lg">
                <h3 className="text-xl font-bold text-green-900 mb-4">🏆 Podium</h3>
                <div className="space-y-3">
                  {ranking.slice(0, 3).map((entry, idx) => (
                    <div
                      key={entry.participantId}
                      className="flex items-center justify-between p-3 rounded-lg"
                      style={{
                        background:
                          idx === 0
                            ? '#FCD34D'
                            : idx === 1
                              ? '#E5E7EB'
                              : '#FED7AA'
                      }}
                    >
                      <div>
                        <p className="font-bold text-gray-800">{entry.participantName}</p>
                        <p className="text-sm text-gray-600">{entry.totalPoints} pts</p>
                      </div>
                      <span className="text-2xl">
                        {idx === 0 ? '🥇' : idx === 1 ? '🥈' : '🥉'}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

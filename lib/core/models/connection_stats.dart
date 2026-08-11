enum TransportMode { bleHid, udpRelay }

class ConnectionStats {
  final TransportMode mode;
  final bool isConnected;
  final String hostAddress;
  final int hostPort;
  final double pingMs;
  final int totalPacketsSent;
  final int packetsPerSecond; // Current Hz tick rate (target 250Hz)
  final int activePlayersCount;
  final Map<int, double> playerPings; // player_id (0..3) -> ping in ms

  ConnectionStats({
    this.mode = TransportMode.udpRelay,
    this.isConnected = false,
    this.hostAddress = '127.0.0.1',
    this.hostPort = 9999,
    this.pingMs = 0.0,
    this.totalPacketsSent = 0,
    this.packetsPerSecond = 0,
    this.activePlayersCount = 1,
    this.playerPings = const {0: 4.0},
  });

  ConnectionStats copyWith({
    TransportMode? mode,
    bool? isConnected,
    String? hostAddress,
    int? hostPort,
    double? pingMs,
    int? totalPacketsSent,
    int? packetsPerSecond,
    int? activePlayersCount,
    Map<int, double>? playerPings,
  }) {
    return ConnectionStats(
      mode: mode ?? this.mode,
      isConnected: isConnected ?? this.isConnected,
      hostAddress: hostAddress ?? this.hostAddress,
      hostPort: hostPort ?? this.hostPort,
      pingMs: pingMs ?? this.pingMs,
      totalPacketsSent: totalPacketsSent ?? this.totalPacketsSent,
      packetsPerSecond: packetsPerSecond ?? this.packetsPerSecond,
      activePlayersCount: activePlayersCount ?? this.activePlayersCount,
      playerPings: playerPings ?? this.playerPings,
    );
  }
}

enum EffectType {
  stun,
  // Future effects like burn, slow, etc.
}

class StatusEffect {
  final EffectType type;
  final Duration duration;
  final DateTime? startTime;

  const StatusEffect({
    required this.type,
    required this.duration,
    this.startTime, // Explicitly defined as nullable parameter
  });

  StatusEffect copyWith({
    EffectType? type,
    Duration? duration,
    DateTime? startTime,
  }) {
    return StatusEffect(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
    );
  }
}

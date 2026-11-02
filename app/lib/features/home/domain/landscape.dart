/// Pejzaż w nagłówku ekranu startowego, zależny od pory dnia (v10).
enum Landscape {
  dawn('assets/landscapes/dawn.jpg'),
  day('assets/landscapes/day.jpg'),
  sunset('assets/landscapes/sunset.jpg'),
  night('assets/landscapes/night.jpg');

  const Landscape(this.asset);

  final String asset;

  /// Świt 5–8, dzień 8–18, zachód 18–21, noc 21–5 (czas lokalny telefonu).
  static Landscape at(DateTime time) => switch (time.hour) {
    >= 5 && < 8 => dawn,
    >= 8 && < 18 => day,
    >= 18 && < 21 => sunset,
    _ => night,
  };
}

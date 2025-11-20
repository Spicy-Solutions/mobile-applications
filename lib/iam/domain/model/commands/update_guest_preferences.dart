class EditGuestPreferences {
  final int guestId;
  final int temperature;

  EditGuestPreferences({
    required this.guestId,
    required this.temperature,
  });

  Map<String, dynamic> toJson() {
    return {
      'guestId': guestId,
      'temperature': temperature,
    };
  }
}
class ReminderService {
  static String getReminder(String disease) {
    if (disease == "Late Blight") {
      return "Spray fungicide every 3 days";
    }
    return "Monitor plant regularly";
  }
}
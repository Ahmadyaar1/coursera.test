class AppConfig {
  // ── Change ONLY this when your IP changes ──────────────────────────
  static const String baseUrl = "http://192.168.1.22:8000";

  // Endpoints
  static const String predictEndpoint  = "$baseUrl/predict-gesture";
  static const String labelsEndpoint   = "$baseUrl/labels";
  static const String reloadEndpoint   = "$baseUrl/reload";
  static const String healthEndpoint   = "$baseUrl/";

  // Detection settings
  static const double confidenceThreshold = 0.60; // 60%
  static const int    detectionIntervalMs = 1000;  // 1 frame/sec
}
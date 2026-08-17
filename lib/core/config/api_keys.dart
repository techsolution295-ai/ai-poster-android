/// API keys for the free image providers used by Poster Maker AI.
///
/// ---------------------------------------------------------------------------
/// SETUP (see README for full details)
/// ---------------------------------------------------------------------------
/// 1. Pexels  – create a free account at https://www.pexels.com/api/ and copy
///    your API key into [pexels].
/// 2. Pixabay – create a free account at https://pixabay.com/api/docs/ and copy
///    your API key into [pixabay].
///
/// The app still runs without keys: it falls back to free, key-less demo
/// imagery (Lorem Picsum) so you can explore the whole flow before signing up.
///
/// SECURITY NOTE
/// -------------
/// For this MVP the keys live in the client and calls go directly to the APIs
/// (no backend, by design). This is fine for development / a first release. For
/// a production app you should proxy these requests through a small server so
/// the keys are never shipped inside the APK. Do NOT commit real keys to a
/// public repository.
class ApiKeys {
  ApiKeys._();

  /// Your Pexels API key. Paste it between the quotes. Leave empty for demo mode.
  ///
  /// You can also inject it at build time without editing this file:
  ///   flutter run --dart-define=PEXELS_API_KEY=xxxx
  static const String pexels = bool.hasEnvironment('PEXELS_API_KEY')
      ? String.fromEnvironment('PEXELS_API_KEY')
      : ''; // <-- or paste your Pexels key here

  /// Your Pixabay API key. Paste it between the quotes. Leave empty for demo mode.
  ///
  ///   flutter run --dart-define=PIXABAY_API_KEY=xxxx
  static const String pixabay = bool.hasEnvironment('PIXABAY_API_KEY')
      ? String.fromEnvironment('PIXABAY_API_KEY')
      : ''; // <-- or paste your Pixabay key here

  /// Optional HuggingFace token for prompt -> poster text/category extraction.
  ///
  /// Free tier works but can be slow. If empty, the app uses a local parser.
  ///   flutter run --dart-define=HUGGINGFACE_API_KEY=xxxx
  static const String huggingFace = bool.hasEnvironment('HUGGINGFACE_API_KEY')
      ? String.fromEnvironment('HUGGINGFACE_API_KEY')
      : ''; // <-- optional

  static bool get hasPexels => pexels.isNotEmpty;
  static bool get hasPixabay => pixabay.isNotEmpty;
  static bool get hasAnyKey => hasPexels || hasPixabay;
  static bool get hasHuggingFace => huggingFace.isNotEmpty;
}

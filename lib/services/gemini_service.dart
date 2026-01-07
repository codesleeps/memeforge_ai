import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';

/// Service for interacting with Google's Gemini AI for meme generation
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  GenerativeModel? _model;
  GenerativeModel? _visionModel;
  // Gemini API Key - loaded from environment or hardcoded
  static const String apiKey = 'AIzaSyBgkc55uIuOpPKliKEbZfCBvY8vKGtNVxI';
  bool _isInitialized = false;
  String? _initializationError;

  factory GeminiService() => _instance;

  GeminiService._internal() {
    _initializeService();
  }

  void _initializeService() {
    try {
      if (apiKey.isEmpty) {
        _initializationError =
            'GEMINI_API_KEY is not configured. Please add your API key to use AI meme generation.';
        _isInitialized = false;
        return;
      }

      // Initialize text generation model with optimized settings
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.9,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
          stopSequences: [],
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      // Initialize vision model for image analysis
      _visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 32,
          topP: 0.8,
          maxOutputTokens: 1024,
        ),
      );

      _isInitialized = true;
      _initializationError = null;
    } catch (e) {
      _initializationError =
          'Failed to initialize Gemini AI: ${e.toString()}. Please check your API key.';
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  void _checkInitialization() {
    if (!_isInitialized || _model == null) {
      throw GeminiException(
        _initializationError ??
            'Gemini AI is not initialized. Please configure GEMINI_API_KEY.',
      );
    }
  }

  /// Generate meme concept and description based on user prompt
  Future<MemeGenerationResult> generateMemeIdea(String prompt) async {
    _checkInitialization();

    try {
      final enhancedPrompt =
          '''
You are a creative meme generator assistant. Based on the user's request, generate a detailed meme concept.

User request: $prompt

Provide a response in the following format (use EXACT labels):
MEME_CONCEPT: [Brief creative description of the meme idea in 10-15 words]
IMAGE_PROMPT: [Detailed visual description with specific elements: subject, action, setting, mood, style - be very specific for image search]
TOP_TEXT: [Funny/relatable text for top of meme in CAPITAL LETTERS, max 8 words, or "NONE"]
BOTTOM_TEXT: [Punchline/caption for bottom in CAPITAL LETTERS, max 8 words, or "NONE"]
SEARCH_TERMS: [3-5 specific keywords for image search, comma-separated]

Make it funny, relatable, and visually interesting! Focus on popular meme formats and current trends.''';

      final content = [Content.text(enhancedPrompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw GeminiException(
          'No response generated. Try rephrasing your request.',
        );
      }

      return _parseMemeResponse(response.text!);
    } on GenerativeAIException catch (e) {
      throw GeminiException(
        'AI generation failed: ${e.message}. Please try again with a different prompt.',
      );
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException(
        'Error generating meme idea: ${e.toString()}. Please try again.',
      );
    }
  }

  /// Generate conversational response for chat
  Future<String> generateChatResponse(String userMessage) async {
    _checkInitialization();

    try {
      final prompt =
          '''
You are a friendly, creative AI meme assistant named MemeBuddy. 
Respond to the user's message in a casual, enthusiastic, and helpful way.
Keep responses very concise (1-2 short sentences maximum).
Be encouraging and make the user excited about creating memes.
Use emojis sparingly (max 1-2 per response).

User message: $userMessage

Response:''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return "That sounds awesome! Let's create an amazing meme together! 🎨";
      }

      return response.text!.trim();
    } catch (e) {
      // Return friendly fallback instead of throwing error
      return "I'm excited to help you create this meme! Let's make it hilarious! 😄";
    }
  }

  /// Analyze image and provide meme suggestions
  Future<String> analyzeImageForMeme(Uint8List imageBytes) async {
    _checkInitialization();

    if (_visionModel == null) {
      throw GeminiException('Vision AI is not available right now.');
    }

    try {
      final prompt = '''
Analyze this image and suggest 2-3 creative meme ideas. Be specific and funny.
Focus on:
- What's happening in the image that could be funny
- Relatable situations or reactions it could represent
- Popular meme format ideas that would work

Keep each suggestion brief (one sentence) and include a caption idea.''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _visionModel!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return 'This image has great meme potential! Try adding some funny text that relates to a common situation.';
      }

      return response.text!.trim();
    } catch (e) {
      return 'This image looks perfect for a meme! What funny situation does it remind you of?';
    }
  }

  /// Stream chat responses for real-time interaction
  Stream<String> streamChatResponse(String userMessage) async* {
    _checkInitialization();

    try {
      final prompt =
          '''
You are a friendly AI meme assistant. Respond to: $userMessage
Keep it brief, enthusiastic, and helpful.''';

      final content = [Content.text(prompt)];
      final response = _model!.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "Let's create something amazing together! 🚀";
    }
  }

  MemeGenerationResult _parseMemeResponse(String response) {
    String concept = 'Creative meme concept';
    String imagePrompt = 'Funny meme image';
    String topText = '';
    String bottomText = '';
    String searchTerms = 'funny,meme,humor';

    final lines = response.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('MEME_CONCEPT:')) {
        concept = trimmedLine.substring('MEME_CONCEPT:'.length).trim();
      } else if (trimmedLine.startsWith('IMAGE_PROMPT:')) {
        imagePrompt = trimmedLine.substring('IMAGE_PROMPT:'.length).trim();
      } else if (trimmedLine.startsWith('TOP_TEXT:')) {
        final text = trimmedLine.substring('TOP_TEXT:'.length).trim();
        if (text.toUpperCase() != 'NONE') topText = text;
      } else if (trimmedLine.startsWith('BOTTOM_TEXT:')) {
        final text = trimmedLine.substring('BOTTOM_TEXT:'.length).trim();
        if (text.toUpperCase() != 'NONE') bottomText = text;
      } else if (trimmedLine.startsWith('SEARCH_TERMS:')) {
        searchTerms = trimmedLine.substring('SEARCH_TERMS:'.length).trim();
      }
    }

    // Fallback if parsing failed
    if (concept.isEmpty) concept = 'Creative meme idea';
    if (imagePrompt.isEmpty) imagePrompt = response.substring(0, 100);
    if (searchTerms.isEmpty) {
      searchTerms = imagePrompt.toLowerCase().split(' ').take(3).join(',');
    }

    return MemeGenerationResult(
      concept: concept,
      imagePrompt: imagePrompt,
      topText: topText,
      bottomText: bottomText,
      searchTerms: searchTerms,
    );
  }
}

/// Result from meme generation
class MemeGenerationResult {
  final String concept;
  final String imagePrompt;
  final String topText;
  final String bottomText;
  final String searchTerms;

  MemeGenerationResult({
    required this.concept,
    required this.imagePrompt,
    required this.topText,
    required this.bottomText,
    required this.searchTerms,
  });
}

/// Custom exception for Gemini service errors
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}

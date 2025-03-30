import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../utils/constants.dart';

/// Screen for configuring AI provider settings
class AIConfigScreen extends StatefulWidget {
  const AIConfigScreen({super.key});

  @override
  State<AIConfigScreen> createState() => _AIConfigScreenState();
}

class _AIConfigScreenState extends State<AIConfigScreen> {
  bool _isLoading = true;
  String _selectedProvider = Constants.aiProviderOpenAI;
  final TextEditingController _apiKeyController = TextEditingController();
  late AIProviderConfig _currentConfig;
  bool _showApiKey = false;

  // Models for each provider
  final Map<String, List<String>> _providerModels = {
    Constants.aiProviderOpenAI: [
      'gpt-3.5-turbo',
      'gpt-3.5-turbo-16k',
      'gpt-4',
      'gpt-4-turbo',
    ],
    Constants.aiProviderAnthropic: [
      'claude-2',
      'claude-instant-1',
    ],
    Constants.aiProviderGoogle: [
      'gemini-pro',
    ],
  };

  String _selectedModel = Constants.aiModelOpenAI;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final aiService = await AIService.create();
      final config = await aiService.getConfig();

      if (config != null) {
        setState(() {
          _currentConfig = config;
          _selectedProvider = config.provider;
          _apiKeyController.text = config.apiKey;
          _selectedModel = config.model;
        });
      } else {
        // Use defaults
        setState(() {
          _selectedProvider = Constants.aiProviderOpenAI;
          _selectedModel = Constants.aiModelOpenAI;
          _currentConfig = AIProviderConfig(
            provider: _selectedProvider,
            apiKey: '',
            model: _selectedModel,
          );
        });
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newConfig = AIProviderConfig(
        provider: _selectedProvider,
        apiKey: _apiKeyController.text,
        model: _selectedModel,
      );

      final aiService = await AIService.create();
      await aiService.saveConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Provider Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select provider
                  const Text(
                    'AI Provider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProvider,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: Constants.aiProviderOpenAI,
                        child: const Text('OpenAI (GPT)'),
                      ),
                      DropdownMenuItem(
                        value: Constants.aiProviderAnthropic,
                        child: const Text('Anthropic (Claude)'),
                      ),
                      DropdownMenuItem(
                        value: Constants.aiProviderGoogle,
                        child: const Text('Google AI (Gemini)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedProvider = value;
                          // Set default model for provider
                          switch (value) {
                            case Constants.aiProviderOpenAI:
                              _selectedModel = Constants.aiModelOpenAI;
                              break;
                            case Constants.aiProviderAnthropic:
                              _selectedModel = Constants.aiModelAnthropic;
                              break;
                            case Constants.aiProviderGoogle:
                              _selectedModel = Constants.aiModelGoogle;
                              break;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // API key
                  const Text(
                    'API Key',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Enter your API key',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showApiKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _showApiKey = !_showApiKey;
                          });
                        },
                      ),
                    ),
                    obscureText: !_showApiKey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get your API key from:',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _selectedProvider == Constants.aiProviderOpenAI
                        ? 'https://platform.openai.com/api-keys'
                        : _selectedProvider == Constants.aiProviderAnthropic
                            ? 'https://console.anthropic.com/keys'
                            : 'https://ai.google.dev/',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select model
                  const Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _providerModels[_selectedProvider]!.contains(_selectedModel)
                        ? _selectedModel
                        : _providerModels[_selectedProvider]!.first,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: _providerModels[_selectedProvider]!
                        .map(
                          (model) => DropdownMenuItem(
                            value: model,
                            child: Text(model),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedModel = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedModel.contains('3.5')
                        ? 'Recommended: Affordable, good quality'
                        : _selectedModel.contains('4')
                            ? 'Best quality, higher cost'
                            : _selectedModel.contains('claude-instant')
                                ? 'Fastest response, lower cost'
                                : 'Standard model for this provider',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Configuration'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 
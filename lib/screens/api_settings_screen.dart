import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/api_key_entry.dart';
import '../models/gemini_model.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  bool _showKeys = false;
  int? _pendingDeleteIdx;

  @override
  void initState() {
    super.initState();
  }

  void _showDeleteConfirmation(int index) {
    setState(() {
      _pendingDeleteIdx = index;
    });
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete API Key'),
        content: const Text('Are you sure you want to delete this API key?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              setState(() {
                _pendingDeleteIdx = null;
              });
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              if (_pendingDeleteIdx != null) {
                await _deleteApiKey(_pendingDeleteIdx!);
                setState(() {
                  _pendingDeleteIdx = null;
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApiKey(int index) async {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    await apiKeyBox.deleteAt(index);
    _showSnackbar('API key deleted', color: CupertinoColors.systemOrange);
  }

  void _showAddApiKeyDialog() {
    final keyController = TextEditingController();
    final nicknameController = TextEditingController();
    String selectedModelId = GeminiModel.defaultModel.id;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Add API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: keyController,
                placeholder: 'Enter your Gemini API key',
                obscureText: true,
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: nicknameController,
                placeholder: 'Nickname (optional)',
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Model',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        _showModelSelector(selectedModelId, (newModelId) {
                          setDialogState(() {
                            selectedModelId = newModelId;
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: CupertinoColors.systemGrey4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                GeminiModel.getModelById(selectedModelId)
                                        ?.displayName ??
                                    'Unknown',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: CupertinoColors.systemGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Add'),
              onPressed: () async {
                if (keyController.text.trim().isNotEmpty) {
                  await _addApiKey(
                    keyController.text.trim(),
                    nickname: nicknameController.text.trim().isEmpty
                        ? null
                        : nicknameController.text.trim(),
                    modelId: selectedModelId,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addApiKey(String key,
      {String? nickname, String? modelId}) async {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    await apiKeyBox.add(ApiKeyEntry(
      key: key,
      nickname: nickname,
      modelId: modelId,
    ));
    _showSnackbar('API key added successfully!',
        color: CupertinoColors.activeGreen);
  }

  void _selectApiKey(int index) async {
    final settings = Hive.box('settings');
    try {
      await settings.put('selectedApiKeyIndex', index);
      _showSnackbar('Selected API key ${index + 1}');
    } catch (e) {
      _showSnackbar('Failed to select API key: $e',
          color: CupertinoColors.systemRed);
    }
  }

  void _showSnackbar(String msg, {Color color = CupertinoColors.activeBlue}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showModelSelector(
      String currentModelId, Function(String) onModelSelected) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select AI Model'),
        message: const Text('Choose the Gemini model for this API key'),
        actions: GeminiModel.availableModels
            .map((model) => CupertinoActionSheetAction(
                  onPressed: () {
                    onModelSelected(model.id);
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  model.displayName,
                                  style: TextStyle(
                                    fontWeight: currentModelId == model.id
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: currentModelId == model.id
                                        ? CupertinoColors.activeBlue
                                        : null,
                                  ),
                                ),
                                if (model.isRecommended) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeGreen
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'RECOMMENDED',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.activeGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (currentModelId == model.id) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: CupertinoColors.activeBlue,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      Text(
                        model.displayInfo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEditApiKeyDialog(int index, ApiKeyEntry apiKey) {
    final nicknameController =
        TextEditingController(text: apiKey.nickname ?? '');
    String selectedModelId = apiKey.modelId;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Edit API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: nicknameController,
                placeholder: 'Nickname (optional)',
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Model',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        _showModelSelector(selectedModelId, (newModelId) {
                          setDialogState(() {
                            selectedModelId = newModelId;
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: CupertinoColors.systemGrey4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                GeminiModel.getModelById(selectedModelId)
                                        ?.displayName ??
                                    'Unknown',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: CupertinoColors.systemGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Save'),
              onPressed: () async {
                await _updateApiKey(
                  index,
                  nickname: nicknameController.text.trim().isEmpty
                      ? null
                      : nicknameController.text.trim(),
                  modelId: selectedModelId,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateApiKey(int index,
      {String? nickname, String? modelId}) async {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    final apiKey = apiKeyBox.getAt(index);
    if (apiKey != null) {
      if (nickname != null) apiKey.nickname = nickname;
      if (modelId != null) apiKey.modelId = modelId;
      await apiKey.save();
      _showSnackbar('API key updated successfully!',
          color: CupertinoColors.activeGreen);
    }
  }

  Future<void> _testApiKey(String key, {String? modelId}) async {
    try {
      // Use the provided model ID or fallback to default model
      final selectedModel =
          GeminiModel.getModelById(modelId ?? GeminiModel.defaultModel.id) ??
              GeminiModel.defaultModel;

      final response = await http
          .post(
            Uri.parse(selectedModel.generateApiUrl(key)),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Daily Tips App/1.0',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Hello, test API key functionality.'}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 50,
              }
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if we got a valid response
        if (data.containsKey('candidates') &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty) {
          _showSnackbar('✅ API key is valid and working!',
              color: CupertinoColors.activeGreen);
        } else {
          _showSnackbar('⚠️ API key connected but returned unexpected response',
              color: CupertinoColors.systemOrange);
        }
      } else if (response.statusCode == 401) {
        _showSnackbar('❌ Invalid API key. Please check your key and try again.',
            color: CupertinoColors.systemRed);
      } else if (response.statusCode == 403) {
        _showSnackbar(
            '❌ API access forbidden. Please verify your API key has Gemini access enabled.',
            color: CupertinoColors.systemRed);
      } else if (response.statusCode == 429) {
        _showSnackbar(
            '⏳ Rate limit exceeded. Please wait a moment and try again.',
            color: CupertinoColors.systemOrange);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown error';
          _showSnackbar('❌ API Error (${response.statusCode}): $errorMessage',
              color: CupertinoColors.systemRed);
        } catch (_) {
          _showSnackbar(
              '❌ API Error (${response.statusCode}): ${response.reasonPhrase}',
              color: CupertinoColors.systemRed);
        }
      }
    } on TimeoutException {
      _showSnackbar(
          '⏱️ Request timed out. Please check your internet connection.',
          color: CupertinoColors.systemRed);
    } on SocketException {
      _showSnackbar('🌐 Network error. Please check your internet connection.',
          color: CupertinoColors.systemRed);
    } catch (e) {
      String errorMessage = '❌ Unexpected error occurred.';
      if (e.toString().contains('FormatException')) {
        errorMessage = '❌ Invalid response format from API.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage =
            '🔒 SSL/TLS connection error. Please check your network.';
      }
      _showSnackbar('$errorMessage', color: CupertinoColors.systemRed);
    }
  }

  // Method to show API guide and launch URL
  void _showApiGuide() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Get Gemini API Key',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Follow these steps to get your free Gemini API key:\n\n'
          '1. Visit ai.google.dev\n'
          '2. Sign in with your Google account\n'
          '3. Click "Get API Key"\n'
          '4. Create a new API key\n'
          '5. Copy and paste it here\n\n'
          'Would you like to open the website now?',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Open Website'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final url = Uri.parse('https://ai.google.dev/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  _showSnackbar(
                      'Could not open website. Please visit ai.google.dev manually.',
                      color: CupertinoColors.systemOrange);
                }
              } catch (e) {
                _showSnackbar(
                    'Could not open website. Please visit ai.google.dev manually.',
                    color: CupertinoColors.systemOrange);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    final settings = Hive.box('settings');
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('API Key Settings'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Get API button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.info_circle),
              onPressed: _showApiGuide,
            ),
            // Add API button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: _showAddApiKeyDialog,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: apiKeyBox.listenable(),
          builder: (context, Box<ApiKeyEntry> box, _) {
            final apiKeys = box.values.toList();
            final selectedIdx =
                settings.get('selectedApiKeyIndex', defaultValue: 0);

            if (apiKeys.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.app_badge,
                      size: 60,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No API Keys Added',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a Gemini API key to start generating tips',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          color: CupertinoColors.activeBlue.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(CupertinoIcons.info_circle,
                                  color: CupertinoColors.activeBlue, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Get API Key',
                                style: TextStyle(
                                    color: CupertinoColors.activeBlue),
                              ),
                            ],
                          ),
                          onPressed: _showApiGuide,
                        ),
                        const SizedBox(width: 12),
                        CupertinoButton.filled(
                          child: const Text('Add API Key'),
                          onPressed: _showAddApiKeyDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Toggle visibility button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _showKeys
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showKeys ? 'Hide API Keys' : 'Show API Keys',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      CupertinoSwitch(
                        value: _showKeys,
                        onChanged: (value) => setState(() => _showKeys = value),
                      ),
                    ],
                  ),
                ),

                // API Keys list
                Expanded(
                  child: ListView.builder(
                    itemCount: apiKeys.length,
                    itemBuilder: (context, index) {
                      final apiKey = apiKeys[index];
                      final isSelected = index == selectedIdx;
                      final isPendingDelete = _pendingDeleteIdx == index;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue.withOpacity(0.1)
                              : CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? CupertinoColors.activeBlue.withOpacity(0.3)
                                : CupertinoColors.systemGrey5,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CupertinoListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CupertinoColors.activeBlue.withOpacity(0.2)
                                  : CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.app_badge,
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            apiKey.nickname?.isNotEmpty == true
                                ? apiKey.nickname!
                                : 'API Key ${index + 1}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _showKeys ? apiKey.key : '•' * 32,
                                style: const TextStyle(
                                  fontFamily: 'SF Mono',
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.sparkles,
                                    size: 12,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      apiKey.model.displayName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: CupertinoColors.systemBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Model change button
                              CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  CupertinoIcons.settings,
                                  color: CupertinoColors.systemBlue,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _showEditApiKeyDialog(index, apiKey),
                              ),

                              // Test button
                              CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  CupertinoIcons.checkmark_circle,
                                  color: CupertinoColors.activeGreen,
                                  size: 20,
                                ),
                                onPressed: () => _testApiKey(apiKey.key,
                                    modelId: apiKey.modelId),
                              ),

                              // Select button
                              if (!isSelected)
                                CupertinoButton(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    CupertinoIcons.circle,
                                    color: CupertinoColors.systemGrey,
                                    size: 20,
                                  ),
                                  onPressed: () => _selectApiKey(index),
                                ),

                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    color: CupertinoColors.activeBlue,
                                    size: 20,
                                  ),
                                ),

                              // Delete button
                              CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  isPendingDelete
                                      ? CupertinoIcons.clear_circled_solid
                                      : CupertinoIcons.delete,
                                  color: CupertinoColors.destructiveRed,
                                  size: 20,
                                ),
                                onPressed: () => _showDeleteConfirmation(index),
                              ),
                            ],
                          ),
                          onTap: () => _selectApiKey(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

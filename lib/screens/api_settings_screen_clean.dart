import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/api_key_entry.dart';
import '../models/tip_entry.dart';
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
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Enter your Gemini API key',
              obscureText: true,
              maxLines: 1,
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
              if (controller.text.trim().isNotEmpty) {
                await _addApiKey(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addApiKey(String key) async {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    await apiKeyBox.add(ApiKeyEntry(key: key));
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

  Future<void> _testApiKey(String key) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key'),
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

  @override
  Widget build(BuildContext context) {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    final settings = Hive.box('settings');
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('API Key Settings'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: _showAddApiKeyDialog,
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
                    CupertinoButton.filled(
                      child: const Text('Add API Key'),
                      onPressed: _showAddApiKeyDialog,
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
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
                            padding: const EdgeInsets.all(8),
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
                            'API Key ${index + 1}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            _showKeys ? apiKey.key : '•' * 32,
                            style: const TextStyle(
                              fontFamily: 'SF Mono',
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Test button
                              CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  CupertinoIcons.checkmark_circle,
                                  color: CupertinoColors.activeGreen,
                                  size: 20,
                                ),
                                onPressed: () => _testApiKey(apiKey.key),
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

                // Help section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to get a Gemini API Key:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Visit ai.google.dev\n'
                        '2. Sign in with your Google account\n'
                        '3. Go to "Get API Key"\n'
                        '4. Create a new API key\n'
                        '5. Copy and paste it here',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                          height: 1.4,
                        ),
                      ),
                    ],
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

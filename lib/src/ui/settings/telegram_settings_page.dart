import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openiptv/src/telegram/telegram_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t/t.dart' as t;
import 'package:tg/tg.dart' as tg;

class TelegramSettingsPage extends StatefulWidget {
  const TelegramSettingsPage({super.key});

  @override
  State<TelegramSettingsPage> createState() => _TelegramSettingsPageState();
}

enum AuthState { idle, codeSent, passwordRequired, loggedIn }

class _TelegramSettingsPageState extends State<TelegramSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageCountController = TextEditingController(text: '50');

  // Auth Controllers
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  List<t.ChatBase> _myChats = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  // Telegram Client State
  tg.Client? get _client => TelegramService.instance.client;
  AuthState _authState = AuthState.idle;
  String? _statusMessage;
  t.AuthSentCode? _authSentCode;
  t.AccountPassword? _accountPassword;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Listen to logs
    TelegramService.instance.logs.listen((log) {
      if (mounted) {
        // Optional: show logs in UI or console
        debugPrint(log);
      }
    });
  }

  @override
  void dispose() {
    _messageCountController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageCount = prefs.getInt('telegram_message_count') ?? 50;

      if (mounted) {
        setState(() {
          _messageCountController.text = messageCount.toString();
          _isLoading = false;
        });
      }

      // Try to connect silently to check session
      _checkSession();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkSession() async {
    try {
      await TelegramService.instance.connect();
      if (_client != null) {
        // Check if authorized by making a simple call, e.g. getMe (users.getFullUser is complex, maybe help.getConfig)
        // Or just assume if we have a session we are good?
        // Let's try to get self
        // final me = await _client!.users.getUsers(id: [t.InputUserSelf()]);
        // But users.getUsers returns Vector<User>.

        // For now, just set loggedIn if connect succeeds and we have a session.
        // But connect() creates a new session if none exists.
        // We need to check if we are actually authorized.

        // We can try to get config, if it fails with auth error then we are not logged in.
        // But initConnection was called in connect().

        setState(() {
          // We assume logged in if we can connect, but we might need to verify.
          // If we are not authorized, we will find out when we try to fetch.
          // Ideally we should check `await _client!.auth.getAuthorization()`? No such method.

          // Let's assume idle until user tries to login or we fetch.
          // But if we have a saved session, we might be logged in.
          _authState = AuthState.loggedIn;
        });
        _fetchDialogs();
      }
    } catch (e) {
      debugPrint('Session check failed: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final count = int.tryParse(_messageCountController.text) ?? 50;
      await prefs.setInt('telegram_message_count', count);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _fetchDialogs() async {
    if (_client == null) return;
    // Don't set global loading, just background fetch or local loading
    try {
      final res = await _client!.invoke(
        t.MessagesGetDialogs(
          offsetDate: DateTime.fromMillisecondsSinceEpoch(0),
          offsetId: 0,
          offsetPeer: const t.InputPeerEmpty(),
          limit: 100,
          hash: 0,
          excludePinned: false,
          folderId: 0,
        ),
      );

      List<t.ChatBase> chats = [];
      if (res.result is t.MessagesDialogs) {
        chats = (res.result as t.MessagesDialogs).chats;
      } else if (res.result is t.MessagesDialogsSlice) {
        chats = (res.result as t.MessagesDialogsSlice).chats;
      }

      if (mounted) {
        setState(() {
          _myChats = chats.where((c) => c is t.Chat || c is t.Channel).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching dialogs: $e');
    }
  }

  // --- Auth Methods ---

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _setStatus('Please enter phone number (e.g. +1234567890)');
      return;
    }

    setState(() => _isSyncing = true);
    _setStatus('Connecting...');

    try {
      final client = await TelegramService.instance.connect();

      _setStatus('Sending code...');
      final res = await client.auth.sendCode(
        phoneNumber: phone,
        apiId: TelegramService.instance.apiId,
        apiHash: TelegramService.instance.apiHash,
        settings: const t.CodeSettings(
          allowFlashcall: false,
          currentNumber: true,
          allowAppHash: false,
          allowMissedCall: false,
          allowFirebase: false,
          unknownNumber: false,
        ),
      );

      if (res.error != null) {
        if (res.error!.errorCode == 303 &&
            res.error!.errorMessage.startsWith('PHONE_MIGRATE_')) {
          final dcId = int.parse(res.error!.errorMessage.split('_').last);
          _setStatus('Account is on DC $dcId. Switching...');
          await TelegramService.instance.switchDc(dcId);
          if (mounted) await _login();
          return;
        }
        throw res.error!;
      }

      setState(() {
        _authSentCode = res.result as t.AuthSentCode;
        _authState = AuthState.codeSent;
        _statusMessage = 'Code sent to Telegram app.';
        _isSyncing = false;
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Error sending code: $e';
      });
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    final phone = _phoneController.text.trim();

    if (code.isEmpty || _authSentCode == null) return;

    setState(() => _isSyncing = true);
    _setStatus('Verifying code...');

    try {
      final client = TelegramService.instance.client!;
      final res = await client.auth.signIn(
        phoneNumber: phone,
        phoneCodeHash: _authSentCode!.phoneCodeHash,
        phoneCode: code,
      );

      if (res.error != null) {
        if (res.error!.errorMessage == 'SESSION_PASSWORD_NEEDED') {
          final pwdRes = await client.account.getPassword();
          if (pwdRes.error != null) throw pwdRes.error!;

          setState(() {
            _accountPassword = pwdRes.result as t.AccountPassword;
            _authState = AuthState.passwordRequired;
            _statusMessage = 'Two-Step Verification required.';
            _isSyncing = false;
          });
          return;
        }
        throw res.error!;
      }

      final authRes = res.result;
      if (authRes is t.AuthAuthorization) {
        setState(() {
          _authState = AuthState.loggedIn;
          _statusMessage = 'Logged in successfully!';
          _isSyncing = false;
        });
        _fetchDialogs();
      } else if (authRes is t.AuthAuthorizationSignUpRequired) {
        _setStatus('Sign up required (not supported in this client).');
        setState(() => _isSyncing = false);
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Error signing in: $e';
      });
    }
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() => _isSyncing = true);
    _setStatus('Verifying password...');

    try {
      final client = TelegramService.instance.client!;
      final passwordInput = await tg.check2FA(_accountPassword!, password);
      final res = await client.auth.checkPassword(password: passwordInput);

      if (res.error != null) throw res.error!;

      setState(() {
        _authState = AuthState.loggedIn;
        _statusMessage = 'Logged in successfully!';
        _isSyncing = false;
      });
      _fetchDialogs();
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Error verifying password: $e';
      });
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  // --- Fetching ---

  Future<void> _fetchMessages() async {
    if (_client == null || _authState != AuthState.loggedIn) {
      _setStatus('Not logged in.');
      return;
    }

    if (_myChats.isEmpty) {
      _setStatus('No channels found.');
      return;
    }

    setState(() => _isSyncing = true);
    _setStatus('Starting fetch...');

    try {
      final messageCount = int.tryParse(_messageCountController.text) ?? 50;
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      for (final chat in _myChats) {
        t.InputPeerBase? peer;
        String title = 'Unknown';
        String handle = 'unknown';

        if (chat is t.Channel) {
          peer = t.InputPeerChannel(
            channelId: chat.id,
            accessHash: chat.accessHash ?? 0,
          );
          title = chat.title;
          handle = chat.username ?? 'channel_${chat.id}';
        } else if (chat is t.Chat) {
          peer = t.InputPeerChat(chatId: chat.id);
          title = chat.title;
          handle = 'group_${chat.id}';
        }

        if (peer == null) continue;

        _setStatus('Fetching $title...');

        try {
          // Fetch History
          final historyRes = await _client!.invoke(
            t.MessagesGetHistory(
              peer: peer,
              limit: messageCount,
              offsetId: 0,
              offsetDate: DateTime.fromMillisecondsSinceEpoch(0),
              addOffset: 0,
              maxId: 0,
              minId: 0,
              hash: 0,
            ),
          );

          if (historyRes.error != null) throw historyRes.error!;

          final history = historyRes.result;

          List<t.MessageBase> messages = [];
          if (history is t.MessagesMessages) {
            messages = history.messages;
          } else if (history is t.MessagesChannelMessages) {
            messages = history.messages;
          } else if (history is t.MessagesMessagesSlice) {
            messages = history.messages;
          }

          final sb = StringBuffer();
          sb.writeln('Channel: $title ($handle)');
          sb.writeln('Fetched at: $timestamp');
          sb.writeln('Messages Found: ${messages.length}');
          sb.writeln('-------------------');

          int i = 1;
          for (final msg in messages) {
            if (msg is t.Message) {
              sb.writeln('[$i] ${msg.message}');
              sb.writeln('---');
              i++;
            }
          }

          final safeName = handle.replaceAll(RegExp(r'[^\w\d]'), '_');
          final file = File(
            '${tempDir.path}/telegram_${safeName}_$timestamp.txt',
          );
          await file.writeAsString(sb.toString());
          debugPrint('Saved to ${file.path}');
        } catch (e) {
          debugPrint('Error fetching $title: $e');
          _setStatus('Error fetching $title: $e');
        }
      }

      setState(() {
        _isSyncing = false;
        _statusMessage = 'Fetch complete! Check temp folder.';
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Global error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telegram Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Bar
                    if (_statusMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.blue.shade50,
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),

                    // Auth Section
                    const Text(
                      'Authentication',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_authState == AuthState.idle) ...[
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+1234567890',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _login,
                        child: const Text('Send Code'),
                      ),
                    ] else if (_authState == AuthState.codeSent) ...[
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Verification Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _submitCode,
                        child: const Text('Submit Code'),
                      ),
                    ] else if (_authState == AuthState.passwordRequired) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '2FA Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _submitPassword,
                        child: const Text('Submit Password'),
                      ),
                    ] else if (_authState == AuthState.loggedIn) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Logged In'),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          await TelegramService.instance.logout();
                          setState(() {
                            _authState = AuthState.idle;
                            _statusMessage = 'Logged out.';
                          });
                        },
                        child: const Text('Logout'),
                      ),
                    ],

                    const Divider(height: 32),

                    // Settings Section
                    const Text(
                      'Scraping Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageCountController,
                      decoration: const InputDecoration(
                        labelText: 'Messages to Fetch',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Settings'),
                    ),

                    const Divider(height: 32),

                    // Channels Section
                    const Text(
                      'Channels / Groups',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_myChats.isEmpty)
                      const Text('No channels found. Log in to see channels.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myChats.length,
                        itemBuilder: (context, index) {
                          final chat = _myChats[index];
                          String title = 'Unknown';
                          if (chat is t.Channel) {
                            title = chat.title;
                          } else if (chat is t.Chat) {
                            title = chat.title;
                          }
                          return ListTile(
                            title: Text(title),
                            trailing: const Icon(Icons.hourglass_empty),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isSyncing || _authState != AuthState.loggedIn)
                            ? null
                            : _fetchMessages,
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          _isSyncing ? 'Fetching...' : 'Fetch Messages Now',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

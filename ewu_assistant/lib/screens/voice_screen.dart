import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/student_profile.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_branding.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/notification_action_button.dart';
import 'profile_screen.dart';

enum _AssistantMode { voice, text }

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key, required this.onSignedOut});

  final Future<void> Function() onSignedOut;

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _defaultSuggestions = <String>[
    'Admission requirements',
    'Tuition fees',
    'Student clubs',
    'Campus facilities',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  late final AnimationController _glowController;

  _AssistantMode _mode = _AssistantMode.voice;
  int _lastRenderedMessageCount = -1;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _textScrollController.dispose();
    _messageFocusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setMode(_AssistantMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
    });

    if (mode == _AssistantMode.text) {
      context.read<ChatProvider>().stopListening();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _messageFocusNode.requestFocus();
        }
      });
    } else {
      _messageFocusNode.unfocus();
    }
  }

  Future<void> _handleVoiceTap(ChatProvider provider) async {
    if (provider.loading) {
      _showMessage('Please wait for the current reply to finish first.');
      return;
    }

    if (provider.listening) {
      await provider.stopListening();
      return;
    }

    final bool started = await provider.startListening();
    if (!started) {
      _showMessage(
        'Microphone access or speech recognition is unavailable right now. Check mic permission and try again.',
      );
    }
  }

  Future<void> _send(ChatProvider provider, [String? preset]) async {
    final String text = (preset ?? _messageController.text).trim();
    if (text.isEmpty || provider.loading) {
      return;
    }

    if (preset == null) {
      _messageController.clear();
    }

    await provider.sendMessage(text);
    if (!mounted || _mode != _AssistantMode.text) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _messageFocusNode.requestFocus();
      }
    });
  }

  Future<void> _confirmClear(ChatProvider provider) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Clear Assistant Session?',
      message:
          'This will remove your current campus assistant conversation and reset the voice session.',
      confirmLabel: 'Clear Session',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    provider.clearMessages();
    _messageController.clear();
    _showMessage('Assistant session cleared.');
  }

  void _syncAnimations(ChatProvider provider) {
    if (provider.listening && !_glowController.isAnimating) {
      _glowController.repeat();
    } else if (!provider.listening && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  void _scheduleTextScroll(List<ChatMessage> messages, bool loading) {
    final int targetCount = messages.length + (loading ? 1 : 0);
    if (_mode != _AssistantMode.text ||
        targetCount == _lastRenderedMessageCount) {
      return;
    }

    _lastRenderedMessageCount = targetCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_textScrollController.hasClients) {
        return;
      }
      _textScrollController.animateTo(
        _textScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  ChatMessage? _latestAssistantMessage(List<ChatMessage> messages) {
    for (final ChatMessage message in messages.reversed) {
      if (!message.isUser) {
        return message;
      }
    }
    return null;
  }

  List<String> _buildSuggestions(ChatMessage? latestReply) {
    final Iterable<String> source = latestReply?.suggestions.isNotEmpty == true
        ? latestReply!.suggestions
        : _defaultSuggestions;
    final List<String> suggestions = <String>[];
    for (final String suggestion in source) {
      final String trimmed = suggestion.trim();
      if (trimmed.isEmpty || suggestions.contains(trimmed)) {
        continue;
      }
      suggestions.add(trimmed);
      if (suggestions.length == 4) {
        break;
      }
    }
    return suggestions.isEmpty
        ? List<String>.from(_defaultSuggestions)
        : suggestions;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Consumer<ChatProvider>(
        builder: (BuildContext context, ChatProvider provider, Widget? child) {
          final StudentProfile? profile = provider.studentProfile;
          final ChatMessage? latestReply = _latestAssistantMessage(
            provider.messages,
          );
          final bool isVoiceMode = _mode == _AssistantMode.voice;
          final List<String> suggestions = _buildSuggestions(latestReply);

          _syncAnimations(provider);
          _scheduleTextScroll(provider.messages, provider.loading);

          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: isVoiceMode
                ? AppTheme.primaryDark
                : AppTheme.pageTint,
            body: Container(
              decoration: BoxDecoration(
                gradient: isVoiceMode
                    ? AppTheme.navyGradient
                    : AppTheme.backgroundGradient,
              ),
              child: SafeArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    10 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    children: <Widget>[
                      _AssistantHeader(
                        profile: profile,
                        serverOnline: provider.serverOnline,
                        hasMessages: provider.messages.isNotEmpty,
                        darkMode: isVoiceMode,
                        selectedMode: _mode,
                        onModeChanged: _setMode,
                        onOpenProfile: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<ProfileScreen>(
                              builder: (_) => ProfileScreen(
                                onSignedOut: widget.onSignedOut,
                              ),
                            ),
                          );
                        },
                        onClear: () => _confirmClear(provider),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _mode == _AssistantMode.voice
                              ? _VoiceModeView(
                                  key: const ValueKey<String>('voice_mode'),
                                  provider: provider,
                                  latestReply: latestReply,
                                  suggestions: suggestions,
                                  glowController: _glowController,
                                  onMicTap: () => _handleVoiceTap(provider),
                                  onSuggestionTap: (String suggestion) =>
                                      _send(provider, suggestion),
                                )
                              : _TextModeView(
                                  key: const ValueKey<String>('text_mode'),
                                  provider: provider,
                                  latestReply: latestReply,
                                  suggestions: suggestions,
                                  controller: _messageController,
                                  focusNode: _messageFocusNode,
                                  scrollController: _textScrollController,
                                  onSend: () => _send(provider),
                                  onSuggestionTap: (String suggestion) =>
                                      _send(provider, suggestion),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.profile,
    required this.serverOnline,
    required this.hasMessages,
    required this.darkMode,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onOpenProfile,
    required this.onClear,
  });

  final StudentProfile? profile;
  final bool serverOnline;
  final bool hasMessages;
  final bool darkMode;
  final _AssistantMode selectedMode;
  final ValueChanged<_AssistantMode> onModeChanged;
  final VoidCallback onOpenProfile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final Color headingColor = darkMode ? Colors.white : AppTheme.textPrimary;
    final Color secondaryColor = darkMode
        ? Colors.white.withValues(alpha: 0.76)
        : AppTheme.textSecondary;
    final Color actionBackground = darkMode
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.botBubble;
    final Color actionForeground = darkMode
        ? Colors.white
        : AppTheme.primaryDark;
    final String subtitle = darkMode
        ? (profile == null
              ? 'Ask a campus question with voice and get one focused answer at a time.'
              : 'Hello, ${profile!.firstName}. Tap the mic to ask about campus life, tuition, facilities, or student support.')
        : 'Type a question and keep the assistant ready for smooth follow-up prompts.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: darkMode
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            )
          : AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppLogoMark(
                size: 40,
                dark: darkMode,
                backgroundColor: darkMode
                    ? const Color(0x26FFFFFF)
                    : AppTheme.botBubble,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'EWU Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(serverOnline: serverOnline, darkMode: darkMode),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            darkMode ? 'Voice Assistant' : 'Text Assistant',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _ModeToggle(
            darkMode: darkMode,
            selectedMode: selectedMode,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              NotificationActionButton(
                backgroundColor: actionBackground,
                foregroundColor: actionForeground,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: hasMessages ? onClear : null,
                icon: const Icon(Icons.delete_sweep_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: actionBackground,
                  foregroundColor: actionForeground,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onOpenProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: darkMode
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppTheme.primaryDark.withValues(alpha: 0.12),
                  backgroundImage: profile?.photoUrl.isNotEmpty == true
                      ? NetworkImage(profile!.photoUrl)
                      : null,
                  child: profile?.photoUrl.isEmpty != false
                      ? Text(
                          (profile?.firstName ?? 'E')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: darkMode
                                ? Colors.white
                                : AppTheme.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.serverOnline, required this.darkMode});

  final bool serverOnline;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final Color background = darkMode
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.botBubble;
    final Color textColor = darkMode ? Colors.white : AppTheme.primaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: serverOnline
                  ? const Color(0xFF62D38D)
                  : const Color(0xFFFFD166),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            serverOnline ? 'Online' : 'Fallback',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.darkMode,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final bool darkMode;
  final _AssistantMode selectedMode;
  final ValueChanged<_AssistantMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withValues(alpha: 0.1)
            : AppTheme.botBubble,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeChip(
              darkMode: darkMode,
              label: 'Voice',
              icon: Icons.mic_none_rounded,
              selected: selectedMode == _AssistantMode.voice,
              onTap: () => onModeChanged(_AssistantMode.voice),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeChip(
              darkMode: darkMode,
              label: 'Text',
              icon: Icons.chat_bubble_outline_rounded,
              selected: selectedMode == _AssistantMode.text,
              onTap: () => onModeChanged(_AssistantMode.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.darkMode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final bool darkMode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedBackground = darkMode
        ? Colors.white
        : AppTheme.primaryDark;
    final Color selectedForeground = darkMode
        ? AppTheme.primaryDark
        : Colors.white;
    final Color idleForeground = darkMode ? Colors.white : AppTheme.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: selected ? selectedForeground : idleForeground,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? selectedForeground : idleForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceModeView extends StatelessWidget {
  const _VoiceModeView({
    super.key,
    required this.provider,
    required this.latestReply,
    required this.suggestions,
    required this.glowController,
    required this.onMicTap,
    required this.onSuggestionTap,
  });

  final ChatProvider provider;
  final ChatMessage? latestReply;
  final List<String> suggestions;
  final AnimationController glowController;
  final VoidCallback onMicTap;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          key: key,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 14),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _VoiceTapPanel(
                  provider: provider,
                  glowController: glowController,
                  onTap: onMicTap,
                ),
                if (provider.partialText.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  _DarkSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Listening now',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          provider.partialText,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _VoiceResponsePanel(
                  provider: provider,
                  latestReply: latestReply,
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick prompts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: suggestions.map((String suggestion) {
                    return _PromptChip(
                      label: suggestion,
                      darkMode: true,
                      onTap: provider.loading
                          ? null
                          : () => onSuggestionTap(suggestion),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VoiceTapPanel extends StatelessWidget {
  const _VoiceTapPanel({
    required this.provider,
    required this.glowController,
    required this.onTap,
  });

  final ChatProvider provider;
  final AnimationController glowController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String headline = provider.listening ? 'Listening...' : 'Tap to Ask';
    final String subtext = provider.listening
        ? 'Speak clearly. Your final speech will be sent automatically.'
        : provider.loading
        ? 'Your last question is being processed.'
        : 'Tap anywhere in this panel to start voice input.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: _DarkSurfaceCard(
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: glowController,
                      builder: (BuildContext context, Widget? child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: List<Widget>.generate(2, (int index) {
                            final double progress =
                                (glowController.value + index * 0.34) % 1;
                            final double scale = 1 + progress * 0.55;
                            final double opacity = provider.listening
                                ? (1 - progress) * 0.22
                                : 0.07;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 98,
                                height: 98,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF69A0FF,
                                  ).withValues(alpha: opacity),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    Container(
                      height: 104,
                      width: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFFFDFEFF), Color(0xFFD7E3FF)],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFF6A9BFF,
                            ).withValues(alpha: 0.24),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        provider.listening
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        color: AppTheme.primaryDark,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                headline,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceResponsePanel extends StatelessWidget {
  const _VoiceResponsePanel({
    required this.provider,
    required this.latestReply,
  });

  final ChatProvider provider;
  final ChatMessage? latestReply;

  @override
  Widget build(BuildContext context) {
    return _DarkSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.smart_toy_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recent assistant reply',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (provider.loading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _ScrollableReplyText(
            text:
                latestReply?.text ??
                'Ask a question and the assistant reply will appear here in a readable card.',
            darkMode: true,
            placeholder: latestReply == null,
          ),
          if (latestReply != null &&
              (latestReply!.intent != null ||
                  latestReply!.source != null ||
                  latestReply!.responseTimeMs != null)) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (latestReply!.intent != null)
                  _MetaChip(
                    label: latestReply!.intent!.replaceAll('_', ' '),
                    darkMode: true,
                  ),
                if (latestReply!.source != null)
                  _MetaChip(label: latestReply!.source!, darkMode: true),
                if (latestReply!.responseTimeMs != null)
                  _MetaChip(
                    label:
                        '${latestReply!.responseTimeMs!.toStringAsFixed(0)} ms',
                    darkMode: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkSurfaceCard extends StatelessWidget {
  const _DarkSurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _TextModeView extends StatelessWidget {
  const _TextModeView({
    super.key,
    required this.provider,
    required this.latestReply,
    required this.suggestions,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onSend,
    required this.onSuggestionTap,
  });

  final ChatProvider provider;
  final ChatMessage? latestReply;
  final List<String> suggestions;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Text assistant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (provider.loading)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.botBubble,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        latestReply == null ? 'Recent reply' : 'Pinned reply',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ScrollableReplyText(
                        text:
                            latestReply?.text ??
                            'Type a question for EWU Assistant. Your latest answer stays pinned here while the conversation stays scrollable below.',
                        darkMode: false,
                        placeholder: latestReply == null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.messages.isEmpty
                ? _TextEmptyState(
                    suggestions: suggestions,
                    onSuggestionTap: provider.loading ? null : onSuggestionTap,
                  )
                : Scrollbar(
                    controller: scrollController,
                    thumbVisibility: provider.messages.length > 5,
                    child: ListView.separated(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount:
                          provider.messages.length + (provider.loading ? 1 : 0),
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= provider.messages.length) {
                          return const _TypingBubble();
                        }
                        return _AssistantBubble(
                          message: provider.messages[index],
                        );
                      },
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppTheme.primaryDark.withValues(alpha: 0.06),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: _MessageComposer(
              controller: controller,
              focusNode: focusNode,
              loading: provider.loading,
              onSend: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextEmptyState extends StatelessWidget {
  const _TextEmptyState({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.botBubble,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Start with text',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Text mode keeps the assistant compact and makes follow-up questions easier on smaller phones.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Quick prompts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions.map((String suggestion) {
            return _PromptChip(
              label: suggestion,
              darkMode: false,
              onTap: onSuggestionTap == null
                  ? null
                  : () => onSuggestionTap!(suggestion),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth > 340 ? 340 : maxWidth),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.userBubble : AppTheme.botBubble,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  height: 1.45,
                ),
              ),
              if (!isUser &&
                  (message.intent != null ||
                      message.source != null ||
                      message.responseTimeMs != null)) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (message.intent != null)
                      _MetaChip(
                        label: message.intent!.replaceAll('_', ' '),
                        darkMode: false,
                      ),
                    if (message.source != null)
                      _MetaChip(label: message.source!, darkMode: false),
                    if (message.responseTimeMs != null)
                      _MetaChip(
                        label:
                            '${message.responseTimeMs!.toStringAsFixed(0)} ms',
                        darkMode: false,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.botBubble,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.36),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Type a question for EWU Assistant',
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              onPressed: loading ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.darkMode, this.onTap});

  final String label;
  final bool darkMode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: darkMode
            ? Colors.white.withValues(alpha: 0.14)
            : AppTheme.botBubble,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: darkMode ? Colors.white : AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.darkMode});

  final String label;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: darkMode ? Colors.white.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: darkMode ? Colors.white : AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScrollableReplyText extends StatelessWidget {
  const _ScrollableReplyText({
    required this.text,
    required this.darkMode,
    required this.placeholder,
  });

  final String text;
  final bool darkMode;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final Color textColor = darkMode
        ? Colors.white.withValues(alpha: placeholder ? 0.78 : 1)
        : (placeholder ? AppTheme.textSecondary : AppTheme.textPrimary);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: textColor, height: 1.45),
        ),
      ),
    );
  }
}

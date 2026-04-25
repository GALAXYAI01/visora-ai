import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';

// ── Chat Message Model ──
class _ChatMsg {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMsg({required this.text, required this.isUser}) : time = DateTime.now();
}

/// Full-screen Gemini chatbot overlay
class GeminiChatSheet extends ConsumerStatefulWidget {
  const GeminiChatSheet({super.key});
  @override
  ConsumerState<GeminiChatSheet> createState() => _GeminiChatSheetState();
}

class _GeminiChatSheetState extends ConsumerState<GeminiChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(
      text: "Hi! I'm Visora AI — your bias auditing assistant. Ask me anything about fairness metrics, "
            "disparate impact, equalized odds, or how to fix bias in your models.",
      isUser: false,
    ),
  ];
  bool _loading = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMsg(text: text, isUser: true));
      _loading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    final answer = await GeminiService.chat(text);
    setState(() => _messages.add(_ChatMsg(text: answer, isUser: false)));

    _loading = false;
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: VisoraColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(children: [
        // ── Handle Bar ──
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40, height: 4,
          decoration: BoxDecoration(color: VisoraColors.outlineVariant, borderRadius: BorderRadius.circular(2)),
        ),

        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Visora AI', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
              Text('Powered by Gemini', style: GoogleFonts.inter(
                fontSize: 11, color: VisoraColors.onSurfaceVariant)),
            ]),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: VisoraColors.onSurfaceVariant, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),

        Divider(height: 1, color: VisoraColors.outlineVariant),

        // ── Messages ──
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length) return _TypingIndicator();
              return _MessageBubble(msg: _messages[i])
                .animate().fadeIn(duration: 250.ms).slideY(begin: 0.08);
            },
          ),
        ),

        // ── Suggested Questions ──
        if (_messages.length <= 2)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SuggestionChip('What is disparate impact?', onTap: () { _ctrl.text = 'What is disparate impact?'; _send(); }),
                _SuggestionChip('How to fix gender bias?', onTap: () { _ctrl.text = 'How to fix gender bias in hiring?'; _send(); }),
                _SuggestionChip('Explain equalized odds', onTap: () { _ctrl.text = 'Explain equalized odds metric'; _send(); }),
                _SuggestionChip('What is EEOC compliance?', onTap: () { _ctrl.text = 'What is EEOC compliance for AI models?'; _send(); }),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ── Input ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          decoration: BoxDecoration(
            color: VisoraColors.surfaceLowest,
            border: Border(top: BorderSide(color: VisoraColors.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Ask about bias, fairness, compliance...',
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: VisoraColors.outlineVariant)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: VisoraColors.outlineVariant)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: VisoraColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: VisoraColors.background,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _loading ? VisoraColors.surfaceHigh : VisoraColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _loading ? null : _send,
                  icon: Icon(_loading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Message Bubble ──
class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _MessageBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: msg.isUser ? 48 : 0,
        right: msg.isUser ? 0 : 48,
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: msg.isUser ? VisoraColors.primary : VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 16),
            ),
            border: msg.isUser ? null : Border.all(color: VisoraColors.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: SelectableText(msg.text, style: GoogleFonts.inter(
            fontSize: 13.5,
            color: msg.isUser ? Colors.white : VisoraColors.onSurface,
            height: 1.5,
          )),
        ),
      ),
    );
  }
}

// ── Typing Indicator ──
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VisoraColors.outlineVariant),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(delay: 0), const SizedBox(width: 4),
            _Dot(delay: 150), const SizedBox(width: 4),
            _Dot(delay: 300),
            const SizedBox(width: 8),
            Text('Thinking...', style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.onSurfaceVariant)),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8,
      decoration: const BoxDecoration(color: VisoraColors.primary, shape: BoxShape.circle),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .fadeIn(delay: Duration(milliseconds: delay))
      .scaleXY(begin: 0.5, end: 1.0, duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}

// ── Suggestion Chip ──
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip(this.label, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.primary)),
        onPressed: onTap,
        backgroundColor: VisoraColors.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

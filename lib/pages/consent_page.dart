import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';

class PolicyViewerPage extends StatefulWidget {
  final String policyType; // 'privacy' or 'terms'
  const PolicyViewerPage({super.key, required this.policyType});

  @override
  State<PolicyViewerPage> createState() => _PolicyViewerPageState();
}

class _PolicyViewerPageState extends State<PolicyViewerPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  bool _isRead = false;
  late Future<String> _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = _loadPolicy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initialize read state from preferences
    final prefs = Provider.of<PrefsService>(context, listen: false);
    setState(() {
      _isRead = widget.policyType == 'privacy'
          ? prefs.isPrivacyRead
          : prefs.isTermsRead;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _loadPolicy() async {
    final file = widget.policyType == 'privacy' ? 'privacidade.md' : 'terms.md';
    return await rootBundle.loadString('assets/policies/$file');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.policyType == 'privacy'
              ? 'Política de Privacidade'
              : 'Termos de Uso')),
      body: FutureBuilder<String>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Erro ao carregar o documento. Tente novamente mais tarde.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Voltar'))
                    ])));
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isRead && _scrollController.hasClients) {
              final maxExtent = _scrollController.position.maxScrollExtent;
              if (maxExtent <= 0) {
                setState(() {
                  _isRead = true;
                  _scrollProgress = 1.0;
                });
              }
            }
          });

          return Column(
            children: [
              LinearProgressIndicator(value: _scrollProgress),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    final metrics = notification.metrics;
                    final max = metrics.maxScrollExtent;
                    final pixels = metrics.pixels;
                    if (max <= 0) {
                      if (!_isRead) {
                        setState(() {
                          _isRead = true;
                          _scrollProgress = 1.0;
                        });
                      }
                    } else {
                      final progress = (pixels / max).clamp(0.0, 1.0);
                      final reachedEnd = pixels >= (max - 1.0);
                      setState(() {
                        _scrollProgress = progress;
                        _isRead = reachedEnd;
                      });
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBody(data: snapshot.data!)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isRead ? _markAsRead : null,
                  icon: const Icon(Icons.check),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isRead ? const Color(0xFF059669) : null,
                      foregroundColor: _isRead ? Colors.white : null,
                      minimumSize: const Size(double.infinity, 48)),
                  label: const Text('Marcar como lido'),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _markAsRead() async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    await prefs.setPolicyRead(widget.policyType, true);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});
  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _privacyRead = false;
  bool _termsRead = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefs = Provider.of<PrefsService>(context, listen: false);
    setState(() {
      _privacyRead = prefs.isPrivacyRead;
      _termsRead = prefs.isTermsRead;
    });
  }

  bool get _canAccept => _privacyRead && _termsRead;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consentimento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Aceite nossas políticas para continuar.',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text('Li e concordo com a Política de Privacidade'),
              value: _privacyRead,
              onChanged: (value) async {
                if (value == true) {
                  final navigator = Navigator.of(context);
                  final result = await navigator.push<bool?>(MaterialPageRoute(
                      builder: (_) =>
                          const PolicyViewerPage(policyType: 'privacy')));
                  if (!mounted) return;
                  if (result == true) {
                    setState(() {
                      _privacyRead = true;
                    });
                  }
                }
              },
            ),
            CheckboxListTile(
              title: const Text('Li e concordo com os Termos de Uso'),
              value: _termsRead,
              onChanged: (value) async {
                if (value == true) {
                  final navigator = Navigator.of(context);
                  final result = await navigator.push<bool?>(MaterialPageRoute(
                      builder: (_) =>
                          const PolicyViewerPage(policyType: 'terms')));
                  if (!mounted) return;
                  if (result == true) {
                    setState(() {
                      _termsRead = true;
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _canAccept
                  ? () async {
                      final navigator = Navigator.of(context);
                      final prefs =
                          Provider.of<PrefsService>(context, listen: false);
                      await prefs.acceptPolicies();
                      if (!mounted) return;
                      // After accepting policies, go to Home
                      navigator.pushReplacementNamed('/home');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                  maximumSize: const Size(double.infinity, 48),
                  backgroundColor: _canAccept ? const Color(0xFF059669) : null,
                  foregroundColor: _canAccept ? Colors.white : null),
              child: const Text('Aceitar e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

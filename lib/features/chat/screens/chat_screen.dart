import 'package:chatbotapp/features/chat/models/chat_message.dart';
import 'package:chatbotapp/features/chat/screens/chat_provider.dart';
import 'package:chatbotapp/features/chat/screens/home_screen.dart';  
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 

class ChatScreen extends ConsumerStatefulWidget {
  final int chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showScrollToBottom = false;

  // Colores del tema CoddyKIA
  static const Color primaryBlue = Color.fromARGB(255, 0, 3, 173);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color.fromARGB(255, 10, 22, 80);
  static const Color accentYellow = Color(0xFFFFF176);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _animationController.forward();
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final showButton = maxScroll - currentScroll > 100;

      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    await ref
        .read(chatProvider(widget.chatId).notifier)
        .sendMessage(widget.chatId, message);

    // Pequeño delay para asegurar que el mensaje se haya añadido
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Borrar Historial',
                  style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              '¿Estás seguro de que quieres borrar todo el historial de esta conversación? Esta acción no se puede deshacer.',
              style: TextStyle(color: darkBlue, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Borrar'),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref
          .read(chatProvider(widget.chatId).notifier)
          .clearChat(widget.chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.chatId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, darkBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Builder(
          builder:
              (context) => IconButton(
                color: Colors.white,
                tooltip: 'Abrir menú',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology, color: darkBlue, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CoddyKIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Tu asistente inteligente',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _clearChat,
              tooltip: 'Borrar historial',
            ),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: chatState.when(
                loading:
                    () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const CircularProgressIndicator(
                              color: primaryBlue,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando conversación...',
                            style: TextStyle(
                              color: darkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                error:
                    (error, stack) => Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error al cargar el chat',
                              style: TextStyle(
                                color: darkBlue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: $error',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                data:
                    (messages) =>
                        messages.isEmpty
                            ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryYellow, accentYellow],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.psychology,
                                        color: darkBlue,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      '¡Hola! Soy CoddyKIA',
                                      style: TextStyle(
                                        color: darkBlue,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Estoy aquí para ayudarte con todas tus preguntas.\n¡Comienza escribiendo algo!',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: isTablet ? 40 : 0,
                              ),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  return ImprovedMessageBubble(
                                    message: message,
                                  );
                                },
                              ),
                            ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 0),
                child: ImprovedChatInput(onSend: _sendMessage),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _showScrollToBottom
              ? Container(
                margin: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton.small(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              )
              : null,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// Widget mejorado para las burbujas de mensajes
class ImprovedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showCopyButton;

  // Colores del tema
  static const Color primaryBlue = Color.fromARGB(255, 0, 3, 173);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color.fromARGB(255, 10, 22, 80);
  static const Color accentYellow = Color(0xFFFFF176);

  const ImprovedMessageBubble({
    super.key,
    required this.message,
    this.showCopyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.isUserMessage;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            Container(
              margin: const EdgeInsets.only(right: 12, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryYellow, accentYellow],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryYellow.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.psychology, color: darkBlue, size: 20),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * (screenWidth > 600 ? 0.7 : 0.8),
              ),
              decoration: BoxDecoration(
                gradient:
                    isUserMessage
                        ? const LinearGradient(
                          colors: [primaryBlue, darkBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                color: isUserMessage ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUserMessage ? 20 : 4),
                  bottomRight: Radius.circular(isUserMessage ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isUserMessage
                            ? primaryBlue.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contenido del mensaje
                        Expanded(
                          child:
                              isUserMessage
                                  ? Text(
                                    message.content,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  )
                                  : MarkdownBody(
                                    data: message.content,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        color: darkBlue,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                      code: TextStyle(
                                        color: darkBlue,
                                        backgroundColor: lightBlue.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                      codeblockPadding: const EdgeInsets.all(
                                        12,
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: lightBlue.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: primaryBlue.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      h1: const TextStyle(
                                        color: darkBlue,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      h2: const TextStyle(
                                        color: darkBlue,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      h3: const TextStyle(
                                        color: darkBlue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      blockquote: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      blockquoteDecoration: BoxDecoration(
                                        color: lightBlue.withValues(alpha: 0.3),
                                        border: const Border(
                                          left: BorderSide(
                                            color: primaryBlue,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      listBullet: const TextStyle(
                                        color: darkBlue,
                                      ),
                                      tableBorder: TableBorder.all(
                                        color: primaryBlue.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      tableHead: const TextStyle(
                                        color: darkBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      tableBody: const TextStyle(
                                        color: darkBlue,
                                      ),
                                    ),
                                  ),
                        ),
                        // Botón de copiar compacto al lado derecho
                        if (showCopyButton && !isUserMessage) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: lightBlue.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.content_copy,
                                size: 14,
                                color: primaryBlue,
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: message.content),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Copiado al portapapeles'),
                                        ],
                                      ),
                                      backgroundColor: primaryBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Copiar mensaje',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUserMessage) ...[
            Container(
              margin: const EdgeInsets.only(left: 12, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.person, color: primaryBlue, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget mejorado para el input del chat
class ImprovedChatInput extends StatefulWidget {
  final Function(String) onSend;

  const ImprovedChatInput({super.key, required this.onSend});

  @override
  State<ImprovedChatInput> createState() => _ImprovedChatInputState();
}

class _ImprovedChatInputState extends State<ImprovedChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isTyping = false;

  // Colores del tema
  static const Color primaryBlue = Color.fromARGB(255, 0, 3, 173);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color.fromARGB(255, 10, 22, 80); 

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSend(message);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: lightBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      _focusNode.hasFocus
                          ? primaryBlue
                          : primaryBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: darkBlue, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Pregúntame algo...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryYellow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: primaryBlue,
                      size: 18,
                    ),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient:
                  _isTyping
                      ? const LinearGradient(
                        colors: [primaryBlue, darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                      ),
              borderRadius: BorderRadius.circular(24),
              boxShadow:
                  _isTyping
                      ? [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _isTyping ? _sendMessage : null,
                child: Icon(
                  Icons.send,
                  color: _isTyping ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

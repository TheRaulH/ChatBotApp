import 'package:chatbotapp/features/chat/screens/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _queryController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isCreatingChat = false;
  String _loadingMessage = '';
  

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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  

  Future<void> _createAndNavigateToChat() async {
    if (!_formKey.currentState!.validate()) return;

    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isCreatingChat = true;
      _loadingMessage = 'Creando chat...';
    });

    try {
      // Fase 1: Crear el chat
      final chatId = await ref
          .read(chatsListProvider.notifier)
          .createNewChat(query);

      if (!mounted) return;

      // Fase 2: Enviar mensaje inicial
      setState(() {
        _loadingMessage = 'Enviando mensaje...';
      });

      print('mensaje: $query');

      await ref.read(chatProvider(chatId).notifier).sendMessage(chatId, query);

      print('Mensaje enviado al chat $chatId: $query');

      if (!mounted) return;

      // Fase 3: Redirigir
      setState(() {
        _loadingMessage = 'Redirigiendo...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go('/chat/$chatId');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCreatingChat = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al crear el chat: ${error.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _createAndNavigateToChat,
          ),
        ),
      );
    }
  }


  // Versión alternativa con más animaciones
  Widget _buildAdvancedConversationButton() {
    return AnimatedScale(
      scale: _isCreatingChat ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreatingChat ? null : _createAndNavigateToChat,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, darkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            width: double.infinity,
            height: 56,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child:
                    _isCreatingChat
                        ? _buildAdvancedLoadingContent()
                        : _buildAdvancedNormalContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAdvancedNormalContent() {
    return Row(
      key: const ValueKey('advanced_normal'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(            
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Iniciar Conversación',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedLoadingContent() {
    return Row(
      key: const ValueKey('advanced_loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loadingMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1500),
                width: _getProgressWidth(),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getProgressWidth() {
    switch (_loadingMessage) {
      case 'Creando chat...':
        return 25.0;
      case 'Enviando mensaje...':
        return 60.0;
      case 'Redirigiendo...':
        return 80.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 480;

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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology, color: darkBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'CoddyKIA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder:
              (context) => Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : (isTablet ? 40 : 24),
                vertical: 24,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header con animación
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            // Icono principal con gradiente
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryYellow, accentYellow],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryYellow.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology,
                                size: 80,
                                color: darkBlue,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Título principal
                            Text(
                              '¡Hola! Soy CoddyKIA',
                              style: TextStyle(
                                fontSize: isMobile ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Subtítulo
                            Text(
                              'Tu asistente inteligente para responder todas tus preguntas',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),

                      // Formulario mejorado
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 600 : double.infinity,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Campo de texto mejorado
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _queryController,
                                  maxLines: isMobile ? 3 : 4,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: darkBlue,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: '¿En qué puedo ayudarte hoy?',
                                    labelStyle: TextStyle(
                                      color: primaryBlue.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText:
                                        'Ej: Explícame cómo funciona la inteligencia artificial',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: primaryBlue.withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(
                                        color: primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(20),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(12),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryYellow.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline,
                                        color: primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.trim().isEmpty ?? true
                                              ? 'Por favor, ingresa tu consulta'
                                              : null,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Botón principal mejorado
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryBlue, darkBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _buildAdvancedConversationButton()
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Características destacadas
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 600 : double.infinity,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.flash_on,
                                'Respuestas\nRápidas',
                                isMobile,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.library_books,
                                'Base de\nConocimiento',
                                isMobile,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.support_agent,
                                'Asistencia\n24/7',
                                isMobile,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String text, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: isMobile ? 24 : 28),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: darkBlue,
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

 
  static const Color primaryBlue = Color.fromARGB(255, 0, 3, 173);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color.fromARGB(255, 10, 22, 80); 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(chatsListProvider);

    return Drawer(
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [lightBlue, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header mejorado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryYellow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: darkBlue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CoddyKIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tu asistente inteligente',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Navegación principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDrawerItem(context, Icons.home_rounded, 'Inicio', () {
                    context.go('/');
                    Navigator.pop(context);
                  }),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    Icons.chat_rounded,
                    'Todos Mis Chats',
                    () {
                      context.go('/chats');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Sección de chats recientes
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chats Recientes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Lista de chats
            Expanded(
              child: chatsState.when(
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                error:
                    (error, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error al cargar chats',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                data:
                    (chats) =>
                        chats.isEmpty
                            ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: lightBlue.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: primaryBlue,
                                      size: 48,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Aún no tienes chats',
                                      style: TextStyle(
                                        color: darkBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Inicia una conversación desde el inicio',
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: chats.length,
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryYellow.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.chat,
                                        color: primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      chat.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: darkBlue,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: primaryBlue,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.go('/chat/${chat.id}');
                                    },
                                  ),
                                );
                              },
                            ),
              ),
            ),

            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDrawerItem(
                context,
                Icons.info_rounded,
                'Información',
                () {
                  context.go('/vectors');
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: darkBlue),
        ),
        trailing: const Icon(Icons.chevron_right, color: primaryBlue),
        onTap: onTap,
      ),
    );
  }
}
 
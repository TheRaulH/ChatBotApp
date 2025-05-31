import 'package:chatbotapp/features/chat/screens/chat_list_screen.dart';
import 'package:chatbotapp/features/chat/screens/chat_screen.dart';
import 'package:chatbotapp/features/chat/screens/home_screen.dart';
import 'package:chatbotapp/features/chat/screens/main_drawer_navigation.dart'; 
import 'package:chatbotapp/features/vectors/screens/vector_screen.dart';
import 'package:chatbotapp/features/vectors/screens/vector_search_screen.dart';
import 'package:go_router/go_router.dart'; 

final router = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen(),), 
           GoRoute(path: '/chat', builder: (context, state) => const MainDrawerNavigation(),),
           GoRoute(path: '/vectors', builder: (context, state) => VectorScreen(),),
    GoRoute(
      path: '/search',
      builder: (context, state) => const VectorSearchScreen(),
    ),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) {
        final chatId = int.parse(state.pathParameters['chatId']!);
        return ChatScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ChatListScreen(),
    ),
  ],

);

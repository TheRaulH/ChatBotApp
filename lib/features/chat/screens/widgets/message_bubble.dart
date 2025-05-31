import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:chatbotapp/features/chat/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showCopyButton;

  const MessageBubble({
    super.key,
    required this.message,
    this.showCopyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserMessage = message.isUserMessage;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isUserMessage
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCopyButton && !isUserMessage)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.content_copy, size: 18),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: message.content),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copiado al portapapeles'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  showCopyButton && !isUserMessage ? 4 : 12,
                ),
                child:
                    isUserMessage
                        ? Text(
                          message.content,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                        : MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            code: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              backgroundColor: theme.colorScheme.surfaceBright,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            codeblockPadding: const EdgeInsets.all(12),
                            codeblockDecoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            h1: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            blockquote: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              border: Border(
                                left: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                            listBullet: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            tableBorder: TableBorder.all(
                              color: theme.colorScheme.outline,
                            ),
                            tableHead: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                            tableBody: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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

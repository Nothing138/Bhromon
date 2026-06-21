// screens/chat/emoji_picker_sheet.dart
import 'package:flutter/material.dart';

class EmojiPickerSheet extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerSheet({
    super.key,
    required this.onEmojiSelected,
  });

  static const List<String> emojis = [
    // Smileys
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '😉', '😊', '😇', '🙂', '🙃', '😌', '😍', '🥰',
    '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
    '🤪', '😌', '😑', '😔', '😌', '❤️', '🧡', '💛',
    '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '💕',
    // Hand gestures
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏',
    '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👍', '👎',
    '☝️', '👆', '👇', '👈', '👉', '👊', '👏', '🙌',
    '👐', '🤲', '🤝', '🤜', '🤛', '✊', '💪', '🦾',
    // Love/Heart
    '💑', '👨‍❤️‍👨', '💏', '❣️', '💞', '💓', '💗', '💖',
    '💘', '💝', '💟', '💌', '💠', '💢', '💯', '🔥',
    // Celebration
    '🎉', '🎊', '🎈', '🎀', '🎁', '🎂', '🍰', '🎇',
    '🎆', '✨', '⭐', '🌟', '🌠', '🌌', '🎃', '👻',
    // Travel
    '✈️', '🚀', '🚁', '🚂', '🚃', '🚄', '🚅', '🚆',
    '🚇', '🚈', '🚉', '🚊', '🚝', '🚞', '🚋', '🚌',
    '🚎', '🚐', '🚑', '🚒', '🚓', '🚔', '🚕', '🚖',
    '🚗', '🚘', '🚙', '🚚', '🚛', '🚜', '🏎️', '🏍️',
    // Nature
    '🌲', '🌳', '🌴', '🌵', '🌾', '🌿', '☘️', '🍀',
    '🎍', '🎎', '🎏', '🎐', '🌍', '🌎', '🌏', '💧',
    '💦', '☔', '⛈️', '🌤️', '🌥️', '☁️', '🌦️', '🌧️',
    // Food
    '🍕', '🍔', '🍟', '🌭', '🍿', '🥓', '🍗', '🍖',
    '🌮', '🌯', '🥙', '🥪', '🍞', '🥐', '🥖', '🥨',
    '🧀', '🥚', '🍳', '🧈', '🥞', '🥟', '🥠', '🥮',
    '🍢', '🍣', '🍱', '🍛', '🍝', '🍜', '🍲', '🍥',
    // Drinks
    '🍶', '🍾', '🍷', '🍸', '🍹', '🍺', '🍻', '🥂',
    '🥃', '🥤', '🧋', '☕', '🍵', '🧉', '🚭',
    // Sport
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
    '🥏', '🎳', '🏓', '🏸', '🏒', '🏑', '🥅', '⛳',
    '⛸️', '🎣', '🎽', '🎿', '⛷️', '🏂', '🪂', '🏋️',
    // Music
    '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸',
    '🎻', '🎲', '♠️', '♥️', '♦️', '♣️', '🎯', '🎮',
    // Symbols
    '👍', '❤️', '🔥', '💯', '⭐', '🎉', '✔️', '👌',
    '💪', '🚀', '😍', '👏', '💕', '😂', '✨', '👊',
  ];

  static const List<String> categories = [
    '😀',
    '👋',
    '❤️',
    '🎉',
    '✈️',
    '🌲',
    '🍕',
    '🍷',
    '⚽',
    '🎤',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: emojis.length,
              itemBuilder: (_, index) => GestureDetector(
                onTap: () => onEmojiSelected(emojis[index]),
                child: Text(
                  emojis[index],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum MessageChannel { sms, whatsapp }

class ChannelSelectorWidget extends StatelessWidget {
  final MessageChannel? selectedChannel;
  final ValueChanged<MessageChannel> onChannelSelected;

  const ChannelSelectorWidget({
    super.key,
    required this.selectedChannel,
    required this.onChannelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gönderim Kanalı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildChannelOption(
                channel: MessageChannel.sms,
                icon: Icons.sms_outlined,
                label: 'SMS',
                isSelected: selectedChannel == MessageChannel.sms,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChannelOption(
                channel: MessageChannel.whatsapp,
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                isSelected: selectedChannel == MessageChannel.whatsapp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelOption({
    required MessageChannel channel,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onChannelSelected(channel),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

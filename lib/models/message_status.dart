enum MessageStatus { sent, delivered, read }

String messageStatusToString(MessageStatus s) {
  switch (s) {
    case MessageStatus.sent:
      return 'sent';
    case MessageStatus.delivered:
      return 'delivered';
    case MessageStatus.read:
      return 'read';
  }
}

MessageStatus messageStatusFromString(String status) {
  switch (status) {
    case 'delivered':
      return MessageStatus.delivered;
    case 'read':
      return MessageStatus.read;
    default:
      return MessageStatus.sent;
  }
}

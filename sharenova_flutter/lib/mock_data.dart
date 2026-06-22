// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
class TransferItem {
  final int id;
  final String name;
  final String type;
  final String size;
  final String time;
  final String status;
  final String? expires;
  final bool encrypted;

  TransferItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.time,
    required this.status,
    this.expires,
    required this.encrypted,
  });
}

class AppItem {
  final int id;
  final String name;
  final String size;
  final String icon;

  AppItem({
    required this.id,
    required this.name,
    required this.size,
    required this.icon,
  });
}

class ContactItem {
  final String id;
  final String name;
  final String phone;
  final String initials;
  final int bgColor;
  final int textColor;
  final String status;
  final String lastMsg;
  final int unread;

  ContactItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
    required this.bgColor,
    required this.textColor,
    required this.status,
    required this.lastMsg,
    required this.unread,
  });
}

class ChatMessage {
  final int id;
  final String sender;
  final String? text;
  final String time;
  final bool isMine;
  final String type;
  final String? fileName;
  final String? fileType;
  final String? size;
  final String? status;

  ChatMessage({
    required this.id,
    required this.sender,
    this.text,
    required this.time,
    required this.isMine,
    required this.type,
    this.fileName,
    this.fileType,
    this.size,
    this.status,
  });
}

class DiscoverNews {
  final int id;
  final String title;
  final String source;
  final String time;

  DiscoverNews({
    required this.id,
    required this.title,
    required this.source,
    required this.time,
  });
}

class MockData {
  static final List<TransferItem> recentTransfers = [
    TransferItem(id: 1, name: "Project_Presentation.pdf", type: "doc", size: "12.4 MB", time: "1 hour ago", status: "completed", encrypted: true),
    TransferItem(id: 2, name: "Confidential_Specs.docx", type: "doc", size: "2.1 MB", time: "3 hours ago", status: "active", expires: "24h", encrypted: true),
    TransferItem(id: 3, name: "Vacation_Video.mp4", type: "video", size: "1.2 GB", time: "Yesterday", status: "completed", encrypted: true),
  ];

  static final List<AppItem> mockApps = [
    AppItem(id: 1, name: "WhatsApp", size: "85 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=wa&backgroundColor=25D366"),
    AppItem(id: 2, name: "Instagram", size: "120 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=ig&backgroundColor=E1306C"),
    AppItem(id: 3, name: "Signal", size: "45 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=sig&backgroundColor=3b82f6"),
    AppItem(id: 4, name: "Spotify", size: "45 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=sp&backgroundColor=1DB954"),
  ];

  static final List<ContactItem> mockContacts = [
    ContactItem(id: "c1", name: "Sarah Jenkins", phone: "+1 555-0123", initials: "SJ", bgColor: 0xFFF3E8FF, textColor: 0xFF9333EA, status: "Nearby (Wi-Fi Direct)", lastMsg: "Can you send the 4K video?", unread: 2),
    ContactItem(id: "c2", name: "David Chen", phone: "+1 555-0198", initials: "DC", bgColor: 0xFFDBEAFE, textColor: 0xFF2563EB, status: "Offline", lastMsg: "Thanks for the files!", unread: 0),
    ContactItem(id: "c3", name: "Mom", phone: "+1 555-0001", initials: "M", bgColor: 0xFFFCE7F3, textColor: 0xFFEC4899, status: "Online (Cloud Relay)", lastMsg: "Are we still on for dinner?", unread: 0),
    ContactItem(id: "c4", name: "Project Group", phone: "4 Members", initials: "PG", bgColor: 0xFFD1FAE5, textColor: 0xFF059669, status: "2 Members Nearby", lastMsg: "Alex sent a document.", unread: 5),
  ];

  static final List<ChatMessage> mockChatMessages = [
    ChatMessage(id: 1, sender: "Sarah Jenkins", text: "Hey! Did you finish editing the vacation video?", time: "10:42 AM", isMine: false, type: "text"),
    ChatMessage(id: 2, sender: "Me", text: "Yes! Just exported it in 4K.", time: "10:45 AM", isMine: true, type: "text"),
    ChatMessage(id: 3, sender: "Sarah Jenkins", text: "Awesome. Can you beam it over?", time: "10:46 AM", isMine: false, type: "text"),
    ChatMessage(id: 4, sender: "Sarah Jenkins", type: "request", fileName: "Vacation_Edit_Final.mp4", fileType: "video", time: "10:46 AM", isMine: false),
    ChatMessage(id: 5, sender: "Me", type: "transfer", fileName: "Vacation_Edit_Final.mp4", size: "1.2 GB", status: "completed", time: "10:48 AM", isMine: true),
    ChatMessage(id: 6, sender: "Sarah Jenkins", text: "Got it! Speeds were insane. 120MB/s! 🚀", time: "10:49 AM", isMine: false, type: "text"),
  ];

  static final List<DiscoverNews> mockDiscoverNews = [
    DiscoverNews(id: 1, title: "10 Tips for Faster Wi-Fi Direct Transfers", source: "TechRadar", time: "2h ago"),
    DiscoverNews(id: 2, title: "The Future of P2P Encrypted Sharing", source: "Security Weekly", time: "5h ago"),
    DiscoverNews(id: 3, title: "Top 5 Productivity Apps of 2026", source: "App Digest", time: "1d ago"),
  ];

  static final List<AppItem> mockFeaturedApps = [
    AppItem(id: 5, name: "TikTok", size: "110 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=tk&backgroundColor=000000"),
    AppItem(id: 6, name: "Netflix", size: "88 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=nf&backgroundColor=E50914"),
    AppItem(id: 7, name: "CapCut", size: "140 MB", icon: "https://api.dicebear.com/7.x/identicon/png?seed=cc&backgroundColor=111111"),
  ];
}

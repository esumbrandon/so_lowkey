import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/chat/models/message_model.dart';
import '../../features/connections/models/connection_model.dart';
import '../../features/discovery/models/profile_model.dart';
import '../../features/lounges/models/lounge_model.dart';

/// Helper to check if Supabase is properly initialized.
bool get isSupabaseConfigured {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

/// Fallback mock user for offline development.
const String mockUserId = '00000000-0000-0000-0000-000000000001';

final mockCurrentUser = User(
  id: mockUserId,
  appMetadata: {},
  userMetadata: {'alias': 'Quiet Traveler'},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
);

/// Mock Lounges
final List<LoungeModel> mockLounges = [
  LoungeModel(
    id: 'reading_nook',
    name: 'Rainy Reading Nook',
    description: 'Quiet pages turning with gentle rain on the skylight.',
    ambientAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    iconName: 'book',
  ),
  LoungeModel(
    id: 'midnight_coffee',
    name: 'Midnight Coffee',
    description: 'Soft lo-fi warmth and quiet solitude late at night.',
    ambientAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    iconName: 'coffee',
  ),
  LoungeModel(
    id: 'botanical_sanctuary',
    name: 'Botanical Sanctuary',
    description: 'Rustling leaves and gentle wind in a sunlit greenhouse.',
    ambientAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    iconName: 'plant',
  ),
  LoungeModel(
    id: 'rainy_attic',
    name: 'Rainy Attic',
    description: 'Steady rainfall on a tin roof with distant thunder.',
    ambientAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    iconName: 'rain',
  ),
  LoungeModel(
    id: 'starlit_terrace',
    name: 'Starlit Terrace',
    description: 'Calm night breeze under endless constellations.',
    ambientAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    iconName: 'stars',
  ),
];

/// Mock Lounge Presences
final Map<String, List<LoungePresenceModel>> mockPresences = {
  'reading_nook': [
    LoungePresenceModel(
      userId: 'user_luna',
      loungeId: 'reading_nook',
      statusText: 'Reading Haruki Murakami',
    ),
    LoungePresenceModel(
      userId: 'user_rowan',
      loungeId: 'reading_nook',
      statusText: 'Sipping chamomile tea',
    ),
  ],
  'midnight_coffee': [
    LoungePresenceModel(
      userId: 'user_astrid',
      loungeId: 'midnight_coffee',
      statusText: 'Sketching in charcoal',
    ),
  ],
  'botanical_sanctuary': [
    LoungePresenceModel(
      userId: 'user_theo',
      loungeId: 'botanical_sanctuary',
      statusText: 'Listening to leaves rustle',
    ),
  ],
  'rainy_attic': [
    LoungePresenceModel(
      userId: 'user_rowan',
      loungeId: 'rainy_attic',
      statusText: 'Journaling by window',
    ),
  ],
  'starlit_terrace': [
    LoungePresenceModel(
      userId: 'user_luna',
      loungeId: 'starlit_terrace',
      statusText: 'Watching the meteor shower',
    ),
  ],
};

/// Mock Aliases
final Map<String, String> mockAliases = {
  'user_luna': 'Luna Fern',
  'user_rowan': 'Rowan Moss',
  'user_astrid': 'Astrid Night',
  'user_theo': 'Theo Woods',
  'user_kai': 'Kai River',
  mockUserId: 'You (Quiet Traveler)',
};

/// All predefined interest circles users can belong to.
const List<String> kAllCircles = [
  'Tech',
  'Books',
  'Gaming',
  'Art',
  'Music',
  'Nature',
  'Film',
  'Science',
  'Food',
  'Philosophy',
];

/// Mock Discoverable Profiles — enriched with location + circles
final List<ProfileModel> mockProfiles = [
  ProfileModel(
    id: 'user_luna',
    alias: 'Luna Fern',
    avatarSeed: 'luna_warm',
    batteryStatus: 'recharging',
    replyPace: 'slow_mail',
    maxActiveChats: 2,
    sparkPrompt: 'A quiet hobby I adore:',
    sparkAnswer:
        'Binding hardcover notebooks by hand using Japanese stab binding.',
    isDiscoverable: true,
    country: 'Japan',
    region: 'Kansai',
    city: 'Kyoto',
    circles: ['Books', 'Art', 'Philosophy'],
  ),
  ProfileModel(
    id: 'user_rowan',
    alias: 'Rowan Moss',
    avatarSeed: 'rowan_calm',
    batteryStatus: 'medium',
    replyPace: 'few_days',
    maxActiveChats: 3,
    sparkPrompt: 'My ideal weekend with zero obligations looks like:',
    sparkAnswer:
        'Making pour-over coffee at 6am while the morning fog clears over the trees.',
    isDiscoverable: true,
    country: 'United Kingdom',
    region: 'Scotland',
    city: 'Edinburgh',
    circles: ['Nature', 'Books', 'Music'],
  ),
  ProfileModel(
    id: 'user_astrid',
    alias: 'Astrid Night',
    avatarSeed: 'astrid_stars',
    batteryStatus: 'full',
    replyPace: 'same_day',
    maxActiveChats: 3,
    sparkPrompt: 'An unpopular opinion I hold quietly:',
    sparkAnswer:
        'Spontaneous phone calls should require a 24-hour advance written proposal.',
    isDiscoverable: true,
    country: 'Sweden',
    region: 'Västra Götaland',
    city: 'Gothenburg',
    circles: ['Tech', 'Film', 'Art'],
  ),
  ProfileModel(
    id: 'user_theo',
    alias: 'Theo Woods',
    avatarSeed: 'theo_green',
    batteryStatus: 'low',
    replyPace: 'few_days',
    maxActiveChats: 2,
    sparkPrompt: 'A niche rabbit hole I fell down recently:',
    sparkAnswer:
        'Analog tape loop mechanics and 1970s tape delay echo chambers.',
    isDiscoverable: true,
    country: 'United States',
    region: 'Pacific Northwest',
    city: 'Portland',
    circles: ['Music', 'Tech', 'Science'],
  ),
  ProfileModel(
    id: 'user_kai',
    alias: 'Kai River',
    avatarSeed: 'kai_blue',
    batteryStatus: 'medium',
    replyPace: 'same_day',
    maxActiveChats: 3,
    sparkPrompt: 'A niche rabbit hole I fell down recently:',
    sparkAnswer: 'The history of procedurally generated worlds in 8-bit games.',
    isDiscoverable: true,
    country: 'Canada',
    region: 'British Columbia',
    city: 'Vancouver',
    circles: ['Gaming', 'Tech', 'Film'],
  ),
];

/// Mock Chat Messages for Demo Connections
final List<MessageModel> initialMockMessages = [
  MessageModel(
    id: 'm1',
    connectionId: 'demo_chat_rowan',
    senderId: 'user_rowan',
    content:
        'Hello! I saw your note about sourdough baking and quiet mornings. Thought I\'d say hi gently.',
    isGracefulExit: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  MessageModel(
    id: 'm2',
    connectionId: 'demo_chat_rowan',
    senderId: mockUserId,
    content:
        'Hi Rowan, lovely to connect. No pressure at all on reply timing—take all the time you need.',
    isGracefulExit: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  MessageModel(
    id: 'm3',
    connectionId: 'demo_chat_rowan',
    senderId: 'user_rowan',
    content:
        'Thank you, that takes away all the messaging pressure. How has your week been so far?',
    isGracefulExit: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
  ),
  MessageModel(
    id: 'm4',
    connectionId: 'demo_chat_luna',
    senderId: 'user_luna',
    content:
        'I noticed you\'re into philosophy too. Have you ever tried reading Seneca\'s letters late at night? Pure peace.',
    isGracefulExit: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

/// Mock Connections — used by the Connections inbox in offline dev mode.
final List<ConnectionModel> mockConnections = [
  // Active connection with Rowan Moss
  ConnectionModel(
    id: 'demo_chat_rowan',
    initiatorId: mockUserId,
    recipientId: 'user_rowan',
    status: 'active',
    lastInteractionAt: DateTime.now().subtract(const Duration(minutes: 45)),
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    peerAlias: 'Rowan Moss',
    peerBatteryStatus: 'medium',
    peerReplyPace: 'few_days',
    lastMessageContent:
        'Thank you, that takes away all the messaging pressure. How has your week been so far?',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 45)),
  ),
  // Active connection with Luna Fern
  ConnectionModel(
    id: 'demo_chat_luna',
    initiatorId: 'user_luna',
    recipientId: mockUserId,
    status: 'active',
    lastInteractionAt: DateTime.now().subtract(const Duration(days: 2)),
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    peerAlias: 'Luna Fern',
    peerBatteryStatus: 'recharging',
    peerReplyPace: 'slow_mail',
    lastMessageContent:
        'I noticed you\'re into philosophy too. Have you ever tried reading Seneca\'s letters late at night?',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  // Pending incoming request from Astrid Night
  ConnectionModel(
    id: 'pending_astrid',
    initiatorId: 'user_astrid',
    recipientId: mockUserId,
    status: 'pending',
    lastInteractionAt: DateTime.now().subtract(const Duration(hours: 12)),
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    peerAlias: 'Astrid Night',
    peerBatteryStatus: 'full',
    peerReplyPace: 'same_day',
    lastMessageContent: null,
    lastMessageAt: null,
  ),
  // Pending outgoing request to Theo Woods
  ConnectionModel(
    id: 'pending_theo',
    initiatorId: mockUserId,
    recipientId: 'user_theo',
    status: 'pending',
    lastInteractionAt: DateTime.now().subtract(const Duration(hours: 6)),
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    peerAlias: 'Theo Woods',
    peerBatteryStatus: 'low',
    peerReplyPace: 'few_days',
    lastMessageContent: null,
    lastMessageAt: null,
  ),
];

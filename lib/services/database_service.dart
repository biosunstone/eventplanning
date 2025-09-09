import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'event_planning.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        location TEXT,
        category TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'planning',
        organizerId TEXT NOT NULL,
        guestIds TEXT,
        budget REAL DEFAULT 0.0,
        images TEXT,
        customFields TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guests(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        rsvpStatus TEXT NOT NULL DEFAULT 'pending',
        dietaryRestrictions TEXT,
        plusOnes INTEGER DEFAULT 0,
        notes TEXT,
        invitedAt TEXT NOT NULL,
        respondedAt TEXT,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        assignedTo TEXT,
        priority TEXT NOT NULL DEFAULT 'medium',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        receipt TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vendors(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        contact TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        website TEXT,
        rating REAL DEFAULT 0.0,
        notes TEXT,
        isBooked INTEGER NOT NULL DEFAULT 0,
        price REAL DEFAULT 0.0,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_events_organizer ON events(organizerId)
    ''');

    await db.execute('''
      CREATE INDEX idx_guests_event ON guests(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_event ON tasks(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_expenses_event ON expenses(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_vendors_event ON vendors(eventId)
    ''');

    // Attendee Profiles Table
    await db.execute('''
      CREATE TABLE attendee_profiles(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        profileImage TEXT,
        company TEXT,
        jobTitle TEXT,
        department TEXT,
        professionalLevel TEXT,
        industry TEXT,
        location TEXT,
        city TEXT,
        country TEXT,
        bio TEXT,
        interests TEXT,
        skills TEXT,
        linkedInUrl TEXT,
        twitterHandle TEXT,
        website TEXT,
        isPublic INTEGER DEFAULT 1,
        allowNetworking INTEGER DEFAULT 1,
        allowMessages INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Sessions Table
    await db.execute('''
      CREATE TABLE sessions(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        format TEXT NOT NULL DEFAULT 'inPerson',
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT,
        room TEXT,
        virtualLink TEXT,
        maxAttendees INTEGER DEFAULT 0,
        speakerIds TEXT,
        attendeeIds TEXT,
        tags TEXT,
        requiresRegistration INTEGER DEFAULT 0,
        isRecorded INTEGER DEFAULT 0,
        recordingUrl TEXT,
        materialsUrl TEXT,
        customFields TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    // Polls Table
    await db.execute('''
      CREATE TABLE polls(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        sessionId TEXT,
        question TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        options TEXT,
        allowMultipleAnswers INTEGER DEFAULT 0,
        isAnonymous INTEGER DEFAULT 1,
        showResults INTEGER DEFAULT 1,
        startTime TEXT,
        endTime TEXT,
        createdBy TEXT NOT NULL,
        totalVotes INTEGER DEFAULT 0,
        voterIds TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Poll Votes Table
    await db.execute('''
      CREATE TABLE poll_votes(
        id TEXT PRIMARY KEY,
        pollId TEXT NOT NULL,
        optionId TEXT NOT NULL,
        userId TEXT NOT NULL,
        votedAt TEXT NOT NULL,
        FOREIGN KEY (pollId) REFERENCES polls (id) ON DELETE CASCADE
      )
    ''');

    // Q&A Questions Table
    await db.execute('''
      CREATE TABLE qa_questions(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        sessionId TEXT,
        question TEXT NOT NULL,
        answer TEXT,
        askedBy TEXT NOT NULL,
        answeredBy TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        upvotes INTEGER DEFAULT 0,
        upvoterIds TEXT,
        isAnonymous INTEGER DEFAULT 0,
        askedAt TEXT NOT NULL,
        answeredAt TEXT,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Conversations Table
    await db.execute('''
      CREATE TABLE conversations(
        id TEXT PRIMARY KEY,
        eventId TEXT,
        sessionId TEXT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        participantIds TEXT NOT NULL,
        createdBy TEXT,
        unreadCount INTEGER DEFAULT 0,
        isMuted INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Messages Table
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        recipientId TEXT,
        content TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'text',
        status TEXT NOT NULL DEFAULT 'sent',
        fileUrl TEXT,
        fileName TEXT,
        thumbnailUrl TEXT,
        metadata TEXT,
        sentAt TEXT NOT NULL,
        deliveredAt TEXT,
        readAt TEXT,
        isEdited INTEGER DEFAULT 0,
        editedAt TEXT,
        FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Community Posts Table
    await db.execute('''
      CREATE TABLE community_posts(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        authorId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        tags TEXT,
        imageUrls TEXT,
        location TEXT,
        eventDate TEXT,
        likesCount INTEGER DEFAULT 0,
        likedByIds TEXT,
        commentsCount INTEGER DEFAULT 0,
        isPinned INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    // Check-ins Table
    await db.execute('''
      CREATE TABLE check_ins(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        sessionId TEXT,
        boothId TEXT,
        attendeeId TEXT NOT NULL,
        type TEXT NOT NULL,
        checkInTime TEXT NOT NULL,
        checkOutTime TEXT,
        location TEXT,
        metadata TEXT,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Photo Gallery Table
    await db.execute('''
      CREATE TABLE photo_gallery(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        sessionId TEXT,
        uploadedBy TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileUrl TEXT NOT NULL,
        thumbnailUrl TEXT,
        caption TEXT,
        tags TEXT,
        isPublic INTEGER DEFAULT 1,
        likesCount INTEGER DEFAULT 0,
        likedByIds TEXT,
        uploadedAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Announcements Table
    await db.execute('''
      CREATE TABLE announcements(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        sessionId TEXT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        priority TEXT NOT NULL DEFAULT 'normal',
        senderId TEXT NOT NULL,
        targetAudience TEXT,
        isScheduled INTEGER DEFAULT 0,
        scheduledFor TEXT,
        sentAt TEXT,
        expiresAt TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create additional indexes
    await db.execute('''
      CREATE INDEX idx_attendee_profiles_user ON attendee_profiles(userId)
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_event ON sessions(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_polls_event ON polls(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_qa_questions_event ON qa_questions(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_conversations_participants ON conversations(participantIds)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_conversation ON messages(conversationId)
    ''');

    await db.execute('''
      CREATE INDEX idx_community_posts_event ON community_posts(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_check_ins_event ON check_ins(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_check_ins_attendee ON check_ins(attendeeId)
    ''');

    await db.execute('''
      CREATE INDEX idx_photo_gallery_event ON photo_gallery(eventId)
    ''');

    await db.execute('''
      CREATE INDEX idx_announcements_event ON announcements(eventId)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('events');
      await txn.delete('guests');
      await txn.delete('tasks');
      await txn.delete('expenses');
      await txn.delete('vendors');
    });
  }
}
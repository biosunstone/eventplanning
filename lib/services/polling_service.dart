import '../models/poll.dart';
import '../models/qa_question.dart';
import 'database_service.dart';

class PollingService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Poll>> getEventPolls(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'polls',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Poll.fromJson(maps[i]);
    });
  }

  Future<List<Poll>> getSessionPolls(String sessionId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'polls',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Poll.fromJson(maps[i]);
    });
  }

  Future<Poll> createPoll(Poll poll) async {
    final db = await _databaseService.database;
    final pollWithId = poll.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    
    await db.insert('polls', pollWithId.toJson());
    return pollWithId;
  }

  Future<void> updatePoll(Poll poll) async {
    final db = await _databaseService.database;
    await db.update(
      'polls',
      poll.toJson(),
      where: 'id = ?',
      whereArgs: [poll.id],
    );
  }

  Future<void> deletePoll(String pollId) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete(
        'poll_votes',
        where: 'pollId = ?',
        whereArgs: [pollId],
      );
      await txn.delete(
        'polls',
        where: 'id = ?',
        whereArgs: [pollId],
      );
    });
  }

  Future<void> activatePoll(String pollId) async {
    final db = await _databaseService.database;
    await db.update(
      'polls',
      {'status': PollStatus.active.toString().split('.').last},
      where: 'id = ?',
      whereArgs: [pollId],
    );
  }

  Future<void> closePoll(String pollId) async {
    final db = await _databaseService.database;
    await db.update(
      'polls',
      {'status': PollStatus.closed.toString().split('.').last},
      where: 'id = ?',
      whereArgs: [pollId],
    );
  }

  Future<bool> submitVote(String pollId, String userId, List<String> optionIds) async {
    final db = await _databaseService.database;
    
    final poll = await getPollById(pollId);
    if (poll == null || !poll.canVote) {
      return false;
    }

    if (poll.voterIds.contains(userId)) {
      return false;
    }

    await db.transaction((txn) async {
      for (final optionId in optionIds) {
        await txn.insert('poll_votes', {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'pollId': pollId,
          'optionId': optionId,
          'userId': userId,
          'votedAt': DateTime.now().toIso8601String(),
        });
      }

      final updatedVoterIds = [...poll.voterIds, userId];
      await txn.update(
        'polls',
        {
          'voterIds': updatedVoterIds.join(','),
          'totalVotes': poll.totalVotes + 1,
        },
        where: 'id = ?',
        whereArgs: [pollId],
      );
    });

    return true;
  }

  Future<Poll?> getPollById(String pollId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'polls',
      where: 'id = ?',
      whereArgs: [pollId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Poll.fromJson(maps.first);
    }
    return null;
  }

  Future<Map<String, int>> getPollResults(String pollId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'poll_votes',
      columns: ['optionId', 'COUNT(*) as votes'],
      where: 'pollId = ?',
      whereArgs: [pollId],
      groupBy: 'optionId',
    );

    final results = <String, int>{};
    for (final map in maps) {
      results[map['optionId']] = map['votes'];
    }
    return results;
  }

  Future<bool> hasUserVoted(String pollId, String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'poll_votes',
      where: 'pollId = ? AND userId = ?',
      whereArgs: [pollId, userId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Q&A Methods

  Future<List<QAQuestion>> getEventQuestions(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qa_questions',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'upvotes DESC, askedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return QAQuestion.fromJson(maps[i]);
    });
  }

  Future<List<QAQuestion>> getSessionQuestions(String sessionId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qa_questions',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'upvotes DESC, askedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return QAQuestion.fromJson(maps[i]);
    });
  }

  Future<QAQuestion> submitQuestion({
    required String eventId,
    String? sessionId,
    required String question,
    required String askedBy,
    bool isAnonymous = false,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    
    final qaQuestion = QAQuestion(
      id: now.millisecondsSinceEpoch.toString(),
      eventId: eventId,
      sessionId: sessionId,
      question: question,
      askedBy: askedBy,
      isAnonymous: isAnonymous,
      askedAt: now,
      updatedAt: now,
    );

    await db.insert('qa_questions', qaQuestion.toJson());
    return qaQuestion;
  }

  Future<void> upvoteQuestion(String questionId, String userId) async {
    final db = await _databaseService.database;
    
    final question = await getQuestionById(questionId);
    if (question == null || question.upvoterIds.contains(userId)) {
      return;
    }

    final updatedUpvoters = [...question.upvoterIds, userId];
    await db.update(
      'qa_questions',
      {
        'upvotes': question.upvotes + 1,
        'upvoterIds': updatedUpvoters.join(','),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> removeUpvote(String questionId, String userId) async {
    final db = await _databaseService.database;
    
    final question = await getQuestionById(questionId);
    if (question == null || !question.upvoterIds.contains(userId)) {
      return;
    }

    final updatedUpvoters = question.upvoterIds.where((id) => id != userId).toList();
    await db.update(
      'qa_questions',
      {
        'upvotes': question.upvotes - 1,
        'upvoterIds': updatedUpvoters.join(','),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> answerQuestion(String questionId, String answer, String answeredBy) async {
    final db = await _databaseService.database;
    await db.update(
      'qa_questions',
      {
        'answer': answer,
        'answeredBy': answeredBy,
        'status': QuestionStatus.answered.toString().split('.').last,
        'answeredAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> featureQuestion(String questionId) async {
    final db = await _databaseService.database;
    await db.update(
      'qa_questions',
      {
        'status': QuestionStatus.featured.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> dismissQuestion(String questionId) async {
    final db = await _databaseService.database;
    await db.update(
      'qa_questions',
      {
        'status': QuestionStatus.dismissed.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<QAQuestion?> getQuestionById(String questionId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qa_questions',
      where: 'id = ?',
      whereArgs: [questionId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return QAQuestion.fromJson(maps.first);
    }
    return null;
  }

  Future<void> deleteQuestion(String questionId) async {
    final db = await _databaseService.database;
    await db.delete(
      'qa_questions',
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<List<QAQuestion>> searchQuestions(String eventId, String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qa_questions',
      where: 'eventId = ? AND (question LIKE ? OR answer LIKE ?)',
      whereArgs: [eventId, '%$query%', '%$query%'],
      orderBy: 'upvotes DESC, askedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return QAQuestion.fromJson(maps[i]);
    });
  }
}
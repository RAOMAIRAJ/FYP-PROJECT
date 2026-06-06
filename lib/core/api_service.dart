import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static String get baseUrl {
    // Live Cloud Backend (Railway)
    return 'https://web-production-a0cd.up.railway.app/api/v1';
  }

  static String get wsUrl {
    return baseUrl.replaceFirst('http', 'ws').replaceAll('/api/v1', '/api/v1');
  }

  static String get nlpBaseUrl {
    // Live HuggingFace Spaces Deployment URL
    return 'https://raomairaj12-qanoon-buddy-nlp-1.hf.space';
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
    headers: {'Content-Type': 'application/json'},
  ));

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            const storage = FlutterSecureStorage();
            final token = await storage.read(key: 'auth_token');
            if (token != null && !options.headers.containsKey('Authorization')) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeDocument(List<int> bytes, String filename, String token) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    
    final response = await _dio.post(
      '/ai-chat/analyze-document',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> analyzeRisk(String description, String token) async {
    final response = await _dio.post(
      '/ai-chat/analyze-risk',
      data: {'description': description},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> generateFir(String incidentDetails, String token) async {
    final response = await _dio.post(
      '/ai-chat/generate-fir',
      data: {'incident_details': incidentDetails},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> calculateBail(String offenseDescription, String token) async {
    final response = await _dio.post(
      '/ai-chat/calculate-bail',
      data: {'offense_description': offenseDescription},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getComplaints(String token) async {
    final response = await _dio.get('/admin/complaints', queryParameters: {'token': token});
    return response.data;
  }

  Future<List<dynamic>> getTickets(String token) async {
    final response = await _dio.get('/admin/tickets', queryParameters: {'token': token});
    return response.data;
  }

  Future<void> resolveComplaint(String complaintId, String token, String responseText) async {
    await _dio.post('/admin/complaints/$complaintId/resolve', 
      queryParameters: {'token': token},
      data: {'response': responseText}
    );
  }

  Future<Map<String, dynamic>> submitComplaint({
    required String token,
    required String category,
    required String reportedLawyer,
    required String description,
    required String date,
  }) async {
    final response = await _dio.post(
      '/support/submit-complaint',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {
        'category': category,
        'reported_lawyer': reportedLawyer,
        'description': description,
        'date': date,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> submitTicket({
    required String token,
    required String ticketType,
    required String subject,
    required String message,
    required String date,
  }) async {
    final response = await _dio.post(
      '/support/submit-ticket',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {
        'ticket_type': ticketType,
        'subject': subject,
        'message': message,
        'date': date,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMyTickets(String token) async {
    final response = await _dio.get(
      '/support/my-tickets',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> replyMyTicket(String ticketId, String token, String message) async {
    final response = await _dio.post(
      '/support/tickets/$ticketId/reply',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'message': message},
    );
    return response.data;
  }


  Future<void> replyTicket(String ticketId, String token, String replyText, {bool resolve = false}) async {
    await _dio.post('/admin/tickets/$ticketId/reply', 
      queryParameters: {'token': token},
      data: {'reply': replyText, 'resolve': resolve}
    );
  }

  // ── AI Tools ──────────────────────────────────────────────

  Future<Map<String, dynamic>> chatWithSupportAi(List<Map<String, String>> chatHistory, String userMessage) async {
    final response = await _dio.post('/ai-tools/support-chatbot', data: {
      'chat_history': chatHistory,
      'user_message': userMessage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> generateComplaint({
    required String type,
    required String language,
    required String details,
  }) async {
    final response = await _dio.post(
      '/ai-tools/generate-complaint',
      data: {
        'type': type,
        'language': language,
        'details': details,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getDepartmentGuide(String issue) async {
    final response = await _dio.post('/ai-tools/department-guide', data: {'issue_description': issue});
    return response.data;
  }

  Future<Map<String, dynamic>> getAiRouteAdvice(String startLocation, String destination, String token) async {
    final response = await _dio.post(
      '/karachi/safe-route',
      data: {
        'start_location': startLocation,
        'destination': destination,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> generateMagicForm({
    required String templateType,
    required String description,
    required String token,
  }) async {
    final response = await _dio.post(
      '/ai-chat/ai-form/extract',
      data: {
        'template_type': templateType,
        'description': description,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> generateCaseStrategy(String querySummary, String token) async {
    final response = await _dio.post(
      '/ai-chat/strategy',
      data: {'query_summary': querySummary},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> generateCplcComplaint(String voiceText, String token) async {
    final response = await _dio.post(
      '/ai-chat/generate-cplc-complaint',
      data: {'voice_text': voiceText},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String city,
    String? fcmToken,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'email':     email,
      'password':  password,
      'city':      city,
      'fcm_token': fcmToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email':    email,
      'password': password,
      'fcm_token': fcmToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await _dio.get('/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> socialLogin({
    required String idToken,
    String? fcmToken,
  }) async {
    final response = await _dio.post('/auth/firebase-login', data: {
      'id_token': idToken,
      'fcm_token': fcmToken,
    });
    return response.data;
  }

  Future<void> updateFcmToken(String token, String fcmToken) async {
    await _dio.patch(
      '/auth/fcm-token',
      data: {'fcm_token': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> updateRadarAlertArea(String token, String? area) async {
    await _dio.patch(
      '/auth/radar-alert-area',
      data: {'radar_alert_area': area},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> clearFcmToken(String token) async {
    await _dio.post(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> sendOtp(String email) async {
    await _dio.post('/auth/send-otp', data: {'email': email});
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _dio.post('/auth/verify-otp', data: {
      'email': email,
      'otp'  : otp,
    });
  }

  // ── Lawyers ───────────────────────────────────────────────

  Future<List<dynamic>> getLawyers({
    String? specialization,
    String? city,
  }) async {
    final response = await _dio.get('/lawyers', queryParameters: {
      if (specialization != null) 'specialization': specialization,
      if (city != null) 'city': city,
    });
    return response.data;
  }

  Future<List<dynamic>> getLawyersFiltered({
    String? specialization,
    String? city,
    int? maxBudget,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get('/lawyers', queryParameters: {
      if (specialization != null && specialization != 'All' && specialization != 'all')
        'specialization': specialization,
      if (city != null && city != 'All Cities' && city != 'all')
        'city': city,
      if (maxBudget != null) 'max_fee': maxBudget,
      if (sortBy != null) 'sort_by': sortBy,
      'page': page,
      'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> matchLawyer(String description, String token) async {
    final response = await _dio.post(
      '/ai-chat/match-lawyer',
      data: {'description': description},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> bookConsultation({
  required String lawyerId,
  required String querySummary,
  required String category,
  required String meetingType,
  required String token,
  String? notes,
  String? scheduledAt,
}) async {
  final response = await _dio.post(
    '/consultations?token=$token',
    data: {
      'lawyer_id'    : lawyerId,
      'query_summary': querySummary,
      'category'     : category,
      'meeting_type' : meetingType,
      if (notes != null) 'notes': notes,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
    },
  );
  return response.data;
}

Future<Map<String, dynamic>> registerLawyer({
  required String fullName,
  required String email,
  required String password,
  required String phone,
  required String city,
  required String barCouncilNumber,
  required String cnic,
  required String specialization,
  required double consultationFee,
  required int    yearsExperience,
  required String bio,
  required bool   availableOnline,
  required bool   availableInPerson,
}) async {
  final response = await _dio.post('/auth/lawyer/register', data: {
    'full_name'          : fullName,
    'email'              : email,
    'password'           : password,
    'phone'              : phone,
    'city'               : city,
    'bar_council_number' : barCouncilNumber,
    'cnic'               : cnic,
    'specialization'     : specialization,
    'consultation_fee'   : consultationFee,
    'years_experience'   : yearsExperience,
    'bio'                : bio,
    'available_online'   : availableOnline,
    'available_in_person': availableInPerson,
  });
  return response.data;
}

Future<List<dynamic>> getMyConsultations(String token, {int skip = 0, int limit = 10}) async {
  final response = await _dio.get('/consultations/my', queryParameters: {
    'token': token,
    'skip': skip,
    'limit': limit,
  });
  return response.data;
}

// ── Admin ─────────────────────────────────────────────────────

Future<Map<String, dynamic>> getAdminStats(String token) async {
  final response = await _dio.get('/admin/stats', queryParameters: {'token': token});
  return response.data;
}

Future<List<dynamic>> getPendingLawyers(String token) async {
  final response = await _dio.get('/admin/lawyers/pending', queryParameters: {'token': token});
  return response.data;
}

Future<List<dynamic>> getAllUsers(String token) async {
  final response = await _dio.get('/admin/users', queryParameters: {'token': token});
  return response.data;
}

Future<void> approveLawyer(String lawyerId, String token) async {
  await _dio.patch('/admin/lawyers/$lawyerId/approve', queryParameters: {'token': token});
}

Future<void> rejectLawyer(String lawyerId, String token) async {
  await _dio.patch(
    '/admin/lawyers/$lawyerId/reject',
    queryParameters: {'token': token},
  );
}

Future<void> banUser(String userId, String token, {String? reason}) async {
  await _dio.delete('/admin/users/$userId', queryParameters: {
    'token': token,
    if (reason != null) 'reason': reason,
  });
}

Future<List<dynamic>> getAllReviews(String token) async {
  final response = await _dio.get('/admin/reviews', queryParameters: {'token': token});
  return response.data;
}

Future<List<dynamic>> getConsultationReports(String token) async {
  final response = await _dio.get('/admin/reports', queryParameters: {'token': token});
  return response.data;
}

Future<Map<String, dynamic>> getFinanceStats(String token) async {
  final response = await _dio.get('/admin/finance', queryParameters: {'token': token});
  return response.data;
}

Future<void> mediateEscrow(String paymentId, String action, String token) async {
  await _dio.patch('/admin/escrow/$paymentId', queryParameters: {
    'token': token,
    'action': action,
  });
}

Future<void> broadcastNotification(String title, String body, String token) async {
  await _dio.post('/admin/broadcast', 
    queryParameters: {'token': token},
    data: {'title': title, 'body': body},
  );
}

Future<List<dynamic>> getAuditLogs(String token) async {
  final response = await _dio.get('/admin/audit-logs', queryParameters: {'token': token});
  return response.data;
}

Future<List<dynamic>> getRedFlags(String token) async {
  final response = await _dio.get('/admin/red-flags', queryParameters: {'token': token});
  return response.data;
}

Future<List<dynamic>> getAllRadarIncidents(String token) async {
  final response = await _dio.get('/admin/incidents', queryParameters: {'token': token});
  return response.data;
}

Future<void> verifyRadarIncident(String incidentId, String token) async {
  await _dio.patch('/admin/incidents/$incidentId/verify', queryParameters: {'token': token});
}

Future<void> deleteRadarIncident(String incidentId, String token) async {
  await _dio.delete('/admin/incidents/$incidentId', queryParameters: {'token': token});
}

// ── Lawyer Dashboard ──────────────────────────────────────

Future<Map<String, dynamic>> getLawyerProfile(String token) async {
  final response = await _dio.get(
    '/lawyer/profile',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> getLawyerStats(String token) async {
  final response = await _dio.get(
    '/lawyer/stats',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<List<dynamic>> getLawyerConsultations(String token, {int skip = 0, int limit = 10}) async {
  final response = await _dio.get(
    '/consultations/lawyer',
    queryParameters: {
      'skip': skip,
      'limit': limit,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> acceptConsultation(
    String consultationId, String token) async {
  final response = await _dio.patch(
    '/lawyer/consultations/$consultationId/accept',
    queryParameters: {'token': token},
  );
  return response.data;
}

Future<Map<String, dynamic>> completeConsultation(
    String consultationId, String token) async {
  final response = await _dio.patch(
    '/lawyer/consultations/$consultationId/complete',
    queryParameters: {'token': token},
  );
  return response.data;
}

Future<Map<String, dynamic>> cancelConsultation(
    String consultationId, String token) async {
  final response = await _dio.patch(
    '/consultations/$consultationId/cancel',
    queryParameters: {'token': token},
  );
  return response.data;
}

Future<List<dynamic>> searchLawyers(String q, {int skip = 0, int limit = 10}) async {
  final response = await _dio.get(
    '/lawyers/search',
    queryParameters: {
      'q': q,
      'skip': skip,
      'limit': limit,
    },
  );
  return response.data as List<dynamic>;
}

// ── Q&A Forum ──────────────────────────────────────────────

Future<List<dynamic>> getQuestions({String? category, int page = 1}) async {
  final response = await _dio.get(
    '/qa/questions',
    queryParameters: {
      if (category != null && category != 'All') 'category': category,
      'page': page,
    },
  );
  return response.data;
}

Future<Map<String, dynamic>> getQuestionDetails(String questionId) async {
  final response = await _dio.get('/qa/questions/$questionId');
  return response.data;
}

Future<Map<String, dynamic>> askQuestion(String token, String content, String category) async {
  final response = await _dio.post(
    '/qa/questions',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
    data: {
      'content': content,
      'category': category,
    },
  );
  return response.data;
}

Future<Map<String, dynamic>> postAnswer(String token, String questionId, String content) async {
  final response = await _dio.post(
    '/qa/questions/$questionId/answers',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
    data: {'content': content},
  );
  return response.data;
}

Future<Map<String, dynamic>> voteQuestion(String token, String questionId, String action) async {
  final response = await _dio.post(
    '/qa/questions/$questionId/vote',
    queryParameters: {'action': action},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> voteAnswer(String token, String answerId, String action) async {
  final response = await _dio.post(
    '/qa/answers/$answerId/vote',
    queryParameters: {'action': action},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

// ── Peer Chat (User <-> Lawyer) ──────────────────────────────

Future<List<dynamic>> getPeerChatContacts(String token) async {
  final response = await _dio.get(
    '/messages/contacts',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data as List<dynamic>;
}

Future<List<dynamic>> getPeerChatHistory(String peerId, String token, {int skip = 0, int limit = 20}) async {
  final response = await _dio.get(
    '/messages/history/$peerId',
    queryParameters: {
      'skip': skip,
      'limit': limit,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data as List<dynamic>;
}

// ── Reviews ───────────────────────────────────────────────────

Future<void> submitReview({
  required String consultationId,
  required int rating,
  required String token,
  String? reviewText,
}) async {
  await _dio.post(
    '/reviews/$consultationId',
    queryParameters: {
      'token'      : token,
      'rating'     : rating,
      'review_text': reviewText ?? '',
    },
  );
}

Future<bool> checkReviewed(String consultationId, String token) async {
  final response = await _dio.get(
    '/reviews/check/$consultationId',
    queryParameters: {'token': token},
  );
  return response.data['reviewed'] as bool;
}

Future<List<dynamic>> getLawyerReviews(String lawyerId, {int skip = 0, int limit = 10}) async {
  final response = await _dio.get('/reviews/lawyer/$lawyerId', queryParameters: {
    'skip': skip,
    'limit': limit,
  });
  return response.data;
}

// ── Notifications ─────────────────────────────────────────────

Future<List<dynamic>> getNotifications(String token, {int skip = 0, int limit = 20}) async {
  final response = await _dio.get(
    '/notifications',
    queryParameters: {
      'token': token,
      'skip': skip,
      'limit': limit,
    },
  );
  return response.data;
}

Future<int> getUnreadCount(String token) async {
  final response = await _dio.get(
    '/notifications/unread-count',
    queryParameters: {'token': token},
  );
  return response.data['unread_count'] as int;
}

Future<void> markAllRead(String token) async {
  await _dio.patch(
    '/notifications/mark-all-read',
    queryParameters: {'token': token},
  );
}

// ── Payments ──────────────────────────────────────────────────

Future<Map<String, dynamic>> initiatePayment({
  required String consultationId,
  required String phoneNumber,
  required double amount,
  required String token,
}) async {
  final response = await _dio.post(
    '/payments/initiate',
    queryParameters: {
      'token'          : token,
      'consultation_id': consultationId,
      'phone_number'   : phoneNumber,
      'amount'         : amount,
    },
  );
  return response.data;
}

Future<Map<String, dynamic>> getPaymentStatus(
    String consultationId, String token) async {
  final response = await _dio.get(
    '/payments/status/$consultationId',
    queryParameters: {'token': token},
  );
  return response.data;
}

// ── Password Reset ────────────────────────────────────────────

Future<void> forgotPassword(String email) async {
  await _dio.post(
    '/password/forgot-password',
    data: {'email': email},
    options: Options(
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

Future<void> resetPassword({
  required String token,
  required String newPassword,
}) async {
  await _dio.post(
    '/password/reset-password',
    data: {
      'token'       : token,
      'new_password': newPassword,
    },
  );
}

// ── Chatbot ───────────────────────────────────────────────────

Future<Map<String, dynamic>> createChatSession(String title, String token) async {
  final response = await _dio.post(
    '/ai-chat/sessions',
    data: {'title': title},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<List<dynamic>> getChatSessions(String token) async {
  final response = await _dio.get(
    '/ai-chat/sessions',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data as List<dynamic>;
}

Future<List<dynamic>> getSessionMessages(String sessionId, String token) async {
  final response = await _dio.get(
    '/ai-chat/sessions/$sessionId/messages',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data as List<dynamic>;
}

Future<Map<String, dynamic>> sendChatMessage(String sessionId, String message, String token) async {
  final response = await _dio.post(
    '/ai-chat',
    data: {'session_id': sessionId, 'message': message},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> sendVoiceQuery(String audioPath, String token, {String? sessionId}) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(audioPath, filename: 'query_${DateTime.now().millisecondsSinceEpoch}.m4a'),
    if (sessionId != null) 'session_id': sessionId,
  });
  
  final response = await _dio.post(
    '/ai-chat/voice',
    data: formData,
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
      contentType: 'multipart/form-data',
    ),
  );
  return response.data;
}

Future<void> submitFeedback(String messageId, String feedback, String token) async {
  await _dio.post(
    '/ai-chat/feedback',
    data: {'message_id': messageId, 'feedback': feedback},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

Future<Map<String, dynamic>> sendImageQuery(String imagePath, String? text, String token, {String? sessionId}) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(imagePath, filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    if (text != null && text.isNotEmpty) 'message': text,
    if (sessionId != null) 'session_id': sessionId,
  });
  
  final response = await _dio.post(
    '/ai-chat/image',
    data: formData,
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
      contentType: 'multipart/form-data',
    ),
  );
  return response.data;
}

// ── Availability (Lawyer Schedule) ─────────────────────────

Future<List<dynamic>> getLawyerAvailability(String lawyerId) async {
  final response = await _dio.get('/availability/$lawyerId');
  return response.data;
}

Future<List<dynamic>> getMyAvailability(String token) async {
  final response = await _dio.get(
    '/availability',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> addAvailabilitySlot({
  required int dayOfWeek,
  required int startHour,
  required int startMinute,
  required String token,
}) async {
  final response = await _dio.post(
    '/availability',
    data: {
      'day_of_week'  : dayOfWeek,
      'start_hour'   : startHour,
      'start_minute' : startMinute,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<void> deleteAvailabilitySlot(String slotId, String token) async {
  await _dio.delete(
    '/availability/$slotId',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

// ── Reschedule ────────────────────────────────────────────────

Future<Map<String, dynamic>> rescheduleConsultation({
  required String consultationId,
  required String newScheduledAt,
  required String token,
  String? reason,
}) async {
  final response = await _dio.patch(
    '/consultations/$consultationId/reschedule?token=$token',
    data: {
      'new_scheduled_at': newScheduledAt,
      if (reason != null) 'reason': reason,
    },
  );
  return response.data;
}

// ── Session Evidence ──────────────────────────────────────────

Future<Map<String, dynamic>> startSession(
    String consultationId, String token) async {
  final response = await _dio.patch(
    '/consultations/$consultationId/start-session',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> completeSessionWithNotes({
  required String consultationId,
  required String token,
  required String lawyerNotes,
}) async {
  final response = await _dio.patch(
    '/consultations/$consultationId/complete',
    data: {'lawyer_notes': lawyerNotes},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> getSessionEvidence(
    String consultationId, String token) async {
  final response = await _dio.get(
    '/consultations/$consultationId/evidence?token=$token',
  );
  return response.data;
}

// ── Legal News & Gazette ──────────────────────────────────────

Future<List<dynamic>> getNews({int skip = 0, int limit = 10, String type = 'legal', String? topic}) async {
  final response = await _dio.get('/news', queryParameters: {
    'skip': skip,
    'limit': limit,
    'type': type,
    if (topic != null && topic.isNotEmpty) 'topic': topic,
  });
  return response.data;
}

Future<Map<String, dynamic>> getNewsDetail(String newsId) async {
  final response = await _dio.get('/news/$newsId');
  return response.data;
}

// ── Master-Tier: Gavel AI (Case Prediction) ────────────────

Future<Map<String, dynamic>> predictOutcome(String sessionId, String message, String token) async {
  final response = await _dio.post(
    '/ai-chat/predict-outcome',
    data: {'session_id': sessionId, 'message': message},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

// ── Master-Tier: Veritas Vault (Evidence Integrity) ────────

Future<Map<String, dynamic>> logEvidenceHash({
  required String fileHash,
  required String fileName,
  required String fileType,
  required String token,
}) async {
  final response = await _dio.post(
    '/evidence/hash',
    data: {
      'file_hash': fileHash,
      'file_name': fileName,
      'file_type': fileType,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<Map<String, dynamic>> verifyEvidence(String fileHash) async {
  final response = await _dio.post(
    '/evidence/verify',
    data: {'file_hash': fileHash},
  );
  return response.data;
}

// ── Karachi Survival System ───────────────────────────────────

Future<List<dynamic>> fetchLiveIncidents({String? area, String? token}) async {
  try {
    final options = token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null;
    final response = await _dio.get('/karachi/incidents', queryParameters: {
      if (area != null && area != 'All') 'area': area,
    }, options: options);
    return List<dynamic>.from(response.data);
  } catch (e) {
    return [];
  }
}

Future<Map<String, dynamic>> reportIncident({
  required String type,
  required String description,
  required String area,
  String? subArea,
  int? severity,
  required double lat,
  required double lng,
  required String token,
}) async {
  final response = await _dio.post(
    '/karachi/incidents',
    data: {
      'incident_type': type,
      'description': description,
      'area': area,
      if (subArea != null) 'sub_area': subArea,
      if (severity != null) 'severity': severity,
      'latitude': lat,
      'longitude': lng,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<String> fetchRadarSummary(String area) async {
  try {
    final response = await _dio.get('/karachi/radar/summary', queryParameters: {'area': area});
    return response.data['summary'] as String;
  } catch (e) {
    return 'All clear! No active traffic, security, or utility issues reported in $area today. Stay safe! 🚗';
  }
}

Future<Map<String, dynamic>> voteIncident({
  required String incidentId,
  required String action,
  required String token,
}) async {
  final response = await _dio.post(
    '/karachi/incidents/$incidentId/vote',
    queryParameters: {
      'action': action,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}
  // ── Lawyer AI Features ──────────────────────────────────────
  
  Future<Map<String, dynamic>> analyzeCase({
    required String description,
    required String category,
    String? opponentDetails,
    required String token,
  }) async {
    final response = await _dio.post(
      '/lawyer/ai/case-analysis',
      data: {
        'case_description': description,
        'category': category,
        if (opponentDetails != null) 'opponent_details': opponentDetails,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getClientSummary(String consultationId, String token) async {
    final response = await _dio.post(
      '/lawyer/ai/client-summary',
      data: {'consultation_id': consultationId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Smart Case Timeline ───────────────────────────────────────

  Future<List<dynamic>> getCaseTimeline(String consultationId, String token) async {
    final response = await _dio.get(
      '/lawyer/cases/$consultationId/timeline',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addTimelineEvent({
    required String consultationId,
    required String eventType,
    required String title,
    String? description,
    required String eventDate,
    required String token,
  }) async {
    final response = await _dio.post(
      '/lawyer/cases/$consultationId/timeline',
      data: {
        'event_type': eventType,
        'title': title,
        'description': description,
        'event_date': eventDate,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateTimelineEvent({
    required String consultationId,
    required String eventId,
    bool? isCompleted,
    String? title,
    String? description,
    required String token,
  }) async {
    final response = await _dio.patch(
      '/lawyer/cases/$consultationId/timeline/$eventId',
      data: {
        if (isCompleted != null) 'is_completed': isCompleted,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<void> deleteTimelineEvent(String consultationId, String eventId, String token) async {
    await _dio.delete(
      '/lawyer/cases/$consultationId/timeline/$eventId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Map<String, dynamic>> getTimelineAISuggestion(String consultationId, String token) async {
    final response = await _dio.post(
      '/lawyer/cases/$consultationId/timeline/ai-suggest',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Digital Legal Chamber ─────────────────────────────────────

  Future<Map<String, dynamic>> getChamberSession(String consultationId, String token) async {
    final response = await _dio.get(
      '/lawyer/chamber/$consultationId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> saveChamberNotes(String consultationId, String notes, String token) async {
    final response = await _dio.put(
      '/lawyer/chamber/$consultationId/notes',
      data: {'content': notes},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getChamberDocuments(String consultationId, String token) async {
    final response = await _dio.get(
      '/lawyer/chamber/$consultationId/documents',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> uploadChamberDocument({
    required String consultationId,
    required String filename,
    required String base64Content,
    required String token,
  }) async {
    final response = await _dio.post(
      '/lawyer/chamber/$consultationId/documents',
      data: {
        'filename': filename,
        'content': base64Content,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Lawyer Public Profile ─────────────────────────────────────

  Future<Map<String, dynamic>> getLawyerPublicProfile(String lawyerId) async {
    final response = await _dio.get('/lawyers/$lawyerId/public-profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updatePublicProfile({
    required List<dynamic> services,
    required String theme,
    required Map<String, dynamic> sections,
    required String token,
  }) async {
    final response = await _dio.patch(
      '/lawyers/me/public-profile',
      data: {
        'services_offered': services,
        'profile_theme': theme,
        'profile_visible_sections': sections,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Legal Marketplace ─────────────────────────────────────────

  Future<List<dynamic>> getMarketplaceServices({String? category, double? maxPrice, double? minRating}) async {
    final response = await _dio.get('/marketplace/services', queryParameters: {
      if (category != null) 'category': category,
      if (maxPrice != null) 'max_price': maxPrice,
      if (minRating != null) 'min_rating': minRating,
    });
    return response.data;
  }
  
  Future<List<dynamic>> getMyServices(String token) async {
    final response = await _dio.get(
      '/marketplace/my-services',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createService({
    required String title,
    required String description,
    required String category,
    required double price,
    required int deliveryDays,
    String? requirements,
    required String token,
  }) async {
    final response = await _dio.post(
      '/marketplace/services',
      data: {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'delivery_days': deliveryDays,
        'requirements': requirements,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateService({
    required String id,
    String? title,
    String? description,
    String? category,
    double? price,
    int? deliveryDays,
    String? requirements,
    required String token,
  }) async {
    final response = await _dio.patch(
      '/marketplace/services/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (price != null) 'price': price,
        if (deliveryDays != null) 'delivery_days': deliveryDays,
        if (requirements != null) 'requirements': requirements,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<void> deleteService(String id, String token) async {
    await _dio.delete(
      '/marketplace/services/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Map<String, dynamic>> toggleService(String id, String token) async {
    final response = await _dio.patch(
      '/marketplace/services/$id/toggle',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> placeOrder({
    required String serviceId,
    required String requirements,
    required String token,
  }) async {
    final response = await _dio.post(
      '/marketplace/orders',
      data: {
        'service_id': serviceId,
        'requirements': requirements,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getMyOrders(String token) async {
    final response = await _dio.get(
      '/marketplace/lawyer-orders',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getLawyerOrders(String token) async {
    final response = await _dio.get(
      '/marketplace/lawyer-orders',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateOrderStatus(String id, String status, String token) async {
    final response = await _dio.patch(
      '/marketplace/orders/$id/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Lawyer Referral Network ───────────────────────────────────

  Future<List<dynamic>> getMyNetwork(String token) async {
    final response = await _dio.get(
      '/lawyer/network',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addToNetwork(String lawyerId, String token) async {
    final response = await _dio.post(
      '/lawyer/network',
      data: {'lawyer_id': lawyerId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<void> removeFromNetwork(String id, String token) async {
    await _dio.delete(
      '/lawyer/network/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Map<String, dynamic>> sendReferral({
    required String toLawyerId,
    String? consultationId,
    required String caseDescription,
    String? notes,
    double? referralFeePercent,
    required String token,
  }) async {
    final response = await _dio.post(
      '/lawyer/referrals',
      data: {
        'to_lawyer_id': toLawyerId,
        if (consultationId != null) 'consultation_id': consultationId,
        'case_description': caseDescription,
        if (notes != null) 'notes': notes,
        if (referralFeePercent != null) 'referral_fee_percent': referralFeePercent,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getIncomingReferrals(String token) async {
    final response = await _dio.get(
      '/lawyer/referrals/incoming',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getSentReferrals(String token) async {
    final response = await _dio.get(
      '/lawyer/referrals/sent',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> respondToReferral(String id, bool accept, String token) async {
    final response = await _dio.patch(
      '/lawyer/referrals/$id/respond',
      data: {'accept': accept},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> completeReferral(String id, String token) async {
    final response = await _dio.patch(
      '/lawyer/referrals/$id/complete',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ── Achievement & Ranking System ──────────────────────────────

  Future<Map<String, dynamic>> getLawyerAchievements(String token) async {
    final response = await _dio.get(
      '/lawyer/achievements',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> checkAchievements(String token) async {
    final response = await _dio.post(
      '/lawyer/achievements/check',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getLawyerTier(String token) async {
    final response = await _dio.get(
      '/lawyer/tier',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getLawyerBadges(String lawyerId) async {
    final response = await _dio.get('/lawyers/$lawyerId/badges');
    return response.data;
  }


  Future<List<dynamic>> getNetworkLawyers(String token) async {
    final response = await _dio.get(
      '/lawyer/network',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getReceivedReferrals(String token) async {
    final response = await _dio.get(
      '/lawyer/referrals/received',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

}

final apiService = ApiService();

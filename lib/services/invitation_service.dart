import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/guest.dart';

class InvitationService {
  Future<bool> sendEmailInvitation(Event event, Guest guest, {String? customMessage}) async {
    final subject = Uri.encodeComponent('Invitation: ${event.title}');
    final body = Uri.encodeComponent(_generateEmailBody(event, guest, customMessage));
    final emailUrl = 'mailto:${guest.email}?subject=$subject&body=$body';

    try {
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendSMSInvitation(Event event, Guest guest, {String? customMessage}) async {
    if (guest.phone == null || guest.phone!.isEmpty) {
      return false;
    }

    final message = Uri.encodeComponent(_generateSMSBody(event, guest, customMessage));
    final smsUrl = 'sms:${guest.phone}?body=$message';

    try {
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<bool>> sendBulkInvitations(
    Event event,
    List<Guest> guests,
    InvitationType type, {
    String? customMessage,
  }) async {
    final results = <bool>[];
    
    for (final guest in guests) {
      bool success = false;
      
      switch (type) {
        case InvitationType.email:
          success = await sendEmailInvitation(event, guest, customMessage: customMessage);
          break;
        case InvitationType.sms:
          success = await sendSMSInvitation(event, guest, customMessage: customMessage);
          break;
        case InvitationType.both:
          final emailSuccess = await sendEmailInvitation(event, guest, customMessage: customMessage);
          final smsSuccess = await sendSMSInvitation(event, guest, customMessage: customMessage);
          success = emailSuccess || smsSuccess;
          break;
      }
      
      results.add(success);
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  String _generateEmailBody(Event event, Guest guest, String? customMessage) {
    final eventDate = event.dateTime;
    final dateStr = '${eventDate.day}/${eventDate.month}/${eventDate.year}';
    final timeStr = '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';

    return '''
Hello ${guest.name},

You're invited to: ${event.title}

${customMessage ?? 'We would love to have you join us for this special event!'}

Event Details:
📅 Date: $dateStr
🕒 Time: $timeStr
📍 Location: ${event.location.isNotEmpty ? event.location : 'TBD'}

${event.description.isNotEmpty ? 'Description:\n${event.description}\n' : ''}

Please let us know if you can attend by replying to this invitation.

Looking forward to seeing you there!

Best regards,
Event Planning Team
    ''';
  }

  String _generateSMSBody(Event event, Guest guest, String? customMessage) {
    final eventDate = event.dateTime;
    final dateStr = '${eventDate.day}/${eventDate.month}/${eventDate.year}';
    final timeStr = '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';

    return '''
Hi ${guest.name}! You're invited to ${event.title} on $dateStr at $timeStr. Location: ${event.location.isNotEmpty ? event.location : 'TBD'}. ${customMessage ?? 'Hope to see you there!'} Please RSVP.
    ''';
  }

  String generateInvitationLink(Event event) {
    return 'https://event-planner.app/rsvp/${event.id}';
  }

  Map<String, dynamic> generateInvitationData(Event event, Guest guest) {
    return {
      'eventId': event.id,
      'eventTitle': event.title,
      'eventDate': event.dateTime.toIso8601String(),
      'eventLocation': event.location,
      'guestId': guest.id,
      'guestName': guest.name,
      'guestEmail': guest.email,
      'invitationLink': generateInvitationLink(event),
    };
  }
}

enum InvitationType {
  email,
  sms,
  both,
}
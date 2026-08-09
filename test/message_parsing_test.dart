import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:whisper/models/message.dart';

/// The API speaks two dialects for the same message, both captured from the
/// live server: `GET /messages` answers in camelCase with the body under
/// `content`, while WebSocket frames answer in snake_case and put an image's
/// path under `url`. Parsing has to cover both.
void main() {
  group('REST history (camelCase, `content`)', () {
    test('parses a text message', () {
      final message = ChatMessage.fromJson(jsonDecode('''
        {
          "id": "482a3d45-710e-482e-ab06-43e0fba45f27",
          "senderId": "a4fc989c-758b-4003-8b6b-f860fb0dc5c0",
          "receiverId": "421213e5-6397-404c-ba79-e6a2788a5135",
          "type": "text",
          "content": "Hola",
          "createdAt": "2026-08-09T01:15:52.911082+00:00"
        }
      '''));

      expect(message.kind, MessageKind.text);
      expect(message.content, 'Hola');
      expect(message.senderId, 'a4fc989c-758b-4003-8b6b-f860fb0dc5c0');
      expect(message.receiverId, '421213e5-6397-404c-ba79-e6a2788a5135');
      expect(message.createdAt, isNotNull);
    });

    test('parses an image message', () {
      final message = ChatMessage.fromJson(jsonDecode('''
        {
          "id": "dd1c37f3-d3c9-452c-b006-86ba84469123",
          "senderId": "a4fc989c-758b-4003-8b6b-f860fb0dc5c0",
          "receiverId": "421213e5-6397-404c-ba79-e6a2788a5135",
          "type": "image",
          "content": "/uploads/msg_f0d6fb9b-d606-47f7-934b-f0e0f15adef1.jpg",
          "createdAt": "2026-08-09T01:15:33.233940+00:00"
        }
      '''));

      expect(message.kind, MessageKind.image);
      expect(message.imageUrl, 'https://peoplefinder.kaucrow.com/api/uploads/msg_f0d6fb9b-d606-47f7-934b-f0e0f15adef1.jpg');
    });
  });

  group('WebSocket frame (snake_case, `url`)', () {
    test('parses an image echo, which carries no receiver and uses `url`', () {
      final message = ChatMessage.fromJson(jsonDecode('''
        {
          "created_at": "2026-08-09T01:20:20.089549+00:00",
          "id": "a7f5c3f6-07be-4acd-9876-a2488c732459",
          "sender_id": "a4fc989c-758b-4003-8b6b-f860fb0dc5c0",
          "type": "image",
          "url": "/uploads/msg_270f292c-dafc-4dfb-b2e2-44a43e509ad3.jpg"
        }
      '''));

      // Regression: reading only `content` left this empty and the frame was
      // dropped, so a sent image never left the "Enviando…" state.
      expect(message.content, isNotEmpty);
      expect(message.kind, MessageKind.image);
      expect(message.imageUrl, 'https://peoplefinder.kaucrow.com/api/uploads/msg_270f292c-dafc-4dfb-b2e2-44a43e509ad3.jpg');
      expect(message.senderId, 'a4fc989c-758b-4003-8b6b-f860fb0dc5c0');
      expect(message.createdAt, isNotNull);
    });

    test('parses a text echo', () {
      final message = ChatMessage.fromJson(jsonDecode('''
        {
          "created_at": "2026-08-09T01:20:20.089549+00:00",
          "id": "b1",
          "sender_id": "a4fc989c-758b-4003-8b6b-f860fb0dc5c0",
          "type": "text",
          "content": "Hola"
        }
      '''));

      expect(message.kind, MessageKind.text);
      expect(message.content, 'Hola');
    });
  });

  test('an unknown type falls back to inspecting the content', () {
    final image = ChatMessage.fromJson({'content': '/uploads/a.png'});
    final text = ChatMessage.fromJson({'content': 'no soy una ruta'});

    expect(image.kind, MessageKind.image);
    expect(text.kind, MessageKind.text);
  });

  test('sentBy only matches a known id', () {
    final message = ChatMessage.fromJson({'senderId': 'me', 'content': 'x'});

    expect(message.sentBy('me'), isTrue);
    expect(message.sentBy('someone-else'), isFalse);
    expect(message.sentBy(null), isFalse);
  });
}

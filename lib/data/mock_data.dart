import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/friend_request.dart';
import '../models/message.dart';

/// The signed-in user. Will come from the auth endpoint later.
const currentUser = AppUser(
  id: 'me',
  name: 'Camila Torres',
  username: 'camila.t',
  email: 'camila@correo.com',
  bio: 'Diseñadora de producto ✦ café y música',
  avatarColor: Color(0xFFC7C2FF),
);

const _lucia = AppUser(
  id: 'u1',
  name: 'Lucía Marín',
  username: 'lucia.m',
  email: 'lucia@correo.com',
  avatarColor: Color(0xFFC7C2FF),
);
const _diego = AppUser(
  id: 'u2',
  name: 'Diego Ruiz',
  username: 'diego.r',
  email: 'diego@correo.com',
  avatarColor: Color(0xFFA7E8C8),
);
const _grupoTrabajo = AppUser(
  id: 'g1',
  name: 'Grupo · Trabajo',
  username: 'grupo-trabajo',
  email: '',
  avatarColor: Color(0xFFFFCBA6),
);
const _sofia = AppUser(
  id: 'u3',
  name: 'Sofía Navarro',
  username: 'sofia.n',
  email: 'sofia@correo.com',
  avatarColor: Color(0xFFF4B6C8),
);
const _mateo = AppUser(
  id: 'u4',
  name: 'Mateo Álvarez',
  username: 'mateo.a',
  email: 'mateo@correo.com',
  avatarColor: Color(0xFF8EC5FF),
);
const _valeria = AppUser(
  id: 'u5',
  name: 'Valeria Peña',
  username: 'valeria.p',
  email: 'valeria@correo.com',
  avatarColor: Color(0xFFD9C2FF),
);

/// Chat list shown on the home screen, in display order.
final List<Chat> mockChats = [
  Chat(
    id: 'c1',
    otherUser: _lucia,
    lastMessage: '¿Nos vemos hoy? 👀',
    time: '9:36',
    unreadCount: 2,
    messages: const [
      ChatMessage(id: 'm1', text: '¡Hola! ¿Cómo vas con el proyecto? 😊', sentByMe: false, time: '9:24'),
      ChatMessage(id: 'm2', text: 'Muy bien, casi termino los mockups', sentByMe: true, time: '9:28', delivered: true, read: true),
      ChatMessage(id: 'm3', text: '¿Nos vemos hoy para revisarlos?', sentByMe: true, time: '9:30', delivered: true, read: true),
      ChatMessage(id: 'm4', text: '¡Claro! ¿Te va bien a las 5? 👀', sentByMe: false, time: '9:36'),
    ],
  ),
  const Chat(
    id: 'c2',
    otherUser: _diego,
    lastMessage: 'Perfecto, te mando el archivo',
    time: '8:12',
  ),
  Chat(
    id: 'c3',
    otherUser: _grupoTrabajo,
    lastMessage: 'Ana: Lo revisamos mañana 👍',
    time: 'Ayer',
    kind: ChatPreviewKind.group,
  ),
  Chat(
    id: 'c4',
    otherUser: _sofia,
    lastMessage: 'Gracias por todo ✨',
    time: 'Ayer',
    lastMessageSentByMe: true,
    lastMessageRead: true,
  ),
  Chat(
    id: 'c5',
    otherUser: _mateo,
    lastMessage: 'Mensaje de voz · 0:14',
    time: 'Lun',
    kind: ChatPreviewKind.voice,
  ),
  const Chat(
    id: 'c6',
    otherUser: _valeria,
    lastMessage: 'Jajaja sí, total 😂',
    time: 'Lun',
  ),
];

/// Pending friend requests for the requests screen.
final List<FriendRequest> mockReceivedRequests = [
  const FriendRequest(
    id: 'r1',
    user: AppUser(id: 'u6', name: 'Javier Ramírez', username: 'javier.r', email: '', avatarColor: Color(0xFFA7E8C8)),
    mutualFriends: 4,
    direction: RequestDirection.received,
  ),
  const FriendRequest(
    id: 'r2',
    user: AppUser(id: 'u7', name: 'Elena Molina', username: 'elena.m', email: '', avatarColor: Color(0xFFFFCBA6)),
    mutualFriends: 1,
    direction: RequestDirection.received,
  ),
  const FriendRequest(
    id: 'r3',
    user: AppUser(id: 'u8', name: 'Tomás Castro', username: 'tomas.c', email: '', avatarColor: Color(0xFFF4B6C8)),
    mutualFriends: 8,
    direction: RequestDirection.received,
  ),
];

final List<FriendRequest> mockSentRequests = [
  const FriendRequest(
    id: 'r4',
    user: AppUser(id: 'u9', name: 'Renata Ibarra', username: 'renata.i', email: '', avatarColor: Color(0xFF8EC5FF)),
    mutualFriends: 2,
    direction: RequestDirection.sent,
  ),
];

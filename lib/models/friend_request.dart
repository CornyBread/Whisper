import 'app_user.dart';

enum RequestDirection { received, sent }

/// A pending friend request, either received or sent by the current user.
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.user,
    required this.mutualFriends,
    required this.direction,
  });

  final String id;
  final AppUser user;
  final int mutualFriends;
  final RequestDirection direction;
}

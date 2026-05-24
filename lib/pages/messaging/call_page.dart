import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';


class CallPage extends StatelessWidget {
  final String callId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserImage;
  final String otherUserId;
  final String otherUserImage;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserImage,
    required this.otherUserId,
    required this.otherUserImage,
    required this.isVideoCall,
  });

  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.trim().isEmpty) return null;

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const int zegoAppId = 1547729501;
    const String zegoAppSign =
        '42ebf8c1cc225899c2b95b346fee34ba519a10868eb69a6151d0575cd640d296';

    final config = isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    config.avatarBuilder = (
      BuildContext context,
      Size size,
      ZegoUIKitUser? user,
      Map extraInfo,
    ) {
      final isCurrentUser = user?.id == currentUserId;
      final imageUrl = isCurrentUser ? currentUserImage : otherUserImage;
      final imageProvider = _getImageProvider(imageUrl);

      return CircleAvatar(
        radius: size.width / 2,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                (user?.name.isNotEmpty ?? false)
                    ? user!.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: size.width * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              )
            : null,
      );
    };

    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: zegoAppId,
          appSign: zegoAppSign,
          userID: currentUserId,
          userName: currentUserName,
          callID: callId,
          config: config,
        ),
      ),
    );
  }
}
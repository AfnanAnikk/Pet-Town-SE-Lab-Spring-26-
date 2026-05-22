import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  final String callId;
  final String currentUserId;
  final String currentUserName;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.currentUserName,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    const int zegoAppId = 1547729501;
    const String zegoAppSign = "42ebf8c1cc225899c2b95b346fee34ba519a10868eb69a6151d0575cd640d296";

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: zegoAppId,
        appSign: zegoAppSign,
        userID: currentUserId,
        userName: currentUserName,
        callID: callId,
        // Configures the UI automatically based on Voice vs Video
        config: isVideoCall 
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
      ),
    );
  }
}

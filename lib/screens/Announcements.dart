import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:lock/constonants.dart';// Required for HapticFeedback

final _firestore = FirebaseFirestore.instance;

class AnnouncementScreen extends StatefulWidget {
  static const String id = 'announcement_screen';

  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  User? loggedinUser;
  String? messageText;
  DateTime? timestamp;
  bool isAdmin =false;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser!;
      if (user != null) {
        loggedinUser = user;
        print(loggedinUser!.email);
        setState(() {
          isAdmin=loggedinUser?.email=='dev.kamma04@gmail.com';
        });
      }
    } catch (e) {
      print('User login is wrong, because of this exception: $e');
    }
  }

  void messageStreams() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnnouncementScreenBkgColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: kContainerNeumorphim,
          child: AppBar(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
            title: Text('Announcements',style: TextStyle(
                color: kAnnouncementScreenAppBarTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              fontFamily: kAnnouncementScreenPrimaryFontFamily
            ),),
            backgroundColor: kAnnouncementScreenAppBarBkgColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children:[
            Align(
              alignment: Alignment.center, // Adjust position if needed
              child: Opacity(
                opacity: 0.4, // Make it semi-transparent
                child: Icon(
                  kBumbleBeeLogo, // Any icon you prefer
                  size: (MediaQuery.of(context).size.height)*0.5, // Adjust size as needed
                  color: kTextAndIconColor, // Adjust color
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessageStreams(),
              isAdmin
                  ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: kAnnouncementScreenTextFieldContainerColor, width: 2.0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          hintText: 'Type your message here',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        messageTextController.clear();
                        _firestore.collection('announcements').add({
                          'text': messageText,
                          'sender': loggedinUser?.email,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                      },
                      child: Text(
                        'Send',
                        style: TextStyle(
                          color: kAnnouncementScreenTextButtonTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : SizedBox.shrink()
            ],
          )
          ]
          ,
        ),
      ),
    );
  }
}

class MessageStreams extends StatelessWidget {
  const MessageStreams({super.key});

  @override
  Widget build(BuildContext context) {
    void deleteMessage(String messageId) async {
      try {
        await _firestore.collection('announcements').doc(messageId).delete();
        print("Message with ID $messageId deleted successfully.");
      } catch (e) {
        print("Failed to delete message: $e");
      }
    }
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('announcements').orderBy('timestamp',descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: kAnnouncementScreenMessageBubbleColor,
              ),
            );
          }
          final messages = snapshot.data?.docs;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages!) {
            final messageText = message.get('text');
            final messageSender = message.get('sender');
            final messageTimestamp = message.get('timestamp') != null
                ? (message.get('timestamp') as Timestamp).toDate()
                : null; // Convert Firestore timestamp to DateTime
            final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              timestamp: messageTimestamp,
              messageId: message.id,
              onDelete: deleteMessage,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: messageBubbles,
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
   MessageBubble({this.sender, this.text,this.timestamp,this.messageId,this.onDelete ,super.key});
  final String? sender;
  final String? text;
  final DateTime? timestamp;
  final String? messageId; // Document ID
  final Function(String)? onDelete; // Callback for deletion




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        if (messageId != null && onDelete != null) {
          HapticFeedback.mediumImpact();
          onDelete!(messageId!); // Call the delete function with messageId
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
                borderRadius: BorderRadius.circular(12),
                elevation: 5,
                color: kAnnouncementScreenMessageBubbleColor,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('$text',style: TextStyle(color: Colors.white,
                          fontFamily: kAnnouncementScreenPrimaryFontFamily,
                          fontWeight: FontWeight.bold),),
                      Text(
                        textAlign: TextAlign.end,
                        timestamp != null
                            ? DateFormat('MMM d, yyyy hh:mm a').format(timestamp!)
                            : '...',
                        style: TextStyle(
                            color: kAnnouncementScreenDateColor),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

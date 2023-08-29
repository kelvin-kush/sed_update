import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sedweb/Screens/Home/Feed/component/add_feed.dart';
import 'package:sedweb/Screens/Home/Feed/component/feed_card.dart';
import 'package:sedweb/Screens/notifications/notifications.dart';
import 'package:sedweb/components/constraints.dart';
import 'package:sedweb/models/post_model.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key}) : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              elevation: 1,
              title: const Text(
                'Study Buddie',
              ),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      NotificationPage(uid: currentUser!.uid)));
                        },
                        child: const Icon(
                          Icons.notifications,
                          color: kPrimaryColor,
                          size: 32,
                        )),
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("notifications")
                            .where('receiver', isEqualTo: currentUser!.uid)
                            .where('seen', isEqualTo: false)
                            .snapshots(),
                        builder: (
                          BuildContext context,
                          notSnapshot,
                        ) {
                          if (notSnapshot.hasData &&
                              notSnapshot.data!.docs.isNotEmpty) {
                            return Positioned(
                                top: 2,
                                right: 13,
                                child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                          "${notSnapshot.data!.docs.length}"),
                                    )));
                          } else {
                            return Container();
                          }
                        })
                  ],
                )
              ],
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const AddFeed(),
                    StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('Posts')
                            .orderBy('postDate', descending: true)
                            .snapshots(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: snapshot.data.docs.length,
                                itemBuilder: (context, index) {
                                  final data = snapshot.data.docs;
                                  return FeedCard(
                                      postModel: PostModel(
                                          postID: data[index]['postID'],
                                          senderID: data[index]['senderID'],
                                          likes: data[index]['likes'],
                                          likers: data[index]['likers'],
                                          message: data[index]['message'],
                                          postDate: (data[index]['postDate']
                                                  as Timestamp)
                                              .toDate(),
                                          image: data[index]['image']));
                                });
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: kPrimaryColor,
                                ),
                              ),
                            );
                          } else {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No feeds available'),
                              ),
                            );
                          }
                        }),
                  ],
                ),
              ),
            )));
  }
}

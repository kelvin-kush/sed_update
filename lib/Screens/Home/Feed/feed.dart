import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sedweb/Screens/Home/Feed/component/add_feed.dart';
import 'package:sedweb/Screens/Home/Feed/component/feed_card.dart';
import 'package:sedweb/components/constraints.dart';
import 'package:sedweb/models/post_model.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key}) : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'SedWeb',
              ),
              actions: [
                IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications,
                      color: kPrimaryColor,
                    ))
              ],
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AddFeed(),
                    FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('Posts')
                            .orderBy('postDate', descending: true)
                            .get(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: kPrimaryColor,
                                ),
                              );
                            } else {
                              return ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: snapshot.data.docs.length,
                                  itemBuilder: (context, index) {
                                    final data = snapshot.data.docs;
                                    return FeedCard(
                                        postModel: PostModel(
                                            sender: {
                                          'name': data[index]['sender']['name'],
                                          'profile': data[index]['sender']
                                              ['profile'],
                                          'uid': data[index]['sender']['uid'],
                                        },
                                            message: data[index]['message'],
                                            postDate: (data[index]['postDate']
                                                    as Timestamp)
                                                .toDate(),
                                            image: data[index]['image']));
                                  });
                            }
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

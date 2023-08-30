import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sedweb/models/article.dart';
import 'package:sedweb/models/user_model.dart';
import 'package:sedweb/service/api_service.dart';
import 'package:sedweb/service/firebase_db.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

class ArticleFullScreen extends StatefulWidget {
  const ArticleFullScreen({Key? key, required this.article}) : super(key: key);
  final Article article;

  @override
  State<ArticleFullScreen> createState() => _ArticleFullScreenState();
}

class _ArticleFullScreenState extends State<ArticleFullScreen> {
  late bool isReadLoading;
  late bool isSummarizing;
  late bool isCommenting;
  UserModel currentUSer = UserModel();
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get()
        .then((value) {
      currentUSer = UserModel.fromMap(value.data());
    });
    isReadLoading = false;
    isSummarizing = false;
    isCommenting = false;
    textEditingController = TextEditingController(text: '');
  }

  void onAddComment() async {
    if (textEditingController.text.trim().isEmpty) return;
    setState(() {
      isCommenting = true;
    });
    var res = await FirebaseDB.instance.addComment(ArticleComment(
        id: const Uuid().v4(),
        comment: textEditingController.text,
        articleId: widget.article.id,
        name: currentUSer.name ?? '',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        profile: currentUSer.profile ?? '',
        createdAt: DateTime.now()));
    setState(() {
      isCommenting = false;
    });
    if (res is String) {
      //TODO show error message
      return;
    }
  }

  void onRead() async {
    setState(() {
      isReadLoading = true;
    });
    var res = await getExternalStorageDirectory();
    String appDocumentsPath = res!.absolute.path;
    var file = File('$appDocumentsPath/${widget.article.docName}');
    if (file.existsSync()) {
      setState(() {
        isReadLoading = false;
      });
      log(file.existsSync().toString());
      // log(file.readAsString().toString());
      // return;
      if (await Permission.manageExternalStorage.request().isGranted) {
        await OpenFile.open(file.path)
            .then((value) => print(value.type))
            .onError((error, stackTrace) =>
                log(error.toString(), stackTrace: stackTrace));
      }
      return;
    }

    var result = await ApiService.instance.downloadDoc(
        widget.article.documentUrl, appDocumentsPath, widget.article.docName);
    setState(() {
      isReadLoading = false;
    });
    if (result is File) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        OpenFile.open(result.path).then((value) => print(value.message));
      }
      return;
    }
    //TODO: show error dialog here
  }

  List<String>? extractText(File file) {
    try {
      PdfDocument doc = PdfDocument(inputBytes: file.readAsBytesSync());
      var text = PdfTextExtractor(doc).extractTextLines();
      doc.dispose();
      return text.map((e) => e.text).toList();
    } on Exception {}
  }

  void onSummarize() async {
    setState(() {
      isSummarizing = true;
    });
    var res = await getExternalStorageDirectory();
    String appDocumentsPath = res!.absolute.path;
    var file = File('$appDocumentsPath/${widget.article.docName}');
    if (file.existsSync()) {
      var res = extractText(file);

      if (res != null) {
        _getSummary(res);
        return;
      }
      //TODO: show error here
      setState(() {
        isSummarizing = false;
      });
      //TODO: how error message here
      // print(res);
      return;
    }
    var result = await ApiService.instance.downloadDoc(
        widget.article.documentUrl, appDocumentsPath, widget.article.docName);

    if (result is File) {
      var res = extractText(file);
      if (res != null) {
        _getSummary(res);
        return;
      }
      //TODO show error message
      return;
    }
    //TODO: show error msg
    setState(() {
      isSummarizing = false;
    });
  }

  void _getSummary(List<String> res) async {
    String result = res.fold<String>(
        '', (previousValue, element) => previousValue + '\n' + element);
    //TODO: make request here
    var response = await ApiService.instance.summarize(result);
    setState(() {
      isSummarizing = false;
    });
    if (response is String) {
      //TODO show error messge
      print('error');
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Summary'),
              content: Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(response['summary']),
                    ],
                  ),
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            )),
      ),
      // resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                    child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipOval(
                    child: widget.article.profile != null ||
                            widget.article.profile.trim().isEmpty
                        ? Image.network(
                            widget.article.profile,
                            fit: BoxFit.cover,
                            errorBuilder: ((context, error, stackTrace) =>
                                const CircleAvatar(
                                  child: Icon(Icons.person),
                                  //fit: BoxFit.cover,
                                )),
                          )
                        : const Icon(Icons.person),
                  ),
                )),
                title: Text(
                  widget.article.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  timeago.format(widget.article.createdAt),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: RichText(
                    text: TextSpan(
                        text: 'Article Topic:\n',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        children: [
                      TextSpan(
                          text: widget.article.topic,
                          style: const TextStyle(
                            color: Colors.black54,
                          ))
                    ])),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: RichText(
                    text: TextSpan(
                        text: 'Article filename:\n',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        children: [
                      TextSpan(
                          text: widget.article.docName,
                          style: const TextStyle(
                            color: Colors.black54,
                          ))
                    ])),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.comment),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(widget.article.comments.length.toString())
                      ],
                    ),
                    isReadLoading
                        ? const CircularProgressIndicator()
                        : TextButton.icon(
                            onPressed: onRead,
                            icon: const Icon(Icons.read_more),
                            label: const Text('Read article')),
                    isSummarizing
                        ? const CircularProgressIndicator()
                        : TextButton.icon(
                            onPressed: onSummarize,
                            icon: const Icon(Icons.summarize),
                            label: const Text('Get summary'))
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                  child: StreamBuilder<QuerySnapshot<ArticleComment>>(
                stream: FirebaseDB.instance.getComments(widget.article.id),
                builder: (BuildContext context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading comments'),
                    );
                  }
                  if (snapshot.hasData) {
                    final data =
                        snapshot.data!.docs.map((e) => e.data()).toList();
                    return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (_, i) => ListTile(
                              title: Text(data[i].name),
                              subtitle: Text(
                                data[i].comment,
                              ),
                              trailing: Text(timeago.format(data[i].createdAt)),
                              leading: CircleAvatar(
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: ClipOval(
                                    child: data[i].profile.isEmpty
                                        ? null
                                        : Image.network(
                                            data[i].profile,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                            ));
                  }
                  return Container();
                },
              )),
              Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: textEditingController,
                      decoration: const InputDecoration(
                          hintText: 'Enter comment here',
                          border: OutlineInputBorder()),
                    ),
                  )),
                  IconButton(
                      onPressed: isCommenting ? null : onAddComment,
                      icon: const Icon(Icons.send))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

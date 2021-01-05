import 'package:messeco/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:messeco/widgets/fullPhoto.dart';
import 'package:messeco/widgets/spin.dart';
import 'package:intl/intl.dart';

class Chat extends StatelessWidget {
  final String pairId;
  final String pairNickname;
  static String id = 'chat_screen';

  Chat({Key key, @required this.pairId, @required this.pairNickname})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0.0,
        title: Text(
          '$pairNickname',
          style: TextStyle(
            color: kColor2,
            fontSize: 23,
          ),
        ),
        centerTitle: true,
      ),
      body: ChatScreen(
        pairId: pairId,
        pairNickname: pairNickname,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String pairId;
  final String pairNickname;

  ChatScreen({Key key, @required this.pairId, @required this.pairNickname})
      : super(key: key);

  @override
  State createState() =>
      ChatScreenState(pairId: pairId, pairNickname: pairNickname);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState(
      {Key key, @required this.pairId, @required this.pairNickname});

  String pairId;
  String pairNickname;
  String id;

  String messageText;

  List<QueryDocumentSnapshot> listMessage = new List.from([]);

  int _limit = 20;
  final int _limitIncrement = 20;

  String groupChatId;
  bool isShowSticker;
  bool showSpinner;
  String imageUrl;
  File imageFile;
  SharedPreferences prefs;
  IconData heart;

  final TextEditingController messageTextController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      print("reach the bottom");
      setState(() {
        print("reach the bottom");
        _limit += _limitIncrement;
      });
    }
    if (listScrollController.offset <=
            listScrollController.position.minScrollExtent &&
        !listScrollController.position.outOfRange) {
      print("reach the top");
      setState(() {
        print("reach the top");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);

    groupChatId = '';

    showSpinner = false;
    isShowSticker = false;
    imageUrl = '';

    readLocal();

    // getCurrentUser();
  }

  //hàm ẩn bảng sticker khi bật bàn phím
  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  //tạo group chat id
  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= pairId.hashCode) {
      groupChatId = '$id-$pairId'; //gửi - nhận
    } else {
      groupChatId = '$pairId-$id'; //nhận - gửi
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({'chattingWith': pairId});

    setState(() {});
  }

  //hàm lấy hình
  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        showSpinner = true;
      });
      uploadFile();
    }
  }

  //hàm ẩn bàn phím khi bật bảng sticker
  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  //hàm up file
  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        showSpinner = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        showSpinner = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  //Thả tym :3
  IconData dropTheHeart(IconData heart) {
    return heart;
  }

  //hàm viết và lưu tin nhắn
  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      messageTextController.clear();

      var documentReference = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(
            DateTime.now().millisecondsSinceEpoch.toString(),
          );

      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': pairId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type,
            'react': 0
          },
        );
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send',
          backgroundColor: Colors.black,
          textColor: Colors.red);
    }
  }

  //build message
  Widget buildItem(int index, DocumentSnapshot document) {
    if (document.data()['idFrom'] == id) {
      //check idFrom == id hiện tại thì là my message
      // Right (my message)
      return Row(
        children: <Widget>[
          document.data()['type'] == 0
              // nếu type là text
              ? Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM kk:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            int.parse(document.data()['timestamp']),
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        document.data()['content'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(20, 10, 25, 15),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.zero,
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  margin: EdgeInsets.only(
                    bottom: 2.0,
                    right: 5.0,
                  ),
                )
              : document.data()['type'] == 1
                  // nếu type là image
                  ? Container(
                      child: FlatButton(
                        child: Material(
                          child: CachedNetworkImage(
                            placeholder: (context, url) => Container(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    kPrimaryColor),
                              ),
                              width: 220.0,
                              height: 220.0,
                              padding: EdgeInsets.all(70.0),
                              decoration: BoxDecoration(
                                color: kSecondaryColor,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Material(
                              child: Image.asset(
                                'images/img_not_available.jpeg',
                                width: 150.0,
                                height: 150.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                              clipBehavior: Clip.hardEdge,
                            ),
                            imageUrl: document.data()['content'],
                            width: 150.0,
                            height: 150.0,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FullPhoto(
                                      url: document.data()['content'])));
                        },
                        padding: EdgeInsets.all(0),
                      ),
                      margin: EdgeInsets.only(
                        bottom: 2.0,
                        right: 5.0,
                      ),
                    )
                  // nếu type là sticker
                  : Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Text(
                          //   DateFormat('dd MMM kk:mm').format(
                          //     DateTime.fromMillisecondsSinceEpoch(
                          //       int.parse(document.data()['timestamp']),
                          //     ),
                          //   ),
                          //   style: TextStyle(
                          //     color: kSecondaryColor,
                          //     fontSize: 11,
                          //     fontWeight: FontWeight.w400,
                          //     fontStyle: FontStyle.italic,
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 5,
                          // ),
                          Image.asset(
                            'images/${document.data()['content']}.gif',
                            width: 100.0,
                            height: 100.0,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(
                        bottom: 2.0,
                        right: 5.0,
                      ),
                    ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (pair message)
      return Container(
        padding: EdgeInsets.only(left: 15),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // isLastMessageLeft(index)
                //     ? Material(
                //         child: CachedNetworkImage(
                //           placeholder: (context, url) => Container(
                //             child: CircularProgressIndicator(
                //               strokeWidth: 1.0,
                //               valueColor:
                //                   AlwaysStoppedAnimation<Color>(Colors.lime),
                //             ),
                //             width: 35.0,
                //             height: 35.0,
                //             padding: EdgeInsets.all(10.0),
                //           ),
                //           imageUrl: pairAvatar,
                //           width: 35.0,
                //           height: 35.0,
                //           fit: BoxFit.cover,
                //         ),
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(18.0),
                //         ),
                //         clipBehavior: Clip.hardEdge,
                //       )
                //     : Container(width: 35.0),
                document.data()['type'] == 0
                    ? Row(
                        children: [
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document.data()['timestamp']),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: kSecondaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  document.data()['content'],
                                  style: TextStyle(
                                    color: kSecondaryColor,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(25, 10, 20, 15),
                            decoration: BoxDecoration(
                              color: kColor2,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                                topLeft: Radius.zero,
                                topRight: Radius.circular(30),
                              ),
                            ),
                            margin: EdgeInsets.only(
                              left: 5.0,
                              bottom: 5.0,
                            ),
                          ),
                        ],
                      )
                    : document.data()['type'] == 1
                        ? Container(
                            child: FlatButton(
                              child: Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        kPrimaryColor,
                                      ),
                                    ),
                                    width: 220.0,
                                    height: 220.0,
                                    padding: EdgeInsets.all(70.0),
                                    decoration: BoxDecoration(
                                      color: kColor2,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                    child: Image.asset(
                                      'images/img_not_available.jpeg',
                                      width: 150.0,
                                      height: 150.0,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  imageUrl: document.data()['content'],
                                  width: 150.0,
                                  height: 150.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FullPhoto(
                                            url: document.data()['content'])));
                              },
                              padding: EdgeInsets.all(0),
                            ),
                            margin: EdgeInsets.only(
                              left: 5.0,
                              bottom: 2.0,
                            ),
                          )
                        : Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(
                                //   DateFormat('dd MMM kk:mm').format(
                                //     DateTime.fromMillisecondsSinceEpoch(
                                //       int.parse(document.data()['timestamp']),
                                //     ),
                                //   ),
                                //   style: TextStyle(
                                //     color: kSecondaryColor,
                                //     fontSize: 11,
                                //     fontWeight: FontWeight.w400,
                                //     fontStyle: FontStyle.italic,
                                //   ),
                                // ),
                                // SizedBox(
                                //   height: 5,
                                // ),
                                Image.asset(
                                  'images/${document.data()['content']}.gif',
                                  width: 100.0,
                                  height: 100.0,
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                            margin: EdgeInsets.only(bottom: 7.0, right: 10.0),
                          ),
              ],
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 2.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1].data()['idFrom'] == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index].data()['idFrom'] != id) ||
        (index == 0))
      return true;
    else
      return false;
  }

  //xử lý nút back
  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({'chattingWith': null});
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPrimaryColor,
      child: WillPopScope(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              topLeft: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  // List of messages
                  buildMessage(),

                  // Sticker
                  (isShowSticker ? buildSticker() : Container()),

                  // Input
                  buildType(),
                ],
              ),

              // Loading
              buildSpinner()
            ],
          ),
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  //build sticker
  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white,
              width: 0.5,
            ),
          ),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  //build spinner
  Widget buildSpinner() {
    return Positioned(
      child: showSpinner ? const Spinner() : Container(),
    );
  }

  //build type input
  Widget buildType() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                onPressed: getImage,
                color: kSecondaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.face_sharp),
                onPressed: getSticker,
                color: kSecondaryColor,
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (value) {
                  onSendMessage(messageTextController.text, 0);
                },
                style: TextStyle(
                  color: kSecondaryColor,
                  fontSize: 16.0,
                ),
                controller: messageTextController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: kSecondaryColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => onSendMessage(messageTextController.text, 0),
                color: kSecondaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white,
              width: 0.5,
            ),
          ),
          color: Colors.white),
    );
  }

  Widget buildMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
              ),
            )
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .limit(_limit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  );
                } else {
                  listMessage.addAll(snapshot.data.documents);
                  return ListView.builder(
                    padding: EdgeInsets.all(5.0),
                    itemBuilder: (context, index) {
                      if (snapshot.data.documents[index].data()['idFrom'] ==
                          id) {
                        return ListTile(
                          title: new Row(children: <Widget>[
                            new Expanded(
                              child: buildItem(
                                  index, snapshot.data.documents[index]),
                            ),
                          ]),
                          onLongPress: () {
                            showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  color: kColor2,
                                  child: new Wrap(
                                    children: [
                                      new ListTile(
                                        leading: new Icon(
                                          Icons.delete,
                                          color: kSecondaryColor,
                                        ),
                                        title: new Text(
                                          'Delete message',
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: kSecondaryColor),
                                        ),
                                        onTap: () {
                                          FirebaseFirestore.instance
                                              .runTransaction(
                                            (Transaction myTransaction) async {
                                              myTransaction.delete(snapshot.data
                                                  .documents[index].reference);
                                            },
                                          );
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      } else {
                        return ListTile(
                          title: new Row(
                            children: [
                              buildItem(index, snapshot.data.documents[index]),
                              IconButton(
                                icon: snapshot.data.documents[index]
                                            .data()['react'] ==
                                        0
                                    ? Icon(Icons.favorite_outline_rounded)
                                    : Icon(Icons.favorite_rounded),
                                iconSize: 20.0,
                                color: snapshot.data.documents[index]
                                            .data()['react'] ==
                                        0
                                    ? kColor2
                                    : Colors.red,
                                onPressed: () {
                                  setState(() {});
                                },
                              )
                            ],
                          ),
                          onLongPress: () {
                            print(index);
                            FirebaseFirestore.instance.runTransaction(
                                (Transaction myTransaction) async {
                              snapshot.data.documents[index].reference
                                  .updateData(
                                <String, dynamic>{'react': 1},
                              );
                            });
                          },
                        );
                      }
                    },
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }
}

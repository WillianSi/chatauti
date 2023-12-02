import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class Message {
  final String type;
  final String content;

  Message({required this.type, required this.content});
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<Message> messages = [];
  bool isWaitingForAnswer = false;

  void _launchUrl(String url) async {
    try {
      await launch(url);
    } catch (e) {
      print('Error launching $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ZailTea',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.indigoAccent.shade700,
          actions: [
            IconButton(
              onPressed: clearMessages,
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    Message message = messages[index];
                    return Container(
                      key: ValueKey<String>('message_$index'),
                      margin: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        mainAxisAlignment: message.type == 'question'
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250.0),
                            decoration: BoxDecoration(
                              color: message.type == 'question'
                                  ? Colors.blue
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.all(9.0),
                            child: InkWell(
                              onTap: () {
                                if (message.type == 'answer' &&
                                    Uri.tryParse(message.content)?.isAbsolute ==
                                        true) {
                                  _launchUrl(message.content);
                                }
                              },
                              child: Linkify(
                                onOpen: (link) => _launchUrl(link.url),
                                text: message.content,
                                style: const TextStyle(color: Colors.white),
                                linkStyle:
                                    const TextStyle(color: Colors.blueGrey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintText: 'Digite uma pergunta...',
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.indigoAccent),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.indigoAccent),
                  ),
                  suffixIcon: IconButton(
                    onPressed: isWaitingForAnswer
                        ? null
                        : () {
                            sendPrompt(_textEditingController.text);
                            _textEditingController.clear();
                          },
                    icon: const Icon(Icons.send),
                    color: Colors.indigoAccent.shade700,
                  ),
                ),
                onChanged: (text) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

    @override
  void initState() {
    super.initState();
    addWelcomeMessage();
  }

  void addWelcomeMessage() {
    setState(() {
      messages.add(Message(
        type: 'answer',
        content: 'Olá, sou ZailTea assistente virtual para informar sobre a autismo!',
      ));
    });
  }

  Future<void> sendPrompt(String inputText) async {
    setState(() {
      isWaitingForAnswer = true;
      messages.add(Message(type: 'question', content: inputText));
      scrollToBottom();
    });

    try {
      var url = Uri.parse(
          'https://zaila-language.cognitiveservices.azure.com/language/:query-knowledgebases?projectName=AutiZaila&api-version=2021-10-01&deploymentName=production');

      var subscriptionKey = '1bb05b6289a0497ea06bd1219f1eef3e';

      var headers = {
        'Content-Type': 'application/json',
        'Ocp-Apim-Subscription-Key': subscriptionKey,
      };

      var corpoRequisicao = {
        'question': inputText,
        'top': 1,
      };

      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(corpoRequisicao),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["answers"] != null &&
            responseData["answers"].length > 0) {
          setState(() {
            messages.add(Message(
                type: 'answer', content: responseData["answers"][0]["answer"]));
          });
          scrollToBottom();
        } else {
          setState(() {
            messages.add(Message(
                type: 'answer', content: "Nenhuma resposta encontrada."));
          });
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (error) {
      print("Error: $error");
    } finally {
      setState(() {
        isWaitingForAnswer = false;
      });
    }
  }

  void clearMessages() {
    setState(() {
      messages.clear();
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
      );
    });
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

// نوجل كروم 2027 - تطوير سراج علي
void main() => runApp(const NogleApp());

const homeUrl = 'https://www.google.com';
const chromeUA =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36';

class NogleApp extends StatelessWidget {
  const NogleApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'نوجل كروم 2027',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true, colorSchemeSeed: const Color(0xFF0F9D8A)),
        builder: (c, w) =>
            Directionality(textDirection: TextDirection.rtl, child: w!),
        home: const Browser(),
      );
}

class BTab {
  final WebViewController c;
  String url;
  String title;
  BTab(this.c, this.url, this.title);
}

class Browser extends StatefulWidget {
  const Browser({super.key});
  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  final List<BTab> tabs = [];
  int cur = 0;
  int progress = 100;
  final ctl = TextEditingController();

  @override
  void initState() {
    super.initState();
    addTab(homeUrl);
  }

  bool _isCur(BTab t) => cur < tabs.length && tabs[cur] == t;

  void addTab(String start) {
    late final BTab t;
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(chromeUA)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (u) {
          t.url = u;
          if (_isCur(t)) ctl.text = u;
          if (mounted) setState(() {});
        },
        onProgress: (p) {
          if (_isCur(t) && mounted) setState(() => progress = p);
        },
        onPageFinished: (u) async {
          t.url = u;
          final title = await t.c.getTitle();
          t.title = (title == null || title.isEmpty) ? u : title;
          if (mounted) setState(() {});
        },
      ))
      ..loadRequest(Uri.parse(start));
    t = BTab(c, start, 'تبويب جديد');
    setState(() {
      tabs.add(t);
      cur = tabs.length - 1;
      ctl.text = start;
      progress = 0;
    });
  }

  void go(String q) {
    final s = q.trim();
    if (s.isEmpty) return;
    String u;
    if (s.startsWith('http://') || s.startsWith('https://')) {
      u = s;
    } else if (RegExp(r'^[\w-]+(\.[\w-]+)+(/.*)?$').hasMatch(s)) {
      u = 'https://$s';
    } else {
      u = 'https://www.google.com/search?q=${Uri.encodeQueryComponent(s)}';
    }
    tabs[cur].c.loadRequest(Uri.parse(u));
    FocusScope.of(context).unfocus();
  }

  void closeTab(int i) {
    if (tabs.length == 1) {
      tabs[0].c.loadRequest(Uri.parse(homeUrl));
      return;
    }
    setState(() {
      tabs.removeAt(i);
      if (cur >= tabs.length) cur = tabs.length - 1;
      ctl.text = tabs[cur].url;
    });
  }

  void showTabs() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < tabs.length; i++)
              ListTile(
                selected: i == cur,
                leading: const Icon(Icons.public),
                title: Text(tabs[i].title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(tabs[i].url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                    closeTab(i);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    cur = i;
                    ctl.text = tabs[i].url;
                  });
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('تبويب جديد'),
              onTap: () {
                Navigator.pop(context);
                addTab(homeUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('تسجيل الدخول بحساب جوجل'),
              onTap: () {
                Navigator.pop(context);
                addTab('https://accounts.google.com');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tabs[cur];
    return WillPopScope(
      onWillPop: () async {
        if (await t.c.canGoBack()) {
          await t.c.goBack();
        } else if (tabs.length > 1) {
          closeTab(cur);
        } else {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => t.c.goBack()),
                    IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => t.c.goForward()),
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => t.c.reload()),
                    Expanded(
                      child: TextField(
                        controller: ctl,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        textDirection: TextDirection.ltr,
                        onSubmitted: go,
                        onTap: () => ctl.selection = TextSelection(
                            baseOffset: 0, extentOffset: ctl.text.length),
                        decoration: InputDecoration(
                          hintText: 'ابحث أو اكتب عنوان موقع',
                          isDense: true,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => addTab(homeUrl)),
                    InkWell(
                      onTap: showTabs,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(width: 2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${tabs.length}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              if (progress < 100) LinearProgressIndicator(value: progress / 100),
              Expanded(
                child: IndexedStack(
                  index: cur,
                  children: [
                    for (final x in tabs)
                      WebViewWidget(key: ObjectKey(x), controller: x.c)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

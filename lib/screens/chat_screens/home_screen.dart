import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/chat/custom_user_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> dummyContacts = ['Contact 1', 'Contact 2', 'Contact 3'];

  //TODO: tanggalin mo din to
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      dummyContacts.add('New Contact ${dummyContacts.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      //TODO: tanggalin mo to
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
              Column(
                children: [
                  //--------------------------SIGNTALK LOGO AND USERNAME---------------------------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CustomSigntalkLogo(width: 80, height: 80),
                                  Text(
                                    "Hello, Sung!",
                                    style: TextStyle(
                                      fontSize: AppConstants.fontSizeLarge,
                                      color: AppConstants.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              //--------------------------CIRCLE PFP---------------------------
                              CustomCirclePfpButton(
                                borderColor: AppConstants.white,
                                userImage: null,
                                onPressed: () => context.push(
                                  '/profile_screen',
                                ), // TODO: goto profile screen
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        SearchBar(
                          leading: Icon(Icons.search),
                          hintText: "Search Contact...",
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onChanged: (value) {},
                          onSubmitted: (value) {},
                        ),
                      ],
                    ),
                  ),

                  // ------------------------USER CARD WIDGET CONTIANER----------------------------
                  //listview builder
                  //narerefresh dapat
                  //dapat pagkachat, marebuild tong dynamic content, and masort based sa recent na nagchat, based sa timestamp
                  //may padding
                  //sliaable
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40.0),
                          topRight: Radius.circular(40.0),
                        ),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: dummyContacts.length,
                        itemBuilder: (context, index) {
                          return CustomUserCardWidget();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

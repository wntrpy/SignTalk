import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 2)); // simulate network fetch
    setState(() {
      //TODO: fix
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop(); // go back to previous page in the stack
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: _refresh, //TODO: fix
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        //--------------------------APP BAR PERO CNTAINER---------------------------
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white, // Border color
                                width: 1.5, // Border width
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //--------------------------SIGNTALK LOGO AND USERNAME---------------------------
                              Row(
                                children: [
                                  CustomSigntalkLogo(width: 80, height: 80),
                                  Text(
                                    "Hello, Sung!", //username or first name lang dapat here
                                    style: TextStyle(
                                      fontSize: MyApp.fontSizeLarge,
                                      color: MyApp.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              //--------------------------CIRCLE PFP---------------------------
                              IconButton(
                                onPressed: () {
                                  print(
                                    'Profile picture clicked!',
                                  ); //TODO: fix later = redirect to profile screen
                                },
                                icon: Container(
                                  padding: EdgeInsets.all(2.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(
                                      MyApp.signtalk_bg,
                                    ),
                                    radius: 30,
                                    backgroundColor: MyApp.orange,
                                  ),
                                ),
                                splashRadius: 30, // Adjust ripple effect size
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        //search bar
                        SearchBar(
                          leading: Icon(Icons.search),
                          hintText: "Search Contact...",
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onChanged: (value) {}, //TODO: fix later
                          onSubmitted: (value) {}, //TODO: fix later
                        ),
                      ],
                    ),
                  ),

                  //--------------------------BODY---------------------------
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            40.0,
                          ), // Adjust radius as needed
                          topRight: Radius.circular(
                            40.0,
                          ), // Adjust radius as needed
                        ),
                      ),

                      //--------------------------DITO NA YUNG DYNAMIC CONTENT---------------------------
                      //listview builder
                      //narerefresh dapat
                      //dapat pagkachat, marebuild tong dynamic content, and masort based sa recent na nagchat, based sa timestamp
                      //may padding
                      //sliaable
                      child: Container(),
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

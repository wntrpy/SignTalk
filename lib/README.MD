colors:

- dark violet = 481872
- light violet = 6F22A3
- orange = FF8B00
- red = FF0000

Widgets (reusable UI) so far:

- CUSTOM BUTTON - button na para sa lahat

  - specify yung:
    - text
    - color (red, white, orange) refer nalang sa colors sa taas
    - size (w and h)
    - function
    - icon (OPTIONAL)
    - textColor (OPTIONAL)
  - example paano gamitin:
    - CustomButton(
      buttonText: 'Submit',
      colorCode: myApp,
      buttonWidth: 200,
      buttonHeight: 50,
      onPressed: () {},
      icon: MyApp.imagePath, (OPTIONAL, kapag need lang ng image)
      ),

- ## CUSTOM TEXTFIELD (WHITE)

signtalk/ - MAIN FOLDER
│
│ ├── lib/ FRONTEND FOLDER
│ │ ├── main.dart # first screen (pedeng splash screen to) - starting point
│ │ ├── core/ # helper classes, and anything na magagamit natin sa buong UI
│ │ ├── providers/ # for state management using riverpod
│ │ ├── notifiers/ # LAHAT NG FUNCTION NA MAGAGAMIT NI PROVIDER(riverpod) NANDITO (PARA MALINIS ANG CODE AND SEPARATION OF CONCERNS)
│ │ ├── services/ # any code na nag communicate with backend
│ │ ├── models/ # dito lahat ng data models (templates)
│ │ ├── screens/ # pages/screens
│ │ ├── widgets/ # reusable UI (ex. AlertDialog, Button) para hindi paulit-ulit code
│ │ └── firebase/ # placeholder for now
│ ├── pubspec.yaml # flutter dependencies (built in to sa flutter codebase)
│ └── README.md # front end specific documentation (optional)
│
├── backend/ # python server
│ ├── app.py # starting point, initializes everything, and pang-start ng python server(localhost for now using flask?)
│ ├── api/ # api endpoints
│ │ ├── translate.py (example)
│ ├── services/ # nandito lahat ng core logic ng app(translation, camera-input processing)
│ │ └── translator.py(example)
│ ├── models/ # helpers (in case), idk paano pa gagamitin to
│ ├── requirements.txt # list of py libraries na gagamitin (para hindi malito)
│ ├── config.py # api keys..
│ └── README.md # back end specific documentation (optional)
│
├── assets/ # images, logos, avatars, animations???
│
├── .gitignore # ignore anything na important sa code natin (API keys) (hindi pa siguro need for now)
└── README.md # MAIN DOCUMENTATION (setup, how to use)

Splash screen
login screen
registration screen / sign up screen
forget password screen 1 (enter email of the account)
forget password screen 2 (verification)
forget password screen 3 (new and confirm password)
new user welcome screen

home screen(message tab active) (with message(if existing user and has messaged anyone before) or none (new user))
home screen(contacts tab active) (show list of contacts)
home screen (search screen?)
conversation screen

User profile screen
Settings screen
feedback screen
blocked list screen
ASL and FSL alphabet chart screen

Other end(user profile settings screen) the one the user is talking to

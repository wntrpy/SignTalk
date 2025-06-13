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

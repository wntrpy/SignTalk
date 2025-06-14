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

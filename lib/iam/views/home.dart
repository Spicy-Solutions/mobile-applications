import 'package:flutter/material.dart';

class HomeView extends StatelessWidget{
  
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_home.png'),
            fit: BoxFit.cover,
          ),
        ),
         child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: SweetManagerCardHome(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SweetManagerCardHome extends StatelessWidget
{

  const SweetManagerCardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 24
      ),
       child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.ltr,
         children: <Widget>[
          const Text(
                'Sweet Manager',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Optimize your hotel management and offer exceptional guest experiences!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 5, 47, 118),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
         ],
       ),
    );
  }

}
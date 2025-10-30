import 'dart:ui';
import 'package:flutter/material.dart';

class ListeningMainScreen extends StatelessWidget{
  const ListeningMainScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Listening')),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _ListeningModuleButton(
                label: 'predicting answers',
                ontap: () => Navigator.of(context).pushNamed('/skills/listening/listeningmodule_1'),
                color1: const Color.fromARGB(255, 63, 225, 68).withOpacity(0.4),
                color2: const Color.fromARGB(255, 60, 91, 76).withOpacity(0.4),
              ),
              SizedBox(height: 60),
              _ListeningModuleButton(
                label: 'note-taking',
                ontap: () => Navigator.of(context).pushNamed('/skills/listening/listeningmodule_1'),
                color1: const Color.fromARGB(255, 63, 225, 68).withOpacity(0.4),
                color2: const Color.fromARGB(255, 60, 91, 76).withOpacity(0.4),
              ),
              SizedBox(height: 60),
              _ListeningModuleButton(
                label: 'focusing on distractors',
                ontap: () => Navigator.of(context).pushNamed('/skills/listening/listeningmodule_1'),
                color1: const Color.fromARGB(255, 63, 225, 68).withOpacity(0.4),
                color2: const Color.fromARGB(255, 60, 91, 76).withOpacity(0.4),
              ),
              SizedBox(height: 60),
            ]
          ),
        ]
      ),
    );
  }
}

class _ListeningModuleButton extends StatelessWidget {
  final String label;
  final VoidCallback ontap;
  final Color color1;
  final Color color2;


  const _ListeningModuleButton({
    required this.label,
    required this.ontap,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context){
    return InkWell(
      onTap: ontap,
      borderRadius: BorderRadius.circular(24),
      splashColor: Colors.white.withOpacity(0.7),
      child: Container(
        width: 200,
        height: 124,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x4082CEFF),
              blurRadius: 18,
              offset: Offset(0, 8),
            )
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
         ),
       ),
      ),
    );
  }
}
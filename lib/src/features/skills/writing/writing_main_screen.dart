import 'dart:ui';
import 'package:flutter/material.dart';

class WritingMainScreen extends StatelessWidget{
  const WritingMainScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Writing')),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _WritingModuleButton(
                label: 'essay structures',
                ontap: () => Navigator.of(context).pushNamed('/skills/writing/writingmodule_1'),
                color1: const Color.fromARGB(255, 99, 181, 248).withOpacity(0.4),
                color2: const Color.fromARGB(255, 1, 99, 89).withOpacity(0.4),
              ),
              SizedBox(height: 60),
              _WritingModuleButton(
                label: 'paraphrasing',
                ontap: () => Navigator.of(context).pushNamed('/skills/writing/writingmodule_1'),
                color1: const Color.fromARGB(255, 99, 181, 248).withOpacity(0.4),
                color2: const Color.fromARGB(255, 1, 99, 89).withOpacity(0.4),
              ),
              SizedBox(height: 60),
              _WritingModuleButton(
                label: 'linking devices',
                ontap: () => Navigator.of(context).pushNamed('/skills/writing/writingmodule_1'),
                color1: const Color.fromARGB(255, 99, 181, 248).withOpacity(0.4),
                color2: const Color.fromARGB(255, 1, 99, 89).withOpacity(0.4),
              ),
              SizedBox(height: 60),
            ]
          ),
        ]
      ),
    );
  }
}

class _WritingModuleButton extends StatelessWidget {
  final String label;
  final VoidCallback ontap;
  final Color color1;
  final Color color2;


  const _WritingModuleButton({
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
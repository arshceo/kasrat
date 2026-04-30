import 'package:flutter/material.dart';

class Protocol {
  final String id;
  final String title;
  final int durationDays;
  final String difficulty;
  final IconData bgIcon;
  final String exerciseFocus;
  final List<String> outcomes;
  final List<String> exercises;
  final List<String> instructions;
  final String description;
  final List<String> tags;
  final String imagePath;
  final bool isRecommended;

  const Protocol({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.difficulty,
    required this.bgIcon,
    required this.exerciseFocus,
    required this.outcomes,
    required this.exercises,
    required this.instructions,
    required this.description,
    required this.tags,
    required this.imagePath,
    this.isRecommended = false,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'durationDays': durationDays,
      'difficulty': difficulty,
      'bgIconCode': bgIcon.codePoint,
      'exerciseFocus': exerciseFocus,
      'outcomes': outcomes,
      'exercises': exercises,
      'instructions': instructions,
      'description': description,
      'tags': tags,
      'imagePath': imagePath,
      'isRecommended': isRecommended,
    };
  }
}

const List<Protocol> staticProtocols = [
  Protocol(
    id: 'base_recruit',
    title: 'RECRUIT CALISTHENICS',
    durationDays: 28,
    difficulty: 'NOVICE',
    bgIcon: Icons.shield,
    exerciseFocus: 'FOUNDATION',
    outcomes: ['Baseline Strength', 'Form Mastery', 'Mental Fortitude'],
    exercises: ['Pushups', 'Squats', 'Plank'],
    instructions: [
      'Maintain strict form above all else.',
      'Record your sets truthfully.',
      'Embrace the discomfort of consistency.'
    ],
    description: 'The foundation of all combat readiness. Master your bodyweight before you master the battlefield.',
    tags: ['MILITARY PREP', 'BODYWEIGHT', 'CORE'],
    imagePath: 'assets/images/placeholder.png',
    isRecommended: true,
  ),
  Protocol(
    id: 'iron_core',
    title: 'IRON CORE DIRECTIVE',
    durationDays: 21,
    difficulty: 'HARDENED',
    bgIcon: Icons.security,
    exerciseFocus: 'MIDSECTION',
    outcomes: ['Core Armor', 'Posture Resilience', 'Tactical Balance'],
    exercises: ['Plank', 'Squats', 'Wall Sit'],
    instructions: [
      'Breathe through the holds.',
      'Emphasize depth on every squat.',
      'Do not break position early.'
    ],
    description: 'A brutal regimen focused on unbreakable core strength and lower body endurance.',
    tags: ['ABDOMINALS', 'ENDURANCE', 'STATIC HOLDS'],
    imagePath: 'assets/images/placeholder.png',
  ),
  Protocol(
    id: 'stealth_operator',
    title: 'STEALTH OPERATOR',
    durationDays: 14,
    difficulty: 'ELITE',
    bgIcon: Icons.visibility_off,
    exerciseFocus: 'FULL BODY',
    outcomes: ['Explosive Power', 'Rapid Recovery', 'Agility'],
    exercises: ['Pushups', 'Lunges', 'Squats'],
    instructions: [
      'Minimize rest time between sets.',
      'Control the eccentric phase.',
      'Explode upwards on every rep.'
    ],
    description: 'High frequency, high intensity. Designed for quick deployments and maximum physical output.',
    tags: ['HIIT', 'AGILITY', 'POWER'],
    imagePath: 'assets/images/placeholder.png',
  ),
];

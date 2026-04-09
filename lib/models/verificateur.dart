// lib/models/verificateur.dart
import 'package:hive/hive.dart';

part 'verificateur.g.dart';

@HiveType(typeId: 0)
class Verificateur extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String prenom;

  @HiveField(3)
  String email;        // ← Email comme identifiant principal

  @HiveField(4)
  String password;

  @HiveField(5)
  String matricule;

  @HiveField(6)
  DateTime createdAt;

  Verificateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.matricule,
    required this.createdAt,
  });

  factory Verificateur.fromJson(Map<String, dynamic> json) {
    return Verificateur(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      matricule: json['matricule'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      'matricule': matricule,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullName => '$prenom $nom';
}
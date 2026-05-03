/// Model representing a core person record in the [persons] table.
class PersonModel {
  final String uniqueId;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // ISO 8601 string
  final String placeOfBirth;
  final String nationality;
  final String gender;
  final String personalEmail;
  final String phoneNumber;
  final String userType;
  final String status;
  final String createdAt; // ISO 8601 string
  final bool isAlumni;
  final int? graduationYear;

  const PersonModel({
    required this.uniqueId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.nationality,
    required this.gender,
    required this.personalEmail,
    required this.phoneNumber,
    required this.userType,
    required this.status,
    required this.createdAt,
    this.isAlumni = false,
    this.graduationYear,
  });

  /// Creates a PersonModel from a sqflite row map.
  factory PersonModel.fromMap(Map<String, dynamic> map) => PersonModel(
        uniqueId:      map['uniqueId'] as String,
        firstName:     map['firstName'] as String,
        lastName:      map['lastName'] as String,
        dateOfBirth:   map['dateOfBirth'] as String,
        placeOfBirth:  map['placeOfBirth'] as String,
        nationality:   map['nationality'] as String,
        gender:        map['gender'] as String,
        personalEmail: map['personalEmail'] as String,
        phoneNumber:   map['phoneNumber'] as String,
        userType:      map['userType'] as String,
        status:        map['status'] as String,
        createdAt:     map['createdAt'] as String,
        isAlumni:      (map['isAlumni'] as int? ?? 0) == 1,
        graduationYear: map['graduationYear'] as int?,
      );

  /// Converts this model to a sqflite-compatible map.
  Map<String, dynamic> toMap() => {
        'uniqueId':      uniqueId,
        'firstName':     firstName,
        'lastName':      lastName,
        'dateOfBirth':   dateOfBirth,
        'placeOfBirth':  placeOfBirth,
        'nationality':   nationality,
        'gender':        gender,
        'personalEmail': personalEmail,
        'phoneNumber':   phoneNumber,
        'userType':      userType,
        'status':        status,
        'createdAt':     createdAt,
        'isAlumni':      isAlumni ? 1 : 0,
        'graduationYear': graduationYear,
      };

  /// Returns a copy of this model with the specified fields replaced.
  PersonModel copyWith({
    String? status,
    bool? isAlumni,
    int? graduationYear,
    String? firstName,
    String? lastName,
    String? placeOfBirth,
    String? nationality,
    String? gender,
    String? personalEmail,
    String? phoneNumber,
  }) =>
      PersonModel(
        uniqueId:      uniqueId,
        firstName:     firstName ?? this.firstName,
        lastName:      lastName ?? this.lastName,
        dateOfBirth:   dateOfBirth,
        placeOfBirth:  placeOfBirth ?? this.placeOfBirth,
        nationality:   nationality ?? this.nationality,
        gender:        gender ?? this.gender,
        personalEmail: personalEmail ?? this.personalEmail,
        phoneNumber:   phoneNumber ?? this.phoneNumber,
        userType:      userType,
        status:        status ?? this.status,
        createdAt:     createdAt,
        isAlumni:      isAlumni ?? this.isAlumni,
        graduationYear: graduationYear ?? this.graduationYear,
      );

  /// Full name convenience getter.
  String get fullName => '$firstName $lastName';
}

// models/travel_agency_model.dart
import 'package:json_annotation/json_annotation.dart';

class TravelAgency {
  final String id;
  final String userId;
  final String agencyName;
  final String ownerFullName;
  final String ownerEmail;
  final String ownerPhone;
  final String? officeAddress;
  final String? officePhone;

  final String? businessLicenseNumber;
  final String? taxId;
  final String? websiteUrl;

  // Document URLs
  final String? businessLicenseUrl;
  final String? taxCertificateUrl;
  final String? insuranceCertificateUrl;

  // Financial
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankName;
  final String? branchName;
  final double commissionRate;

  // Verification
  final String
      verificationStatus; // 'waiting', 'approved', 'rejected', 'suspended'
  final String? verificationNotes;
  final bool otpVerified;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? verifiedAt;
  final DateTime? otpVerifiedAt;

  TravelAgency({
    required this.id,
    required this.userId,
    required this.agencyName,
    required this.ownerFullName,
    required this.ownerEmail,
    required this.ownerPhone,
    this.officeAddress,
    this.officePhone,
    this.businessLicenseNumber,
    this.taxId,
    this.websiteUrl,
    this.businessLicenseUrl,
    this.taxCertificateUrl,
    this.insuranceCertificateUrl,
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankName,
    this.branchName,
    this.commissionRate = 5.0,
    required this.verificationStatus,
    this.verificationNotes,
    required this.otpVerified,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedAt,
    this.otpVerifiedAt,
  });

  factory TravelAgency.fromJson(Map<String, dynamic> json) {
    return TravelAgency(
      id: json['id'] as String,
      userId: json['userId'] as String,
      agencyName: json['agencyName'] as String,
      ownerFullName: json['ownerFullName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      ownerPhone: json['ownerPhone'] as String,
      officeAddress: json['officeAddress'] as String?,
      officePhone: json['officePhone'] as String?,
      businessLicenseNumber: json['businessLicenseNumber'] as String?,
      taxId: json['taxId'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      businessLicenseUrl: json['businessLicenseUrl'] as String?,
      taxCertificateUrl: json['taxCertificateUrl'] as String?,
      insuranceCertificateUrl: json['insuranceCertificateUrl'] as String?,
      bankAccountHolder: json['bankAccountHolder'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankName: json['bankName'] as String?,
      branchName: json['branchName'] as String?,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 5.0,
      verificationStatus: json['verificationStatus'] as String,
      verificationNotes: json['verificationNotes'] as String?,
      otpVerified: json['otpVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      otpVerifiedAt: json['otpVerifiedAt'] == null
          ? null
          : DateTime.parse(json['otpVerifiedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'agencyName': agencyName,
        'ownerFullName': ownerFullName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'officeAddress': officeAddress,
        'officePhone': officePhone,
        'businessLicenseNumber': businessLicenseNumber,
        'taxId': taxId,
        'websiteUrl': websiteUrl,
        'businessLicenseUrl': businessLicenseUrl,
        'taxCertificateUrl': taxCertificateUrl,
        'insuranceCertificateUrl': insuranceCertificateUrl,
        'bankAccountHolder': bankAccountHolder,
        'bankAccountNumber': bankAccountNumber,
        'bankName': bankName,
        'branchName': branchName,
        'commissionRate': commissionRate,
        'verificationStatus': verificationStatus,
        'verificationNotes': verificationNotes,
        'otpVerified': otpVerified,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'otpVerifiedAt': otpVerifiedAt?.toIso8601String(),
      };

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'waiting';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isSuspended => verificationStatus == 'suspended';

  bool get canLogin => isApproved && otpVerified;
  bool get needsOtpVerification => isApproved && !otpVerified;

  TravelAgency copyWith({
    String? id,
    String? userId,
    String? agencyName,
    String? ownerFullName,
    String? ownerEmail,
    String? ownerPhone,
    String? officeAddress,
    String? officePhone,
    String? businessLicenseNumber,
    String? taxId,
    String? websiteUrl,
    String? businessLicenseUrl,
    String? taxCertificateUrl,
    String? insuranceCertificateUrl,
    String? bankAccountHolder,
    String? bankAccountNumber,
    String? bankName,
    String? branchName,
    double? commissionRate,
    String? verificationStatus,
    String? verificationNotes,
    bool? otpVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? verifiedAt,
    DateTime? otpVerifiedAt,
  }) {
    return TravelAgency(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agencyName: agencyName ?? this.agencyName,
      ownerFullName: ownerFullName ?? this.ownerFullName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      officeAddress: officeAddress ?? this.officeAddress,
      officePhone: officePhone ?? this.officePhone,
      businessLicenseNumber:
          businessLicenseNumber ?? this.businessLicenseNumber,
      taxId: taxId ?? this.taxId,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      businessLicenseUrl: businessLicenseUrl ?? this.businessLicenseUrl,
      taxCertificateUrl: taxCertificateUrl ?? this.taxCertificateUrl,
      insuranceCertificateUrl:
          insuranceCertificateUrl ?? this.insuranceCertificateUrl,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      commissionRate: commissionRate ?? this.commissionRate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      otpVerified: otpVerified ?? this.otpVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      otpVerifiedAt: otpVerifiedAt ?? this.otpVerifiedAt,
    );
  }
}

class AgencyDocument {
  final String id;
  final String agencyId;
  final String documentType; // 'license', 'tax', 'insurance', 'bank_statement'
  final String documentUrl;
  final String? fileName;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final String? rejectedReason;
  final DateTime createdAt;

  AgencyDocument({
    required this.id,
    required this.agencyId,
    required this.documentType,
    required this.documentUrl,
    this.fileName,
    required this.verificationStatus,
    this.rejectedReason,
    required this.createdAt,
  });

  factory AgencyDocument.fromJson(Map<String, dynamic> json) {
    return AgencyDocument(
      id: json['id'] as String,
      agencyId: json['agencyId'] as String,
      documentType: json['documentType'] as String,
      documentUrl: json['documentUrl'] as String,
      fileName: json['fileName'] as String?,
      verificationStatus: json['verificationStatus'] as String,
      rejectedReason: json['rejectedReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agencyId': agencyId,
        'documentType': documentType,
        'documentUrl': documentUrl,
        'fileName': fileName,
        'verificationStatus': verificationStatus,
        'rejectedReason': rejectedReason,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
}

@JsonSerializable()
class AgencyRegistrationRequest {
  final String agencyName;
  final String ownerFullName;
  final String ownerEmail;
  final String ownerPhone;
  final String password;
  final String officeAddress;
  final String? officePhone;
  final String? businessLicenseNumber;
  final String? taxId;
  final String? websiteUrl;
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankName;
  final String? branchName;

  AgencyRegistrationRequest({
    required this.agencyName,
    required this.ownerFullName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.password,
    required this.officeAddress,
    this.officePhone,
    this.businessLicenseNumber,
    this.taxId,
    this.websiteUrl,
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankName,
    this.branchName,
  });

  factory AgencyRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return AgencyRegistrationRequest(
      agencyName: json['agencyName'] as String,
      ownerFullName: json['ownerFullName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      ownerPhone: json['ownerPhone'] as String,
      password: json['password'] as String,
      officeAddress: json['officeAddress'] as String,
      officePhone: json['officePhone'] as String?,
      businessLicenseNumber: json['businessLicenseNumber'] as String?,
      taxId: json['taxId'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      bankAccountHolder: json['bankAccountHolder'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankName: json['bankName'] as String?,
      branchName: json['branchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'agencyName': agencyName,
        'ownerFullName': ownerFullName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'password': password,
        'officeAddress': officeAddress,
        'officePhone': officePhone,
        'businessLicenseNumber': businessLicenseNumber,
        'taxId': taxId,
        'websiteUrl': websiteUrl,
        'bankAccountHolder': bankAccountHolder,
        'bankAccountNumber': bankAccountNumber,
        'bankName': bankName,
        'branchName': branchName,
      };
}

// models/travel_agency_model.dart
// models/travel_agency_model.dart - FIXED VERSION
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
      // ✅ FIXED: Map database snake_case to Dart camelCase
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '', // ✅ Changed from 'userId'
      agencyName:
          json['agency_name'] as String? ?? '', // ✅ Changed from 'agencyName'
      ownerFullName: json['owner_full_name'] as String? ??
          '', // ✅ Changed from 'ownerFullName'
      ownerEmail:
          json['owner_email'] as String? ?? '', // ✅ Changed from 'ownerEmail'
      ownerPhone:
          json['owner_phone'] as String? ?? '', // ✅ Changed from 'ownerPhone'

      officeAddress:
          json['office_address'] as String?, // ✅ Changed from 'officeAddress'
      officePhone:
          json['office_phone'] as String?, // ✅ Changed from 'officePhone'

      businessLicenseNumber:
          json['business_license_number'] as String?, // ✅ Changed
      taxId: json['tax_id'] as String?, // ✅ Changed from 'taxId'
      websiteUrl: json['website_url'] as String?, // ✅ Changed from 'websiteUrl'

      businessLicenseUrl: json['business_license_url'] as String?, // ✅ Changed
      taxCertificateUrl: json['tax_certificate_url'] as String?, // ✅ Changed
      insuranceCertificateUrl:
          json['insurance_certificate_url'] as String?, // ✅ Changed

      bankAccountHolder: json['bank_account_holder'] as String?, // ✅ Changed
      bankAccountNumber: json['bank_account_number'] as String?, // ✅ Changed
      bankName: json['bank_name'] as String?, // ✅ Changed from 'bankName'
      branchName: json['branch_name'] as String?, // ✅ Changed from 'branchName'

      commissionRate:
          (json['commission_rate'] as num?)?.toDouble() ?? 5.0, // ✅ Changed

      verificationStatus:
          json['verification_status'] as String? ?? 'approved', // ✅ Changed
      verificationNotes: json['verification_notes'] as String?, // ✅ Changed
      otpVerified: (json['otp_verified'] as bool?) ?? false, // ✅ Changed

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // ✅ Added fallback
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(), // ✅ Added fallback
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      otpVerifiedAt:
          json['otp_verified_at'] == null // ✅ Changed from 'otpVerifiedAt'
              ? null
              : DateTime.parse(json['otp_verified_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId, // ✅ Changed from 'userId'
        'agency_name': agencyName, // ✅ Changed from 'agencyName'
        'owner_full_name': ownerFullName, // ✅ Changed from 'ownerFullName'
        'owner_email': ownerEmail, // ✅ Changed from 'ownerEmail'
        'owner_phone': ownerPhone, // ✅ Changed from 'ownerPhone'
        'office_address': officeAddress, // ✅ Changed from 'officeAddress'
        'office_phone': officePhone, // ✅ Changed from 'officePhone'
        'business_license_number': businessLicenseNumber, // ✅ Changed
        'tax_id': taxId, // ✅ Changed from 'taxId'
        'website_url': websiteUrl, // ✅ Changed from 'websiteUrl'
        'business_license_url': businessLicenseUrl, // ✅ Changed
        'tax_certificate_url': taxCertificateUrl, // ✅ Changed
        'insurance_certificate_url': insuranceCertificateUrl, // ✅ Changed
        'bank_account_holder': bankAccountHolder, // ✅ Changed
        'bank_account_number': bankAccountNumber, // ✅ Changed
        'bank_name': bankName, // ✅ Changed from 'bankName'
        'branch_name': branchName, // ✅ Changed from 'branchName'
        'commission_rate': commissionRate, // ✅ Changed
        'verification_status': verificationStatus, // ✅ Changed
        'verification_notes': verificationNotes, // ✅ Changed
        'otp_verified': otpVerified, // ✅ Changed
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'verified_at': verifiedAt?.toIso8601String(),
        'otp_verified_at': otpVerifiedAt?.toIso8601String(), // ✅ Changed
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
      id: json['id'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '', // ✅ Changed from 'agencyId'
      documentType: json['document_type'] as String? ?? '', // ✅ Changed
      documentUrl: json['document_url'] as String? ?? '', // ✅ Changed
      fileName: json['file_name'] as String?, // ✅ Changed from 'fileName'
      verificationStatus:
          json['verification_status'] as String? ?? 'pending', // ✅ Changed
      rejectedReason: json['rejected_reason'] as String?, // ✅ Changed
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agency_id': agencyId, // ✅ Changed from 'agencyId'
        'document_type': documentType, // ✅ Changed
        'document_url': documentUrl, // ✅ Changed
        'file_name': fileName, // ✅ Changed from 'fileName'
        'verification_status': verificationStatus, // ✅ Changed
        'rejected_reason': rejectedReason, // ✅ Changed
        'created_at': createdAt.toIso8601String(),
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

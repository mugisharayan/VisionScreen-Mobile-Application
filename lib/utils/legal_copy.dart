class LegalSectionData {
  const LegalSectionData({
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;
}

const termsOfServiceSections = <LegalSectionData>[
  LegalSectionData(
    heading: '1. Purpose',
    body:
        'VisionScreen supports community vision screening, local patient record keeping, referrals, and follow-up within organised screening programmes.',
  ),
  LegalSectionData(
    heading: '2. Intended Use',
    body:
        'Use the app only as part of a trained screening workflow. It is intended for CHWs, supervised trainees, and programme staff working under local clinical supervision.',
  ),
  LegalSectionData(
    heading: '3. Screening Limits',
    body:
        'VisionScreen is a screening tool, not a diagnostic instrument. Results indicate whether a patient should be referred for further assessment. The app does not diagnose disease, prescribe treatment, or replace clinical judgement.',
  ),
  LegalSectionData(
    heading: '4. Data Handling',
    body:
        'Before collecting patient data, obtain consent and explain why the screening is being done. Users are responsible for handling records according to their programme policies and local law.',
  ),
  LegalSectionData(
    heading: '5. Build Limits',
    body:
        'Some features depend on the current build and deployment configuration. Sync, backup, export, and security controls should be understood in the context of the environment where the app is deployed.',
  ),
  LegalSectionData(
    heading: '6. Updates',
    body:
        'VisionScreen may change over time as workflows, devices, and programme needs change. Continuing to use the app means using the current version as provided.',
  ),
];

const privacyPolicySections = <LegalSectionData>[
  LegalSectionData(
    heading: '1. Data We Collect',
    body:
        'VisionScreen may store patient registration details, screening results, referral details, CHW profile information, workspace metadata, and limited device data needed for camera, location, calibration, export, backup, and sync features.',
  ),
  LegalSectionData(
    heading: '2. How We Use It',
    body:
        'Data is used to run screenings, generate referrals and reports, support follow-up, and keep the app functioning for the current workspace or programme.',
  ),
  LegalSectionData(
    heading: '3. Storage and Recovery',
    body:
        'Data is stored locally on the device in SQLite. When configured for the build, records may also be backed up or synchronized to a shared workspace database.',
  ),
  LegalSectionData(
    heading: '4. Sharing',
    body:
        'VisionScreen does not share records outside the current device or configured workspace unless a user explicitly exports or sends them.',
  ),
  LegalSectionData(
    heading: '5. User Choices',
    body:
        'Programme staff should collect consent before screening. Patients or programme administrators can update or remove local records using the controls available in the app and any governing programme process.',
  ),
  LegalSectionData(
    heading: '6. Contact',
    body:
        'For questions about a deployment, contact the programme lead, facility administrator, or workspace owner responsible for that installation.',
  ),
];

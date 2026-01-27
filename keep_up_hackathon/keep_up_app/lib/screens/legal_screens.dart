import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      appBar: AppBar(
        title: Text(
          "Terms of Service",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last Updated: January 19, 2026",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome to KeepUp! By using our application, you agree to the following terms and conditions.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 20),

            _buildSection(
              "1. Acceptance of Terms",
              "By downloading, installing, or using the KeepUp application (\"App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, please do not use the App.",
            ),

            _buildSection(
              "2. Age Requirements",
              "KeepUp is designed for users aged 13 years and older. By using this App, you confirm that you are at least 13 years of age. Users under 18 should have parental/guardian consent before using the App.",
            ),

            _buildSection(
              "3. Child Safety Policy",
              "3.1 Zero Tolerance for CSAM\nKeepUp maintains ZERO TOLERANCE for Child Sexual Abuse Material (CSAM). We will immediately remove content, ban users, and report to NCMEC and law enforcement.\n\n"
                  "3.2 Content Restrictions\nStrictly prohibited: Content that sexualizes or endangers minors, grooming behaviors, and predatory behavior.\n\n"
                  "3.3 Reporting\nReport violations immediately to safety@keepup.app.",
            ),

            _buildSection(
              "4. Prohibited Content",
              "4.1 Harmful Content\nSexual content, graphic violence, hate speech, self-harm promotion, bullying.\n\n"
                  "4.2 Dangerous Information\nWeapons instructions, illegal acts, malware.\n\n"
                  "4.3 Body Image & Health\nEating disorders promotion, health misinformation.\n\n"
                  "4.4 Deceptive Content\nDeepfakes, fraud, impersonation.",
            ),

            _buildSection(
              "5. AI-Generated Content Disclaimer",
              "KeepUp uses AI to summarize news. AI content may contain errors. Users should verify information from primary sources. KeepUp is not responsible for AI inaccuracies.",
            ),

            _buildSection(
              "6. User Conduct",
              "You agree to use the App lawfully, respect others, and not circumvent safety measures.",
            ),

            _buildSection(
              "7. Account Termination",
              "We may suspend accounts that violate these Terms or engage in illegal activities.",
            ),

            _buildSection(
              "8. Privacy",
              "Your use is governed by our Privacy Policy.",
            ),

            _buildSection(
              "9. Changes to Terms",
              "We may update these Terms. Continued use implies acceptance.",
            ),

            _buildSection(
              "10. Contact Information",
              "General: support@keepup.app\nSafety: safety@keepup.app\nCSAM reports go to NCMEC.",
            ),

            _buildSection(
              "11. Disclaimer of Warranties",
              "THE APP IS PROVIDED \"AS IS\" WITHOUT WARRANTIES OF ANY KIND.",
            ),

            _buildSection(
              "12. Limitation of Liability",
              "KEEPUP SHALL NOT BE LIABLE FOR INDIRECT OR CONSEQUENTIAL DAMAGES.",
            ),

            const Divider(height: 40),
            Text(
              "By using KeepUp, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      appBar: AppBar(
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last Updated: January 19, 2026",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "This Privacy Policy describes how KeepUp collects, uses, and protects your information.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 20),

            _buildSection(
              "1. Information We Collect",
              "1.1 Information You Provide\nEmail, username, quiz progress, feedback.\n\n"
                  "1.2 Automatically Collected\nDevice info, app usage, crash reports.\n\n"
                  "1.3 We Do NOT Collect\nPrecise location, phone numbers, personal photos, financial info (unless purchasing).",
            ),

            _buildSection(
              "2. How We Use Your Information",
              "To provide the service, personalize experience, track progress, send updates, and ensure safety.",
            ),

            _buildSection(
              "3. Children's Privacy",
              "3.1 Age Restrictions\nKeepUp is for users 13+. We do not knowingly collect info from under 13s.\n\n"
                  "3.2 Parental Notice\nContact privacy@keepup.app if you believe a child under 13 provided info.\n\n"
                  "3.3 COPPA Compliance\nWe comply with COPPA and similar regulations.",
            ),

            _buildSection(
              "4. Data Sharing",
              "We do NOT sell personal information. We share with service providers (hosting, analytics) and for legal/safety reasons (NCMEC).",
            ),

            _buildSection(
              "5. Data Security",
              "Encryption, security audits, access controls, secure storage.",
            ),

            _buildSection(
              "6. Your Rights",
              "Access, correction, deletion, opt-out, export. Contact privacy@keepup.app.",
            ),

            _buildSection(
              "7. Data Retention",
              "Retained only as necessary. Deletion available at any time.",
            ),

            _buildSection(
              "8. Third-Party Services",
              "Google Cloud/Vertex AI, Firebase, Analytics providers. Each has their own privacy policy.",
            ),

            _buildSection(
              "9. Changes",
              "We may update this policy and will notify you of significant changes.",
            ),

            _buildSection(
              "10. Contact Us",
              "Email: privacy@keepup.app\nSupport: support@keepup.app",
            ),

            const Divider(height: 40),
            Text(
              "KeepUp - Your Privacy Matters",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

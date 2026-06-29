import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTermsScreen extends StatelessWidget {
  const AppTermsScreen({super.key});

  static const _lastUpdated = 'June 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('EasyQuote — Terms & Conditions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Last updated: $_lastUpdated', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
          const SizedBox(height: 20),
          ..._sections.map(_buildSection),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(_TermsSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 6),
          Text(section.body, style: const TextStyle(fontSize: 12.5, height: 1.55, color: AppColors.ink)),
        ],
      ),
    );
  }

  static final List<_TermsSection> _sections = [
    _TermsSection(
      'EDIT BEFORE PUBLISHING THIS NOTICE',
      'This document is a general-purpose template intended to satisfy the baseline '
          'requirements of app marketplaces such as Google Play, and to give users a fair, '
          'plain description of how the App may be used. It is provided for convenience and '
          'does not constitute legal advice. Before publishing this App to any public app '
          'store, you should have this text (and the accompanying Privacy Policy) reviewed by '
          'a qualified legal professional familiar with applicable consumer-protection, '
          'data-protection, and e-commerce regulations in your jurisdiction, and you should '
          'insert your own legal entity name, registered address, and contact details wherever '
          'placeholders such as "[Developer/Company Name]" appear below.',
    ),
    _TermsSection(
      '1. Acceptance of Terms',
      'These Terms & Conditions ("Terms") constitute a legally binding agreement between '
          'you ("User," "you," or "your") and [Developer/Company Name] ("we," "us," "our," or '
          'the "Developer"), governing your access to and use of the EasyQuote mobile '
          'application (the "App"), including all related documentation, updates, and '
          'associated services. By downloading, installing, accessing, or otherwise using the '
          'App, you acknowledge that you have read, understood, and agree to be bound by these '
          'Terms in their entirety, as well as any policies referenced herein, including our '
          'Privacy Policy. If you do not agree with any provision of these Terms, you must '
          'immediately discontinue use of the App and uninstall it from your device. Continued '
          'use of the App following any modification to these Terms shall constitute your '
          'binding acceptance of such modifications.',
    ),
    _TermsSection(
      '2. Eligibility and Permitted Use',
      'The App is intended for use by individuals and business entities for the purpose of '
          'creating, managing, and exporting quotations and invoices in connection with their '
          'own commercial activities. By using the App, you represent and warrant that you '
          'possess the legal capacity and authority to enter into this agreement, whether on '
          'your own behalf or on behalf of a business entity you are authorized to represent. '
          'You agree to use the App solely for lawful purposes and in a manner consistent with '
          'all applicable local, state, national, and international laws and regulations, '
          'including but not limited to those governing taxation, commercial documentation, '
          'consumer protection, and data privacy. Any use of the App to generate fraudulent, '
          'misleading, or unlawful documents, including but not limited to forged invoices, '
          'tax evasion instruments, or documents intended to deceive any third party, is '
          'strictly prohibited and may result in immediate termination of your right to use '
          'the App, in addition to any other remedies available to the Developer or to '
          'affected third parties under applicable law.',
    ),
    _TermsSection(
      '3. Local Data Storage; No Account Required',
      'The App is designed to operate primarily, and in most configurations entirely, in an '
          'offline capacity. All data that you create or input within the App — including, '
          'without limitation, company profile information, client records, catalog items, '
          'terms and conditions templates, quotations, invoices, and any associated images '
          'such as logos, signatures, or stamps — is stored locally on the storage medium of '
          'the device on which the App is installed. The Developer does not operate, '
          'maintain, or have access to any central server, cloud database, or other remote '
          'repository through which such data is transmitted, collected, aggregated, or '
          'otherwise processed by the Developer in the ordinary course of the App\'s '
          'operation. Consequently, the Developer does not collect, view, store, or have any '
          'visibility into the content of your business records created within the App, '
          'except to the limited extent, if any, expressly described in our Privacy Policy. '
          'You acknowledge and agree that, because your data resides solely on your device, '
          'you bear sole responsibility for safeguarding that device, for maintaining '
          'independent backups of your data using the backup and export functionality '
          'provided within the App, and for any consequences arising from the loss, '
          'corruption, theft, or unauthorized access to your device, including but not '
          'limited to data loss resulting from device damage, loss, factory reset, '
          'uninstallation of the App, or operating system-level data clearance.',
    ),
    _TermsSection(
      '4. Access Control and Security',
      'The App may incorporate a local administrative access-control mechanism requiring '
          'entry of a credential before the App\'s functionality becomes available on a given '
          'device. This mechanism is provided solely as a convenience feature to restrict '
          'casual or unauthorized access to the App on a shared or lost device, and does not '
          'constitute, and should not be relied upon as, a comprehensive security, encryption, '
          'or data-protection measure. The Developer makes no representation or warranty, '
          'express or implied, that this mechanism will prevent unauthorized access by a '
          'sufficiently determined third party, including but not limited to access obtained '
          'through reverse engineering, device-level exploits, or physical extraction of '
          'device storage. You are solely responsible for the confidentiality of any access '
          'credentials you configure, for the physical and digital security of the device on '
          'which the App is installed, and for promptly addressing any suspected unauthorized '
          'access.',
    ),
    _TermsSection(
      '5. Accuracy of Generated Documents',
      'The App is a productivity tool that assists in the formatting and generation of '
          'quotation and invoice documents based exclusively on the information you input. The '
          'Developer does not verify, validate, audit, or otherwise assume responsibility for '
          'the accuracy, completeness, legality, or tax compliance of any figures, rates, tax '
          'percentages, terms, or other content that you enter into the App or that appears on '
          'any document generated by the App. It remains your sole and exclusive responsibility '
          'to ensure that all amounts, applicable tax rates (including but not limited to Goods '
          'and Services Tax or any successor or equivalent levy), terms and conditions, and any '
          'other content included in documents generated using the App comply with all '
          'applicable laws, regulations, and professional or industry standards applicable to '
          'your business and jurisdiction. The Developer strongly recommends that you have any '
          'document template, tax configuration, or legal clause reviewed by a qualified '
          'accountant, tax advisor, or legal professional prior to relying upon it for '
          'commercial or regulatory purposes.',
    ),
    _TermsSection(
      '6. Intellectual Property Rights',
      'The App, including without limitation its source code, object code, visual design, '
          'user interface, graphics, icons, trademarks, trade names, and all associated '
          'documentation, is and shall remain the exclusive property of the Developer and is '
          'protected by applicable copyright, trademark, trade secret, and other intellectual '
          'property laws and international treaty provisions. Subject to your compliance with '
          'these Terms, the Developer grants you a limited, non-exclusive, non-transferable, '
          'non-sublicensable, revocable license to install and use the App solely on devices '
          'that you own or control, and solely for your own internal business or personal '
          'purposes. No other rights are granted to you by implication, estoppel, or '
          'otherwise. You shall not, and shall not permit any third party to: (a) copy, '
          'modify, adapt, translate, or create derivative works of the App; (b) reverse '
          'engineer, decompile, disassemble, or otherwise attempt to derive the source code of '
          'the App, except to the limited extent such restriction is expressly prohibited by '
          'applicable law; (c) sell, resell, license, sublicense, rent, lease, or otherwise '
          'commercially exploit the App or make it available to any third party; or (d) remove, '
          'obscure, or alter any proprietary notices contained within the App. All content you '
          'create using the App — including your company information, client data, and '
          'generated documents — remains your own property; the Developer claims no '
          'ownership interest in such content.',
    ),
    _TermsSection(
      '7. Disclaimer of Warranties',
      'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE APP IS PROVIDED ON AN "AS IS" '
          'AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS, IMPLIED, '
          'STATUTORY, OR OTHERWISE, INCLUDING BUT NOT LIMITED TO ANY IMPLIED WARRANTIES OF '
          'MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, NON-INFRINGEMENT, OR '
          'ACCURACY OF DATA. THE DEVELOPER DOES NOT WARRANT THAT THE APP WILL BE '
          'UNINTERRUPTED, TIMELY, SECURE, OR ERROR-FREE, THAT DEFECTS WILL BE CORRECTED, OR '
          'THAT THE APP OR THE SERVERS, IF ANY, THROUGH WHICH IT IS MADE AVAILABLE ARE FREE OF '
          'VIRUSES OR OTHER HARMFUL COMPONENTS. YOU ACKNOWLEDGE THAT YOUR USE OF THE APP IS AT '
          'YOUR SOLE RISK AND THAT ANY MATERIAL DOWNLOADED OR OTHERWISE OBTAINED THROUGH THE '
          'USE OF THE APP IS DONE AT YOUR OWN DISCRETION AND RISK, AND YOU WILL BE SOLELY '
          'RESPONSIBLE FOR ANY DAMAGE TO YOUR DEVICE OR LOSS OF DATA RESULTING THEREFROM.',
    ),
    _TermsSection(
      '8. Limitation of Liability',
      'TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL THE DEVELOPER, '
          'ITS OFFICERS, DIRECTORS, EMPLOYEES, AGENTS, OR AFFILIATES BE LIABLE FOR ANY '
          'INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, '
          'INCLUDING WITHOUT LIMITATION DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR '
          'OTHER INTANGIBLE LOSSES, ARISING OUT OF OR RELATING TO YOUR ACCESS TO OR USE OF, OR '
          'INABILITY TO ACCESS OR USE, THE APP, WHETHER BASED ON WARRANTY, CONTRACT, TORT '
          '(INCLUDING NEGLIGENCE), STATUTE, OR ANY OTHER LEGAL THEORY, AND WHETHER OR NOT THE '
          'DEVELOPER HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. WITHOUT LIMITING THE '
          'FOREGOING, THE DEVELOPER SHALL NOT BE LIABLE FOR ANY LOSS OF BUSINESS DATA, '
          'QUOTATIONS, INVOICES, OR OTHER RECORDS RESULTING FROM DEVICE FAILURE, LOSS, THEFT, '
          'UNINSTALLATION, OPERATING SYSTEM UPDATES, OR YOUR FAILURE TO MAINTAIN ADEQUATE '
          'BACKUPS. IN ANY EVENT, THE AGGREGATE LIABILITY OF THE DEVELOPER ARISING OUT OF OR '
          'RELATING TO THESE TERMS OR THE APP SHALL NOT EXCEED THE GREATER OF (A) THE AMOUNT, '
          'IF ANY, ACTUALLY PAID BY YOU TO THE DEVELOPER FOR THE APP IN THE TWELVE (12) MONTHS '
          'PRECEDING THE EVENT GIVING RISE TO THE CLAIM, OR (B) ONE HUNDRED INDIAN RUPEES '
          '(₹100). SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF CERTAIN '
          'DAMAGES, SO SOME OF THE ABOVE LIMITATIONS MAY NOT APPLY TO YOU.',
    ),
    _TermsSection(
      '9. Indemnification',
      'You agree to defend, indemnify, and hold harmless the Developer and its officers, '
          'directors, employees, and agents from and against any and all claims, damages, '
          'obligations, losses, liabilities, costs, and expenses (including but not limited to '
          'reasonable attorneys\' fees) arising from: (a) your use of and access to the App; '
          '(b) your violation of any provision of these Terms; (c) your violation of any '
          'third-party right, including without limitation any intellectual property, privacy, '
          'or contractual right; or (d) any claim that documents generated using the App caused '
          'damage to a third party, including claims arising from inaccurate, incomplete, or '
          'unlawful content that you entered into the App.',
    ),
    _TermsSection(
      '10. Modifications to the App and Terms',
      'The Developer reserves the right, at its sole discretion, to modify, suspend, or '
          'discontinue the App, or any feature thereof, at any time and without prior notice or '
          'liability. The Developer further reserves the right to revise and update these Terms '
          'from time to time. Any such changes will become effective upon publication of the '
          'updated Terms, whether through an updated version of the App, the App store listing, '
          'or other reasonable means of notice. Your continued use of the App after any such '
          'changes constitutes your acceptance of the revised Terms. It is your responsibility '
          'to review these Terms periodically for updates.',
    ),
    _TermsSection(
      '11. Termination',
      'These Terms remain in effect until terminated by either party. You may terminate these '
          'Terms at any time by uninstalling the App and discontinuing all use thereof. The '
          'Developer may suspend or terminate your access to or use of the App, in whole or in '
          'part, at any time, with or without notice, for any reason, including but not limited '
          'to your breach of these Terms. Upon termination, all licenses and rights granted to '
          'you under these Terms shall immediately cease, and the provisions of these Terms '
          'that by their nature should survive termination (including without limitation '
          'Sections 6, 7, 8, 9, and 13) shall survive.',
    ),
    _TermsSection(
      '12. Third-Party Services',
      'The App may rely on certain third-party software libraries and components to provide '
          'functionality such as document generation, file sharing, and printing. Such '
          'third-party components are used in accordance with their respective licenses and do '
          'not, in themselves, result in the transmission of your data to any third party '
          'unless you affirmatively choose to share a generated document (for example, by '
          'using the App\'s share or print functionality to send a document via email, '
          'messaging applications, or a printing service). Any such sharing is performed at '
          'your direction and is subject to the terms and privacy practices of the third-party '
          'application or service you choose to use.',
    ),
    _TermsSection(
      '13. Governing Law and Jurisdiction',
      'These Terms and any dispute or claim arising out of or in connection with them or their '
          'subject matter (including non-contractual disputes or claims) shall be governed by '
          'and construed in accordance with the laws of India, without regard to its conflict '
          'of law provisions. Subject to applicable consumer-protection law, you and the '
          'Developer agree that the courts located in Ahmedabad, Gujarat, India shall have '
          'exclusive jurisdiction to resolve any dispute arising out of or relating to these '
          'Terms or the App.',
    ),
    _TermsSection(
      '14. Severability and Entire Agreement',
      'If any provision of these Terms is held to be invalid, illegal, or unenforceable by a '
          'court or tribunal of competent jurisdiction, such provision shall be modified to the '
          'minimum extent necessary to make it enforceable, or if it cannot be so modified, '
          'severed from these Terms, and the remaining provisions shall continue in full force '
          'and effect. These Terms, together with our Privacy Policy, constitute the entire '
          'agreement between you and the Developer concerning the App and supersede all prior '
          'or contemporaneous understandings, agreements, representations, and warranties, both '
          'written and oral, with respect to such subject matter.',
    ),
    _TermsSection(
      '15. Contact Information',
      'If you have any questions, concerns, or comments regarding these Terms, please contact '
          'the Developer at: [Insert Support Email Address Here]. [Developer/Company Name], '
          '[Insert Registered Business Address, City, State, PIN Code, India].',
    ),
  ];
}

class _TermsSection {
  final String title;
  final String body;
  const _TermsSection(this.title, this.body);
}

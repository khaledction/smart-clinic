import 'package:flutter/material.dart';

import '../../core/services/password_recovery.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/section_card.dart';

/// بيانات التواصل مع فريق البرمجة.
const kDevEmail = 'loraneemtech@gmail.com';
const kDevPhone = '0933713023';
const kDevPhone2 = '0930720434';
const kDevWhatsappUrl = 'https://wa.me/963933713023';

/// ميزات البرنامج كما تظهر في «حول البرنامج».
const kAboutFeatures = <String>[
  'ضمان تخزين بيانات المرضى بطريقة آمنة وسهلة الوصول.',
  'إمكانية حجز وتعديل وإلغاء المواعيد بسهولة.',
  'حفظ المسار الزمني للمريض والفحوصات والتشخيصات والوصفات.',
  'توثيق الأدوية والأمراض السابقة والوصفات.',
  'بحث متقدم وسريع وإتمام تلقائي.',
  'الوصول السريع للبيانات.',
  'إدارة كاملة للإيرادات حسب نوعها وتاريخها.',
  'نسخ احتياطي تلقائي ويدوي.',
  'حفظ واسترجاع نسخة احتياطية سابقة.',
  'حفظ صور الأشعة والفحوصات.',
  'إمكانية تصدير الملفات والتقارير إلى ملف CSV.',
];

/// «حول البرنامج»: التعريف والميزات وحقوق النشر والتواصل مع المبرمج.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  static const _navyText = TextStyle(
    fontSize: 13,
    color: AppColors.navy,
    height: 1.7,
  );

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'حول البرنامج',
      icon: Icons.info_outline,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'برنامج عيادتي الذكي',
              key: Key('aboutAppName'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            const Row(
              children: [
                Icon(
                  Icons.desktop_windows_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'يعمل على بيئة Windows — نسخة 0.1.0',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'برنامج عصري متطور لإدارة العيادات، وتحويل العمل إلى متعة.',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            // الميزات في عمودين متوازيين.
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth >= 760
                    ? (c.maxWidth - 16) / 2
                    : c.maxWidth;
                return Wrap(
                  key: const Key('aboutFeatures'),
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (final f in kAboutFeatures)
                      SizedBox(
                        width: w,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.check_circle,
                                size: 17,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'وستكتشف الكثير من الخصائص بالتعامل مع البرنامج.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 30, color: AppColors.divider),
            const Text(
              'تم برمجة البرنامج بشكل خاص لعيادة الدكتور طارق نجم مقلد — '
              'اختصاصي جراحة عصبية ومجهرية.',
              key: Key('aboutMadeFor'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 4),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '© حقوق النشر والتوزيع لصالح فريق '),
                  TextSpan(
                    text: 'Loraneem Tech',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' - '),
                  TextSpan(
                    text: '\u200E$kDevPhone\u200E',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' - '),
                  TextSpan(
                    text: '\u200E$kDevPhone2\u200E',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' - هذه النسخة حصرية لصالح عيادة الدكتور طارق مقلد',
                  ),
                ],
              ),
              key: Key('aboutCopyright'),
              style: _navyText,
            ),
            const SizedBox(height: 16),
            // شعار فريق البرمجة ووسائل التواصل.
            Wrap(
              spacing: 22,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // شعار هادئ بحجم صغير: مقروء وواضح دون أن يلفت النظر.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/loraneem_tech.jpg',
                    key: const Key('aboutDevLogo'),
                    width: 240,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'للتواصل مع فريق البرمجة:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ContactButton(
                      key: const Key('aboutEmail'),
                      icon: Icons.email_outlined,
                      label: kDevEmail,
                      uri: Uri.parse('mailto:$kDevEmail'),
                    ),
                    const SizedBox(height: 8),
                    _ContactButton(
                      key: const Key('aboutWhatsapp'),
                      icon: Icons.chat_outlined,
                      label: 'واتساب \u200E$kDevPhone\u200E',
                      uri: Uri.parse(kDevWhatsappUrl),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'قاعدة بيانات محلية مخزّنة داخل جهازك دون أي اتصال بالإنترنت؛ '
              'لا تُرسَل أي بيانات إلى أي جهة خارجية، وكلمات المرور مشفّرة.',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.uri,
  });

  final IconData icon;
  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.standard,
        minimumSize: const Size(250, 42),
        alignment: AlignmentDirectional.centerStart,
      ),
      onPressed: () async {
        try {
          await PasswordRecovery.openUri(uri);
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('تعذّر فتح الرابط: $uri')));
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

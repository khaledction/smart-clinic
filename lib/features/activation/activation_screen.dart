import 'package:flutter/material.dart';

import '../../core/services/device_activation.dart';
import '../../core/services/developer_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/window_controls.dart';

/// شاشة التفعيل: تظهر على أي جهاز غير مفعّل بدل شاشة الدخول.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeCtrl = TextEditingController();
  final _devUser = TextEditingController(text: 'khaled.a.f');
  final _devPass = TextEditingController();
  bool _showDev = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _devUser.dispose();
    _devPass.dispose();
    super.dispose();
  }

  void _activateWithCode() {
    final ok = DeviceActivation.activateWithCode(_codeCtrl.text);
    if (!ok) {
      setState(() {
        _error = 'كود التفعيل غير صحيح، تحقّق منه وحاول مجدداً.';
      });
    }
    // عند النجاح تعيد الواجهة بناء نفسها ويفتح البرنامج تلقائياً.
  }

  void _recover() {
    // نفس الجهاز بعد إعادة تثبيت ويندوز — بلا كود جديد.
    DeviceActivation.recover();
  }

  void _devActivate() {
    final dev = DeveloperMode.tryLogin(_devUser.text, _devPass.text);
    if (dev == null) {
      setState(() {
        _error = 'اسم المبرمج أو كلمة المرور غير صحيحة.';
      });
      return;
    }
    DeviceActivation.activate();
    // بعد هذا تتبدل الشاشة تلقائياً ويفتح البرنامج.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // نفس شريط شاشة الدخول: سحب + اسم البرنامج + أزرار النافذة.
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: LoginWindowStrip(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 54,
                      color: AppColors.navy,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تفعيل البرنامج',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'هذا الجهاز غير مفعّل بعد.\n'
                      'أرسل رمز الجهاز للمطور ثم أدخل الكود الذي يصلك،\n'
                      'أو يمكن للمطور تفعيله على الموقع مباشرة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // استعادة التفعيل بعد فرماتة/تغيير اسم على نفس الجهاز.
                    if (DeviceActivation.recoveryAvailable) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'عُثر على تفعيل سابق محفوظ على هذا القرص\n'
                              '(غالباً بعد إعادة تثبيت ويندوز).',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 46,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                                onPressed: _recover,
                                icon: const Icon(Icons.restore_rounded,
                                    size: 18),
                                label: const Text(
                                  'استعادة التفعيل على هذا الجهاز',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 18),
                    // رمز الجهاز (قابل للنسخ لإرساله للمطور).
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.navy.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'رمز الجهاز: ',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SelectableText(
                            DeviceActivation.deviceId,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      maxLength: 16,
                      style: const TextStyle(letterSpacing: 2, fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'كود التفعيل (16 حرفاً)',
                        hintText: 'يصلك من المطور بعد إرسال رمز الجهاز',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _activateWithCode,
                        child: const Text('تفعيل'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        const SizedBox(width: 10),
                        const Text(
                          'أو',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_showDev)
                      TextButton(
                        onPressed: () => setState(() {
                          _error = null;
                          _showDev = true;
                        }),
                        child: const Text('دخول المبرمج (تفعيل على الموقع)'),
                      )
                    else ...[
                      TextField(
                        controller: _devUser,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _devPass,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navy,
                          ),
                          onPressed: _devActivate,
                          icon: const Icon(Icons.vpn_key_rounded, size: 18),
                          label: const Text('تفعيل هذا الجهاز'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

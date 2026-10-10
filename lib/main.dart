import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/database/app_database.dart';
import 'core/services/device_activation.dart';
import 'core/services/app_folders.dart';
import 'core/services/auto_backup.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'core/widgets/frame_trail.dart';
import 'core/widgets/window_controls.dart';
import 'data/providers/appointments_provider.dart';
import 'data/providers/patients_provider.dart';
import 'data/providers/session_provider.dart';
import 'data/providers/settings_provider.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/patient_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'features/activation/activation_screen.dart';
import 'features/login/login_screen.dart';

/// ============================================================================
///  نقطة الانطلاق
/// ============================================================================
/// اسم النافذة في شريط المهام = اسم أيقونة سطح المكتب.
const kAppWindowTitle = 'برنامج عيادتي الذكي - عيادة د.طارق مقلد';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) تهيئة SQLite لسطح المكتب (ضروري قبل أي استخدام لقاعدة البيانات)
  AppDatabase.initForDesktop();

  // قراءة حالة تفعيل الجهاز (دون اتصال) قبل فتح أي شاشة.
  await DeviceActivation.load();

  // 2) ضبط نافذة سطح المكتب
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(1180, 760),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: kAppWindowTitle,
    // الإطار الكحلي الموحد يحل محل شريط ويندوز الأصلي
    // (السحب والتكبير والإغلاق من داخل البرنامج — انظر window_controls.dart).
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    // تفتح النافذة مكبرةً على الشاشة تلقائياً (يمكن الاستعادة من زر التكبير).
    await windowManager.maximize();
    await windowManager.focus();
    // تأكيد بعد لحظة: إن لم يُنفَّذ التكبير (يحدث أحياناً عند الإقلاع) نعيد المحاولة.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      if (!await windowManager.isMaximized()) {
        await windowManager.maximize();
      }
    } catch (_) {}
  });

  runApp(const NeuroClinicApp());

  // مجلد البرنامج D:\myclinic (والنسخ الاحتياطية بداخله) يُنشأ تلقائياً.
  AppFolders.ensure();

  // 3) نسخ احتياطي تلقائي يومي (بعد 15 ثانية من التشغيل ثم فحص كل ساعة).
  AutoBackup.start();
}

class NeuroClinicApp extends StatelessWidget {
  const NeuroClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionProvider(AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(SettingsRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientsProvider(PatientRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentsProvider(AppointmentRepository()),
        ),
      ],
      child: MaterialApp(
        title: kAppWindowTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),

        // ------------------------------------------- العربية والاتجاه RTL
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // فرض الاتجاه من اليمين لليسار على كامل التطبيق
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          // حافة علوية لتغيير ارتفاع النافذة بعد إخفاء شريط ويندوز.
          child: WindowTopResizeEdge(child: child ?? const SizedBox.shrink()),
        ),

        // مسار النوافذ المفتوحة في الشريط الكحلي.
        navigatorObservers: [FrameTrail.instance],

        home: const _Root(),
      ),
    );
  }
}

/// يقرّر: شاشة التفعيل (جهاز جديد) أم شاشة الدخول أم الشاشة الرئيسية.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DeviceActivation.state,
      builder: (context, _) {
        if (!DeviceActivation.isActivated) return const ActivationScreen();
        final loggedIn = context.watch<SessionProvider>().isLoggedIn;
        return loggedIn ? const AppShell() : const LoginScreen();
      },
    );
  }
}

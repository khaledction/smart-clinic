import 'dart:io';
import 'dart:math';

import '../../data/repositories/app_prefs_repository.dart';
import '../../data/repositories/auth_repository.dart';

enum RecoveryChannel { email, whatsapp }

/// «نسيت كلمة المرور»: رمز من 6 أرقام صالح 15 دقيقة يُرسل إلى البريد
/// أو رقم الواتساب المحفوظين في الإعدادات، ثم تُعيَّن كلمة مرور جديدة.
class PasswordRecovery {
  PasswordRecovery({AppPrefsRepository? prefs, AuthRepository? auth})
    : _prefs = prefs ?? AppPrefsRepository(),
      _auth = auth ?? AuthRepository();

  final AppPrefsRepository _prefs;
  final AuthRepository _auth;

  static const validFor = Duration(minutes: 15);
  static const maxAttempts = 5;

  /// فتح رابط (واتساب أو برنامج البريد) — قابل للاستبدال في الاختبارات.
  static Future<void> Function(Uri uri) openUri = _openUri;

  static DateTime Function() now = DateTime.now;

  // الرمز الحالي (في الذاكرة فقط، لا يُحفظ في أي ملف).
  static String? _code;
  static String? _user;
  static DateTime? _expires;
  static int _attempts = 0;

  static void clear() {
    _code = null;
    _user = null;
    _expires = null;
    _attempts = 0;
  }

  static String _newCode() {
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }

  /// يحوّل الرقم إلى الصيغة الدولية بدون + (رقم يبدأ بـ 0 يُعتبر سورياً).
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0')) d = '963${d.substring(1)}';
    return d;
  }

  static String maskEmail(String email) {
    final e = email.trim();
    final at = e.indexOf('@');
    if (at <= 0) return e;
    final name = e.substring(0, at);
    final keep = name.length <= 2 ? name.substring(0, 1) : name.substring(0, 2);
    return '$keep***${e.substring(at)}';
  }

  static String maskPhone(String phone) {
    final d = normalizePhone(phone);
    if (d.length <= 3) return d;
    return '…${d.substring(d.length - 3)}';
  }

  /// رسالة جاهزة في برنامج البريد على هذا الجهاز (بدون كلمة مرور تطبيقات).
  static Uri mailUri(String email, String subject, String body) => Uri.parse(
    'mailto:${email.trim()}'
    '?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );

  static Uri whatsappUri(String phone, String text) =>
      Uri.https('wa.me', '/${normalizePhone(phone)}', {'text': text});

  Future<AppPrefs> prefs() => _prefs.load();

  /// يرسل رمزاً جديداً. يرمي [StateError] برسالة عربية عند المشكلة.
  Future<void> sendCode(String username, RecoveryChannel channel) async {
    final user = await _auth.findActive(username);
    if (user == null) {
      throw StateError('اسم المستخدم غير موجود أو الحساب معطّل.');
    }
    final p = await _prefs.load();
    final code = _newCode();
    final text =
        'رمز استعادة كلمة المرور لبرنامج العيادة: $code\n'
        'المستخدم: ${user.username}\n'
        'الرمز صالح لمدة ${validFor.inMinutes} دقيقة. إن لم تطلبه فتجاهل هذه الرسالة.';
    switch (channel) {
      case RecoveryChannel.email:
        if (!p.canEmail) {
          throw StateError('لم يُضبط بريد في الإعدادات ← استعادة كلمة المرور.');
        }
        await openUri(
          mailUri(p.recoveryEmail, 'رمز استعادة كلمة المرور', text),
        );
      case RecoveryChannel.whatsapp:
        if (!p.canWhatsapp) {
          throw StateError(
            'لم يُضبط رقم واتساب في الإعدادات ← استعادة كلمة المرور.',
          );
        }
        await openUri(whatsappUri(p.recoveryWhatsapp, text));
    }
    _code = code;
    _user = user.username;
    _expires = now().add(validFor);
    _attempts = 0;
  }

  /// يتحقق من الرمز ويعيّن كلمة المرور الجديدة.
  Future<void> reset(String username, String code, String newPassword) async {
    if (_code == null || _expires == null || _user == null) {
      throw StateError('اطلب رمزاً جديداً أولاً.');
    }
    if (now().isAfter(_expires!)) {
      clear();
      throw StateError('انتهت صلاحية الرمز. اطلب رمزاً جديداً.');
    }
    if (username.trim() != _user) {
      throw StateError('الرمز صادر لمستخدم آخر.');
    }
    if (code.trim() != _code) {
      _attempts++;
      if (_attempts >= maxAttempts) {
        clear();
        throw StateError('محاولات خاطئة كثيرة. اطلب رمزاً جديداً.');
      }
      throw StateError('الرمز غير صحيح.');
    }
    if (newPassword.length < 8) {
      throw StateError('كلمة المرور الجديدة يجب ألا تقل عن 8 أحرف.');
    }
    final user = await _auth.findActive(username);
    if (user == null) throw StateError('اسم المستخدم غير موجود.');
    await _auth.changePassword(user.id!, newPassword);
    clear();
  }
}

Future<void> _openUri(Uri uri) async {
  final url = uri.toString();
  if (Platform.isWindows) {
    // بدون cmd حتى لا تُفسَّر علامة & في الرابط.
    await Process.start('rundll32', ['url.dll,FileProtocolHandler', url]);
  } else if (Platform.isMacOS) {
    await Process.start('open', [url]);
  } else {
    await Process.start('xdg-open', [url]);
  }
}

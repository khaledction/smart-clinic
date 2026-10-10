import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ============================================================================
///  تفعيل لكل جهاز (دون اتصال بالإنترنت — بلا خادم) — V25
/// ============================================================================
/// هوية الجهاز = بصمة عتاد ثابتة (رقم اللوحة + المعالج + قرص النظام عبر WMI)،
/// لا تتغير بإعادة تثبيت ويندوز ولا بتغيير اسم الحاسوب.
///
///  - جهاز جديد: تظهر شاشة التفعيل (كود من المطور أو تفعيل على الموقع).
///  - بعد فورمات القرص C: يتعرّف البرنامج على الجهاز تلقائياً بلا أي شاشة
///    (سجل التفعيل محفوظ على D:\myclinic الذي يبقى بعد الفورمات).
///  - حتى لو مُسح كامل القرص: الكود القديم نفسه يبقى صالحاً للأبد لأن
///    الكود مشتق حتمياً من بصمة العتاد: sha256(deviceId + salt).
///  - إن تعذّر قراءة العتاد (نادر): يُستخدم اسم الحاسوب كاحتياطي مع زر
///    «استعادة التفعيل» بنقرة واحدة بلا كود.
///
/// حاسبة المطور (PowerShell) لاستخراج الكود من رمز الجهاز:
/// $id='رمز الجهاز'; $s='LORANEEM-TECH-CLINIC-2026';
/// $h=[Security.Cryptography.SHA256]::Create().ComputeHash(
///   [Text.Encoding]::UTF8.GetBytes(($id -replace '[^A-Z0-9]','').ToUpper()+$s));
/// ((($h|ForEach-Object{$_.ToString('x2')}) -join '').Substring(0,16).ToUpper())
class DeviceActivation {
  DeviceActivation._();

  /// سر مشترك لتوليد كود التفعيل (نفس القيمة في حاسبة المطور).
  static const _salt = 'LORANEEM-TECH-CLINIC-2026';

  /// اسم ملف التفعيل وملف بصمة الجهاز (كاش).
  static const fileName = 'activation.json';
  static const _fpCacheName = 'device.id';

  /// مجلد البيانات (يبقى بعد فورمات C) + بديل إن لم يوجد القرص D.
  static const _dataDir = r'D:\myclinic';
  static const _dataDirAlt = r'C:\myclinic';

  static String _fingerprint = '';
  static String _hostname = '';
  static bool _isFallback = false;
  static String? _dirPath;

  /// هل هذا الجهاز مفعّل؟
  static bool isActivated = false;

  /// يوجد سجل تفعيل لا يطابق البصمة (وضع احتياطي نادر) — زر استعادة بنقرة.
  static bool recoveryAvailable = false;

  /// وقت التفعيل (للعرض).
  static DateTime? activatedAt;

  /// إشعار لإعادة بناء الواجهة بعد التفعيل.
  static final ValueNotifier<int> state = ValueNotifier(0);

  /// رمز الجهاز المعروض (12 حرفاً) — يُرسل للمطور لاستخراج الكود.
  static String get deviceId {
    if (_fingerprint.isEmpty) return 'unknown-device';
    return sha256
        .convert(utf8.encode(_fingerprint))
        .toString()
        .substring(0, 12)
        .toUpperCase();
  }

  static List<File> _files(String name) {
    final list = <File>[];
    if (_dirPath != null) list.add(File(p.join(_dirPath!, name)));
    list.add(File(p.join(_dataDir, name)));
    list.add(File(p.join(_dataDirAlt, name)));
    return list;
  }

  /// يقرأ حالة التفعيل عند الإقلاع (يُستدعى في main قبل runApp).
  static Future<void> load() async {
    try {
      _hostname = Platform.localHostname;
    } catch (_) {}
    try {
      final dir = await getApplicationSupportDirectory();
      _dirPath = dir.path;
    } catch (_) {}

    _fingerprint = await _resolveFingerprint();

    for (final f in _files(fileName)) {
      Map<String, Object?> m;
      try {
        if (!f.existsSync()) continue;
        m = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
        if (m['activated'] != true) continue;
      } catch (_) {
        continue;
      }
      // سجل حديث مطابق للبصمة → تفعيل صامت (حتى بعد الفورمات).
      if (_fingerprint.isNotEmpty &&
          (m['fingerprint'] as String?) == _fingerprint) {
        isActivated = true;
        activatedAt = DateTime.tryParse((m['activatedAt'] as String?) ?? '');
        return;
      }
      // سجل V24p قديم (أسماء أجهزة) بنفس الاسم → ترحيل صامت للبصمة.
      final savedHosts =
          (m['hostnames'] as List?)?.cast<String>() ?? const <String>[];
      if (_hostname.isNotEmpty && savedHosts.contains(_hostname)) {
        activate();
        return;
      }
      // سجل مفعّل لا يطابق: وضع احتياطي (زر استعادة بنقرة واحدة).
      if (_isFallback || savedHosts.isNotEmpty) recoveryAvailable = true;
    }
  }

  /// يحسم بصمة الجهاز: كاش سابق، وإلا قراءة العتاد، وإلا الاسم احتياطياً.
  static Future<String> _resolveFingerprint() async {
    for (final f in _files(_fpCacheName)) {
      try {
        if (!f.existsSync()) continue;
        final v = f.readAsStringSync().trim();
        if (v.length >= 8) {
          _isFallback = v.startsWith('HOST:');
          return v;
        }
      } catch (_) {}
    }
    final hw = await _readHardwareId();
    final fp = hw.isNotEmpty ? 'HW:$hw' : 'HOST:$_hostname';
    _isFallback = hw.isEmpty;
    for (final f in _files(_fpCacheName)) {
      try {
        if (!f.parent.existsSync()) f.parent.createSync(recursive: true);
        f.writeAsStringSync(fp, flush: true);
      } catch (_) {}
    }
    return fp;
  }

  /// يقرأ (رقم اللوحة + المعالج + قرص النظام) باستدعاء WMI واحد.
  static Future<String> _readHardwareId() async {
    try {
      final r = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-Command',
        r'(Get-CimInstance Win32_ComputerSystemProduct).UUID; (Get-CimInstance Win32_Processor | Select-Object -First 1).ProcessorId; $d = (Get-CimInstance Win32_DiskPartition | Where-Object { $_.BootPartition } | Select-Object -First 1).DiskIndex; (Get-CimInstance Win32_DiskDrive | Where-Object { $_.Index -eq $d }).SerialNumber',
      ]).timeout(const Duration(seconds: 25));
      final out = (r.stdout as String?) ?? '';
      final parts = out
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where(_looksReal)
          .toList();
      if (parts.isEmpty) return '';
      return parts.join('|');
    } catch (_) {
      return '';
    }
  }

  /// يرفض القيم الوهمية التي تضعها بعض اللوحات (أصفار/عبارات افتراضية).
  static bool _looksReal(String v) {
    if (v.length < 4) return false;
    final u = v.toUpperCase();
    if (u.contains('TO BE FILLED')) return false;
    if (u == 'NONE' || u == 'UNKNOWN' || u == 'DEFAULT STRING') return false;
    if (RegExp(r'^0+$').hasMatch(u)) return false;
    if (u.startsWith('FFFFFFFF')) return false;
    return true;
  }

  /// تفعيل (على الموقع بعد دخول المبرمج، أو بالكود، أو استعادة) — للبصمة.
  static bool activate() {
    try {
      final record = <String, Object?>{
        'fingerprint': _fingerprint,
        'deviceId': deviceId,
        'hostnames': _hostname.isEmpty ? <String>[] : <String>[_hostname],
        'activated': true,
        'activatedAt': DateTime.now().toIso8601String(),
      };
      final text = const JsonEncoder.withIndent('  ').convert(record);
      var ok = false;
      for (final f in _files(fileName)) {
        try {
          if (!f.parent.existsSync()) f.parent.createSync(recursive: true);
          f.writeAsStringSync(text, flush: true);
          ok = true;
        } catch (_) {}
      }
      if (!ok) return false;
    } catch (_) {
      return false;
    }
    isActivated = true;
    recoveryAvailable = false;
    activatedAt = DateTime.now();
    state.value++;
    return true;
  }

  /// استعادة التفعيل بنقرة واحدة (الوضع الاحتياطي النادر فقط).
  static bool recover() {
    if (!recoveryAvailable) return false;
    return activate();
  }

  /// تفعيل بالكود المرسل من المطور.
  static bool activateWithCode(String code) {
    if (code.trim().toUpperCase() != expectedCode) return false;
    return activate();
  }

  /// كود التفعيل الصحيح لهذا الجهاز (16 حرفاً — ثابت للأبد لنفس العتاد).
  static String get expectedCode {
    final digest = sha256.convert(utf8.encode(deviceId + _salt));
    return digest.toString().substring(0, 16).toUpperCase();
  }
}

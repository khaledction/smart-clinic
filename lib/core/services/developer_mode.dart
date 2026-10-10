import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/user.dart';

/// «حساب المبرمج»: بيانات العيادة لا تظهر للطبيب ولا تُعدَّل إلا عند الدخول
/// من شاشة الدخول باسم مستخدم المبرمج وكلمة مروره.
/// الحساب غير مخزَّن في قاعدة البيانات ولا يظهر في قائمة المستخدمين،
/// ويُقفل الوضع تلقائياً عند تسجيل الخروج أو إغلاق البرنامج.
class DeveloperMode {
  DeveloperMode._();

  static const username = 'khaled.a.f';

  /// bcrypt لكلمة مرور المبرمج (لا تُحفظ الكلمة نفسها في الكود).
  static const _hash =
      r'$2a$10$Erc73lva92ZO5.Yax1h7H.2hK5zTHdT2xSNvSzHqW7koX9qclimg6';

  static final ValueNotifier<bool> unlocked = ValueNotifier(false);

  /// هل هذا الاسم محجوز لحساب المبرمج؟ (لا يُنشأ مستخدم عادي بنفس الاسم).
  static bool isReserved(String name) => name.trim().toLowerCase() == username;

  /// يعيد مستخدم المبرمج إن كانت البيانات صحيحة، ويفتح الوضع. وإلا null.
  static User? tryLogin(String name, String password) {
    if (!isReserved(name) || password.isEmpty) return null;
    if (!BCrypt.checkpw(password, _hash)) return null;
    unlocked.value = true;
    return const User(username: username, fullName: 'المبرمج', role: 'admin');
  }

  static void lock() => unlocked.value = false;
}

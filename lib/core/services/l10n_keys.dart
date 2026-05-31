// AUTO-MAINTAINED MANUALLY.
//
// This list mirrors the keys in `app_l10n.dart` and exists so that callers
// can write `LK.profileEdit.tr(ref)` and get a compile-time error if the key
// is removed — instead of getting the raw key string back at runtime.
//
// Until we adopt a codegen-based i18n (slang / flutter_intl), this is the
// type-safe boundary.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';

extension type const LK(String key) {
  String tr(WidgetRef ref) => key.tr(ref);

  // ── common ───────────────────────────────────────────────────────────────
  static const cancel = LK('common.cancel');
  static const confirm = LK('common.confirm');
  static const save = LK('common.save');
  static const send = LK('common.send');
  static const edit = LK('common.edit');
  static const delete = LK('common.delete');
  static const search = LK('common.search');
  static const show = LK('common.show');
  static const hide = LK('common.hide');
  static const refresh = LK('common.refresh');
  static const notFound = LK('common.notFound');
  static const required = LK('common.required');
  static const negotiable = LK('common.negotiable');
  static const price = LK('common.price');
  static const date = LK('common.date');
  static const km = LK('common.km');
  static const tons = LK('common.tons');
  static const m3 = LK('common.m3');

  // ── nav ──────────────────────────────────────────────────────────────────
  static const navSearch = LK('nav.search');
  static const navPost = LK('nav.post');
  static const navMyLoads = LK('nav.myLoads');
  static const navMyTrucks = LK('nav.myTrucks');
  static const navProfile = LK('nav.profile');

  // ── auth ─────────────────────────────────────────────────────────────────
  static const authWelcome = LK('auth.welcome');
  static const authContinue = LK('auth.continue');
  static const authSendCode = LK('auth.sendCode');

  // ── loads ────────────────────────────────────────────────────────────────
  static const loadsTitle = LK('loads.title');
  static const trucksTitle = LK('trucks.title');
  static const loadsAllCount = LK('loads.allCount');
  static const loadsOriginPlace = LK('loads.originPlace');
  static const loadsDestPlace = LK('loads.destPlace');
  static const loadsSearchBtn = LK('loads.searchBtn');
  static const loadsFilterBtn = LK('loads.filterBtn');

  // ── owner actions ────────────────────────────────────────────────────────
  static const ownerView = LK('owner.view');
  static const ownerArchive = LK('owner.archive');
  static const ownerReactivate = LK('owner.reactivate');
  static const ownerArchiveMessage = LK('owner.archiveMessage');
  static const ownerReactivateMessage = LK('owner.reactivateMessage');

  // ── profile ──────────────────────────────────────────────────────────────
  static const profileEdit = LK('profile.edit');
  static const profileStatistics = LK('profile.statistics');
  static const profileSaved = LK('profile.saved');
  static const profilePremium = LK('profile.premium');
  static const profileLanguage = LK('profile.language');
  static const profileTheme = LK('profile.theme');
  static const profileTerms = LK('profile.terms');
  static const profilePrivacy = LK('profile.privacy');
  static const profileFaq = LK('profile.faq');
  static const profileSupport = LK('profile.support');
  static const profileInstructions = LK('profile.instructions');
  static const profileLogout = LK('profile.logout');
  static const profileLogoutTitle = LK('profile.logoutTitle');
  static const profileLogoutMessage = LK('profile.logoutMessage');
  static const profilePersonalData = LK('profile.personalData');

  // ── success modal ────────────────────────────────────────────────────────
  static const successTitle = LK('success.title');
  static const successAddLoadMessage = LK('success.addLoadMessage');
  static const successGoToMyLoads = LK('success.goToMyLoads');
}

import 'package:flutter/widgets.dart';

import '../state/app_scope.dart';

/// Idiomas soportados por la app (y por los home widgets).
enum AppLocale { en, es }

extension AppLocaleExt on AppLocale {
  /// Código ISO 2 letras.
  String get code => switch (this) {
    AppLocale.en => 'en',
    AppLocale.es => 'es',
  };

  /// Etiqueta legible que se muestra en el selector.
  String get label => switch (this) {
    AppLocale.en => 'English',
    AppLocale.es => 'Español',
  };

  /// Emoji bandera.
  String get flag => switch (this) {
    AppLocale.en => '🇺🇸',
    AppLocale.es => '🇪🇸',
  };
}

AppLocale localeFromCode(String? code) => switch (code) {
  'es' => AppLocale.es,
  _ => AppLocale.en,
};

/// Bundle inmutable de TODAS las cadenas de texto que ve el usuario.
class AppStrings {
  const AppStrings._({
    required this.appName,
    required this.tagline,
    // Navegación
    required this.navTimeline,
    required this.navVault,
    required this.navCalendar,
    required this.navProfile,
    required this.navCreate,
    // Timeline
    required this.timelineWritingSince,
    required this.timelineEmpty,
    required this.timelineNoteBy,
    required this.timelineDeleteMomentTitle,
    required this.timelineDeletePhotoBody,
    required this.timelineDeleteNoteBody,
    // Vault
    required this.vaultPhotos,
    required this.vaultNotes,
    required this.vaultTitle,
    required this.vaultCategory,
    required this.vaultPhotosSubtitle,
    required this.vaultNotesSubtitle,
    required this.vaultSearchHint,
    required this.vaultPhotosEmpty,
    required this.vaultNotesEmpty,
    required this.vaultAll,
    required this.vaultAddPhoto,
    required this.vaultTitleOptional,
    required this.vaultTitleHint,
    required this.vaultAddToVault,
    // Categorías
    required this.categoryTrips,
    required this.categoryDates,
    required this.categoryFirsts,
    required this.categoryFamily,
    required this.categoryPets,
    required this.categoryTimeline,
    // Calendar
    required this.calendarUpcoming,
    required this.calendarUpcomingEvents,
    required this.calendarNoEvents,
    required this.calendarAddEvent,
    required this.calendarEventTitle,
    required this.calendarEventSubtitle,
    required this.calendarStartDate,
    required this.calendarEndDate,
    required this.calendarOptionalEndDate,
    required this.calendarSelectDate,
    required this.calendarTitleHint,
    required this.calendarSubtitleHint,
    required this.calendarDeleteEventTitle,
    required this.calendarSaveEvent,
    required this.calendarEventPresetAnniversary,
    required this.calendarEventPresetTrip,
    required this.calendarEventPresetDate,
    required this.calendarEventPresetMovie,
    required this.calendarEventPresetHome,
    required this.calendarChoose,
    // Profile
    required this.profileTogetherFor,
    required this.profileEditProfile,
    required this.profileMilestones,
    required this.profileAddMilestone,
    required this.profileSettings,
    required this.profileNotifications,
    required this.profilePrivacy,
    required this.profileMessageBoard,
    required this.profileTheme,
    required this.profileLanguage,
    required this.profileNameA,
    required this.profileNameB,
    required this.profileAnniversary,
    required this.profilePickGallery,
    required this.profilePickCamera,
    required this.profileDeleteMilestoneTitle,
    required this.profileMilestoneTitle,
    required this.profileMilestoneTitleHint,
    required this.profileMilestonePlace,
    required this.profileMilestonePlaceHint,
    required this.profileThemePlaceholder,
    required this.profileSaveProfile,
    required this.profileEmptyMilestones,
    // Create
    required this.createPhoto,
    required this.createNote,
    required this.createCaption,
    required this.createQuote,
    required this.createTags,
    required this.createPost,
    required this.createChoosePhoto,
    required this.createCaptureMemory,
    required this.createCaptureSubtitle,
    required this.createLeaveNote,
    required this.createNoteSubtitle,
    required this.createWhenPhoto,
    required this.createStory,
    required this.createTagsLabel,
    required this.createWhenNote,
    required this.createYourMessage,
    required this.createCaptionHint,
    required this.createNoteHint,
    required this.createCustomTag,
    required this.createCustomTagHint,
    required this.createMarkAsMilestone,
    required this.createMilestoneHint,
    // Message board
    required this.messageBoardTitle,
    required this.messageBoardSubtitle,
    required this.messageBoardEmpty,
    required this.messageBoardDeleteTitle,
    required this.messageBoardDeleteBody,
    required this.noteText,
    required this.noteColor,
    required this.noteComposerTitle,
    required this.noteComposerPin,
    required this.noteComposerHint,
    required this.noteComposerAuthor,
    // Common
    required this.save,
    required this.cancel,
    required this.add,
    required this.delete,
    required this.edit,
    required this.done,
    required this.continueLabel,
    required this.skip,
    required this.next,
    required this.back,
    required this.confirmDelete,
    required this.chooseFromGallery,
    required this.takePhoto,
    required this.retake,
    required this.remove,
    required this.change,
    required this.close,
    required this.cameraUnavailable,
    required this.notificationSent,
    // Duration / relative
    required this.years,
    required this.year,
    required this.months,
    required this.month,
    required this.days,
    required this.day,
    required this.today,
    required this.tomorrow,
    required this.past,
    required this.justTogether,
    // Onboarding
    required this.obWelcomeTitle,
    required this.obWelcomeBody,
    required this.obStartButton,
    required this.obLanguageTitle,
    required this.obLanguageBody,
    required this.obCoupleTitle,
    required this.obCoupleBody,
    required this.obYourName,
    required this.obPartnerName,
    required this.obAvatarA,
    required this.obAvatarB,
    required this.obAvatarShared,
    required this.obAvatarSharedHint,
    required this.obDateTitle,
    required this.obDateBody,
    required this.obPickDate,
    required this.obEventsTitle,
    required this.obEventsBody,
    required this.obEventsHint,
    required this.obEventsAdded,
    required this.obDoneTitle,
    required this.obDoneBody,
    required this.obFinish,
    // Countdown widget
    required this.countdownEmpty,
    // Thinking-of-you (notificación)
    required this.thinkingSentToast,
    required this.thinkingNotificationTitle,
    required this.thinkingNotificationBodyTemplate,
    required this.thinkingAnonymous,
    required this.thinkingPermissionDenied,
    // Auth
    required this.authWelcomeTitle,
    required this.authWelcomeBody,
    required this.authLoginTitle,
    required this.authSignUpTitle,
    required this.authEmail,
    required this.authPassword,
    required this.authDisplayName,
    required this.authForgotPassword,
    required this.authNoAccount,
    required this.authHasAccount,
    required this.authLoginBtn,
    required this.authSignUpBtn,
    required this.authGoToSignUp,
    required this.authGoToLogin,
    required this.authLogout,
    required this.authInvalidCredentials,
    required this.authWeakPassword,
    required this.authEmailInUse,
    required this.authInvalidEmail,
    required this.authGenericError,
    required this.authRequired,
    required this.authPasswordShort,
    required this.authResetSent,
    // Pairing
    required this.pairTitle,
    required this.pairSubtitle,
    required this.pairCreateCode,
    required this.pairCreateBody,
    required this.pairEnterCode,
    required this.pairEnterBody,
    required this.pairGeneratedLabel,
    required this.pairCodeHint,
    required this.pairJoin,
    required this.pairShareCode,
    required this.pairInviteExpires,
    required this.pairCopyCode,
    required this.pairCodeCopied,
    required this.pairErrorNotFound,
    required this.pairErrorExpired,
    required this.pairErrorAlreadyUsed,
    required this.pairErrorFull,
    required this.pairErrorGeneric,
    required this.pairCancelInvite,
    required this.pairWaitingForPartner,
  });

  final String appName;
  final String tagline;
  // Nav
  final String navTimeline;
  final String navVault;
  final String navCalendar;
  final String navProfile;
  final String navCreate;
  // Timeline
  final String timelineWritingSince;
  final String timelineEmpty;
  final String timelineNoteBy;
  final String timelineDeleteMomentTitle;
  final String timelineDeletePhotoBody;
  final String timelineDeleteNoteBody;
  // Vault
  final String vaultPhotos;
  final String vaultNotes;
  final String vaultTitle;
  final String vaultCategory;
  final String vaultPhotosSubtitle;
  final String vaultNotesSubtitle;
  final String vaultSearchHint;
  final String vaultPhotosEmpty;
  final String vaultNotesEmpty;
  final String vaultAll;
  final String vaultAddPhoto;
  final String vaultTitleOptional;
  final String vaultTitleHint;
  final String vaultAddToVault;
  // Categorías
  final String categoryTrips;
  final String categoryDates;
  final String categoryFirsts;
  final String categoryFamily;
  final String categoryPets;
  final String categoryTimeline;
  // Calendar
  final String calendarUpcoming;
  final String calendarUpcomingEvents;
  final String calendarNoEvents;
  final String calendarAddEvent;
  final String calendarEventTitle;
  final String calendarEventSubtitle;
  final String calendarStartDate;
  final String calendarEndDate;
  final String calendarOptionalEndDate;
  final String calendarSelectDate;
  final String calendarTitleHint;
  final String calendarSubtitleHint;
  final String calendarDeleteEventTitle;
  final String calendarSaveEvent;
  final String calendarEventPresetAnniversary;
  final String calendarEventPresetTrip;
  final String calendarEventPresetDate;
  final String calendarEventPresetMovie;
  final String calendarEventPresetHome;
  final String calendarChoose;
  // Profile
  final String profileTogetherFor;
  final String profileEditProfile;
  final String profileMilestones;
  final String profileAddMilestone;
  final String profileSettings;
  final String profileNotifications;
  final String profilePrivacy;
  final String profileMessageBoard;
  final String profileTheme;
  final String profileLanguage;
  final String profileNameA;
  final String profileNameB;
  final String profileAnniversary;
  final String profilePickGallery;
  final String profilePickCamera;
  final String profileDeleteMilestoneTitle;
  final String profileMilestoneTitle;
  final String profileMilestoneTitleHint;
  final String profileMilestonePlace;
  final String profileMilestonePlaceHint;
  final String profileThemePlaceholder;
  final String profileSaveProfile;
  final String profileEmptyMilestones;
  // Create
  final String createPhoto;
  final String createNote;
  final String createCaption;
  final String createQuote;
  final String createTags;
  final String createPost;
  final String createChoosePhoto;
  final String createCaptureMemory;
  final String createCaptureSubtitle;
  final String createLeaveNote;
  final String createNoteSubtitle;
  final String createWhenPhoto;
  final String createStory;
  final String createTagsLabel;
  final String createWhenNote;
  final String createYourMessage;
  final String createCaptionHint;
  final String createNoteHint;
  final String createCustomTag;
  final String createCustomTagHint;
  final String createMarkAsMilestone;
  final String createMilestoneHint;
  // Message board
  final String messageBoardTitle;
  final String messageBoardSubtitle;
  final String messageBoardEmpty;
  final String messageBoardDeleteTitle;
  final String messageBoardDeleteBody;
  final String noteText;
  final String noteColor;
  final String noteComposerTitle;
  final String noteComposerPin;
  final String noteComposerHint;
  final String noteComposerAuthor;
  // Common
  final String save;
  final String cancel;
  final String add;
  final String delete;
  final String edit;
  final String done;
  final String continueLabel;
  final String skip;
  final String next;
  final String back;
  final String confirmDelete;
  final String chooseFromGallery;
  final String takePhoto;
  final String retake;
  final String remove;
  final String change;
  final String close;
  final String cameraUnavailable;
  final String notificationSent;
  // Duration
  final String years;
  final String year;
  final String months;
  final String month;
  final String days;
  final String day;
  final String today;
  final String tomorrow;
  final String past;
  final String justTogether;
  // Onboarding
  final String obWelcomeTitle;
  final String obWelcomeBody;
  final String obStartButton;
  final String obLanguageTitle;
  final String obLanguageBody;
  final String obCoupleTitle;
  final String obCoupleBody;
  final String obYourName;
  final String obPartnerName;
  final String obAvatarA;
  final String obAvatarB;
  final String obAvatarShared;
  final String obAvatarSharedHint;
  final String obDateTitle;
  final String obDateBody;
  final String obPickDate;
  final String obEventsTitle;
  final String obEventsBody;
  final String obEventsHint;
  final String obEventsAdded;
  final String obDoneTitle;
  final String obDoneBody;
  final String obFinish;
  // Countdown
  final String countdownEmpty;
  // Thinking-of-you
  final String thinkingSentToast;
  final String thinkingNotificationTitle;
  final String thinkingNotificationBodyTemplate;
  final String thinkingAnonymous;
  final String thinkingPermissionDenied;
  // Auth
  final String authWelcomeTitle;
  final String authWelcomeBody;
  final String authLoginTitle;
  final String authSignUpTitle;
  final String authEmail;
  final String authPassword;
  final String authDisplayName;
  final String authForgotPassword;
  final String authNoAccount;
  final String authHasAccount;
  final String authLoginBtn;
  final String authSignUpBtn;
  final String authGoToSignUp;
  final String authGoToLogin;
  final String authLogout;
  final String authInvalidCredentials;
  final String authWeakPassword;
  final String authEmailInUse;
  final String authInvalidEmail;
  final String authGenericError;
  final String authRequired;
  final String authPasswordShort;
  final String authResetSent;
  // Pairing
  final String pairTitle;
  final String pairSubtitle;
  final String pairCreateCode;
  final String pairCreateBody;
  final String pairEnterCode;
  final String pairEnterBody;
  final String pairGeneratedLabel;
  final String pairCodeHint;
  final String pairJoin;
  final String pairShareCode;
  final String pairInviteExpires;
  final String pairCopyCode;
  final String pairCodeCopied;
  final String pairErrorNotFound;
  final String pairErrorExpired;
  final String pairErrorAlreadyUsed;
  final String pairErrorFull;
  final String pairErrorGeneric;
  final String pairCancelInvite;
  final String pairWaitingForPartner;

  /// Formatea "in X days/weeks/months" según locale.
  String relativeLabel(int days) {
    if (days < 0) return past;
    if (days == 0) return today;
    if (days == 1) return tomorrow;
    if (days < 7) return _formatIn('$days ${days == 1 ? day : this.days}');
    if (days < 30) {
      final w = (days / 7).round();
      return _formatIn('$w ${w == 1 ? _weekSingular : _weekPlural}');
    }
    final m = (days / 30).round();
    return _formatIn('$m ${m == 1 ? month : months}');
  }

  String get _weekSingular => this == _es ? 'semana' : 'week';
  String get _weekPlural => this == _es ? 'semanas' : 'weeks';

  String _formatIn(String quantity) {
    if (this == _es) return 'en $quantity';
    return 'in $quantity';
  }

  /// Descomposición humana ("3 Years, 2 Months").
  String durationLabel({required int years, required int months}) {
    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? year : this.years}');
    if (months > 0) parts.add('$months ${months == 1 ? month : this.months}');
    if (parts.isEmpty) return justTogether;
    return parts.join(', ');
  }

  /// Mensaje de notificación "pensando en ti" con [name] insertado.
  String thinkingBody(String name) =>
      thinkingNotificationBodyTemplate.replaceAll(
        '{name}',
        name.trim().isEmpty ? thinkingAnonymous : name.trim(),
      );

  /// Nombre completo del mes 1-indexado ("January" / "Enero").
  String monthNameFull(int month) {
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const es = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final list = this == _es ? es : en;
    return list[(month - 1).clamp(0, 11)];
  }

  /// Nombre corto del mes 1-indexado ("Jan" / "Ene").
  String monthNameShort(int month) {
    const en = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const es = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final list = this == _es ? es : en;
    return list[(month - 1).clamp(0, 11)];
  }

  /// Nombre corto de día de la semana ("Sun" / "Dom"). 0=Sunday...6=Saturday.
  String weekdayNameShort(int weekdayZeroSun) {
    const en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const es = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final list = this == _es ? es : en;
    return list[weekdayZeroSun.clamp(0, 6)];
  }

  /// Formato corto de fecha ("Aug 12, 2024" / "12 Ago 2024").
  String formatShortDate(DateTime d) {
    if (this == _es) {
      return '${d.day} ${monthNameShort(d.month)} ${d.year}';
    }
    return '${monthNameShort(d.month)} ${d.day}, ${d.year}';
  }

  /// Traduce una categoría "conocida" (Trips, Dates, ...) al idioma actual.
  /// Categorías desconocidas se devuelven tal cual.
  String translateCategory(String raw) {
    switch (raw) {
      case 'All':
        return vaultAll;
      case 'Trips':
        return categoryTrips;
      case 'Dates':
        return categoryDates;
      case 'Firsts':
        return categoryFirsts;
      case 'Family':
        return categoryFamily;
      case 'Pets':
        return categoryPets;
      case 'Timeline':
        return categoryTimeline;
      default:
        return raw;
    }
  }
}

const _en = AppStrings._(
  appName: 'Tandem',
  tagline: 'Our little universe.',
  navTimeline: 'Timeline',
  navVault: 'Vault',
  navCalendar: 'Calendar',
  navProfile: 'Profile',
  navCreate: 'Create',
  timelineWritingSince: 'Writing our story since',
  timelineEmpty: 'Tap + to share your first moment.',
  timelineNoteBy: 'A note by',
  timelineDeleteMomentTitle: 'Delete this moment?',
  timelineDeletePhotoBody: 'This photo will be removed from the timeline.',
  timelineDeleteNoteBody: 'This note will be removed from the timeline.',
  vaultPhotos: 'Photos',
  vaultNotes: 'Notes',
  vaultTitle: 'Vault',
  vaultCategory: 'Category',
  vaultPhotosSubtitle: 'Your shared memories, beautifully preserved.',
  vaultNotesSubtitle: "Little notes you've left for each other.",
  vaultSearchHint: 'Search memories, places, dates...',
  vaultPhotosEmpty: 'No photos in this category yet.',
  vaultNotesEmpty: 'No notes yet — tap the button to create one.',
  vaultAll: 'All',
  vaultAddPhoto: 'Add a photo',
  vaultTitleOptional: 'Title (optional)',
  vaultTitleHint: 'e.g. Sunday Coffee',
  vaultAddToVault: 'Add to Vault',
  categoryTrips: 'Trips',
  categoryDates: 'Dates',
  categoryFirsts: 'Firsts',
  categoryFamily: 'Family',
  categoryPets: 'Pets',
  categoryTimeline: 'Timeline',
  calendarUpcoming: 'Upcoming',
  calendarUpcomingEvents: 'Upcoming Events',
  calendarNoEvents: 'No upcoming events. Tap "+ Add Event" to plan something.',
  calendarAddEvent: 'Add Event',
  calendarEventTitle: 'Title',
  calendarEventSubtitle: 'Subtitle (optional)',
  calendarStartDate: 'Start date',
  calendarEndDate: 'End date',
  calendarOptionalEndDate: 'Ends (optional)',
  calendarSelectDate: 'Select date',
  calendarTitleHint: 'e.g. Our Anniversary',
  calendarSubtitleHint: "e.g. Dinner at Luigi's",
  calendarDeleteEventTitle: 'Delete event?',
  calendarSaveEvent: 'Save event',
  calendarEventPresetAnniversary: 'Anniversary',
  calendarEventPresetTrip: 'Trip',
  calendarEventPresetDate: 'Date Night',
  calendarEventPresetMovie: 'Movie',
  calendarEventPresetHome: 'Home',
  calendarChoose: 'Choose date',
  profileTogetherFor: 'Together for',
  profileEditProfile: 'Edit profile',
  profileMilestones: 'Milestones',
  profileAddMilestone: 'Add milestone',
  profileSettings: 'Settings',
  profileNotifications: 'Notifications',
  profilePrivacy: 'Private mode',
  profileMessageBoard: 'Message board',
  profileTheme: 'Theme & Appearance',
  profileLanguage: 'Language',
  profileNameA: 'Your name',
  profileNameB: 'Partner name',
  profileAnniversary: 'Anniversary date',
  profilePickGallery: 'Gallery',
  profilePickCamera: 'Camera',
  profileDeleteMilestoneTitle: 'Delete milestone?',
  profileMilestoneTitle: 'Title',
  profileMilestoneTitleHint: 'e.g. First Date',
  profileMilestonePlace: 'Place (optional)',
  profileMilestonePlaceHint: 'e.g. Paris',
  profileThemePlaceholder: 'Theme picker — coming soon',
  profileSaveProfile: 'Save profile',
  profileEmptyMilestones: 'No milestones yet. Tap + to add one.',
  createPhoto: 'Photo',
  createNote: 'Note',
  createCaption: 'Write a caption...',
  createQuote: 'Write a little note...',
  createTags: 'Tags',
  createPost: 'Post',
  createChoosePhoto: 'Choose a photo to share',
  createCaptureMemory: 'Capture a Memory',
  createCaptureSubtitle: 'Save a special moment to your timeline.',
  createLeaveNote: 'Leave a Note',
  createNoteSubtitle: 'Write a sweet thought for your timeline.',
  createWhenPhoto: 'When did this happen?',
  createStory: "What's the story?",
  createTagsLabel: 'Tag this memory',
  createWhenNote: 'When',
  createYourMessage: 'Your message',
  createCaptionHint: 'Write a sweet caption...',
  createNoteHint: 'Write your note...',
  createCustomTag: 'Custom Tag',
  createCustomTagHint: 'e.g. Milestone',
  createMarkAsMilestone: 'Mark as milestone',
  createMilestoneHint: 'Also saves this to Milestones on your profile.',
  messageBoardTitle: 'Message board',
  messageBoardSubtitle: 'Little love notes for us.',
  messageBoardEmpty: 'No notes yet. Leave the first one.',
  messageBoardDeleteTitle: 'Delete note?',
  messageBoardDeleteBody: 'This will remove the sticky note.',
  noteText: 'Write a note...',
  noteColor: 'Color',
  noteComposerTitle: 'Leave a note',
  noteComposerPin: 'Pin to board',
  noteComposerHint: 'Write a little something...',
  noteComposerAuthor: 'From',
  save: 'Save',
  cancel: 'Cancel',
  add: 'Add',
  delete: 'Delete',
  edit: 'Edit',
  done: 'Done',
  continueLabel: 'Continue',
  skip: 'Skip',
  next: 'Next',
  back: 'Back',
  confirmDelete: 'Delete this item?',
  chooseFromGallery: 'Choose from gallery',
  takePhoto: 'Take a photo',
  retake: 'Retake',
  remove: 'Remove',
  change: 'Change',
  close: 'Close',
  cameraUnavailable: 'Camera not available',
  notificationSent: 'Notification sent',
  years: 'Years',
  year: 'Year',
  months: 'Months',
  month: 'Month',
  days: 'days',
  day: 'day',
  today: 'Today',
  tomorrow: 'Tomorrow',
  past: 'Past',
  justTogether: 'Just Together',
  obWelcomeTitle: 'Welcome to Tandem',
  obWelcomeBody: "Let's set up your little universe together.",
  obStartButton: "Let's start",
  obLanguageTitle: 'Choose your language',
  obLanguageBody: 'You can change this later in Settings.',
  obCoupleTitle: 'Who are you two?',
  obCoupleBody: 'Names and avatars for the two of you.',
  obYourName: 'Your name',
  obPartnerName: "Partner's name",
  obAvatarA: 'Your photo',
  obAvatarB: "Partner's photo",
  obAvatarShared: 'A photo of you two together',
  obAvatarSharedHint: 'Shown in the top bar of the app.',
  obDateTitle: 'When did it all start?',
  obDateBody: "Pick your anniversary date. We'll count every day.",
  obPickDate: 'Pick a date',
  obEventsTitle: 'Important dates',
  obEventsBody: 'Add birthdays, trips, anniversaries...',
  obEventsHint: 'Event name',
  obEventsAdded: 'Added',
  obDoneTitle: "You're all set",
  obDoneBody: 'Enjoy your Tandem.',
  obFinish: 'Enter Tandem',
  countdownEmpty: 'Add an important date',
  thinkingSentToast: '💗 Sent!',
  thinkingNotificationTitle: 'Tandem 💗',
  thinkingNotificationBodyTemplate: '{name} is thinking of you',
  thinkingAnonymous: 'Someone',
  thinkingPermissionDenied: 'Enable notifications to send love',
  authWelcomeTitle: 'Welcome to Tandem',
  authWelcomeBody: 'Sign in or create an account to sync with your partner.',
  authLoginTitle: 'Sign in',
  authSignUpTitle: 'Create account',
  authEmail: 'Email',
  authPassword: 'Password',
  authDisplayName: 'Your name',
  authForgotPassword: 'Forgot password?',
  authNoAccount: "Don't have an account?",
  authHasAccount: 'Already have an account?',
  authLoginBtn: 'Sign in',
  authSignUpBtn: 'Create account',
  authGoToSignUp: 'Sign up',
  authGoToLogin: 'Sign in',
  authLogout: 'Sign out',
  authInvalidCredentials: 'Incorrect email or password.',
  authWeakPassword: 'Password must be at least 6 characters.',
  authEmailInUse: 'That email is already in use.',
  authInvalidEmail: 'The email address is not valid.',
  authGenericError: 'Something went wrong. Try again.',
  authRequired: 'Required',
  authPasswordShort: 'Min. 6 characters',
  authResetSent: 'Password reset email sent.',
  pairTitle: 'Connect with your partner',
  pairSubtitle: 'Share a 6-digit code with them, or enter theirs.',
  pairCreateCode: 'Create code',
  pairCreateBody: 'Generate a code for your partner to enter on their phone.',
  pairEnterCode: 'Enter code',
  pairEnterBody: 'Enter the 6-digit code that your partner shared with you.',
  pairGeneratedLabel: 'Share this code with your partner:',
  pairCodeHint: '6-digit code',
  pairJoin: 'Join',
  pairShareCode: 'Share',
  pairInviteExpires: 'Expires in {minutes} min',
  pairCopyCode: 'Copy',
  pairCodeCopied: 'Code copied',
  pairErrorNotFound: "That code doesn't exist.",
  pairErrorExpired: 'That code expired. Ask for a new one.',
  pairErrorAlreadyUsed: 'That code was already used.',
  pairErrorFull: 'That couple already has 2 members.',
  pairErrorGeneric: 'Could not join. Try again.',
  pairCancelInvite: 'Cancel invite',
  pairWaitingForPartner: 'Waiting for your partner to join...',
);

const _es = AppStrings._(
  appName: 'Tandem',
  tagline: 'Nuestro pequeño universo.',
  navTimeline: 'Línea',
  navVault: 'Álbum',
  navCalendar: 'Calendario',
  navProfile: 'Perfil',
  navCreate: 'Crear',
  timelineWritingSince: 'Escribiendo nuestra historia desde',
  timelineEmpty: 'Toca + para compartir tu primer momento.',
  timelineNoteBy: 'Una nota de',
  timelineDeleteMomentTitle: '¿Borrar este momento?',
  timelineDeletePhotoBody: 'Esta foto se quitará de la línea.',
  timelineDeleteNoteBody: 'Esta nota se quitará de la línea.',
  vaultPhotos: 'Fotos',
  vaultNotes: 'Notas',
  vaultTitle: 'Álbum',
  vaultCategory: 'Categoría',
  vaultPhotosSubtitle: 'Sus recuerdos compartidos, guardados con cariño.',
  vaultNotesSubtitle: 'Notitas que se han dejado.',
  vaultSearchHint: 'Buscar recuerdos, lugares, fechas...',
  vaultPhotosEmpty: 'Aún no hay fotos en esta categoría.',
  vaultNotesEmpty: 'Aún no hay notas — toca el botón para crear una.',
  vaultAll: 'Todas',
  vaultAddPhoto: 'Agregar foto',
  vaultTitleOptional: 'Título (opcional)',
  vaultTitleHint: 'ej. Café del domingo',
  vaultAddToVault: 'Agregar al álbum',
  categoryTrips: 'Viajes',
  categoryDates: 'Citas',
  categoryFirsts: 'Primeras veces',
  categoryFamily: 'Familia',
  categoryPets: 'Mascotas',
  categoryTimeline: 'Línea',
  calendarUpcoming: 'Próximos',
  calendarUpcomingEvents: 'Próximos eventos',
  calendarNoEvents:
      'Sin eventos próximos. Toca "+ Agregar evento" para planear algo.',
  calendarAddEvent: 'Agregar evento',
  calendarEventTitle: 'Título',
  calendarEventSubtitle: 'Descripción (opcional)',
  calendarStartDate: 'Fecha de inicio',
  calendarEndDate: 'Fecha de fin',
  calendarOptionalEndDate: 'Termina (opcional)',
  calendarSelectDate: 'Elige la fecha',
  calendarTitleHint: 'ej. Nuestro aniversario',
  calendarSubtitleHint: "ej. Cena en Luigi's",
  calendarDeleteEventTitle: '¿Borrar evento?',
  calendarSaveEvent: 'Guardar evento',
  calendarEventPresetAnniversary: 'Aniversario',
  calendarEventPresetTrip: 'Viaje',
  calendarEventPresetDate: 'Noche de cita',
  calendarEventPresetMovie: 'Película',
  calendarEventPresetHome: 'Casa',
  calendarChoose: 'Elegir fecha',
  profileTogetherFor: 'Juntos hace',
  profileEditProfile: 'Editar perfil',
  profileMilestones: 'Hitos',
  profileAddMilestone: 'Agregar hito',
  profileSettings: 'Ajustes',
  profileNotifications: 'Notificaciones',
  profilePrivacy: 'Modo privado',
  profileMessageBoard: 'Tablero de notas',
  profileTheme: 'Tema y apariencia',
  profileLanguage: 'Idioma',
  profileNameA: 'Tu nombre',
  profileNameB: 'Nombre de tu pareja',
  profileAnniversary: 'Fecha de aniversario',
  profilePickGallery: 'Galería',
  profilePickCamera: 'Cámara',
  profileDeleteMilestoneTitle: '¿Borrar hito?',
  profileMilestoneTitle: 'Título',
  profileMilestoneTitleHint: 'ej. Primera cita',
  profileMilestonePlace: 'Lugar (opcional)',
  profileMilestonePlaceHint: 'ej. París',
  profileThemePlaceholder: 'Selector de tema — próximamente',
  profileSaveProfile: 'Guardar perfil',
  profileEmptyMilestones: 'Aún no hay hitos. Toca + para agregar uno.',
  createPhoto: 'Foto',
  createNote: 'Nota',
  createCaption: 'Escribe un pie de foto...',
  createQuote: 'Escribe una notita...',
  createTags: 'Etiquetas',
  createPost: 'Publicar',
  createChoosePhoto: 'Elige una foto para compartir',
  createCaptureMemory: 'Captura un recuerdo',
  createCaptureSubtitle: 'Guarda un momento especial en tu línea.',
  createLeaveNote: 'Deja una nota',
  createNoteSubtitle: 'Escribe un pensamiento lindo para su línea.',
  createWhenPhoto: '¿Cuándo pasó esto?',
  createStory: '¿Cuál es la historia?',
  createTagsLabel: 'Etiqueta este recuerdo',
  createWhenNote: 'Cuándo',
  createYourMessage: 'Tu mensaje',
  createCaptionHint: 'Escribe un pie de foto lindo...',
  createNoteHint: 'Escribe tu nota...',
  createCustomTag: 'Etiqueta personalizada',
  createCustomTagHint: 'ej. Hito',
  createMarkAsMilestone: 'Marcar como hito',
  createMilestoneHint: 'También lo guarda en Hitos de tu perfil.',
  messageBoardTitle: 'Tablero de notas',
  messageBoardSubtitle: 'Notitas de amor para nosotros.',
  messageBoardEmpty: 'Sin notas todavía. Deja la primera.',
  messageBoardDeleteTitle: '¿Borrar nota?',
  messageBoardDeleteBody: 'Esto quitará la nota adhesiva.',
  noteText: 'Escribe una nota...',
  noteColor: 'Color',
  noteComposerTitle: 'Deja una nota',
  noteComposerPin: 'Fijar al tablero',
  noteComposerHint: 'Escribe algo lindo...',
  noteComposerAuthor: 'De',
  save: 'Guardar',
  cancel: 'Cancelar',
  add: 'Agregar',
  delete: 'Borrar',
  edit: 'Editar',
  done: 'Listo',
  continueLabel: 'Continuar',
  skip: 'Omitir',
  next: 'Siguiente',
  back: 'Atrás',
  confirmDelete: '¿Borrar este elemento?',
  chooseFromGallery: 'Elegir de la galería',
  takePhoto: 'Tomar foto',
  retake: 'Repetir',
  remove: 'Quitar',
  change: 'Cambiar',
  close: 'Cerrar',
  cameraUnavailable: 'Cámara no disponible',
  notificationSent: 'Notificación enviada',
  years: 'Años',
  year: 'Año',
  months: 'Meses',
  month: 'Mes',
  days: 'días',
  day: 'día',
  today: 'Hoy',
  tomorrow: 'Mañana',
  past: 'Pasado',
  justTogether: 'Recién juntos',
  obWelcomeTitle: 'Bienvenidos a Tandem',
  obWelcomeBody: 'Vamos a preparar su pequeño universo.',
  obStartButton: 'Empezar',
  obLanguageTitle: 'Elige tu idioma',
  obLanguageBody: 'Puedes cambiarlo después en Ajustes.',
  obCoupleTitle: '¿Quiénes son ustedes?',
  obCoupleBody: 'Nombres y fotos para los dos.',
  obYourName: 'Tu nombre',
  obPartnerName: 'Nombre de tu pareja',
  obAvatarA: 'Tu foto',
  obAvatarB: 'Foto de tu pareja',
  obAvatarShared: 'Una foto de ustedes dos juntos',
  obAvatarSharedHint: 'Se muestra en la barra superior de la app.',
  obDateTitle: '¿Cuándo empezó todo?',
  obDateBody: 'Elige la fecha de su aniversario. Contaremos cada día.',
  obPickDate: 'Elige la fecha',
  obEventsTitle: 'Fechas importantes',
  obEventsBody: 'Agrega cumpleaños, viajes, aniversarios...',
  obEventsHint: 'Nombre del evento',
  obEventsAdded: 'Agregado',
  obDoneTitle: 'Todo listo',
  obDoneBody: 'Disfruten su Tandem.',
  obFinish: 'Entrar a Tandem',
  countdownEmpty: 'Agrega una fecha importante',
  thinkingSentToast: '💗 ¡Enviado!',
  thinkingNotificationTitle: 'Tandem 💗',
  thinkingNotificationBodyTemplate: '{name} está pensando en ti',
  thinkingAnonymous: 'Alguien',
  thinkingPermissionDenied: 'Activa las notificaciones para enviar amor',
  authWelcomeTitle: 'Bienvenidos a Tandem',
  authWelcomeBody:
      'Inicia sesión o crea una cuenta para sincronizar con tu pareja.',
  authLoginTitle: 'Iniciar sesión',
  authSignUpTitle: 'Crear cuenta',
  authEmail: 'Correo',
  authPassword: 'Contraseña',
  authDisplayName: 'Tu nombre',
  authForgotPassword: '¿Olvidaste tu contraseña?',
  authNoAccount: '¿No tienes cuenta?',
  authHasAccount: '¿Ya tienes cuenta?',
  authLoginBtn: 'Iniciar sesión',
  authSignUpBtn: 'Crear cuenta',
  authGoToSignUp: 'Regístrate',
  authGoToLogin: 'Iniciar sesión',
  authLogout: 'Cerrar sesión',
  authInvalidCredentials: 'Correo o contraseña incorrectos.',
  authWeakPassword: 'La contraseña debe tener al menos 6 caracteres.',
  authEmailInUse: 'Ese correo ya está en uso.',
  authInvalidEmail: 'El correo no es válido.',
  authGenericError: 'Algo salió mal. Intenta de nuevo.',
  authRequired: 'Requerido',
  authPasswordShort: 'Mín. 6 caracteres',
  authResetSent: 'Enviamos el correo para restablecer la contraseña.',
  pairTitle: 'Conéctate con tu pareja',
  pairSubtitle:
      'Comparte un código de 6 dígitos con tu pareja, o ingresa el suyo.',
  pairCreateCode: 'Crear código',
  pairCreateBody:
      'Genera un código para que tu pareja lo ingrese en su teléfono.',
  pairEnterCode: 'Ingresar código',
  pairEnterBody:
      'Ingresa el código de 6 dígitos que tu pareja compartirá contigo.',
  pairGeneratedLabel: 'Comparte este código con tu pareja:',
  pairCodeHint: 'Código de 6 dígitos',
  pairJoin: 'Unirse',
  pairShareCode: 'Compartir',
  pairInviteExpires: 'Expira en {minutes} min',
  pairCopyCode: 'Copiar',
  pairCodeCopied: 'Código copiado',
  pairErrorNotFound: 'Ese código no existe.',
  pairErrorExpired: 'Ese código expiró. Pide uno nuevo.',
  pairErrorAlreadyUsed: 'Ese código ya se usó.',
  pairErrorFull: 'Esa pareja ya tiene 2 miembros.',
  pairErrorGeneric: 'No se pudo unir. Intenta de nuevo.',
  pairCancelInvite: 'Cancelar invitación',
  pairWaitingForPartner: 'Esperando a que tu pareja se una...',
);

AppStrings stringsFor(AppLocale locale) => locale == AppLocale.es ? _es : _en;

/// Helper: `context.l10n.appName` para acceder al bundle en cualquier
/// widget que esté debajo de un [AppScope].
extension AppL10nContext on BuildContext {
  AppStrings get l10n => stringsFor(AppScope.of(this).locale);
}

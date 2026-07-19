import 'package:flutter/material.dart';

import '../theme/cozy_colors.dart';

/// Modelo simple para un momento del timeline (foto o nota de texto).
class TimelineMoment {
  const TimelineMoment.photo({
    required this.date,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    this.aspectRatio = 4 / 3,
  }) : type = TimelineMomentType.photo,
       quote = '';

  const TimelineMoment.note({required this.date, required this.quote})
    : type = TimelineMomentType.note,
      imageUrl = '',
      caption = '',
      likes = 0,
      aspectRatio = 1;

  final TimelineMomentType type;
  final String date;
  final String imageUrl;
  final String caption;
  final int likes;
  final String quote;
  final double aspectRatio;
}

enum TimelineMomentType { photo, note }

class TimelineGroup {
  const TimelineGroup({
    required this.monthLabel,
    required this.moments,
    this.milestone,
  });

  final String monthLabel;
  final List<TimelineMoment> moments;
  final String? milestone;
}

/// Notas del Message Board.
class StickyNote {
  const StickyNote({
    required this.text,
    required this.color,
    required this.timestamp,
    required this.author,
    required this.avatarBg,
    required this.avatarFg,
    this.tilt = 0,
  });

  final String text;
  final Color color;
  final String timestamp;
  final String author;
  final Color avatarBg;
  final Color avatarFg;
  final double tilt;
}

/// Fotos del vault (galería masonry).
class VaultPhoto {
  const VaultPhoto({
    required this.url,
    this.title,
    this.date,
    this.aspectRatio = 1,
    this.badge,
    this.category = 'All',
  });

  final String url;
  final String? title;
  final String? date;
  final double aspectRatio;
  final String? badge;
  final String category;
}

/// Evento del calendario compartido.
class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.thumbnailUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String thumbnailUrl;
}

/// Milestone del perfil.
class Milestone {
  const Milestone({
    required this.title,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.wide = false,
    this.place,
  });

  final String title;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool wide;
  final String? place;
}

/// Datos dummy que replican lo que muestran los mockups de Stitch.
///
/// Se mantienen las mismas URLs de imagen usadas en el HTML para preservar
/// la fidelidad visual 1:1 durante esta primera iteración.
class MockData {
  const MockData._();

  static const String coupleHeroAvatar1 =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAqTGf2pXpdNQ_eZu12OeJFx4DXPxrOoum0XPH8TM-GE5YzzG47Vi84q0DojRbHxZCcQ5Y-Kuuq5EkIAvTsKE2GLI8qz_5fIwTjgzFsP3-NdShaSzMbLHTUyujjpsWCqWy9Vnx2tseGIa57eo1u0Sd0_A6SJagGcgens_fQoS5JJgdJq0hxpbxhc-lWz_VRyh66jLGbn66dfSnHlowKJWmto3HrotPXVW_aMUYzz-2Ui6o77nVwaYSB';

  static const String coupleHeroAvatar2 =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAIdBpSbeLI1ZPfbPNSNRVREgSywAUvQtNaXjnzNK3-rLDFkn6Q-my_PguouELHW_-qL9gPEVVkacNRRD1Gk3SFw2N_FmynOFG5IApyXfyjAFzg6daDDQG9yNvxz7t5lMxtGKBwO_TO41G3cptH6d5j7nlDt0Dq7lTVhIm4v8Utp89erU6xjDcSbazVtFSgBeMw91LjQN_PoSZ28arSngL4nZPeWd8nIAKx02w2gOZfQS9jdM4Zx-R3';

  static const String profileHeroAvatar1 =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB7Eto0AVVtJujqGzE0mOY5ayF-MmticnGxUbWdg0HLBaq8_lqn-Gl7Pu__aADIqXFJQo3757heETIfmvqbi79HVjZzm8cB476MEViKDAEjAmWHsDANLZaVEwJhwqO0CHViK2bIx_pOw39jmAIgE8FsMVdlb00L_fUHld0r8tZAL0ucZqqzg8q8rwhgZwY7NuwK-UPc7zXLzKzK2_Gj6r-W8htKRJTqXBYLxkkeAfcRQYbfpdEpSL0f';
  static const String profileHeroAvatar2 =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA5g-S8acbI5EOWN6w8Esdgivp7wdv4ilummPwDrA7hg7qo9Zf0ueZCOxVwdBz7bok3c5wfV87lglW9i3XGdAYwwv7_E86G-KoDP5Ask7FklZfypg2o1WjyB8cMUocTciP5yvZqysQZxRrqEvKvOdwUGwJA69ey0_Z82u1rqYnpvb6Gzpa9LoXXHlWrGdptPuvQ5yM_vxxE4a5VSebKk8pVzEC-HfQk6hCl_w27r3dwpllgSYpXefdV';

  static const List<TimelineGroup> timeline = [
    TimelineGroup(
      monthLabel: 'AUGUST 2023',
      moments: [
        TimelineMoment.photo(
          date: 'Aug 24, 2023',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBLuib7eIbqPq-3dLPOdiAfjqB1g76obtKSdNRPnwiWzI0Yd3PddizX9vtUaqKzyBlNypMLBizq9n4qDTxLHlHEYIMV6tkFcnBshhf4pm1bhtxVPs93pBK2Z1C86C30K-DCs0nz9-Ai-FKKYPYMDJ7UQNmsQwtld8irzxdYYDpSbE--5cWEPl_394TmGOCqQ-vJFxwIEk1dVAT3A0LmJ4bt4gkp07n918RrCG7AEwr-vhYXrw8CB8_3',
          caption:
              'Weekend getaway at the lake cabin. The sunsets here never get old. 🌅',
          likes: 12,
        ),
        TimelineMoment.note(
          date: 'Aug 12, 2023',
          quote:
              '"I loved waking up to the smell of coffee and pancakes this morning. Thank you for making my birthday so special."',
        ),
      ],
    ),
    TimelineGroup(
      monthLabel: 'JULY 2023',
      milestone: '4 Years Together',
      moments: [
        TimelineMoment.photo(
          date: 'Jul 15, 2023',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCjnVt1C4DSjX9iQVbG6FoqPF4JGSih3wqcGElSLo84-pdRZFHQkEYZBv-ek70ALjGZCCt7RXlZuBGM1QeYEUoqF-vvMjwds2pH3ZZh9NncWxsa85mMwMHkYxaxYHnVEC93hDBF_QvCQ55TJ3uRQds-RyS8cXk-bBmjHkCuEpvqqTczYvpbsNVyzV3tU1npGlXXUQSfd7jl_O7gBgSbP_sb5w2sWtCRk4mEHqDkVU4MZVV_xep1C9m0',
          caption:
              'Anniversary dinner at our favorite spot. Here\'s to many more years. 🥂',
          likes: 24,
          aspectRatio: 1,
        ),
      ],
    ),
  ];

  static const List<StickyNote> stickyNotes = [
    StickyNote(
      text: "Don't forget to grab oat milk on the way home! 🥛 Love you! 💕",
      color: CozyColors.noteYellow,
      timestamp: '10:42 AM',
      author: 'E',
      avatarBg: CozyColors.secondaryContainer,
      avatarFg: CozyColors.onSecondaryContainer,
      tilt: 2,
    ),
    StickyNote(
      text:
          'I love you more than pizza. And you know how much I love pizza. 🍕',
      color: CozyColors.notePink,
      timestamp: 'Yesterday',
      author: 'M',
      avatarBg: CozyColors.primaryContainer,
      avatarFg: CozyColors.onPrimaryContainer,
      tilt: -3,
    ),
    StickyNote(
      text:
          'Movie night tonight! I picked the movie, you pick the snacks. Deal? 🍿🎬',
      color: CozyColors.noteBlue,
      timestamp: 'Tuesday',
      author: 'E',
      avatarBg: CozyColors.tertiaryContainer,
      avatarFg: CozyColors.onTertiaryContainer,
      tilt: 1,
    ),
    StickyNote(
      text:
          "Thank you for being my safe place. Can't wait to see you tonight. ✨",
      color: CozyColors.notePurple,
      timestamp: 'Monday',
      author: 'M',
      avatarBg: CozyColors.primaryContainer,
      avatarFg: CozyColors.onPrimaryContainer,
      tilt: -2,
    ),
  ];

  static const List<VaultPhoto> vaultPhotos = [
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDTGaE5Vpx1eARv6peePFcKPnBguLy8JhMW_jxzaAkgXcx9AoG5iMWs76gTND5w9_zhx6OJWuHDo6yjPQaFhlouDzTmipNnuBCKnMj8_Tkq7Nn2ABFdwjvUEKRVMJjAuMsGV045-IQAUI08tu_IxDeg7MAybFaeA8mHG-1kIwAFRtmLRxqwBeYcym5-kIzfLIR944G7w7R5GTrz9lDQ6cTBnXipzL7QN63yYheDqZPu2k1y_9VjE0xG',
      title: 'Paris Getaway',
      date: 'Oct 2023',
      aspectRatio: 2 / 3,
      category: 'Trips',
    ),
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDegxLOpDkUXp_ja0CwTsW4CFl-6xug_TucTwE2VhjflxbYYCxrHFTQ4ppv8q2WE2Liaf1kZcywP9us5SfwJknfHiOEWV0aTiya0NRs8nXwU5GPq9vQwkzo8L5eg0gIHIpShnh9QdslHOdpl_oov8mwxTslKw6rmk_GPPOJhoI3CNBksciLfXV9TGEIIaL-Tz-edyqMZFl5yOBy1Nq98MPSbvqeyl0lRJqQq399HWCkM5CDDfc4It0e',
      title: 'Sunday Coffee',
      category: 'Dates',
    ),
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDVhvb8M0f6U2iS7CnVGy389Lb-1OHN948WVSiZpj_dW_D0kQqp-xokgSpH18EEZcZ9_ipF5mE5uBWZFMtBuGxO7wpHD9mbZ7XILuGTVI7Z8Ger0NTR2c-yf-QfnDgSxa4YvZ1E7GQnvu3ZFMOfRgbMv7XJ0Ag_jNK9v7L2FIDFLsrFo8bos4vhtvkNdLB5N8oZgigZPWtvVLdYeoMz3rArHmLjRf080j4ZEh3xFaMHlpdyFWpycbSF',
      title: 'Lazy Afternoons',
      aspectRatio: 3 / 5,
    ),
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDqU3m0Z0YQ9jdVIhDklkdVV21cuqnzFimP5CJXz1OdVnD8_I0f1mdh9Zk3Bf19IDmhavdUhfHSlqxbYtbHZrEwPOkXX7U0_BumK088J-jpuDfV3ONknvgY9RZtHwOGFOEezcM4ngw_jyARo4ERJ0du0-m5sz9K0Vah_82zng6gdlR6wessG_8RKs2WI2A9FJ35-MKxZn89RC-LGRrNGnyOB6zDtlwaubPcH0QgH4WtJMdLck8bKql2',
      aspectRatio: 4 / 3,
    ),
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCr3gPuIAG9Em_bMktoguMwsXNv75ggazaLwXr8bnkQMg3I7uqiy4xYIuS8hPbSay4eAsHEEHGCJJhXsJ4roEhaUYrbpKBAoKjpYzLOGsH--tdxsGkTMp3y8-ZNcbzctpe7fuNOAwi-IvCrs2pt-dYIT92zLpi-CU0maltFeARjRlTqHjlx95SvoRE-4CqgLvXibM7DICFe0i9XXy9H1P0M8JNotoinZHl03UF7z2uWflK2X_hoIrQ_',
      badge: 'Anniversary',
      category: 'Firsts',
    ),
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAL9eThuyeUozyBfx3x17SbOLikPLF0SnC7NTlhPzPLeoLu0oX513AYtDFaM2ixjw2Pkva9BzjHfVjOlKqP8jw4Mz4IW53OL0u9Ve8grrw1Y08Hew1Ja84EXER7JY6jYTvWokFxI6LtPwsv96DupqpYj9BNA2Fulm8WvXzhug_eYXTLGtzafjv8eFqaURnkmhUedI9C4UajVndGy4XR1vVg7VE8O2NENlviz2EA__J5S8bCOaH-5ZVa',
      aspectRatio: 2 / 3,
      category: 'Trips',
    ),
    VaultPhoto(
      url:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB5eP2UXSK5ugzcXenQnwqIkEKrPjyaeiqBTQhV_uSFtFxYcCrS4gTHu2748g-2HBxisjPoXmXflN3AWFSNz1ag7je8DogWe-9SUQNBZPU_fK-wOUtwAjp6QJWljMdI6ZKwr0-2BYCh4d6KTdOo59lhylsAM4yuknY9nxWHE_I-EP3j5YOo1nMvpyFrz-KVLSBBjpKEx5PG5IMxTv3C-yGe01Ks515mmQ01o5eeiK7HZ7-DvNQlD4FE',
      category: 'Firsts',
    ),
  ];

  static const List<CalendarEvent> upcomingEvents = [
    CalendarEvent(
      title: 'Our Anniversary',
      subtitle: "August 8th • Dinner at Luigi's",
      icon: Icons.favorite,
      iconColor: CozyColors.primary,
      iconBg: CozyColors.primaryContainer,
      thumbnailUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDmXqW3CXzatNfWQA6DhaeWSny15zVffLNJWEJL8x06n_jrj70c0P34C9ru-nuUF7ilnobteeoRXo9-zR99z2NiZRYL21zjd3blvsnKV-wZecKuZnavkRvDJGjL1H0zMutbmyKii0wg5lOo_YImJsygfWu1d40SadnaHxKFqZ6tDNDyCbeAJRpcEI1zh8xpl03Pw4xffD0l1jnj45yAfvKVDi6hMuyFflsfDAxcEext6qhEBTlgD_AV',
    ),
    CalendarEvent(
      title: 'Beach Trip',
      subtitle: 'August 18th - 20th • Malibu',
      icon: Icons.flight,
      iconColor: CozyColors.secondary,
      iconBg: CozyColors.secondaryContainer,
      thumbnailUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBnz6kwF-8uAn8sdlvR9nEVBsiHioyl0Soy4sRNY9dByZBGhDIKJ2jXru2TByLNj7PdJEwH016LMTjjlmjcxePt-hSlB9PSuQSOa7qRg-qmmMLTXDoywVZEfJmPnRIgYttDNS4n6BHMwDATuCmTI4F1DI5F6Jakk5OARmz8GN5cq26A3t8PdI2KA-bC-ITIKzM_CNgnJYmyrJV_uxADegZbynaZbkgDU8We0kCbW5vmQNqNjzn4R-Wf',
    ),
  ];

  static const List<Milestone> milestones = [
    Milestone(
      title: 'First Date',
      date: 'Oct 14, 2020',
      icon: Icons.restaurant,
      iconColor: CozyColors.primary,
      iconBg: CozyColors.primaryContainer,
    ),
    Milestone(
      title: 'First Kiss',
      date: 'Oct 28, 2020',
      icon: Icons.favorite,
      iconColor: CozyColors.secondary,
      iconBg: CozyColors.secondaryContainer,
    ),
    Milestone(
      title: 'Moved In Together',
      date: 'Sep 1, 2022',
      place: 'The Little Condo',
      icon: Icons.home_outlined,
      iconColor: CozyColors.tertiary,
      iconBg: CozyColors.tertiaryContainer,
      wide: true,
    ),
  ];
}

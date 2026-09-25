// Katalog aplikasi floating/bubble/overlay populer untuk screening mode ujian.
//
// File ini murni data + helper tanpa dependency eksternal. Semua package
// Android di bawah menggunakan format lowercase dot-separated yang valid.
//
// riskLevel: 1 = rendah, 2 = sedang, 3 = paling berisiko untuk ujian
// (bubble/chat-heads/overlay yang memudahkan interaksi lintas aplikasi).

/// Satu entri aplikasi floating/overlay yang dikenal.
class FloatingAppEntry {
  /// Nama package Android (contoh: com.whatsapp).
  final String androidPackage;

  /// Nama tampilan aplikasi.
  final String label;

  /// Kategori aplikasi (mis. 'Messaging', 'Video/Media').
  final String category;

  /// Tingkat risiko 1-3 (3 = paling berisiko untuk ujian).
  final int riskLevel;

  const FloatingAppEntry({
    required this.androidPackage,
    required this.label,
    required this.category,
    required this.riskLevel,
  });
}

/// Daftar package Android ternama yang memiliki fitur
/// bubble/chat-heads/overlay/float-window.
const List<FloatingAppEntry> kFloatingAppCatalog = <FloatingAppEntry>[
  FloatingAppEntry(
    androidPackage: 'com.lwi.android.flapps',
    label: 'Floating Apps',
    category: 'System/Tools',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.floatee.app',
    label: 'Floatee',
    category: 'System/Tools',
    riskLevel: 3,
  ),
  // ---------------------------------------------------------------------------
  // Messaging / chat dengan chat-heads & bubble
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.whatsapp',
    label: 'WhatsApp',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.whatsapp.w4b',
    label: 'WhatsApp Business',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.telegram.messenger',
    label: 'Telegram',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.telegram.plus',
    label: 'Telegram Plus',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.telegram.messenger.web',
    label: 'Telegram Web',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'org.thunderdog.challegram',
    label: 'Telegram X',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.facebook.orca',
    label: 'Messenger',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.facebook.orca.kids',
    label: 'Messenger Kids',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.facebook.lite',
    label: 'Facebook Lite',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.facebook.katana',
    label: 'Facebook',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.thoughtcrime.securesms',
    label: 'Signal',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.thoughtcrime.secondsms',
    label: 'Signal',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'jp.naver.line.android',
    label: 'LINE',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.mm',
    label: 'WeChat',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.mobileqq',
    label: 'QQ',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.viber.voip',
    label: 'Viber',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.discord',
    label: 'Discord',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.discord.dev',
    label: 'Discord Dev',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.Slack',
    label: 'Slack',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.teams',
    label: 'Microsoft Teams',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.skype.raider',
    label: 'Skype',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.messaging',
    label: 'Google Messages',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.samsung.android.messaging',
    label: 'Samsung Messages',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.android.mms',
    label: 'MIUI Messages',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.android.messaging',
    label: 'AOSP Messages',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.kakao.talk',
    label: 'KakaoTalk',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.bbm',
    label: 'BBM',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.imo.android.imoim',
    label: 'IMO',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.imo.android.imoimlite',
    label: 'IMO Lite',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.botim.me',
    label: 'Botim',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.zing.zalo',
    label: 'Zalo',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.snapchat.android',
    label: 'Snapchat',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.instagram.android',
    label: 'Instagram',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.instagram.lite',
    label: 'Instagram Lite',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.twitter.android',
    label: 'X / Twitter',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.twitter.android.lite',
    label: 'X Lite',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.instagram.barcelona',
    label: 'Threads',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.linkedin.android',
    label: 'LinkedIn',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.dynamite',
    label: 'Google Chat',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.talk',
    label: 'Hangouts',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.whatsapp.quick',
    label: 'WhatsApp Quick',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.telegram.instant',
    label: 'Telegram Instant',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.whatsapp.status',
    label: 'WA Status Saver',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.viber.rakuten',
    label: 'Rakuten Viber',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.skype.teams.ipphone',
    label: 'Teams Phone',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.wework',
    label: 'WeCom',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.tim',
    label: 'TIM',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.vkontakte.android',
    label: 'VK',
    category: 'Messaging',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'ru.ok.android',
    label: 'Odnoklassniki',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.whatsapp.w4b.lite',
    label: 'WhatsApp Business Lite',
    category: 'Messaging',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'org.telegram.bot',
    label: 'Telegram Bot',
    category: 'Messaging',
    riskLevel: 1,
  ),

  // ---------------------------------------------------------------------------
  // Video / media floating player
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.google.android.youtube',
    label: 'YouTube',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'app.revanced.android.youtube',
    label: 'YouTube ReVanced',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'app.revanced.android.apps.youtube.music',
    label: 'YouTube Music ReVanced',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.youtube.music',
    label: 'YouTube Music',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.netflix.mediaclient',
    label: 'Netflix',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.zhiliaoapp.musically',
    label: 'TikTok',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.ss.android.ugc.trill',
    label: 'TikTok',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.ss.android.ugc.aweme',
    label: 'Douyin',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.videolan.vlc',
    label: 'VLC',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.mxtech.videoplayer.ad',
    label: 'MX Player',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.mxtech.videoplayer.pro',
    label: 'MX Player Pro',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.kmplayer',
    label: 'KMPlayer',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.nemo.vidmate',
    label: 'Vidmate',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.snaptube.premium',
    label: 'Snaptube',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'tv.twitch.android.app',
    label: 'Twitch',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.disney.disneyplus',
    label: 'Disney+',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.amazon.avod.thirdpartyclient',
    label: 'Prime Video',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.spotify.music',
    label: 'Spotify',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.joox',
    label: 'Joox',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.garena.music',
    label: 'Audio Beats',
    category: 'Video/Media',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.youtube.kids',
    label: 'YouTube Kids',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.smarttube.app',
    label: 'SmartTube',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.vanced.android.youtube',
    label: 'YouTube Vanced',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.netflix.partner.activation',
    label: 'Netflix Activation',
    category: 'Video/Media',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.videos',
    label: 'Google TV',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.hbo.hbonow',
    label: 'HBO Max',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.hulu.plus',
    label: 'Hulu',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.crunchyroll.crunchyroid',
    label: 'Crunchyroll',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.deezer.android.app',
    label: 'Deezer',
    category: 'Video/Media',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.soundcloud.android',
    label: 'SoundCloud',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.facebook.katana.video',
    label: 'Facebook Video',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.dailymotion.dailymotion',
    label: 'Dailymotion',
    category: 'Video/Media',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.vimeo.android.videoapp',
    label: 'Vimeo',
    category: 'Video/Media',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.kwai.video',
    label: 'Kwai',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.likee.video',
    label: 'Likee',
    category: 'Video/Media',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.rumble.battles',
    label: 'Rumble',
    category: 'Video/Media',
    riskLevel: 2,
  ),

  // ---------------------------------------------------------------------------
  // Utility overlay / bubble
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.truecaller',
    label: 'Truecaller',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.callapp.contacts',
    label: 'CallApp',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.drupe.app',
    label: 'Drupe',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.drupe.dialer',
    label: 'Drupe Dialer',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.samsung.android.app.cocktailbarservice',
    label: 'Edge Lighting / Chat Bubbles',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.miui.securitycenter',
    label: 'Xiaomi Game Turbo',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.coloros.gamespace',
    label: 'Oppo Game Space',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.vivo.game',
    label: 'Vivo Game Mode',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.hecorat.screenrecorder.free',
    label: 'AZ Screen Recorder',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.rsupport.mvagent',
    label: 'Mobizen',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.duapps.recorder',
    label: 'DU Recorder',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.kimcy929.screenrecorder',
    label: 'Screen Recorder',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.recorder.screenrecorder',
    label: 'XRecorder',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.ar.lens',
    label: 'Google Lens',
    category: 'Utility Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.jackhenry.goodboneproducts.assistivetouch',
    label: 'Assistive Touch',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.easytouch.assistivetouch',
    label: 'EasyTouch',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.floating.widgets',
    label: 'Floating Widgets',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.blueLightFilter.eyecare',
    label: 'Blue Light Filter',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.urbandroid.lux',
    label: 'Twilight',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'eu.chainfire.lumen',
    label: 'CF.lumen',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.gm',
    label: 'Gmail',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.office.outlook',
    label: 'Microsoft Outlook',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.readdle.spark',
    label: 'Spark Mail',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.samsung.android.app.screenmirroring',
    label: 'Screen Mirroring',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.chromecast.app',
    label: 'Google Home Cast',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.duapps.ducleaner',
    label: 'DU Cleaner',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.cleanmaster.mguard',
    label: 'Clean Master',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.lionmobi.powerclean',
    label: 'Power Clean',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.antivirus.tablet',
    label: 'Antivirus Overlay',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.floatingtimer.timer',
    label: 'Floating Timer',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.floaty.window',
    label: 'Floaty Window',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.screenrecorder.video',
    label: 'Video Screen Recorder',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.streaming.cast.app',
    label: 'Cast App',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.sec.android.app.sbrowsercast',
    label: 'Samsung Cast',
    category: 'Utility Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.apple.android.music',
    label: 'Apple Music',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.waze',
    label: 'Waze',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.maps',
    label: 'Google Maps',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.dialer',
    label: 'Google Phone (overlay)',
    category: 'Utility Overlay',
    riskLevel: 2,
  ),

  // ---------------------------------------------------------------------------
  // Gaming dengan overlay
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.mobile.legendsesports.mlbb.mp',
    label: 'Mobile Legends',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.mobilelegends.mi',
    label: 'Mobile Legends MI',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.ig',
    label: 'PUBG Mobile',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.pubg.imobile',
    label: 'PUBG Mobile (Global)',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.rekoo.pubgm',
    label: 'PUBG Mobile KR',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.tmgp.pubgmhd',
    label: 'PUBG Mobile HD',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.dts.freefireth',
    label: 'Free Fire',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.dts.freefiremax',
    label: 'Free Fire MAX',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.miHoYo.GenshinImpact',
    label: 'Genshin Impact',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.activision.callofduty.shooter',
    label: 'Call of Duty Mobile',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.roblox.client',
    label: 'Roblox',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.supercell.clashofclans',
    label: 'Clash of Clans',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.supercell.clashroyale',
    label: 'Clash Royale',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.supercell.brawlstars',
    label: 'Brawl Stars',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.innersloth.spacemafia',
    label: 'Among Us',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.riotgames.league.wildrift',
    label: 'League of Legends: Wild Rift',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.riotgames.league.wildrifttw',
    label: 'Wild Rift TW',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.garena.game.codm',
    label: 'Garena CODM',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.mojang.minecraftpe',
    label: 'Minecraft',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.epicgames.fortnite',
    label: 'Fortnite',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.ea.gp.fifamobile',
    label: 'FIFA Mobile',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.pubg.krmobile',
    label: 'PUBG Mobile KR (alt)',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.gameloft.android.ANMP.GloftA9HM',
    label: 'Asphalt 9',
    category: 'Gaming Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.miHoYo.hkrpg',
    label: 'Honkai: Star Rail',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.miHoYo.enterprise.NGHSoD',
    label: 'Honkai Impact 3rd',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.HoYoverse.hkrpgoversea',
    label: 'Honkai Star Rail (Global)',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.tencent.tmgp.sgame',
    label: 'Honor of Kings',
    category: 'Gaming Overlay',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.netease.dwrg',
    label: 'Identity V',
    category: 'Gaming Overlay',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.kiloo.subwaysurf',
    label: 'Subway Surfers',
    category: 'Gaming Overlay',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.imangi.templerun2',
    label: 'Temple Run 2',
    category: 'Gaming Overlay',
    riskLevel: 1,
  ),

  // ---------------------------------------------------------------------------
  // Browser dengan floating video
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.android.chrome',
    label: 'Chrome',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.chrome.beta',
    label: 'Chrome Beta',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.mozilla.firefox',
    label: 'Firefox',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'org.mozilla.firefox_beta',
    label: 'Firefox Beta',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.opera.browser',
    label: 'Opera',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.opera.mini.native',
    label: 'Opera Mini',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.brave.browser',
    label: 'Brave',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.UCMobile.intl',
    label: 'UC Browser',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'mobi.mgeek.TunnyBrowser',
    label: 'Dolphin Browser',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'ru.yandex.searchplugin',
    label: 'Yandex Browser',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.sec.android.app.sbrowser',
    label: 'Samsung Internet',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.emmx',
    label: 'Microsoft Edge',
    category: 'Browser',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.duckduckgo.mobile.android',
    label: 'DuckDuckGo',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.yandex.browser',
    label: 'Yandex',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.quark.browser',
    label: 'Quark Browser',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.baidu.searchbox',
    label: 'Baidu Browser',
    category: 'Browser',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'org.mozilla.focus',
    label: 'Firefox Focus',
    category: 'Browser',
    riskLevel: 1,
  ),
  FloatingAppEntry(
    androidPackage: 'com.vivaldi.browser',
    label: 'Vivaldi',
    category: 'Browser',
    riskLevel: 2,
  ),

  // ---------------------------------------------------------------------------
  // Cloud / office dengan overlay
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.docs',
    label: 'Google Drive',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.docs.editors.sheets',
    label: 'Google Sheets',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.docs.editors.docs',
    label: 'Google Docs',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.docs.editors.slides',
    label: 'Google Slides',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.dropbox.android',
    label: 'Dropbox',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'cn.wps.moffice_eng',
    label: 'WPS Office',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'cn.wps.moffice_eng.lite',
    label: 'WPS Office Lite',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.office.officehubrow',
    label: 'Microsoft Office',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.office.word',
    label: 'Microsoft Word',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.office.excel',
    label: 'Microsoft Excel',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'notion.id',
    label: 'Notion',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.trello',
    label: 'Trello',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.onedrive.release',
    label: 'Microsoft OneDrive',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.box.android',
    label: 'Box',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.evernote',
    label: 'Evernote',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.pushbullet.android',
    label: 'Pushbullet',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.office.powerpoint',
    label: 'Microsoft PowerPoint',
    category: 'Cloud/Office',
    riskLevel: 2,
  ),

  // ---------------------------------------------------------------------------
  // Screen recording / streaming
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.streamlabs',
    label: 'Streamlabs',
    category: 'Screen Recording',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.obsproject.obsstudio',
    label: 'OBS Studio',
    category: 'Screen Recording',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.prism.live',
    label: 'Prism Live',
    category: 'Screen Recording',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.garena.live',
    label: 'Loco',
    category: 'Screen Recording',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.omlet',
    label: 'Omlet Arcade',
    category: 'Screen Recording',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.nll.screenrecorder',
    label: 'NLL Screen Recorder',
    category: 'Screen Recording',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.dubpace.screenrecorder',
    label: 'Screen Recorder',
    category: 'Screen Recording',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.screenrecorder.az',
    label: 'AZ Recorder',
    category: 'Screen Recording',
    riskLevel: 2,
  ),

  // ---------------------------------------------------------------------------
  // Keyboard dengan overlay
  // ---------------------------------------------------------------------------
  FloatingAppEntry(
    androidPackage: 'com.google.android.inputmethod.latin',
    label: 'Gboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.touchtype.swiftkey',
    label: 'SwiftKey',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.baidu.input',
    label: 'Facemoji Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.kika.inputmethod',
    label: 'Kika Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.facebook.katana.keyboard',
    label: 'Facebook Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.samsung.android.honeyboard',
    label: 'Samsung Keyboard',
    category: 'Keyboard',
    riskLevel: 2,
  ),
  FloatingAppEntry(
    androidPackage: 'com.zhiliaoapp.musically.keyboard',
    label: 'TikTok Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.sohu.inputmethod.sogou',
    label: 'Sogou Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.baidu.inputmethod',
    label: 'Baidu Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.cootek.smartinputv5',
    label: 'TouchPal Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.emoji.keyboard.touchpal',
    label: 'TouchPal Emoji',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.fleksy.keyboard',
    label: 'Fleksy Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.grammarly.www.customkeyboard',
    label: 'Grammarly Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.iflytek.inputmethod',
    label: 'iFlytek Keyboard',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.microsoft.swiftkey.beta',
    label: 'SwiftKey Beta',
    category: 'Keyboard',
    riskLevel: 3,
  ),
  FloatingAppEntry(
    androidPackage: 'com.google.android.apps.inputmethod.hindi',
    label: 'Gboard Hindi',
    category: 'Keyboard',
    riskLevel: 2,
  ),
];

/// Pola substring lowercase nama package yang menandakan fitur
/// overlay/bubble/floating.
const List<String> kFloatingPackagePatterns = <String>[
  'bubble',
  'overlay',
  'floating',
  'floatwindow',
  'chathead',
  'chat.head',
  'screenrecorder',
  'screen.recorder',
  'recorder',
  'screencapture',
  'screen.capture',
  'assistivetouch',
  'assistive.touch',
  'easytouch',
  'easy.touch',
  'caller',
  'dialer',
  'filetransfer',
  'file.transfer',
  'cloner',
  'parallel',
  'dualspace',
  'dual.space',
  'gameturbo',
  'game.turbo',
  'gamespace',
  'game.space',
  'multiwindow',
  'multi.window',
  'split.screen',
  'splitscreen',
  'floaty',
  'popup',
  'pop.up',
];

/// Package kritis yang DIIZINKAN (tidak dianggap pelanggaran) karena
/// menyediakan fungsi sistem yang vital selama ujian.
const Set<String> kAllowedCriticalPackages = <String>{
  // Dialer / telepon default
  'com.android.dialer',
  'com.google.android.dialer',
  'com.samsung.android.dialer',
  'com.android.phone',
  'com.android.server.telecom',
  'com.samsung.android.incallui',
  'com.oneplus.dialer',
  'com.oplus.dialer',
  'com.vivo.dialer',
  'com.miui.dialer',
  'com.huawei.contacts',
  // SMS
  'com.android.mms',
  'com.google.android.apps.messaging',
  'com.samsung.android.messaging',
  // Contacts
  'com.android.contacts',
  'com.google.android.contacts',
  'com.samsung.android.app.contacts',
  // Settings
  'com.android.settings',
  'com.google.android.settings',
  'com.samsung.android.settings',
  // System UI
  'com.android.systemui',
  'com.android.systemui.plugin',
  // Camera
  'com.android.camera',
  'com.android.camera2',
  'com.google.android.GoogleCamera',
  // Permissions Controller
  'com.google.android.permissioncontroller',
  'com.android.permissioncontroller',
  // HiDocs sendiri
  'id.hidocs.app',
  // Play Store
  'com.android.vending',
  // Google Play Services
  'com.google.android.gms',
  'com.google.android.gsf',
  // Package Installer
  'com.android.packageinstaller',
  'com.google.android.packageinstaller',
  // Files
  'com.android.documentsui',
  'com.google.android.documentsui',
  // Bluetooth / Clock / Calculator
  'com.android.bluetooth',
  'com.android.deskclock',
  'com.google.android.deskclock',
  'com.android.calculator2',
  'com.google.android.calculator',
  'com.samsung.android.calculator',
};

/// Cek apakah package merupakan package kritis yang diizinkan (exact match).
bool isCriticalAllowed(String packageName) {
  return kAllowedCriticalPackages.contains(packageName);
}

/// Cari entri katalog berdasarkan nama package (exact match).
FloatingAppEntry? lookupCatalog(String packageName) {
  for (final entry in kFloatingAppCatalog) {
    if (entry.androidPackage == packageName) {
      return entry;
    }
  }
  return null;
}

/// Cek apakah package cocok dengan salah satu pola overlay/bubble/floating.
bool matchesFloatingPattern(String packageName) {
  final lower = packageName.toLowerCase();
  for (final pattern in kFloatingPackagePatterns) {
    if (lower.contains(pattern)) {
      return true;
    }
  }
  return false;
}

/// Kata kunci pada nama tampilan aplikasi yang menandakan fitur floating.
const List<String> _kSuspiciousNameKeywords = <String>[
  'bubble',
  'overlay',
  'floating',
  'recorder',
  'chat head',
  'chathead',
  'assistive',
  'easy touch',
  'dual',
  'clone',
  'parallel',
];

/// Menentukan apakah sebuah aplikasi mencurigakan sebagai floating/overlay app.
///
/// Mengembalikan `true` jika package BUKAN package kritis yang diizinkan DAN
/// (ada di katalog ATAU cocok pola OTAU nama app mengandung kata kunci
/// mencurigakan). Perbandingan case-insensitive.
bool isSuspiciousFloatingApp({
  required String packageName,
  required String appName,
}) {
  if (isCriticalAllowed(packageName)) {
    return false;
  }

  if (lookupCatalog(packageName) != null) {
    return true;
  }

  if (matchesFloatingPattern(packageName)) {
    return true;
  }

  final lowerName = appName.toLowerCase();
  for (final keyword in _kSuspiciousNameKeywords) {
    if (lowerName.contains(keyword)) {
      return true;
    }
  }

  return false;
}

// ============================================================
// ADHKAR - ENGLISH TEXTS, REFERENCES AND AUDIO
//
// One entry per dua, matched by the dua id from adhkar_data.dart.
//
// REFERENCE NUMBERS were read from the scanned book pages you shared.
// Numbers that were not clearly readable were left out on purpose
// (only the book name is shown). Please check every number against
// your book, and add the missing ones here.
//
// AUDIO: put an mp3 inside assets/audio/ and set  audio: 'audio/name.mp3'
// for that dua. The play button appears automatically when audio is set.
// Use only recordings you have permission to use.
// ============================================================

class Ref {
  /// Key from [refBooks].
  final String book;

  /// Hadith number as printed in the book (use digits 0-9).
  final String? number;

  /// 'sahih' or 'hasan' when the book states the grade of the chain.
  final String? grade;

  const Ref(this.book, [this.number, this.grade]);
}

const Map<String, List<String>> refBooks = {
  'bukhari': ['সহীহ বুখারী', 'Sahih al-Bukhari'],
  'muslim': ['সহীহ মুসলিম', 'Sahih Muslim'],
  'abu_dawud': ['আবূ দাঊদ', 'Sunan Abi Dawud'],
  'tirmidhi': ['তিরমিযী', 'Jami at-Tirmidhi'],
  'ibn_majah': ['ইবনু মাজাহ', 'Sunan Ibn Majah'],
  'darimi': ['দারেমী', 'Sunan ad-Darimi'],
  'mishkat': ['মিশকাত', 'Mishkat al-Masabih'],
  'ahmad': ['মুসনাদে আহমাদ', 'Musnad Ahmad'],
  'silsila': ['সিলসিলা সহীহা', 'Silsilah as-Sahihah'],
  'targhib': ['আত-তারগীব ওয়াত তারহীব', 'At-Targhib wat-Tarhib'],
  'ibn_khuzaymah': ['সহীহ ইবনু খুযায়মা', 'Sahih Ibn Khuzaymah'],
};

class DhikrExtra {
  final String title;
  final String transliteration;
  final String meaning;
  final String? note;
  final List<Ref> refs;

  /// Asset path inside assets/, for example 'audio/ayatul_kursi.mp3'.
  final String? audio;

  const DhikrExtra({
    required this.title,
    required this.transliteration,
    required this.meaning,
    this.note,
    this.refs = const [],
    this.audio,
  });
}

const String _tinQulTranslitEn =
    'Qul huwallahu ahad. Allahus-samad. Lam yalid wa lam yulad. Wa lam yakun lahu kufuwan ahad.\n\n'
    "Qul a'udhu birabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. "
    "Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.\n\n"
    "Qul a'udhu birabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. "
    'Alladhi yuwaswisu fi suduri-nas. Minal-jinnati wan-nas.';

const String _ayatulKursiTranslitEn =
    "Allahu la ilaha illa huwal-hayyul-qayyum. La ta'khudhuhu sinatun wa la nawm. "
    'Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa\'u \'indahu illa bi-idhnih. '
    "Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im min 'ilmihi illa bima sha'. "
    "Wasi'a kursiyyuhus-samawati wal-ard. Wa la ya'uduhu hifzuhuma. Wa huwal-'aliyyul-'azim.";

const String _ayatulKursiMeaningEn =
    'Allah! There is no god but Him, the Ever-Living, the Sustainer of all existence. '
    'Neither drowsiness nor sleep overtakes Him. To Him belongs whatever is in the heavens and '
    'whatever is on the earth. Who is there that can intercede with Him except by His permission? '
    'He knows what is before them and what is behind them, and they encompass nothing of His '
    'knowledge except what He wills. His Throne extends over the heavens and the earth, and '
    'preserving them does not weary Him. He is the Most High, the Most Great.';

const String _tinQulMeaningEn =
    'Surah Al-Ikhlas declares the oneness of Allah. Surah Al-Falaq seeks refuge in the Lord of '
    'daybreak from the evil of creation, of darkness, of those who practise sorcery and of the '
    'envier. Surah An-Nas seeks refuge in the Lord of mankind from the whispering of the '
    'retreating devil.';

const Map<String, DhikrExtra> adhkarExtra = {
  'ayatul_kursi': DhikrExtra(
    title: 'Ayatul Kursi',
    transliteration: _ayatulKursiTranslitEn,
    meaning: _ayatulKursiMeaningEn,
    refs: [
      Ref('bukhari', '5010'),
      Ref('ibn_khuzaymah'),
      Ref('targhib'),
    ],
  ),
  'tin_qul': DhikrExtra(
    title: 'The Three Quls (Ikhlas, Falaq, Nas)',
    transliteration: _tinQulTranslitEn,
    meaning: _tinQulMeaningEn,
    note:
        'Reciting them three times in the morning and evening is enough to protect you '
        'from every harm.',
    refs: [
      Ref('abu_dawud', '5056'),
      Ref('tirmidhi', '2902'),
      Ref('abu_dawud', '5082'),
      Ref('tirmidhi', '3575', 'hasan'),
    ],
  ),
  'sayyidul_istighfar': DhikrExtra(
    title: 'Sayyidul Istighfar (Master of Seeking Forgiveness)',
    transliteration:
        "Allahumma anta rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika "
        "wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bi ni'matika 'alayya, "
        'wa abu\'u bi dhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa anta.',
    meaning:
        'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, '
        'and I keep Your covenant and promise as best I can. I seek refuge in You from the evil of '
        'what I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive '
        'me, for none forgives sins except You.',
    note:
        'Whoever says it during the day with firm faith and dies before evening, or says it at '
        'night with firm faith and dies before morning, will be among the people of Paradise.',
    refs: [
      Ref('bukhari', '6306'),
      Ref('mishkat', '2335'),
    ],
  ),
  'afini': DhikrExtra(
    title: 'Dua for wellbeing of body, hearing and sight',
    transliteration:
        "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma 'afini fi basari, "
        'la ilaha illa anta.',
    meaning:
        'O Allah, grant me health in my body. O Allah, grant me health in my hearing. '
        'O Allah, grant me health in my sight. There is no god but You.',
    refs: [
      Ref('abu_dawud', '5090', 'hasan'),
      Ref('mishkat', '2413'),
    ],
  ),
  'aalimul_ghaib': DhikrExtra(
    title: 'Seeking refuge from the evil of one\'s soul and Shaytan',
    transliteration:
        "Allahumma 'alimal-ghaybi wash-shahadati, fatiras-samawati wal-ard, rabba kulli shay'in "
        "wa malikah, ash-hadu an la ilaha illa anta, a'udhu bika min sharri nafsi wa min "
        'sharrish-shaytani wa shirkih.',
    meaning:
        'O Allah, Knower of the unseen and the seen, Creator of the heavens and the earth, '
        'Lord and Owner of everything: I bear witness that there is no god but You. I seek refuge '
        'in You from the evil of my soul and from the evil of Shaytan and his call to shirk.',
    note: 'This dua can also be read at bedtime.',
    refs: [
      Ref('abu_dawud', '5067'),
      Ref('tirmidhi', '3392'),
      Ref('darimi'),
    ],
  ),
  'la_ilaha': DhikrExtra(
    title: 'Kalimah of Tawhid',
    transliteration:
        "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala "
        "kulli shay'in qadir.",
    meaning:
        'There is no god but Allah alone, with no partner. His is the dominion and His is the '
        'praise, and He has power over all things.',
    note:
        'A hadith mentions the reward of freeing a slave, ten good deeds recorded, ten sins '
        'erased, ten ranks raised and protection from Shaytan. (The book gives no count, so it is '
        'counted once.)',
    refs: [
      Ref('abu_dawud', '5077'),
      Ref('ibn_majah', '3867'),
      Ref('mishkat', '2395'),
    ],
  ),
  'bismillah_la_yadurru': DhikrExtra(
    title: 'Dua for protection from harm',
    transliteration:
        "Bismillahil-ladhi la yadurru ma'asmihi shay'un fil-ardi wa la fis-sama'i wa "
        "huwas-sami'ul-'alim.",
    meaning:
        'In the name of Allah, with whose name nothing on earth or in heaven can cause harm; '
        'and He is the All-Hearing, the All-Knowing.',
    note: 'A hadith says no calamity will touch the one who says it.',
    refs: [
      Ref('ibn_majah', '3869'),
      Ref('tirmidhi', '3388'),
      Ref('abu_dawud', '5088'),
      Ref('mishkat', '2391'),
    ],
  ),
  'subhanallah': DhikrExtra(
    title: 'Tasbih',
    transliteration: "Subhanallahil-'azimi wa bihamdih.",
    meaning: 'Glory be to Allah, the Most Great, and praise be to Him.',
    note:
        'A hadith mentions a special reward for saying it a hundred times in the morning '
        'and in the evening.',
    refs: [
      Ref('tirmidhi', '3464'),
      Ref('abu_dawud', '5091'),
      Ref('mishkat', '2304'),
    ],
  ),
  'afu_wal_afiyah': DhikrExtra(
    title: 'Dua for safety in this world and the Hereafter',
    transliteration:
        "Allahumma inni as'alukal-'afwa wal-'afiyata fid-dunya wal-akhirah. Allahumma inni "
        "as'alukal-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahummastur 'awrati "
        "wa amin raw'ati. Allahummahfazni min bayni yadayya wa min khalfi wa 'an yamini wa 'an "
        "shimali wa min fawqi, wa a'udhu bi'azamatika an ughtala min tahti.",
    meaning:
        'O Allah, I ask You for pardon and wellbeing in this world and the Hereafter. O Allah, '
        'I ask You for pardon and wellbeing in my religion, my worldly affairs, my family and my '
        'wealth. O Allah, conceal my faults and calm my fears. O Allah, protect me from before me, '
        'from behind me, from my right, from my left and from above me, and I seek refuge in Your '
        'greatness from being swallowed up from beneath me.',
    refs: [
      Ref('abu_dawud', '5074'),
      Ref('mishkat', '2397'),
    ],
  ),
  'husbiyallah': DhikrExtra(
    title: 'Hasbiyallah',
    transliteration:
        "Hasbiyallahu la ilaha illa huwa, 'alayhi tawakkaltu wa huwa rabbul-'arshil-'azim.",
    meaning:
        'Allah is sufficient for me. There is no god but Him. In Him I put my trust, and He is '
        'the Lord of the Mighty Throne.',
    refs: [
      Ref('abu_dawud', '5081'),
      Ref('tirmidhi'),
    ],
  ),
  'ya_hayyu': DhikrExtra(
    title: 'Ya Hayyu Ya Qayyum',
    transliteration:
        "Ya Hayyu ya Qayyumu, birahmatika astaghith, aslih li sha'ni kullah, wa la takilni "
        "ila nafsi tarfata 'ayn.",
    meaning:
        'O Ever-Living, O Sustainer! In Your mercy I seek relief. Set right all my affairs, and '
        'do not leave me to myself even for the blink of an eye.',
    refs: [
      Ref('silsila', '227'),
    ],
  ),
  'durood': DhikrExtra(
    title: 'Durood',
    transliteration: "Allahumma salli wa sallim 'ala nabiyyina Muhammad.",
    meaning: 'O Allah, send blessings and peace upon our Prophet Muhammad.',
    note:
        'A hadith says whoever sends blessings on the Prophet ten times in the morning and '
        'evening will receive his intercession on the Day of Judgement.',
    refs: [
      Ref('targhib', '1/273'),
    ],
  ),
  'asbahna': DhikrExtra(
    title: 'Morning dua (Asbahna)',
    transliteration:
        "Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika "
        "lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Rabbi as'aluka khayra "
        "ma fi hadhal-yawmi wa khayra ma ba'dah, wa a'udhu bika min sharri ma fi hadhal-yawmi wa "
        "sharri ma ba'dah. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min "
        "'adhabin fin-nar wa 'adhabin fil-qabr.",
    meaning:
        'We have reached the morning and all dominion belongs to Allah; all praise is for Allah. '
        'There is no god but Allah alone, with no partner. His is the dominion and His is the '
        'praise, and He has power over all things. My Lord, I ask You for the good of this day and '
        'the good after it, and I seek refuge in You from the evil of this day and the evil after '
        'it. My Lord, I seek refuge in You from laziness and the misery of old age. My Lord, I seek '
        'refuge in You from punishment in the Fire and punishment in the grave.',
    refs: [
      Ref('muslim', '2723'),
      Ref('mishkat', '2381'),
    ],
  ),
  'bika_asbahna': DhikrExtra(
    title: 'Morning dua (Bika Asbahna)',
    transliteration:
        'Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namutu, wa ilaykan-nushur.',
    meaning:
        'O Allah, by You we reach the morning and by You we reach the evening; by You we live and '
        'by You we die, and to You is the resurrection.',
    note:
        'Note: in your book the endings of the morning and evening versions (nushur / masir) '
        'appear printed the other way round. This follows the commonly narrated wording of Abu '
        'Dawud and Hisnul Muslim. Please check with your book.',
    refs: [
      Ref('abu_dawud', '5068'),
      Ref('tirmidhi', '3391'),
      Ref('mishkat', '2389'),
      Ref('ibn_majah', '3868'),
    ],
  ),
  'after_fajr': DhikrExtra(
    title: 'Dua after the Fajr prayer',
    transliteration:
        "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan.",
    meaning:
        'O Allah, I ask You for beneficial knowledge, good provision and accepted deeds.',
    note: 'Read it after the salam of the Fajr prayer.',
    refs: [
      Ref('ibn_majah', '925'),
      Ref('mishkat', '2498'),
    ],
  ),
  'fitrah': DhikrExtra(
    title: 'Dua of the natural religion (Fitrah)',
    transliteration:
        "Allahumma asbahna 'ala fitratil-islam, wa 'ala kalimatil-ikhlas, wa 'ala dini nabiyyina "
        "Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima hanifan wa ma "
        'kana minal-mushrikin.',
    meaning:
        'We have reached the morning upon the natural way of Islam, the word of sincerity, the '
        'religion of our Prophet Muhammad (peace be upon him) and the creed of our father Ibrahim, '
        'upright, who was not of the polytheists.',
    refs: [
      Ref('darimi', '2688'),
      Ref('ahmad', '15400'),
      Ref('mishkat', '2415'),
    ],
  ),
  'amsaina': DhikrExtra(
    title: 'Evening dua (Amsaina)',
    transliteration:
        "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika "
        "lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Allahumma inni "
        "as'aluka min khayri hadhihil-laylati wa khayri ma fiha, wa a'udhu bika min sharriha wa "
        "sharri ma fiha. Allahumma inni a'udhu bika minal-kasali wal-harami wa su'il-kibar. "
        "Rabbi inni a'udhu bika min 'adhabin fin-nar wa 'adhabin fil-qabr.",
    meaning:
        'We have reached the evening and all dominion belongs to Allah; all praise is for Allah. '
        'There is no god but Allah alone, with no partner. His is the dominion and His is the '
        'praise, and He has power over all things. O Allah, I ask You for the good of this night '
        'and the good of what is in it, and I seek refuge in You from its evil and the evil of what '
        'is in it. O Allah, I seek refuge in You from laziness, old age and the misery of old age. '
        'My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.',
    refs: [
      Ref('muslim', '2723'),
      Ref('mishkat', '2381'),
    ],
  ),
  'bika_amsaina': DhikrExtra(
    title: 'Evening dua (Bika Amsaina)',
    transliteration:
        'Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namutu, wa ilaykal-masir.',
    meaning:
        'O Allah, by You we reach the evening and by You we reach the morning; by You we live and '
        'by You we die, and to You is the final return.',
    note:
        'Note: in your book the endings of the morning and evening versions (nushur / masir) '
        'appear printed the other way round. This follows the commonly narrated wording of Abu '
        'Dawud and Hisnul Muslim. Please check with your book.',
    refs: [
      Ref('abu_dawud', '5068'),
      Ref('tirmidhi', '3391'),
      Ref('mishkat', '2389'),
      Ref('ibn_majah', '3868'),
    ],
  ),
  'kalimat_tammat': DhikrExtra(
    title: "Seeking refuge in Allah's perfect words",
    transliteration: "A'udhu bikalimatillahit-tammati min sharri ma khalaq.",
    meaning:
        'I seek refuge in the perfect words of Allah from the evil of what He has created.',
    note: 'Read it three times in the evening.',
    refs: [
      Ref('ibn_majah', '3518'),
      Ref('mishkat', '2422-23'),
      Ref('muslim'),
    ],
  ),
  'sleep_tin_qul': DhikrExtra(
    title: 'The Three Quls before sleep',
    transliteration: _tinQulTranslitEn,
    meaning:
        'Cup your palms together, blow into them and recite the three surahs. Then wipe over as '
        'much of your body as you can, starting with the head and face and the front of the body. '
        'Do this three times.',
    refs: [
      Ref('bukhari', '5017'),
      Ref('muslim'),
      Ref('mishkat', '2132'),
    ],
  ),
  'sleep_ayatul_kursi': DhikrExtra(
    title: 'Ayatul Kursi',
    transliteration: _ayatulKursiTranslitEn,
    meaning: _ayatulKursiMeaningEn,
    note: 'Reciting it at bedtime means Shaytan will not come near you.',
    refs: [
      Ref('bukhari', '2311, 3275'),
      Ref('muslim'),
    ],
  ),
  'sleep_baqarah_last_two': DhikrExtra(
    title: 'Last two verses of Surah Al-Baqarah',
    transliteration:
        "Amanar-rasulu bima unzila ilayhi min rabbihi wal-mu'minun. Kullun amana billahi wa "
        "mala'ikatihi wa kutubihi wa rusulih. La nufarriqu bayna ahadin min rusulih. Wa qalu "
        "sami'na wa ata'na, ghufranaka rabbana wa ilaykal-masir. La yukallifullahu nafsan illa "
        "wus'aha, laha ma kasabat wa 'alayha maktasabat. Rabbana la tu'akhidhna in nasina aw "
        "akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'alal-ladhina min qablina. "
        "Rabbana wa la tuhammilna ma la taqata lana bih. Wa'fu 'anna waghfir lana warhamna, anta "
        "mawlana fansurna 'alal-qawmil-kafirin.",
    meaning:
        'The Messenger believes in what was revealed to him from his Lord, and so do the '
        'believers. All of them believe in Allah, His angels, His books and His messengers. '
        'They say: we hear and we obey; Your forgiveness, our Lord, and to You is the final '
        'return. Allah does not burden a soul beyond its capacity. It earns what it has earned '
        'and is held to account for what it has done. Our Lord, do not take us to task if we '
        'forget or make a mistake. Our Lord, do not place on us a burden like the one You placed '
        'on those before us. Our Lord, do not burden us with more than we can bear. Pardon us, '
        'forgive us and have mercy on us. You are our Protector, so help us against the '
        'disbelieving people.',
    note: 'Whoever recites these two verses at night, they will suffice him.',
    refs: [
      Ref('bukhari', '5040'),
      Ref('muslim'),
      Ref('mishkat', '2125'),
    ],
  ),
  'sleep_sajdah_mulk': DhikrExtra(
    title: 'Surah As-Sajdah and Surah Al-Mulk',
    transliteration: '',
    meaning:
        'Recite Surah As-Sajdah (Alif Lam Mim Tanzil) and Surah Al-Mulk (Tabarakalladhi) before '
        'sleeping. Read the full surahs from the Quran.',
    refs: [
      Ref('darimi'),
      Ref('tirmidhi', '2892'),
      Ref('mishkat', '2155'),
    ],
  ),
};

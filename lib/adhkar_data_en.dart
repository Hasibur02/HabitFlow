// ============================================================
// ADHKAR DATA - ENGLISH
//
// English title, pronunciation, meaning, source and note for
// every dua in adhkar_data.dart. Each entry is matched by its
// "id". The Arabic text stays in adhkar_data.dart.
//
// The English pronunciation and meaning are written fresh for
// this app. IMPORTANT: please verify every item against a
// trusted book before you release the app.
//
// If an id is missing here, the screen shows the Bangla text
// for that dua instead.
// ============================================================

class DhikrEn {
  final String title;
  final String transliteration;
  final String meaning;
  final String source;
  final String? note;

  const DhikrEn({
    required this.title,
    required this.transliteration,
    required this.meaning,
    required this.source,
    this.note,
  });
}

const String _bookCheckNote =
    'Caution: the ending of the morning and evening versions '
    '(nushur / masir) looked reversed in your book. This follows the '
    'commonly reported wording from Hisnul Muslim and Abu Dawud. '
    'Please check it against your book.';

const Map<String, DhikrEn> adhkarEnglish = {
  'ayatul_kursi': DhikrEn(
    title: 'Ayat al-Kursi (The Verse of the Throne)',
    transliteration:
        "Allahu la ilaha illa huwal-hayyul-qayyum, la ta'khudhuhu sinatun "
        "wa la nawm, lahu ma fis-samawati wa ma fil-ard, man dhal-ladhi "
        "yashfa'u 'indahu illa bi-idhnih, ya'lamu ma bayna aydihim wa ma "
        "khalfahum, wa la yuhituna bishay'im min 'ilmihi illa bima sha', "
        "wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifzuhuma, "
        "wa huwal-'aliyyul-'azim.",
    meaning:
        'Allah! There is no god but Him, the Ever-Living, the Sustainer of '
        'all. Neither drowsiness nor sleep overtakes Him. To Him belongs '
        'whatever is in the heavens and on the earth. Who can intercede '
        'with Him except by His permission? He knows what is before them '
        'and what is behind them, and they encompass nothing of His '
        'knowledge except what He wills. His Throne extends over the '
        'heavens and the earth, and preserving them does not tire Him. He '
        'is the Most High, the Most Great.',
    source: 'Sahih al-Bukhari; Sahih Ibn Khuzaymah',
  ),
  'tin_qul': DhikrEn(
    title: 'The Three Quls (Al-Ikhlas, Al-Falaq, An-Nas)',
    transliteration:
        "Qul huwallahu ahad. Allahus-samad. Lam yalid wa lam yulad. Wa lam "
        "yakul-lahu kufuwan ahad.\n\n"
        "Qul a'udhu bi-rabbil-falaq. Min sharri ma khalaq. Wa min sharri "
        "ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min "
        "sharri hasidin idha hasad.\n\n"
        "Qul a'udhu bi-rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-"
        "waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati "
        "wan-nas.",
    meaning:
        'Surah Al-Ikhlas declares the oneness of Allah. Surah Al-Falaq '
        'seeks refuge from the evil of all creation, the evil of darkness, '
        'of those who practise witchcraft, and of the envious. Surah An-Nas '
        'seeks refuge with the Lord of mankind from the evil of the '
        'whispering devil.',
    source: 'Sahih Abu Dawud; Tirmidhi',
    note: 'Reciting them three times in the morning and evening is '
        'sufficient protection from all harm.',
  ),
  'asbahna': DhikrEn(
    title: 'Morning dua (Asbahna)',
    transliteration:
        "Asbahna wa asbahal-mulku lillahi wal-hamdu lillah, la ilaha "
        "illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa "
        "huwa 'ala kulli shay'in qadir. Rabbi as'aluka khayra ma fi "
        "hadhal-yawmi wa khayra ma ba'dah, wa a'udhu bika min sharri ma fi "
        "hadhal-yawmi wa sharri ma ba'dah. Rabbi a'udhu bika minal-kasali "
        "wa su'il-kibar, rabbi a'udhu bika min 'adhabin fin-nari wa "
        "'adhabin fil-qabr.",
    meaning:
        'We have reached the morning, and the whole kingdom belongs to '
        'Allah; all praise is for Allah. There is no god but Allah alone, '
        'with no partner. The kingdom and the praise are His, and He has '
        'power over all things. My Lord, I ask You for the good of this day '
        'and the good of what follows it, and I seek refuge in You from the '
        'evil of this day and the evil of what follows it. My Lord, I seek '
        'refuge in You from laziness and the hardship of old age. My Lord, '
        'I seek refuge in You from punishment in the Fire and punishment '
        'in the grave.',
    source: 'Sahih Muslim; Mishkat',
  ),
  'sayyidul_istighfar': DhikrEn(
    title: 'Sayyid al-Istighfar (Master of Seeking Forgiveness)',
    transliteration:
        "Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana 'abduk, "
        "wa ana 'ala 'ahdika wa wa'dika mastata't. A'udhu bika min sharri "
        "ma sana't, abu'u laka bini'matika 'alayya, wa abu'u bidhanbi "
        "faghfir li, fa-innahu la yaghfirudh-dhunuba illa ant.",
    meaning:
        'O Allah, You are my Lord; there is no god but You. You created me '
        'and I am Your servant, and I keep Your covenant and promise as '
        'best I can. I seek refuge in You from the evil of what I have '
        'done. I acknowledge Your blessings upon me and I acknowledge my '
        'sin, so forgive me, for none forgives sins except You.',
    source: 'Sahih al-Bukhari',
    note: 'It is reported that whoever says it during the day with firm '
        'faith and dies before evening, or says it at night with firm '
        'faith and dies before morning, will be among the people of '
        'Paradise.',
  ),
  'afini': DhikrEn(
    title: 'Dua for health of body, hearing and sight',
    transliteration:
        "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma "
        "'afini fi basari, la ilaha illa ant.",
    meaning:
        'O Allah, grant me well-being in my body. O Allah, grant me '
        'well-being in my hearing. O Allah, grant me well-being in my '
        'sight. There is no god but You.',
    source: 'Sahih Abu Dawud (hasan chain)',
  ),
  'aalimul_ghaib': DhikrEn(
    title: 'Refuge with the Knower of the unseen and the seen',
    transliteration:
        "Allahumma 'alimal-ghaybi wash-shahadati fatiras-samawati wal-ard, "
        "rabba kulli shay'in wa malikah, ash-hadu an la ilaha illa ant, "
        "a'udhu bika min sharri nafsi wa min sharrish-shaytani wa shirkih.",
    meaning:
        'O Allah, Knower of the unseen and the seen, Creator of the '
        'heavens and the earth, Lord and Owner of everything: I bear '
        'witness that there is no god but You. I seek refuge in You from '
        'the evil of my own soul, and from the evil of Satan and his call '
        'to shirk.',
    source: 'Abu Dawud; Sahih Tirmidhi; Darimi',
    note: 'This dua can also be recited at bedtime.',
  ),
  'bika_asbahna': DhikrEn(
    title: 'Morning dua (Bika Asbahna)',
    transliteration:
        "Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika "
        "namutu wa ilaykan-nushur.",
    meaning:
        'O Allah, by Your grace we reach the morning and by Your grace we '
        'reach the evening. By You we live and by You we die, and to You '
        'is the resurrection.',
    source: 'Sahih Abu Dawud; Tirmidhi; Ibn Majah',
    note: _bookCheckNote,
  ),
  'la_ilaha': DhikrEn(
    title: 'Kalimah of Tawhid',
    transliteration:
        "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa "
        "lahul-hamdu wa huwa 'ala kulli shay'in qadir.",
    meaning:
        'There is no god but Allah alone, with no partner. The kingdom and '
        'the praise are His, and He has power over all things.',
    source: 'Sahih Abu Dawud; Ibn Majah',
    note: 'Reported rewards include the reward of freeing a slave, ten '
        'good deeds, ten sins erased, ten ranks raised, and protection '
        'from Satan. (Your book gives no count, so 1 time is used.)',
  ),
  'bismillah_la_yadurru': DhikrEn(
    title: 'Dua for protection from harm',
    transliteration:
        "Bismillahilladhi la yadurru ma'asmihi shay'un fil-ardi wa la "
        "fis-sama'i wa huwas-sami'ul-'alim.",
    meaning:
        'In the name of Allah, with whose name nothing on earth or in '
        'heaven can cause harm, and He is the All-Hearing, the All-Knowing.',
    source: 'Ibn Majah; Tirmidhi; Sahih Abu Dawud',
    note: 'It is reported that no calamity will touch the one who says it.',
  ),
  'subhanallah': DhikrEn(
    title: 'Tasbih',
    transliteration: "Subhanallahil-'azimi wa bihamdih.",
    meaning: 'Glory be to Allah the Most Great, and praise be to Him.',
    source: 'Tirmidhi; Sahih Abu Dawud',
    note: 'Reciting it one hundred times in the morning and evening carries '
        'special virtue.',
  ),
  'afu_wal_afiyah': DhikrEn(
    title: 'Dua for safety in this world and the next',
    transliteration:
        "Allahumma inni as'alukal-'afwa wal-'afiyata fid-dunya wal-akhirah. "
        "Allahumma inni as'alukal-'afwa wal-'afiyata fi dini wa dunyaya wa "
        "ahli wa mali. Allahummastur 'awrati wa amin raw'ati. Allahummahfazni "
        "min bayni yadayya wa min khalfi wa 'an yamini wa 'an shimali wa min "
        "fawqi, wa a'udhu bi'azamatika an ughtala min tahti.",
    meaning:
        'O Allah, I ask You for pardon and well-being in this world and the '
        'next. O Allah, I ask You for pardon and well-being in my religion, '
        'my worldly affairs, my family and my wealth. O Allah, conceal my '
        'faults and calm my fears. O Allah, protect me from in front, from '
        'behind, from my right, from my left and from above, and I seek '
        'refuge in Your greatness from being swallowed up by the earth '
        'beneath me.',
    source: 'Abu Dawud; Mishkat',
  ),
  'husbiyallah': DhikrEn(
    title: 'Hasbiyallah',
    transliteration:
        "Hasbiyallahu la ilaha illa huwa 'alayhi tawakkaltu wa huwa "
        "rabbul-'arshil-'azim.",
    meaning:
        'Allah is enough for me; there is no god but Him. In Him I place my '
        'trust, and He is the Lord of the Mighty Throne.',
    source: 'Abu Dawud; Tirmidhi',
  ),
  'ya_hayyu': DhikrEn(
    title: 'Ya Hayyu Ya Qayyum',
    transliteration:
        "Ya Hayyu ya Qayyumu birahmatika astaghith, aslih li sha'ni "
        "kullahu wa la takilni ila nafsi tarfata 'ayn.",
    meaning:
        'O Ever-Living, O Sustainer of all, by Your mercy I seek help. Set '
        'right all my affairs, and do not leave me to myself even for the '
        'blink of an eye.',
    source: 'Silsilah Sahihah',
  ),
  'durood': DhikrEn(
    title: 'Durood (Salawat)',
    transliteration: "Allahumma salli wa sallim 'ala nabiyyina Muhammad.",
    meaning:
        'O Allah, send blessings and peace upon our Prophet Muhammad '
        '(peace be upon him).',
    source: 'At-Targhib wat-Tarhib',
    note: 'It is reported that whoever does this will receive the '
        "Prophet's (peace be upon him) intercession on the Day of "
        'Resurrection.',
  ),
  'after_fajr': DhikrEn(
    title: 'Dua after the Fajr prayer',
    transliteration:
        "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa "
        "'amalan mutaqabbalan.",
    meaning:
        'O Allah, I ask You for beneficial knowledge, good and lawful '
        'provision, and accepted deeds.',
    source: 'Ibn Majah; Mishkat',
    note: 'Recite after the salam of the Fajr prayer.',
  ),
  'fitrah': DhikrEn(
    title: 'Dua of the natural way of Islam (Fitrah)',
    transliteration:
        "Allahumma asbahna 'ala fitratil-Islam wa 'ala kalimatil-ikhlas wa "
        "'ala dini nabiyyina Muhammadin sallallahu 'alayhi wa sallam wa "
        "'ala millati abina Ibrahima hanifan wa ma kana minal-mushrikin.",
    meaning:
        'We have woken up upon the natural way of Islam, upon the word of '
        'sincerity, upon the religion of our Prophet Muhammad (peace be upon '
        'him), and upon the creed of our father Ibrahim, upright, and he was '
        'not among the polytheists.',
    source: 'Darimi; Musnad Ahmad; Mishkat',
  ),
  'amsaina': DhikrEn(
    title: 'Evening dua (Amsaina)',
    transliteration:
        "Amsayna wa amsal-mulku lillahi wal-hamdu lillah, la ilaha "
        "illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa "
        "huwa 'ala kulli shay'in qadir. Allahumma inni as'aluka min khayri "
        "hadhihil-laylati wa khayri ma fiha, wa a'udhu bika min sharriha wa "
        "sharri ma fiha. Allahumma inni a'udhu bika minal-kasali wal-harami "
        "wa su'il-kibar, rabbi inni a'udhu bika min 'adhabin fin-nari wa "
        "'adhabin fil-qabr.",
    meaning:
        'We have reached the evening, and the whole kingdom belongs to '
        'Allah; all praise is for Allah. There is no god but Allah alone, '
        'with no partner. The kingdom and the praise are His, and He has '
        'power over all things. O Allah, I ask You for the good of this '
        'night and the good of what is in it, and I seek refuge in You from '
        'its evil and the evil of what is in it. O Allah, I seek refuge in '
        'You from laziness, old age and the hardship of old age. My Lord, I '
        'seek refuge in You from punishment in the Fire and punishment in '
        'the grave.',
    source: 'Sahih Muslim; Mishkat',
  ),
  'bika_amsaina': DhikrEn(
    title: 'Evening dua (Bika Amsaina)',
    transliteration:
        "Allahumma bika amsayna wa bika asbahna wa bika nahya wa bika "
        "namutu wa ilaykal-masir.",
    meaning:
        'O Allah, by Your grace we reach the evening and by Your grace we '
        'reach the morning. By You we live and by You we die, and to You is '
        'the final return.',
    source: 'Sahih Abu Dawud; Tirmidhi; Ibn Majah',
    note: _bookCheckNote,
  ),
  'kalimat_tammat': DhikrEn(
    title: 'Refuge in the perfect words of Allah',
    transliteration:
        "A'udhu bikalimatillahit-tammati min sharri ma khalaq.",
    meaning:
        'I seek refuge in the perfect words of Allah from the evil of all '
        'that He has created.',
    source: 'Ibn Majah; Mishkat; Sahih Muslim',
    note: 'Recite three times in the evening.',
  ),
};
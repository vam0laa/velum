# Velum kod anlatımı (1. aşama)

## Büyük resim

```
src/main.cpp        programın girişi: motoru ayarlar, pencereyi yükler
src/address.*       yazdığın metni adrese ya da aramaya çevirir
src/addressbridge.h yukarıdakini arayüze (QML) açan köprü
src/widevine.*      Netflix için gereken modülü bulur
qml/Main.qml        pencere, sekmeler, sayfalar, kısayollar
qml/Sidebar.qml     sol panel
qml/TabItem.qml     listedeki tek sekme satırı
qml/AddressField.qml adres kutusu
qml/StartPage.qml   yeni sekme ekranı
qml/IconButton.qml  küçük kare düğme
qml/Theme.qml       renkler ve ölçüler, tek yerde
tests/test_core.cpp penceresiz parçaların testleri
CMakeLists.txt      derleme tarifi
```

C++ "işi yapan", QML "görünen" kısım. Sayfayı çizen motor (Chromium) bize `WebEngineView` adlı bir kutu olarak geliyor.

## 1. main.cpp: sıra neden önemli?

```cpp
const QString cdm = widevine::find();
if (!cdm.isEmpty() && ...) { qputenv("QTWEBENGINE_CHROMIUM_FLAGS", ...); }
QtWebEngineQuick::initialize();
QGuiApplication app(argc, argv);
```

Motor ayarlarını yalnızca **bir kez, açılırken** okur. Bu yüzden önce Widevine'in yerini bulup bir ortam değişkenine yazıyoruz, sonra motoru başlatıyoruz. Sırayı ters çevirirsen Netflix açılmaz.

```cpp
engine.setInitialProperties({{"startUrls", start}, {"hasWidevine", !cdm.isEmpty()}});
engine.loadFromModule("Velum", "Main");
```

C++, `Main.qml`'e iki bilgi veriyor (açılacak adresler ve Widevine var mı), sonra pencereyi yüklüyor.

## 1b. graphics.cpp: siyah ekran neden oldu?

İlk sürümde sayfa NVIDIA kartında çiziliyor, pencere AMD kartında gösteriliyordu. İki kart arasında görüntü aktarılamayınca ekran siyah kaldı.

```cpp
if (hybridWithNvidia("/sys/class/drm"))
    qputenv("VK_LOADER_DRIVERS_DISABLE", "*nvidia*");
```

Makinede hem NVIDIA hem başka bir kart varsa motora NVIDIA'nın Vulkan sürücüsünü gizliyoruz; motor da pencereyle aynı kartı kullanıyor. Yalnızca NVIDIA olan makinelerde hiçbir şey değişmiyor. Bu da motor başlamadan önce yapılmak zorunda.

## 2. address.cpp: adres mi, arama mı?

Sırayla sorulan sorular:

1. Boş mu? Hiçbir şey yapma.
2. `https://`, `file://`, `about:` ile mi başlıyor? Olduğu gibi aç.
3. İçinde boşluk var mı? Arama.
4. Başına `https://` koyunca geçerli bir site adı oluyor mu?
5. Yerel bir adres mi (`localhost`, `192.168...`)? `http` kullan.
6. Sonu `.com`, `.dev` gibi harflerle mi bitiyor? Site. Değilse arama (`3.14` gibi).

İki güvenlik kararı:

- `javascript:` yazılırsa **çalıştırılmaz, aranır**. Biri seni adres çubuğuna kod yapıştırmaya ikna edemesin diye.
- `banka.com@kotu.site` aslında `kotu.site`'a gider. Bu görünüm aldatıcı olduğu için aranır.

## 3. addressbridge.h: C++ ile QML arasındaki köprü

```cpp
class Address : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_INVOKABLE QUrl resolve(const QString &typed) const { ... }
};
```

- `QML_ELEMENT`: bu sınıf QML'de görünsün.
- `QML_SINGLETON`: tek kopya olsun, `Address.resolve(...)` diye doğrudan çağrılsın.
- `Q_INVOKABLE`: bu fonksiyon QML'den çağrılabilsin.

## 4. widevine.cpp: en yeni sürümü seçmek

Başka tarayıcıların indirdiği klasörlere (`~/.config/chromium/WidevineCdm/4.10.xxxx/`) bakar. Sürümleri **metin olarak değil sayı olarak** karşılaştırır (`QVersionNumber`): metin olarak `900` > `3112` çıkardı.

## 5. Main.qml: sekmeler nasıl çalışıyor?

```qml
ListModel { id: tabs }
Repeater {
    model: tabs
    WebEngineView { ... }
}
```

- `tabs` bir liste: her satır bir sekme.
- `Repeater` listedeki her satır için bir `WebEngineView` (yani bir sayfa) oluşturur. Satır eklersen sayfa doğar, silersen sayfa yok olur.
- `StackLayout` sayfaları üst üste koyar, yalnızca `current` numaralı olanı gösterir.

```qml
readonly property WebEngineView view: views.count > 0 ? views.itemAt(current) : null
```

Bu bir **bağlama (binding)**: `current` ya da sekme sayısı değişince `view` kendiliğinden güncellenir. Sol panel `view`'e bağlı olduğu için geri düğmesi ve adres de kendiliğinden güncellenir. QML'in asıl gücü budur: "şu değişince şunu yenile" kodu yazmazsın.

`closeTab` fonksiyonundaki hesap: kapatılan sekme seçili olandan **önceyse** seçim bir geri kayar, böylece aynı sayfada kalırsın.

### Sayfa ayarları

```qml
settings.dnsPrefetchEnabled: false
settings.hyperlinkAuditingEnabled: false
onPermissionRequested: permission => permission.deny()
```

Tıklamadığın bağlantılar için ağ sorgusu yapma, tıklama takibi gönderme, kamera/konum gibi istekleri şimdilik reddet.

### Yeni pencere isteği

```qml
onNewWindowRequested: request => request.openIn(window.openTab(""))
```

Site yeni pencere açmak isterse yeni sekme açıp isteği oraya yönlendiriyoruz.

## 6. AddressField.qml

Kutuya tıklamadığında kısa adres (`vamola.dev`), tıkladığında tam adres görünür ve seçili gelir. `signal go(url target)` "kullanıcı bir yere gitmek istiyor" diye haber verir. Nereye yükleneceğine kutu değil, onu kullanan karar verir. Bu yüzden aynı kutu hem sol panelde hem başlangıç sayfasında çalışıyor.

## 7. Theme.qml ve masaüstü renkleri

```qml
function pick(name, fallback) { return DesktopColors.colors[name] ?? fallback }
readonly property color accent: pick("primary", "#89b4fa")
```

Bütün renkler tek dosyada. `DesktopColors` (C++) masaüstü temanın renk dosyasını okur ve **izler**. Duvar kâğıdını değiştirdiğinde dosya değişir, `changed` sinyali gider, bağlı her renk kendiliğinden güncellenir. Dosya yoksa soldaki yedek renkler kullanılır.

`palette.cpp` yalnızca `#rrggbb` biçimindeki değerleri kabul eder. Yarım yazılmış bir dosya gelirse eski renkler kalır.

## 7b. Icon.qml: ikonlar

İkonlar resim dosyası değil, 24×24'lük bir ızgarada çizgi tarifi:

```qml
plus: "M12 5v14 M5 12h14"   // (12,5)'ten aşağı 14; (5,12)'den sağa 14
```

Böylece her boyutta keskin kalır ve temanın rengini alır.

## 7c. Daralan panel

```qml
implicitWidth: compact ? Theme.strip : Theme.sidebar
Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth } }
```

`compact` değişince genişlik atlamaz, `Behavior` değişimi canlandırır. `Settings` sayesinde tercihin bir sonraki açılışta hatırlanır.

## 7d. CommandBar.qml: komut kutusu

`find(text)` yazdığına göre bir sonuç listesi kurar: önce "aç ya da ara", sonra eşleşen açık sekmeler, kısayollar ve komutlar.

```qml
{ name: "Sekmeyi kapat", keys: "Ctrl+W", run: () => window.closeTab(window.current) }
```

Bir komut, adı ve çalıştıracağı fonksiyonu olan küçük bir nesne. Yeni komut eklemek listeye bir satır yazmaktır. `Ctrl+T` kutuyu "yeni sekme" kipinde açar; sekme ancak bir şey seçince oluşur.

## 7e. Sekme taşıma ve sabitleme

`moveTab(from, to)` iki kuralı korur: sabit sekmeler hep üstte kalır ve **seçili sayfa değişmez** (sırası değişse bile). `current` hesabı bunun için. `moves++` satırı QML'e "sıra değişti, `view`'i yeniden bul" der.

Sabit sekmeler ve kısayollar `Settings` içinde JSON metni olarak saklanır. `readList` bozuk veriyi sessizce boş listeye çevirir.

## 7f. Kalkan: reklam ve izleyici engelleme

```
blocker/src/lib.rs   Brave'in Rust motoruna C arayüzü
src/blocker.*        o arayüzün C++ yüzü
src/shield.*         her isteği denetleyen, listeleri indiren parça
qml/ShieldPanel.qml  kalkan düğmesinin paneli
```

```cpp
void Shield::interceptRequest(QWebEngineUrlRequestInfo &info) {
    ...
    if (m_blocker->blocks(url, source, kindOf(type))) {
        info.block(true);
```

Motor internete çıkan **her isteği** önce bu fonksiyona sorar. Cevap "engelle" ise istek hiç gönderilmez. Sayfanın kendisi (`isMainPage`) asla engellenmez.

Listeler ayrı bir iş parçacığında yüklenir, pencere donmaz. İndirilen dosya mantıklı görünmüyorsa (`lists::plausible`) eskisinin üstüne yazılmaz.

Rust tarafında her fonksiyon `catch_unwind` ile sarılı: bozuk bir filtre tarayıcıyı çökertemez.

## 7g. Gizlilik

**Üçüncü taraf çerezleri** (`shield.cpp`):

```cpp
quick->cookieStore()->setCookieFilter([this](const FilterRequest &request) {
    if (!request.thirdParty || !m_blockCookies) return true;
    ...
```
Her çerez yazılmadan önce bu küçük fonksiyona sorulur. Motorun **ağ iş parçacığında** çalıştığı için okuduğu veriler kilitle (`QReadWriteLock`) ve `std::atomic` ile korunur.

**İzin soruları** (`PermissionBar.qml`): "İzin ver" düğmesi 0,6 saniye boyunca basılamaz. Sayfa, tam tıklayacağın anda soruyu açtırıp yanlışlıkla izin aldıramasın diye. Çubukta sayfanın başlığı değil gerçek adresi yazar.

## 7h. Geçmiş (historystore.cpp)

SQLite küçük bir veritabanı dosyasıdır; sunucu gerekmez.

```cpp
INSERT INTO pages(url, title, last) VALUES(?, ?, ?)
ON CONFLICT(url) DO UPDATE SET visits = visits + 1, ...
```
Adres yeniyse ekler, daha önce varsa ziyaret sayısını artırır. `?` işaretleri çok önemli: kullanıcıdan gelen metin sorgunun parçası değil **değeri** olarak verilir (SQL enjeksiyonu olmaz). Dosya yalnızca senin okuyabileceğin izinle açılır, adresteki parola kaydedilmez.

## 7i. İndirmeler

```qml
profile.downloadRequested.connect(startDownload)
request.accept()
```
Motor her indirmede haber verir, biz kabul edip listeye ekleriz. Velum indirilen dosyayı **asla kendiliğinden açmaz**, yalnızca klasörünü gösterir.

## 7j. Sekme uyutma ve kaynaklar

Motor her sekmeye üç durumdan birini verebilir: **Active** (çalışıyor), **Frozen** (durduruldu, işlemci harcamaz), **Discarded** (bellekten atıldı, açınca yeniden yüklenir).

```qml
function sleepTarget(idle, advice, pinned, audible, loading) { ... }
```
Varsayılan "Erken" kipte süreler 2 ve 10 dakika. Karar tek, küçük bir fonksiyonda: ne kadar süredir bakılmadı, motor ne öneriyor, sabit mi, ses çalıyor mu. Böyle ayrı tutunca pencere açmadan test edilebiliyor.

**Bellek** `/proc/<pid>/smaps_rollup` içindeki **Pss** değerinden okunur: ortak kullanılan bellek süreçlere paylaştırılır, böylece toplam şişmez (kerna'daki yaklaşımın benzeri).

## 7k. Oturum, tek pencere, sorun sayfaları

**Tembel yükleme:** geri gelen sekmeler hemen yüklenmez. Listede adresi ve başlığı durur, ilk baktığında `load_()` çalışır. Elli sekmeyle açılış bu yüzden hızlı kalır.

**Tek pencere** (`instance.cpp`): ikinci açılan Velum, yerel bir sokete adresleri yazıp kapanır; açık olan yeni sekme açar. Sokete yalnızca senin kullanıcın yazabilir ve yalnızca `http`, `https`, `file` adresleri kabul edilir.

**Sertifika hatası** her zaman reddedilir. "Yine de devam et" düğmesi bilerek yok.

## 7l. Ayarlar ve dil

```qml
function t(tr, en) { return turkish ? tr : en }
text: Lang.t("Yeni sekme", "New tab")
```
`turkish` bir özellik; onu okuyan her metin, dil değişince kendiliğinden yeniden hesaplanır. Yeniden başlatma gerekmez.

Arama motoru listesi C++ tarafında (`address::engines`), çünkü "bu yazı arama mı" kararını orası veriyor. Ayarlar sayfası yalnızca anahtarı değiştirir.

## 7m. Bildirimler ve sağ tık

**Bildirim** (`notifier.h`): site bildirim göstermek isterse (ve sen izin verdiysen) Velum bunu masaüstünün bildirim servisine D-Bus ile iletir. Sitenin yazısı `notice::plain` ile temizlenir; altında her zaman **gerçek site adı** yazar, sayfa bunu değiştiremez.

**Sağ tık** (`PageMenu.qml`): `request.accepted = true` motorun kendi menüsünü kapatır, biz tıklanan şeye göre (bağlantı, resim, seçili yazı, yazı kutusu) kendi menümüzü gösteririz.

## 7n. Tasarım: hafif webcore

```
qml/TitleBar.qml  ince pencere başlığı ve üç yuvarlak düğme
qml/Panel.qml     yuvarlak köşeli pencere
qml/Theme.qml     paletler, köşe yarıçapları, fontlar
```
Bütün görünüm `Theme.qml`'deki birkaç değerden yönetilir: `corner` pencere köşelerini, `radius` düğme ve satırları yuvarlar. Pixel yazı tipi yalnızca başlıklarda.

## 7o. Bölünmüş ekran

```qml
property WebEngineView splitLeft
property WebEngineView splitRight
```
Çift, sekme numarasıyla değil **sayfanın kendisiyle** hatırlanır; sekmeleri taşısan da bozulmaz. Seçili sekme çiftten biriyse ikisi de görünür (`visible`, `x`, `width` buna göre hesaplanır), başka sekme seçersen tek görünür. Hiçbir sayfa yeniden yüklenmez, yalnızca boyutu değişir.

## 7p. Çalışma alanları

```qml
property var spaces       // [{ id, name }]
property int space        // bakılan alan
```
Her sekmenin bir `space` numarası var. Kenar çubuğu yalnızca `pinned || space === window.space` olanları gösterir; diğerlerinin satır yüksekliği 0'dır. Sayfalar silinmez ve yeniden yüklenmez, sadece listeden gizlenir. Profil (çerezler) ortaktır; sabitlenen sekmeler her alanda görünür.

Dikkat edilen kural: ekranda her zaman o alanın gösterebileceği bir sekme olur. Son sekmeyi kapatınca ya da taşıyınca sabitlenene dönülür; o da yoksa boş sekme açılır (`neighbourOf` -1 dönerse).

## 7r. Küçük video penceresi

```qml
page.runJavaScript(miniPlayer.enterScript, ...)   // 1: videoyu sayfayı kaplayacak hale getir
page.parent = miniPlayer.stage                    // 2: sayfayı küçük pencereye taşı
```
Qt WebEngine tarayıcıların "picture-in-picture" özelliğini desteklemiyor. Onun yerine sekmenin sayfasının kendisi küçük pencereye taşınıyor: yeniden yüklenmediği için video kesilmiyor. JavaScript yalnızca bir stil ekler (videoyu büyütür, gerisini gizler); geri dönünce stil silinir.

Pencerenin başlığı `Picture-in-Picture`: Hyprland kuralları bu başlığı tanıyıp pencereyi yüzen ve sabit yapar. Sınırlar: başka siteden gömülü (iframe) videolar bulunamaz; sitenin kendi çizdiği altyazılar küçük pencerede görünmez.

## 7s. Yer imi yöneticisi

`qml/BookmarksPage.qml` yalnızca gösterir ve ister; listeyi `Main.qml` tutar ve değiştirir (`saveBookmark`, `moveBookmark`, `renameFolder`). Klasörler ayrıca saklanmaz: yer imlerinin `folder` alanlarından çıkarılır, bu yüzden boş klasör kalmaz.

## 7t. Başka tarayıcıdan aktarma

`src/importer.cpp` öbür tarayıcının dosyasını geçici bir klasöre **kopyalar** ve kopyayı okur; asıl dosyaya dokunmaz (Firefox açıkken dosya kilitli olduğu için de gerekli).
- Firefox ailesi: `places.sqlite` (SQL sorgusu)
- Chromium ailesi: `Bookmarks` (JSON) ve `History` (SQL). Chromium zamanı 1601'den sayar, 1970'e çevrilir.

`importbridge.h` yalnızca kendi bulduğu profilleri okur. Parola ve çerez alınmaz. Aynı aktarmayı iki kez yapmak bir şeyi çoğaltmaz.

## 7u. Okuma modu

`qml/Reader.qml` içindeki JavaScript:
1. **Bulur:** her uzun paragraf, kapsayan öğeye puan verir; menü, kenar sütunu, yorum gibi adlı bölümler sayılmaz.
2. **Temiz kopyalar:** sayfanın öğelerini taşımaz, izin verilen etiketlerden *yenilerini* yapar. Betik, form, `onclick`, `javascript:` bağlantısı bu yüzden geçemez.
3. **Üste serer:** kendi stilini taşıyan bir katman (shadow root). Çıkınca katman silinir, sayfa olduğu gibi kalır.

Betik `ApplicationWorld`'de çalışır: sayfanın kendi kodu onun değişkenlerine karışamaz.

## 7v. Parolalar

```
src/passwords.cpp      sistem anahtarlığı (libsecret): kaydet, listele, oku, sil
src/passwordbridge.h   aynısı QML için; her iş ayrı bir iş parçacığında
qml/LoginScript.qml    sayfanın içinde: giriş formunu fark eder, gönderileni bildirir, doldurur
```
Güvenlik kuralları:
- Parola dosyaya yazılmaz; anahtarlık şifreler.
- Sayfa betiği `ApplicationWorld`'de çalışır ve Velum'la `QWebChannel` üzerinden konuşur. Sitenin kendi kodu bu kanala erişemez.
- Köken (`https://site`) birebir eşleşmeli; http siteler (kendi bilgisayarın dışında) hiç izlenmez.
- Doldurma yalnızca sen isteyince, yalnızca görünen alana. Betik doldururken sayfanın hâlâ aynı site olduğunu bir daha kontrol eder.
- Panoya kopyalanan parola 30 saniye sonra silinir.

Test (`tests/run-keyring.sh`) kendi geçici anahtarlığını açar; seninkine dokunamaz.

## 7y. Ayarlar sekmesi, iki düzen, karşılama

```
qml/SettingsPage.qml   ayarlar: solda kategoriler, sağda kartlar
qml/ThemePicker.qml    temaların küçük resimleri + vurgu rengi
qml/LayoutPicker.qml   dikey / yatay seçimi
qml/TopBar.qml         yatay düzen
qml/Welcome.qml        ilk açılış adımları
```
- Ayarlar bir **sekme**: modeldeki `kind` alanı `"settings"` ise sayfanın yerine ayarlar gösterilir; o sekmede bir adrese gidersen sıradan sekmeye döner.
- İki düzen aynı sekme listesini ve aynı `TabItem`'i kullanır (`horizontal: true`). Kalkan ve indirme düğmeleri ortak bileşen oldu.
- Karşılama yalnızca normal açılışta ve daha önce görülmediyse gelir; ayarlardan yeniden açılabilir.

## 7z. Eklentiler

```
src/crx.cpp            mağaza adresinden kimlik; paketin imzasını doğrulama
src/storebridge.h      paketi Google'dan indirme (yalnızca sen istediğinde)
qml/ExtensionList.qml  ayarlardaki sayfa
```
Eklentinin 32 harflik kimliği, onu imzalayan anahtarın özetidir. `verifiedZip` bu yüzden iki şeye bakar: anahtarın özeti istenen kimlik mi, ve o anahtarın imzası paketin içeriğine uyuyor mu. Biri tutmazsa kurulmaz. Kurulumu motorun kendi yöneticisi (`profile.extensionManager`) yapar; yalnızca Manifest V3.

## 7x. Başlangıç sayfası

- `qml/Backdrop.qml` arka planı çizer (ışıltı: radyal renk geçişleri).
- Site simgeleri: yalnızca yer imine eklediğin bir siteyi açtığında, motorun elindeki simge bir kez ekran dışında çizilip `icons/` klasörüne yazılır. Başlangıç sayfası ağdan bir şey istemez.
- "Sık gidilenler" geçmişten, site başına bir tane. Kalkan sayacı yalnızca bir sayıdır, nereyle ilgili olduğu tutulmaz.

## 7w. Animasyonlar ve gölgeler

- `qml/PopIn.qml` / `PopOut.qml`: panellerin gelişi ve gidişi, hepsi aynı iki dosyayı kullanır.
- `qml/Shadow.qml`: bulanıklaştırma yerine üç soluk katman; ucuzdur, cam görünümde kapanır.
- Süreler `Theme.quick` ve `Theme.smooth`'tan gelir. "Animasyonlar" kapatılınca ikisi de 0 olur.

## 7q2. Mavi cybercore tasarımı

- `qml/Theme.qml`: renkler. `bar` başlık çubuklarının mavisi, `accentInk` onun üstündeki yazı. (Bir renge `on...` diye ad verilemez: QML onu olay işleyicisi sanır.)
- `qml/Panel.qml`, `TitleBar.qml`, `WindowButton.qml`: `.exe` pencereleri.
- `qml/TopBar.qml`, `TabItem.qml`: üstteki klasör biçimli sekmeler (`Shape` ile köşesi kesik).
- `qml/StartPage.qml`: glitch saat, aynı yazının dört renkte üst üste, birkaç piksel kaydırılmış hali.
- `data/sky.jpg`, `data/scanline.png`: Velum için çizilmiş gökyüzü ve tarama çizgisi.

## Yarım ekran hatası

Hyprland'de Velum başka çalışma alanına taşınınca bazen yeni kare çizmiyor, eski yarım kare esnetilip kırpılıyordu. `WAYLAND_DEBUG` kaydında görüldü: yeni boyut geliyor, Qt onu uygulamayı erteliyor ve kare gelmiyor. Çare: `graphics.cpp` Hyprland'de, ekran ölçeğini `hyprctl`'den okuyup Velum'u XWayland üzerinden başlatır (`force_zero_scaling` açıksa net görünür). Bu ayarlar yalnızca Velum'a verilir; açtığı programlara geçmesin diye uygulama kurulunca geri alınır.

## İki görünüm

`Theme.style` ya `"classic"` ya `"webcore"`. Bütün bileşenler aynı; köşe yarıçapı (`Theme.radius`), yazı tipi (`Theme.ui`), yazı boyutu (`Theme.size()`) ve gölgeler görünüme göre değişir. Ana sayfanın iki yüzü var: `ClassicStart.qml` ve `WebStart.qml`; verileri `StartPage.qml` tutar.

Gizli görünüm: adres ya da arama kutusuna `velum:webcore` yazılınca açılır, tekrar yazınca kapanır (`Theme.secret`).

## Ana sayfa ve ayarlar (son hali)

- `qml/ClassicStart.qml`: Lucid tarzı iki sütun. Dönen kelime bir `SequentialAnimation` ile yukarı kayıp yenisiyle değişir. Dar pencerede sütunlar alt alta gelir.
- `qml/MonthCard.qml`: ayın takvimi; bugün işaretli.
- `qml/SettingsPage.qml`: kategoriler ve kartlar; arama kutusu her kartın anahtar kelimelerine bakar (`shows`).
- `src/defaultbrowser.h`: "Varsayılan yap" düğmesi, `xdg-settings` ile.
- Kalın yazılar `Theme.axes()` ile: yazı tipinin gerçek ağırlık ekseni.

## Üst çubuk ve önerilen eklentiler

- Sayfayla ilgili her şey adres kutusunun içinde: solda kalkan, sağda sayfa düğmeleri ve yer imi yıldızı. Sağda indirmeler, eklentiler ve menü (☰).
- Çalışma alanı düğmeleri ancak ikinci alan açılınca görünür.
- `qml/Recommended.qml`: karşılamada işaretlemeli, ayarlarda tek tek "Kur". Karşılamada hiçbiri işaretli gelmez; seçilenler sırayla indirilir (`queueExtensions`).

## Karşılama ekranı

`qml/Welcome.qml` bütün pencereyi kaplar: solda başlık ve ilerleme, sağda seçimler. `BrowserPreview.qml` seçilen renk ve düzeni anında gösteren küçük bir Velum çizer; `ChoiceCard.qml` büyük seçim kartıdır. Dar pencerede iki sütun alt alta gelir; düğmeler tek yerde tanımlıdır, iki `LayoutItemProxy`'den görünen onları gösterir. Enter / sağ ok ilerler, sol ok geri döner.

## Renk geçişi

`qml/ThemeWash.qml`: renk seçilince önce eski görünümün fotoğrafı çekilip üste konur, yeni renkler altta uygulanır, fotoğrafta ortadan büyüyen yuvarlak bir delik açılır (`MultiEffect` maskesi). Tema değiştiren her yer `Theme.change()` kullanır; animasyonlar kapalıysa doğrudan uygulanır.

## Windows sürümü ve güncelleme

```
src/passwords_win.cpp, procinfo_win.cpp, notifier_win.h   Windows karşılıkları
src/update.cpp        sürüm karşılaştırma, imza (Ed25519) ve dosya özeti doğrulama
src/updatebridge.h    denetle → indir → doğrula → kapanışta kur
installer/velum.iss   yönetici istemeyen kurulum
.github/workflows/    Windows'ta derleme ve test
scripts/release.sh    derlemeyi indirir, burada imzalar, yayınlar
```
İmzalama anahtarının gizli yarısı yalnızca `~/.config/velum-release/signing.pem` dosyasında. **Yedekle:** kaybolursa kurulu Velum'lar güncelleme alamaz. Başkasının eline geçerse sahte güncelleme imzalayabilir.

## Ana sayfa tasarımı

- `qml/HomeCss.qml`: yazdığın CSS'i okur; yalnızca bilinen seçici ve özellikleri, geçerli değerleri alır, gerisini hata listesine yazar. `url()` gibi dışarı uzanan hiçbir şey yok.
- `qml/HomeBox.qml`, `HomeText.qml`: görünümünü o stile soran kutu ve yazı.
- `qml/HomeWidget.qml`: widget'lar; `HomeEditor.qml`: düzenleme paneli.

## Performans ve kısayollar

- Modlar `Main.qml` içinde: `freezeAfter`, `discardAfter`, `Theme.calm`. `pickToSleep` bellek sınırı aşılınca hangi sekmelerin uyutulacağını seçer.
- `src/graphics.cpp` + `gpubridge.h`: ekran kartı ayarı; "Zorla" ile açılış yarıda kalırsa bir sonrakinde otomatiğe döner.
- `qml/Keymap.qml`: kısayolların tek listesi ve senin değişikliklerin; `KeyList.qml` ayarlardaki düzenleyici.

## Görünümü kişiselleştirme

- `qml/Theme.qml`: kendi renklerin, köşe/yoğunluk/sekme biçimi, araç çubuğu sırası, tarayıcı CSS'i; `bundle`/`applyBundle` tema dosyasını yazar ve yalnızca geçerli alanları geri alır.
- `qml/ColorEditor.qml`, `ShapeEditor.qml`, `CssEditor.qml`: ayarlardaki düzenleyiciler.
- `src/files.h`: arayüz yalnızca `.velumtheme` dosyalarını okuyup yazabilir.

## 8. CMakeLists.txt

- `velumcore`: penceresiz kod ayrı bir kütüphane, böylece testler pencere açmadan çalışır.
- `qt_add_qml_module`: QML dosyalarını programın içine gömer.

## Kendin dene

1. `qml/Theme.qml` içinde `accent` rengini değiştir, `cmake --build build && ./build/velum`.
2. `sidebar` genişliğini 220 yap.
3. `address.cpp` içindeki arama motoru adresini değiştir, sonra `ctest --test-dir build` çalıştır: testler neden kırıldı?

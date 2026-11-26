#include <QCoreApplication>
#include <QJsonArray>
#include <QTcpSocket>
#include <QTcpServer>
#include <QCryptographicHash>
#include <QDir>
#include <QtEndian>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/x509.h>
#include <QSignalSpy>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QTest>

#include "address.h"
#include "ai.h"
#include "blocker.h"
#include "crx.h"
#include "lists.h"
#include "notice.h"
#include "procinfo.h"
#include "graphics.h"
#include "held.h"
#include "historystore.h"
#include "importer.h"
#include "instance.h"
#include "library.h"
#include "palette.h"
#include "passwords.h"
#include "update.h"
#include "widevine.h"

class CoreTest : public QObject
{
    Q_OBJECT

    // makes a small SQLite file for the import tests
    static bool database(const QString &path, const QStringList &statements)
    {
        bool ok = true;
        {
            QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", path);
            db.setDatabaseName(path);
            ok = db.open();
            for (const QString &s : statements)
                ok = ok && QSqlQuery(db).exec(s);
            db.close();
        }
        QSqlDatabase::removeDatabase(path);
        return ok;
    }

private slots:
    void resolve_data()
    {
        QTest::addColumn<QString>("typed");
        QTest::addColumn<QString>("expected");
        const auto search = [](const char *q) { return QStringLiteral("https://duckduckgo.com/?q=") + QLatin1String(q); };

        QTest::newRow("domain") << "vamola.dev" << "https://vamola.dev";
        QTest::newRow("path") << "  github.com/vam0laa " << "https://github.com/vam0laa";
        QTest::newRow("kept http") << "http://example.com/a" << "http://example.com/a";
        QTest::newRow("localhost") << "localhost:3000" << "http://localhost:3000";
        QTest::newRow("private ip") << "192.168.1.1" << "http://192.168.1.1";
        QTest::newRow("public ip") << "1.1.1.1" << "https://1.1.1.1";
        QTest::newRow("about") << "about:blank" << "about:blank";
        QTest::newRow("words") << "arch linux wiki" << search("arch%20linux%20wiki");
        QTest::newRow("one word") << "hyprland" << search("hyprland");
        QTest::newRow("number") << "3.14" << search("3.14");
        QTest::newRow("script") << "javascript:alert(1)" << search("javascript%3Aalert%281%29");
        QTest::newRow("data") << "data:text/html,x" << search("data%3Atext%2Fhtml%2Cx");
        QTest::newRow("disguise") << "bank.com@evil.example" << search("bank.com%40evil.example");
        QTest::newRow("ampersand") << "a & b" << search("a%20%26%20b");
        QTest::newRow("empty") << "   " << "";
    }

    void resolve()
    {
        QFETCH(QString, typed);
        QFETCH(QString, expected);
        QCOMPARE(address::resolve(typed).toString(QUrl::FullyEncoded), expected);
    }

    void searchEngines()
    {
        address::setEngine("brave");
        QCOMPARE(address::resolve("a b").toString(QUrl::FullyEncoded), "https://search.brave.com/search?q=a%20b");
        QVERIFY(address::isSearch("a b"));
        address::setEngine("nonsense");
        QCOMPARE(address::engine().key, "duckduckgo");
        for (const auto &e : address::engines())
            QVERIFY2(QByteArray(e.query).startsWith("https://"), e.key);
    }

    void searching()
    {
        QVERIFY(address::isSearch("arch wiki"));
        QVERIFY(address::isSearch("javascript:alert(1)"));
        QVERIFY(!address::isSearch("vamola.dev"));
        QVERIFY(!address::isSearch("https://duckduckgo.com"));
        QVERIFY(!address::isSearch(""));
    }

    void display()
    {
        QCOMPARE(address::display(QUrl("https://vamola.dev/")), "vamola.dev");
        QCOMPARE(address::display(QUrl("https://vamola.dev/tr/")), "vamola.dev/tr/");
        QCOMPARE(address::display(QUrl("http://example.com/")), "http://example.com/");
        QCOMPARE(address::display(QUrl("about:blank")), "");
    }

    void hybridGraphics()
    {
        const auto machine = [](const QStringList &vendors) {
            QTemporaryDir drm;
            int n = 128;
            for (const QString &v : vendors) {
                const QString dir = drm.path() + "/renderD" + QString::number(n++) + "/device";
                QDir().mkpath(dir);
                QFile f(dir + "/vendor");
                if (f.open(QIODevice::WriteOnly))
                    f.write(v.toLatin1() + '\n');
            }
            return graphics::hybridWithNvidia(drm.path());
        };
        QVERIFY(machine({"0x1002", "0x10de"}));
        QVERIFY(machine({"0x10de", "0x8086"}));
        QVERIFY(!machine({"0x10de"}));            // only NVIDIA: it must stay usable
        QVERIFY(!machine({"0x1002", "0x8086"}));
        QVERIFY(!machine({}));
    }

    void desktopColours()
    {
        const QVariantMap c = palette::parse("{\"primary\":\"#C3c6d6\",\"bad\":\"red\",\"short\":\"#fff\",\"n\":4,\"surface\":\"#131315\"}");
        QCOMPARE(c.size(), 2);
        QCOMPARE(c.value("primary").toString(), "#C3c6d6");
        QVERIFY(palette::parse("{ half written").isEmpty());
        QVERIFY(palette::parse("[1,2]").isEmpty());
    }

    void engineBlocksAndWritesPageScripts()
    {
        const auto blocker = Blocker::build({{"||ads.example^\nsite.test##.banner\n", false}}, {});
        QVERIFY(blocker);
        QVERIFY(blocker->blocks(QUrl("https://ads.example/x.js"), QUrl("https://site.test/"), "script"));
        QVERIFY(!blocker->blocks(QUrl("https://site.test/x.js"), QUrl("https://site.test/"), "script"));
        QVERIFY(blocker->pageScript(QUrl("https://site.test/")).contains(".banner{display:none!important}"));
        QVERIFY(blocker->pageScript(QUrl("https://other.test/")).isEmpty());
    }

    void downloadsAreChecked()
    {
        QVERIFY(lists::plausible("a.txt", "[Adblock Plus 2.0]\n" + QByteArray(300, 'x')));
        QVERIFY(!lists::plausible("a.txt", "<html>error</html>" + QByteArray(300, 'x')));
        QVERIFY(!lists::plausible("a.txt", "! short"));
        QVERIFY(lists::plausible("resources.json", "[{}]"));
        QVERIFY(!lists::plausible("resources.json", "[]"));
        for (const auto &source : lists::sources())
            QCOMPARE(source.url.scheme(), "https");
    }

    void upgrades()
    {
        QVERIFY(lists::shouldUpgrade(QUrl("http://example.com/a")));
        for (const char *keep : {"https://example.com", "http://localhost:3000", "http://192.168.1.1", "http://printer.local", "http://nas", "file:///tmp/a"})
            QVERIFY2(!lists::shouldUpgrade(QUrl(keep)), keep);
    }

    void history()
    {
        HistoryStore h(":memory:");
        QVERIFY(h.isOpen());
        h.add("https://a.example/", "Alpha", 100);
        h.add("https://b.example/x", "Beta 100%", 200);
        h.add("https://a.example/", "", 300);
        h.add("file:///etc/passwd", "no", 400);
        h.add("about:blank", "no", 400);
        QCOMPARE(h.search("", 10).size(), 2);
        QCOMPARE(h.search("", 10).first().toMap().value("title").toString(), "Alpha");   // newest, title kept
        QCOMPARE(h.search("beta", 10).size(), 1);
        QCOMPARE(h.search("100%", 10).size(), 1);
        QCOMPARE(h.search("%", 10).size(), 1);       // a percent sign is not a wildcard
        QCOMPARE(h.search("_", 10).size(), 0);
        h.add("https://user:secret@c.example/", "C", 500);
        QCOMPARE(h.search("secret", 10).size(), 0);
        h.setTitle("https://b.example/x", "Renamed");
        QCOMPARE(h.search("renamed", 10).size(), 1);
        QCOMPARE(h.frequent(5).size(), 1);          // only the page seen twice
        QCOMPARE(h.frequent(5).first().toMap().value("url").toString(), "https://a.example/");
        h.forgetBefore(250);
        QCOMPARE(h.search("", 10).size(), 2);
        h.remove("https://a.example/");
        QCOMPARE(h.search("", 10).size(), 1);
        h.clear();
        QCOMPARE(h.search("", 10).size(), 0);
    }

    void importsFromFirefox()
    {
        QTemporaryDir home;
        const QString profile = home.path() + "/.mozilla/firefox/ab12.default-release";
        QVERIFY(QDir().mkpath(profile));
        QVERIFY(database(profile + "/places.sqlite", {
            "CREATE TABLE moz_places(id INTEGER PRIMARY KEY, url TEXT, title TEXT, hidden INTEGER, visit_count INTEGER, last_visit_date INTEGER)",
            "CREATE TABLE moz_bookmarks(id INTEGER PRIMARY KEY, type INTEGER, fk INTEGER, parent INTEGER, position INTEGER, title TEXT, guid TEXT)",
            "INSERT INTO moz_places VALUES(1,'https://a.example/','A',0,5,2000000000),(2,'https://b.example/','B',0,1,50000000),"
            "(3,'place:sort=8','smart',0,0,NULL),(4,'https://hidden.example/','H',1,1,3000000000)",
            "INSERT INTO moz_bookmarks VALUES(1,2,NULL,0,0,'','root________'),(2,2,NULL,1,0,'toolbar','toolbar_____'),(3,2,NULL,2,0,'Linux','x'),"
            "(4,2,NULL,1,1,'tags','tags________'),(5,2,NULL,4,0,'etiket','y'),"
            "(6,1,1,2,0,'Alpha','a'),(7,1,2,3,0,'Beta','b'),(8,1,3,2,1,'smart','c'),(9,1,2,5,0,'tagged copy','d')"}));
        const auto sources = importer::find(home.path());
        QCOMPARE(sources.size(), 1);
        QCOMPARE(sources.first().name, "Firefox (default-release)");
        const auto data = importer::read(sources.first(), 100);
        QVERIFY(data.ok);
        QCOMPARE(data.bookmarks.size(), 2);
        QCOMPARE(data.bookmarks[0].folder, "");
        QCOMPARE(data.bookmarks[1].folder, "Linux");
        QCOMPARE(data.visits.size(), 1);           // the old and the hidden one are left out
        QCOMPARE(data.visits.first().last, 2000);
        QVERIFY(importer::read(sources.first(), -1).visits.isEmpty());
        HistoryStore h(":memory:");
        h.add("https://a.example/", "Mine", 9000);
        QCOMPARE(h.merge(data.visits), 1);
        QCOMPARE(h.merge(data.visits), 1);
        QCOMPARE(h.search("", 10).size(), 1);
        QCOMPARE(h.search("", 10).first().toMap().value("title").toString(), "Mine");
    }

    void importsFromChromium()
    {
        QTemporaryDir home;
        const QString profile = home.path() + "/.config/chromium/Default";
        QVERIFY(QDir().mkpath(profile));
        QVERIFY(QDir().mkpath(home.path() + "/.config/chromium/System Profile"));
        QFile marks(profile + "/Bookmarks");
        QVERIFY(marks.open(QIODevice::WriteOnly));
        marks.write(R"j({"roots":{"bookmark_bar":{"children":[{"type":"url","name":"A","url":"https://a.example/"},)j"
                    R"j({"type":"folder","name":"Kod","children":[{"type":"url","name":"B","url":"https://b.example/"},)j"
                    R"j({"type":"url","name":"js","url":"javascript:alert(1)"}]}]},"other":{"children":[]}}})j");
        marks.close();
        // 13000000000000000 microseconds since 1601 is a moment in 2012
        QVERIFY(database(profile + "/History", {
            "CREATE TABLE urls(url TEXT, title TEXT, visit_count INTEGER, last_visit_time INTEGER, hidden INTEGER)",
            "INSERT INTO urls VALUES('https://a.example/','A',2,13000000000000000,0),('chrome://settings/','s',1,13000000000000000,0)"}));
        const auto sources = importer::find(home.path());
        QCOMPARE(sources.size(), 1);
        const auto data = importer::read(sources.first(), 0);
        QVERIFY(data.ok);
        QCOMPARE(data.bookmarks.size(), 2);
        QCOMPARE(data.bookmarks[1].folder, "Kod");
        QCOMPARE(data.visits.size(), 1);
        QCOMPARE(data.visits.first().last, 13000000000LL - 11644473600LL);
        QVERIFY(marks.open(QIODevice::WriteOnly | QIODevice::Truncate));
        marks.write("{broken");
        marks.close();
        QVERIFY(!importer::read(sources.first(), -1).ok);
    }

    void passwordOrigins()
    {
        QCOMPARE(passwords::origin(QUrl("https://Site.example/login?x=1")), "https://site.example");
        QCOMPARE(passwords::origin(QUrl("https://user:pw@site.example:443/")), "https://site.example");
        QCOMPARE(passwords::origin(QUrl("https://site.example:8443/")), "https://site.example:8443");
        QCOMPARE(passwords::origin(QUrl("http://localhost:3000/a")), "http://localhost:3000");
        QCOMPARE(passwords::origin(QUrl("http://[::1]/")), "http://[::1]");
        for (const char *no : {"http://site.example/", "http://192.168.1.1/", "file:///tmp/a", "about:blank", "data:text/html,x", ""})
            QCOMPARE(passwords::origin(QUrl(no)), "");
        QVERIFY(passwords::origin(QUrl("https://xn--pple-43d.com/")) != passwords::origin(QUrl("https://apple.com/")));
    }

    // runs only through tests/run-keyring.sh, which gives it an empty keyring of its own
    void keyring()
    {
        const QByteArray sandbox = qgetenv("VELUM_TEST_KEYRING");
        if (sandbox.isEmpty() || sandbox != qgetenv("HOME"))
            QSKIP("needs the throwaway keyring of tests/run-keyring.sh");
        const auto empty = passwords::accounts({});
        QVERIFY(empty.has_value());
        QVERIFY(empty->isEmpty());
        const QString a = "https://a.example", b = "https://b.example";
        const QString secret = QString::fromUtf8("g\xc4\xb1zli \"\\ parola");
        QVERIFY(passwords::save(a, "ali", secret));
        QVERIFY(passwords::save(a, "veli", "two"));
        QVERIFY(passwords::save(b, "", "three"));
        QVERIFY(!passwords::save(a, "x", ""));
        QVERIFY(!passwords::save("", "x", "y"));
        QCOMPARE(passwords::accounts(a)->size(), 2);
        QCOMPARE(passwords::accounts({})->size(), 3);
        QCOMPARE(passwords::password(a, "ali").value_or("?"), secret);
        QCOMPARE(passwords::password(b, "").value_or("?"), "three");
        QVERIFY(!passwords::password(a, "nobody").has_value());
        QVERIFY(!passwords::password("https://c.example", "ali").has_value());
        QVERIFY(passwords::save(a, "ali", "new"));
        QCOMPARE(passwords::accounts(a)->size(), 2);
        QCOMPARE(passwords::password(a, "ali").value_or("?"), "new");
        QVERIFY(!passwords::remove("", ""));
        QVERIFY(passwords::remove(a, "ali"));
        QCOMPARE(passwords::accounts({})->size(), 2);
    }

    void storeAddresses()
    {
        const QString id = "ddkjiahejlhfcafbddmgiahcphecmpfh";
        QCOMPARE(crx::idFrom(" " + id + " "), id);
        QCOMPARE(crx::idFrom("https://chromewebstore.google.com/detail/ublock-origin-lite/" + id), id);
        QCOMPARE(crx::idFrom("https://chromewebstore.google.com/detail/" + id + "?hl=tr"), id);
        QCOMPARE(crx::idFrom("https://chrome.google.com/webstore/detail/x/" + id), id);
        for (const QString &no : {QString("http://chromewebstore.google.com/detail/x/" + id), QString("https://evil.example/detail/x/" + id),
                                  QString("https://chromewebstore.google.com/search/" + id), QString(id + "a"), QString("zz"), QString()})
            QCOMPARE(crx::idFrom(no), "");
        QVERIFY(crx::downloadAddress(id).startsWith("https://clients2.google.com/"));
    }

    // a package built and signed here, then tampered with
    void storePackages()
    {
        std::unique_ptr<EVP_PKEY, decltype(&EVP_PKEY_free)> key(EVP_RSA_gen(2048), EVP_PKEY_free);
        QVERIFY(key != nullptr);
        QByteArray der(i2d_PUBKEY(key.get(), nullptr), 0);
        auto *out = reinterpret_cast<unsigned char *>(der.data());
        i2d_PUBKEY(key.get(), &out);
        const QByteArray raw = QCryptographicHash::hash(der, QCryptographicHash::Sha256).left(16);
        QString id;
        for (const char c : raw) {
            id += QChar('a' + (quint8(c) >> 4));
            id += QChar('a' + (quint8(c) & 15));
        }
        const auto field = [](quint64 number, const QByteArray &value) {
            QByteArray bytes;
            const auto varint = [&bytes](quint64 v) { do { bytes.append(char((v & 0x7f) | (v > 0x7f ? 0x80 : 0))); v >>= 7; } while (v); };
            varint(number << 3 | 2);
            varint(quint64(value.size()));
            return bytes + value;
        };
        const auto number = [](quint32 v) { QByteArray b(4, 0); qToLittleEndian(v, b.data()); return b; };
        const QByteArray zip = "PK pretend zip", stated = field(1, raw);
        const QByteArray message = QByteArray("CRX3 SignedData\0", 16) + number(quint32(stated.size())) + stated + zip;
        std::unique_ptr<EVP_MD_CTX, decltype(&EVP_MD_CTX_free)> context(EVP_MD_CTX_new(), EVP_MD_CTX_free);
        QVERIFY(EVP_DigestSignInit(context.get(), nullptr, EVP_sha256(), nullptr, key.get()) == 1);
        size_t length = 512;
        QByteArray signature(512, 0);
        QVERIFY(EVP_DigestSign(context.get(), reinterpret_cast<unsigned char *>(signature.data()), &length,
                               reinterpret_cast<const unsigned char *>(message.constData()), size_t(message.size())) == 1);
        signature.resize(qsizetype(length));
        const QByteArray header = field(2, field(1, der) + field(2, signature)) + field(10000, stated);
        const QByteArray package = "Cr24" + number(3) + number(quint32(header.size())) + header + zip;

        QCOMPARE(crx::verifiedZip(package, id), zip);
        QVERIFY(crx::verifiedZip(package, QString(32, 'a')).isEmpty());       // asked for another one
        QVERIFY(crx::verifiedZip(package + "x", id).isEmpty());               // changed content
        QByteArray broken = package;
        broken[broken.size() - 1] = 'X';
        QVERIFY(crx::verifiedZip(broken, id).isEmpty());
        for (qsizetype n = 0; n < package.size(); n += 7)                     // cut short anywhere
            QVERIFY(crx::verifiedZip(package.left(n), id).isEmpty());
        QVERIFY(crx::verifiedZip("Cr24" + number(3) + number(0xffffffffu) + header, id).isEmpty());
        QVERIFY(crx::verifiedZip("Cr24" + number(2) + number(0) + zip, id).isEmpty());
    }

    void xwaylandOnlyWhenSharp()
    {
        const QByteArray screens = R"([{"scale":1.0,"focused":false},{"scale":1.6666666,"focused":true}])";
        const QByteArray on = R"({"option":"xwayland:force_zero_scaling","bool":true,"set":true})";
        QCOMPARE(graphics::xwaylandScale(screens, on), 1.6666666);
        QCOMPARE(graphics::xwaylandScale(R"([{"scale":2.0}])", on), 2.0);
        QCOMPARE(graphics::xwaylandScale(screens, R"({"bool":false})"), 0.0);
        QCOMPARE(graphics::xwaylandScale(screens, "unknown option"), 0.0);
        QCOMPARE(graphics::xwaylandScale("", on), 0.0);
        QCOMPARE(graphics::xwaylandScale(R"([{"scale":40}])", on), 0.0);
    }

    void desktopCursor()
    {
        QTemporaryDir icons;
        QVERIFY(QDir(icons.path()).mkpath("Bibata/cursors"));
        QCOMPARE(graphics::cursorTheme("'Bibata'\n", {"/nowhere", icons.path()}), QByteArray("Bibata"));
        QCOMPARE(graphics::cursorTheme("'Missing'\n", {icons.path()}), QByteArray());
        QCOMPARE(graphics::cursorTheme("'../Bibata'", {icons.path()}), QByteArray());
        QCOMPARE(graphics::cursorTheme("", {icons.path()}), QByteArray());
        QCOMPARE(graphics::cursorSize("24\n"), 24);
        QVERIFY(graphics::writePointerFolder(icons.filePath("own"), "Bibata"));
        QFile index(icons.filePath("own/default/index.theme"));
        QVERIFY(index.open(QIODevice::ReadOnly));
        QVERIFY(index.readAll().contains("\nInherits=Bibata\n"));
        QVERIFY(!graphics::writePointerFolder(icons.filePath("own"), "a\nInherits=b"));
        QCOMPARE(graphics::cursorSize("uint32 x"), 0);
    }

    void bookmarkFiles()
    {
        const QVariantList list{QVariantMap{{"title", "A & <b>"}, {"url", "https://a.example/?x=1&y=2"}},
                                QVariantMap{{"title", "Tool"}, {"url", "https://t.example/"}, {"folder", "Work/Tools"}},
                                QVariantMap{{"title", "Mail"}, {"url", "https://m.example/"}, {"folder", "Work"}}};
        const QString html = library::toHtml(list);
        QVERIFY(html.contains("A &amp; &lt;b&gt;"));
        const QVariantList back = library::fromHtml(html);
        QCOMPARE(back.size(), 3);
        QStringList seen;
        for (const QVariant &v : back)
            seen << v.toMap().value("title").toString() + "|" + v.toMap().value("folder").toString() + "|" + v.toMap().value("url").toString();
        seen.sort();
        QCOMPARE(seen, (QStringList{"A & <b>||https://a.example/?x=1&y=2", "Mail|Work|https://m.example/", "Tool|Work/Tools|https://t.example/"}));
        // as other browsers write it, and with things that must not come in
        const QVariantList other = library::fromHtml("<DL><p><DT><H3 ADD_DATE=\"1\">&#199;ay</H3><DL><p><DT><A HREF=\"https://c.example/\" ICON=\"x\">C</A>"
                                                     "<DT><A HREF=\"javascript:alert(1)\">bad</A><DT><A HREF=\"data:text/html,x\">bad</A></DL><p><DT><A href=\"http://d.example/\">D</A></DL>");
        QCOMPARE(other.size(), 2);
        QCOMPARE(other[0].toMap().value("folder").toString(), QString::fromUtf8("Çay"));
        QVERIFY(!other[1].toMap().contains("folder"));
        QVERIFY(library::fromHtml("<<<>>> </DL></DL>").isEmpty());
    }

    void lockedFiles()
    {
        const QByteArray sealed = library::seal("secret bookmarks", "dogru parola");
        QVERIFY(!sealed.isEmpty() && !sealed.contains("secret"));
        QCOMPARE(library::unseal(sealed, "dogru parola").value_or(""), QByteArray("secret bookmarks"));
        QVERIFY(!library::unseal(sealed, "yanlis parola"));
        QByteArray bent = sealed;
        bent[bent.size() - 1] = char(bent[bent.size() - 1] ^ 1);
        QVERIFY(!library::unseal(bent, "dogru parola"));
        QVERIFY(!library::unseal(sealed.left(20), "dogru parola") && !library::unseal("nonsense", "x"));
        QVERIFY(library::seal("a", "").isEmpty());
        QVERIFY(library::seal("a", "p") != library::seal("a", "p"));      // salted: never the same twice
    }

    void historyByTime()
    {
        HistoryStore store(":memory:");
        store.add("https://old.example/", "old", 100);
        store.add("https://new.example/", "new", 200);
        QCOMPARE(store.browse("", 10).size(), 2);
        QCOMPARE(store.browse("", 10).first().toMap().value("title").toString(), "new");
        QCOMPARE(store.browse("old", 10).size(), 1);
        QCOMPARE(store.browse("%", 10).size(), 0);
        store.removeSince(150);
        QCOMPARE(store.browse("", 10).size(), 1);
        store.removeSince(0);
        QCOMPARE(store.browse("", 10).size(), 0);
    }

    void passwordTools()
    {
        for (int i = 0; i < 50; ++i) {
            const QString p = library::generatePassword(20);
            QCOMPARE(p.size(), 20);
            QVERIFY(p.contains(QRegularExpression("[a-z]")) && p.contains(QRegularExpression("[A-Z]")) && p.contains(QRegularExpression("[0-9]")) && p.contains(QRegularExpression("[^a-zA-Z0-9]")));
        }
        QCOMPARE(library::generatePassword(1).size(), 12);
        QVERIFY(library::generatePassword(20) != library::generatePassword(20));
        const auto read = library::fromCsv("\xEF\xBB\xBFname,url,username,password,note\r\n\"A, inc\",https://a.example/login,me,\"p\"\"w,1\"\r\nb,https://b.example,,secret\r\nbad,,x,\r\n");
        QCOMPARE(read.size(), 2);
        QCOMPARE(read[0].password, "p\"w,1");
        QCOMPARE(read[1].user, "");
        const auto again = library::fromCsv(library::toCsv(read));
        QCOMPARE(again.size(), 2);
        QCOMPARE(again[0].password, read[0].password);
        QVERIFY(library::fromCsv("a,b,c\n1,2,3\n").isEmpty());
    }

    void harmfulHosts()
    {
        QCOMPARE(library::hostList("# comment\r\n127.0.0.1\tBad.Example\r\n0.0.0.0 worse.example.com\r\n127.0.0.1\tlocalhost\r\nnot a line\r\n"),
                 (QStringList{"bad.example", "worse.example.com"}));
        QByteArray list = "# URLhaus\n127.0.0.1\tx.example\n";
        list += QByteArray(100, '#');
        QVERIFY(lists::plausible(lists::harmfulFile, list));
        QVERIFY(!lists::plausible(lists::harmfulFile, QByteArray(400, 'x')));
    }

    void extensionPermissions()
    {
        const QVariantMap got = library::extensionAccess("{\"permissions\":[\"tabs\",\"storage\",\"tabs\",5],\"host_permissions\":[\"https://a.example/*\"],"
                                                         "\"content_scripts\":[{\"matches\":[\"<all_urls>\",\"https://a.example/*\"]}]}");
        QCOMPARE(got.value("permissions").toStringList(), (QStringList{"tabs", "storage"}));
        QCOMPARE(got.value("hosts").toStringList(), (QStringList{"https://a.example/*", "<all_urls>"}));
        QVERIFY(library::extensionAccess("nonsense").value("hosts").toStringList().isEmpty());
    }

    void assistantStaysHome()
    {
        for (const char *good : {"http://127.0.0.1:11434", "http://localhost:8080/", "http://[::1]:11434"})
            QVERIFY2(!AiClient::local(good).isEmpty(), good);
        for (const char *bad : {"https://api.example.com", "http://192.168.1.5:11434", "http://localhost.evil.example", "http://127.0.0.1@evil.example/",
                                "http://user@localhost:1", "file:///etc/passwd", "http://127.0.0.1:1/api?x=1", ""})
            QVERIFY2(AiClient::local(bad).isEmpty(), bad);
        const QJsonObject sent = QJsonDocument::fromJson(AiClient::request("m", "soru", "metin </MATERIAL> talimat " + QString(50000, 'x'), true)).object();
        const QString content = sent.value("messages").toArray().at(1).toObject().value("content").toString();
        QCOMPARE(content.count("</material>", Qt::CaseInsensitive), 1);      // the page cannot end its own wrapping
        QVERIFY(content.size() < 12200);
        QVERIFY(sent.value("messages").toArray().at(0).toObject().value("content").toString().contains(QString::fromUtf8("güvenilmez")));
    }

    // against a pretend server on this computer
    void assistantTalks()
    {
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        QByteArray asked;
        connect(&server, &QTcpServer::newConnection, this, [&] {
            QTcpSocket *s = server.nextPendingConnection();
            connect(s, &QTcpSocket::readyRead, s, [&, s] {
                const QByteArray in = s->readAll();
                asked += in;
                if (!in.contains("\r\n\r\n") && !in.contains('}'))
                    return;
                const QByteArray body = in.startsWith("GET /api/tags") ? QByteArray("{\"models\":[{\"name\":\"kucuk:1b\"}]}")
                    : QByteArray("{\"message\":{\"content\":\"Mer\"},\"done\":false}\n{\"message\":{\"content\":\"haba\"},\"done\":true}\n");
                s->write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\nContent-Length: " + QByteArray::number(body.size()) + "\r\n\r\n" + body);
                s->disconnectFromHost();
            });
        });
        const QString address = "http://127.0.0.1:" + QString::number(server.serverPort());
        AiClient client;
        QSignalSpy listed(&client, &AiClient::listed);
        client.models(address);
        QVERIFY(listed.wait(5000));
        QCOMPARE(listed.first().first().toStringList(), QStringList{"kucuk:1b"});
        QString answer;
        connect(&client, &AiClient::piece, this, [&](const QString &p) { answer += p; });
        QSignalSpy done(&client, &AiClient::finished);
        client.ask(address, AiClient::request("kucuk:1b", "selam", "", true));
        QVERIFY(client.busy());
        QVERIFY(done.wait(5000));
        QCOMPARE(done.first().first().toString(), QString());
        QCOMPARE(answer, "Merhaba");
        QVERIFY(!client.busy() && asked.contains("selam"));
        server.close();
        QSignalSpy failed(&client, &AiClient::finished);
        client.ask(address, "{}");
        QVERIFY(failed.wait(5000));
        QCOMPARE(failed.first().first().toString(), "server");
        QSignalSpy outside(&client, &AiClient::finished);
        client.ask("http://example.com", "{}");
        QCOMPARE(outside.first().first().toString(), "address");
    }

    void heldDownloads()
    {
        QTemporaryDir dir;
        const auto make = [&](const QString &name) { QFile f(dir.filePath(name)); QVERIFY(f.open(QIODevice::WriteOnly)); f.write(name.toUtf8()); };
        make("tool.sh");
        make("tool.sh.velum-hold");
        QCOMPARE(held::release(dir.path(), "tool.sh.velum-hold"), "tool (1).sh");      // the old one stays
        QVERIFY(QFile::exists(dir.filePath("tool.sh")) && !QFile::exists(dir.filePath("tool.sh.velum-hold")));
        make("x.exe.velum-hold");
        QVERIFY(held::discard(dir.path(), "x.exe.velum-hold"));
        QVERIFY(!QFile::exists(dir.filePath("x.exe.velum-hold")));
        const QString free = held::freePath(dir.path(), "../a/b: \"c\"?", "pdf");
        QCOMPARE(QFileInfo(free).absolutePath(), QDir(dir.path()).absolutePath());
        QCOMPARE(QFileInfo(free).fileName(), "a b c.pdf");
        make("a b c.pdf");
        QCOMPARE(QFileInfo(held::freePath(dir.path(), "a b c", "pdf")).fileName(), "a b c (1).pdf");
        QCOMPARE(QFileInfo(held::freePath(dir.path(), "...", "pdf")).fileName(), "page.pdf");
        QVERIFY(held::freePath("/nowhere", "x", "pdf").isEmpty());
        // nothing but held files, and nothing outside the folder
        QVERIFY(!held::discard(dir.path(), "tool.sh") && QFile::exists(dir.filePath("tool.sh")));
        QVERIFY(held::release(dir.path(), "../a.velum-hold").isEmpty());
        QVERIFY(held::release(dir.path(), ".velum-hold").isEmpty());
        QVERIFY(!held::discard(dir.path(), "sub/a.velum-hold"));
    }

    void argumentsThatAreFiles()
    {
        QTemporaryDir dir;
        QFile page(dir.filePath("bir sayfa.html"));
        QVERIFY(page.open(QIODevice::WriteOnly));
        page.close();
        const QUrl file = address::fromArgument(page.fileName());
        QVERIFY(file.isLocalFile());
        QCOMPARE(file.toLocalFile(), page.fileName());
        // handed to a running Velum it stays whole, spaces and all
        QCOMPARE(Instance::accepted(file.toString(QUrl::FullyEncoded).toUtf8()), QStringList{file.toString(QUrl::FullyEncoded)});
        const QString before = QDir::currentPath();
        QVERIFY(QDir::setCurrent(dir.path()));
        QVERIFY(address::fromArgument("bir sayfa.html").isLocalFile());
        QDir::setCurrent(before);
        QCOMPARE(address::fromArgument("example.com"), QUrl("https://example.com"));
    }

    void turkishSearch()
    {
        HistoryStore store(":memory:");
        store.add("https://a.example/", QString::fromUtf8("İzmir ÇAY Şehir IŞIK"), 1);
        for (const char *typed : {"izmir", "İZMİR", "çay", "şehir", "ışık", "Işık"})
            QVERIFY2(store.search(QString::fromUtf8(typed), 5).size() == 1, typed);
        store.setTitle("https://a.example/", "Ankara");
        QCOMPARE(store.search("izmir", 5).size(), 0);
        QCOMPARE(store.search("ankara", 5).size(), 1);
    }

    void accelerationSetting()
    {
        QCOMPARE(graphics::engineFlags(false, false, true), QByteArray("--disable-gpu"));
        QCOMPARE(graphics::engineFlags(true, true, true), QByteArray());
        QVERIFY(graphics::engineFlags(true, false, true).contains("AcceleratedVideoDecodeLinuxGL"));
        QVERIFY(!graphics::engineFlags(true, false, false).contains("Linux"));
        QVERIFY(!graphics::engineFlags(true, false, true).contains("ignore-gpu-blocklist"));
    }

    void updateVersions()
    {
        QCOMPARE(update::compare("0.1.0-beta.2", "0.1.0-beta.1"), 1);
        QCOMPARE(update::compare("0.1.0-beta.10", "0.1.0-beta.9"), 1);
        QCOMPARE(update::compare("0.1.0", "0.1.0-beta.99"), 1);
        QCOMPARE(update::compare("0.2.0-beta.1", "0.1.5"), 1);
        QCOMPARE(update::compare("1.0.0", "1.0.0"), 0);
        QCOMPARE(update::compare("nonsense", "0.0.1"), -1);
        QCOMPARE(update::compare("0.0.1", "v2"), 1);
    }

    // a description signed here with a throwaway key, then bent in every way
    void updatesMustBeSigned()
    {
        std::unique_ptr<EVP_PKEY, decltype(&EVP_PKEY_free)> key(EVP_PKEY_Q_keygen(nullptr, nullptr, "ED25519"), EVP_PKEY_free);
        QVERIFY(key != nullptr);
        QByteArray pub(32, 0);
        size_t length = 32;
        QCOMPARE(EVP_PKEY_get_raw_public_key(key.get(), reinterpret_cast<unsigned char *>(pub.data()), &length), 1);
        const QByteArray hex = pub.toHex();
        const auto sign = [&](const QByteArray &data) {
            std::unique_ptr<EVP_MD_CTX, decltype(&EVP_MD_CTX_free)> context(EVP_MD_CTX_new(), EVP_MD_CTX_free);
            QByteArray out(64, 0);
            size_t n = 64;
            if (EVP_DigestSignInit(context.get(), nullptr, nullptr, nullptr, key.get()) != 1
                || EVP_DigestSign(context.get(), reinterpret_cast<unsigned char *>(out.data()), &n,
                                  reinterpret_cast<const unsigned char *>(data.constData()), size_t(data.size())) != 1)
                return QByteArray();
            return out.toBase64();
        };
        QTemporaryDir dir;
        QFile installer(dir.filePath("setup.exe"));
        QVERIFY(installer.open(QIODevice::WriteOnly));
        installer.write("pretend installer");
        installer.close();
        const QByteArray digest = QCryptographicHash::hash("pretend installer", QCryptographicHash::Sha256).toHex();
        const QString from = "https://github.com/o/r/releases/download/";
        const auto manifest = [&](const QString &url, const QString &version = "0.2.0", const QByteArray &sum = {}, int size = 17) {
            return QString(R"({"version":"%1","url":"%2","sha256":"%3","size":%4,"notes":"n"})")
                .arg(version, url, QString::fromLatin1(sum.isEmpty() ? digest : sum)).arg(size).toUtf8();
        };
        const QByteArray good = manifest(from + "v0.2.0/setup.exe");
        const auto release = update::verify(good, sign(good), hex, from);
        QVERIFY(release.has_value());
        QCOMPARE(release->version, "0.2.0");
        QVERIFY(update::matches(installer.fileName(), *release));
        QVERIFY(!update::verify(good + " ", sign(good), hex, from));                    // changed after signing
        QVERIFY(!update::verify(good, sign(good + " "), hex, from));
        QVERIFY(!update::verify(good, sign(good), QByteArray(64, 'a'), from));           // another key
        QVERIFY(!update::verify(good, "", hex, from));
        for (const QByteArray &bad : {manifest("https://evil.example/setup.exe"), manifest(from + "../../x/setup.exe"),
                                      manifest("http://github.com/o/r/releases/download/v/setup.exe"), manifest(from + "v/s.exe", "latest"),
                                      manifest(from + "v/s.exe", "0.2.0", "abc"), manifest(from + "v/s.exe", "0.2.0", {}, 0)})
            QVERIFY2(!update::verify(bad, sign(bad), hex, from), bad);
        QVERIFY(installer.open(QIODevice::WriteOnly | QIODevice::Truncate));
        installer.write("pretend installeR");
        installer.close();
        QVERIFY(!update::matches(installer.fileName(), *release));
    }

    void ownProcess()
    {
        const qint64 self = QCoreApplication::applicationPid();
        QVERIFY(procinfo::memoryKb(self) > 0);
        QVERIFY(procinfo::cpuMs(self) >= 0);
        QVERIFY(procinfo::tree(self).contains(self));
    }

    void processes()
    {
#ifndef Q_OS_LINUX
        QSKIP("reads /proc");
#else
        QCOMPARE(procinfo::pssKb("55d0-7ffd ---p [rollup]\nRss:  900 kB\nPss:  1234 kB\nPss_Anon: 5 kB\n"), 1234);
        QCOMPARE(procinfo::pssKb("nothing"), -1);
        QCOMPARE(procinfo::cpuTicks("42 (odd ) name) S 1 2 3 4 5 6 7 8 9 10 30 12 0 0"), 42);
        QCOMPARE(procinfo::cpuTicks("broken"), -1);
        QTemporaryDir proc;
        const auto process = [&](int pid, int parent) {
            QDir().mkpath(proc.path() + "/" + QString::number(pid));
            QFile f(proc.path() + "/" + QString::number(pid) + "/stat");
            if (f.open(QIODevice::WriteOnly))
                f.write(QString("%1 (x) S %2 0 0").arg(pid).arg(parent).toLatin1());
        };
        process(10, 1); process(11, 10); process(12, 11); process(20, 1);
        QList<qint64> found = procinfo::tree(proc.path(), 10);
        std::sort(found.begin(), found.end());
        QCOMPARE(found, (QList<qint64>{10, 11, 12}));
#endif
    }

    void messagesFromASecondStart()
    {
        const QStringList got = Instance::accepted("https://a.example/x y\nhttps://b.example/\njavascript:alert(1)\ndata:text/html,x\nfile:///tmp/a.html\n\nnot a url\n");
        QCOMPARE(got, (QStringList{"https://b.example/", "file:///tmp/a.html"}));
        QVERIFY(Instance::accepted(QByteArray(100000, 'a')).isEmpty());
        QVERIFY(Instance::socketName("/a") != Instance::socketName("/b"));
    }

    void secondStartHandsOver()
    {
        QTemporaryDir dir;
        const QString socket = dir.path() + "/s";
        QVERIFY(!Instance::handOver(socket, {"https://a.example/"}));      // nobody listening yet
        Instance first;
        QVERIFY(first.listen(socket));
        QSignalSpy spy(&first, &Instance::received);
        QVERIFY(Instance::handOver(socket, {"https://a.example/"}));
        QVERIFY(spy.wait(4000));
        QCOMPARE(spy.first().first().toStringList(), QStringList{"https://a.example/"});
    }

    void notificationText()
    {
        QCOMPARE(notice::plain("a\n<b>hi</b>  &", 80), "a &lt;b&gt;hi&lt;/b&gt; &amp;");
        QCOMPARE(notice::plain(QString::fromUtf8("ok\x07\xe2\x80\xae!"), 80), "ok!");   // bell and right-to-left override
        QCOMPARE(notice::plain(QString(200, 'a'), 10).size(), 10);
        QCOMPARE(notice::body("", "x.example"), "x.example");
        QCOMPARE(notice::body("hello", "x.example"), "hello\nx.example");
    }

    void newestWidevineWins()
    {
#ifndef Q_OS_LINUX
        QSKIP("the paths in this test are those of Linux");
#endif
        QTemporaryDir home;
        for (const char *v : {"4.10.2000.0", "4.10.3112.0", "4.10.900.0"}) {
            const QString dir = home.path() + "/.config/chromium/WidevineCdm/" + v + "/_platform_specific/linux_x64";
            QVERIFY(QDir().mkpath(dir));
            QFile f(dir + "/libwidevinecdm.so");
            QVERIFY(f.open(QIODevice::WriteOnly));
        }
        QVERIFY(widevine::find(home.path(), {}).contains("4.10.3112.0"));
        QTemporaryDir empty;
        QVERIFY(widevine::find(empty.path(), {}).isEmpty());
    }
};

QTEST_GUILESS_MAIN(CoreTest)
#include "test_core.moc"

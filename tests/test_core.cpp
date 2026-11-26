#include <QDir>
#include <QSignalSpy>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QTest>

#include "address.h"
#include "blocker.h"
#include "lists.h"
#include "notice.h"
#include "procinfo.h"
#include "graphics.h"
#include "historystore.h"
#include "importer.h"
#include "instance.h"
#include "palette.h"
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

    void processes()
    {
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

<p align="center"><img src="src/Yolla/wwwroot/icon-192.png" width="88" alt=""></p>
<h1 align="center">Yolla</h1>
<p align="center">Telefonundaki fotoğrafları, videoları ve dosyaları kendi bilgisayarındaki bir klasöre yolla.<br>Telefona uygulama kurmak yok, bulut yok, hesap açmak yok.</p>

<p align="center">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/lisans-MIT-blue.svg"></a>
  <img alt=".NET 10" src="https://img.shields.io/badge/.NET-10-512BD4">
  <img alt="Docker amd64 | arm64" src="https://img.shields.io/badge/docker-amd64%20%7C%20arm64-2496ED">
  <a href="README.md"><img alt="English" src="https://img.shields.io/badge/README-English-blue"></a>
</p>

<p align="center"><img src="docs/demo.gif" width="300" alt="iPhone'da Yolla: 13 fotoğraf seçiliyor, bilgisayardaki klasöre düşüyor">&nbsp;&nbsp;<img src="docs/receive-dark.png" width="300" alt="Koyu temada Al sekmesi"></p>

## Bu ne?

Yolla, dosya kabul eden küçücük bir web sayfası. Dosyaların gitmesini istediğin bilgisayarda çalıştırıyorsun; Windows, Mac, Linux, NAS ya da Raspberry Pi, fark etmez. Sonra telefonundan adresini açıyorsun, **Fotoğraf & Video**'ya basıp istediğin kadar fotoğraf seçiyorsun, hepsi o bilgisayardaki sıradan bir klasöre iniyor. Tersi de mümkün: bilgisayarda `Outbox` klasörüne attığın dosyalar telefonda görünüyor, oradan alıyorsun. Önüne bir tünel ya da kendi alan adını koyduğunda sadece evde değil, dünyanın her yerinden çalışıyor.

Bunu yazmamın sebebi basit: iPhone'daki birkaç yüz tatil fotoğrafını Windows'a atmak hâlâ işkence. iCloud for Windows olmadık yerde tıkanıyor, AirDrop yalnızca Apple cihazlarla konuşuyor, "dosya aktarma" uygulamalarının hepsi iki cihaza da kurulmak ve aynı Wi‑Fi'da olmak istiyor. Ben tam tersini istedim: tek konteyner, tek sayfa, kendi klasörüm. Projenin tamamı bir C# dosyası ile bir HTML dosyasından ibaret, harici bağımlılığı yok. Bir akşamda okur, sonra unutursun.

## Neden Yolla?

Dosya taşımanın yüz yolu var. Bunu farklı kılan şeyler şunlar:

- **Telefona hiçbir şey kurmuyorsun.** Tarayıcıda bir adres açıyorsun, o kadar. iPhone, Android, eşinin telefonu, arkadaşının bilgisayarı; tarayıcısı olan her cihaz olur.
- **Öğrenmen gereken bir şey yok.** Tek sayfa, iki düğme. Hesap yok, kütüphane yok, ayar ekranı yok, ayar dosyası yok.
- **Dosyalar klasöre iniyor.** Kendi bilgisayarındaki normal bir klasöre; buluta ya da bir uygulamanın kendi veritabanına değil. Explorer'da veya Finder'da diğer klasörler gibi açıyorsun.
- **Her yerden çalışıyor.** Ücretsiz bir tünelle aynı adres ofisten de, otelden de, başka bir ülkeden de çalışıyor.
- **Toplu iş için tasarlandı.** 400 fotoğraf seç, telefonu kenara koy. Bağlantı koparsa aynı fotoğrafları yeniden seç: kaldığı yerden devam ediyor, aynı fotoğrafı iki kez yüklemiyor.
- **Yüklediklerin geri okunamıyor.** Telefonun görebildiği tek klasör, senin bilerek doldurduğun Outbox. Yüklediğin her şey yalnızca yazılabilir; linki eline geçiren biri fotoğraflarına göz atamaz, şifre koyduysan yükleme de yapamaz.
- **Okuyup güvenebileceğin kadar küçük.** İki dosya. Bağımlılık yok, telemetri yok, kendi ağının dışına giden tek bir istek yok.
- **Ücretsiz.** MIT lisansı. Windows, macOS ve Linux'ta tek satırla kuruluyor; Raspberry Pi'de, NAS'ta da rahat çalışıyor.

Sık kullanılan araçlarla karşılaştırırsak:

| | Yolla | LocalSend | PairDrop | copyparty | Immich / Nextcloud |
|---|:-:|:-:|:-:|:-:|:-:|
| Telefona kurulum gerektirmez | ✅ | ❌ iki cihaza da uygulama | ✅ | ✅ | ❌ uygulama |
| Ev dışından çalışır | ✅ | ❌ yalnızca aynı Wi‑Fi | ~ iki tarafta da sayfa açık olmalı | ✅ | ✅ |
| Dosyalar sıradan bir klasöre iner | ✅ | ✅ | ~ tarayıcının indirme klasörüne, ZIP olarak | ✅ | ❌ kendi kütüphanesine |
| Öğrenecek, ayarlayacak bir şey yok | ✅ | ✅ | ✅ | ❌ yüzlerce seçenek | ❌ |
| Kopan 400 dosyalık yüklemeyi sürdürür | ✅ | ❌ | ❌ | ✅ | ✅ |
| Yüklenenler geri okunamaz | ✅ | – | – | ~ ayarlanabilir | ❌ |

<sub>Eylül 2026 itibarıyla, bildiğim kadarıyla. Kullandığın araç hakkında yanlış bir şey yazdıysam bir issue aç, düzelteyim.</sub>

Ne zaman başka bir araç daha iyi olur? Dosyalarına telefondan göz atıp indirmek de istiyorsan, üstüne küçük resim, WebDAV ve medya oynatıcı da gerekiyorsa [copyparty](https://github.com/9001/copyparty) bunların hepsini ve çok daha fazlasını yapıyor. Yüz tanıyan, telefondan otomatik yedek alan tam teşekküllü bir fotoğraf arşivi istiyorsan aradığın şey [Immich](https://immich.app). İki cihaz hep aynı Wi‑Fi'daysa ve uygulama kurmak senin için dert değilse [LocalSend](https://localsend.org) gayet iyi. Yolla ise tek bir şey istediğin an için: "Şu dosyalar bilgisayarıma geçsin, hemen, hiçbir şey ayarlamadan."

## Neler yapıyor?

- Aynı anda üç dosya yüklüyor, hata olursa yeniden deniyor; ilerlemeyi, hızı ve kalan süreyi gösteriyor.
- Her dosyayı 32 MB'lık parçalar hâlinde doğrudan diske yazıyor. Bağlantı koparsa en fazla bir parça kaybediyorsun; aynı dosyaları yeniden seçtiğinde tam kaldığı bayttan devam ediyor.
- Hiçbir dosyanın üzerine yazmıyor. Adı ve boyutu aynı olan dosya zaten var sayılıp atlanıyor; adı aynı ama içeriği farklı olan `IMG_0001 (1).JPG` diye kaydediliyor.
- Fotoğrafın çekim tarihini dosyanın tarihi yapıyor; klasörün yükleme sırasına değil, çekim tarihine göre sıralanıyor. İstersen `YYYY/YYYY-AA/` şeklinde alt klasörlere de dağıtıyor.
- **Al** sekmesi: bilgisayarda `Outbox` klasörüne koyduğun dosyalar telefonda listeleniyor. Tek dosyayı indiriyorsun, birkaçını seçersen ZIP olarak geliyor, iPhone'da *Fotoğraflara Kaydet* dersen doğrudan galeriye iniyor.
- Her tarayıcıda çalışıyor. Bilgisayarda sürükle-bırak ve yapıştırma da var. İkinci düğme fotoğraf dışındaki dosyaları da alıyor. Açık ve koyu tema, Türkçe ve İngilizce arayüz. iPhone'da *Ana Ekrana Ekle* dediğinde uygulama simgesi gibi duruyor.
- İsteğe bağlı erişim şifresi, dosya boyutu sınırı ve her yükleme için ayrı alt klasör.
- Cloudflare Tunnel'ın, ngrok'un, kendi reverse proxy'nin (alt yol altında bile) ya da düz yerel ağın arkasında; hepsinde çalışıyor. Parçalar Cloudflare'in istek başına 100 MB sınırının altında kalıyor.

## Kurulum

### Önce üç şeye karar ver

Kurulum betiği sana soru sormuyor; her şeyi varsayılan değerlerle kuruyor. Sonradan bir şeyi değiştirmek istersen betiği yeniden çalıştırman yeterli. Yine de neyi ayarladığını bilmek iyi olur:

1. **Klasör.** Yüklenen dosyaların bu bilgisayarda gideceği yer. Varsayılanı, ev klasörünün içindeki `Pictures/Yolla`. Herhangi bir klasör olabilir; yoksa betik oluşturuyor.
2. **Erişim şifresi.** Kısacası bir parola. Telefon bunu bir kez soruyor, sonra hatırlıyor. Şifre koymazsan adresi bulan herkes diskine dosya atabilir; bu yüzden Yolla'yı evden dışarı hiç çıkarmayacak olsan bile bir şifre olsun. Sen belirlemezsen betik rastgele bir tane üretip ekrana yazıyor.
3. **Tünel.** Yalnızca Yolla'ya kendi Wi‑Fi'ının dışından erişmek istiyorsan gerekiyor. `quick`, hesap açmadan rastgele bir Cloudflare adresi veriyor (her yeniden başlatmada değişiyor). `cloudflare` (kendi alan adında kalıcı adres) ve `ngrok` ise o servislerden alacağın bir token istiyor; ayrıntılar [Her yerden erişim](#her-yerden-erişim) bölümünde. Evde deneme yaparken bunu atlayabilirsin.

Docker gerekiyor: Windows ve macOS'ta [Docker Desktop](https://docker.com/products/docker-desktop). Linux'ta betik Docker'ı senin adına kurmayı teklif ediyor; sen onaylıyorsun.

### Tek satır

Varsayılanlarla: klasör `Pictures/Yolla`, şifre otomatik üretiliyor, tünel yok.

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1 | iex
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash
```

Betik Docker'ın kurulu olup olmadığına bakıyor, ayar dosyasını yazıyor, imajı indiriyor, Yolla'yı başlatıyor ve sonunda üç şeyi ekrana yazıyor: bu bilgisayardaki adres, Wi‑Fi'daki adres ve şifre.

İnternetten indirilen bir betiği doğrudan çalıştırmak hoşuna gitmiyorsa haklısın. Önce indir, oku (200 satır kadar), sonra çalıştır:

```bash
curl -fsSLO https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh && less install.sh && bash install.sh
```

### Parametreyle

Aynı komutlar, ama üç ayarı da kendin veriyorsun. Örnekte `D:` sürücüsünde bir klasör, kendi şifren ve hemen her yerden erişilsin diye hızlı tünel var:

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1))) -Dir "D:\Fotolar\Yolla" -Token "gizli" -Tunnel quick
```
```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash -s -- --dir ~/Pictures/Yolla --token gizli --tunnel quick
```

Sonradan fikrin değişirse betiği başka parametrelerle yeniden çalıştır; mesela mevcut kuruluma `--tunnel quick` ekleyebilirsin. Yeniden vermediğin ayarlar olduğu gibi kalıyor.

| Parametre (sh / ps1) | Ne işe yarıyor |
|---|---|
| `--dir` / `-Dir` | Dosyaların ineceği klasör. Varsayılan `~/Pictures/Yolla`. |
| `--token` / `-Token` | Erişim şifresi. Vermezsen otomatik üretiliyor. `--no-token` / `-NoToken` şifreyi tamamen kapatıyor (lütfen yalnızca yerel ağda). |
| `--port` / `-Port` | Bu bilgisayarda dinlenecek port. Varsayılan `8080`. |
| `--tunnel` / `-Tunnel` | `quick`, `cloudflare` (`--cf-token` ile), `ngrok` (`--ngrok-token` ile, istersen `--ngrok-domain`) ya da `none`. |
| `--group-by-date` / `-GroupByDate` | Fotoğrafları çekim tarihine göre `YYYY/YYYY-AA/` klasörlerine dağıt. |
| `--max-mb` / `-MaxMb` | Bundan büyük dosyaları kabul etme. Varsayılan 0, yani sınır yok. |
| `--no-outbox` / `-NoOutbox` | Al sekmesini kapat; telefondan hiçbir şey okunamasın. |
| `--update`, `--status`, `--uninstall` / `-Update`, `-Status`, `-Uninstall` | Güncelleme, durum, kaldırma. Kaldırma dosyalarına dokunmuyor. |

Betik, `~/.yolla/` klasörüne (Windows'ta `%LOCALAPPDATA%\Yolla\`) bir `.env` ve bir `docker-compose.yml` yazıyor. İstersen bunları elle düzenleyip `--update` ile uygulayabilirsin.

### Elle kurulum

```bash
docker run -d --name yolla --restart unless-stopped -p 8080:8080 \
  -v "/klasor/yolu:/data" -e UPLOAD_TOKEN=gizli \
  ghcr.io/tekyaygilfethi/yolla:latest
```

Windows'ta klasör yolunu `/` ile yaz: `-v "C:/Users/sen/Pictures/Yolla:/data"`. Konteyner 1000 numaralı kullanıcıyla çalışıyor; Linux'ta klasör başka bir kullanıcıya aitse komuta `--user "$(id -u):$(id -g)"` ekle. Compose kullanacaksan: `git clone`, ardından `cp .env.example .env`, dosyayı düzenle, `docker compose up -d`. Docker'ın hiç yoksa [.NET 10 SDK](https://dotnet.microsoft.com/download) ile de çalışıyor: `cd src/Yolla && UPLOAD_DIR=/yol UPLOAD_TOKEN=gizli dotnet run -c Release`.

## Kullanım

1. Bilgisayarda <http://localhost:8080> adresini aç. Aynı Wi‑Fi'daki telefondan `http://<bilgisayarın-ip'si>:8080` ile gir (betik bu adresi ekrana yazıyor). Arada tünel olmadığı için en hızlı yol bu.
2. İlk girişte şifre soruyor ve o cihazda hatırlıyor. Sonradan başka bir şifre girmek istersen klasör bilgisinin yanındaki *şifreyi değiştir* bağlantısına bas.
3. **Fotoğraf & Video**, telefonun fotoğraf seçicisini açıyor. Seçtiğin an yükleme başlıyor. **Herhangi bir dosya** ise dosya tarayıcısını açıyor: belgeler, ZIP'ler ve iPhone'da videoların orijinalleri için (aşağıya bak).
4. **Alt klasör** kutusu isteğe bağlı; `Tatil2026` yazarsan o yükleme aynı adlı bir alt klasöre gidiyor.
5. Ekranda **Tamamlandı** yazana kadar sayfayı kapatma. Yazmadan koptuysa aynı dosyaları yeniden seç; kaldığı yerden devam ediyor.
6. **Al**: bilgisayarda dosyaları Yolla klasörünün içindeki `Outbox` klasörüne at. Telefonda Al sekmesini aç, istediklerine dokun, sonra *İndir* (tek dosya ya da birkaçı için ZIP) ya da iPhone'da *Fotoğraflara Kaydet*.

## Her yerden erişim

Yolla, 8080 portunda çalışan sıradan bir HTTP sunucusu. Ona HTTP trafiği iletebilen her şeyin arkasına koyabilirsin. Seçenekler:

**Cloudflare Tunnel**, benim tavsiyem. Ücretsiz, trafik sınırı yok, HTTPS hazır geliyor, modemde port açmak gerekmiyor, CGNAT arkasında bile çalışıyor.

- Hızlı tünel, hesap gerekmez: betikte `--tunnel quick`, ya da `docker compose --profile quick up -d`, ya da bilgisayarda cloudflared kuruluysa `cloudflared tunnel --url http://localhost:8080`. Sana her yeniden başlatmada değişen rastgele bir `https://….trycloudflare.com` adresi veriyor. "Fotoğrafları şimdi at" durumları için birebir.
- Kalıcı tünel, kendi alan adınla: [Zero Trust panelinde](https://one.dash.cloudflare.com) **Networks → Tunnels → Create a tunnel → Cloudflared** yolunu izle, **Docker**'ı seç ve token'ı kopyala. Betiği `--tunnel cloudflare --cf-token <token>` ile çalıştır (ya da token'ı `.env`'e yazıp `cloudflare` profilini kullan). Panele dönüp bir **Public Hostname** ekle: subdomain `yolla`, alan adın, servis türü **HTTP**, URL `yolla:8080`. Artık telefondan `https://yolla.alanadin.com` adresine giriyorsun. Önüne gerçek bir giriş ekranı istersen **Cloudflare Access** ekle (Access → Applications → Self-hosted, e-postaya gelen tek kullanımlık kodla giriş); ücretsiz plan 50 kullanıcıya kadar yetiyor.

**ngrok**, deneme için adres almanın en hızlı yolu. Hesap aç, `ngrok config add-authtoken <token>` komutunu bir kez çalıştır, sonra `ngrok http 8080`. Ya da betikte `--tunnel ngrok --ngrok-token <token>` de; adresi <http://localhost:4040>'ta görürsün. ngrok panelinden ücretsiz sabit alan adını alıp `--ngrok-domain isim.ngrok-free.app` verirsen adres hep aynı kalıyor. İlk girişte ngrok'un ara sayfası çıkıyor; bir kez **Visit Site**'a basman yeterli. Yolla, API isteklerine o sayfayı atlatan başlığı ekliyor, yüklemeler bundan etkilenmiyor.

**Kendi reverse proxy'n** (Caddy, nginx, Traefik, NPM) ya da **Tailscale** kullanacaksan [docs/reverse-proxy.md](docs/reverse-proxy.md) dosyasına bak. Dikkat edilecek iki ayar var: istek gövdesi sınırını büyüt, istek tamponlamayı kapat.

## Bilmekte fayda var

- **iPhone'da Fotoğraflar'dan seçilen videoların kalitesi düşüyor.** Safari bu videoları yeniden kodluyor: HEVC yerine daha düşük bitrate'li H.264. 4K/60 çekimlerde fark gözle görülüyor; ses kanalının kaybolduğunu bildirenler bile var. Bunu hiçbir web sayfası engelleyemiyor, iOS'un kendi davranışı. Orijinali istiyorsan videoyu önce Dosyalar'a kaydet, sonra **Herhangi bir dosya → Dosyalar** ile seç; ya da [docs/ios-originals.md](docs/ios-originals.md) dosyasındaki kısa Kısayol'u kur, o yolla fotoğrafların orijinal HEIC'leri de geliyor. Fotoğraflar'dan seçilen fotoğraflara gelince: HEIC'ten çevrilmiş tam çözünürlüklü JPEG olarak geliyorlar, çoğu kişi için sorun değil.
- **ngrok'un ücretsiz planı ayda 1 GB civarında trafik veriyor.** Bir tatil albümü buna denk. Büyük yüklemeler için Cloudflare ya da yerel ağ kullan.
- **Cloudflare, ücretsiz planlarda istek başına 100 MB kabul ediyor.** Yüklemelerin parçalı olmasının sebebi bu; `CHUNK_MB` değerini 100'ün altında tut.
- **Ekran açık kalsın.** HTTPS üzerindeyken Yolla iOS'tan ekranı açık tutmasını istiyor. Düz `http://` yerel ağ adreslerinde bunu yapamıyor; otomatik kilidi kendin kapat. Yüzlerce öğe seçtiğinde yükleme başlamadan önce biraz beklemen normal, iOS dosyaları hazırlıyor.
- **Şifre koy.** Evden hiç çıkarmayacak olsan bile.
- **Windows güvenlik duvarı:** telefon `http://<pc-ip>:8080` adresine ulaşamıyorsa Docker Desktop için TCP 8080 portuna izin ver.
- **Linux'ta izinler:** konteyner uid 1000 ile çalışıyor. Betik `PUID`/`PGID` değerlerini senin kullanıcına göre ayarlıyor; `docker run` kullanıyorsan `--user` ekle.

## Ayarlar

Tüm ayarlar ortam değişkeni. Betik bunları senin için `.env` dosyasına yazıyor.

| Değişken | Varsayılan | Anlamı |
|---|---|---|
| `UPLOAD_DIR` | Docker'da `/data`, `dotnet run`'da `./uploads` | Dosyaların yazıldığı klasör. |
| `UPLOAD_TOKEN` | boş = şifre yok | Ortak şifre. `X-Upload-Token` başlığıyla ya da `?token=` ile gönderiliyor. |
| `GROUP_BY_DATE` | `false` | `true` yapınca dosyalar çekim tarihine göre `2026/2026-09/` gibi klasörlere gidiyor. |
| `CHUNK_MB` | `32` | Yükleme parçalarının boyutu. |
| `MAX_UPLOAD_MB` | `0` (sınırsız) | Bundan büyük dosyaları reddet. |
| `SHARE_DIR` | `<UPLOAD_DIR>/Outbox` | Telefonun okuyabildiği tek klasör (Al sekmesi). `off` yazarsan kapanıyor. |
| `ASPNETCORE_HTTP_PORTS` | `8080` | Konteynerin içindeki port. |

Compose kullanıyorsan ek olarak `YOLLA_DIR`, `YOLLA_PORT`, `YOLLA_BIND` (yerel proxy arkasında `127.0.0.1`), `YOLLA_IMAGE`, `PUID`/`PGID` ve `COMPOSE_PROFILES=quick|cloudflare|ngrok` de var; [.env.example](.env.example) dosyasına bak.

## Nasıl çalışıyor?

Sayfa her dosyadan önce `GET /api/exists` ile sunucuya soruyor: bu dosya zaten var mı (varsa atla), yarım mı kalmış (kaldığı bayttan devam et)? Sonra dosyayı `PUT /api/upload` ile parça parça gönderiyor; her parça ham istek gövdesi olarak `.part` dosyasının sonuna ekleniyor. Son parça geldiğinde dosya asıl adına taşınıyor ve tarihi geri yazılıyor. Hiçbir şey bellekte tutulmuyor; dosya ne kadar büyük olursa olsun bellek kullanımı değişmiyor. Al sekmesi yalnızca Outbox klasörünü okuyor: `GET /api/outbox` listeliyor, `/api/outbox/file` tek dosyayı veriyor (aralık istekleri desteklendiği için video ileri sarılabiliyor), `/api/outbox/zip` birkaç dosyayı ZIP olarak akıtıyor. API'nin tamamı, tek satırlık `curl -T` örneğiyle birlikte [docs/api.md](docs/api.md) dosyasında.

`tests/smoke.sh` uçtan uca bir test: uygulamayı derleyip başlatıyor ve her endpoint'i tek tek deniyor (parçalama, devam etme, kopya tespiti, boyut sınırı, hatalı şifre freni). CI'da her push'ta çalışıyor.

## Yol haritası

- [ ] Al sekmesinde küçük resimler
- [ ] Aileye erişim vermek için QR kod ya da davet bağlantısı
- [ ] İsteğe bağlı olarak sunucuda HEIC → JPEG dönüşümü
- [ ] Birden fazla şifre, kişi başına ayrı alt klasör
- [ ] Docker gerektirmeyen tek exe'lik Windows uygulaması

## Katkı, güvenlik, lisans

Hata bildirimleri ve küçük, bağımlılık eklemeyen PR'lar başım üstüne; ayrıntılar [CONTRIBUTING.md](CONTRIBUTING.md) dosyasında. Güvenlik notları ve bir açığı nasıl bildireceğin [SECURITY.md](SECURITY.md) dosyasında. Lisans [MIT](LICENSE).

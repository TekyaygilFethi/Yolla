<p align="center"><img src="src/Yolla/wwwroot/icon-192.png" width="88" alt=""></p>
<h1 align="center">Yolla</h1>
<p align="center">Kendi bilgisayarınızda veya sunucunuzda hafif bir dosya aktarım aracı.<br>Açık kaynak. Tarayıcıdan erişim. Kontrolünüzde depolama.</p>

<p align="center">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/lisans-MIT-blue.svg"></a>
  <img alt=".NET 10" src="https://img.shields.io/badge/.NET-10-512BD4">
  <img alt="Docker amd64 | arm64" src="https://img.shields.io/badge/docker-amd64%20%7C%20arm64-2496ED">
  <a href="README.md"><img alt="English" src="https://img.shields.io/badge/README-English-blue"></a>
</p>

<p align="center"><img src="docs/demo.gif" width="300" alt="iPhone'da Yolla: 13 fotoğraf seçiliyor, bilgisayardaki klasöre iniyor">&nbsp;&nbsp;<img src="docs/receive-dark.png" width="300" alt="Koyu temada Al sekmesi"></p>

## Yolla nedir?

Yolla, kendi bilgisayarınızda veya sunucunuzda çalıştırabileceğiniz hafif, açık kaynak bir dosya aktarım aracıdır. Tarayıcıdan adresini açarak fotoğraf, video ve diğer dosyaları seçtiğiniz klasöre gönderebilirsiniz. Ters yönde aktarım için sunucudaki `Outbox` klasörüne dosya koymanız yeterlidir; başka bir cihazdan **Al** sekmesini açıp indirebilirsiniz.

iPhone, Android telefon, tablet veya bilgisayardaki fotoğraf, video ve diğer dosyalar sade bir web sayfası üzerinden aktarılabilir. Gönderen cihazda yalnızca bir tarayıcı ve Yolla adresine erişim gerekir. Sunucu tarafı Windows, macOS veya Linux'ta; uyumlu NAS ve Raspberry Pi kurulumlarında çalıştırılabilir.

Yolla, kapsamı bilinçli olarak dar tutulmuş küçük bir kişisel araçtır. Amacı büyük depolama platformlarıyla yarışmak veya sundukları bütün özelliklerin yerini almak değildir. Kendi altyapınızda dosya aktarımı yapabileceğiniz, kodunu inceleyip ihtiyacınıza göre uyarlayabileceğiniz hafif bir yapı sunar.

## Neden Yolla?

- **Dosyaların nerede duracağını siz seçersiniz.** Yüklemeler bilgisayarınızda veya sunucunuzda normal bir klasöre kaydedilir. Diski ve klasörü siz belirler, dosyaları alıştığınız araçlarla açarsınız.
- **Gönderen cihazda tarayıcı yeterlidir.** Telefona uygulama kurmak veya Yolla hesabı açmak gerekmez. Sunucuyu bir kez kurduktan sonra adresine girip erişim şifrenizi kullanırsınız.
- **İhtiyacınıza göre ayarlarsınız.** Ortak erişim şifresini, dosya boyutu sınırını ve yükleme alt klasörlerini belirleyebilirsiniz. İndirmeye açık klasörü seçebilir veya indirmeleri tamamen kapatabilirsiniz.
- **İki yönde aktarım yaparsınız.** Yolla adresine ulaşabilen ve erişim şifresiyle giriş yapabilen cihazlar dosya yükleyebilir, `Outbox` klasörüne koyduğunuz dosyaları indirebilir.
- **Ev dışından da erişebilirsiniz.** Bir tünel veya kendi HTTPS reverse proxy'nizle dışarıdan erişimi yapılandırabilirsiniz. Sunucunun açık, disk alanının yeterli ve adresin gönderen cihazdan erişilebilir olması gerekir.
- **Elinizdeki depolama alanını kullanırsınız.** Örneğin tatil fotoğraflarını ek bir bulut depolama aboneliği almadan kendi diskinize aktarabilirsiniz. Depolama, bağlantı ve varsa sunucu ya da tünel hizmetinin maliyeti seçtiğiniz kuruluma bağlıdır.
- **Kurulum küçük kalır.** Uygulamanın işleyişi bir C# dosyası ile bir HTML dosyasında yer alır. Üçüncü taraf NuGet veya JavaScript paketi ve ayrı bir veritabanı gerektirmez. Belgelenen kurulum Docker kullanır; .NET 10 ile de çalıştırabilirsiniz. Web sayfasında üçüncü taraf script veya analiz aracı bulunmaz.
- **Kodu inceleyip değiştirebilirsiniz.** Yolla, MIT lisansıyla ücretsiz ve açık kaynak olarak sunulur. Kodu okuyabilir, kendi ihtiyacınıza göre uyarlayabilir veya katkıda bulunabilirsiniz.

## Hangi ihtiyaçlara uygun?

Yolla, dosyaları kendi makinenize göndermek ve seçtiğiniz dosyaları tarayıcı üzerinden indirilebilir hâle getirmek istediğinizde kullanışlıdır. Seyahatteyken evdeki sunucunuza fotoğraf gönderebilir, farklı cihazlarınızdaki dosyaları tek klasörde toplayabilir veya telefona indireceğiniz bir belgeyi `Outbox` klasörüne koyabilirsiniz.

Aktarımları siz başlatırsınız. Otomatik arka plan yedeklemesi, senkronize fotoğraf arşivi, yedekli depolama veya ayrı kullanıcı hesapları sunmaz. Bu özelliklere ihtiyaç duyuyorsanız kapsamlı bir depolama ya da yedekleme hizmeti daha uygun olabilir. Yolla telefonda otomatik yer açmaz: yerel kopyaları silmeden önce aktarılan dosyaları kontrol edin ve önemli dosyaların ayrıca yedeğini tutun.

## Neler yapar?

- Tarayıcının ilettiği dosyayı fotoğraf veya video sıkıştırması uygulamadan aktarır. Cihaz, yükleme öncesinde medyayı dönüştürebilir; aşağıdaki iPhone notuna bakın.
- Aynı anda üç dosya yükler, hata olursa yeniden dener; ilerlemeyi, hızı ve kalan süreyi gösterir.
- Her dosyayı 32 MB'lık parçalar hâlinde doğrudan diske yazar. Bağlantı koparsa en fazla bir parça kaybedersiniz; aynı dosyaları yeniden seçtiğinizde kaldığı bayttan devam eder.
- Mevcut dosyaların üzerine yazmaz. Tarayıcı, adı ve boyutu mevcut bir yüklemeyle eşleşen dosyayı atlar; bu bir içerik karşılaştırması değildir. Diğer ad çakışmalarında `IMG_0001 (1).JPG` gibi bir ek kullanılır.
- Dosya sistemi desteklediğinde tarayıcının ilettiği son değiştirilme tarihini korur. İsteğe bağlı `YYYY/YYYY-AA/` alt klasörleri bu tarihe göre oluşturulur; uygulama EXIF içinden çekim tarihi okumaz.
- **Al** sekmesi: bilgisayarda `Outbox` klasörüne koyduğunuz dosyalar telefonda listelenir. Tek dosyayı indirebilir, birkaçını seçip ZIP olarak alabilir, iPhone'da *Fotoğraflara Kaydet* ile doğrudan galeriye aktarabilirsiniz.
- Tarayıcı üzerinden kullanılır. Bilgisayarda sürükle-bırak ve yapıştırma desteklenir. İkinci düğme fotoğraf dışındaki dosyaları da kabul eder. Açık ve koyu tema, Türkçe ve İngilizce arayüz. iPhone'da *Ana Ekrana Ekle* dendiğinde bir uygulama simgesi gibi görünür.
- İsteğe bağlı erişim şifresi, dosya boyutu sınırı ve her aktarım için ayrı alt klasör.
- Cloudflare Tunnel, ngrok, kendi reverse proxy'niz (alt yol altında bile) ya da düz yerel ağ; hepsinin arkasında çalışır. Parçalar Cloudflare'in istek başına 100 MB sınırının altında kalır.

## Kurulum

### Önce karar verilecek üç şey

Kurulum scripti Yolla ayarları için varsayılan değerleri kullanır. Docker eksikse kurulumu için onay isteyebilir. Bir ayarı sonradan değiştirmek isterseniz scripti yeniden çalıştırabilirsiniz. Yine de neleri ayarladığını bilmekte fayda var:

1. **Klasör.** Yüklenen dosyaların bu bilgisayarda gideceği yer. Varsayılan olarak ev klasörünüzün içindeki `Pictures/Yolla`. Herhangi bir klasör olabilir; yoksa script oluşturur.
2. **Erişim şifresi.** Bir paroladır. Telefon bunu bir kez sorar, sonra hatırlar. Şifre koymazsanız adresi bulan herkes diskinize dosya atabilir; bu yüzden Yolla'yı evden dışarı hiç açmayacak olsanız bile bir şifre koyun. Siz belirlemezseniz script rastgele bir şifre üretip ekrana yazar.
3. **Tünel.** Yalnızca Yolla'ya kendi Wi‑Fi ağınızın dışından erişmek istiyorsanız gerekir. `quick`, hesap açmadan rastgele bir Cloudflare adresi verir (her yeniden başlatmada değişir). `cloudflare` (kendi alan adınızda kalıcı adres) ve `ngrok` ise ilgili servisten alınan bir token ister; ayrıntılar [Her yerden erişim](#her-yerden-erişim) bölümünde. Evde deneme yaparken bu adımı atlayabilirsiniz.

Docker gerekir: Windows ve macOS'ta [Docker Desktop](https://docker.com/products/docker-desktop). Linux'ta script Docker'ı sizin adınıza kurmayı teklif eder; onaylamanız yeterlidir.

### Tek satırla kurulum

Varsayılan ayarlarla: klasör `Pictures/Yolla`, şifre otomatik üretilir, tünel yok.

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1 | iex
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash
```

Script Docker'ın kurulu olup olmadığını kontrol eder, ayar dosyasını yazar, imajı indirir, Yolla'yı başlatır ve sonunda üç bilgiyi ekrana yazar: bu bilgisayardaki adres, Wi‑Fi ağındaki adres ve şifre.

İnternetten indirilen bir scripti doğrudan çalıştırmak istemiyorsanız haklısınız. Önce indirin, okuyun (yaklaşık 200 satır), sonra çalıştırın:

```bash
curl -fsSLO https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh && less install.sh && bash install.sh
```

### Parametreyle kurulum

Aynı komutlar, ama üç ayarı kendiniz veriyorsunuz. Aşağıdaki örnekte `D:` sürücüsünde bir klasör, kendi şifreniz ve hemen her yerden erişilebilmesi için hızlı tünel var:

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.ps1))) -Dir "D:\Fotolar\Yolla" -Token "gizli" -Tunnel quick
```
```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/TekyaygilFethi/yolla/main/scripts/install.sh | bash -s -- --dir ~/Pictures/Yolla --token gizli --tunnel quick
```

Sonradan fikriniz değişirse scripti başka parametrelerle yeniden çalıştırın; örneğin mevcut kuruluma `--tunnel quick` ekleyebilirsiniz. Yeniden vermediğiniz ayarlar olduğu gibi kalır.

| Parametre (sh / ps1) | Açıklama |
|---|---|
| `--dir` / `-Dir` | Dosyaların ineceği klasör. Varsayılan `~/Pictures/Yolla`. |
| `--token` / `-Token` | Erişim şifresi. Verilmezse otomatik üretilir. `--no-token` / `-NoToken` şifreyi tamamen kapatır (yalnızca yerel ağda kullanın). |
| `--port` / `-Port` | Bu bilgisayarda dinlenecek port. Varsayılan `8080`. |
| `--tunnel` / `-Tunnel` | `quick`, `cloudflare` (`--cf-token` ile), `ngrok` (`--ngrok-token` ile, isteğe bağlı `--ngrok-domain`) ya da `none`. |
| `--group-by-date` / `-GroupByDate` | Fotoğrafları çekim tarihine göre `YYYY/YYYY-AA/` klasörlerine dağıtır. |
| `--max-mb` / `-MaxMb` | Bundan büyük dosyaları reddeder. Varsayılan 0, yani sınırsız. |
| `--no-outbox` / `-NoOutbox` | Al sekmesini kapatır; telefondan hiçbir şey okunamaz. |
| `--update`, `--status`, `--uninstall` / `-Update`, `-Status`, `-Uninstall` | Güncelleme, durum görüntüleme, kaldırma. Kaldırma işlemi dosyalarınıza dokunmaz. |

Script, `~/.yolla/` klasörüne (Windows'ta `%LOCALAPPDATA%\Yolla\`) bir `.env` ve bir `docker-compose.yml` dosyası yazar. Bunları elle düzenleyip `--update` ile uygulayabilirsiniz.

### Elle kurulum

```bash
docker run -d --name yolla --restart unless-stopped -p 8080:8080 \
  -v "/klasor/yolu:/data" -e UPLOAD_TOKEN=gizli \
  ghcr.io/tekyaygilfethi/yolla:latest
```

Windows'ta klasör yolunu `/` ile yazın: `-v "C:/Users/siz/Pictures/Yolla:/data"`. Konteyner 1000 numaralı kullanıcıyla çalışır; Linux'ta klasör başka bir kullanıcıya aitse komuta `--user "$(id -u):$(id -g)"` ekleyin. Compose kullanacaksanız: `git clone`, ardından `cp .env.example .env`, dosyayı düzenleyin ve `docker compose up -d`. Docker yoksa [.NET 10 SDK](https://dotnet.microsoft.com/download) ile de çalışır: `cd src/Yolla && UPLOAD_DIR=/yol UPLOAD_TOKEN=gizli dotnet run -c Release`.

## Kullanım

1. Bilgisayarda <http://localhost:8080> adresini açın. Aynı Wi‑Fi ağındaki telefondan `http://<bilgisayarın-ip-adresi>:8080` ile bağlanın (script bu adresi ekrana yazar). Arada tünel olmadığı için en hızlı yol budur.
2. İlk girişte şifre sorulur ve o cihazda hatırlanır. Daha sonra başka bir şifre girmek isterseniz klasör bilgisinin yanındaki *şifreyi değiştir* bağlantısını kullanın.
3. **Fotoğraf & Video** düğmesi telefonun fotoğraf seçicisini açar; seçtiğiniz anda yükleme başlar. **Herhangi bir dosya** düğmesi ise dosya tarayıcısını açar: belgeler, ZIP dosyaları ve iPhone'da videoların orijinalleri için (aşağıya bakın).
4. **Alt klasör** kutusu isteğe bağlıdır; `Tatil2026` yazarsanız o aktarım aynı adlı bir alt klasöre gider.
5. Ekranda **Tamamlandı** yazana kadar sayfayı kapatmayın. Bağlantı koparsa aynı dosyaları yeniden seçin; kaldığı yerden devam eder.
6. **Al**: bilgisayarda dosyaları Yolla klasörünün içindeki `Outbox` klasörüne koyun. Telefonda Al sekmesini açın, istediklerinize dokunun, ardından *İndir* (tek dosya ya da birkaçı için ZIP) ya da iPhone'da *Fotoğraflara Kaydet* deyin.

## Her yerden erişim

Yolla, 8080 portunda çalışan sıradan bir HTTP sunucusudur; HTTP trafiği iletebilen her şeyin arkasına koyulabilir. Seçenekler:

**Cloudflare Tunnel** ile modemde port açmadan HTTPS erişimi sağlanabilir. CGNAT arkasındaki kurulumlarda da kullanılabilir.

- Hızlı tünel, hesap gerekmez: scriptte `--tunnel quick`, ya da `docker compose --profile quick up -d`, ya da bilgisayarda cloudflared kuruluysa `cloudflared tunnel --url http://localhost:8080`. Her yeniden başlatmada değişen rastgele bir `https://….trycloudflare.com` adresi oluşturulur. Geçici aktarımlar için kullanılabilir.
- Kalıcı tünel, kendi alan adınızla: [Zero Trust panelinde](https://one.dash.cloudflare.com) **Networks → Tunnels → Create a tunnel → Cloudflared** yolunu izleyin, **Docker** seçeneğini seçip token'ı kopyalayın. Scripti `--tunnel cloudflare --cf-token <token>` ile çalıştırın (ya da token'ı `.env` dosyasına yazıp `cloudflare` profilini kullanın). Panele dönüp bir **Public Hostname** ekleyin: subdomain `yolla`, alan adınız, servis türü **HTTP**, URL `yolla:8080`. Artık telefondan `https://yolla.alanadiniz.com` adresine bağlanabilirsiniz. Önüne gerçek bir giriş ekranı istiyorsanız **Cloudflare Access** ekleyin (Access → Applications → Self-hosted, e-postaya gelen tek kullanımlık kodla giriş); ücretsiz plan 50 kullanıcıya kadar yeterlidir.

**ngrok**, deneme için adres almanın en hızlı yolu. Hesap açın, `ngrok config add-authtoken <token>` komutunu bir kez çalıştırın, ardından `ngrok http 8080`. Ya da scriptte `--tunnel ngrok --ngrok-token <token>` verin; adresi <http://localhost:4040> üzerinden görebilirsiniz. ngrok panelinden ücretsiz sabit alan adını alıp `--ngrok-domain isim.ngrok-free.app` verirseniz adres hep aynı kalır. İlk girişte ngrok'un ara sayfası çıkar; bir kez **Visit Site** düğmesine basmanız yeterlidir. Yolla, API isteklerine bu sayfayı atlatan başlığı eklediği için yüklemeler etkilenmez.

**Kendi reverse proxy'niz** (Caddy, nginx, Traefik, NPM) ya da **Tailscale** için [docs/reverse-proxy.md](docs/reverse-proxy.md) dosyasına bakın. Dikkat edilecek iki ayar var: istek gövdesi sınırını büyütün, istek tamponlamayı kapatın.

## Bilmekte fayda var

- **iPhone'da Fotoğraflar'dan seçilen videoların kalitesi düşer.** Safari bu videoları yeniden kodlar: HEVC yerine daha düşük bitrate'li H.264. 4K/60 çekimlerde fark gözle görülür; ses kanalının kaybolduğunu bildiren kullanıcılar da var. Bunu hiçbir web sayfası engelleyemez, iOS'un kendi davranışıdır. Orijinali istiyorsanız videoyu önce Dosyalar'a kaydedin, sonra **Herhangi bir dosya → Dosyalar** ile seçin; ya da [docs/ios-originals.md](docs/ios-originals.md) dosyasındaki kısa Kısayol'u kurun, bu yolla fotoğrafların orijinal HEIC dosyaları da gelir. Fotoğraflar'dan seçilen fotoğraflar ise HEIC'ten dönüştürülmüş tam çözünürlüklü JPEG olarak gelir; çoğu kullanım için yeterlidir.
- **ngrok'un ücretsiz planı ayda yaklaşık 1 GB trafik verir.** Bu, bir tatil albümüne denk gelir. Büyük aktarımlar için Cloudflare ya da yerel ağı kullanın.
- **Cloudflare, ücretsiz planlarda istek başına 100 MB kabul eder.** Yüklemelerin parçalı olmasının nedeni budur; `CHUNK_MB` değerini 100'ün altında tutun.
- **Ekran açık kalmalı.** HTTPS üzerinden bağlandığınızda Yolla iOS'tan ekranı açık tutmasını ister. Düz `http://` yerel ağ adreslerinde bunu yapamaz; otomatik kilidi kendiniz kapatın. Yüzlerce öğe seçtiğinizde yükleme başlamadan önce kısa bir bekleme olması normaldir, iOS dosyaları hazırlar.
- **Şifre koyun.** Evden dışarı hiç açmayacak olsanız bile.
- **Windows güvenlik duvarı:** telefon `http://<pc-ip>:8080` adresine ulaşamıyorsa Docker Desktop için TCP 8080 portuna izin verin.
- **Linux'ta izinler:** konteyner uid 1000 ile çalışır. Script `PUID`/`PGID` değerlerini kullanıcınıza göre ayarlar; `docker run` kullanıyorsanız `--user` ekleyin.

## Ayarlar

Tüm ayarlar ortam değişkenidir. Script bunları sizin için `.env` dosyasına yazar.

| Değişken | Varsayılan | Açıklama |
|---|---|---|
| `UPLOAD_DIR` | Docker'da `/data`, `dotnet run` ile `./uploads` | Dosyaların yazıldığı klasör. |
| `UPLOAD_TOKEN` | boş = şifre yok | Ortak şifre. `X-Upload-Token` başlığıyla ya da `?token=` parametresiyle gönderilir. |
| `GROUP_BY_DATE` | `false` | `true` olduğunda dosyalar çekim tarihine göre `2026/2026-09/` gibi klasörlere gider. |
| `CHUNK_MB` | `32` | Yükleme parçalarının boyutu. |
| `MAX_UPLOAD_MB` | `0` (sınırsız) | Bundan büyük dosyaları reddeder. |
| `SHARE_DIR` | `<UPLOAD_DIR>/Outbox` | Telefonun okuyabildiği tek klasör (Al sekmesi). `off` verilirse kapanır. |
| `ASPNETCORE_HTTP_PORTS` | `8080` | Konteynerin içindeki port. |

Compose kullanıyorsanız ek olarak `YOLLA_DIR`, `YOLLA_PORT`, `YOLLA_BIND` (yerel proxy arkasında `127.0.0.1`), `YOLLA_IMAGE`, `PUID`/`PGID` ve `COMPOSE_PROFILES=quick|cloudflare|ngrok` değişkenleri de vardır; [.env.example](.env.example) dosyasına bakın.

## Nasıl çalışır?

Sayfa, her dosyadan önce `GET /api/exists` ile sunucuya sorar: bu dosya zaten var mı (varsa atlanır), yarım mı kalmış (kaldığı bayttan devam edilir)? Ardından dosyayı `PUT /api/upload` ile parça parça gönderir; her parça ham istek gövdesi olarak `.part` dosyasının sonuna eklenir. Son parça geldiğinde dosya asıl adına taşınır ve tarihi geri yazılır. Yüklemeler dosyanın tamamını belleğe almak yerine sabit boyutlu bir tampon üzerinden diske yazılır. Al sekmesi yalnızca Outbox klasörünü okur: `GET /api/outbox` listeler, `/api/outbox/file` tek dosyayı verir (aralık istekleri desteklendiği için video ileri sarılabilir), `/api/outbox/zip` birkaç dosyayı ZIP olarak akıtır. API'nin tamamı, tek satırlık `curl -T` örneğiyle birlikte [docs/api.md](docs/api.md) dosyasındadır.

`tests/smoke.sh` uçtan uca bir testtir: uygulamayı derleyip başlatır ve her endpoint'i tek tek dener (parçalama, devam etme, kopya tespiti, boyut sınırı, hatalı şifre freni). CI'da her push'ta çalışır.

## Yol haritası

- [ ] Al sekmesinde küçük resimler
- [ ] Aileye erişim vermek için QR kod ya da davet bağlantısı
- [ ] İsteğe bağlı olarak sunucu tarafında HEIC → JPEG dönüşümü
- [ ] Birden fazla şifre, kişi başına ayrı alt klasör
- [ ] Docker gerektirmeyen, tek exe'den oluşan Windows uygulaması

## Katkı, güvenlik, lisans

Hata bildirimleri ve bağımlılık eklemeyen küçük PR'lar memnuniyetle karşılanır; ayrıntılar [CONTRIBUTING.md](CONTRIBUTING.md) dosyasında. Güvenlik notları ve bir açığı nasıl bildireceğiniz [SECURITY.md](SECURITY.md) dosyasında. Lisans: [MIT](LICENSE).

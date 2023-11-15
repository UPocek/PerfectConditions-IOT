# Projektna specifikacija PerfectConditions-IoT

## Uvod
Namena sistema PerfectConditions IoT je da kućnim biljkama obezbedi idealne uslove. Naš sistem se sastoji od hardverski IoT uređaja i softverskog sistema za nadzor i upravljanje.

Prvi deo procesa je prpoznavanje kućne biljke na osnovu slike (projekat iz predmeta SoftComputing) pošto budimo iskreni niko ne zna kako se zove biljka koju ti je tetka kupila za rođendan.
Nakon što smo prepoznali sortu biljke znamo i koji su idealni uslovi potrebni baš za tu biljku. Naš IoT sistem ima zadatak da prati različite metrike, njih prikazuje vlasniku i da mu ukaže na savete kako da obezbedi idalne uslove za svoju mezimicu.

## Uredjaji
- RaspberryPi4
- Arduino Uno
- ESP32

## Senzori i namene
- Detektor vlažnosti zemljišta -> Kako bi vlasnik znao kada i koliko tačno da zaliva svoju bilju
- Senzor intenziteta svetlosti -> Kako neke biljke preferiraju više, odnosno manje svetla, ova funkcionalnost pomaže vlasniku da pronađe idealno mesto u domu za svoju bilju
- Senzor temperature i vlažnosti vazduha -> Postavite vašu bilju na previše hladno ili previše toplo mesto i ☠️(gecrk) zato naš sistem daje vlasniku uvid kada se spoljašnji uslovi promene da je potrebno da premesti biljku na toplije/hladnije mesto
- Barometar -> Česte promene u pritisku mogu da poremeti mir i spokoj biljke zato naš sistem obaveštava vlasnika ukoliko dođe do bilo kakvog poremeđaja
- Zvučnik -> Opšte je poznato da biljke vole muziku, mada je retko da iko ima vremena da svaki dan priča i peva svojoj biljci zato naš sistem radi i to. Sa specijlanom opcijom uspavanka za "Twinkle, Twinkle, Little Plant"

## Arhitektura sistema
Logika aplikacije i mesto gde pristižu sva očitavanja će biti iskucana u Java Spring Boot radnom okviru, dok će se perzistencija podataka vršiti u TimeSeries bazi podataka InfluxDB. Nakon što mikrokontroler u predefinisanom trenutku očita trenutne vrednosti svojih senzora šalje ih putem MQTT protokola na SBC RaspberryPI koji sakuplja te podatke i prosleđuje ih na back gde se vrši čuvanje podataka i najnovije vrednosti se prikazuju korisniku putem IOS ili Android mobilne aplikacije. Mobilna aplikacija će biti iskucana u Flutter radnom okviru, Dart programski jezik.

Povezivanje uređaja će biti odrađeno na sledeći način: RaspberryPI će biti centralni uređaj sistema i uređaj koji će vršiti pametnu komunikaciju sa aplikativnim serverom preko interneta. Detektor vlažnosti zemljišta, Senzor intenziteta svetlosti, Senzor temperature i vlažnosti vazduha, Barometar i Zvučnik će biti povezani na ESP32 i Arduino koji će preko MQTT protokola slati očitavanja na RaspberryPI u istoj lokalnoj mreži.

## Tim
- [Tamara Ilić](https://www.linkedin.com/in/tamara-ili%C4%87-ab9958257/)
- [Uroš Poček](https://www.linkedin.com/in/uros-pocek/)

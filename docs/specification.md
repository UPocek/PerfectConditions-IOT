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
- Senzor svetlosti -> Kako neke biljke preferiraju više, odnosno manje svetla, ova funkcionalnost pomaže vlasniku da pronađe idealno mesto u domu za svoju bilju
- Senzor temperature -> Postavite vašu bilju na previše hladno ili previše toplo mesto i ☠️(gecrk) zato naš sistem daje vlasniku uvid kada se spoljašnji uslovi promene da je potrebno da premesti biljku na toplije/hladnije mesto
- Senzor pritiska -> Česte promene u pritisku mogu da poremeti mir i spokoj biljke zato naš sistem obaveštava vlasnika ukoliko dođe do bilo kakvog poremeđaja
- Zvuci -> Opšte je poznato da biljke vole muziku, mada je retko da iko ima vremena da svaki dan priča i peva svojoj biljci zato naš sistem radi i to. Sa specijlanom opcijom uspavanka za "Twinkle, Twinkle, Little Plant"

## Tim
- [Tamara Ilić](https://www.linkedin.com/in/tamara-ili%C4%87-ab9958257/)
- [Uroš Poček](https://www.linkedin.com/in/uros-pocek/)
